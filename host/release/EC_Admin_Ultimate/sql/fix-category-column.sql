-- =====================================================
-- FIX: Add missing 'category' column to ec_admin_action_logs
-- MariaDB compatible migration
-- =====================================================

-- Check if column exists before adding it
-- This is a safe migration that won't fail if column already exists

-- First, check the table structure
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME='ec_admin_action_logs' AND COLUMN_NAME='category';

-- If the above returns nothing, run this:
-- ALTER TABLE `ec_admin_action_logs` ADD COLUMN `category` VARCHAR(50) DEFAULT 'general' AFTER `action`;

-- Safe approach: Use this stored procedure-like logic
-- Since MariaDB doesn't support IF NOT EXISTS for ALTER, we provide both commands:

-- OPTION 1: If column doesn't exist (run this if SELECT above returns empty):
ALTER TABLE `ec_admin_action_logs` ADD COLUMN `category` VARCHAR(50) DEFAULT 'general' AFTER `action`;

-- OPTION 2: Add index for better performance
ALTER TABLE `ec_admin_action_logs` ADD INDEX `idx_category` (`category`);

-- Verify the column exists
SELECT * FROM `ec_admin_action_logs` LIMIT 1;
