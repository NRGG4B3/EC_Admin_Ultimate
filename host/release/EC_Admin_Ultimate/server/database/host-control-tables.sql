-- EC Admin Ultimate - Host Control Database Tables
-- Tables for host control system logging and management
-- Version: 1.0.0

-- Host control action logs
CREATE TABLE IF NOT EXISTS `ec_host_actions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_id` varchar(255) NOT NULL,
  `admin_name` varchar(255) NOT NULL,
  `action_type` varchar(50) NOT NULL,
  `target` varchar(255) NOT NULL,
  `action` varchar(50) NOT NULL,
  `params` longtext DEFAULT NULL,
  `success` tinyint(1) DEFAULT 1,
  `error` text DEFAULT NULL,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `admin_id` (`admin_id`),
  KEY `action_type` (`action_type`),
  KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- API status history
CREATE TABLE IF NOT EXISTS `ec_host_api_status` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `api_name` varchar(100) NOT NULL,
  `status` varchar(20) NOT NULL,
  `uptime` int(11) DEFAULT 0,
  `requests` int(11) DEFAULT 0,
  `avg_response_time` int(11) DEFAULT 0,
  `error_rate` decimal(5,4) DEFAULT 0,
  `cpu_usage` decimal(5,2) DEFAULT 0,
  `memory_usage` int(11) DEFAULT 0,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `api_name` (`api_name`),
  KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Connected cities tracking
CREATE TABLE IF NOT EXISTS `ec_host_cities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `city_id` varchar(100) NOT NULL UNIQUE,
  `city_name` varchar(255) NOT NULL,
  `ip_address` varchar(50) NOT NULL,
  `status` varchar(20) NOT NULL,
  `framework` varchar(50) DEFAULT NULL,
  `version` varchar(20) DEFAULT NULL,
  `first_connected` int(11) NOT NULL,
  `last_seen` int(11) NOT NULL,
  `total_uptime` int(11) DEFAULT 0,
  `connected_apis` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `city_id` (`city_id`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- City metrics history
CREATE TABLE IF NOT EXISTS `ec_host_city_metrics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `city_id` varchar(100) NOT NULL,
  `players` int(11) DEFAULT 0,
  `max_players` int(11) DEFAULT 0,
  `tps` decimal(5,2) DEFAULT 0,
  `cpu_usage` decimal(5,2) DEFAULT 0,
  `memory_usage` int(11) DEFAULT 0,
  `network_in` decimal(10,2) DEFAULT 0,
  `network_out` decimal(10,2) DEFAULT 0,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `city_id` (`city_id`),
  KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Global ban registry (synced across all cities)
CREATE TABLE IF NOT EXISTS `ec_host_global_bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `player_name` varchar(255) NOT NULL,
  `reason` text NOT NULL,
  `banned_by` varchar(255) NOT NULL,
  `banned_at` int(11) NOT NULL,
  `expires_at` int(11) DEFAULT NULL,
  `is_permanent` tinyint(1) DEFAULT 0,
  `active` tinyint(1) DEFAULT 1,
  `applied_cities` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `active` (`active`),
  KEY `expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- API alerts and notifications
CREATE TABLE IF NOT EXISTS `ec_host_alerts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `alert_type` varchar(50) NOT NULL,
  `severity` varchar(20) NOT NULL,
  `source` varchar(100) NOT NULL,
  `message` text NOT NULL,
  `details` longtext DEFAULT NULL,
  `acknowledged` tinyint(1) DEFAULT 0,
  `acknowledged_by` varchar(255) DEFAULT NULL,
  `acknowledged_at` int(11) DEFAULT NULL,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `alert_type` (`alert_type`),
  KEY `severity` (`severity`),
  KEY `acknowledged` (`acknowledged`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Config sync history
CREATE TABLE IF NOT EXISTS `ec_host_config_sync` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `city_id` varchar(100) NOT NULL,
  `config_type` varchar(50) NOT NULL,
  `config_data` longtext NOT NULL,
  `synced_by` varchar(255) NOT NULL,
  `synced_at` int(11) NOT NULL,
  `success` tinyint(1) DEFAULT 1,
  `error` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `city_id` (`city_id`),
  KEY `config_type` (`config_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Backup history
