-- Connect as the project user: STIS_ADMIN_28179

CREATE OR REPLACE TRIGGER STIS_AUDIT_TRG
BEFORE UPDATE OR DELETE ON PLANTING_BATCHES
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
BEGIN
    -- Determine the operation
    IF UPDATING THEN
        v_operation := 'UPDATE';
    ELSIF DELETING THEN
        v_operation := 'DELETE';
    ELSE
        -- Should not happen with this trigger definition
        RETURN;
    END IF;

    -- Only log if a critical column has been updated OR if the row is being deleted
    IF UPDATING AND (
        :OLD.STATUS != :NEW.STATUS OR
        :OLD.EXPECTED_HARVEST_DATE != :NEW.EXPECTED_HARVEST_DATE OR
        :OLD.AREA_PLANTED_SQM != :NEW.AREA_PLANTED_SQM
    ) OR DELETING THEN
        
        -- Insert the audit record
        INSERT INTO BATCH_AUDIT_LOG (
            BATCH_ID,
            OPERATION,
            OLD_STATUS, NEW_STATUS,
            OLD_HARVEST_DATE, NEW_HARVEST_DATE,
            OLD_AREA_SQM, NEW_AREA_SQM
        ) VALUES (
            :OLD.BATCH_ID,
            v_operation,
            :OLD.STATUS, :NEW.STATUS,
            :OLD.EXPECTED_HARVEST_DATE, :NEW.EXPECTED_HARVEST_DATE,
            :OLD.AREA_PLANTED_SQM, :NEW.AREA_PLANTED_SQM
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        -- IMPORTANT: Avoid failure of the primary DML statement (Update/Delete)
        -- by trapping the trigger error. Log the failure elsewhere if needed.
        DBMS_OUTPUT.PUT_LINE('Audit Trigger Failed: ' || SQLERRM);
END STIS_AUDIT_TRG;
/