-- ============================================================================
-- EC Admin Ultimate - Quick Actions Schema
-- ============================================================================
-- SQL migration file for quick actions logging
-- Run this SQL to create the required tables for quick actions audit trail
-- ============================================================================

-- Table: Quick Actions Log (audit trail for all quick actions)
CREATE TABLE IF NOT EXISTS `ec_quick_actions_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `action_id` VARCHAR(100) NOT NULL,
  `action_name` VARCHAR(100) NOT NULL,
  `performed_by` VARCHAR(50) NOT NULL,
  `target_player` VARCHAR(50),
  `target_name` VARCHAR(100),
  `action_data` TEXT,
  `success` TINYINT(1) DEFAULT 1,
  `error_message` TEXT,
  `timestamp` BIGINT NOT NULL,
  INDEX `idx_action_id` (`action_id`),
  INDEX `idx_performed_by` (`performed_by`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_target_player` (`target_player`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Quick Actions Statistics (daily statistics)
CREATE TABLE IF NOT EXISTS `ec_quick_actions_statistics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `date` DATE NOT NULL,
  `action_id` VARCHAR(100) NOT NULL,
  `action_name` VARCHAR(100) NOT NULL,
  `usage_count` INT DEFAULT 0,
  `success_count` INT DEFAULT 0,
  `failure_count` INT DEFAULT 0,
  UNIQUE KEY `unique_date_action` (`date`, `action_id`),
  INDEX `idx_date` (`date`),
  INDEX `idx_action_id` (`action_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

