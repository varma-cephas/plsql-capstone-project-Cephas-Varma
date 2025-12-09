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
        -- 1. Check Stock and Lock Row (Atomic Start)
        SELECT CURRENT_STOCK INTO v_current_stock
        FROM FARM_SUPPLIES
        WHERE SUPPLY_ID = p_supply_id
        FOR UPDATE OF CURRENT_STOCK; 

        -- 2. Decision Point: Is there enough stock?
        IF v_current_stock < p_seeds_consumed THEN
            RAISE e_stock_out;
        END IF;

        -- 3. Deduct Inventory 
        UPDATE FARM_SUPPLIES
        SET CURRENT_STOCK = CURRENT_STOCK - p_seeds_consumed
        WHERE SUPPLY_ID = p_supply_id;

        -- 4. Calculate Harvest Date
        x_harvest_date := STIS_PKG.get_expected_harvest_date(TRUNC(SYSDATE), p_crop_id);

        -- 5. Insert New Batch (Assumes BATCH_ID trigger is in place)
        INSERT INTO PLANTING_BATCHES (
            CROP_ID, SUPPLY_ID, PLANTING_DATE, AREA_PLANTED_SQM, SEEDS_CONSUMED, STATUS, EXPECTED_HARVEST_DATE
        )
        VALUES (
            p_crop_id, p_supply_id, TRUNC(SYSDATE), p_area_planted, p_seeds_consumed, 'PLANTED', x_harvest_date
        )
        RETURNING BATCH_ID INTO x_new_batch_id; 

        -- 6. Success
        COMMIT;

    EXCEPTION
        WHEN e_stock_out THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'Inventory Stock-Out: Cannot deduct ' || p_seeds_consumed || ' from supply ID ' || p_supply_id || '.');
        WHEN OTHERS THEN
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
        UPDATE PLANTING_BATCHES SET STATUS = p_new_status WHERE BATCH_ID = p_batch_id;
        COMMIT;
    END update_batch_status;
    
    -- Procedure 3: Records the purchase/addition of new supply stock
    PROCEDURE replenish_supply (
        p_supply_id IN NUMBER,
        p_quantity_added IN NUMBER
    )
    AS
    BEGIN
        UPDATE FARM_SUPPLIES SET CURRENT_STOCK = CURRENT_STOCK + p_quantity_added WHERE SUPPLY_ID = p_supply_id;
        COMMIT;
    END replenish_supply;
    
    -- Function 2 (Validation/Lookup): Retrieves the current stock level
    FUNCTION check_supply_stock (
        p_supply_id IN NUMBER
    ) RETURN NUMBER
    AS
        v_stock NUMBER;
    BEGIN
        SELECT CURRENT_STOCK INTO v_stock FROM FARM_SUPPLIES WHERE SUPPLY_ID = p_supply_id;
        RETURN v_stock;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END check_supply_stock;
    
    -- Function 3 (Calculation): Calculates the actual yield rate
    FUNCTION calculate_yield_rate (
        p_batch_id IN NUMBER,
        p_actual_harvest_kg IN NUMBER
    ) RETURN NUMBER
    AS
    BEGIN
        -- Placeholder implementation for demonstration
        RETURN p_actual_harvest_kg / 1000; 
    END calculate_yield_rate;


    -- Function 4 (Advanced/Cursor): Uses Explicit Cursor & Bulk Fetch with Window Functions
    FUNCTION get_top_batches_by_area (
        p_num_batches IN NUMBER DEFAULT 5
    ) RETURN t_batch_list
    AS
        CURSOR c_top_batches IS
            SELECT 
                BATCH_ID,
                CROP_NAME,
                AREA_PLANTED_SQM,
                ROW_NUMBER() OVER (ORDER BY AREA_PLANTED_SQM DESC) AS ROW_NUMBER_RANK,
                RANK() OVER (ORDER BY AREA_PLANTED_SQM DESC) AS AREA_RANK
            FROM PLANTING_BATCHES pb
            JOIN CROP_TYPES ct ON pb.CROP_ID = ct.CROP_ID
            WHERE pb.STATUS IN ('PLANTED', 'GROWING');
            
        v_batch_list t_batch_list;
        v_batch_rec c_top_batches%ROWTYPE;
    BEGIN
        OPEN c_top_batches;
        FETCH c_top_batches BULK COLLECT INTO v_batch_list LIMIT p_num_batches;
        CLOSE c_top_batches;
        
        RETURN v_batch_list;
    END get_top_batches_by_area;

END STIS_PKG;
/