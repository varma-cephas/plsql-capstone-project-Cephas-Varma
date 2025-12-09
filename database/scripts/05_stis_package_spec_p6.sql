-- Defines the public interface for all business logic
CREATE OR REPLACE PACKAGE STIS_PKG AS
    -- Custom Exception for business rule violations
    e_stock_out EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_stock_out, -20002);
    
    -- Function 1 (Innovation): Calculates expected harvest date
    FUNCTION get_expected_harvest_date (
        p_planting_date IN DATE,
        p_crop_id IN NUMBER
    ) RETURN DATE;
    
    -- Procedure 1 (Optimization): Atomic transaction for planting a new batch
    PROCEDURE record_new_batch (
        p_crop_id IN NUMBER,
        p_supply_id IN NUMBER,
        p_area_planted IN NUMBER,
        p_seeds_consumed IN NUMBER,
        x_new_batch_id OUT NUMBER,
        x_harvest_date OUT DATE
    );

    -- Procedure 2: Updates a batch's status
    PROCEDURE update_batch_status (
        p_batch_id IN NUMBER,
        p_new_status IN VARCHAR2
    );
    
    -- Procedure 3: Records the purchase/addition of new supply stock
    PROCEDURE replenish_supply (
        p_supply_id IN NUMBER,
        p_quantity_added IN NUMBER
    );
    
    -- Function 2 (Validation/Lookup): Retrieves the current stock level
    FUNCTION check_supply_stock (
        p_supply_id IN NUMBER
    ) RETURN NUMBER;
    
    -- Function 3 (Calculation): Calculates the actual yield rate
    FUNCTION calculate_yield_rate (
        p_batch_id IN NUMBER,
        p_actual_harvest_kg IN NUMBER
    ) RETURN NUMBER;

-- Function 4 (Advanced/Cursor): Uses an Explicit Cursor and Bulk Fetch for BI prep
    TYPE t_batch_record IS RECORD (
        batch_id NUMBER(10), 
        crop_name VARCHAR2(50),
        area_planted_value NUMBER(10, 2), -- *** CRITICAL FINAL FIX: Renamed to avoid ambiguity ***
        row_number_rank NUMBER(10), 
        area_rank NUMBER(10)        
    );
    TYPE t_batch_list IS TABLE OF t_batch_record;

    FUNCTION get_top_batches_by_area (
        p_num_batches IN NUMBER DEFAULT 5
    ) RETURN t_batch_list;

END STIS_PKG;
/