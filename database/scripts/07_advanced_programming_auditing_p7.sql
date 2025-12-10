-- Phase VII: Advanced Programming & Auditing Requirements Setup Script

SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT FAILURE

-- 1. CLEANUP PREVIOUS PHASE VII OBJECTS (Optional, but safe)
DROP TRIGGER trg_crop_dml_restriction;
DROP TRIGGER trg_batch_dml_audit;
DROP FUNCTION check_restriction_rule;
DROP PROCEDURE log_dml_attempt; 
DROP FUNCTION log_dml_attempt; 
DROP TABLE PUBLIC_HOLIDAYS CASCADE CONSTRAINTS;
DROP TABLE DML_AUDIT_LOG CASCADE CONSTRAINTS;
-- Removed: DROP SEQUENCE seq_holiday_id; (Confirmed not in use)

-- Re-establish SQL Error Handling
WHENEVER SQLERROR EXIT FAILURE

-- 2. HOLIDAY MANAGEMENT TABLE & DATA
CREATE TABLE PUBLIC_HOLIDAYS (
    HOLIDAY_DATE DATE PRIMARY KEY,
    HOLIDAY_NAME VARCHAR2(100) NOT NULL
) TABLESPACE STIS_DATA_TS;

-- Insert sample holidays for the upcoming month (Dec 2025)
INSERT INTO PUBLIC_HOLIDAYS (HOLIDAY_DATE, HOLIDAY_NAME) VALUES (DATE '2025-12-25', 'Christmas Day');
INSERT INTO PUBLIC_HOLIDAYS (HOLIDAY_DATE, HOLIDAY_NAME) VALUES (DATE '2025-12-26', 'Boxing Day');
COMMIT;

-- 3. AUDIT LOG TABLE
CREATE TABLE DML_AUDIT_LOG (
    LOG_ID          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    TRANSACTION_DATE TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP,
    USER_ACTION     VARCHAR2(10) NOT NULL,
    TABLE_NAME      VARCHAR2(50) NOT NULL,
    USER_NAME       VARCHAR2(50) DEFAULT USER,
    STATUS          VARCHAR2(10) NOT NULL,
    DETAILS         VARCHAR2(255)
) TABLESPACE STIS_DATA_TS;

-- 4. AUDIT LOGGING PROCEDURE (FIX: Changed from FUNCTION to PROCEDURE)
CREATE OR REPLACE PROCEDURE log_dml_attempt (
    p_action    IN VARCHAR2,
    p_table     IN VARCHAR2,
    p_status    IN VARCHAR2,
    p_details   IN VARCHAR2 DEFAULT NULL
) 
IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO DML_AUDIT_LOG (USER_ACTION, TABLE_NAME, STATUS, DETAILS)
    VALUES (p_action, p_table, p_status, p_details);
    COMMIT; -- Necessary for autonomous transactions
END log_dml_attempt;
/

-- 5. RESTRICTION CHECK FUNCTION 
CREATE OR REPLACE FUNCTION check_restriction_rule 
RETURN BOOLEAN
IS
    v_is_weekend    VARCHAR2(1);
    v_is_holiday    NUMBER;
    v_current_date  DATE := TRUNC(SYSDATE);
BEGIN
    SELECT DECODE(TO_CHAR(v_current_date, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH'), 'SAT', 'Y', 'SUN', 'Y', 'N')
    INTO v_is_weekend 
    FROM DUAL;

    SELECT COUNT(*)
    INTO v_is_holiday
    FROM PUBLIC_HOLIDAYS
    WHERE HOLIDAY_DATE = v_current_date;

    IF v_is_weekend = 'Y' AND v_is_holiday = 0 THEN
        RETURN TRUE; 
    ELSE 
        RETURN FALSE; 
    END IF;
END check_restriction_rule;
/

-- 6. SIMPLE TRIGGER: Enforce Restriction Rule 
CREATE OR REPLACE TRIGGER trg_crop_dml_restriction
BEFORE INSERT OR UPDATE OR DELETE ON CROP_TYPES
DECLARE
BEGIN
    IF NOT check_restriction_rule THEN
        log_dml_attempt(
            p_action => CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
            p_table  => 'CROP_TYPES',
            p_status => 'DENIED',
            p_details => 'DML restricted on Weekday/Holiday.'
        );
        RAISE_APPLICATION_ERROR(-20010, 'Business Rule Violation: DML is restricted to weekends (non-holiday).');
    END IF;
END trg_crop_dml_restriction;
/

-- 7. COMPOUND TRIGGER: Comprehensive Audit Logging 
CREATE OR REPLACE TRIGGER trg_batch_dml_audit
FOR INSERT OR UPDATE OR DELETE ON PLANTING_BATCHES
COMPOUND TRIGGER
    v_action DML_AUDIT_LOG.USER_ACTION%TYPE;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING THEN
            v_action := 'INSERT';
        ELSIF UPDATING THEN
            v_action := 'UPDATE';
        ELSE
            v_action := 'DELETE';
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        log_dml_attempt(
            p_action => v_action,
            p_table  => 'PLANTING_BATCHES',
            p_status => 'ALLOWED',
            p_details => 'Transaction successfully executed.'
        );
    END AFTER STATEMENT;
END trg_batch_dml_audit;
/
