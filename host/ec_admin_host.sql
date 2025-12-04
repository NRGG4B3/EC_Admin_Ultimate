-- ============================================================================
-- EC ADMIN ULTIMATE - HOST DATABASE SCHEMA
-- ============================================================================
-- Version: 1.0.0
-- Description: Complete database schema for EC Admin Ultimate (Host Side - NRG Internal)
-- Purpose: All tables required for NRG to manage customers, global bans, and API
-- Installation: Run this file in your HOST database ONCE during initial setup
-- Note: This schema is separate from customer databases and runs on NRG's infrastructure
-- ============================================================================

-- ============================================================================
-- GLOBAL BAN MANAGEMENT (Host Side)
-- ============================================================================

-- Host Global Bans (Master List)
CREATE TABLE IF NOT EXISTS `ec_host_global_bans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `license` VARCHAR(100) NULL,
    `discord` VARCHAR(100) NULL,
    `fivem` VARCHAR(100) NULL,
    `ip` VARCHAR(45) NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `reason` TEXT NOT NULL,
    `evidence` TEXT NULL,
    `banned_by` VARCHAR(100) NOT NULL,
    `ban_type` VARCHAR(50) DEFAULT 'permanent',
    `severity` VARCHAR(20) DEFAULT 'high',
    `server_count` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    UNIQUE KEY `identifier_unique` (`identifier`),
    INDEX `idx_license` (`license`),
    INDEX `idx_discord` (`discord`),
    INDEX `idx_fivem` (`fivem`),
    INDEX `idx_ip` (`ip`),
    INDEX `idx_expires` (`expires_at`),
    INDEX `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ban Appeals
CREATE TABLE IF NOT EXISTS `ec_host_ban_appeals` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `ban_id` INT NOT NULL,
    `identifier` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `appeal_reason` TEXT NOT NULL,
    `evidence` TEXT NULL,
    `status` VARCHAR(50) DEFAULT 'pending',
    `reviewed_by` VARCHAR(100) NULL,
    `reviewed_at` TIMESTAMP NULL,
    `review_notes` TEXT NULL,
    `decision` VARCHAR(50) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_ban_id` (`ban_id`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_status` (`status`),
    FOREIGN KEY (`ban_id`) REFERENCES `ec_host_global_bans`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Global Warnings (Host Side)
CREATE TABLE IF NOT EXISTS `ec_host_global_warnings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `reason` TEXT NOT NULL,
    `severity` VARCHAR(20) DEFAULT 'medium',
    `issued_by` VARCHAR(100) NOT NULL,
    `server_count` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- CUSTOMER SERVER MANAGEMENT
-- ============================================================================

-- Customer Servers
CREATE TABLE IF NOT EXISTS `ec_customer_servers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `server_name` VARCHAR(100) NOT NULL,
    `server_key` VARCHAR(100) NOT NULL UNIQUE,
    `ip_address` VARCHAR(45) NOT NULL,
    `port` INT DEFAULT 30120,
    `owner_name` VARCHAR(100) NOT NULL,
    `owner_contact` VARCHAR(255) NULL,
    `license_tier` VARCHAR(50) DEFAULT 'standard',
    `license_status` VARCHAR(50) DEFAULT 'active',
    `license_expires` TIMESTAMP NULL,
    `max_players` INT DEFAULT 64,
    `region` VARCHAR(50) NULL,
    `api_access` TINYINT(1) DEFAULT 1,
    `global_bans_enabled` TINYINT(1) DEFAULT 1,
    `last_heartbeat` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_active` TINYINT(1) DEFAULT 1,
    INDEX `idx_server_key` (`server_key`),
    INDEX `idx_is_active` (`is_active`),
    INDEX `idx_last_heartbeat` (`last_heartbeat`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Server Stats
CREATE TABLE IF NOT EXISTS `ec_customer_server_stats` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `server_id` INT NOT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `players_online` INT DEFAULT 0,
    `avg_ping` INT DEFAULT 0,
    `uptime_hours` FLOAT DEFAULT 0,
    `api_calls` INT DEFAULT 0,
    `bans_synced` INT DEFAULT 0,
    INDEX `idx_server_id` (`server_id`),
    INDEX `idx_timestamp` (`timestamp`),
    FOREIGN KEY (`server_id`) REFERENCES `ec_customer_servers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- HOST ACTION LOGGING
-- ============================================================================

-- Host Actions Log
CREATE TABLE IF NOT EXISTS `ec_host_actions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_identifier` VARCHAR(100) NOT NULL,
    `admin_name` VARCHAR(100) NOT NULL,
    `action_type` VARCHAR(100) NOT NULL,
    `target_type` VARCHAR(50) NOT NULL,
    `target_id` VARCHAR(100) NULL,
    `target_name` VARCHAR(100) NULL,
    `details` TEXT NULL,
    `metadata` JSON NULL,
    `severity` VARCHAR(20) DEFAULT 'info',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_admin` (`admin_identifier`),
    INDEX `idx_action_type` (`action_type`),
    INDEX `idx_target_type` (`target_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Host Action Logs (Alternative)
