-- package specs test
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS 
FROM USER_OBJECTS 
WHERE OBJECT_NAME = 'STIS_PKG';

-- atomic transaction test
SET SERVEROUTPUT ON;
COMMIT; 

DECLARE
    v_new_batch_id NUMBER;
    v_harvest_date DATE;
    v_supply_id NUMBER := 100;      -- Using Maize Seeds
    v_initial_stock NUMBER;
    v_seeds_to_consume NUMBER := 50;
    v_final_stock NUMBER;
BEGIN
    -- 1. Check Initial Stock
    SELECT CURRENT_STOCK INTO v_initial_stock FROM FARM_SUPPLIES WHERE SUPPLY_ID = v_supply_id;
    DBMS_OUTPUT.PUT_LINE('--- SUCCESS TEST START ---');
    DBMS_OUTPUT.PUT_LINE('Initial Stock (Supply 100): ' || v_initial_stock);
    
    -- 2. Execute the Atomic Procedure
    STIS_PKG.record_new_batch (
        p_crop_id => 1,          
        p_supply_id => v_supply_id,
        p_area_planted => 1000,
        p_seeds_consumed => v_seeds_to_consume,
        x_new_batch_id => v_new_batch_id,
        x_harvest_date => v_harvest_date
    );
    
    -- 3. Check Final Stock (must be reduced)
    SELECT CURRENT_STOCK INTO v_final_stock FROM FARM_SUPPLIES WHERE SUPPLY_ID = v_supply_id;
    DBMS_OUTPUT.PUT_LINE('Transaction Successful.');
    DBMS_OUTPUT.PUT_LINE('New Batch ID Created: ' || v_new_batch_id);
    DBMS_OUTPUT.PUT_LINE('Final Stock (Deducted ' || v_seeds_to_consume || '): ' || v_final_stock);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: The successful path failed: ' || SQLERRM);
        ROLLBACK;
END;
/

-- function successful execution and data integrity
SET SERVEROUTPUT ON;

DECLARE
    -- Declare a variable of the table type returned by the function
    v_top_batches STIS_PKG.t_batch_list;
BEGIN
    -- Call the function and collect the results into the variable
    v_top_batches := STIS_PKG.get_top_batches_by_area(p_num_batches => 5);
    
    -- Print Header
    DBMS_OUTPUT.PUT_LINE(RPAD('BATCH_ID', 10) || ' | ' || RPAD('CROP_NAME', 20) || ' | ' || RPAD('AREA', 15) || ' | ' || RPAD('ROW#', 6) || ' | ' || 'RANK');
    DBMS_OUTPUT.PUT_LINE('---------- | -------------------- | --------------- | ------ | ----');

    -- Loop through the collected results and print the 5 columns
    FOR i IN 1..v_top_batches.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_top_batches(i).batch_id, 10) || ' | ' || 
            RPAD(v_top_batches(i).crop_name, 20) || ' | ' || 
            RPAD(v_top_batches(i).area_planted_value, 15) || ' | ' || -- Use the final field name
            RPAD(v_top_batches(i).row_number_rank, 6) || ' | ' || 
            v_top_batches(i).area_rank
        );
    END LOOP;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error executing advanced function test: ' || SQLERRM);
END;
/