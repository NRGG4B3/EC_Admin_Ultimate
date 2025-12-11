-- ============================================================================
-- EC Admin Ultimate - Framework Bans Table
-- ============================================================================
-- SQL migration file for framework-compatible bans table
-- This table is used by QB/QBX/ESX frameworks for ban checking
-- Run this SQL to create the required bans table
-- ============================================================================

-- Table: Bans (Framework Compatible)
-- This table matches the structure expected by qbx_core and other frameworks
CREATE TABLE IF NOT EXISTS `bans` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `license` VARCHAR(100) NULL,
  `discord` VARCHAR(100) NULL,
  `ip` VARCHAR(45) NULL,
  `reason` TEXT NOT NULL,
  `expire` BIGINT NULL,
  `bannedby` VARCHAR(100) NOT NULL DEFAULT 'System',
  `timestamp` BIGINT NOT NULL,
  `active` TINYINT(1) DEFAULT 1,
  INDEX `idx_license` (`license`),
  INDEX `idx_discord` (`discord`),
  INDEX `idx_ip` (`ip`),
  INDEX `idx_expire` (`expire`),
  INDEX `idx_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Note: This table is compatible with:
-- - qbx_core (expects: license, expire, reason)
-- - qb-core (expects: license, expire, reason)
-- - ESX (may use different structure, but this is a common format)
