-- ============================================================================
-- EC Admin Ultimate - System Management Database Schema
-- ============================================================================
-- SQL migration file for system management tables
-- Run this SQL to create the required tables for the system management system
-- ============================================================================

-- Table: System Actions Log
CREATE TABLE IF NOT EXISTS `ec_system_actions_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `action_type` VARCHAR(50) NOT NULL, -- e.g., 'start_resource', 'stop_resource', 'restart_resource', 'announcement', 'kick_all', 'clear_cache', 'database_cleanup'
  `target` VARCHAR(255), -- Resource name, player count, etc.
  `details` TEXT, -- JSON object for action-specific details
  `success` TINYINT(1) DEFAULT 1,
  `error_message` TEXT,
  `created_at` BIGINT NOT NULL,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_action_type` (`action_type`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Console Logs
CREATE TABLE IF NOT EXISTS `ec_system_console_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `log_type` VARCHAR(20) NOT NULL, -- info, warning, error, debug
  `message` TEXT NOT NULL,
  `source` VARCHAR(100), -- Resource name or system
  `created_at` BIGINT NOT NULL,
  INDEX `idx_log_type` (`log_type`),
  INDEX `idx_source` (`source`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Scheduled Restarts
CREATE TABLE IF NOT EXISTS `ec_system_scheduled_restarts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `scheduled_by` VARCHAR(50) NOT NULL,
  `scheduled_by_name` VARCHAR(100) NOT NULL,
  `scheduled_at` BIGINT NOT NULL,
  `reason` TEXT,
  `completed` TINYINT(1) DEFAULT 0,
  `completed_at` BIGINT NULL,
  `created_at` BIGINT NOT NULL,
  INDEX `idx_scheduled_at` (`scheduled_at`),
  INDEX `idx_completed` (`completed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: System Statistics
CREATE TABLE IF NOT EXISTS `ec_system_statistics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `date` DATE NOT NULL,
  `total_resources` INT DEFAULT 0,
  `running_resources` INT DEFAULT 0,
  `stopped_resources` INT DEFAULT 0,
  `total_actions` INT DEFAULT 0,
  `peak_players` INT DEFAULT 0,
  `average_uptime` BIGINT DEFAULT 0,
  `memory_usage_mb` DECIMAL(10,2) DEFAULT 0,
  UNIQUE KEY `unique_date` (`date`),
  INDEX `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