CREATE TABLE IF NOT EXISTS `ec_host_backups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `city_id` varchar(100) NOT NULL,
  `backup_type` varchar(50) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_size` bigint(20) DEFAULT 0,
  `created_by` varchar(255) NOT NULL,
  `created_at` int(11) NOT NULL,
  `restored_at` int(11) DEFAULT NULL,
  `restored_by` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `city_id` (`city_id`),
  KEY `backup_type` (`backup_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- API usage statistics (aggregated)
CREATE TABLE IF NOT EXISTS `ec_host_api_stats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `api_name` varchar(100) NOT NULL,
  `stat_date` date NOT NULL,
  `total_requests` bigint(20) DEFAULT 0,
  `total_errors` int(11) DEFAULT 0,
  `avg_response_time` int(11) DEFAULT 0,
  `peak_requests_per_minute` int(11) DEFAULT 0,
  `downtime_minutes` int(11) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `api_stat_date` (`api_name`, `stat_date`),
  KEY `stat_date` (`stat_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert sample data for testing (optional)
-- This data will be replaced with real data from APIs

-- Sample host action
INSERT INTO `ec_host_actions` (`admin_id`, `admin_name`, `action_type`, `target`, `action`, `params`, `success`, `timestamp`)
VALUES ('steam:110000103fd1bb1', 'System', 'API_CONTROL', 'analytics', 'restart', NULL, 1, UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE `id`=`id`;

-- Sample global ban
INSERT INTO `ec_host_global_bans` (`identifier`, `player_name`, `reason`, `banned_by`, `banned_at`, `is_permanent`, `active`)
VALUES ('steam:example123', 'Cheater Example', 'Caught using aimbot', 'NRG Admin', UNIX_TIMESTAMP(), 1, 1)
ON DUPLICATE KEY UPDATE `id`=`id`;

-- Sample alert
INSERT INTO `ec_host_alerts` (`alert_type`, `severity`, `source`, `message`, `acknowledged`, `timestamp`)
VALUES ('API_ERROR', 'high', 'anticheat-sync', 'High error rate detected', 0, UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE `id`=`id`;

-- Indexes for performance optimization
CREATE INDEX idx_host_actions_timestamp ON ec_host_actions(timestamp DESC);
CREATE INDEX idx_host_api_status_api_time ON ec_host_api_status(api_name, timestamp DESC);
CREATE INDEX idx_host_city_metrics_city_time ON ec_host_city_metrics(city_id, timestamp DESC);
CREATE INDEX idx_host_alerts_severity_ack ON ec_host_alerts(severity, acknowledged);

-- Views for easy querying

-- Recent host actions
CREATE OR REPLACE VIEW v_recent_host_actions AS
SELECT 
  ha.*,
  FROM_UNIXTIME(ha.timestamp) as action_datetime
FROM ec_host_actions ha
ORDER BY ha.timestamp DESC
LIMIT 100;

-- Active alerts
CREATE OR REPLACE VIEW v_active_alerts AS
SELECT 
  ha.*,
  FROM_UNIXTIME(ha.timestamp) as alert_datetime
FROM ec_host_alerts ha
WHERE ha.acknowledged = 0
ORDER BY 
  CASE ha.severity
    WHEN 'critical' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    WHEN 'low' THEN 4
  END,
  ha.timestamp DESC;

-- Online cities summary
CREATE OR REPLACE VIEW v_online_cities AS
SELECT 
  hc.*,
  FROM_UNIXTIME(hc.last_seen) as last_seen_datetime,
  (SELECT COUNT(*) FROM ec_host_city_metrics WHERE city_id = hc.city_id) as metrics_count
FROM ec_host_cities hc
WHERE hc.status = 'online'
ORDER BY hc.last_seen DESC;

-- API health summary
CREATE OR REPLACE VIEW v_api_health AS
SELECT 
  api_name,
  status,
  AVG(avg_response_time) as avg_response,
  MAX(error_rate) as max_error_rate,
  COUNT(*) as check_count,
  FROM_UNIXTIME(MAX(timestamp)) as last_check
FROM ec_host_api_status
WHERE timestamp > UNIX_TIMESTAMP() - 3600
GROUP BY api_name, status;
