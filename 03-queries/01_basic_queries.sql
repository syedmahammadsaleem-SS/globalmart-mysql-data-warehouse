-- ============================================================
-- GLOBALMART DATA WAREHOUSE
-- File: 01_basic_queries.sql
-- Purpose: Basic SQL queries for beginners
-- Skills: SELECT, WHERE, GROUP BY, HAVING, ORDER BY, Aggregation
-- ============================================================

USE globalmart_dw;

-- --------------------------------------------------------
-- QUERY 1: Total Sales, Profit, and Orders
-- --------------------------------------------------------
SELECT 
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit), 2) AS avg_profit_per_sale,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS overall_profit_margin_pct
FROM fact_sales;

-- --------------------------------------------------------
-- QUERY 2: Sales by Year
-- --------------------------------------------------------
SELECT 
    YEAR(order_date) AS year,
    COUNT(DISTINCT order_id) AS orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(sales), 2) AS revenue,
    ROUND(SUM(profit), 2) AS profit
FROM fact_sales
GROUP BY YEAR(order_date)
ORDER BY year;

-- --------------------------------------------------------
-- QUERY 3: Top 10 Customers by Revenue
-- --------------------------------------------------------
SELECT 
    c.customer_name,
    c.segment,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.quantity) AS total_units,
    ROUND(SUM(f.sales), 2) AS total_revenue,
    ROUND(SUM(f.profit), 2) AS total_profit
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.segment
ORDER BY total_revenue DESC
LIMIT 10;

-- --------------------------------------------------------
-- QUERY 4: Sales by Customer Segment
-- --------------------------------------------------------
SELECT 
    c.segment,
    COUNT(DISTINCT f.customer_id) AS unique_customers,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.sales), 2) AS total_revenue,
    ROUND(SUM(f.profit), 2) AS total_profit,
    ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) AS profit_margin_pct
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.segment
ORDER BY total_revenue DESC;

-- --------------------------------------------------------
-- QUERY 5: Sales by Category
-- --------------------------------------------------------
SELECT 
    cat.category_name,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.sales), 2) AS revenue,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) AS profit_margin_pct
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
GROUP BY cat.category_name
ORDER BY revenue DESC;

-- --------------------------------------------------------
-- QUERY 6: Top 10 Products by Revenue
-- --------------------------------------------------------
SELECT 
    p.product_name,
    sc.subcategory_name,
    cat.category_name,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.sales), 2) AS total_revenue,
    ROUND(SUM(f.profit), 2) AS total_profit
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
GROUP BY p.product_id, p.product_name, sc.subcategory_name, cat.category_name
ORDER BY total_revenue DESC
LIMIT 10;

-- --------------------------------------------------------
-- QUERY 7: Sales by Region
-- --------------------------------------------------------
SELECT 
    l.region,
    COUNT(DISTINCT f.order_id) AS orders,
    ROUND(SUM(f.sales), 2) AS revenue,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) AS profit_margin_pct
FROM fact_sales f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.region
ORDER BY revenue DESC;

-- --------------------------------------------------------
-- QUERY 8: Sales by Ship Mode
-- --------------------------------------------------------
SELECT 
    sm.ship_mode_name,
    sm.avg_delivery_days,
    COUNT(DISTINCT f.order_id) AS orders,
    ROUND(SUM(f.sales), 2) AS revenue,
    ROUND(AVG(DATEDIFF(f.ship_date, f.order_date)), 1) AS actual_avg_delivery_days
FROM fact_sales f
JOIN dim_ship_mode sm ON f.ship_mode_id = sm.ship_mode_id
GROUP BY sm.ship_mode_id, sm.ship_mode_name, sm.avg_delivery_days
ORDER BY sm.ship_rating;

-- --------------------------------------------------------
-- QUERY 9: Discount Analysis
-- --------------------------------------------------------
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.2 THEN 'Low (1-20%)'
        WHEN discount <= 0.4 THEN 'Medium (21-40%)'
        WHEN discount <= 0.6 THEN 'High (41-60%)'
        ELSE 'Very High (61%+)'
    END AS discount_band,
    COUNT(*) AS sale_count,
    ROUND(SUM(sales), 2) AS revenue,
    ROUND(SUM(profit), 2) AS profit,
    ROUND(AVG(profit), 2) AS avg_profit
FROM fact_sales
GROUP BY discount_band
ORDER BY MIN(discount);

-- --------------------------------------------------------
-- QUERY 10: Monthly Sales Summary (2014)
-- --------------------------------------------------------
SELECT 
    MONTHNAME(order_date) AS month_name,
    MONTH(order_date) AS month_num,
    COUNT(DISTINCT order_id) AS orders,
    SUM(quantity) AS units,
    ROUND(SUM(sales), 2) AS revenue,
    ROUND(SUM(profit), 2) AS profit
FROM fact_sales
WHERE YEAR(order_date) = 2014
GROUP BY MONTH(order_date), MONTHNAME(order_date)
ORDER BY month_num;
