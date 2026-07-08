-- ============================================================
-- GLOBALMART DATA WAREHOUSE
-- File: 05_executive_reports.sql
-- Purpose: Executive-level business reports and insights
-- Skills: Complex CTEs, Business Logic, KPIs, Recommendations
-- ============================================================

USE globalmart_dw;

-- --------------------------------------------------------
-- REPORT 1: Executive Summary Dashboard
-- --------------------------------------------------------
WITH yearly_summary AS (
    SELECT 
        YEAR(order_date) AS year,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(quantity) AS total_units,
        ROUND(SUM(sales), 2) AS total_revenue,
        ROUND(SUM(profit), 2) AS total_profit,
        COUNT(DISTINCT customer_id) AS unique_customers,
        ROUND(AVG(sales), 2) AS avg_order_value
    FROM fact_sales
    GROUP BY YEAR(order_date)
)
SELECT 
    year,
    total_orders,
    total_units,
    total_revenue,
    total_profit,
    ROUND(total_profit / total_revenue * 100, 2) AS profit_margin_pct,
    unique_customers,
    avg_order_value,
    ROUND(total_revenue / total_orders, 2) AS revenue_per_order,
    ROUND(total_revenue / unique_customers, 2) AS revenue_per_customer
FROM yearly_summary
ORDER BY year;

-- --------------------------------------------------------
-- REPORT 2: Product Discontinuation Recommendations
-- --------------------------------------------------------
SELECT 
    p.product_name,
    sc.subcategory_name,
    cat.category_name,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.sales), 2) AS total_sales,
    ROUND(SUM(f.profit), 2) AS total_profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100, 2) AS margin_pct,
    MAX(f.order_date) AS last_sale_date,
    DATEDIFF('2015-01-01', MAX(f.order_date)) AS days_since_last_sale,
    CASE 
        WHEN SUM(f.profit) < 0 THEN 'DISCONTINUE - Loss Maker'
        WHEN MAX(f.order_date) < '2013-01-01' THEN 'DISCONTINUE - No Recent Sales'
        WHEN SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100 < 5 THEN 'REVIEW - Low Margin'
        ELSE 'KEEP'
    END AS recommendation,
    CASE 
        WHEN SUM(f.profit) < 0 THEN 'Immediate'
        WHEN MAX(f.order_date) < '2013-01-01' THEN 'Within 90 days'
        WHEN SUM(f.profit) / NULLIF(SUM(f.sales), 0) * 100 < 5 THEN 'Within 6 months'
        ELSE 'N/A'
    END AS action_timeline
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
GROUP BY p.product_id, p.product_name, sc.subcategory_name, cat.category_name
HAVING recommendation != 'KEEP'
ORDER BY total_profit ASC
LIMIT 30;

-- --------------------------------------------------------
-- REPORT 3: Regional Performance Matrix
-- --------------------------------------------------------
SELECT 
    m.market_name,
    l.region,
    l.country,
    COUNT(DISTINCT f.customer_id) AS customers,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(f.quantity) AS units,
    ROUND(SUM(f.sales), 2) AS revenue,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) AS margin_pct,
    ROUND(SUM(f.sales) / COUNT(DISTINCT f.customer_id), 2) AS revenue_per_customer,
    ROUND(SUM(f.sales) / COUNT(DISTINCT f.order_id), 2) AS avg_order_value,
    CASE 
        WHEN SUM(f.profit) / SUM(f.sales) * 100 >= 15 THEN 'Star Region'
        WHEN SUM(f.profit) / SUM(f.sales) * 100 >= 10 THEN 'Growth Region'
        WHEN SUM(f.profit) / SUM(f.sales) * 100 >= 5 THEN 'Stable Region'
        ELSE 'Underperforming'
    END AS region_status
FROM fact_sales f
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_market m ON l.market_id = m.market_id
GROUP BY m.market_name, l.region, l.country
ORDER BY profit DESC;

