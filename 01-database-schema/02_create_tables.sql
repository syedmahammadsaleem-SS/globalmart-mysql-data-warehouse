-- ============================================================
-- GLOBALMART DATA WAREHOUSE
-- File: 02_create_tables.sql
-- Purpose: Create all tables with Star Schema design
-- Schema: 8 Dimension Tables + 1 Fact Table
-- ============================================================

USE globalmart_dw;

-- --------------------------------------------------------
-- 1. DIMENSION: Market
-- Stores the 7 global markets
-- --------------------------------------------------------
CREATE TABLE dim_market (
    market_id INT PRIMARY KEY AUTO_INCREMENT,
    market_name VARCHAR(50) NOT NULL,
    market_code VARCHAR(10) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- 2. DIMENSION: Location
-- Stores city, state, country, region with market reference
-- --------------------------------------------------------
CREATE TABLE dim_location (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    market_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (market_id) REFERENCES dim_market(market_id),
    UNIQUE KEY uk_location (city, state, country)
);

-- --------------------------------------------------------
-- 3. DIMENSION: Category
-- Product categories: Furniture, Office Supplies, Technology
-- --------------------------------------------------------
CREATE TABLE dim_category (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- 4. DIMENSION: Sub-Category
-- Sub-categories linked to parent category
-- --------------------------------------------------------
CREATE TABLE dim_subcategory (
    subcategory_id INT PRIMARY KEY AUTO_INCREMENT,
    subcategory_name VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
    UNIQUE KEY uk_subcategory (subcategory_name, category_id)
);

-- --------------------------------------------------------
-- 5. DIMENSION: Product
-- Individual products with full-text search on name
-- --------------------------------------------------------
CREATE TABLE dim_product (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_code VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(255) NOT NULL,
    subcategory_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subcategory_id) REFERENCES dim_subcategory(subcategory_id),
    FULLTEXT INDEX idx_product_name (product_name)
);

-- --------------------------------------------------------
-- 6. DIMENSION: Customer
-- Customer master data with segment classification
-- --------------------------------------------------------
CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_code VARCHAR(50) NOT NULL UNIQUE,
    customer_name VARCHAR(255) NOT NULL,
    segment VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_segment (segment)
);

