-- =====================================================
-- MIGRATION: Add category column to ec_admin_action_logs
-- =====================================================
-- This migration adds the missing 'category' column to the
-- ec_admin_action_logs table. This column tracks the type of
-- admin action that was performed.
-- =====================================================

-- Add category column if it doesn't exist
ALTER TABLE `ec_admin_action_logs` ADD COLUMN IF NOT EXISTS `category` VARCHAR(50) DEFAULT 'general' AFTER `action`;

-- Add index on category for faster queries
ALTER TABLE `ec_admin_action_logs` ADD INDEX IF NOT EXISTS `idx_category` (`category`);

-- Verify table structure
-- SHOW COLUMNS FROM `ec_admin_action_logs`;
