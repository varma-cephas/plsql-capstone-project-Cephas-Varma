-- Connect as the project user: STIS_ADMIN_28179

SET SERVEROUTPUT ON
SET LINESIZE 120

-- TEST 1: SUCCESSFUL BATCH RECORDING (Optimization/Innovation)
DECLARE
    v_new_batch_id PLANTING_BATCHES.BATCH_ID%TYPE;
    v_harvest_date DATE;
    v_crop_id CONSTANT NUMBER := 100; -- Maize (White)
    v_supply_id CONSTANT NUMBER := 200; -- Maize Seeds
    v_seeds_used CONSTANT NUMBER := 5.00;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TEST 1: Successful Planting Transaction ---');
    -- Record initial stock for comparison
    DBMS_OUTPUT.PUT_LINE('Initial Stock (Supply 200): ' || STIS_PKG.check_supply_stock(v_supply_id));

    STIS_PKG.record_new_batch(
        p_crop_id => v_crop_id,
        p_supply_id => v_supply_id,
        p_area_planted => 5.0,
        p_seeds_consumed => v_seeds_used,
        x_new_batch_id => v_new_batch_id,
        x_harvest_date => v_harvest_date
    );

    DBMS_OUTPUT.PUT_LINE('SUCCESS! New Batch ID: ' || v_new_batch_id);
    DBMS_OUTPUT.PUT_LINE('Predicted Harvest Date: ' || TO_CHAR(v_harvest_date, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('New Stock (Supply 200): ' || STIS_PKG.check_supply_stock(v_supply_id));
    -- The New Stock should be reduced by 5.00
END;
/

-- TEST 2: STOCK-OUT EXCEPTION HANDLING (Critical Error Path)
DECLARE
    v_new_batch_id PLANTING_BATCHES.BATCH_ID%TYPE;
    v_harvest_date DATE;
    v_crop_id CONSTANT NUMBER := 101; -- Tomatoes
    v_supply_id CONSTANT NUMBER := 201; -- Tomato Seeds (current stock is 15.00 GRAM)
    v_seeds_used CONSTANT NUMBER := 20.00; -- Attempt to consume more than available
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- TEST 2: Stock-Out Failure Test ---');
    DBMS_OUTPUT.PUT_LINE('Initial Stock (Supply 201): ' || STIS_PKG.check_supply_stock(v_supply_id));
    
    STIS_PKG.record_new_batch(
        p_crop_id => v_crop_id,
        p_supply_id => v_supply_id,
        p_area_planted => 1.0,
        p_seeds_consumed => v_seeds_used, -- Will fail (20 > 15)
        x_new_batch_id => v_new_batch_id,
        x_harvest_date => v_harvest_date
    );

EXCEPTION
    WHEN STIS_PKG.e_stock_out THEN
        DBMS_OUTPUT.PUT_LINE('ERROR CAUGHT: Stock-Out Exception raised correctly.');
        DBMS_OUTPUT.PUT_LINE('Final Stock (Supply 201): ' || STIS_PKG.check_supply_stock(v_supply_id));
        -- The stock should be unchanged (due to ROLLBACK)
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected Error: ' || SQLERRM);
END;
/

-- TEST 3: WINDOW FUNCTION / CURSOR DEMONSTRATION
DECLARE
    v_batches STIS_PKG.t_batch_list;
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- TEST 3: Top 3 Largest Batches (Window Function) ---');
    
    v_batches := STIS_PKG.get_top_batches_by_area(p_num_batches => 3);

    DBMS_OUTPUT.PUT_LINE(RPAD('Rank', 6) || RPAD('Batch ID', 10) || RPAD('Crop Name', 20) || 'Area Planted (SQM)');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 6, '-') || RPAD('-', 10, '-') || RPAD('-', 20, '-') || RPAD('-', 20, '-'));

    FOR i IN 1..v_batches.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_batches(i).area_rank, 6) || 
            RPAD(v_batches(i).batch_id, 10) || 
            RPAD(v_batches(i).crop_name, 20) || 
            v_batches(i).area_planted
        );
    END LOOP;
END;
/