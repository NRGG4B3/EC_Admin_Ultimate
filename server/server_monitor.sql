-- ============================================================================
-- EC Admin Ultimate - Server Monitor Schema
-- ============================================================================
-- SQL migration file for server monitor tables
-- Run this SQL to create the required tables for server monitoring
-- ============================================================================

-- Table: Server Monitor History (metrics tracking)
CREATE TABLE IF NOT EXISTS `ec_server_monitor_history` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `timestamp` BIGINT NOT NULL,
  `tps` DECIMAL(5,2) DEFAULT 0,
  `memory` DECIMAL(10,2) DEFAULT 0,
  `cpu` DECIMAL(5,2) DEFAULT 0,
  `players` INT DEFAULT 0,
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_date` (DATE(FROM_UNIXTIME(timestamp)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Resource Monitor (resource performance tracking)
CREATE TABLE IF NOT EXISTS `ec_resource_monitor` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `resource_name` VARCHAR(100) NOT NULL,
  `status` VARCHAR(20) NOT NULL,
  `cpu` DECIMAL(5,2) DEFAULT 0,
  `memory` DECIMAL(10,2) DEFAULT 0,
  `threads` INT DEFAULT 0,
  `uptime` BIGINT DEFAULT 0,
  `timestamp` BIGINT NOT NULL,
  INDEX `idx_resource` (`resource_name`),
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Network Metrics History (network performance tracking)
CREATE TABLE IF NOT EXISTS `ec_network_metrics_history` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `timestamp` BIGINT NOT NULL,
  `players_online` INT DEFAULT 0,
  `peak_count` INT DEFAULT 0,
  `avg_ping` DECIMAL(5,2) DEFAULT 0,
  `bandwidth_in` DECIMAL(10,2) DEFAULT 0,
  `bandwidth_out` DECIMAL(10,2) DEFAULT 0,
  `connections` INT DEFAULT 0,
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Database Metrics History (database performance tracking)
CREATE TABLE IF NOT EXISTS `ec_database_metrics_history` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `timestamp` BIGINT NOT NULL,
  `queries` INT DEFAULT 0,
  `avg_query_time` DECIMAL(10,2) DEFAULT 0,
  `slow_queries` INT DEFAULT 0,
  `connections` INT DEFAULT 0,
  `database_size` DECIMAL(15,2) DEFAULT 0,
  INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Resource Restart Log (audit trail for resource actions)
CREATE TABLE IF NOT EXISTS `ec_resource_restart_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `resource_name` VARCHAR(100) NOT NULL,
  `restarted_by` VARCHAR(50) NOT NULL,
  `restart_time` BIGINT NOT NULL,
  `success` TINYINT(1) DEFAULT 1,
  `error_message` TEXT,
  INDEX `idx_resource` (`resource_name`),
  INDEX `idx_restart_time` (`restart_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

