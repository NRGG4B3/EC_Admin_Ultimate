-- ============================================================================
-- EC Admin Ultimate - Housing Management Database Schema
-- ============================================================================
-- SQL migration file for housing management tables
-- Run this SQL to create the required tables for the housing system
-- ============================================================================

-- Table: Housing Actions Log
CREATE TABLE IF NOT EXISTS `ec_housing_actions_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `action_type` VARCHAR(50) NOT NULL,
  `property_id` VARCHAR(50),
  `property_name` VARCHAR(100),
  `old_owner` VARCHAR(50),
  `old_owner_name` VARCHAR(100),
  `new_owner` VARCHAR(50),
  `new_owner_name` VARCHAR(100),
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `old_price` DECIMAL(15,2),
  `new_price` DECIMAL(15,2),
  `action_data` TEXT,
  `reason` TEXT,
  `timestamp` BIGINT NOT NULL,
  `success` TINYINT(1) DEFAULT 1,
  `error_message` TEXT,
  INDEX `idx_property_id` (`property_id`),
  INDEX `idx_old_owner` (`old_owner`),
  INDEX `idx_new_owner` (`new_owner`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_action_type` (`action_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Housing Statistics
CREATE TABLE IF NOT EXISTS `ec_housing_statistics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `total_properties` INT DEFAULT 0,
  `owned_properties` INT DEFAULT 0,
  `vacant_properties` INT DEFAULT 0,
  `total_value` DECIMAL(15,2) DEFAULT 0,
  `active_rentals` INT DEFAULT 0,
  `monthly_rent_income` DECIMAL(15,2) DEFAULT 0,
  `last_updated` BIGINT NOT NULL,
  INDEX `idx_last_updated` (`last_updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

