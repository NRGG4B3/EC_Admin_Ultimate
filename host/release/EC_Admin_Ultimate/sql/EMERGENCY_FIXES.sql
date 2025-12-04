-- =====================================================
-- EMERGENCY DATABASE FIXES - RUN IF MIGRATIONS FAIL
-- =====================================================
-- Copy this entire SQL and run it directly in your database
-- if the auto-migration system doesn't apply the changes
-- =====================================================

-- FIX 1: Add missing 'category' column
-- This fixes: "Unknown column 'category' in 'field list'"
ALTER TABLE `ec_admin_action_logs` ADD COLUMN IF NOT EXISTS `category` VARCHAR(50) DEFAULT 'general' AFTER `action`;

-- Add index for faster queries on category
ALTER TABLE `ec_admin_action_logs` ADD INDEX IF NOT EXISTS `idx_category` (`category`);

-- FIX 2: Verify all columns exist in ec_admin_action_logs
-- Expected columns: id, admin_identifier, admin_name, action, category, target_identifier, target_name, details, metadata, timestamp, action_type
SHOW COLUMNS FROM `ec_admin_action_logs`;

-- FIX 3: Verify ec_admin_config table structure
-- Should have: id, config_key, config_value, value_type, enabled, updated_by, updated_at, created_at
SHOW COLUMNS FROM `ec_admin_config`;

-- If ec_admin_config looks wrong, you may need to manually check it exists with all columns
-- The auto-migration should have handled this, but verify with the SHOW COLUMNS query above
