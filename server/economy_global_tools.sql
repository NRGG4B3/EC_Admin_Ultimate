-- ============================================================================
-- EC Admin Ultimate - Economy & Global Tools Schema
-- ============================================================================
-- SQL migration file for economy management and global tools
-- Run this SQL to create the required tables for economy and global tools
-- ============================================================================

-- Table: Economy Data (cached player wealth data)
CREATE TABLE IF NOT EXISTS `ec_economy_data` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) NOT NULL,
  `cash` DECIMAL(15,2) DEFAULT 0,
  `bank` DECIMAL(15,2) DEFAULT 0,
  `crypto` DECIMAL(15,2) DEFAULT 0,
  `total_wealth` DECIMAL(15,2) DEFAULT 0,
  `job` VARCHAR(50),
  `last_updated` BIGINT NOT NULL,
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_total_wealth` (`total_wealth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Economy Transactions (transaction history)
CREATE TABLE IF NOT EXISTS `ec_economy_transactions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `transaction_id` VARCHAR(50) UNIQUE,
  `from_identifier` VARCHAR(50),
  `from_name` VARCHAR(100),
  `to_identifier` VARCHAR(50),
  `to_name` VARCHAR(100),
  `amount` DECIMAL(15,2) NOT NULL,
  `type` VARCHAR(50) NOT NULL,
  `reason` TEXT,
  `status` VARCHAR(20) DEFAULT 'completed',
  `suspicious` TINYINT(1) DEFAULT 0,
  `timestamp` BIGINT NOT NULL,
  INDEX `idx_from_identifier` (`from_identifier`),
  INDEX `idx_to_identifier` (`to_identifier`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_type` (`type`),
  INDEX `idx_suspicious` (`suspicious`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Economy Actions Log (admin economy actions audit trail)
CREATE TABLE IF NOT EXISTS `ec_economy_actions_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `action` VARCHAR(100) NOT NULL,
  `performed_by` VARCHAR(50) NOT NULL,
  `target_player` VARCHAR(50),
  `target_name` VARCHAR(100),
  `amount` DECIMAL(15,2),
  `account_type` VARCHAR(20),
  `details` TEXT,
  `timestamp` BIGINT NOT NULL,
  INDEX `idx_action` (`action`),
  INDEX `idx_performed_by` (`performed_by`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Server Settings (server settings persistence)
CREATE TABLE IF NOT EXISTS `ec_server_settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `setting_key` VARCHAR(100) UNIQUE NOT NULL,
  `setting_value` TEXT,
  `category` VARCHAR(50),
  `updated_by` VARCHAR(50),
  `updated_at` BIGINT NOT NULL,
  INDEX `idx_category` (`category`),
  INDEX `idx_key` (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Economy Statistics (daily economy statistics)
CREATE TABLE IF NOT EXISTS `ec_economy_statistics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `date` DATE NOT NULL,
  `total_cash` DECIMAL(15,2) DEFAULT 0,
  `total_bank` DECIMAL(15,2) DEFAULT 0,
  `total_crypto` DECIMAL(15,2) DEFAULT 0,
  `total_wealth` DECIMAL(15,2) DEFAULT 0,
  `average_wealth` DECIMAL(15,2) DEFAULT 0,
  `total_transactions` INT DEFAULT 0,
  `suspicious_transactions` INT DEFAULT 0,
  `suspicious_players` INT DEFAULT 0,
  UNIQUE KEY `unique_date` (`date`),
  INDEX `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

