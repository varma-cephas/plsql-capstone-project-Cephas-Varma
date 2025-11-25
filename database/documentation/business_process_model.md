## Business Proccess Modeling
![BPMN Diagram](bpmn_diagram.png "BPMN Diagram") 
### Define Scope, Objectives, and Outcomes

- **Business Process:** **New Planting Batch Creation and Inventory Update.**
- **Scope:** The process begins when a farmer decides to plant a new batch of a specific crop and ends with the planting batch record being created and the corresponding seed inventory being accurately deducted.
- **Objective:** To ensure that the act of planting a new crop batch is immediately and reliably recorded in the **PLANTING_BATCHES** table and that the relevant seed inventory in the **FARM_SUPPLIES** table is atomically updated. 

- **Outcomes:**
    - An accurate new record in the **PLANTING_BATCHES** table. 
    - Accurate and real-time reduction of seed stock in **FARM_SUPPLIES**, preventing stock-outs or over-stocking. 
    - The expected harvest date is instantly predictable. 

### Identify Key Entities (Swimlanes)

You should use three primary swimlanes to separate the actors and systems involved in this process:

| **Key Entity**                     | **Role and Responsibility**                                                                                                                                    |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Farmer (User)**                  | The main user; initiates the planting action and provides the necessary input data (which crop, area, seeds used).                                             |
| **STIS Application/Form (System)** | The front-end interface (or an Oracle SQL prompt) that collects and validates the data before sending it to the database.                                      |
| **Oracle Database (STIS PL/SQL)**  | The core system that executes the business logic, specifically the **Atomic Inventory Consumption Procedure**, to ensure data integrity and automated updates. |


### Logical Flow and Notations (BPMN/UML)

This flow maps directly to the actions performed by your key PL/SQL components.

| **Step**                      | **Actor (Swimlane)**     | **Description**                                                                                                                                      | **STIS Relevance**        |
| ----------------------------- | ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| **Start**                     | Farmer                   | Starts the planting process.                                                                                                                         | _Initial action._         |
| **1. Gather Data**            | Farmer                   | Inputs required data: Crop Type, Date, Area Planted, and Seeds Consumed.                                                                             | _Inputs for STIS._        |
| **2. Submit Data**            | Farmer $\to$ STIS App    | Submits the planting details to the system.                                                                                                          | _Handoff point._          |
| **3. Validate Input**         | STIS App                 | Checks if all NOT NULL fields are present and if the Crop ID exists (e.g., checks **CROP_TYPES** table).                                             | _Data integrity._         |
| **4. Decision Point**         | STIS App                 | Is the data valid? **(Gateway)**                                                                                                                     | _Logical branch._         |
| **- If No**                   | STIS App $\to$ Farmer    | Display Error message. **(End)**                                                                                                                     | _Error path._             |
| **- If Yes**                  | STIS App $\to$ Oracle DB | Call the **Atomic Inventory Consumption Procedure**.                                                                                                 | _PL/SQL execution._       |
| **5. Deduct Inventory**       | Oracle DB (PL/SQL)       | Executes the procedure: checks if `CURRENT_STOCK` in **FARM_SUPPLIES** is $\ge$ `SEEDS_CONSUMED`.                                                    | _Optimization component._ |
| **6. Decision Point**         | Oracle DB (PL/SQL)       | Is there enough stock? **(Gateway)**                                                                                                                 | _Business logic branch._  |
| **- If No**                   | Oracle DB $\to$ STIS App | Rollback transaction. Return "Inventory Stock-Out" error. **(End)**                                                                                  | _Prevents stock-outs._    |
| **- If Yes**                  | Oracle DB (PL/SQL)       | Updates `CURRENT_STOCK` in **FARM_SUPPLIES** (deducts seeds).                                                                                        | _Data update._            |
| **7. Insert Batch**           | Oracle DB (PL/SQL)       | Inserts the new record into the **PLANTING_BATCHES** table.                                                                                          | _Core data creation._     |
| **8. Calculate Harvest Date** | Oracle DB (PL/SQL)       | **(Call Function)** Uses the **Simple Harvest Prediction Function** and the `GROWTH_DAYS` from **CROP_TYPES** to calculate `EXPECTED_HARVEST_DATE`.  | _Innovation component._   |
| **9. Success**                | Oracle DB $\to$ STIS App | Commits transaction and returns success message/calculated date.                                                                                     | _Final result._           |
| **End**                       | STIS App                 | Displays confirmation and the predicted harvest date to the Farmer.                                                                                  | _End of process._         |


### 4. Documentation and Organizational Impact

You will use this section for your one-page explanation.

- **Main Components:** **FARM_SUPPLIES**, **CROP_TYPES**, and **PLANTING_BATCHES** tables. 
- **MIS Functions:** The system acts as a **Transaction Processing System (TPS)** for data entry (new batches) and an **Inventory Management System** for controlling stock. 
    
- **STIS PL/SQL Functions:**
    - **Optimization:** The **Atomic Inventory Consumption Procedure** enforces data integrity by ensuring inventory is updated **at the same time** the batch is planted, replacing error-prone manual tracking. 
    - **Innovation:** The **Simple Harvest Prediction Function** instantly provides reliable future data based on fixed crop metrics, which manual systems cannot do easily. 
- **Organizational Impact Justified:** This system moves the farm from manual, decentralized records to a **centralized source of truth**. This directly addresses the two main issues: **Inventory Inaccuracy** is eliminated by automated deduction, and **Poor Planning** is solved by automated harvest date predictions, allowing for better logistics and sales scheduling.
- **Analytics Opportunities Identified:**
    - **Demand Forecasting:** Tracking consumption (`SEEDS_CONSUMED`) against stock in **FARM_SUPPLIES** allows the farm to predict when to re-order supplies.
    - **Performance Tracking:** Comparing planned vs. actual harvest dates (once Phase III is complete) and tracking `YIELD_PER_UNIT` can help optimize crop management for higher yield.
