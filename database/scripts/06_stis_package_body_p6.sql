-- Implements the logic for the STIS_PKG package
CREATE OR REPLACE PACKAGE BODY STIS_PKG AS

    -- Function 1 (Innovation): Calculates expected harvest date
    FUNCTION get_expected_harvest_date (
        p_planting_date IN DATE,
        p_crop_id IN NUMBER
    ) RETURN DATE
    AS
        v_growth_days CROP_TYPES.GROWTH_DAYS%TYPE;
    BEGIN
        SELECT GROWTH_DAYS INTO v_growth_days
        FROM CROP_TYPES
        WHERE CROP_ID = p_crop_id;
        
        -- Date arithmetic: Planting Date + Growth Days
        RETURN p_planting_date + v_growth_days;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20003, 'Error calculating harvest date: ' || SQLERRM);
    END get_expected_harvest_date;

    -- Procedure 1 (Optimization): Atomic planting transaction
    PROCEDURE record_new_batch (
        p_crop_id IN NUMBER,
        p_supply_id IN NUMBER,
        p_area_planted IN NUMBER,
        p_seeds_consumed IN NUMBER,
        x_new_batch_id OUT NUMBER,
        x_harvest_date OUT DATE
    )
    AS
        v_current_stock FARM_SUPPLIES.CURRENT_STOCK%TYPE;
    BEGIN
        -- 1. Check Stock and Lock Row (Step 5 in BPMN)
        SELECT CURRENT_STOCK INTO v_current_stock
        FROM FARM_SUPPLIES
        WHERE SUPPLY_ID = p_supply_id
        FOR UPDATE OF CURRENT_STOCK; 

        -- 2. Decision Point: Is there enough stock? (Step 6 in BPMN)
        IF v_current_stock < p_seeds_consumed THEN
            -- If No -> Rollback transaction and raise custom exception
            RAISE e_stock_out;
        END IF;

        -- 3. Deduct Inventory (Step 6: If Yes)
        UPDATE FARM_SUPPLIES
        SET CURRENT_STOCK = CURRENT_STOCK - p_seeds_consumed
        WHERE SUPPLY_ID = p_supply_id;

        -- 4. Calculate Harvest Date (Step 8: Call Function)
        x_harvest_date := STIS_PKG.get_expected_harvest_date(SYSDATE, p_crop_id);

        -- 5. Insert New Batch (Step 7)
        INSERT INTO PLANTING_BATCHES (
            CROP_ID, SUPPLY_ID, PLANTING_DATE, AREA_PLANTED_SQM, SEEDS_CONSUMED, STATUS, EXPECTED_HARVEST_DATE
        )
        VALUES (
            p_crop_id, p_supply_id, SYSDATE, p_area_planted, p_seeds_consumed, 'PLANTED', x_harvest_date
        )
        RETURNING BATCH_ID INTO x_new_batch_id; -- Get the auto-generated ID

        -- 6. Success (Step 9)
        COMMIT;

    EXCEPTION
        WHEN e_stock_out THEN
            -- Custom exception handling
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'Inventory Stock-Out: Cannot deduct ' || p_seeds_consumed || ' from supply ID ' || p_supply_id || '.');
        WHEN OTHERS THEN
            -- Generic exception handling
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'Error during new batch recording: ' || SQLERRM);
    END record_new_batch;

    -- Procedure 2: Updates a batch's status
    PROCEDURE update_batch_status (
        p_batch_id IN NUMBER,
        p_new_status IN VARCHAR2
    )
    AS
    BEGIN
        UPDATE PLANTING_BATCHES
        SET STATUS = p_new_status
        WHERE BATCH_ID = p_batch_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Batch ID ' || p_batch_id || ' not found.');
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'Error updating batch status: ' || SQLERRM);
    END update_batch_status;

    -- Procedure 3: Records the purchase/addition of new supply stock
    PROCEDURE replenish_supply (
        p_supply_id IN NUMBER,
        p_quantity_added IN NUMBER
    )
    AS
    BEGIN
        UPDATE FARM_SUPPLIES
        SET CURRENT_STOCK = CURRENT_STOCK + p_quantity_added
        WHERE SUPPLY_ID = p_supply_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Supply ID ' || p_supply_id || ' not found for replenishment.');
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'Error during supply replenishment: ' || SQLERRM);
    END replenish_supply;
    
    -- Function 2 (Validation/Lookup): Retrieves the current stock level
    FUNCTION check_supply_stock (
        p_supply_id IN NUMBER
    ) RETURN NUMBER
    AS
        v_stock FARM_SUPPLIES.CURRENT_STOCK%TYPE;
    BEGIN
        SELECT CURRENT_STOCK INTO v_stock
        FROM FARM_SUPPLIES
        WHERE SUPPLY_ID = p_supply_id;
        
        RETURN v_stock;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN -1; -- Indicates supply not found
    END check_supply_stock;
    
    -- Function 3 (Calculation): Calculates the actual yield rate
    FUNCTION calculate_yield_rate (
        p_batch_id IN NUMBER,
        p_actual_harvest_kg IN NUMBER
    ) RETURN NUMBER
    AS
        v_area PLANTING_BATCHES.AREA_PLANTED_SQM%TYPE;
    BEGIN
        SELECT AREA_PLANTED_SQM INTO v_area
        FROM PLANTING_BATCHES
        WHERE BATCH_ID = p_batch_id;
        
        IF v_area = 0 THEN
            RETURN 0; -- Avoid division by zero
        END IF;
        
        -- Actual Yield Rate = Total Harvest (kg) / Area Planted (sqm)
        RETURN p_actual_harvest_kg / v_area;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END calculate_yield_rate;

    -- Function 4 (Advanced/Cursor): Uses Explicit Cursor & Bulk Fetch with Window Functions
    -- This function fetches the top N largest planting batches using ROW_NUMBER()
    FUNCTION get_top_batches_by_area (
        p_num_batches IN NUMBER DEFAULT 5
    ) RETURN t_batch_list
    AS
        -- Define Explicit Cursor using a Window Function (ROW_NUMBER)
        CURSOR c_top_batches IS
            SELECT 
                BATCH_ID,
                CROP_NAME,
                AREA_PLANTED_SQM,
                ROW_NUMBER() OVER (ORDER BY AREA_PLANTED_SQM DESC) AS area_rank
            FROM PLANTING_BATCHES pb
            JOIN CROP_TYPES ct ON pb.CROP_ID = ct.CROP_ID
            WHERE pb.STATUS IN ('PLANTED', 'GROWING');
            
        v_batch_list t_batch_list;
        v_batch_rec c_top_batches%ROWTYPE;
    BEGIN
        -- Bulk Operations: Open, Fetch (Bulk Collect), Close
        OPEN c_top_batches;
        FETCH c_top_batches BULK COLLECT INTO v_batch_list LIMIT p_num_batches;
        CLOSE c_top_batches;
        
        RETURN v_batch_list;
    END get_top_batches_by_area;

END STIS_PKG;
/