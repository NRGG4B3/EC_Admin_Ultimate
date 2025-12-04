-- ============================================================================
-- EC ADMIN ULTIMATE - COMPLETE SQL SCHEMA (AUTO-APPLY)
-- ============================================================================
-- This file is applied automatically on server startup
-- Creates ALL tables if they don't exist
-- Works for both HOST and CUSTOMER modes
-- ============================================================================

-- ============================================================================
-- CORE ADMIN TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_admin_action_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_identifier` VARCHAR(100),
    `admin_name` VARCHAR(50),
    `action` VARCHAR(100),
    `category` VARCHAR(50) DEFAULT 'general',
    `target_identifier` VARCHAR(100),
    `target_name` VARCHAR(50),
    `details` TEXT,
    `metadata` JSON,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `action_type` VARCHAR(50),
    INDEX `idx_admin` (`admin_identifier`),
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_category` (`category`),
    INDEX `idx_action_type` (`action_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ec_admin_migrations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `filename` VARCHAR(255) NOT NULL UNIQUE,
    `executed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `success` BOOLEAN DEFAULT TRUE,
    `error_message` TEXT NULL,
    INDEX `idx_filename` (`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ec_admin_config` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `config_key` VARCHAR(100) UNIQUE NOT NULL,
    `config_value` TEXT,
    `value_type` VARCHAR(20),
    `enabled` BOOLEAN DEFAULT TRUE,
    `updated_by` VARCHAR(100),
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_key` (`config_key`),
    INDEX `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PLAYER & ADMIN MANAGEMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS `player_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `report_id` VARCHAR(50) UNIQUE,
    `reporter_identifier` VARCHAR(100),
    `reporter_name` VARCHAR(50),
    `reported_identifier` VARCHAR(100),
    `reported_name` VARCHAR(50),
    `reason` TEXT,
    `status` VARCHAR(20) DEFAULT 'open',
    `priority` VARCHAR(20) DEFAULT 'normal',
    `assigned_to` VARCHAR(100),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `resolved_at` TIMESTAMP NULL,
    INDEX `idx_status` (`status`),
    INDEX `idx_reported` (`reported_identifier`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ec_admin_abuse_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_identifier` VARCHAR(100),
    `admin_name` VARCHAR(50),
    `action_type` VARCHAR(50),
    `target_identifier` VARCHAR(100),
    `target_name` VARCHAR(50),
    `severity` VARCHAR(20),
    `details` TEXT,
    `metadata` JSON,
    `flagged_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `reviewed` BOOLEAN DEFAULT FALSE,
    `reviewed_by` VARCHAR(100),
    `reviewed_at` TIMESTAMP NULL,
    INDEX `idx_admin` (`admin_identifier`),
    INDEX `idx_severity` (`severity`),
    INDEX `idx_reviewed` (`reviewed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- AI ANALYTICS & DETECTION
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_ai_analytics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `metric_name` VARCHAR(100),
    `metric_value` FLOAT,
    `metric_data` JSON,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_metric` (`metric_name`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ec_ai_detections` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(100),
    `player_name` VARCHAR(50),
    `detection_type` VARCHAR(50),
    `detection_data` JSON,
    `prediction_score` FLOAT,
    `confidence` FLOAT,
    `is_flagged` BOOLEAN DEFAULT FALSE,
    `detected_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `reviewed` BOOLEAN DEFAULT FALSE,
    `reviewed_by` VARCHAR(100),
    `reviewed_at` TIMESTAMP NULL,
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_type` (`detection_type`),
    INDEX `idx_flagged` (`is_flagged`),
    INDEX `idx_timestamp` (`detected_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- HOUSING MARKET & ECONOMY
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_housing_market` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `property_id` VARCHAR(50),
    `owner_identifier` VARCHAR(100),
    `owner_name` VARCHAR(50),
    `price` INT,
    `status` VARCHAR(20) DEFAULT 'available',
    `type` VARCHAR(50),
    `location` VARCHAR(100),
    `metadata` JSON,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `property_unique` (`property_id`),
    INDEX `idx_owner` (`owner_identifier`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ec_economy_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(100),
    `player_name` VARCHAR(50),
    `transaction_type` VARCHAR(50),
    `amount` INT,
    `new_balance` INT,
    `metadata` JSON,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_type` (`transaction_type`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- JOBS & GANGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_job_history` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(100),
    `player_name` VARCHAR(50),
    `job_name` VARCHAR(50),
    `job_grade` VARCHAR(20),
    `started_at` TIMESTAMP,
    `ended_at` TIMESTAMP NULL,
    `metadata` JSON,
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ec_gang_history` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(100),
    `player_name` VARCHAR(50),
    `gang_name` VARCHAR(50),
    `gang_grade` VARCHAR(20),
    `joined_at` TIMESTAMP,
    `left_at` TIMESTAMP NULL,
    `metadata` JSON,
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_gang` (`gang_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- LIVE MAP & TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_livemap_positions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(100),
    `player_name` VARCHAR(50),
    `x` FLOAT,
    `y` FLOAT,
    `z` FLOAT,
    `heading` FLOAT,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ec_livemap_heatmap` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `cell_x` INT,
    `cell_y` INT,
    `intensity` INT DEFAULT 0,
    `player_count` INT DEFAULT 0,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `cell_unique` (`cell_x`, `cell_y`),
    INDEX `idx_intensity` (`intensity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- COMMUNITY & ENGAGEMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_community_members` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(100) UNIQUE,
    `player_name` VARCHAR(50),
    `tier` VARCHAR(20) DEFAULT 'bronze',
    `engagement_score` INT DEFAULT 0,
    `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_activity` TIMESTAMP NULL,
    `metadata` JSON,
    INDEX `idx_tier` (`tier`),
    INDEX `idx_score` (`engagement_score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ec_community_events` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `event_name` VARCHAR(100),
    `event_type` VARCHAR(50),
    `participants` JSON,
    `points_awarded` INT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_type` (`event_type`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- BILLING & REVENUE (Host Mode)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_billing_invoices` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `invoice_id` VARCHAR(50) UNIQUE,
    `customer_id` VARCHAR(100),
    `amount` DECIMAL(10, 2),
    `status` VARCHAR(20) DEFAULT 'pending',
    `description` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `due_at` TIMESTAMP NULL,
    `paid_at` TIMESTAMP NULL,
    INDEX `idx_status` (`status`),
    INDEX `idx_customer` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ec_billing_subscriptions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `subscription_id` VARCHAR(50) UNIQUE,
    `customer_id` VARCHAR(100),
    `plan_name` VARCHAR(50),
    `monthly_amount` DECIMAL(10, 2),
    `status` VARCHAR(20) DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `cancelled_at` TIMESTAMP NULL,
    INDEX `idx_status` (`status`),
    INDEX `idx_customer` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ANTICHEAT & SECURITY
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_anticheat_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(100),
    `player_name` VARCHAR(50),
    `violation_type` VARCHAR(50),
    `violation_data` JSON,
    `severity` VARCHAR(20),
    `action_taken` VARCHAR(50),
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_type` (`violation_type`),
    INDEX `idx_severity` (`severity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ec_anticheat_flags` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(100),
    `player_name` VARCHAR(50),
    `flag_reason` TEXT,
    `flag_data` JSON,
    `flagged_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `resolved` BOOLEAN DEFAULT FALSE,
    `resolved_by` VARCHAR(100),
    `resolved_at` TIMESTAMP NULL,
    INDEX `idx_player` (`player_identifier`),
    INDEX `idx_resolved` (`resolved`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- WHITELIST & QUEUE (Customer Mode)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_whitelist_entries` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) UNIQUE,
    `player_name` VARCHAR(50),
    `added_by` VARCHAR(100),
    `reason` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ec_queue_positions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_identifier` VARCHAR(100) UNIQUE,
    `player_name` VARCHAR(50),
    `position` INT,
    `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_position` (`position`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- INDEX ALL CRITICAL COLUMNS FOR PERFORMANCE
-- ============================================================================

ALTER TABLE `ec_admin_action_logs` ADD INDEX IF NOT EXISTS `idx_admin_id` (`admin_identifier`);
ALTER TABLE `ec_admin_action_logs` ADD INDEX IF NOT EXISTS `idx_timestamp` (`timestamp`);
ALTER TABLE `ec_admin_action_logs` ADD INDEX IF NOT EXISTS `idx_category` (`category`);
ALTER TABLE `player_reports` ADD INDEX IF NOT EXISTS `idx_status_created` (`status`, `created_at`);
ALTER TABLE `ec_ai_detections` ADD INDEX IF NOT EXISTS `idx_player_type` (`player_identifier`, `detection_type`);
ALTER TABLE `ec_livemap_positions` ADD INDEX IF NOT EXISTS `idx_player_time` (`player_identifier`, `timestamp`);
