-- ============================================================
-- GLOBALMART DATA WAREHOUSE
-- File: 02_intermediate_queries.sql
-- Purpose: Intermediate SQL queries
-- Skills: JOINs, CASE, Date Functions, RANK(), Subqueries
-- ============================================================

USE globalmart_dw;

-- --------------------------------------------------------
-- QUERY 1: Monthly Sales Trend with Growth Rate
-- --------------------------------------------------------
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(sales) AS revenue,
        SUM(profit) AS profit,
        COUNT(DISTINCT order_id) AS orders
    FROM fact_sales
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(profit, 2) AS profit,
    orders,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2) AS prev_month_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2) AS revenue_change,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) / 
        NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 
        2
    ) AS growth_pct
FROM monthly_sales
ORDER BY month;

-- --------------------------------------------------------
-- QUERY 2: Category Ranking with RANK()
-- --------------------------------------------------------
SELECT 
    cat.category_name,
    sc.subcategory_name,
    ROUND(SUM(f.sales), 2) AS revenue,
    ROUND(SUM(f.profit), 2) AS profit,
    RANK() OVER (PARTITION BY cat.category_name ORDER BY SUM(f.sales) DESC) AS rank_in_category,
    RANK() OVER (ORDER BY SUM(f.sales) DESC) AS overall_rank
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
GROUP BY cat.category_name, sc.subcategory_name
ORDER BY cat.category_name, rank_in_category;

-- --------------------------------------------------------
-- QUERY 3: Profit Margin by Sub-Category
-- --------------------------------------------------------
SELECT 
    cat.category_name,
    sc.subcategory_name,
    ROUND(SUM(f.sales), 2) AS revenue,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS profit_margin_pct,
    CASE 
        WHEN SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100 >= 20 THEN 'Excellent'
        WHEN SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100 >= 10 THEN 'Good'
        WHEN SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100 >= 0 THEN 'Average'
        ELSE 'Loss Making'
    END AS performance_band
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
GROUP BY cat.category_name, sc.subcategory_name
ORDER BY profit_margin_pct DESC;

-- --------------------------------------------------------
-- QUERY 4: Top 5 Products Per Category
-- --------------------------------------------------------
WITH ranked_products AS (
    SELECT 
        cat.category_name,
        p.product_name,
        ROUND(SUM(f.sales), 2) AS revenue,
        RANK() OVER (PARTITION BY cat.category_name ORDER BY SUM(f.sales) DESC) AS rnk
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
    JOIN dim_category cat ON sc.category_id = cat.category_id
    GROUP BY cat.category_name, p.product_id, p.product_name
)
SELECT category_name, product_name, revenue
FROM ranked_products
WHERE rnk <= 5
ORDER BY category_name, rnk;

-- --------------------------------------------------------
-- QUERY 5: Customer Purchase Behavior
-- --------------------------------------------------------
SELECT 
    c.customer_name,
    c.segment,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.quantity) AS total_units,
    ROUND(SUM(f.sales), 2) AS total_spent,
    ROUND(AVG(f.sales), 2) AS avg_order_value,
    ROUND(SUM(f.profit), 2) AS total_profit,
    MIN(f.order_date) AS first_purchase,
    MAX(f.order_date) AS last_purchase,
    DATEDIFF(MAX(f.order_date), MIN(f.order_date)) AS customer_lifespan_days
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.segment
ORDER BY total_spent DESC
LIMIT 20;

-- --------------------------------------------------------
-- QUERY 6: Sales by Day of Week
-- --------------------------------------------------------
SELECT 
    DAYNAME(order_date) AS day_of_week,
    DAYOFWEEK(order_date) AS day_num,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(sales), 2) AS revenue,
    ROUND(AVG(sales), 2) AS avg_order_value
FROM fact_sales
GROUP BY DAYNAME(order_date), DAYOFWEEK(order_date)
ORDER BY day_num;

-- --------------------------------------------------------
-- QUERY 7: High-Value Orders (Above Average)
-- --------------------------------------------------------
WITH avg_order AS (
    SELECT AVG(sales) AS avg_sale_amount FROM fact_sales
)
SELECT 
    f.order_id,
    f.order_date,
    c.customer_name,
    ROUND(f.sales, 2) AS sale_amount,
    ROUND(f.profit, 2) AS profit,
    p.product_name
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
JOIN dim_product p ON f.product_id = p.product_id
CROSS JOIN avg_order
WHERE f.sales > avg_order.avg_sale_amount
ORDER BY f.sales DESC
LIMIT 20;

-- --------------------------------------------------------
-- QUERY 8: Discount Impact Analysis
-- --------------------------------------------------------
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.2 THEN 'Low Discount'
        WHEN discount <= 0.5 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS discount_category,
    COUNT(*) AS transaction_count,
    ROUND(SUM(sales), 2) AS gross_revenue,
    ROUND(SUM(sales * (1 - discount)), 2) AS net_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit), 2) AS avg_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM fact_sales
GROUP BY discount_category
ORDER BY MIN(discount);

-- --------------------------------------------------------
-- QUERY 9: Repeat vs One-Time Customers
-- --------------------------------------------------------
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM fact_sales
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-Time'
        WHEN order_count BETWEEN 2 AND 5 THEN 'Occasional (2-5)'
        WHEN order_count BETWEEN 6 AND 10 THEN 'Regular (6-10)'
        ELSE 'Frequent (11+)'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_customers
FROM customer_orders
GROUP BY customer_type
ORDER BY MIN(order_count);

-- --------------------------------------------------------
-- QUERY 10: Quarterly Performance
-- --------------------------------------------------------
SELECT 
    YEAR(order_date) AS year,
    QUARTER(order_date) AS quarter,
    CONCAT('Q', QUARTER(order_date)) AS quarter_label,
    COUNT(DISTINCT order_id) AS orders,
    SUM(quantity) AS units,
    ROUND(SUM(sales), 2) AS revenue,
    ROUND(SUM(profit), 2) AS profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_pct
FROM fact_sales
GROUP BY YEAR(order_date), QUARTER(order_date)
ORDER BY year, quarter;
