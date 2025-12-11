-- ============================================================================
-- EC Admin Ultimate - Whitelist Database Schema
-- ============================================================================
-- SQL migration file for whitelist management tables
-- Run this SQL to create the required tables for the whitelist system
-- ============================================================================

-- Table: Whitelist Entries
CREATE TABLE IF NOT EXISTS `ec_whitelist_entries` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) NOT NULL UNIQUE,
  `name` VARCHAR(100) NOT NULL,
  `steam_id` VARCHAR(50),
  `license` VARCHAR(50),
  `discord_id` VARCHAR(50),
  `ip_address` VARCHAR(45),
  `roles` TEXT,
  `status` VARCHAR(20) DEFAULT 'active',
  `added_by` VARCHAR(50) NOT NULL,
  `added_at` BIGINT NOT NULL,
  `priority` VARCHAR(20) DEFAULT 'normal',
  `notes` TEXT,
  `expires_at` BIGINT NULL,
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_steam_id` (`steam_id`),
  INDEX `idx_license` (`license`),
  INDEX `idx_discord_id` (`discord_id`),
  INDEX `idx_status` (`status`),
  INDEX `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Whitelist Applications
CREATE TABLE IF NOT EXISTS `ec_whitelist_applications` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) NOT NULL,
  `applicant_name` VARCHAR(100) NOT NULL,
  `steam_id` VARCHAR(50),
  `license` VARCHAR(50),
  `discord_id` VARCHAR(50),
  `discord_tag` VARCHAR(100),
  `age` INT,
  `reason` TEXT,
  `experience` TEXT,
  `referral` VARCHAR(100),
  `status` VARCHAR(20) DEFAULT 'pending',
  `submitted_at` BIGINT NOT NULL,
  `reviewed_by` VARCHAR(50),
  `reviewed_by_name` VARCHAR(100),
  `reviewed_at` BIGINT NULL,
  `deny_reason` TEXT,
  `application_data` TEXT,
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_status` (`status`),
  INDEX `idx_submitted_at` (`submitted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Whitelist Roles
CREATE TABLE IF NOT EXISTS `ec_whitelist_roles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL UNIQUE,
  `display_name` VARCHAR(100) NOT NULL,
  `priority` INT DEFAULT 50,
  `color` VARCHAR(7) DEFAULT '#3b82f6',
  `permissions` TEXT,
  `is_default` TINYINT(1) DEFAULT 0,
  `created_at` BIGINT NOT NULL,
  INDEX `idx_name` (`name`),
  INDEX `idx_priority` (`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Whitelist Actions Log
CREATE TABLE IF NOT EXISTS `ec_whitelist_actions_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `action_type` VARCHAR(50) NOT NULL,
  `target_type` VARCHAR(50),
  `target_id` INT,
  `target_identifier` VARCHAR(50),
  `target_name` VARCHAR(100),
  `details` TEXT,
  `created_at` BIGINT NOT NULL,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_action_type` (`action_type`),
  INDEX `idx_target_type` (`target_type`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Player Join Attempts (for tracking failed joins)
CREATE TABLE IF NOT EXISTS `ec_whitelist_join_attempts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50),
  `name` VARCHAR(100),
  `steam_id` VARCHAR(50),
  `license` VARCHAR(50),
  `discord_id` VARCHAR(50),
  `ip_address` VARCHAR(45),
  `result` VARCHAR(20) NOT NULL,
  `reason` TEXT,
  `attempted_at` BIGINT NOT NULL,
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_result` (`result`),
  INDEX `idx_attempted_at` (`attempted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

