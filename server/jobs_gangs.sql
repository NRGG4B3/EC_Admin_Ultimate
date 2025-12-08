-- ============================================================================
-- EC Admin Ultimate - Jobs & Gangs Database Schema
-- ============================================================================
-- SQL migration file for jobs and gangs management tables
-- Run this SQL to create the required tables for the jobs & gangs system
-- ============================================================================

-- Table: Jobs Management Log
CREATE TABLE IF NOT EXISTS `ec_jobs_actions_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `action_type` VARCHAR(50) NOT NULL,
  `job_name` VARCHAR(50),
  `player_id` INT,
  `player_identifier` VARCHAR(50),
  `player_name` VARCHAR(100),
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `action_data` TEXT,
  `old_grade` INT,
  `new_grade` INT,
  `reason` TEXT,
  `timestamp` BIGINT NOT NULL,
  `success` TINYINT(1) DEFAULT 1,
  `error_message` TEXT,
  INDEX `idx_job_name` (`job_name`),
  INDEX `idx_player_identifier` (`player_identifier`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Gangs Management Log
CREATE TABLE IF NOT EXISTS `ec_gangs_actions_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `action_type` VARCHAR(50) NOT NULL,
  `gang_name` VARCHAR(50),
  `player_id` INT,
  `player_identifier` VARCHAR(50),
  `player_name` VARCHAR(100),
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `action_data` TEXT,
  `old_rank` INT,
  `new_rank` INT,
  `reason` TEXT,
  `timestamp` BIGINT NOT NULL,
  `success` TINYINT(1) DEFAULT 1,
  `error_message` TEXT,
  INDEX `idx_gang_name` (`gang_name`),
  INDEX `idx_player_identifier` (`player_identifier`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Jobs Statistics
CREATE TABLE IF NOT EXISTS `ec_jobs_statistics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `job_name` VARCHAR(50) NOT NULL,
  `total_employees` INT DEFAULT 0,
  `online_employees` INT DEFAULT 0,
  `total_hires` INT DEFAULT 0,
  `total_fires` INT DEFAULT 0,
  `last_updated` BIGINT NOT NULL,
  UNIQUE KEY `uk_job_name` (`job_name`),
  INDEX `idx_last_updated` (`last_updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Gangs Statistics
CREATE TABLE IF NOT EXISTS `ec_gangs_statistics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `gang_name` VARCHAR(50) NOT NULL,
  `total_members` INT DEFAULT 0,
  `online_members` INT DEFAULT 0,
  `total_recruits` INT DEFAULT 0,
  `total_removals` INT DEFAULT 0,
  `last_updated` BIGINT NOT NULL,
  UNIQUE KEY `uk_gang_name` (`gang_name`),
  INDEX `idx_last_updated` (`last_updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

