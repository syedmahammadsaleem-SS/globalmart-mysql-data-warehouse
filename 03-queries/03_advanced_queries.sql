-- ============================================================
-- GLOBALMART DATA WAREHOUSE
-- File: 03_advanced_queries.sql
-- Purpose: Advanced SQL queries with complex joins and subqueries
-- Skills: Multi-table joins, Correlated subqueries, EXISTS, IN
-- ============================================================

USE globalmart_dw;

-- --------------------------------------------------------
-- QUERY 1: Geographic Performance with Market Context
-- --------------------------------------------------------
SELECT 
    m.market_name,
    l.country,
    l.state,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.sales), 2) AS revenue,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS margin_pct,
    COUNT(DISTINCT f.customer_id) AS unique_customers
FROM fact_sales f
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_market m ON l.market_id = m.market_id
GROUP BY m.market_name, l.country, l.state
ORDER BY revenue DESC
LIMIT 30;

-- --------------------------------------------------------
-- QUERY 2: Customer Segmentation - Cross-Category Buyers
-- --------------------------------------------------------
SELECT 
    c.customer_name,
    c.segment,
    COUNT(DISTINCT cat.category_name) AS categories_purchased,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.sales), 2) AS total_revenue,
    ROUND(SUM(f.profit), 2) AS total_profit,
    GROUP_CONCAT(DISTINCT cat.category_name ORDER BY cat.category_name SEPARATOR ', ') AS category_list
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
GROUP BY c.customer_id, c.customer_name, c.segment
HAVING categories_purchased >= 2
ORDER BY total_revenue DESC
LIMIT 20;

-- --------------------------------------------------------
-- QUERY 3: Products with Above-Average Profit Margin
-- (Correlated Subquery)
-- --------------------------------------------------------
SELECT 
    p.product_name,
    sc.subcategory_name,
    cat.category_name,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.sales), 2) AS revenue,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) AS profit_margin_pct
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
GROUP BY p.product_id, p.product_name, sc.subcategory_name, cat.category_name
HAVING profit_margin_pct > (
    SELECT AVG(profit / sales * 100) 
    FROM fact_sales 
    WHERE sales > 0
)
ORDER BY profit_margin_pct DESC
LIMIT 20;

-- --------------------------------------------------------
-- QUERY 4: Customers Who Purchased in ALL Three Categories
-- --------------------------------------------------------
SELECT 
    c.customer_name,
    c.segment,
    COUNT(DISTINCT cat.category_id) AS category_count,
    ROUND(SUM(f.sales), 2) AS total_spent
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
GROUP BY c.customer_id, c.customer_name, c.segment
HAVING category_count = 3
ORDER BY total_spent DESC
LIMIT 20;

-- --------------------------------------------------------
-- QUERY 5: Products Never Sold (Using NOT EXISTS)
-- --------------------------------------------------------
SELECT 
    p.product_code,
    p.product_name,
    sc.subcategory_name,
    cat.category_name
FROM dim_product p
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
WHERE NOT EXISTS (
    SELECT 1 FROM fact_sales f WHERE f.product_id = p.product_id
)
ORDER BY cat.category_name, sc.subcategory_name;

-- --------------------------------------------------------
-- QUERY 6: Top Customer Per Region
-- --------------------------------------------------------
WITH customer_region_sales AS (
    SELECT 
        l.region,
        c.customer_name,
        SUM(f.sales) AS total_sales,
        RANK() OVER (PARTITION BY l.region ORDER BY SUM(f.sales) DESC) AS rnk
    FROM fact_sales f
    JOIN dim_customer c ON f.customer_id = c.customer_id
    JOIN dim_location l ON f.location_id = l.location_id
    GROUP BY l.region, c.customer_id, c.customer_name
)
SELECT region, customer_name, ROUND(total_sales, 2) AS total_sales
FROM customer_region_sales
WHERE rnk = 1
ORDER BY total_sales DESC;

-- --------------------------------------------------------
-- QUERY 7: Sales Performance vs Category Average
-- --------------------------------------------------------
WITH category_avg AS (
    SELECT 
        cat.category_id,
        cat.category_name,
        AVG(f.sales) AS avg_sale_value
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
    JOIN dim_category cat ON sc.category_id = cat.category_id
    GROUP BY cat.category_id, cat.category_name
)
SELECT 
    f.order_id,
    f.order_date,
    p.product_name,
    cat.category_name,
    ROUND(f.sales, 2) AS sale_amount,
    ROUND(ca.avg_sale_value, 2) AS category_avg,
    ROUND(f.sales - ca.avg_sale_value, 2) AS vs_category_avg,
    CASE 
        WHEN f.sales > ca.avg_sale_value THEN 'Above Average'
        WHEN f.sales < ca.avg_sale_value THEN 'Below Average'
        ELSE 'Average'
    END AS performance
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
JOIN category_avg ca ON cat.category_id = ca.category_id
ORDER BY vs_category_avg DESC
LIMIT 30;

-- --------------------------------------------------------
-- QUERY 8: Market Penetration Analysis
-- --------------------------------------------------------
SELECT 
    m.market_name,
    COUNT(DISTINCT l.state) AS states_served,
    COUNT(DISTINCT l.city) AS cities_served,
    COUNT(DISTINCT f.customer_id) AS unique_customers,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.sales), 2) AS total_revenue,
    ROUND(SUM(f.profit), 2) AS total_profit,
    ROUND(AVG(f.sales), 2) AS avg_order_value
FROM fact_sales f
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_market m ON l.market_id = m.market_id
GROUP BY m.market_id, m.market_name
ORDER BY total_revenue DESC;

-- --------------------------------------------------------
-- QUERY 9: Shipping Efficiency Analysis
-- --------------------------------------------------------
SELECT 
    sm.ship_mode_name,
    sm.avg_delivery_days AS expected_days,
    ROUND(AVG(DATEDIFF(f.ship_date, f.order_date)), 1) AS actual_avg_days,
    ROUND(AVG(DATEDIFF(f.ship_date, f.order_date)) - sm.avg_delivery_days, 1) AS variance,
    COUNT(*) AS shipments,
    ROUND(SUM(f.shipping_cost), 2) AS total_shipping_cost,
    ROUND(AVG(f.shipping_cost), 2) AS avg_shipping_cost,
    ROUND(SUM(f.sales), 2) AS revenue_shipped
FROM fact_sales f
JOIN dim_ship_mode sm ON f.ship_mode_id = sm.ship_mode_id
GROUP BY sm.ship_mode_id, sm.ship_mode_name, sm.avg_delivery_days
ORDER BY sm.ship_rating;

-- --------------------------------------------------------
-- QUERY 10: Priority vs Performance
-- --------------------------------------------------------
SELECT 
    op.priority_level,
    op.priority_rank,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(f.quantity) AS units,
    ROUND(SUM(f.sales), 2) AS revenue,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(AVG(f.discount), 4) AS avg_discount,
    ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) AS margin_pct
FROM fact_sales f
JOIN dim_order_priority op ON f.priority_id = op.priority_id
GROUP BY op.priority_id, op.priority_level, op.priority_rank
ORDER BY op.priority_rank;
