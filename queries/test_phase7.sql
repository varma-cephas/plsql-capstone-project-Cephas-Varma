SET SERVEROUTPUT ON;
WHENEVER SQLERROR CONTINUE 

TRUNCATE TABLE DML_AUDIT_LOG; 
COMMIT;


-- A. TEST 1: Trigger blocks INSERT on weekday (DENIED)
BEGIN
    INSERT INTO CROP_TYPES (CROP_ID, CROP_NAME, GROWTH_DAYS, YIELD_PER_UNIT) 
    VALUES (9999, 'TestCropWeekday_Denial', 100, 0.5);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SUCCESS: DML blocked. Error: ' || SQLERRM); 
END;
/

-- B. TEST 2: Compound Trigger allows INSERT (ALLOWED)
DECLARE
    v_new_batch_id NUMBER;
    v_harvest_date DATE;
BEGIN
    STIS_PKG.record_new_batch ( 
        p_crop_id => 1, p_supply_id => 100, p_area_planted => 100,
        p_seeds_consumed => 1, x_new_batch_id => v_new_batch_id, x_harvest_date => v_harvest_date
    );
    DBMS_OUTPUT.PUT_LINE('SUCCESS: ALLOWED transaction executed. Batch ID: ' || v_new_batch_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ALLOWED transaction failed: ' || SQLERRM);
END;
/
COMMIT; 

-- C. VERIFICATION: Audit log captures both DENIED and ALLOWED
SELECT 
    LOG_ID, 
    TRANSACTION_DATE, 
    USER_ACTION, 
    TABLE_NAME, 
    STATUS, 
    DETAILS
FROM DML_AUDIT_LOG
ORDER BY LOG_ID;
