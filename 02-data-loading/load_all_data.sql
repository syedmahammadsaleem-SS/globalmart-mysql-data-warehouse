-- ============================================================
-- GLOBALMART DATA WAREHOUSE
-- File: load_all_data.sql
-- Purpose: Load all dimension and fact table data
-- Note: Run this AFTER running 02_create_tables.sql
-- ============================================================

USE globalmart_dw;

-- --------------------------------------------------------
-- 1. LOAD DIMENSION: Market
-- --------------------------------------------------------
INSERT INTO dim_market (market_name, market_code) VALUES
('United States', 'US'),
('Europe', 'EU'),
('Asia Pacific', 'APAC'),
('Latin America', 'LATAM'),
('Africa', 'AFR'),
('Middle East', 'EMEA'),
('Canada', 'CAN');

SELECT 'Markets loaded' AS status;

-- --------------------------------------------------------
-- 2. LOAD DIMENSION: Order Priority
-- --------------------------------------------------------
INSERT INTO dim_order_priority (priority_level, priority_rank) VALUES
('Critical', 1),
('High', 2),
('Medium', 3),
('Low', 4);

SELECT 'Order priorities loaded' AS status;

-- --------------------------------------------------------
-- 3. LOAD DIMENSION: Ship Mode
-- --------------------------------------------------------
INSERT INTO dim_ship_mode (ship_mode_name, ship_rating, avg_delivery_days) VALUES
('Same Day', 1, 1),
('First Class', 2, 2),
('Second Class', 3, 4),
('Standard Class', 4, 7);

SELECT 'Ship modes loaded' AS status;

-- --------------------------------------------------------
-- 4. LOAD DIMENSION: Category
-- --------------------------------------------------------
INSERT INTO dim_category (category_name) VALUES
('Furniture'),
('Office Supplies'),
('Technology');

SELECT 'Categories loaded' AS status;

-- --------------------------------------------------------
-- 5. LOAD DIMENSION: Sub-Category
-- --------------------------------------------------------
INSERT INTO dim_subcategory (subcategory_name, category_id) VALUES
-- Furniture (category_id = 1)
('Bookcases', 1),
('Chairs', 1),
('Tables', 1),
('Furnishings', 1),
-- Office Supplies (category_id = 2)
('Art', 2),
('Binders', 2),
('Envelopes', 2),
('Fasteners', 2),
('Labels', 2),
('Paper', 2),
('Storage', 2),
('Supplies', 2),
-- Technology (category_id = 3)
('Accessories', 3),
('Copiers', 3),
('Machines', 3),
('Phones', 3);

SELECT 'Sub-categories loaded' AS status;

-- --------------------------------------------------------
-- 6. LOAD DIMENSION: Location
-- NOTE: This is a SAMPLE. For full dataset, use CSV import.
-- Use MySQL Workbench Table Data Import Wizard for complete data.
-- --------------------------------------------------------
INSERT INTO dim_location (city, state, country, region, market_id) VALUES
('New York City', 'New York', 'United States', 'East', 1),
('Los Angeles', 'California', 'United States', 'West', 1),
('Chicago', 'Illinois', 'United States', 'Central', 1),
('Houston', 'Texas', 'United States', 'Central', 1),
('Phoenix', 'Arizona', 'United States', 'West', 1),
('Philadelphia', 'Pennsylvania', 'United States', 'East', 1),
('San Antonio', 'Texas', 'United States', 'Central', 1),
('San Diego', 'California', 'United States', 'West', 1),
('Dallas', 'Texas', 'United States', 'Central', 1),
('San Jose', 'California', 'United States', 'West', 1),
('London', 'England', 'United Kingdom', 'EMEA', 2),
('Berlin', 'Berlin', 'Germany', 'EMEA', 2),
('Paris', 'Ile-de-France', 'France', 'EMEA', 2),
('Mumbai', 'Maharashtra', 'India', 'APAC', 3),
('Tokyo', 'Tokyo', 'Japan', 'APAC', 3),
('Sydney', 'New South Wales', 'Australia', 'APAC', 3),
('Sao Paulo', 'Sao Paulo', 'Brazil', 'LATAM', 4),
('Mexico City', 'Mexico City', 'Mexico', 'LATAM', 4),
('Cape Town', 'Western Cape', 'South Africa', 'Africa', 5),
('Toronto', 'Ontario', 'Canada', 'North', 7);

SELECT 'Sample locations loaded (Load full data from CSV)' AS status;

-- --------------------------------------------------------
-- 7. LOAD DIMENSION: Customer
-- NOTE: This is a SAMPLE. For full dataset, use CSV import.
-- --------------------------------------------------------
INSERT INTO dim_customer (customer_code, customer_name, segment) VALUES
('CUST-0001', 'Claire Gute', 'Consumer'),
('CUST-0002', 'Darrin Van Huff', 'Corporate'),
('CUST-0003', 'Sean ODonnell', 'Consumer'),
('CUST-0004', 'Brosina Hoffman', 'Consumer'),
('CUST-0005', 'Andrew Allen', 'Consumer'),
('CUST-0006', 'Irene Maddox', 'Consumer'),
('CUST-0007', 'Harold Pawlan', 'Home Office'),
('CUST-0008', 'Pete Kriz', 'Consumer'),
('CUST-0009', 'Alejandro Grove', 'Consumer'),
('CUST-0010', 'Zuschuss Donatelli', 'Consumer'),
('CUST-0011', 'Ken Black', 'Corporate'),
('CUST-0012', 'Sandra Flanagan', 'Consumer'),
('CUST-0013', 'Emily Burns', 'Consumer'),
('CUST-0014', 'Eric Hoffmann', 'Consumer'),
('CUST-0015', 'Tracy Blumstein', 'Consumer');

