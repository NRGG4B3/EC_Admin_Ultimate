-- ============================================================================
-- EC ADMIN ULTIMATE - COMPLETE DATABASE MIGRATION
-- Version: 3.5.0
-- All tables required for full functionality
-- ============================================================================

-- ============================================================================
-- ANTICHEAT TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_admin_anticheat` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `player_id` INT NOT NULL,
  `player_name` VARCHAR(255) DEFAULT 'Unknown',
  `identifier` VARCHAR(255) DEFAULT NULL,
  `detection_type` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `severity` ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
  `timestamp` BIGINT NOT NULL,
  `banned` TINYINT(1) DEFAULT 0,
  `whitelisted` TINYINT(1) DEFAULT 0,
  `false_positive` TINYINT(1) DEFAULT 0,
  INDEX `idx_player_id` (`player_id`),
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_detection_type` (`detection_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- AI DETECTION TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_admin_ai_detections` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `player_id` INT NOT NULL,
  `player_name` VARCHAR(255) DEFAULT 'Unknown',
  `detection_type` VARCHAR(100) NOT NULL,
  `confidence` DECIMAL(5,4) DEFAULT 0.5000,
  `description` TEXT DEFAULT NULL,
  `severity` ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
  `timestamp` BIGINT NOT NULL,
  `resolved` TINYINT(1) DEFAULT 0,
  `resolved_by` VARCHAR(255) DEFAULT NULL,
  `resolved_at` BIGINT DEFAULT NULL,
  INDEX `idx_player_id` (`player_id`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_detection_type` (`detection_type`),
  INDEX `idx_resolved` (`resolved`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ADMIN ACTION LOGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_admin_action_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_name` VARCHAR(255) NOT NULL,
  `admin_identifier` VARCHAR(255) NOT NULL,
  `action_type` VARCHAR(100) NOT NULL,
  `target_name` VARCHAR(255) DEFAULT NULL,
  `target_identifier` VARCHAR(255) DEFAULT NULL,
  `details` TEXT DEFAULT NULL,
  `timestamp` BIGINT NOT NULL,
  `suspicious` TINYINT(1) DEFAULT 0,
  INDEX `idx_admin_identifier` (`admin_identifier`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_action_type` (`action_type`),
  INDEX `idx_suspicious` (`suspicious`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SETTINGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_admin_settings` (
  `id` INT PRIMARY KEY DEFAULT 1,
  `settings` LONGTEXT NOT NULL,
  `created_at` BIGINT NOT NULL,
  `updated_at` BIGINT NOT NULL,
  `updated_by` VARCHAR(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PLAYER REPORTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS `player_reports` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `report_id` VARCHAR(50) UNIQUE NOT NULL,
  `reported_player` VARCHAR(255) NOT NULL,
  `reported_license` VARCHAR(255) NOT NULL,
  `reporter` VARCHAR(255) NOT NULL,
  `reporter_license` VARCHAR(255) NOT NULL,
  `reason` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `category` VARCHAR(50) DEFAULT 'general',
  `status` ENUM('open', 'in_progress', 'resolved', 'closed') DEFAULT 'open',
  `priority` ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
  `timestamp` BIGINT NOT NULL,
  `assigned_to` VARCHAR(255) DEFAULT NULL,
  `resolved_by` VARCHAR(255) DEFAULT NULL,
  `resolved_at` BIGINT DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  `evidence` TEXT DEFAULT NULL,
  INDEX `idx_status` (`status`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_reported_license` (`reported_license`),
  INDEX `idx_reporter_license` (`reporter_license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ACTIVITY LOGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS `activity_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `log_id` VARCHAR(50) UNIQUE NOT NULL,
  `event_type` VARCHAR(100) NOT NULL,
  `event` VARCHAR(100) DEFAULT NULL,
  `user_identifier` VARCHAR(255) DEFAULT NULL,
  `user` VARCHAR(255) DEFAULT NULL,
  `timestamp` BIGINT NOT NULL,
  `severity` ENUM('info', 'warning', 'error', 'critical') DEFAULT 'info',
  `level` VARCHAR(50) DEFAULT 'info',
  `details` TEXT DEFAULT NULL,
  `description` TEXT DEFAULT NULL,
  `category` VARCHAR(50) DEFAULT 'system',
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `metadata` TEXT DEFAULT NULL,
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_event_type` (`event_type`),
  INDEX `idx_user_identifier` (`user_identifier`),
  INDEX `idx_severity` (`severity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- AUDIT TRAIL TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS `audit_trail` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `audit_id` VARCHAR(50) UNIQUE NOT NULL,
  `action_type` VARCHAR(100) NOT NULL,
  `action` VARCHAR(100) DEFAULT NULL,
  `admin_identifier` VARCHAR(255) NOT NULL,
  `admin` VARCHAR(255) DEFAULT NULL,
  `target_identifier` VARCHAR(255) DEFAULT NULL,
  `target` VARCHAR(255) DEFAULT NULL,
  `target_name` VARCHAR(255) DEFAULT NULL,
  `timestamp` BIGINT NOT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `details` TEXT DEFAULT NULL,
  `success` TINYINT(1) DEFAULT 1,
  `reason` VARCHAR(255) DEFAULT NULL,
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_admin_identifier` (`admin_identifier`),
  INDEX `idx_action_type` (`action_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SYSTEM REPORTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS `system_reports` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `report_id` VARCHAR(50) UNIQUE NOT NULL,
  `report_type` VARCHAR(100) NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `severity` ENUM('info', 'warning', 'error', 'critical') DEFAULT 'info',
  `status` ENUM('new', 'investigating', 'resolved', 'ignored') DEFAULT 'new',
  `created_at` BIGINT NOT NULL,
  `created_by` VARCHAR(255) DEFAULT 'System',
  `resolved_at` BIGINT DEFAULT NULL,
  `resolved_by` VARCHAR(255) DEFAULT NULL,
  `metadata` TEXT DEFAULT NULL,
  INDEX `idx_created_at` (`created_at`),
  INDEX `idx_status` (`status`),
  INDEX `idx_severity` (`severity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ERROR LOGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS `error_logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `error_id` VARCHAR(50) UNIQUE NOT NULL,
  `error_type` VARCHAR(100) NOT NULL,
  `message` TEXT NOT NULL,
  `stack_trace` TEXT DEFAULT NULL,
  `source` VARCHAR(255) DEFAULT NULL,
  `timestamp` BIGINT NOT NULL,
  `severity` ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
  `resolved` TINYINT(1) DEFAULT 0,
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_error_type` (`error_type`),
  INDEX `idx_resolved` (`resolved`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PLAYER KICKS TABLE (if not exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `player_kicks` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `kick_id` VARCHAR(50) UNIQUE NOT NULL,
  `citizenid` VARCHAR(50) DEFAULT NULL,
  `player` VARCHAR(255) DEFAULT NULL,
  `name` VARCHAR(255) DEFAULT NULL,
  `license` VARCHAR(255) DEFAULT NULL,
  `reason` VARCHAR(255) DEFAULT NULL,
  `kicked_by` VARCHAR(255) DEFAULT NULL,
  `kickedby` VARCHAR(255) DEFAULT NULL,
  `timestamp` BIGINT NOT NULL,
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

SELECT '✅ EC ADMIN ULTIMATE - Database migration completed successfully!' AS message;
SELECT 'All required tables have been created or verified.' AS status;