CREATE TABLE IF NOT EXISTS `ec_host_action_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `action` VARCHAR(255) NOT NULL,
    `category` VARCHAR(50) DEFAULT 'general',
    `performed_by` VARCHAR(100) NOT NULL,
    `target` VARCHAR(100) NULL,
    `details` TEXT NULL,
    `metadata` JSON NULL,
    `timestamp` BIGINT(20) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_action` (`action`),
    INDEX `idx_category` (`category`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- API MANAGEMENT
-- ============================================================================

-- API Metrics
CREATE TABLE IF NOT EXISTS `ec_host_api_metrics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `server_id` INT NULL,
    `endpoint` VARCHAR(255) NOT NULL,
    `method` VARCHAR(10) DEFAULT 'GET',
    `status_code` INT NOT NULL,
    `response_time_ms` INT NOT NULL,
    `request_size_bytes` INT DEFAULT 0,
    `response_size_bytes` INT DEFAULT 0,
    `success` TINYINT(1) DEFAULT 1,
    `error_message` TEXT NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` VARCHAR(255) NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_server_id` (`server_id`),
    INDEX `idx_endpoint` (`endpoint`),
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_success` (`success`),
    FOREIGN KEY (`server_id`) REFERENCES `ec_customer_servers`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- API Keys
CREATE TABLE IF NOT EXISTS `ec_host_api_keys` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `server_id` INT NOT NULL,
    `api_key` VARCHAR(100) NOT NULL UNIQUE,
    `key_type` VARCHAR(50) DEFAULT 'standard',
    `rate_limit` INT DEFAULT 1000,
    `allowed_endpoints` TEXT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `last_used` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NULL,
    INDEX `idx_api_key` (`api_key`),
    INDEX `idx_server_id` (`server_id`),
    INDEX `idx_is_active` (`is_active`),
    FOREIGN KEY (`server_id`) REFERENCES `ec_customer_servers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- API Rate Limiting
CREATE TABLE IF NOT EXISTS `ec_host_api_rate_limits` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `server_id` INT NOT NULL,
    `endpoint` VARCHAR(255) NOT NULL,
    `requests_count` INT DEFAULT 0,
    `window_start` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `window_end` TIMESTAMP NOT NULL,
    INDEX `idx_server_endpoint` (`server_id`, `endpoint`),
    INDEX `idx_window_end` (`window_end`),
    FOREIGN KEY (`server_id`) REFERENCES `ec_customer_servers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- HOST ALERTS & MONITORING
-- ============================================================================

-- Host Alerts
CREATE TABLE IF NOT EXISTS `ec_host_alerts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `alert_type` VARCHAR(50) NOT NULL,
    `severity` VARCHAR(20) DEFAULT 'warning',
    `title` VARCHAR(200) NOT NULL,
    `message` TEXT NOT NULL,
    `source` VARCHAR(100) NULL,
    `metadata` JSON NULL,
    `is_acknowledged` TINYINT(1) DEFAULT 0,
    `acknowledged_by` VARCHAR(100) NULL,
    `acknowledged_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_alert_type` (`alert_type`),
    INDEX `idx_severity` (`severity`),
    INDEX `idx_acknowledged` (`is_acknowledged`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- System Health Checks
CREATE TABLE IF NOT EXISTS `ec_host_health_checks` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `check_type` VARCHAR(50) NOT NULL,
    `status` VARCHAR(20) DEFAULT 'unknown',
    `response_time_ms` INT NULL,
    `error_message` TEXT NULL,
    `metadata` JSON NULL,
    `checked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_check_type` (`check_type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_checked_at` (`checked_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- HOST REVENUE & BILLING
-- ============================================================================

-- Revenue Tracking
CREATE TABLE IF NOT EXISTS `ec_host_revenue` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `server_id` INT NOT NULL,
    `transaction_type` VARCHAR(50) NOT NULL,
    `amount` DECIMAL(10, 2) NOT NULL,
    `currency` VARCHAR(3) DEFAULT 'USD',
    `description` TEXT NULL,
    `payment_method` VARCHAR(50) NULL,
    `status` VARCHAR(50) DEFAULT 'pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_server_id` (`server_id`),
    INDEX `idx_transaction_type` (`transaction_type`),
    INDEX `idx_status` (`status`),
    FOREIGN KEY (`server_id`) REFERENCES `ec_customer_servers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- License Renewals
CREATE TABLE IF NOT EXISTS `ec_host_license_renewals` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `server_id` INT NOT NULL,
    `old_expiry` TIMESTAMP NOT NULL,
    `new_expiry` TIMESTAMP NOT NULL,
    `amount` DECIMAL(10, 2) NOT NULL,
    `renewal_type` VARCHAR(50) DEFAULT 'manual',
    `processed_by` VARCHAR(100) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_server_id` (`server_id`),
    FOREIGN KEY (`server_id`) REFERENCES `ec_customer_servers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- HOST NOTIFICATIONS & MESSAGING
-- ============================================================================

-- Host Notifications
CREATE TABLE IF NOT EXISTS `ec_host_notifications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `recipient_type` VARCHAR(50) NOT NULL,
    `recipient_id` VARCHAR(100) NOT NULL,
    `notification_type` VARCHAR(50) NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `message` TEXT NOT NULL,
    `priority` VARCHAR(20) DEFAULT 'normal',
    `is_read` TINYINT(1) DEFAULT 0,
    `read_at` TIMESTAMP NULL,
    `metadata` JSON NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_recipient` (`recipient_type`, `recipient_id`),
    INDEX `idx_is_read` (`is_read`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Broadcast Messages
CREATE TABLE IF NOT EXISTS `ec_host_broadcasts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `message_type` VARCHAR(50) NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `content` TEXT NOT NULL,
    `target_tier` VARCHAR(50) NULL,
    `target_region` VARCHAR(50) NULL,
    `sent_by` VARCHAR(100) NOT NULL,
    `servers_reached` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_message_type` (`message_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- HOST ANALYTICS
-- ============================================================================

-- Platform Analytics
CREATE TABLE IF NOT EXISTS `ec_host_analytics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `metric_type` VARCHAR(50) NOT NULL,
    `metric_name` VARCHAR(100) NOT NULL,
    `metric_value` FLOAT NOT NULL,
    `aggregation_period` VARCHAR(20) DEFAULT 'hourly',
    `metadata` JSON NULL,
    `recorded_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_metric_type` (`metric_type`),
    INDEX `idx_recorded_at` (`recorded_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ban Statistics
CREATE TABLE IF NOT EXISTS `ec_host_ban_statistics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `date` DATE NOT NULL,
    `total_bans` INT DEFAULT 0,
    `new_bans` INT DEFAULT 0,
    `lifted_bans` INT DEFAULT 0,
    `appeals_submitted` INT DEFAULT 0,
    `appeals_approved` INT DEFAULT 0,
    INDEX `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- HOST CONFIGURATION
-- ============================================================================

-- Host Settings
CREATE TABLE IF NOT EXISTS `ec_host_settings` (
    `id` INT DEFAULT 1 PRIMARY KEY,
    `settings` LONGTEXT NULL,
    `api_config` LONGTEXT NULL,
    `notification_config` LONGTEXT NULL,
    `updated_by` VARCHAR(100) NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Feature Flags
CREATE TABLE IF NOT EXISTS `ec_host_feature_flags` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `feature_name` VARCHAR(100) NOT NULL UNIQUE,
    `description` TEXT NULL,
    `is_enabled` TINYINT(1) DEFAULT 0,
    `rollout_percentage` INT DEFAULT 0,
    `target_tiers` TEXT NULL,
    `updated_by` VARCHAR(100) NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_is_enabled` (`is_enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- HOST STAFF MANAGEMENT
-- ============================================================================

-- Host Staff
CREATE TABLE IF NOT EXISTS `ec_host_staff` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL UNIQUE,
    `username` VARCHAR(100) NOT NULL,
    `email` VARCHAR(255) NULL,
    `role` VARCHAR(50) NOT NULL,
    `permissions` TEXT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `last_login` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Staff Activity Log
CREATE TABLE IF NOT EXISTS `ec_host_staff_activity` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `staff_id` INT NOT NULL,
    `activity_type` VARCHAR(50) NOT NULL,
    `description` TEXT NOT NULL,
    `metadata` JSON NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_staff_id` (`staff_id`),
    INDEX `idx_activity_type` (`activity_type`),
    FOREIGN KEY (`staff_id`) REFERENCES `ec_host_staff`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- MIGRATION TRACKING (Host Side)
-- ============================================================================

-- Host Migrations
CREATE TABLE IF NOT EXISTS `ec_host_migrations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `filename` VARCHAR(255) NOT NULL UNIQUE,
    `executed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `success` BOOLEAN DEFAULT TRUE,
    `error_message` TEXT NULL,
    INDEX `idx_filename` (`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- END OF HOST SCHEMA
-- ============================================================================

-- Insert default settings row
INSERT IGNORE INTO `ec_host_settings` (`id`, `settings`, `api_config`, `notification_config`) 
VALUES (1, '{}', '{}', '{}');

-- Success message
SELECT 'EC ADMIN ULTIMATE - Host database schema installed successfully!' AS Status;
SELECT CONCAT('Total Host Tables Created: ', COUNT(*)) AS TableCount 
FROM information_schema.tables 
WHERE table_schema = DATABASE() 
AND table_name LIKE 'ec_host_%' OR table_name LIKE 'ec_customer_%';
