-- ============================================================
-- GLOBALMART DATA WAREHOUSE
-- File: 04_window_functions.sql
-- Purpose: Advanced window function queries
-- Skills: ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, NTILE, SUM OVER, AVG OVER
-- ============================================================

USE globalmart_dw;

-- --------------------------------------------------------
-- QUERY 1: Running Total of Sales by Month
-- --------------------------------------------------------
WITH monthly AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(sales) AS monthly_revenue
    FROM fact_sales
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY month), 2) AS running_total,
    ROUND(AVG(monthly_revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3m
FROM monthly
ORDER BY month;

-- --------------------------------------------------------
-- QUERY 2: Top N Products Per Category (ROW_NUMBER)
-- --------------------------------------------------------
WITH ranked AS (
    SELECT 
        cat.category_name,
        p.product_name,
        SUM(f.sales) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY cat.category_name ORDER BY SUM(f.sales) DESC) AS rnk
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
    JOIN dim_category cat ON sc.category_id = cat.category_id
    GROUP BY cat.category_name, p.product_id, p.product_name
)
SELECT category_name, product_name, ROUND(revenue, 2) AS revenue, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY category_name, rnk;

-- --------------------------------------------------------
-- QUERY 3: Customer Quartile Segmentation (NTILE)
-- --------------------------------------------------------
WITH customer_sales AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.segment,
        SUM(f.sales) AS total_sales,
        SUM(f.profit) AS total_profit
    FROM fact_sales f
    JOIN dim_customer c ON f.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name, c.segment
)
SELECT 
    customer_name,
    segment,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(total_profit, 2) AS total_profit,
    NTILE(4) OVER (ORDER BY total_sales DESC) AS sales_quartile,
    NTILE(4) OVER (ORDER BY total_profit DESC) AS profit_quartile,
    CASE 
        WHEN NTILE(4) OVER (ORDER BY total_sales DESC) = 1 THEN 'Top 25%'
        WHEN NTILE(4) OVER (ORDER BY total_sales DESC) = 2 THEN 'Upper Mid 25%'
        WHEN NTILE(4) OVER (ORDER BY total_sales DESC) = 3 THEN 'Lower Mid 25%'
        ELSE 'Bottom 25%'
    END AS sales_tier
FROM customer_sales
ORDER BY total_sales DESC;

-- --------------------------------------------------------
-- QUERY 4: Year-over-Year Growth (LAG)
-- --------------------------------------------------------
WITH yearly AS (
    SELECT 
        YEAR(order_date) AS year,
        SUM(sales) AS revenue,
        SUM(profit) AS profit
    FROM fact_sales
    GROUP BY YEAR(order_date)
)
SELECT 
    year,
    ROUND(revenue, 2) AS revenue,
    ROUND(profit, 2) AS profit,
    ROUND(LAG(revenue) OVER (ORDER BY year), 2) AS prev_year_revenue,
    ROUND(revenue - LAG(revenue) OVER (ORDER BY year), 2) AS revenue_change,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY year)) / NULLIF(LAG(revenue) OVER (ORDER BY year), 0) * 100, 2) AS revenue_growth_pct,
    ROUND(LAG(profit) OVER (ORDER BY year), 2) AS prev_year_profit,
    ROUND((profit - LAG(profit) OVER (ORDER BY year)) / NULLIF(LAG(profit) OVER (ORDER BY year), 0) * 100, 2) AS profit_growth_pct
FROM yearly;

-- --------------------------------------------------------
-- QUERY 5: Month-over-Month Growth by Category
-- --------------------------------------------------------
WITH monthly_cat AS (
    SELECT 
        cat.category_name,
        DATE_FORMAT(f.order_date, '%Y-%m') AS month,
        SUM(f.sales) AS revenue
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
    JOIN dim_category cat ON sc.category_id = cat.category_id
    GROUP BY cat.category_name, DATE_FORMAT(f.order_date, '%Y-%m')
)
SELECT 
    category_name,
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(LAG(revenue) OVER (PARTITION BY category_name ORDER BY month), 2) AS prev_month,
    ROUND(revenue - LAG(revenue) OVER (PARTITION BY category_name ORDER BY month), 2) AS change,
    ROUND((revenue - LAG(revenue) OVER (PARTITION BY category_name ORDER BY month)) / NULLIF(LAG(revenue) OVER (PARTITION BY category_name ORDER BY month), 0) * 100, 2) AS growth_pct
