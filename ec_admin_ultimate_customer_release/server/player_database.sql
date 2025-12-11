-- ============================================================================
-- EC Admin Ultimate - Player Database Schema
-- ============================================================================
-- SQL migration file for player database tables
-- Run this SQL to create the required tables for the player database system
-- ============================================================================

-- Table: Players
CREATE TABLE IF NOT EXISTS `ec_players` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) UNIQUE NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `steamid` VARCHAR(50),
  `license` VARCHAR(50),
  `discord` VARCHAR(50),
  `fivem` VARCHAR(50),
  `ip` VARCHAR(45),
  `hwid` VARCHAR(100),
  `playtime` INT DEFAULT 0,
  `last_seen` BIGINT,
  `join_date` BIGINT,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_steamid` (`steamid`),
  INDEX `idx_last_seen` (`last_seen`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Player History (24-hour player count tracking)
CREATE TABLE IF NOT EXISTS `ec_player_history` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `hour` INT NOT NULL,
  `date` DATE NOT NULL,
  `player_count` INT DEFAULT 0,
  `peak_count` INT DEFAULT 0,
  `timestamp` BIGINT NOT NULL,
  UNIQUE KEY `unique_hour_date` (`hour`, `date`),
  INDEX `idx_date` (`date`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Player Sessions (track playtime)
CREATE TABLE IF NOT EXISTS `ec_player_sessions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) NOT NULL,
  `source` INT NOT NULL,
  `login_time` BIGINT NOT NULL,
  `logout_time` BIGINT,
  `playtime_minutes` INT DEFAULT 0,
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_source` (`source`),
  INDEX `idx_login_time` (`login_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Player Stats (cached statistics)
CREATE TABLE IF NOT EXISTS `ec_player_stats` (
  `identifier` VARCHAR(50) PRIMARY KEY,
  `total_playtime` INT DEFAULT 0,
  `total_sessions` INT DEFAULT 0,
  `last_login` BIGINT,
  `warnings_count` INT DEFAULT 0,
  `bans_count` INT DEFAULT 0,
  `money_cash` DECIMAL(15,2) DEFAULT 0,
  `money_bank` DECIMAL(15,2) DEFAULT 0,
  `job_name` VARCHAR(50),
  `job_grade` INT DEFAULT 0,
  `gang_name` VARCHAR(50),
  `level` INT DEFAULT 0,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`identifier`) REFERENCES `ec_players`(`identifier`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

