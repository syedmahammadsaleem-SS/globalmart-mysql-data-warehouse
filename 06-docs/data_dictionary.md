# GlobalMart Data Warehouse - Data Dictionary

## Dimension Tables

### dim_market
| Column | Type | Description |
|--------|------|-------------|
| market_id | INT PK | Surrogate key |
| market_name | VARCHAR(50) | Market name (US, EU, APAC, etc.) |
| market_code | VARCHAR(10) | Short code |

### dim_location
| Column | Type | Description |
|--------|------|-------------|
| location_id | INT PK | Surrogate key |
| city | VARCHAR(100) | City name |
| state | VARCHAR(100) | State/Province |
| country | VARCHAR(100) | Country name |
| region | VARCHAR(50) | Geographic region |
| market_id | INT FK | Reference to dim_market |

### dim_category
| Column | Type | Description |
|--------|------|-------------|
| category_id | INT PK | Surrogate key |
| category_name | VARCHAR(100) | Furniture, Office Supplies, Technology |

### dim_subcategory
| Column | Type | Description |
|--------|------|-------------|
| subcategory_id | INT PK | Surrogate key |
| subcategory_name | VARCHAR(100) | Sub-category name |
| category_id | INT FK | Reference to dim_category |

### dim_product
| Column | Type | Description |
|--------|------|-------------|
| product_id | INT PK | Surrogate key |
| product_code | VARCHAR(50) | Original product ID |
| product_name | VARCHAR(255) | Product description |
| subcategory_id | INT FK | Reference to dim_subcategory |

### dim_customer
| Column | Type | Description |
|--------|------|-------------|
| customer_id | INT PK | Surrogate key |
| customer_code | VARCHAR(50) | Original customer ID |
| customer_name | VARCHAR(255) | Customer full name |
| segment | VARCHAR(50) | Consumer, Corporate, Home Office |

### dim_ship_mode
| Column | Type | Description |
|--------|------|-------------|
| ship_mode_id | INT PK | Surrogate key |
| ship_mode_name | VARCHAR(100) | Shipping method |
| ship_rating | INT | 1=Fastest, 4=Slowest |
| avg_delivery_days | INT | Expected delivery time |

### dim_order_priority
| Column | Type | Description |
|--------|------|-------------|
| priority_id | INT PK | Surrogate key |
| priority_level | VARCHAR(20) | Critical, High, Medium, Low |
| priority_rank | INT | 1=Highest, 4=Lowest |

## Fact Table

### fact_sales
| Column | Type | Description |
|--------|------|-------------|
| sale_id | INT PK | Surrogate key |
| order_id | VARCHAR(50) | Original order identifier |
| order_date | DATE | When order was placed |
| ship_date | DATE | When order was shipped |
| customer_id | INT FK | Reference to dim_customer |
| product_id | INT FK | Reference to dim_product |
| location_id | INT FK | Reference to dim_location |
| ship_mode_id | INT FK | Reference to dim_ship_mode |
| priority_id | INT FK | Reference to dim_order_priority |
| quantity | INT | Units ordered |
| sales | DECIMAL(12,2) | Revenue amount |
| discount | DECIMAL(5,4) | Discount percentage (0-1) |
| profit | DECIMAL(12,2) | Profit amount |
| shipping_cost | DECIMAL(12,2) | Shipping cost |