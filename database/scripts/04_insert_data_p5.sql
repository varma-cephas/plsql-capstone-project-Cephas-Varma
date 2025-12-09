-- 4. INSERT REFERENCE DATA (CROP_TYPES)
INSERT INTO CROP_TYPES (CROP_ID, CROP_NAME, GROWTH_DAYS, YIELD_PER_UNIT) VALUES 
(seq_crop_id.NEXTVAL, 'Maize (White)', 120, 0.5); -- CROP_ID = 1
INSERT INTO CROP_TYPES (CROP_ID, CROP_NAME, GROWTH_DAYS, YIELD_PER_UNIT) VALUES 
(seq_crop_id.NEXTVAL, 'Beans (Red)', 90, 0.3); -- CROP_ID = 2
INSERT INTO CROP_TYPES (CROP_ID, CROP_NAME, GROWTH_DAYS, YIELD_PER_UNIT) VALUES 
(seq_crop_id.NEXTVAL, 'Sorghum', 150, 0.6); -- CROP_ID = 3
INSERT INTO CROP_TYPES (CROP_ID, CROP_NAME, GROWTH_DAYS, YIELD_PER_UNIT) VALUES 
(seq_crop_id.NEXTVAL, 'Wheat', 180, 0.4); -- CROP_ID = 4

-- 5. INSERT INITIAL INVENTORY DATA (FARM_SUPPLIES)
-- SUPPLY_ID 100 = Maize Seeds; SUPPLY_ID 102 = Beans Seeds
INSERT INTO FARM_SUPPLIES (SUPPLY_ID, ITEM_NAME, CURRENT_STOCK, UNIT_OF_MEASURE) VALUES 
(100, 'Maize Seeds (Hybrid)', 5000, 'KG');
INSERT INTO FARM_SUPPLIES (SUPPLY_ID, ITEM_NAME, CURRENT_STOCK, UNIT_OF_MEASURE) VALUES 
(101, 'Fertilizer (NPK)', 2500, 'KG');
INSERT INTO FARM_SUPPLIES (SUPPLY_ID, ITEM_NAME, CURRENT_STOCK, UNIT_OF_MEASURE) VALUES 
(102, 'Beans Seeds (Red Variety)', 1500, 'KG');
INSERT INTO FARM_SUPPLIES (SUPPLY_ID, ITEM_NAME, CURRENT_STOCK, UNIT_OF_MEASURE) VALUES 
(103, 'Sorghum Seeds', 3000, 'KG');


-- 6. INSERT BULK TRANSACTIONAL DATA
DECLARE
    v_date DATE := DATE '2024-01-01';
    v_crop_id_maize CONSTANT NUMBER := 1; 
    v_crop_id_beans CONSTANT NUMBER := 2; 
    v_supply_id_maize CONSTANT NUMBER := 100;
    v_supply_id_beans CONSTANT NUMBER := 102;
    v_count NUMBER := 0;
BEGIN
    -- Loop 1: Create 60 Maize batches
    FOR i IN 1..60 LOOP
        v_date := DATE '2024-01-01' + (i * 5);
        
        INSERT INTO PLANTING_BATCHES (BATCH_ID, CROP_ID, SUPPLY_ID, PLANTING_DATE, AREA_PLANTED_SQM, SEEDS_CONSUMED, STATUS)
        VALUES (seq_batch_id.NEXTVAL, v_crop_id_maize, v_supply_id_maize, v_date, 
                DBMS_RANDOM.VALUE(100, 500), 
                DBMS_RANDOM.VALUE(5, 20),    
                CASE 
                    WHEN i < 15 THEN 'HARVESTED' 
                    ELSE 'PLANTED'
                END);
        v_count := v_count + 1;
    END LOOP;
    
    -- Loop 2: Create 45 Beans batches
    FOR i IN 1..45 LOOP
        v_date := DATE '2024-02-15' + (i * 6);
        
        INSERT INTO PLANTING_BATCHES (BATCH_ID, CROP_ID, SUPPLY_ID, PLANTING_DATE, AREA_PLANTED_SQM, SEEDS_CONSUMED, STATUS, EXPECTED_HARVEST_DATE)
        VALUES (seq_batch_id.NEXTVAL, v_crop_id_beans, v_supply_id_beans, v_date, 
                DBMS_RANDOM.VALUE(50, 300), 
                DBMS_RANDOM.VALUE(3, 15),
                CASE 
                    WHEN i < 30 THEN 'HARVESTED' 
                    ELSE 'PLANTED'
                END,
                CASE 
                    WHEN i < 30 THEN v_date + 90 
                    ELSE NULL
                END);
        v_count := v_count + 1;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(v_count || ' transactional rows inserted into PLANTING_BATCHES.');
END;
/

COMMIT;

