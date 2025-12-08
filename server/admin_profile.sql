-- ============================================================================
-- EC Admin Ultimate - Admin Profile Database Schema
-- ============================================================================
-- SQL migration file for admin profile tables
-- Run this SQL to create the required tables for the admin profile system
-- ============================================================================

-- Table: Admin Profiles
CREATE TABLE IF NOT EXISTS `ec_admin_profiles` (
  `admin_id` VARCHAR(50) PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `email` VARCHAR(255),
  `phone` VARCHAR(20),
  `location` VARCHAR(100),
  `role` VARCHAR(50) DEFAULT 'admin',
  `joined_date` BIGINT NOT NULL,
  `last_login` BIGINT,
  `status` VARCHAR(20) DEFAULT 'active',
  `password_hash` VARCHAR(255),
  `framework` VARCHAR(50),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_status` (`status`),
  INDEX `idx_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Admin Permissions
CREATE TABLE IF NOT EXISTS `ec_admin_permissions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `permission_name` VARCHAR(100) NOT NULL,
  `category` VARCHAR(50) NOT NULL,
  `granted` BOOLEAN DEFAULT TRUE,
  `granted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `granted_by` VARCHAR(50),
  FOREIGN KEY (`admin_id`) REFERENCES `ec_admin_profiles`(`admin_id`) ON DELETE CASCADE,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_category` (`category`),
  UNIQUE KEY `unique_admin_permission` (`admin_id`, `permission_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Admin Roles
CREATE TABLE IF NOT EXISTS `ec_admin_roles` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `role_name` VARCHAR(100) NOT NULL,
  `active` BOOLEAN DEFAULT TRUE,
  `assigned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `assigned_by` VARCHAR(50),
  FOREIGN KEY (`admin_id`) REFERENCES `ec_admin_profiles`(`admin_id`) ON DELETE CASCADE,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Admin Activity
CREATE TABLE IF NOT EXISTS `ec_admin_activity` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `action` VARCHAR(255) NOT NULL,
  `category` VARCHAR(50) NOT NULL,
  `target_name` VARCHAR(100),
  `target_id` VARCHAR(50),
  `details` TEXT,
  `timestamp` BIGINT NOT NULL,
  `ip_address` VARCHAR(45),
  FOREIGN KEY (`admin_id`) REFERENCES `ec_admin_profiles`(`admin_id`) ON DELETE CASCADE,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_category` (`category`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Admin Infractions
CREATE TABLE IF NOT EXISTS `ec_admin_infractions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `reason` TEXT NOT NULL,
  `issued_by` VARCHAR(50),
  `timestamp` BIGINT NOT NULL,
  FOREIGN KEY (`admin_id`) REFERENCES `ec_admin_profiles`(`admin_id`) ON DELETE CASCADE,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Admin Warnings
CREATE TABLE IF NOT EXISTS `ec_admin_warnings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `reason` TEXT NOT NULL,
  `issued_by` VARCHAR(50),
  `timestamp` BIGINT NOT NULL,
  FOREIGN KEY (`admin_id`) REFERENCES `ec_admin_profiles`(`admin_id`) ON DELETE CASCADE,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Admin Bans
CREATE TABLE IF NOT EXISTS `ec_admin_bans` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `reason` TEXT NOT NULL,
  `issued_by` VARCHAR(50),
  `timestamp` BIGINT NOT NULL,
  `expires_at` BIGINT,
  `active` BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (`admin_id`) REFERENCES `ec_admin_profiles`(`admin_id`) ON DELETE CASCADE,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_active` (`active`),
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Admin Sessions
CREATE TABLE IF NOT EXISTS `ec_admin_sessions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100),
  `login_time` BIGINT NOT NULL,
  `logout_time` BIGINT,
  `ip_address` VARCHAR(45),
  `status` VARCHAR(20) DEFAULT 'active',
  FOREIGN KEY (`admin_id`) REFERENCES `ec_admin_profiles`(`admin_id`) ON DELETE CASCADE,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Admin Preferences
CREATE TABLE IF NOT EXISTS `ec_admin_preferences` (
  `admin_id` VARCHAR(50) PRIMARY KEY,
  `email_notifications` BOOLEAN DEFAULT TRUE,
  `discord_notifications` BOOLEAN DEFAULT TRUE,
  `player_reports` BOOLEAN DEFAULT TRUE,
  `ban_alerts` BOOLEAN DEFAULT TRUE,
  `security_alerts` BOOLEAN DEFAULT TRUE,
  `system_alerts` BOOLEAN DEFAULT TRUE,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`admin_id`) REFERENCES `ec_admin_profiles`(`admin_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

