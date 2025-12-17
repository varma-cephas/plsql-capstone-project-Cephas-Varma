# PL/SQL-Capstone-Project-STIS-VarmaCephas
- Project Name: Seed-to-Harvest Tracking and Inventory System (STIS)
- Student Name and ID: Varma Cephas V. (28179)
- Technology: Oracle Database, PL/SQL


## 1. Project Overview and Problem Statement (Phase I)

The **Seed-to-Harvest Tracking and Inventory System (STIS)** is designed to provide small farming operations with a reliable, centralized system for managing crop cycles and critical supply inventory.

### Key Objective

To replace error-prone manual records with a **centralized source of truth** in an Oracle Database, enforcing data integrity and automating key logistical calculations.

### Real-World Problems Addressed

1.  **Inventory Inaccuracy (Optimization Focus):** Manual tracking leads to stock-outs or costly over-stocking of seeds and fertilizer.
2.  **Poor Planning (Innovation Focus):** Lack of centralized data prevents accurate prediction of harvest dates, causing logistical and sales delays.

## 2. Core PL/SQL Components (Phase II & VI)

The system enforces business logic and automation via a PL/SQL Package (`STIS_PKG`).

| Component | Category | Functionality |
| :--- | :--- | :--- |
| **`record_new_batch` Procedure** | **Optimization** | Executes the core business transaction: **atomically** deducts seed stock from `FARM_SUPPLIES` and inserts the new batch record into `PLANTING_BATCHES`. Includes robust exception handling for 'Stock-Outs' (BPMN critical path). |
| **`get_expected_harvest_date` Function** | **Innovation** | Calculates the expected harvest date instantly by adding the crop's `GROWTH_DAYS` (from `CROP_TYPES`) to the planting date, solving the poor planning problem. |
| **Auditing Triggers** | **Security/Phase VII** | `STIS_AUDIT_TRG` logs all changes (Update/Delete) to the critical `PLANTING_BATCHES` table, ensuring a complete, historical audit trail of all crop life-cycle events. |
| **Advanced Features** | **Phase VI/VII** | Includes an Explicit Cursor and Bulk Fetch to demonstrate data analysis features (e.g., retrieving the largest planted batches for BI). |


## 3. Database Architecture (Phase III)

The logical design is modeled in **Third Normal Form (3NF)** to minimize redundancy and maximize data integrity.

| Table Name | Purpose | Relationship | Key Attributes |
| :--- | :--- | :--- | :--- |
| **PLANTING\_BATCHES** | Transactional log of every planting event. | Linked to `CROP_TYPES` (FK) and `FARM_SUPPLIES` (FK). | `BATCH_ID` (PK), `PLANTING_DATE`, `SEEDS_CONSUMED`. |
| **FARM\_SUPPLIES** | Inventory of all resources. | Tracks `CURRENT_STOCK` and `UNIT_COST`. | `SUPPLY_ID` (PK), `ITEM_NAME`, `CURRENT_STOCK`. |
| **CROP\_TYPES** | Reference data for crop metrics. | Stores fixed data needed for calculations. | `CROP_ID` (PK), `CROP_NAME`, `GROWTH_DAYS`. |

---

### Quick Start: Database Setup (Phase IV)

This project requires an Oracle Database 12c (or higher). The setup is done in two steps:

**Database Naming:** `STIS_PDB` (Pluggable Database)
**Schema User:** `STIS_ADMIN_28179` / Password: `varma`

1.  **PDB and Tablespace Setup:**
    * Connect to your Oracle Container Database (CDB) as `SYSDBA`.
    * Execute the script: `database/scripts/01_pdb_creation_and_config.sql`.
    * *Note: This script verifies Archive Log status, which is required for Auditing (Phase VII).*

2.  **User and Permissions Setup:**
    * Connect to the newly created PDB (`STIS_PDB`) as `SYSDBA`.
    * Execute the script: `database/scripts/02_user_and_permissions.sql`.

Once completed, all subsequent PL/SQL in the scripts folder should be executed while logged in as the user: `STIS_ADMIN_28179`.


### Links to Documentation
- [Logical Database Design](./database/documentation/logical_database_design.md "Logical Database Design") 
- [Business Process Model](./database/documentation/business_process_model.md "Business Process Model") 