-- --------------------------------------------------------
-- REPORT 4: Customer Retention Analysis
-- --------------------------------------------------------
WITH first_purchase AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date,
        YEAR(MIN(order_date)) AS acquisition_year
    FROM fact_sales
    GROUP BY customer_id
),
customer_activity AS (
    SELECT 
        f.customer_id,
        fp.first_order_date,
        fp.acquisition_year,
        COUNT(DISTINCT f.order_id) AS total_orders,
        MAX(f.order_date) AS last_order_date,
        DATEDIFF('2015-01-01', MAX(f.order_date)) AS days_since_last,
        ROUND(SUM(f.sales), 2) AS lifetime_value
    FROM fact_sales f
    JOIN first_purchase fp ON f.customer_id = fp.customer_id
    GROUP BY f.customer_id, fp.first_order_date, fp.acquisition_year
)
SELECT 
    acquisition_year,
    COUNT(*) AS customers_acquired,
    ROUND(AVG(total_orders), 1) AS avg_orders_per_customer,
    ROUND(AVG(lifetime_value), 2) AS avg_lifetime_value,
    ROUND(AVG(days_since_last), 1) AS avg_days_since_last,
    SUM(CASE WHEN days_since_last <= 90 THEN 1 ELSE 0 END) AS active_customers,
    SUM(CASE WHEN days_since_last > 90 AND days_since_last <= 180 THEN 1 ELSE 0 END) AS at_risk_customers,
    SUM(CASE WHEN days_since_last > 180 THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN days_since_last <= 90 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS active_rate_pct
FROM customer_activity
GROUP BY acquisition_year
ORDER BY acquisition_year;

-- --------------------------------------------------------
-- REPORT 5: Seasonal Sales Patterns
-- --------------------------------------------------------
SELECT 
    MONTHNAME(order_date) AS month_name,
    MONTH(order_date) AS month_num,
    COUNT(DISTINCT order_id) AS orders,
    SUM(quantity) AS units,
    ROUND(SUM(sales), 2) AS revenue,
    ROUND(SUM(profit), 2) AS profit,
    ROUND(AVG(sales), 2) AS avg_order_value,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_pct,
    CASE 
        WHEN MONTH(order_date) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(order_date) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(order_date) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END AS season
FROM fact_sales
GROUP BY MONTH(order_date), MONTHNAME(order_date)
ORDER BY month_num;

-- --------------------------------------------------------
-- REPORT 6: Discount Impact on Profitability
-- --------------------------------------------------------
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.1 THEN '0-10%'
        WHEN discount <= 0.2 THEN '11-20%'
        WHEN discount <= 0.3 THEN '21-30%'
        WHEN discount <= 0.5 THEN '31-50%'
        ELSE '50%+'
    END AS discount_band,
    COUNT(*) AS transactions,
    ROUND(SUM(sales), 2) AS gross_revenue,
    ROUND(SUM(sales * (1 - discount)), 2) AS net_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit), 2) AS avg_profit_per_transaction,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_pct,
    CASE 
        WHEN SUM(profit) / SUM(sales) * 100 < 0 THEN 'PROFIT DESTROYING'
        WHEN SUM(profit) / SUM(sales) * 100 < 5 THEN 'MARGIN ERODING'
        ELSE 'ACCEPTABLE'
    END AS discount_health
FROM fact_sales
GROUP BY discount_band
ORDER BY MIN(discount);

-- --------------------------------------------------------
-- REPORT 7: Category Performance Scorecard
-- --------------------------------------------------------
WITH cat_metrics AS (
    SELECT 
        cat.category_name,
        COUNT(DISTINCT f.order_id) AS orders,
        SUM(f.quantity) AS units,
        ROUND(SUM(f.sales), 2) AS revenue,
        ROUND(SUM(f.profit), 2) AS profit,
        ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) AS margin_pct,
        COUNT(DISTINCT p.product_id) AS products_sold,
        COUNT(DISTINCT f.customer_id) AS unique_customers
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
    JOIN dim_category cat ON sc.category_id = cat.category_id
    GROUP BY cat.category_name
)
SELECT 
    category_name,
    orders,
    units,
    revenue,
    profit,
    margin_pct,
    products_sold,
    unique_customers,
    ROUND(revenue / orders, 2) AS avg_order_value,
    ROUND(revenue / unique_customers, 2) AS revenue_per_customer,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    RANK() OVER (ORDER BY margin_pct DESC) AS margin_rank,
    CASE 
        WHEN RANK() OVER (ORDER BY revenue DESC) <= 2 AND RANK() OVER (ORDER BY margin_pct DESC) <= 2 THEN 'STAR'
        WHEN RANK() OVER (ORDER BY revenue DESC) <= 2 THEN 'CASH COW'
        WHEN RANK() OVER (ORDER BY margin_pct DESC) <= 2 THEN 'HIGH MARGIN'
        ELSE 'REVIEW NEEDED'
    END AS category_status
