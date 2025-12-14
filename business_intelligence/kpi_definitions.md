## `Key Performance Indicators`

This document details the Key Performance Indicators (KPIs) used by the STIS application to monitor farming efficiency, resource consumption, and forecasting reliability.

### 1. Resource Consumption and Allocation

These KPIs focus on how efficiently resources (land and seeds) are utilized across the farm.

#### **Percent of Farm Avg Area**

* **Description:** Measures the planted area of an individual batch or crop type relative to the average area planted across the entire farm in a given period. This provides context for resource allocation decisions.
* **Calculation Method:** $\frac{\text{Batch Area}}{\text{AVG(Total Area) OVER (Time Window)}}$
* **PL/SQL Implementation Note:** Implemented using an **Aggregate Window Function** (`AVG(...) OVER (PARTITION BY ...)` or `ORDER BY ...`) to avoid complex self-joins and perform contextual ranking directly within the database layer.

#### **Seed Consumption Deviation**

* **Description:** Quantifies how far a batch's actual seed consumption deviates (as a percentage) from the established historical average consumption rate for that *specific crop type*.
* **Calculation Method:** $\frac{\text{Actual Consumption} - \text{Crop Average}}{\text{Crop Average}} \times 100\%$
* **PL/SQL Implementation Note:** Requires pre-calculated averages (or a dedicated function call) grouped by `Crop_Type`. A positive deviation indicates potential seed overuse and should trigger an alert.

### 2. Operational Reliability and Data Integrity

These KPIs focus on the system's ability to maintain correct inventory and deliver reliable predictions.

#### **On-Time Delivery Predictability**

* **Description:** A measure of the reliability of the automated `Harvest Prediction Function`. Initially tracked by the consistency of the system's prediction, and later tracked by comparing the predicted harvest date against the actual harvest date.
* **Calculation Method:** Reliability Score based on: $\frac{\text{Batches with Consistent Prediction}}{\text{Total Active Batches}}$
* **PL/SQL Implementation Note:** The integrity of this metric depends on the reliable function of the `calculateHarvestDate` routine and the quality/stability of the input `Harvest_Duration_Days` data from the inventory module.

#### **Total Inventory Efficiency**

* **Description:** Tracks the balance between stock consumption (from planting) and remaining stock. This KPI reflects the accuracy and reliability of the current `SupplyStock` value in real-time.
* **Calculation Method:** $\frac{\text{Current Stock}}{\text{Historical Consumption Rate (per period)}}$
* **PL/SQL Implementation Note:** The reliability of this KPI is fundamentally tied to the **Atomic Update** logic within the PL/SQL package, ensuring that `CurrentStock` is *always* deducted immediately and correctly when a planting transaction is successfully recorded.