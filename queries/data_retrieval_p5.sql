-- Connect as the project user: STIS_ADMIN_28179

-- 1. Basic Retrieval (Test 1: Check Data Volume and Structure)
-- 1. Basic Analysis: Expected Yield Rate Per Batch
SELECT
    pb.BATCH_ID,
    ct.CROP_NAME,
    pb.AREA_PLANTED_SQM,
    ct.YIELD_PER_UNIT AS Expected_Yield_Rate_Per_SQM
FROM
    PLANTING_BATCHES pb
JOIN
    CROP_TYPES ct ON pb.CROP_ID = ct.CROP_ID
WHERE
    pb.STATUS = 'PLANTED'
ORDER BY
    pb.EXPECTED_HARVEST_DATE
FETCH FIRST 10 ROWS ONLY;

-- 2. Join Query (Test 2: Verify Foreign Key Relationships)
-- Show all active planting batches, including the name of the crop and the seeds used.
-- 3. Aggregate Analysis: Comparison to Farm Average Area (Aggregate Window Function)
SELECT
    ct.CROP_NAME,
    ROUND(AVG(pb.AREA_PLANTED_SQM), 2) AS Avg_Area_Planted_Per_Crop,
    ROUND(AVG(pb.AREA_PLANTED_SQM) OVER (), 2) AS Farm_Wide_Avg_Area,
    -- Calculated Percentage Deviation from the Farm Average
    ROUND((AVG(pb.AREA_PLANTED_SQM) / AVG(pb.AREA_PLANTED_SQM) OVER ()) * 100, 2) AS Percent_of_Farm_Avg
FROM
    PLANTING_BATCHES pb
JOIN
    CROP_TYPES ct ON pb.CROP_ID = ct.CROP_ID
GROUP BY
    ct.CROP_NAME
ORDER BY
    Percent_of_Farm_Avg DESC;


-- 3. Aggregation Query (Test 3: Calculate total inventory and total area planted)
-- Total sum of current stock across all supplies.
-- 3. Historical Audit: Track High Consumption Batches (Join and Aggregate)
-- Finds which batches consumed the most seeds from the Maize supply (ID 100)
SELECT
    pb.BATCH_ID,
    pb.PLANTING_DATE,
    pb.SEEDS_CONSUMED,
    ct.CROP_NAME
FROM
    PLANTING_BATCHES pb
JOIN
    CROP_TYPES ct ON pb.CROP_ID = ct.CROP_ID
WHERE
    pb.SUPPLY_ID = 100 -- Targeting Maize Seeds
ORDER BY
    pb.SEEDS_CONSUMED DESC
FETCH FIRST 5 ROWS ONLY;