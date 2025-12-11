-- ============================================================================
-- EC Admin Ultimate - Inventory Management Database Schema
-- ============================================================================
-- SQL migration file for inventory management tables
-- Run this SQL to create the required tables for the inventory system
-- ============================================================================

-- Table: Inventory Actions Log
CREATE TABLE IF NOT EXISTS `ec_inventory_actions_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `action_type` VARCHAR(50) NOT NULL,
  `player_id` INT,
  `player_identifier` VARCHAR(50),
  `player_name` VARCHAR(100),
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `item_name` VARCHAR(100),
  `item_label` VARCHAR(100),
  `old_amount` INT,
  `new_amount` INT,
  `slot` INT,
  `metadata` TEXT,
  `reason` TEXT,
  `timestamp` BIGINT NOT NULL,
  `success` TINYINT(1) DEFAULT 1,
  `error_message` TEXT,
  INDEX `idx_player_identifier` (`player_identifier`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_item_name` (`item_name`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_action_type` (`action_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Inventory Statistics
CREATE TABLE IF NOT EXISTS `ec_inventory_statistics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `player_identifier` VARCHAR(50) NOT NULL,
  `total_items` INT DEFAULT 0,
  `total_weight` DECIMAL(10,2) DEFAULT 0,
  `max_weight` DECIMAL(10,2) DEFAULT 0,
  `unique_items` INT DEFAULT 0,
  `last_updated` BIGINT NOT NULL,
  UNIQUE KEY `uk_player_identifier` (`player_identifier`),
  INDEX `idx_last_updated` (`last_updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