FROM cat_metrics;

-- --------------------------------------------------------
-- REPORT 8: Shipping Cost Optimization
-- --------------------------------------------------------
SELECT 
    sm.ship_mode_name,
    COUNT(*) AS shipments,
    ROUND(SUM(f.shipping_cost), 2) AS total_shipping_cost,
    ROUND(AVG(f.shipping_cost), 2) AS avg_shipping_cost,
    ROUND(SUM(f.sales), 2) AS revenue_shipped,
    ROUND(SUM(f.shipping_cost) / SUM(f.sales) * 100, 2) AS shipping_cost_pct_of_revenue,
    ROUND(AVG(DATEDIFF(f.ship_date, f.order_date)), 1) AS avg_delivery_days,
    ROUND(SUM(f.profit), 2) AS profit,
    CASE 
        WHEN SUM(f.shipping_cost) / SUM(f.sales) * 100 > 15 THEN 'HIGH COST - Review'
        WHEN SUM(f.shipping_cost) / SUM(f.sales) * 100 > 10 THEN 'MODERATE - Monitor'
        ELSE 'EFFICIENT'
    END AS shipping_efficiency
FROM fact_sales f
JOIN dim_ship_mode sm ON f.ship_mode_id = sm.ship_mode_id
GROUP BY sm.ship_mode_id, sm.ship_mode_name
ORDER BY shipping_cost_pct_of_revenue;

-- --------------------------------------------------------
-- REPORT 9: Market Share Analysis
-- --------------------------------------------------------
WITH market_totals AS (
    SELECT 
        m.market_name,
        SUM(f.sales) AS market_revenue
    FROM fact_sales f
    JOIN dim_location l ON f.location_id = l.location_id
    JOIN dim_market m ON l.market_id = m.market_id
    GROUP BY m.market_name
),
total AS (
    SELECT SUM(sales) AS grand_total FROM fact_sales
)
SELECT 
    mt.market_name,
    ROUND(mt.market_revenue, 2) AS revenue,
    ROUND(mt.market_revenue / t.grand_total * 100, 2) AS market_share_pct,
    ROUND(SUM(mt.market_revenue) OVER (ORDER BY mt.market_revenue DESC) / t.grand_total * 100, 2) AS cumulative_share_pct,
    CASE 
        WHEN mt.market_revenue / t.grand_total * 100 >= 30 THEN 'Dominant'
        WHEN mt.market_revenue / t.grand_total * 100 >= 15 THEN 'Major'
        WHEN mt.market_revenue / t.grand_total * 100 >= 5 THEN 'Significant'
        ELSE 'Emerging'
    END AS market_position
FROM market_totals mt
CROSS JOIN total t
ORDER BY revenue DESC;

-- --------------------------------------------------------
-- REPORT 10: Profitability Deep Dive - Loss Analysis
-- --------------------------------------------------------
SELECT 
    cat.category_name,
    sc.subcategory_name,
    p.product_name,
    COUNT(*) AS transactions,
    SUM(f.quantity) AS units,
    ROUND(SUM(f.sales), 2) AS revenue,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / SUM(f.sales) * 100, 2) AS margin_pct,
    SUM(CASE WHEN f.profit < 0 THEN 1 ELSE 0 END) AS loss_transactions,
    SUM(CASE WHEN f.profit < 0 THEN f.profit ELSE 0 END) AS total_losses,
    ROUND(SUM(CASE WHEN f.profit < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS loss_rate_pct,
    CASE 
        WHEN SUM(f.profit) < 0 THEN 'LOSS MAKER'
        WHEN SUM(CASE WHEN f.profit < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 30 THEN 'HIGH RISK'
        ELSE 'PROFITABLE'
    END AS product_health
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
JOIN dim_subcategory sc ON p.subcategory_id = sc.subcategory_id
JOIN dim_category cat ON sc.category_id = cat.category_id
GROUP BY p.product_id, p.product_name, sc.subcategory_name, cat.category_name
HAVING product_health != 'PROFITABLE'
ORDER BY total_losses ASC
LIMIT 30;
