-- ============================================================
-- File: 05_rfm_cohort_analysis.sql
-- Purpose: RFM Segmentation and Cohort Retention Analysis
-- ============================================================

USE globalmart_dw;

-- --------------------------------------------------------
-- RFM ANALYSIS
-- Recency, Frequency, Monetary segmentation
-- --------------------------------------------------------

WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.segment,
        DATEDIFF('2015-01-01', MAX(f.order_date)) AS recency,
        COUNT(DISTINCT f.order_id) AS frequency,
        ROUND(SUM(f.sales), 2) AS monetary
    FROM fact_sales f
    JOIN dim_customer c ON f.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name, c.segment
),
rfm_scores AS (
    SELECT 
        *,
        NTILE(4) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency) AS f_score,
        NTILE(4) OVER (ORDER BY monetary) AS m_score
    FROM customer_metrics
)
SELECT 
    customer_name,
    segment,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_segment,
    CASE 
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 2 THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score >= 2 THEN 'Cannot Lose Them'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'Hibernating'
        ELSE 'Lost'
    END AS customer_segment,
    CASE 
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Reward them. Early adopter for new products.'
        WHEN r_score >= 3 AND f_score >= 2 THEN 'Upsell higher value products.'
        WHEN r_score >= 3 AND f_score <= 2 THEN 'Make them familiar, nurture them.'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'Send personalized reactivation campaigns.'
        WHEN r_score <= 2 AND f_score >= 2 THEN 'Win them back via renewals/helpful products.'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'Offer discounts/other products.'
        ELSE 'Ignore them. Not worth the effort.'
    END AS recommended_action
FROM rfm_scores
ORDER BY monetary DESC;

-- --------------------------------------------------------
-- COHORT ANALYSIS
-- Customer retention by first purchase month
-- --------------------------------------------------------

WITH user_first_purchase AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
    FROM fact_sales
    GROUP BY customer_id
),
user_activity AS (
    SELECT 
        f.customer_id,
        ufp.cohort_month,
        DATE_FORMAT(f.order_date, '%Y-%m') AS activity_month,
        PERIOD_DIFF(DATE_FORMAT(f.order_date, '%Y%m'), DATE_FORMAT(ufp.cohort_month, '%Y%m')) AS period_num
    FROM fact_sales f
    JOIN user_first_purchase ufp ON f.customer_id = ufp.customer_id
    GROUP BY f.customer_id, ufp.cohort_month, DATE_FORMAT(f.order_date, '%Y-%m')
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT customer_id) AS total_users
    FROM user_first_purchase
    GROUP BY cohort_month
)
SELECT 
    ca.cohort_month,
    cs.total_users,
    ca.period_num,
    COUNT(DISTINCT ca.customer_id) AS active_users,
    ROUND(COUNT(DISTINCT ca.customer_id) * 100.0 / cs.total_users, 2) AS retention_pct
FROM user_activity ca
JOIN cohort_size cs ON ca.cohort_month = cs.cohort_month
WHERE ca.period_num <= 12
GROUP BY ca.cohort_month, ca.period_num, cs.total_users
ORDER BY ca.cohort_month, ca.period_num;