-- EC Admin Ultimate - Host Database Schema
-- Additional tables for Host build only
-- Run this AFTER database.sql if deploying host version

-- API Keys
CREATE TABLE IF NOT EXISTS `ec_host_api_keys` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `key_value` VARCHAR(255) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_used` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key_value` (`key_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- IP Allowlist
CREATE TABLE IF NOT EXISTS `ec_host_ip_allowlist` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `ip` VARCHAR(45) NOT NULL,
  `label` VARCHAR(255) NOT NULL,
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Connected Cities
CREATE TABLE IF NOT EXISTS `ec_host_cities` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `api_key` VARCHAR(255) NOT NULL,
  `status` ENUM('online', 'offline') NOT NULL DEFAULT 'offline',
  `last_seen` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `api_key` (`api_key`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- License Management
CREATE TABLE IF NOT EXISTS `ec_host_licenses` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `license_key` VARCHAR(255) NOT NULL,
  `owner_email` VARCHAR(255) NOT NULL,
  `status` ENUM('active', 'suspended', 'expired') NOT NULL DEFAULT 'active',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `license_key` (`license_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- OAuth Sessions
CREATE TABLE IF NOT EXISTS `ec_host_oauth_sessions` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(255) NOT NULL,
  `token` VARCHAR(500) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- NRG Staff Sessions (fly into city)
CREATE TABLE IF NOT EXISTS `ec_host_nrg_sessions` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `staff_email` VARCHAR(255) NOT NULL,
  `staff_name` VARCHAR(255) NOT NULL,
  `city_id` INT(11) NOT NULL,
  `reason` TEXT DEFAULT NULL,
  `started_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ended_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `city_id` (`city_id`),
  KEY `staff_email` (`staff_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Audit Trail
CREATE TABLE IF NOT EXISTS `ec_host_audit` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `user_email` VARCHAR(255) NOT NULL,
  `action` VARCHAR(100) NOT NULL,
  `details` LONGTEXT DEFAULT NULL,
  `ip_address` VARCHAR(45) DEFAULT NULL,
  `timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_email` (`user_email`),
  KEY `action` (`action`),
  KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Metrics Storage (for analytics)
CREATE TABLE IF NOT EXISTS `ec_host_metrics` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `metric_type` VARCHAR(50) NOT NULL,
  `metric_value` DECIMAL(10,2) NOT NULL,
  `city_id` INT(11) DEFAULT NULL,
  `recorded_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `metric_type` (`metric_type`),
  KEY `city_id` (`city_id`),
  KEY `recorded_at` (`recorded_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
