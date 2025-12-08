-- ============================================================================
-- EC Admin Ultimate - Player Profile Schema
-- ============================================================================
-- SQL migration file for player profile tables
-- Run this SQL to create the required tables for the player profile system
-- ============================================================================

-- Table: Player Profiles (extended player data)
CREATE TABLE IF NOT EXISTS `ec_player_profiles` (
  `identifier` VARCHAR(50) PRIMARY KEY,
  `citizen_id` VARCHAR(50) UNIQUE,
  `phone_number` VARCHAR(20),
  `nationality` VARCHAR(50),
  `birth_date` DATE,
  `gender` VARCHAR(10),
  `metadata` LONGTEXT,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`identifier`) REFERENCES `ec_players`(`identifier`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Player Transactions (transaction history)
CREATE TABLE IF NOT EXISTS `ec_player_transactions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) NOT NULL,
  `type` VARCHAR(50) NOT NULL,
  `amount` DECIMAL(15,2) NOT NULL,
  `balance_after` DECIMAL(15,2) NOT NULL,
  `from_account` VARCHAR(50),
  `to_account` VARCHAR(50),
  `details` TEXT,
  `timestamp` BIGINT NOT NULL,
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_timestamp` (`timestamp`),
  FOREIGN KEY (`identifier`) REFERENCES `ec_players`(`identifier`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Player Activity (activity log)
CREATE TABLE IF NOT EXISTS `ec_player_activity` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) NOT NULL,
  `action` VARCHAR(100) NOT NULL,
  `type` VARCHAR(50),
  `details` TEXT,
  `admin_id` VARCHAR(50),
  `timestamp` BIGINT NOT NULL,
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_timestamp` (`timestamp`),
  FOREIGN KEY (`identifier`) REFERENCES `ec_players`(`identifier`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Player Moderation Notes (admin notes)
CREATE TABLE IF NOT EXISTS `ec_player_moderation_notes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) NOT NULL,
  `note` TEXT NOT NULL,
  `created_by` VARCHAR(50) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_identifier` (`identifier`),
  FOREIGN KEY (`identifier`) REFERENCES `ec_players`(`identifier`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Player Performance (daily performance tracking)
CREATE TABLE IF NOT EXISTS `ec_player_performance` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) NOT NULL,
  `date` DATE NOT NULL,
  `playtime_minutes` INT DEFAULT 0,
  `arrests` INT DEFAULT 0,
  `deaths` INT DEFAULT 0,
  `money_earned` DECIMAL(15,2) DEFAULT 0,
  `money_spent` DECIMAL(15,2) DEFAULT 0,
  UNIQUE KEY `unique_identifier_date` (`identifier`, `date`),
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_date` (`date`),
  FOREIGN KEY (`identifier`) REFERENCES `ec_players`(`identifier`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

