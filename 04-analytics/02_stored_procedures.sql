-- ============================================================
-- File: 02_stored_procedures.sql
-- Purpose: Reusable stored procedures for reporting
-- ============================================================

USE globalmart_dw;

DELIMITER //

-- Procedure 1: Sales Report by Date Range
CREATE PROCEDURE sp_sales_report(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        DATE_FORMAT(f.order_date, '%Y-%m') AS month,
        cat.category_name,
        COUNT(DISTINCT f.order_id) AS orders,
        SUM(f.quantity) AS units,
        ROUND(SUM(f.sales), 2) AS revenue,
        ROUND(SUM(f.profit), 2) AS profit
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
    JOIN dim_category cat ON sc.category_id = cat.category_id
    WHERE f.order_date BETWEEN p_start_date AND p_end_date
    GROUP BY month, cat.category_name
    ORDER BY month, revenue DESC;
END //

-- Procedure 2: Customer Ranking
CREATE PROCEDURE sp_customer_ranking(
    IN p_limit INT
)
BEGIN
    SELECT 
        c.customer_name,
        c.segment,
        COUNT(DISTINCT f.order_id) AS orders,
        ROUND(SUM(f.sales), 2) AS total_revenue,
        ROUND(SUM(f.profit), 2) AS total_profit,
        CASE 
            WHEN SUM(f.sales) >= 10000 THEN 'Platinum'
            WHEN SUM(f.sales) >= 5000 THEN 'Gold'
            WHEN SUM(f.sales) >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END AS tier
    FROM fact_sales f
    JOIN dim_customer c ON f.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name, c.segment
    ORDER BY total_revenue DESC
    LIMIT p_limit;
END //

-- Procedure 3: Product Analysis
CREATE PROCEDURE sp_product_analysis(
    IN p_category VARCHAR(100)
)
BEGIN
    SELECT 
        p.product_name,
        sc.subcategory_name,
        cat.category_name,
        SUM(f.quantity) AS units_sold,
        ROUND(SUM(f.sales), 2) AS revenue,
        ROUND(SUM(f.profit), 2) AS profit,
        ROUND(SUM(f.profit)/NULLIF(SUM(f.sales),0)*100, 2) AS margin_pct
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
    JOIN dim_category cat ON sc.category_id = cat.category_id
    WHERE p_category IS NULL OR cat.category_name = p_category
    GROUP BY p.product_id, p.product_name, sc.subcategory_name, cat.category_name
    ORDER BY revenue DESC;
END //

-- Procedure 4: Monthly Trend
CREATE PROCEDURE sp_monthly_trend()
BEGIN
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        COUNT(DISTINCT order_id) AS orders,
        SUM(quantity) AS units,
        ROUND(SUM(sales), 2) AS revenue,
        ROUND(SUM(profit), 2) AS profit,
        ROUND(SUM(profit)/SUM(sales)*100, 2) AS margin_pct
    FROM fact_sales
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
    ORDER BY month;
END //

DELIMITER ;

-- How to call:
-- CALL sp_sales_report('2014-01-01', '2014-12-31');
-- CALL sp_customer_ranking(10);
-- CALL sp_product_analysis('Technology');
-- CALL sp_product_analysis(NULL);
-- CALL sp_monthly_trend();