-- ============================================================
-- GLOBALMART DATA WAREHOUSE
-- File: 01_create_database.sql
-- Purpose: Create the database
-- ============================================================

-- Drop if exists (for clean setup)
DROP DATABASE IF EXISTS globalmart_dw;

-- Create database
CREATE DATABASE globalmart_dw
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Use the database
USE globalmart_dw;

SELECT 'Database globalmart_dw created successfully!' AS status;
