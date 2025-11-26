-- Connect as the project user: STIS_ADMIN_28179

-- 1. Basic Retrieval (Test 1: Check Data Volume and Structure)
SELECT 'CROP_TYPES' AS Table_Name, COUNT(*) AS Row_Count FROM CROP_TYPES
UNION ALL
SELECT 'FARM_SUPPLIES', COUNT(*) FROM FARM_SUPPLIES
UNION ALL
SELECT 'PLANTING_BATCHES', COUNT(*) FROM PLANTING_BATCHES;
-- Result should show 100+ rows for PLANTING_BATCHES.

-- 2. Join Query (Test 2: Verify Foreign Key Relationships)
-- Show all active planting batches, including the name of the crop and the seeds used.
SELECT
    pb.BATCH_ID,
    ct.CROP_NAME,
    fs.ITEM_NAME AS Seeds_Used,
    pb.PLANTING_DATE,
    pb.AREA_PLANTED_SQM,
    pb.SEEDS_CONSUMED
FROM PLANTING_BATCHES pb
JOIN CROP_TYPES ct ON pb.CROP_ID = ct.CROP_ID
JOIN FARM_SUPPLIES fs ON pb.SUPPLY_ID = fs.SUPPLY_ID
WHERE pb.STATUS = 'PLANTED' OR pb.STATUS = 'GROWING';

-- 3. Aggregation Query (Test 3: Calculate total inventory and total area planted)
-- Total sum of current stock across all supplies.
SELECT
    fs.UNIT_OF_MEASURE,
    SUM(fs.CURRENT_STOCK) AS Total_Current_Stock,
    SUM(fs.UNIT_COST * fs.CURRENT_STOCK) AS Total_Inventory_Value
FROM FARM_SUPPLIES fs
GROUP BY fs.UNIT_OF_MEASURE;

-- Total area planted per crop type.
SELECT
    ct.CROP_NAME,
    SUM(pb.AREA_PLANTED_SQM) AS Total_Area_Planted_SQM
FROM PLANTING_BATCHES pb
JOIN CROP_TYPES ct ON pb.CROP_ID = ct.CROP_ID
GROUP BY ct.CROP_NAME
ORDER BY 2 DESC;