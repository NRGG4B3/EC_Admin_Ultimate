-- ============================================================================
-- EC Admin Ultimate - Dashboard Schema
-- ============================================================================
-- SQL migration file for dashboard metrics tracking
-- Run this SQL to create the required tables for dashboard data persistence
-- ============================================================================

-- Table: Server Metrics History (metrics tracking for charts)
CREATE TABLE IF NOT EXISTS `ec_server_metrics_history` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `timestamp` BIGINT NOT NULL,
  `players_online` INT DEFAULT 0,
  `server_tps` DECIMAL(5,2) DEFAULT 0,
  `cached_vehicles` INT DEFAULT 0,
  `memory_usage` DECIMAL(10,2) DEFAULT 0,
  `cpu_usage` DECIMAL(5,2) DEFAULT 0,
  `network_in` DECIMAL(10,2) DEFAULT 0,
  `network_out` DECIMAL(10,2) DEFAULT 0,
  `avg_ping` DECIMAL(5,2) DEFAULT 0,
  INDEX `idx_timestamp` (`timestamp`),
  INDEX `idx_date` (DATE(FROM_UNIXTIME(timestamp)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Dashboard Statistics (daily aggregated stats)
CREATE TABLE IF NOT EXISTS `ec_dashboard_statistics` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `date` DATE NOT NULL,
  `peak_players` INT DEFAULT 0,
  `new_players` INT DEFAULT 0,
  `total_resources` INT DEFAULT 0,
  `avg_tps` DECIMAL(5,2) DEFAULT 0,
  `avg_memory` DECIMAL(10,2) DEFAULT 0,
  `avg_cpu` DECIMAL(5,2) DEFAULT 0,
  `total_network_in` DECIMAL(15,2) DEFAULT 0,
  `total_network_out` DECIMAL(15,2) DEFAULT 0,
  UNIQUE KEY `unique_date` (`date`),
  INDEX `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

