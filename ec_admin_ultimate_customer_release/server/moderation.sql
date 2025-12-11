-- ============================================================================
-- EC Admin Ultimate - Moderation Database Schema
-- ============================================================================
-- SQL migration file for moderation management tables
-- Run this SQL to create the required tables for the moderation system
-- ============================================================================

-- Table: Warnings
CREATE TABLE IF NOT EXISTS `ec_moderation_warnings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `player_id` VARCHAR(50) NOT NULL,
  `player_name` VARCHAR(100) NOT NULL,
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `reason` TEXT NOT NULL,
  `severity` VARCHAR(20) DEFAULT 'medium',
  `points` INT DEFAULT 1,
  `active` TINYINT(1) DEFAULT 1,
  `created_at` BIGINT NOT NULL,
  `expires_at` BIGINT NULL,
  INDEX `idx_player_id` (`player_id`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_active` (`active`),
  INDEX `idx_created_at` (`created_at`),
  INDEX `idx_severity` (`severity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Kicks
CREATE TABLE IF NOT EXISTS `ec_moderation_kicks` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `player_id` VARCHAR(50) NOT NULL,
  `player_name` VARCHAR(100) NOT NULL,
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `reason` TEXT NOT NULL,
  `created_at` BIGINT NOT NULL,
  INDEX `idx_player_id` (`player_id`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Mutes
CREATE TABLE IF NOT EXISTS `ec_moderation_mutes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `player_id` VARCHAR(50) NOT NULL,
  `player_name` VARCHAR(100) NOT NULL,
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `reason` TEXT NOT NULL,
  `duration` INT NOT NULL,
  `active` TINYINT(1) DEFAULT 1,
  `created_at` BIGINT NOT NULL,
  `expires_at` BIGINT NULL,
  INDEX `idx_player_id` (`player_id`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_active` (`active`),
  INDEX `idx_created_at` (`created_at`),
  INDEX `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Reports
CREATE TABLE IF NOT EXISTS `ec_moderation_reports` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `reporter_id` VARCHAR(50) NOT NULL,
  `reporter_name` VARCHAR(100) NOT NULL,
  `reported_id` VARCHAR(50) NOT NULL,
  `reported_name` VARCHAR(100) NOT NULL,
  `reason` TEXT NOT NULL,
  `category` VARCHAR(50) DEFAULT 'other',
  `status` VARCHAR(20) DEFAULT 'pending',
  `assigned_to` VARCHAR(50) NULL,
  `assigned_name` VARCHAR(100) NULL,
  `resolution` TEXT NULL,
  `created_at` BIGINT NOT NULL,
  `updated_at` BIGINT NOT NULL,
  INDEX `idx_reporter_id` (`reporter_id`),
  INDEX `idx_reported_id` (`reported_id`),
  INDEX `idx_status` (`status`),
  INDEX `idx_assigned_to` (`assigned_to`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Moderation Action Logs
CREATE TABLE IF NOT EXISTS `ec_moderation_action_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `action_type` VARCHAR(50) NOT NULL,
  `target_id` VARCHAR(50) NULL,
  `target_name` VARCHAR(100) NULL,
  `reason` TEXT NULL,
  `details` TEXT NULL,
  `created_at` BIGINT NOT NULL,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_target_id` (`target_id`),
  INDEX `idx_action_type` (`action_type`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

