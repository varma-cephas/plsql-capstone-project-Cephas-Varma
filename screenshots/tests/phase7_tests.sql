-- Connect as the project user: STIS_ADMIN_28179

SET SERVEROUTPUT ON
SET LINESIZE 120

-- TEST 1: DML Trigger (Update)
DECLARE
    v_batch_id PLANTING_BATCHES.BATCH_ID%TYPE;
    v_new_status CONSTANT VARCHAR2(20) := 'HARVESTING';
BEGIN
    -- Find a sample batch (e.g., the oldest one still 'PLANTED')
    SELECT MIN(BATCH_ID) INTO v_batch_id
    FROM PLANTING_BATCHES
    WHERE STATUS = 'PLANTED';

    IF v_batch_id IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('No PLANTED batches found for testing.');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('--- TEST 1: Updating Batch Status (DML Trigger) ---');
    DBMS_OUTPUT.PUT_LINE('Updating Batch ID: ' || v_batch_id || ' to status: ' || v_new_status);

    -- Execute the update (which should fire the DML trigger)
    STIS_PKG.update_batch_status(p_batch_id => v_batch_id, p_new_status => v_new_status);

    -- Verify the audit log record
    DBMS_OUTPUT.PUT_LINE('Verification from Audit Log:');
    SELECT COUNT(*) FROM BATCH_AUDIT_LOG
    WHERE BATCH_ID = v_batch_id AND NEW_STATUS = v_new_status;

    DBMS_OUTPUT.PUT_LINE('Successfully audited status change for Batch ' || v_batch_id);
END;
/

-- TEST 2: DDL Trigger (Create a dummy table)
DECLARE
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- TEST 2: Testing DDL Trigger ---');
    
    -- Execute a DDL command
    EXECUTE IMMEDIATE 'CREATE TABLE Z_DUMMY_TEST (ID NUMBER)';

    -- Check DDL Audit Log
    SELECT COUNT(*) INTO v_count FROM DDL_AUDIT_LOG
    WHERE OBJECT_NAME = 'Z_DUMMY_TEST' AND EVENT_TYPE = 'CREATE';

    DBMS_OUTPUT.PUT_LINE('DDL Log count for Z_DUMMY_TEST: ' || v_count);
    
    -- Cleanup (This DDL command will also be logged)
    EXECUTE IMMEDIATE 'DROP TABLE Z_DUMMY_TEST';
    
    -- Check DDL Audit Log again
    SELECT COUNT(*) INTO v_count FROM DDL_AUDIT_LOG
    WHERE OBJECT_NAME = 'Z_DUMMY_TEST' AND EVENT_TYPE = 'DROP';
    
    DBMS_OUTPUT.PUT_LINE('DDL Log count for DROP: ' || v_count);
END;
/