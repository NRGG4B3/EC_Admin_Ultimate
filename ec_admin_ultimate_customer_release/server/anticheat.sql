-- ============================================================================
-- EC Admin Ultimate - Anticheat & AI Detection Database Schema
-- ============================================================================
-- SQL migration file for anticheat and AI detection tables
-- Run this SQL to create the required tables for the anticheat system
-- ============================================================================

-- Table: Anticheat Detections
CREATE TABLE IF NOT EXISTS `ec_anticheat_detections` (
  `id` VARCHAR(50) PRIMARY KEY,
  `player_id` VARCHAR(50) NOT NULL,
  `player_name` VARCHAR(100) NOT NULL,
  `type` VARCHAR(50) NOT NULL,
  `category` VARCHAR(50) NOT NULL,
  `severity` VARCHAR(20) DEFAULT 'medium',
  `confidence` DECIMAL(5,2) DEFAULT 0.00,
  `timestamp` BIGINT NOT NULL,
  `location` VARCHAR(255),
  `coords_x` DECIMAL(10,2),
  `coords_y` DECIMAL(10,2),
  `coords_z` DECIMAL(10,2),
  `evidence` TEXT,
  `action` VARCHAR(20) DEFAULT 'none',
  `action_taken` TINYINT(1) DEFAULT 0,
  `ai_analyzed` TINYINT(1) DEFAULT 0,
  `pattern` VARCHAR(100),
  `resolved` TINYINT(1) DEFAULT 0,
  `resolved_by` VARCHAR(50),
  `resolved_at` BIGINT NULL,
  INDEX `idx_player_id` (`player_id`),
  INDEX `idx_type` (`type`),
  INDEX `idx_severity` (`severity`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_resolved` (`resolved`),
  INDEX `idx_action_taken` (`action_taken`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Violation History
CREATE TABLE IF NOT EXISTS `ec_anticheat_violations` (
  `id` VARCHAR(50) PRIMARY KEY,
  `player_id` VARCHAR(50) NOT NULL,
  `player_name` VARCHAR(100) NOT NULL,
  `type` VARCHAR(50) NOT NULL,
  `action` VARCHAR(20) NOT NULL,
  `timestamp` BIGINT NOT NULL,
  `banned_by` VARCHAR(50),
  `banned_by_name` VARCHAR(100),
  `reason` TEXT,
  `details` TEXT,
  INDEX `idx_player_id` (`player_id`),
  INDEX `idx_type` (`type`),
  INDEX `idx_action` (`action`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: AI Patterns
CREATE TABLE IF NOT EXISTS `ec_anticheat_ai_patterns` (
  `id` VARCHAR(50) PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `type` VARCHAR(50) NOT NULL,
  `confidence` DECIMAL(5,2) DEFAULT 0.00,
  `occurrences` INT DEFAULT 1,
  `last_seen` BIGINT NOT NULL,
  `risk` VARCHAR(20) DEFAULT 'low',
  `pattern_data` TEXT,
  INDEX `idx_type` (`type`),
  INDEX `idx_risk` (`risk`),
  INDEX `idx_last_seen` (`last_seen`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Anticheat Configuration
CREATE TABLE IF NOT EXISTS `ec_anticheat_config` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `config_key` VARCHAR(100) UNIQUE NOT NULL,
  `config_value` TEXT,
  `updated_at` BIGINT NOT NULL,
  `updated_by` VARCHAR(50),
  INDEX `idx_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Anticheat Statistics
CREATE TABLE IF NOT EXISTS `ec_anticheat_statistics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `date` DATE NOT NULL,
  `total_detections` INT DEFAULT 0,
  `critical_detections` INT DEFAULT 0,
  `bans_issued` INT DEFAULT 0,
  `kicks_issued` INT DEFAULT 0,
  `warnings_issued` INT DEFAULT 0,
  `ai_analyzed` INT DEFAULT 0,
  UNIQUE KEY `unique_date` (`date`),
  INDEX `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