SELECT 'Sample customers loaded (Load full data from CSV)' AS status;

-- --------------------------------------------------------
-- 8. LOAD DIMENSION: Product
-- NOTE: This is a SAMPLE. For full dataset, use CSV import.
-- --------------------------------------------------------
INSERT INTO dim_product (product_code, product_name, subcategory_id) VALUES
('PROD-0001', 'Hon Deluxe Fabric Upholstered Stacking Chairs', 2),
('PROD-0002', 'Self-Adhesive Address Labels for Typewriters by Universal', 9),
('PROD-0003', 'Bretford CR4500 Series Slim Rectangular Table', 3),
('PROD-0004', 'Eldon Fold N Roll Cart System', 11),
('PROD-0005', 'Eldon Expressions Wood and Plastic Desk Accessories', 11),
('PROD-0006', 'Newell 322', 9),
('PROD-0007', 'Office Star Ergonomic Mid-Back Chair with 2-Way Adjustable Arms', 2),
('PROD-0008', 'Bevis Round Conference Table Top & Base', 3),
('PROD-0009', 'Avery Self-Adhesive Address Labels for Typewriters by Universal', 9),
('PROD-0010', 'Hon 4700 Series Mobuis Mid-Back Task Chairs', 2),
('PROD-0011', 'Global Deluxe High-Back Manager Chair', 2),
('PROD-0012', 'Xerox 1967', 14),
('PROD-0013', 'Fellowes PB500 Electric Punch Plastic Comb Binding Machine', 14),
('PROD-0014', 'Cardinal Slant-D Ring Binder', 6),
('PROD-0015', 'Memorex Mini Travel Drive 64 GB USB 2.0 Flash Drive', 13);

SELECT 'Sample products loaded (Load full data from CSV)' AS status;

-- --------------------------------------------------------
-- 9. LOAD FACT TABLE: Sales
-- NOTE: This is a SAMPLE. For full dataset, use CSV import.
-- --------------------------------------------------------
INSERT INTO fact_sales (order_id, order_date, ship_date, customer_id, product_id, location_id, ship_mode_id, priority_id, quantity, sales, discount, profit, shipping_cost) VALUES
('CA-2011-100006', '2011-09-07', '2011-09-13', 1, 1, 1, 4, 3, 2, 457.5680, 0.0000, -123.8580, 25.50),
('CA-2011-100090', '2011-07-08', '2011-07-12', 2, 2, 2, 4, 3, 3, 46.7100, 0.0000, 15.6100, 3.60),
('CA-2011-100293', '2011-03-14', '2011-03-18', 3, 3, 3, 4, 3, 5, 1706.1840, 0.2000, -246.9840, 60.20),
('CA-2011-100328', '2011-01-28', '2011-02-01', 4, 4, 4, 4, 3, 2, 68.8100, 0.0000, -123.8580, 7.30),
('CA-2011-100363', '2011-04-30', '2011-05-04', 5, 5, 5, 4, 3, 7, 25.9200, 0.0000, 11.3600, 2.50),
('CA-2011-100391', '2011-12-26', '2012-01-02', 6, 6, 6, 4, 3, 3, 146.7300, 0.0000, 63.1300, 4.80),
('CA-2011-100678', '2011-11-03', '2011-11-08', 7, 7, 7, 4, 3, 1, 243.1600, 0.0000, 72.9500, 8.99),
('CA-2011-100706', '2011-03-02', '2011-03-06', 8, 8, 8, 4, 3, 2, 496.5000, 0.0000, -330.3300, 14.30),
('CA-2011-100762', '2011-05-30', '2011-06-05', 9, 9, 9, 4, 3, 3, 19.4600, 0.0000, 9.3400, 2.20),
('CA-2011-100860', '2011-08-28', '2011-09-02', 10, 10, 10, 4, 3, 7, 1044.6300, 0.0000, 240.2600, 32.10);

SELECT 'Sample sales loaded (Load full data from CSV)' AS status;

-- ============================================================
-- HOW TO LOAD FULL DATA FROM CSV (Using MySQL Workbench)
-- ============================================================
--
-- Method 1: Table Data Import Wizard (Recommended for beginners)
-- 1. In MySQL Workbench, right-click on the table
-- 2. Select "Table Data Import Wizard"
-- 3. Browse to your CSV file
-- 4. Map columns and follow the wizard
--
-- Method 2: LOAD DATA INFILE (Faster for large files)
--
-- LOAD DATA INFILE 'C:/path/to/your/dim_location.csv'
-- INTO TABLE dim_location
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '
'
-- IGNORE 1 ROWS
-- (city, state, country, region, market_id);
--
-- ============================================================

SELECT 'Data loading complete!' AS status;
