-- EC Admin Ultimate - Missing Schema Fix
-- Date: November 9, 2025
-- Purpose: Add missing admin_profiles table and ec_admin_bans.expires column

-- Create admin_profiles table (used by admin uptime tracking)
CREATE TABLE IF NOT EXISTS `admin_profiles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(64) NOT NULL UNIQUE,
  `name` VARCHAR(64) DEFAULT NULL,
  `status` ENUM('active','inactive') NOT NULL DEFAULT 'inactive',
  `uptime` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `identifier_idx` (`identifier`),
  INDEX `status_idx` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add expires column to ec_admin_bans if it doesn't exist
-- Check if column exists first
SET @dbname = DATABASE();
SET @tablename = 'ec_admin_bans';
SET @columnname = 'expires';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      TABLE_SCHEMA = @dbname
      AND TABLE_NAME = @tablename
      AND COLUMN_NAME = @columnname
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN `', @columnname, '` TIMESTAMP NULL DEFAULT NULL AFTER `reason`')
));

PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Add index on expires for faster ban expiry queries
SET @preparedStatement2 = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      TABLE_SCHEMA = @dbname
      AND TABLE_NAME = @tablename
      AND INDEX_NAME = 'expires_idx'
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD INDEX `expires_idx` (`expires`)')
));

PREPARE alterIfNotExists2 FROM @preparedStatement2;
EXECUTE alterIfNotExists2;
DEALLOCATE PREPARE alterIfNotExists2;
