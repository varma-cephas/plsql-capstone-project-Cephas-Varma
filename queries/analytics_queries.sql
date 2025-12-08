-- analytics_queries.sql: Management-level summary and comparative analytics
-- Goal 1: Group data by crop to find total area and average seeds consumed.
-- Goal 2: Use an Aggregate Window Function to compare each crop's average area to the total farm average.
SELECT
    ct.CROP_NAME,
    COUNT(pb.BATCH_ID) AS Total_Batches,
    SUM(pb.AREA_PLANTED_SQM) AS Total_Area_Planted_SQM,
    ROUND(AVG(pb.SEEDS_CONSUMED), 2) AS Avg_Seeds_Per_Batch,
    ROUND(AVG(pb.AREA_PLANTED_SQM) * 100 / (
        AVG(pb.AREA_PLANTED_SQM) OVER ()
    ), 2) AS Percent_of_Farm_Avg_Area -- Aggregate Window Function
FROM
    PLANTING_BATCHES pb
JOIN
    CROP_TYPES ct ON pb.CROP_ID = ct.CROP_ID
GROUP BY
    ct.CROP_NAME
ORDER BY
    Total_Area_Planted_SQM DESC;