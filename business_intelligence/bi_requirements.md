## `Business Intelligence Requirements`

This document outlines the Business Intelligence (BI) and visualization requirements for the main dashboard, ensuring that the KPIs are actionable and presented effectively to the user.

### 1. Comparative Performance View

This requirement addresses the need for farmers to make immediate resource allocation and management decisions.

* **KPI Source:** **Percent of Farm Avg Area**
* **Visualization:** **Bar Chart or Radial Chart.** Each crop type/batch should show its area planted, overlaid with a benchmark line or color-coding representing the Farm-Wide Average area.
* **Functionality:** Allows farmers to instantly identify crops over-utilizing or under-utilizing land resources compared to the mean.

### 2. Deviation Alert Monitor

This is the primary tool for auditing and quality control related to resource usage.

* **KPI Source:** **Seed Consumption Deviation**
* **Visualization:** **Traffic Light System (Red/Yellow/Green)** or a **Scatter Plot** with a tolerance band.
* **Alert Threshold:** Batches with a deviation exceeding a predefined threshold should trigger a **Red Alert**, signaling potential seed wastage or documentation error.
* **Functionality:** Enables farm managers to perform audits by investigating batches where seed consumption falls outside the expected norms.

### 3. Real-Time Status & Scheduling

This requirement centralizes operational data for forecasting and management.

* **KPI Source:** **On-Time Delivery Predictability** (indirectly)
* **Visualization:** **Active Batch Table/Gantt Chart.** Must show key columns: `Batch Name`, `Crop Type`, `Phase` (Seedling, Growing, Maturing), and `Expected Harvest Date`.
* **Data Integrity:** The displayed `Expected Harvest Date` must be calculated using the reliable, non-locale-dependent **Harvest Prediction Function** in the reporting module.
* **Functionality:** Provides a central "control tower" for scheduling future labor and logistics based on the predicted harvest windows.

### 4. Inventory Efficiency View

This requirement provides confidence in the current stock levels.

* **KPI Source:** **Total Inventory Efficiency**
* **Visualization:** **Gauge or Donut Chart.** Shows the current stock level and its relationship to the historical consumption rate (e.g., "Enough stock for X months").
* **Functionality:** Confirms the success of the atomic transaction process and aids in deciding when to initiate the **Restock** process.