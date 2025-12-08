-- ============================================================================
-- EC Admin Ultimate - Vehicles Schema
-- ============================================================================
-- SQL migration file for vehicle management tables
-- Run this SQL to create the required tables for vehicle management
-- ============================================================================

-- Table: Vehicle Spawn Log (audit trail for vehicle spawns)
CREATE TABLE IF NOT EXISTS `ec_vehicle_spawn_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `vehicle_model` VARCHAR(50) NOT NULL,
  `plate` VARCHAR(20),
  `spawned_by` VARCHAR(50) NOT NULL,
  `spawned_for` VARCHAR(50),
  `coords_x` DECIMAL(10,2),
  `coords_y` DECIMAL(10,2),
  `coords_z` DECIMAL(10,2),
  `timestamp` BIGINT NOT NULL,
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_plate` (`plate`),
  INDEX `idx_spawned_by` (`spawned_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Vehicle Action Log (audit trail for all vehicle actions)
CREATE TABLE IF NOT EXISTS `ec_vehicle_action_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `plate` VARCHAR(20) NOT NULL,
  `action` VARCHAR(50) NOT NULL,
  `performed_by` VARCHAR(50) NOT NULL,
  `details` TEXT,
  `timestamp` BIGINT NOT NULL,
  INDEX `idx_plate` (`plate`),
  INDEX `idx_action` (`action`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_performed_by` (`performed_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Vehicle Statistics (aggregated vehicle stats)
CREATE TABLE IF NOT EXISTS `ec_vehicle_statistics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `date` DATE NOT NULL,
  `total_vehicles` INT DEFAULT 0,
  `spawned_vehicles` INT DEFAULT 0,
  `owned_vehicles` INT DEFAULT 0,
  `impounded_vehicles` INT DEFAULT 0,
  `total_value` DECIMAL(15,2) DEFAULT 0,
  `vehicles_added` INT DEFAULT 0,
  `vehicles_deleted` INT DEFAULT 0,
  `vehicles_repaired` INT DEFAULT 0,
  `vehicles_refueled` INT DEFAULT 0,
  `vehicles_impounded` INT DEFAULT 0,
  UNIQUE KEY `unique_date` (`date`),
  INDEX `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Vehicle Model Cache (cached detected vehicle models)
CREATE TABLE IF NOT EXISTS `ec_vehicle_model_cache` (
  `model` VARCHAR(50) PRIMARY KEY,
  `name` VARCHAR(100),
  `class` VARCHAR(50),
  `manufacturer` VARCHAR(50),
  `category` VARCHAR(20),
  `is_addon` TINYINT(1) DEFAULT 0,
  `last_verified` BIGINT,
  INDEX `idx_class` (`class`),
  INDEX `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Vehicle Plate History (track plate changes)
CREATE TABLE IF NOT EXISTS `ec_vehicle_plate_history` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `old_plate` VARCHAR(20) NOT NULL,
  `new_plate` VARCHAR(20) NOT NULL,
  `changed_by` VARCHAR(50) NOT NULL,
  `timestamp` BIGINT NOT NULL,
  INDEX `idx_old_plate` (`old_plate`),
  INDEX `idx_new_plate` (`new_plate`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Vehicle Transfer Log (track ownership transfers)
CREATE TABLE IF NOT EXISTS `ec_vehicle_transfer_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `plate` VARCHAR(20) NOT NULL,
  `old_owner` VARCHAR(50),
  `new_owner` VARCHAR(50) NOT NULL,
  `transferred_by` VARCHAR(50) NOT NULL,
  `timestamp` BIGINT NOT NULL,
  INDEX `idx_plate` (`plate`),
  INDEX `idx_new_owner` (`new_owner`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

