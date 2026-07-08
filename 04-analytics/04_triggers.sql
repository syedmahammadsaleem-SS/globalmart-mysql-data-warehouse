-- ============================================================
-- File: 04_triggers.sql
-- Purpose: Triggers for data validation and audit logging
-- ============================================================

USE globalmart_dw;

-- --------------------------------------------------------
-- TRIGGER 1: Validate sales data before insert
-- --------------------------------------------------------
DELIMITER //

CREATE TRIGGER trg_validate_sales
BEFORE INSERT ON fact_sales
FOR EACH ROW
BEGIN
    -- Prevent negative sales
    IF NEW.sales < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Sales amount cannot be negative';
    END IF;
    
    -- Prevent invalid dates
    IF NEW.ship_date < NEW.order_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Ship date cannot be before order date';
    END IF;
    
    -- Prevent discount > 100%
    IF NEW.discount > 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Discount cannot exceed 100%';
    END IF;
END //

-- --------------------------------------------------------
-- TRIGGER 2: Audit log for sales updates
-- --------------------------------------------------------
CREATE TRIGGER trg_audit_sales_update
AFTER UPDATE ON fact_sales
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name,
        action_type,
        record_id,
        old_value,
        new_value,
        changed_at
    ) VALUES (
        'fact_sales',
        'UPDATE',
        NEW.sale_id,
        CONCAT('Sales: ', OLD.sales, ', Profit: ', OLD.profit),
        CONCAT('Sales: ', NEW.sales, ', Profit: ', NEW.profit),
        NOW()
    );
END //

-- --------------------------------------------------------
-- TRIGGER 3: Audit log for sales deletes
-- --------------------------------------------------------
CREATE TRIGGER trg_audit_sales_delete
AFTER DELETE ON fact_sales
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name,
        action_type,
        record_id,
        old_value,
        changed_at
    ) VALUES (
        'fact_sales',
        'DELETE',
        OLD.sale_id,
        CONCAT('Deleted sales record: ', OLD.sales),
        NOW()
    );
END //

DELIMITER ;

-- Note: Create audit_log table first if not exists:
/*
CREATE TABLE audit_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50),
    action_type VARCHAR(20),
    record_id INT,
    old_value TEXT,
    new_value TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
*/