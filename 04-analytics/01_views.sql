-- ============================================================
-- GLOBALMART DATA WAREHOUSE
-- File: 01_views.sql
-- Purpose: Create analytical views for business reporting
-- ============================================================

USE globalmart_dw;

-- --------------------------------------------------------
-- VIEW 1: Executive Summary Dashboard
-- Yearly KPIs for leadership
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_executive_summary AS
SELECT 
    YEAR(order_date) AS year,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_units,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(AVG(sales), 2) AS avg_order_value,
    ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM fact_sales
GROUP BY YEAR(order_date)
ORDER BY year;

-- --------------------------------------------------------
-- VIEW 2: Product Performance
-- All products with key metrics
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_product_performance AS
SELECT 
    cat.category_name,
    sc.subcategory_name,
    p.product_id,
    p.product_name,
    COUNT(*) AS transactions,
    SUM(f.quantity) AS total_quantity,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.profit), 2) AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    COUNT(DISTINCT f.order_id) AS order_count,
    COUNT(DISTINCT f.customer_id) AS unique_customers,
    MAX(f.order_date) AS last_sale_date
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
GROUP BY p.product_id, p.product_name, sc.subcategory_name, cat.category_name;

-- --------------------------------------------------------
-- VIEW 3: Customer 360 Profile
-- Complete customer view with RFM-style metrics
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_360 AS
SELECT 
    c.customer_id,
    c.customer_code,
    c.customer_name,
    c.segment,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.quantity) AS total_units,
    ROUND(SUM(f.sales), 2) AS total_revenue,
    ROUND(SUM(f.profit), 2) AS total_profit,
    ROUND(AVG(f.sales), 2) AS avg_order_value,
    MIN(f.order_date) AS first_purchase,
    MAX(f.order_date) AS last_purchase,
    DATEDIFF(MAX(f.order_date), MIN(f.order_date)) AS customer_lifespan_days,
    DATEDIFF('2015-01-01', MAX(f.order_date)) AS days_since_last_purchase,
    COUNT(DISTINCT cat.category_id) AS categories_purchased,
    COUNT(DISTINCT p.subcategory_id) AS subcategories_purchased,
    CASE 
        WHEN SUM(f.sales) >= 10000 THEN 'Platinum'
        WHEN SUM(f.sales) >= 5000 THEN 'Gold'
        WHEN SUM(f.sales) >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
GROUP BY c.customer_id, c.customer_code, c.customer_name, c.segment;

-- --------------------------------------------------------
-- VIEW 4: Geographic Performance
-- Market and region level analysis
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_geographic_performance AS
SELECT 
    m.market_name,
    l.region,
    l.country,
    l.state,
    COUNT(DISTINCT f.customer_id) AS unique_customers,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.quantity) AS total_units,
    ROUND(SUM(f.sales), 2) AS total_revenue,
    ROUND(SUM(f.profit), 2) AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(f.sales), 2) AS avg_order_value,
    ROUND(SUM(f.sales) / COUNT(DISTINCT f.customer_id), 2) AS revenue_per_customer
FROM fact_sales f
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_market m ON l.market_id = m.market_id
GROUP BY m.market_name, l.region, l.country, l.state;

-- --------------------------------------------------------
-- VIEW 5: Shipping Performance
-- Shipping mode efficiency analysis
-- --------------------------------------------------------
CREATE OR REPLACE VIEW vw_shipping_performance AS
SELECT 
    sm.ship_mode_name,
    sm.ship_rating,
    sm.avg_delivery_days AS expected_days,
    COUNT(*) AS total_shipments,
    ROUND(AVG(DATEDIFF(f.ship_date, f.order_date)), 1) AS actual_avg_days,
    ROUND(SUM(f.shipping_cost), 2) AS total_shipping_cost,
    ROUND(AVG(f.shipping_cost), 2) AS avg_shipping_cost,
    ROUND(SUM(f.sales), 2) AS revenue_shipped,
    ROUND(SUM(f.shipping_cost) / SUM(f.sales) * 100, 2) AS shipping_cost_pct,
    ROUND(SUM(f.profit), 2) AS total_profit,
    SUM(CASE WHEN DATEDIFF(f.ship_date, f.order_date) <= sm.avg_delivery_days THEN 1 ELSE 0 END) AS on_time_shipments,
    ROUND(SUM(CASE WHEN DATEDIFF(f.ship_date, f.order_date) <= sm.avg_delivery_days THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS on_time_rate_pct
FROM fact_sales f
JOIN dim_ship_mode sm ON f.ship_mode_id = sm.ship_mode_id
GROUP BY sm.ship_mode_id, sm.ship_mode_name, sm.ship_rating, sm.avg_delivery_days;

SELECT 'All views created successfully!' AS status;
