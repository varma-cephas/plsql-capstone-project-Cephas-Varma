## `Dashboard_Structure` 

This document defines the layout and flow of the main STIS dashboard, integrating the components defined in the BI Requirements document.

### 1. Dashboard Layout and Priority

The dashboard is designed with a three-column layout for immediate consumption of critical information, followed by a dedicated area for detailed scheduling.

| Section | Priority | BI Requirement Component | Purpose |
| :--- | :--- | :--- | :--- |
| **Header** | High | N/A | Navigation (Dashboard, Reports, Inventory) and System-wide Status/Notifications. |
| **Top Left (Widget)** | Critical | **Alert Monitor** | Instant visual signal for highest-priority audit issues. |
| **Top Right (Widget)** | Critical | **Inventory Efficiency View** | Quick check on stock health and atomic transaction integrity. |
| **Center Section** | High | **Comparative Performance View** | Primary area for strategic decision-making and resource analysis. |
| **Bottom Section** | Standard | **Real-Time Status & Scheduling** | Detailed, scrollable area for operational planning and timeline review. |

### 2. Dashboard Flow and Interaction

1.  **Alert-Driven:** Users should first check the **Alert Monitor** for any Red Alerts requiring immediate action.
2.  **Strategic Review:** Users then review the **Comparative Performance View** to analyze resource efficiency across different crops.
3.  **Operational Planning:** The **Real-Time Status & Scheduling** section is used for day-to-day work, focusing on dates and phases.

