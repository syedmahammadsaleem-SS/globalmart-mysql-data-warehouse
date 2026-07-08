-- ============================================================
-- File: 03_functions.sql
-- Purpose: User-defined functions for reusable calculations
-- ============================================================

USE globalmart_dw;

DELIMITER //

-- Function 1: Calculate Profit Margin Percentage
CREATE FUNCTION fn_profit_margin(
    p_sales DECIMAL(12,2),
    p_profit DECIMAL(12,2)
)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    IF p_sales = 0 OR p_sales IS NULL THEN
        RETURN 0.00;
    END IF;
    RETURN ROUND(p_profit / p_sales * 100, 2);
END //

-- Function 2: Customer Tier Classification
CREATE FUNCTION fn_customer_tier(
    p_sales DECIMAL(12,2)
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    IF p_sales >= 10000 THEN RETURN 'Platinum';
    ELSEIF p_sales >= 5000 THEN RETURN 'Gold';
    ELSEIF p_sales >= 1000 THEN RETURN 'Silver';
    ELSE RETURN 'Bronze';
    END IF;
END //

-- Function 3: Shipping Rating
CREATE FUNCTION fn_ship_rating(
    p_actual_days INT,
    p_expected_days INT
)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    IF p_actual_days <= p_expected_days THEN RETURN 'On Time';
    ELSEIF p_actual_days <= p_expected_days + 1 THEN RETURN 'Slight Delay';
    ELSEIF p_actual_days <= p_expected_days + 3 THEN RETURN 'Delayed';
    ELSE RETURN 'Significantly Delayed';
    END IF;
END //

DELIMITER ;

-- How to use:
-- SELECT fn_profit_margin(1000, 150);  -- Returns 15.00
-- SELECT fn_customer_tier(7500);       -- Returns 'Gold'
-- SELECT fn_ship_rating(5, 4);        -- Returns 'Slight Delay'