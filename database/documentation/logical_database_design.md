## Logical Database Design
### ER Diagram
![ER Diagram](./er_diagram.png "ER Diagram") 
### Data Dictionary
#### 1. Table: CROP_TYPES

Purpose: Stores standard metrics for different crops (Reference Data).

|Column Name|Data Type|Constraints|Purpose|
|---|---|---|---|
|`CROP_ID`|`NUMBER(10)`|**PK**, NOT NULL|Unique identifier.|
|`CROP_NAME`|`VARCHAR2(50)`|NOT NULL, UNIQUE|Name of the crop.|
|`GROWTH_DAYS`|`NUMBER(5)`|CHECK (>0)|Used for harvest prediction.|
|`YIELD_PER_UNIT`|`NUMBER(10,2)`|CHECK (>=0)|Standard yield metric.|


#### 2. Table: FARM_SUPPLIES

Purpose: Tracks current stock and cost of farm resources (Inventory).

|Column Name|Data Type|Constraints|Purpose|
|---|---|---|---|
|`SUPPLY_ID`|`NUMBER(10)`|**PK**, NOT NULL|Unique identifier.|
|`ITEM_NAME`|`VARCHAR2(100)`|NOT NULL, UNIQUE|Name of supply (e.g. 'Potato Seeds').|
|`CURRENT_STOCK`|`NUMBER(10,2)`|NOT NULL, CHECK (>=0)|Quantity on hand.|
|`UNIT_OF_MEASURE`|`VARCHAR2(20)`|NOT NULL|e.g. 'KG', 'BAG'.|
|`UNIT_COST`|`NUMBER(10,2)`|CHECK (>=0)|Tracks cost (implied by "Tracks cost" in purpose).|


#### 3. Table: PLANTING_BATCHES

Purpose: Tracks specific planting instances.

|Column Name|Data Type|Constraints|Purpose|
|---|---|---|---|
|`BATCH_ID`|`NUMBER(10)`|**PK**, NOT NULL|Unique identifier.|
|`CROP_ID`|`NUMBER(10)`|**FK** (Ref CROP_TYPES)|Identifies crop type.|
|`SUPPLY_ID`|`NUMBER(10)`|**FK** (Ref FARM_SUPPLIES)|**Added:** Links batch to specific seed inventory.|
|`PLANTING_DATE`|`DATE`|NOT NULL|Date of planting.|
|`AREA_PLANTED_SQM`|`NUMBER(10,2)`|NOT NULL, CHECK (>0)|Size of area planted.|
|`SEEDS_CONSUMED`|`NUMBER(10,2)`|NOT NULL, CHECK (>0)|Quantity deducted from inventory.|
|`STATUS`|`VARCHAR2(20)`|NOT NULL|e.g. 'PLANTED'.|
|`EXPECTED_HARVEST_DATE`|`DATE`||Stores the calculated prediction.|