FROM monthly_cat
ORDER BY category_name, month;

-- --------------------------------------------------------
-- QUERY 6: RANK vs DENSE_RANK vs ROW_NUMBER Comparison
-- --------------------------------------------------------
WITH subcat_sales AS (
    SELECT 
        sc.subcategory_name,
        SUM(f.sales) AS revenue
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
    GROUP BY sc.subcategory_name
)
SELECT 
    subcategory_name,
    ROUND(revenue, 2) AS revenue,
    ROW_NUMBER() OVER (ORDER BY revenue DESC) AS row_num,
    RANK() OVER (ORDER BY revenue DESC) AS rank_val,
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS dense_rank_val
FROM subcat_sales
ORDER BY revenue DESC;

-- --------------------------------------------------------
-- QUERY 7: Percent of Total Sales by Customer
-- --------------------------------------------------------
WITH customer_totals AS (
    SELECT 
        c.customer_name,
        c.segment,
        SUM(f.sales) AS customer_revenue
    FROM fact_sales f
    JOIN dim_customer c ON f.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name, c.segment
)
SELECT 
    customer_name,
    segment,
    ROUND(customer_revenue, 2) AS revenue,
    ROUND(SUM(customer_revenue) OVER (), 2) AS total_revenue,
    ROUND(customer_revenue / SUM(customer_revenue) OVER () * 100, 2) AS pct_of_total,
    ROUND(SUM(customer_revenue) OVER (ORDER BY customer_revenue DESC) / SUM(customer_revenue) OVER () * 100, 2) AS cumulative_pct
FROM customer_totals
ORDER BY customer_revenue DESC
LIMIT 20;

-- --------------------------------------------------------
-- QUERY 8: First and Last Purchase per Customer
-- --------------------------------------------------------
SELECT 
    c.customer_name,
    c.segment,
    COUNT(DISTINCT f.order_id) AS total_orders,
    FIRST_VALUE(f.order_date) OVER (PARTITION BY c.customer_id ORDER BY f.order_date) AS first_purchase,
    LAST_VALUE(f.order_date) OVER (PARTITION BY c.customer_id ORDER BY f.order_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_purchase,
    DATEDIFF(
        LAST_VALUE(f.order_date) OVER (PARTITION BY c.customer_id ORDER BY f.order_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
        FIRST_VALUE(f.order_date) OVER (PARTITION BY c.customer_id ORDER BY f.order_date)
    ) AS customer_lifespan_days
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.segment
ORDER BY total_orders DESC
LIMIT 20;

-- --------------------------------------------------------
-- QUERY 9: Sales Distribution by Percentile
-- --------------------------------------------------------
SELECT 
    p.product_name,
    sc.subcategory_name,
    ROUND(SUM(f.sales), 2) AS total_sales,
    PERCENT_RANK() OVER (ORDER BY SUM(f.sales)) AS percentile_rank,
    CASE 
        WHEN PERCENT_RANK() OVER (ORDER BY SUM(f.sales)) >= 0.9 THEN 'Top 10%'
        WHEN PERCENT_RANK() OVER (ORDER BY SUM(f.sales)) >= 0.75 THEN 'Top 25%'
        WHEN PERCENT_RANK() OVER (ORDER BY SUM(f.sales)) >= 0.5 THEN 'Top 50%'
        ELSE 'Bottom 50%'
    END AS performance_tier
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
GROUP BY p.product_id, p.product_name, sc.subcategory_name
ORDER BY total_sales DESC
LIMIT 30;

-- --------------------------------------------------------
-- QUERY 10: Gap Analysis - Days Between Orders per Customer
-- --------------------------------------------------------
WITH customer_orders AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        f.order_date,
        LAG(f.order_date) OVER (PARTITION BY c.customer_id ORDER BY f.order_date) AS prev_order_date
    FROM fact_sales f
    JOIN dim_customer c ON f.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name, f.order_date
)
SELECT 
    customer_name,
    order_date,
    prev_order_date,
    DATEDIFF(order_date, prev_order_date) AS days_between_orders
FROM customer_orders
WHERE prev_order_date IS NOT NULL
ORDER BY days_between_orders DESC
LIMIT 30;
