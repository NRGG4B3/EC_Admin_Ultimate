-- ============================================================================
-- EC Admin Ultimate - Settings Database Schema
-- ============================================================================
-- SQL migration file for settings management tables
-- Run this SQL to create the required tables for the settings system
-- ============================================================================

-- Table: Settings
CREATE TABLE IF NOT EXISTS `ec_settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `category` VARCHAR(50) NOT NULL,
  `setting_key` VARCHAR(100) NOT NULL,
  `setting_value` TEXT,
  `updated_at` BIGINT NOT NULL,
  `updated_by` VARCHAR(50),
  UNIQUE KEY `unique_category_key` (`category`, `setting_key`),
  INDEX `idx_category` (`category`),
  INDEX `idx_setting_key` (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Webhooks
CREATE TABLE IF NOT EXISTS `ec_webhooks` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `url` TEXT NOT NULL,
  `event_type` VARCHAR(50) NOT NULL,
  `enabled` TINYINT(1) DEFAULT 1,
  `method` VARCHAR(10) DEFAULT 'POST',
  `headers` TEXT,
  `format` VARCHAR(20) DEFAULT 'json',
  `retry_count` INT DEFAULT 3,
  `timeout` INT DEFAULT 30,
  `created_at` BIGINT NOT NULL,
  `updated_at` BIGINT NOT NULL,
  INDEX `idx_event_type` (`event_type`),
  INDEX `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Settings Changes Log
CREATE TABLE IF NOT EXISTS `ec_settings_changes_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `category` VARCHAR(50) NOT NULL,
  `setting_key` VARCHAR(100) NOT NULL,
  `old_value` TEXT,
  `new_value` TEXT,
  `created_at` BIGINT NOT NULL,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_category` (`category`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