-- --------------------------------------------------------
-- 7. DIMENSION: Ship Mode
-- Shipping methods with performance ratings
-- --------------------------------------------------------
CREATE TABLE dim_ship_mode (
    ship_mode_id INT PRIMARY KEY AUTO_INCREMENT,
    ship_mode_name VARCHAR(100) NOT NULL UNIQUE,
    ship_rating INT COMMENT '1=Fastest, 4=Slowest',
    avg_delivery_days INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- 8. DIMENSION: Order Priority
-- Priority levels for orders
-- --------------------------------------------------------
CREATE TABLE dim_order_priority (
    priority_id INT PRIMARY KEY AUTO_INCREMENT,
    priority_level VARCHAR(20) NOT NULL UNIQUE,
    priority_rank INT NOT NULL COMMENT '1=Highest, 4=Lowest',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------
-- 9. FACT TABLE: Sales
-- Central fact table with all measures and foreign keys
-- --------------------------------------------------------
CREATE TABLE fact_sales (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id VARCHAR(50) NOT NULL,
    order_date DATE NOT NULL,
    ship_date DATE NOT NULL,

    -- Foreign Keys (Dimension Surrogate Keys)
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    location_id INT NOT NULL,
    ship_mode_id INT NOT NULL,
    priority_id INT NOT NULL,

    -- Measures
    quantity INT NOT NULL,
    sales DECIMAL(12,2) NOT NULL,
    discount DECIMAL(5,4) NOT NULL,
    profit DECIMAL(12,2) NOT NULL,
    shipping_cost DECIMAL(12,2),

    -- Audit Fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Foreign Key Constraints
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
    FOREIGN KEY (ship_mode_id) REFERENCES dim_ship_mode(ship_mode_id),
    FOREIGN KEY (priority_id) REFERENCES dim_order_priority(priority_id),

    -- Data Quality Constraints
    CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_sales_nonnegative CHECK (sales >= 0),
    CONSTRAINT chk_discount_range CHECK (discount BETWEEN 0 AND 1),

    -- Indexes for Performance
    INDEX idx_order_date (order_date),
    INDEX idx_customer (customer_id),
    INDEX idx_product (product_id),
    INDEX idx_location (location_id),
    INDEX idx_ship_mode (ship_mode_id),
    INDEX idx_order_id (order_id),
    INDEX idx_date_product (order_date, product_id),
    INDEX idx_date_customer (order_date, customer_id)
) ENGINE=InnoDB;

SELECT 'All tables created successfully!' AS status;


-- ==========new
-- ============================================================
-- GLOBALMART DATA WAREHOUSE
-- File: 02_create_tables.sql
-- Purpose: Create all tables with Star Schema Design
-- Database: MySQL 8+
-- ============================================================

-- Create Database
CREATE DATABASE IF NOT EXISTS globalmart_dw;
USE globalmart_dw;

-- ============================================================
-- 1. DIMENSION: MARKET
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_market (
    market_id INT PRIMARY KEY AUTO_INCREMENT,
    market_name VARCHAR(50) NOT NULL,
    market_code VARCHAR(10) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 2. DIMENSION: LOCATION
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_location (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    market_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_location_market
        FOREIGN KEY (market_id)
        REFERENCES dim_market(market_id),

    UNIQUE KEY uk_location (city, state, country)
) ENGINE=InnoDB;

-- ============================================================
-- 3. DIMENSION: CATEGORY
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_category (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 4. DIMENSION: SUBCATEGORY
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_subcategory (
    subcategory_id INT PRIMARY KEY AUTO_INCREMENT,
    subcategory_name VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_subcategory_category
        FOREIGN KEY (category_id)
        REFERENCES dim_category(category_id),

    UNIQUE KEY uk_subcategory (subcategory_name, category_id)
) ENGINE=InnoDB;

-- ============================================================
-- 5. DIMENSION: PRODUCT
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_product (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_code VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(255) NOT NULL,
    subcategory_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_product_subcategory
        FOREIGN KEY (subcategory_id)
        REFERENCES dim_subcategory(subcategory_id),

    FULLTEXT INDEX idx_product_name (product_name)
) ENGINE=InnoDB;

-- ============================================================
-- 6. DIMENSION: CUSTOMER
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_code VARCHAR(50) NOT NULL UNIQUE,
    customer_name VARCHAR(255) NOT NULL,
    segment VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_segment (segment)
) ENGINE=InnoDB;

-- ============================================================
-- 7. DIMENSION: SHIP MODE
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_ship_mode (
    ship_mode_id INT PRIMARY KEY AUTO_INCREMENT,
    ship_mode_name VARCHAR(100) NOT NULL UNIQUE,
    ship_rating TINYINT NOT NULL,
    avg_delivery_days TINYINT UNSIGNED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_ship_rating
        CHECK (ship_rating BETWEEN 1 AND 4)
) ENGINE=InnoDB;

-- ============================================================
-- 8. DIMENSION: ORDER PRIORITY
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_order_priority (
    priority_id INT PRIMARY KEY AUTO_INCREMENT,
    priority_level VARCHAR(20) NOT NULL UNIQUE,
    priority_rank TINYINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_priority_rank
        CHECK (priority_rank BETWEEN 1 AND 4)
) ENGINE=InnoDB;

-- ============================================================
-- 9. FACT TABLE: SALES
-- ============================================================
CREATE TABLE IF NOT EXISTS fact_sales (
    sale_id BIGINT PRIMARY KEY AUTO_INCREMENT,

    order_id VARCHAR(50) NOT NULL,
    order_date DATE NOT NULL,
    ship_date DATE NOT NULL,

    -- Foreign Keys
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    location_id INT NOT NULL,
    ship_mode_id INT NOT NULL,
    priority_id INT NOT NULL,

    -- Measures
    quantity SMALLINT UNSIGNED NOT NULL,
    sales DECIMAL(12,2) NOT NULL,
    discount DECIMAL(5,4) NOT NULL,
    profit DECIMAL(12,2) NOT NULL,
    shipping_cost DECIMAL(10,2) DEFAULT 0.00,

    -- Audit Columns
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    -- Foreign Keys
    CONSTRAINT fk_sales_customer
        FOREIGN KEY (customer_id)
        REFERENCES dim_customer(customer_id),

    CONSTRAINT fk_sales_product
        FOREIGN KEY (product_id)
        REFERENCES dim_product(product_id),

    CONSTRAINT fk_sales_location
        FOREIGN KEY (location_id)
        REFERENCES dim_location(location_id),

    CONSTRAINT fk_sales_ship_mode
        FOREIGN KEY (ship_mode_id)
        REFERENCES dim_ship_mode(ship_mode_id),

    CONSTRAINT fk_sales_priority
        FOREIGN KEY (priority_id)
        REFERENCES dim_order_priority(priority_id),

    -- Data Quality Checks
    CONSTRAINT chk_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_sales
        CHECK (sales >= 0),

    CONSTRAINT chk_discount
        CHECK (discount BETWEEN 0 AND 1),

    -- Performance Indexes
    INDEX idx_order_date (order_date),
    INDEX idx_ship_date (ship_date),
    INDEX idx_customer (customer_id),
    INDEX idx_product (product_id),
    INDEX idx_location (location_id),
    INDEX idx_ship_mode (ship_mode_id),
    INDEX idx_priority (priority_id),
    INDEX idx_order (order_id),
    INDEX idx_date_product (order_date, product_id),
    INDEX idx_date_customer (order_date, customer_id),
    INDEX idx_customer_product (customer_id, product_id),
    INDEX idx_order_ship (order_date, ship_date)

) ENGINE=InnoDB;

-- ============================================================
-- SUCCESS MESSAGE
-- ============================================================
SELECT '✅ All GlobalMart Data Warehouse tables created successfully!' AS Status;