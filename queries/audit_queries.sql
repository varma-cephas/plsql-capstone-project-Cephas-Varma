-- audit_queries.sql: Identifies transactional anomalies (soft audit)
-- Goal: Find the top 5 batches where seed consumption was significantly higher 
-- than the average consumption for that specific crop type.
SELECT
    p.BATCH_ID,
    c.CROP_NAME,
    p.SEEDS_CONSUMED,
    ROUND((p.SEEDS_CONSUMED - AVG(p.SEEDS_CONSUMED) OVER (PARTITION BY p.CROP_ID)), 2) AS Seed_Deviation_From_Crop_Avg,
    p.PLANTING_DATE
FROM
    PLANTING_BATCHES p
JOIN
    CROP_TYPES c ON p.CROP_ID = c.CROP_ID
WHERE
    p.SEEDS_CONSUMED > (
        SELECT 
            AVG(SEEDS_CONSUMED)
        FROM 
            PLANTING_BATCHES sub
        WHERE 
            sub.CROP_ID = p.CROP_ID
    ) -- Filter for only batches above their crop average
ORDER BY
    Seed_Deviation_From_Crop_Avg DESC
FETCH FIRST 5 ROWS ONLY;