-- EC Admin Ultimate - Host Management Database Tables
-- Extended tables for ban appeals, webhooks, warnings, NRG staff
-- Version: 1.0.0

-- Ban appeals system
CREATE TABLE IF NOT EXISTS `ec_host_ban_appeals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ban_id` int(11) NOT NULL,
  `appeal_reason` text NOT NULL,
  `evidence` text DEFAULT NULL,
  `contact_info` varchar(255) DEFAULT NULL,
  `submitted_at` int(11) NOT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `reviewed_by` varchar(255) DEFAULT NULL,
  `reviewed_at` int(11) DEFAULT NULL,
  `review_notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ban_id` (`ban_id`),
  KEY `status` (`status`),
  KEY `submitted_at` (`submitted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Webhooks configuration
CREATE TABLE IF NOT EXISTS `ec_host_webhooks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `webhook_name` varchar(255) NOT NULL,
  `webhook_url` varchar(500) NOT NULL,
  `event_type` varchar(100) NOT NULL,
  `enabled` tinyint(1) DEFAULT 1,
  `config` longtext DEFAULT NULL,
  `created_by` varchar(255) NOT NULL,
  `created_at` int(11) NOT NULL,
  `updated_by` varchar(255) DEFAULT NULL,
  `updated_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `event_type` (`event_type`),
  KEY `enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Webhook execution logs
CREATE TABLE IF NOT EXISTS `ec_host_webhook_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `webhook_id` int(11) NOT NULL,
  `event_type` varchar(100) NOT NULL,
  `status` varchar(20) NOT NULL,
  `response` text DEFAULT NULL,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `webhook_id` (`webhook_id`),
  KEY `event_type` (`event_type`),
  KEY `status` (`status`),
  KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Global warnings system
CREATE TABLE IF NOT EXISTS `ec_host_global_warnings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `player_name` varchar(255) NOT NULL,
  `reason` text NOT NULL,
  `issued_by` varchar(255) NOT NULL,
  `issued_at` int(11) NOT NULL,
  `severity` varchar(20) DEFAULT 'medium',
  `active` tinyint(1) DEFAULT 1,
  `applied_cities` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `active` (`active`),
  KEY `severity` (`severity`),
  KEY `issued_at` (`issued_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- NRG Staff registry
CREATE TABLE IF NOT EXISTS `ec_host_nrg_staff` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL UNIQUE,
  `staff_name` varchar(255) NOT NULL,
  `role` varchar(100) DEFAULT 'admin',
  `permissions` text DEFAULT NULL,
  `added_by` varchar(255) NOT NULL,
  `added_at` int(11) NOT NULL,
  `last_seen` int(11) DEFAULT NULL,
  `active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- NRG Staff activity log
CREATE TABLE IF NOT EXISTS `ec_host_staff_activity` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `staff_identifier` varchar(255) NOT NULL,
  `staff_name` varchar(255) NOT NULL,
  `city_id` varchar(100) DEFAULT NULL,
  `city_name` varchar(255) DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `details` longtext DEFAULT NULL,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `staff_identifier` (`staff_identifier`),
  KEY `city_id` (`city_id`),
  KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Global player notes (cross-city notes)
CREATE TABLE IF NOT EXISTS `ec_host_player_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `player_name` varchar(255) NOT NULL,
  `note` text NOT NULL,
  `note_type` varchar(50) DEFAULT 'general',
  `added_by` varchar(255) NOT NULL,
  `added_at` int(11) NOT NULL,
  `visible_to_cities` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `note_type` (`note_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Cross-city player tracking
CREATE TABLE IF NOT EXISTS `ec_host_player_tracking` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `player_name` varchar(255) NOT NULL,
  `city_id` varchar(100) NOT NULL,
  `first_seen` int(11) NOT NULL,
  `last_seen` int(11) NOT NULL,
  `total_playtime` int(11) DEFAULT 0,
  `times_connected` int(11) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier_city` (`identifier`, `city_id`),
  KEY `identifier` (`identifier`),
  KEY `city_id` (`city_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Host notifications system
CREATE TABLE IF NOT EXISTS `ec_host_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `notification_type` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `severity` varchar(20) DEFAULT 'info',
  `target_staff` varchar(255) DEFAULT NULL,
  `target_all_staff` tinyint(1) DEFAULT 0,
  `read_by` text DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `expires_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `notification_type` (`notification_type`),
  KEY `severity` (`severity`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- API rate limiting tracking
CREATE TABLE IF NOT EXISTS `ec_host_rate_limits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(255) NOT NULL,
  `api_name` varchar(100) NOT NULL,
  `requests_count` int(11) DEFAULT 0,
  `window_start` int(11) NOT NULL,
  `window_end` int(11) NOT NULL,
  `blocked` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier_api_window` (`identifier`, `api_name`, `window_start`),
  KEY `identifier` (`identifier`),
  KEY `api_name` (`api_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Global blacklist (IPs, VPNs, etc)
CREATE TABLE IF NOT EXISTS `ec_host_global_blacklist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `blacklist_type` varchar(50) NOT NULL,
  `value` varchar(255) NOT NULL,
  `reason` text NOT NULL,
  `added_by` varchar(255) NOT NULL,
  `added_at` int(11) NOT NULL,
  `expires_at` int(11) DEFAULT NULL,
  `active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `blacklist_type` (`blacklist_type`),
  KEY `value` (`value`),
  KEY `active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default webhook event types
INSERT INTO `ec_host_webhooks` (`webhook_name`, `webhook_url`, `event_type`, `enabled`, `created_by`, `created_at`)
VALUES 
  ('Global Bans', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 'global_ban', 0, 'System', UNIX_TIMESTAMP()),
  ('Global Unbans', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 'global_unban', 0, 'System', UNIX_TIMESTAMP()),
  ('Ban Appeals', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 'ban_appeal_submitted', 0, 'System', UNIX_TIMESTAMP()),
  ('Global Warnings', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 'global_warning', 0, 'System', UNIX_TIMESTAMP()),
  ('City Connections', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 'city_connected', 0, 'System', UNIX_TIMESTAMP()),
  ('API Alerts', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 'api_error', 0, 'System', UNIX_TIMESTAMP()),
  ('Emergency Actions', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 'emergency_stop', 0, 'System', UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE `id`=`id`;

-- Create views for easy querying

-- Active ban appeals
CREATE OR REPLACE VIEW v_pending_ban_appeals AS
SELECT 
  ba.id,
  ba.ban_id,
  ba.appeal_reason,
  ba.submitted_at,
  gb.identifier,
  gb.player_name,
  gb.reason as ban_reason,
  gb.banned_by,
  gb.banned_at,
  DATEDIFF(NOW(), FROM_UNIXTIME(ba.submitted_at)) as days_pending
FROM ec_host_ban_appeals ba
LEFT JOIN ec_host_global_bans gb ON ba.ban_id = gb.id
WHERE ba.status = 'pending'
ORDER BY ba.submitted_at ASC;

-- Active global bans
CREATE OR REPLACE VIEW v_active_global_bans AS
SELECT 
  gb.*,
  (SELECT COUNT(*) FROM ec_host_ban_appeals WHERE ban_id = gb.id) as appeal_count,
  CASE 
    WHEN gb.is_permanent = 1 THEN 'Permanent'
    WHEN gb.expires_at IS NULL THEN 'Permanent'
    WHEN gb.expires_at < UNIX_TIMESTAMP() THEN 'Expired'
    ELSE 'Active'
  END as ban_status
FROM ec_host_global_bans gb
WHERE gb.active = 1
ORDER BY gb.banned_at DESC;

-- Webhook statistics
CREATE OR REPLACE VIEW v_webhook_stats AS
SELECT 
  hw.id,
  hw.webhook_name,
  hw.event_type,
  hw.enabled,
  COUNT(wl.id) as total_executions,
  SUM(CASE WHEN wl.status = 'success' THEN 1 ELSE 0 END) as successful_executions,
  SUM(CASE WHEN wl.status = 'failed' THEN 1 ELSE 0 END) as failed_executions,
  MAX(wl.timestamp) as last_execution
FROM ec_host_webhooks hw
LEFT JOIN ec_host_webhook_logs wl ON hw.id = wl.webhook_id
GROUP BY hw.id;

-- NRG Staff activity summary
CREATE OR REPLACE VIEW v_staff_activity_summary AS
SELECT 
  sa.staff_identifier,
  sa.staff_name,
  COUNT(*) as total_actions,
  COUNT(DISTINCT sa.city_id) as cities_accessed,
  MAX(sa.timestamp) as last_action,
  SUM(CASE WHEN sa.timestamp > UNIX_TIMESTAMP() - 86400 THEN 1 ELSE 0 END) as actions_today
FROM ec_host_staff_activity sa
GROUP BY sa.staff_identifier, sa.staff_name;

-- Player global history
CREATE OR REPLACE VIEW v_player_global_history AS
SELECT 
  pt.identifier,
  pt.player_name,
  COUNT(DISTINCT pt.city_id) as cities_played,
  SUM(pt.total_playtime) as total_playtime_all_cities,
  SUM(pt.times_connected) as total_connections,
  (SELECT COUNT(*) FROM ec_host_global_bans WHERE identifier = pt.identifier) as ban_count,
  (SELECT COUNT(*) FROM ec_host_global_warnings WHERE identifier = pt.identifier AND active = 1) as warning_count,
  MAX(pt.last_seen) as last_seen_any_city
FROM ec_host_player_tracking pt
GROUP BY pt.identifier, pt.player_name;

-- Optimization indexes
CREATE INDEX idx_ban_appeals_status ON ec_host_ban_appeals(status, submitted_at DESC);
CREATE INDEX idx_webhooks_event_enabled ON ec_host_webhooks(event_type, enabled);
CREATE INDEX idx_webhook_logs_webhook_time ON ec_host_webhook_logs(webhook_id, timestamp DESC);
CREATE INDEX idx_global_warnings_active ON ec_host_global_warnings(active, issued_at DESC);
CREATE INDEX idx_staff_activity_time ON ec_host_staff_activity(timestamp DESC);
CREATE INDEX idx_player_tracking_identifier ON ec_host_player_tracking(identifier, last_seen DESC);

-- Clean up old data (optional, run periodically)
-- Delete webhook logs older than 30 days
-- DELETE FROM ec_host_webhook_logs WHERE timestamp < UNIX_TIMESTAMP() - (30 * 86400);

-- Delete inactive warnings older than 90 days
-- DELETE FROM ec_host_global_warnings WHERE active = 0 AND issued_at < UNIX_TIMESTAMP() - (90 * 86400);

-- Backup recommendations
-- 1. Backup ec_host_global_bans daily
-- 2. Backup ec_host_ban_appeals daily
-- 3. Backup ec_host_webhooks weekly
-- 4. Backup ec_host_nrg_staff weekly
