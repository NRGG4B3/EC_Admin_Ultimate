-- ============================================================================
-- EC ADMIN ULTIMATE - CUSTOMER DATABASE SCHEMA
-- ============================================================================
-- Version: 1.0.0
-- Description: Complete database schema for EC Admin Ultimate (Customer Side)
-- Purpose: All tables required for city owners to run EC Admin Ultimate
-- Installation: Run this file in your database ONCE during initial setup
-- Auto-install: This schema is also auto-installed by the resource on first run
-- ============================================================================

-- ============================================================================
-- CORE ADMIN TABLES
-- ============================================================================

-- Admin Permissions
CREATE TABLE IF NOT EXISTS `ec_admin_permissions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `permission_level` INT DEFAULT 1,
    `permissions` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `identifier_unique` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Admin Logs (Legacy - kept for compatibility)
CREATE TABLE IF NOT EXISTS `ec_admin_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_identifier` VARCHAR(100) NOT NULL,
    `admin_name` VARCHAR(100) NOT NULL,
    `action` VARCHAR(100) NOT NULL,
    `target_identifier` VARCHAR(100) NULL,
    `target_name` VARCHAR(100) NULL,
    `details` TEXT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_admin` (`admin_identifier`),
    INDEX `idx_action` (`action`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Admin Action Logs (Primary logging table)
CREATE TABLE IF NOT EXISTS `ec_admin_action_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_identifier` VARCHAR(100) NOT NULL,
    `admin_name` VARCHAR(100) NOT NULL,
    `action` VARCHAR(255) NOT NULL,
    `category` VARCHAR(50) DEFAULT 'general',
    `action_type` VARCHAR(50) NULL,
    `target_identifier` VARCHAR(100) NULL,
    `target_name` VARCHAR(100) NULL,
    `details` TEXT NULL,
    `metadata` JSON NULL,
    `timestamp` BIGINT(20) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_admin` (`admin_identifier`),
    INDEX `idx_action` (`action`),
    INDEX `idx_category` (`category`),
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Action Logs (Alternative Name)
CREATE TABLE IF NOT EXISTS `ec_action_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_id` VARCHAR(100) NOT NULL,
    `admin_name` VARCHAR(100) NOT NULL,
    `action` VARCHAR(255) NOT NULL,
    `target_id` VARCHAR(100) NULL,
    `target_name` VARCHAR(100) NULL,
    `details` TEXT NULL,
    `timestamp` BIGINT(20) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_admin` (`admin_id`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Moderation Logs
CREATE TABLE IF NOT EXISTS `ec_moderation_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `moderator_id` VARCHAR(100) NOT NULL,
    `moderator_name` VARCHAR(100) NOT NULL,
    `action_type` VARCHAR(100) NOT NULL,
    `target_id` VARCHAR(100) NULL,
    `target_name` VARCHAR(100) NULL,
    `reason` TEXT NULL,
    `details` TEXT NULL,
    `timestamp` BIGINT(20) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_moderator` (`moderator_id`),
    INDEX `idx_action_type` (`action_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- MODERATION TABLES
-- ============================================================================

-- Bans
CREATE TABLE IF NOT EXISTS `ec_admin_bans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `license` VARCHAR(100) NULL,
    `discord` VARCHAR(100) NULL,
    `fivem` VARCHAR(100) NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `reason` TEXT NOT NULL,
    `banned_by` VARCHAR(100) NOT NULL,
    `ip` VARCHAR(45) NULL,
    `ban_type` VARCHAR(50) DEFAULT 'temporary',
    `expires` BIGINT(20) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_active` TINYINT(1) DEFAULT 1,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_expires` (`expires`),
    INDEX `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Warnings
CREATE TABLE IF NOT EXISTS `ec_admin_warnings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `reason` TEXT NOT NULL,
    `warned_by` VARCHAR(100) NOT NULL,
    `severity` VARCHAR(50) DEFAULT 'medium',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reports
CREATE TABLE IF NOT EXISTS `ec_admin_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `reporter_identifier` VARCHAR(100) NOT NULL,
    `reporter_name` VARCHAR(100) NOT NULL,
    `reported_identifier` VARCHAR(100) NULL,
    `reported_name` VARCHAR(100) NULL,
    `reason` TEXT NOT NULL,
    `status` VARCHAR(50) DEFAULT 'pending',
    `handled_by` VARCHAR(100) NULL,
    `handled_at` TIMESTAMP NULL,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_status` (`status`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reports (Alternative Table Name)
CREATE TABLE IF NOT EXISTS `ec_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `reporter_id` VARCHAR(100) NOT NULL,
    `reporter_name` VARCHAR(100) NOT NULL,
    `reported_id` VARCHAR(100) NULL,
    `reported_name` VARCHAR(100) NULL,
    `reason` TEXT NOT NULL,
    `category` VARCHAR(50) DEFAULT 'general',
    `status` VARCHAR(50) DEFAULT 'open',
    `priority` VARCHAR(20) DEFAULT 'medium',
    `handled_by` VARCHAR(100) NULL,
    `handled_at` TIMESTAMP NULL,
    `notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_status` (`status`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player Reports (Legacy/Extended)
CREATE TABLE IF NOT EXISTS `player_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `reported_player` VARCHAR(100) NOT NULL,
    `reported_license` VARCHAR(100) NULL,
    `reporter` VARCHAR(100) NOT NULL,
    `reporter_license` VARCHAR(100) NULL,
    `reason` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `category` VARCHAR(50) DEFAULT 'general',
    `status` VARCHAR(50) DEFAULT 'pending',
    `priority` VARCHAR(20) DEFAULT 'medium',
    `timestamp` BIGINT(20) NOT NULL,
    `evidence` TEXT NULL,
    INDEX `idx_status` (`status`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Activity Logs
CREATE TABLE IF NOT EXISTS `activity_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `event_type` VARCHAR(100) NOT NULL,
    `user_identifier` VARCHAR(100) NULL,
    `details` TEXT NULL,
    `severity` VARCHAR(20) DEFAULT 'info',
    `category` VARCHAR(50) DEFAULT 'general',
    `timestamp` BIGINT(20) NOT NULL,
    `ip_address` VARCHAR(45) NULL,
    `metadata` JSON NULL,
    INDEX `idx_event_type` (`event_type`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- System Reports
CREATE TABLE IF NOT EXISTS `system_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(200) NOT NULL,
    `report_type` VARCHAR(50) NOT NULL,
    `category` VARCHAR(50) DEFAULT 'general',
    `status` VARCHAR(50) DEFAULT 'generated',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `generated_by` VARCHAR(100) NULL,
    `report_data` LONGTEXT NULL,
    `format` VARCHAR(20) DEFAULT 'json',
    INDEX `idx_type` (`report_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Error Logs
CREATE TABLE IF NOT EXISTS `error_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `error_type` VARCHAR(100) NOT NULL,
    `message` TEXT NOT NULL,
    `stack_trace` TEXT NULL,
    `resource_name` VARCHAR(100) NULL,
    `timestamp` BIGINT(20) NOT NULL,
    `severity` VARCHAR(20) DEFAULT 'error',
    `resolved` TINYINT(1) DEFAULT 0,
    `occurrences` INT DEFAULT 1,
    INDEX `idx_error_type` (`error_type`),
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_resolved` (`resolved`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Scheduled Reports
CREATE TABLE IF NOT EXISTS `scheduled_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `report_type` VARCHAR(50) NOT NULL,
    `schedule` VARCHAR(50) NOT NULL,
    `recipients` TEXT NOT NULL,
    `filters` TEXT NULL,
    `enabled` TINYINT(1) DEFAULT 1,
    `last_run` TIMESTAMP NULL,
    `next_run` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_enabled` (`enabled`),
    INDEX `idx_next_run` (`next_run`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ADMIN TEAM MANAGEMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_admin_team` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `role` VARCHAR(50) NOT NULL,
    `permissions` TEXT NULL,
    `added_by` VARCHAR(100) NOT NULL,
    `added_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_active` TINYINT(1) DEFAULT 1,
    UNIQUE KEY `identifier_unique` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- AI DETECTION & ANTICHEAT
-- ============================================================================

-- AI Detections (Live)
CREATE TABLE IF NOT EXISTS `ai_detections_live` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `detection_type` VARCHAR(100) NOT NULL,
    `confidence` FLOAT NOT NULL,
    `details` TEXT NULL,
    `action_taken` VARCHAR(50) NULL,
    `is_false_positive` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_detection_type` (`detection_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- AI Detection Rules
CREATE TABLE IF NOT EXISTS `ai_detection_rules` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `rule_name` VARCHAR(100) NOT NULL,
    `detection_type` VARCHAR(100) NOT NULL,
    `threshold` FLOAT NOT NULL,
    `action` VARCHAR(50) NOT NULL,
    `enabled` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- AI Detection Whitelist
CREATE TABLE IF NOT EXISTS `ai_detection_whitelist` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `reason` TEXT NULL,
    `added_by` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `identifier_unique` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- AI Detections (Extended)
CREATE TABLE IF NOT EXISTS `ec_ai_detections` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NULL,
    `detection_type` VARCHAR(100) NOT NULL,
    `confidence_score` FLOAT DEFAULT 0.0,
    `behavior_pattern` TEXT NULL,
    `evidence` TEXT NULL,
    `action_taken` VARCHAR(50) NULL,
    `reviewed_by` VARCHAR(100) NULL,
    `is_false_positive` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player` (`player_id`),
    INDEX `idx_type` (`detection_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- AI Player Patterns
CREATE TABLE IF NOT EXISTS `ec_ai_player_patterns` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(100) NOT NULL,
    `pattern_type` VARCHAR(50) NOT NULL,
    `pattern_data` TEXT NULL,
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `player_pattern` (`player_id`, `pattern_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- AI Behavior Logs
CREATE TABLE IF NOT EXISTS `ec_ai_behavior_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(100) NOT NULL,
    `action_type` VARCHAR(100) NOT NULL,
    `action_data` TEXT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player` (`player_id`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- AI Analytics Snapshots
CREATE TABLE IF NOT EXISTS `ai_analytics_snapshots` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `snapshot_type` VARCHAR(50) NOT NULL,
    `data` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_snapshot_type` (`snapshot_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Anticheat Detections
CREATE TABLE IF NOT EXISTS `ec_anticheat_detections` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `detection_type` VARCHAR(100) NOT NULL,
    `severity` VARCHAR(20) DEFAULT 'medium',
    `details` TEXT NULL,
    `evidence` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player` (`player_id`),
    INDEX `idx_type` (`detection_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Anticheat Flags
CREATE TABLE IF NOT EXISTS `ec_anticheat_flags` (
    `player_id` VARCHAR(100) PRIMARY KEY,
    `player_name` VARCHAR(100) NOT NULL,
    `risk_score` INT DEFAULT 0,
    `total_detections` INT DEFAULT 0,
    `last_detection` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_risk` (`risk_score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Anticheat Bans
CREATE TABLE IF NOT EXISTS `ec_anticheat_bans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `reason` TEXT NOT NULL,
    `evidence` TEXT NULL,
    `ban_type` VARCHAR(50) DEFAULT 'permanent',
    `expires_at` TIMESTAMP NULL,
    `banned_by` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Anticheat Whitelist
CREATE TABLE IF NOT EXISTS `ec_anticheat_whitelist` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `reason` TEXT NULL,
    `added_by` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `player_unique` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SETTINGS & CONFIGURATION
-- ============================================================================

-- Settings Storage
CREATE TABLE IF NOT EXISTS `ec_admin_settings` (
    `id` INT DEFAULT 1 PRIMARY KEY,
    `settings` LONGTEXT NULL,
    `webhooks` LONGTEXT NULL,
    `permissions` LONGTEXT NULL,
    `updated_by` VARCHAR(100) NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Settings History
CREATE TABLE IF NOT EXISTS `ec_settings_history` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `category` VARCHAR(50) NOT NULL,
    `changed_by` VARCHAR(100) NOT NULL,
    `old_value` TEXT NULL,
    `new_value` TEXT NULL,
    `change_description` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_category` (`category`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- WHITELIST SYSTEM
-- ============================================================================

-- Whitelist
CREATE TABLE IF NOT EXISTS `ec_whitelist` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NULL,
    `role` VARCHAR(50) DEFAULT 'member',
    `priority` INT DEFAULT 0,
    `added_by` VARCHAR(100) NULL,
    `added_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_active` TINYINT(1) DEFAULT 1,
    UNIQUE KEY `identifier_unique` (`identifier`),
    INDEX `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Whitelist Applications
CREATE TABLE IF NOT EXISTS `ec_whitelist_applications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `discord_id` VARCHAR(100) NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `reason` TEXT NOT NULL,
    `status` VARCHAR(50) DEFAULT 'pending',
    `reviewed_by` VARCHAR(100) NULL,
    `reviewed_at` TIMESTAMP NULL,
    `review_notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_status` (`status`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Whitelist Roles
CREATE TABLE IF NOT EXISTS `ec_whitelist_roles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `role_name` VARCHAR(100) NOT NULL,
    `display_name` VARCHAR(100) NOT NULL,
    `priority` INT DEFAULT 0,
    `permissions` TEXT NULL,
    `color` VARCHAR(7) DEFAULT '#3b82f6',
    `is_default` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `role_name_unique` (`role_name`),
    INDEX `idx_priority` (`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- COMMUNITY MANAGEMENT
-- ============================================================================

-- Community Groups
CREATE TABLE IF NOT EXISTS `ec_community_groups` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `group_type` ENUM('crew', 'clan', 'organization', 'faction', 'custom') DEFAULT 'custom',
    `leader_id` VARCHAR(50) NOT NULL,
    `leader_name` VARCHAR(100) NOT NULL,
    `member_count` INT DEFAULT 0,
    `max_members` INT DEFAULT 50,
    `is_public` BOOLEAN DEFAULT 1,
    `discord_webhook` VARCHAR(255) NULL,
    `color` VARCHAR(7) DEFAULT '#3b82f6',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_leader` (`leader_id`),
    INDEX `idx_type` (`group_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Community Members
CREATE TABLE IF NOT EXISTS `ec_community_members` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `group_id` INT NOT NULL,
    `player_id` VARCHAR(50) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `role` ENUM('leader', 'officer', 'member') DEFAULT 'member',
    `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_member` (`group_id`, `player_id`),
    INDEX `idx_player` (`player_id`),
    FOREIGN KEY (`group_id`) REFERENCES `ec_community_groups`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Community Events
CREATE TABLE IF NOT EXISTS `ec_community_events` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT NULL,
    `event_type` ENUM('race', 'tournament', 'meetup', 'heist', 'custom') DEFAULT 'custom',
    `organizer_id` VARCHAR(50) NOT NULL,
    `organizer_name` VARCHAR(100) NOT NULL,
    `start_time` TIMESTAMP NOT NULL,
    `duration` INT DEFAULT 60,
    `location` VARCHAR(255) NULL,
    `max_participants` INT DEFAULT 50,
    `participant_count` INT DEFAULT 0,
    `prize_pool` INT DEFAULT 0,
    `status` ENUM('scheduled', 'ongoing', 'completed', 'cancelled') DEFAULT 'scheduled',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_organizer` (`organizer_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_start` (`start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Event Participants
CREATE TABLE IF NOT EXISTS `ec_community_event_participants` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `event_id` INT NOT NULL,
    `player_id` VARCHAR(50) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `registered_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_participant` (`event_id`, `player_id`),
    FOREIGN KEY (`event_id`) REFERENCES `ec_community_events`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Community Achievements
CREATE TABLE IF NOT EXISTS `ec_community_achievements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `category` VARCHAR(50) DEFAULT 'general',
    `icon` VARCHAR(50) DEFAULT 'trophy',
    `points` INT DEFAULT 10,
    `requirement_type` VARCHAR(50) NOT NULL,
    `requirement_value` INT DEFAULT 1,
    `is_secret` BOOLEAN DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player Achievements
CREATE TABLE IF NOT EXISTS `ec_community_player_achievements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(50) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `achievement_id` INT NOT NULL,
    `unlocked_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_unlock` (`player_id`, `achievement_id`),
    INDEX `idx_player` (`player_id`),
    FOREIGN KEY (`achievement_id`) REFERENCES `ec_community_achievements`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Community Leaderboards
CREATE TABLE IF NOT EXISTS `ec_community_leaderboards` (
    `player_id` VARCHAR(50) PRIMARY KEY,
    `player_name` VARCHAR(100) NOT NULL,
    `total_playtime` INT DEFAULT 0,
    `total_money` INT DEFAULT 0,
    `total_arrests` INT DEFAULT 0,
    `total_deaths` INT DEFAULT 0,
    `total_kills` INT DEFAULT 0,
    `achievement_points` INT DEFAULT 0,
    `reputation_score` INT DEFAULT 0,
    `rank_position` INT DEFAULT 0,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_playtime` (`total_playtime`),
    INDEX `idx_money` (`total_money`),
    INDEX `idx_achievements` (`achievement_points`),
    INDEX `idx_rank` (`rank_position`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Community Announcements
CREATE TABLE IF NOT EXISTS `ec_community_announcements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(200) NOT NULL,
    `message` TEXT NOT NULL,
    `announcement_type` ENUM('info', 'warning', 'success', 'event', 'update') DEFAULT 'info',
    `posted_by` VARCHAR(100) NOT NULL,
    `priority` INT DEFAULT 1,
    `is_pinned` BOOLEAN DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_priority` (`priority`),
    INDEX `idx_pinned` (`is_pinned`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Announcements (Alternative Name)
CREATE TABLE IF NOT EXISTS `ec_announcements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(200) NOT NULL,
    `content` TEXT NOT NULL,
    `type` VARCHAR(50) DEFAULT 'info',
    `posted_by` VARCHAR(100) NOT NULL,
    `priority` INT DEFAULT 1,
    `is_pinned` BOOLEAN DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Community Social Feed
CREATE TABLE IF NOT EXISTS `ec_community_social` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(50) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `action_type` ENUM('status', 'achievement', 'event', 'group') NOT NULL,
    `message` TEXT NOT NULL,
    `metadata` TEXT NULL,
    `likes` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player` (`player_id`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Community Messages
CREATE TABLE IF NOT EXISTS `ec_community_messages` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `message_type` VARCHAR(50) NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `content` TEXT NOT NULL,
    `sender` VARCHAR(100) NOT NULL,
    `target_players` TEXT NULL,
    `expires_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_message_type` (`message_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Community Engagement
CREATE TABLE IF NOT EXISTS `ec_community_engagement` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(50) NOT NULL,
    `action` VARCHAR(100) NOT NULL,
    `points` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PERFORMANCE & MONITORING
-- ============================================================================

-- Performance Snapshots
CREATE TABLE IF NOT EXISTS `ec_performance_snapshots` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `snapshot_data` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Performance Metrics
CREATE TABLE IF NOT EXISTS `ec_performance_metrics` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `metric_type` VARCHAR(50) NOT NULL,
    `metric_value` FLOAT NOT NULL,
    `metadata` TEXT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_type` (`metric_type`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player History
CREATE TABLE IF NOT EXISTS `ec_player_history` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `player_count` INT NOT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Server Metrics History
CREATE TABLE IF NOT EXISTS `ec_admin_metrics_history` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `timestamp` BIGINT(20) NOT NULL,
    `players_online` INT NOT NULL DEFAULT 0,
    `max_players` INT NOT NULL DEFAULT 64,
    `avg_ping` INT NOT NULL DEFAULT 0,
    `max_ping` INT NOT NULL DEFAULT 0,
    `memory_mb` FLOAT NOT NULL DEFAULT 0,
    `resources_started` INT NOT NULL DEFAULT 0,
    `resources_total` INT NOT NULL DEFAULT 0,
    `tps` INT NOT NULL DEFAULT 60,
    `metadata` LONGTEXT NULL,
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_players` (`players_online`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Webhook Logs
CREATE TABLE IF NOT EXISTS `ec_admin_webhook_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `webhook_url` VARCHAR(255) NOT NULL,
    `webhook_type` VARCHAR(50) NOT NULL,
    `event_type` VARCHAR(100) NOT NULL,
    `status_code` INT NULL,
    `success` TINYINT(1) DEFAULT 0,
    `error_message` TEXT NULL,
    `payload_size` INT DEFAULT 0,
    `response_time_ms` INT NULL,
    `timestamp` BIGINT(20) NOT NULL,
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_webhook_type` (`webhook_type`),
    INDEX `idx_success` (`success`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- API Usage Tracking
CREATE TABLE IF NOT EXISTS `ec_admin_api_usage` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `api_name` VARCHAR(100) NOT NULL,
    `endpoint` VARCHAR(255) NOT NULL,
    `method` VARCHAR(10) NOT NULL DEFAULT 'GET',
    `status_code` INT NULL,
    `success` TINYINT(1) DEFAULT 0,
    `response_time_ms` INT NULL,
    `error_message` TEXT NULL,
    `timestamp` BIGINT(20) NOT NULL,
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_api_name` (`api_name`),
    INDEX `idx_success` (`success`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- HOUSING SYSTEM
-- ============================================================================

-- Housing Rentals
CREATE TABLE IF NOT EXISTS `ec_housing_rentals` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `property_id` VARCHAR(100) NOT NULL,
    `property_name` VARCHAR(200) NULL,
    `tenant_id` VARCHAR(100) NOT NULL,
    `tenant_name` VARCHAR(100) NULL,
    `rent_amount` INT DEFAULT 0,
    `rent_due_date` TIMESTAMP NULL,
    `status` VARCHAR(50) DEFAULT 'active',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_tenant` (`tenant_id`),
    INDEX `idx_property` (`property_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Housing Properties
CREATE TABLE IF NOT EXISTS `ec_housing_properties` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `property_name` VARCHAR(200) NOT NULL,
    `property_type` VARCHAR(50) DEFAULT 'apartment',
    `address` VARCHAR(255) NULL,
    `owner_id` VARCHAR(100) NULL,
    `owner_name` VARCHAR(100) NULL,
    `price` INT DEFAULT 0,
    `rent_price` INT DEFAULT 0,
    `status` VARCHAR(50) DEFAULT 'available',
    `coords` VARCHAR(255) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_owner` (`owner_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player Houses (Framework Integration)
CREATE TABLE IF NOT EXISTS `player_houses` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `house` VARCHAR(100) NOT NULL,
    `identifier` VARCHAR(100) NOT NULL,
    `citizenid` VARCHAR(100) NULL,
    `keyholders` TEXT NULL,
    `decorations` TEXT NULL,
    `stash` TEXT NULL,
    `outfit` TEXT NULL,
    `logout` TEXT NULL,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_house` (`house`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- LIVEMAP SYSTEM
-- ============================================================================

-- Livemap History
CREATE TABLE IF NOT EXISTS `ec_livemap_history` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `player_id` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NULL,
    `position_x` FLOAT NOT NULL,
    `position_y` FLOAT NOT NULL,
    `position_z` FLOAT NOT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_player` (`player_id`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- VEHICLE SYSTEM
-- ============================================================================

-- Player Vehicles (Framework Integration)
CREATE TABLE IF NOT EXISTS `player_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `license` VARCHAR(100) NULL,
    `citizenid` VARCHAR(100) NULL,
    `vehicle` VARCHAR(50) NOT NULL,
    `hash` VARCHAR(50) NOT NULL,
    `mods` LONGTEXT NULL,
    `plate` VARCHAR(15) NOT NULL UNIQUE,
    `garage` VARCHAR(50) DEFAULT 'pillboxgarage',
    `fuel` INT DEFAULT 100,
    `engine` FLOAT DEFAULT 1000,
    `body` FLOAT DEFAULT 1000,
    `state` INT DEFAULT 1,
    `depotprice` INT DEFAULT 0,
    `drivingdistance` INT DEFAULT 0,
    `status` TEXT NULL,
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_license` (`license`),
    INDEX `idx_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player Warnings (Framework Integration)
CREATE TABLE IF NOT EXISTS `player_warnings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `senderIdentifier` VARCHAR(100) NOT NULL,
    `targetIdentifier` VARCHAR(100) NOT NULL,
    `sender` VARCHAR(100) NOT NULL,
    `target` VARCHAR(100) NOT NULL,
    `reason` TEXT NOT NULL,
    `warnId` VARCHAR(100) NULL,
    `timestamp` BIGINT(20) NOT NULL,
    INDEX `idx_target` (`targetIdentifier`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- FRAMEWORK INTEGRATION TABLES (QBCore/ESX/Standalone Fallback)
-- These tables provide fallback support if framework tables don't exist
-- ============================================================================

-- ============================================================================
-- PLAYER DATA TABLES
-- ============================================================================

-- QBCore/QBX Players (Fallback)
CREATE TABLE IF NOT EXISTS `players` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL UNIQUE,
    `cid` INT NULL,
    `license` VARCHAR(50) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `firstname` VARCHAR(50) NULL,
    `lastname` VARCHAR(50) NULL,
    `phone_number` VARCHAR(20) NULL,
    `money` LONGTEXT NULL,
    `charinfo` LONGTEXT NULL,
    `job` LONGTEXT NULL,
    `gang` LONGTEXT NULL,
    `position` LONGTEXT NULL,
    `skin` LONGTEXT NULL,
    `status` LONGTEXT NULL,
    `metadata` LONGTEXT NULL,
    `inventory` LONGTEXT NULL,
    `is_dead` TINYINT(1) DEFAULT 0,
    `last_property` VARCHAR(255) NULL,
    `last_seen` TIMESTAMP NULL,
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_license` (`license`),
    INDEX `idx_cid` (`cid`),
    INDEX `idx_lastname` (`lastname`),
    INDEX `idx_last_seen` (`last_seen`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ESX Users (Fallback)
CREATE TABLE IF NOT EXISTS `users` (
    `identifier` VARCHAR(50) NOT NULL PRIMARY KEY,
    `license` VARCHAR(50) NULL,
    `money` INT DEFAULT 0,
    `bank` INT DEFAULT 0,
    `accounts` LONGTEXT NULL,
    `group` VARCHAR(50) DEFAULT 'user',
    `inventory` LONGTEXT NULL,
    `job` VARCHAR(50) DEFAULT 'unemployed',
    `job_grade` INT DEFAULT 0,
    `loadout` LONGTEXT NULL,
    `position` VARCHAR(255) NULL,
    `firstname` VARCHAR(50) DEFAULT '',
    `lastname` VARCHAR(50) DEFAULT '',
    `dateofbirth` VARCHAR(25) DEFAULT '',
    `sex` VARCHAR(10) DEFAULT 'M',
    `height` VARCHAR(5) DEFAULT '',
    `skin` LONGTEXT NULL,
    `status` LONGTEXT NULL,
    `is_dead` TINYINT(1) DEFAULT 0,
    `last_property` VARCHAR(255) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_seen` TIMESTAMP NULL,
    INDEX `idx_license` (`license`),
    INDEX `idx_job` (`job`),
    INDEX `idx_group` (`group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Character Data (Multi-Character Support)
CREATE TABLE IF NOT EXISTS `characters` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `owner` VARCHAR(50) NOT NULL,
    `citizenid` VARCHAR(50) NULL,
    `firstname` VARCHAR(50) NOT NULL,
    `lastname` VARCHAR(50) NOT NULL,
    `dateofbirth` VARCHAR(25) NOT NULL,
    `sex` VARCHAR(10) NOT NULL,
    `nationality` VARCHAR(50) DEFAULT 'USA',
    `phone` VARCHAR(20) NULL,
    `job` VARCHAR(50) NULL,
    `job_grade` INT DEFAULT 0,
    `gang` VARCHAR(50) NULL,
    `gang_grade` INT DEFAULT 0,
    `metadata` LONGTEXT NULL,
    `position` LONGTEXT NULL,
    `skin` LONGTEXT NULL,
    `last_seen` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_owner` (`owner`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_job` (`job`),
    INDEX `idx_gang` (`gang`),
    INDEX `idx_lastname` (`lastname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player Sessions (Login Tracking)
CREATE TABLE IF NOT EXISTS `player_sessions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `license` VARCHAR(50) NOT NULL,
    `citizenid` VARCHAR(50) NULL,
    `name` VARCHAR(100) NULL,
    `hwid` VARCHAR(100) NULL,
    `discord_id` VARCHAR(50) NULL,
    `login_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `logout_time` TIMESTAMP NULL,
    `playtime` INT DEFAULT 0,
    `playtime_session` INT DEFAULT 0,
    `ip_address` VARCHAR(50) NULL,
    `server_id` INT DEFAULT 1,
    INDEX `idx_license` (`license`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_hwid` (`hwid`),
    INDEX `idx_login_time` (`login_time`),
    INDEX `idx_server_id` (`server_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- JOBS & GANGS SYSTEM
-- ============================================================================

-- Jobs (Framework Integration)
CREATE TABLE IF NOT EXISTS `jobs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL UNIQUE,
    `label` VARCHAR(100) NOT NULL,
    `icon` VARCHAR(100) NULL,
    `whitelisted` TINYINT(1) DEFAULT 0,
    `boss_job` VARCHAR(50) NULL,
    `max_grade` INT DEFAULT 0,
    `discord_role_id` VARCHAR(50) NULL,
    INDEX `idx_name` (`name`),
    INDEX `idx_boss_job` (`boss_job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Job Grades (Framework Integration)
CREATE TABLE IF NOT EXISTS `job_grades` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `job_name` VARCHAR(50) NOT NULL,
    `grade` INT NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `salary` INT DEFAULT 0,
    `skin_male` LONGTEXT NULL,
    `skin_female` LONGTEXT NULL,
    INDEX `idx_job_name` (`job_name`),
    INDEX `idx_grade` (`grade`),
    UNIQUE KEY `job_grade_unique` (`job_name`, `grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Gangs (QBCore Integration)
CREATE TABLE IF NOT EXISTS `gangs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL UNIQUE,
    `label` VARCHAR(100) NOT NULL,
    `icon` VARCHAR(100) NULL,
    `boss_gang` VARCHAR(50) NULL,
    `max_grade` INT DEFAULT 0,
    `discord_role_id` VARCHAR(50) NULL,
    INDEX `idx_name` (`name`),
    INDEX `idx_boss_gang` (`boss_gang`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Gang Grades (QBCore Integration)
CREATE TABLE IF NOT EXISTS `gang_grades` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `gang_name` VARCHAR(50) NOT NULL,
    `grade` INT NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    INDEX `idx_gang_name` (`gang_name`),
    INDEX `idx_grade` (`grade`),
    UNIQUE KEY `gang_grade_unique` (`gang_name`, `grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Society Accounts (ESX/Job Money)
CREATE TABLE IF NOT EXISTS `addon_account` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(60) NOT NULL UNIQUE,
    `label` VARCHAR(100) NOT NULL,
    `type` VARCHAR(50) DEFAULT 'job',
    `owner_job` VARCHAR(50) NULL,
    `owner_gang` VARCHAR(50) NULL,
    `shared` INT(11) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `index_addon_account_name` (`name`),
    INDEX `idx_owner_job` (`owner_job`),
    INDEX `idx_owner_gang` (`owner_gang`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `addon_account_data` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `account_id` INT NULL,
    `account_name` VARCHAR(100) NOT NULL,
    `money` BIGINT NOT NULL DEFAULT 0,
    `owner` VARCHAR(60) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `index_addon_account_data_account_name` (`account_name`),
    INDEX `index_addon_account_data_owner` (`owner`),
    INDEX `idx_account_id` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ECONOMY SYSTEM
-- ============================================================================

-- Bank Accounts (Standalone Banking)
CREATE TABLE IF NOT EXISTS `bank_accounts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NULL,
    `identifier` VARCHAR(50) NULL,
    `account_type` VARCHAR(50) DEFAULT 'personal',
    `account_name` VARCHAR(100) NULL,
    `balance` BIGINT DEFAULT 0,
    `account_number` VARCHAR(20) NULL,
    `routing_number` VARCHAR(20) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_account_type` (`account_type`),
    UNIQUE KEY `account_unique` (`citizenid`, `account_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Transactions (Economy Tracking)
CREATE TABLE IF NOT EXISTS `transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `transaction_id` VARCHAR(100) NULL,
    `citizenid` VARCHAR(50) NULL,
    `identifier` VARCHAR(50) NULL,
    `account_id` INT NULL,
    `transaction_type` VARCHAR(50) NOT NULL,
    `amount` BIGINT NOT NULL,
    `balance_before` BIGINT DEFAULT 0,
    `balance_after` BIGINT DEFAULT 0,
    `reason` VARCHAR(255) NULL,
    `sender` VARCHAR(100) NULL,
    `receiver` VARCHAR(100) NULL,
    `sender_citizenid` VARCHAR(50) NULL,
    `receiver_citizenid` VARCHAR(50) NULL,
    `status` VARCHAR(50) DEFAULT 'completed',
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_transaction_type` (`transaction_type`),
    INDEX `idx_sender_citizenid` (`sender_citizenid`),
    INDEX `idx_receiver_citizenid` (`receiver_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- INVENTORY SYSTEM
-- ============================================================================

-- Items (Inventory Items Definition)
CREATE TABLE IF NOT EXISTS `items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL UNIQUE,
    `label` VARCHAR(100) NOT NULL,
    `weight` INT DEFAULT 1,
    `rare` TINYINT(1) DEFAULT 0,
    `can_remove` TINYINT(1) DEFAULT 1,
    `type` VARCHAR(50) DEFAULT 'item',
    `usable` TINYINT(1) DEFAULT 0,
    `unique` TINYINT(1) DEFAULT 0,
    `stack` INT DEFAULT 1,
    `limit` INT DEFAULT -1,
    `script` VARCHAR(255) NULL,
    `image` VARCHAR(255) NULL,
    `description` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_name` (`name`),
    INDEX `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Stash Items (Inventory Storage)
CREATE TABLE IF NOT EXISTS `stashitems` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `stash` VARCHAR(100) NOT NULL,
    `items` LONGTEXT NULL,
    UNIQUE KEY `stash_unique` (`stash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Trunk Inventory (Vehicle Storage)
CREATE TABLE IF NOT EXISTS `trunkitems` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `plate` VARCHAR(15) NOT NULL,
    `items` LONGTEXT NULL,
    UNIQUE KEY `plate_unique` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Glovebox Inventory (Vehicle Storage)
CREATE TABLE IF NOT EXISTS `gloveboxitems` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `plate` VARCHAR(15) NOT NULL,
    `items` LONGTEXT NULL,
    UNIQUE KEY `plate_unique` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- HOUSING SYSTEM
-- ============================================================================

-- Properties (Housing Definitions)
CREATE TABLE IF NOT EXISTS `properties` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `property_id` VARCHAR(50) NULL,
    `name` VARCHAR(100) NULL,
    `label` VARCHAR(100) NULL,
    `property_name` VARCHAR(100) NULL,
    `address` VARCHAR(255) NULL,
    `street` VARCHAR(100) NULL,
    `coords` LONGTEXT NULL,
    `entering` LONGTEXT NULL,
    `exit` LONGTEXT NULL,
    `door_data` LONGTEXT NULL,
    `ipls` LONGTEXT NULL,
    `gateway` LONGTEXT NULL,
    `property_type` VARCHAR(50) DEFAULT 'house',
    `owner` VARCHAR(60) NULL,
    `owner_citizenid` VARCHAR(50) NULL,
    `owner_name` VARCHAR(100) NULL,
    `price` INT DEFAULT 0,
    `is_available` TINYINT(1) DEFAULT 1,
    `locked` TINYINT(1) DEFAULT 0,
    `garage` TINYINT(1) DEFAULT 0,
    `has_garage` TINYINT(1) DEFAULT 0,
    `tier` INT DEFAULT 1,
    `is_single` TINYINT(1) DEFAULT 0,
    `is_room` TINYINT(1) DEFAULT 0,
    `is_gateway` TINYINT(1) DEFAULT 0,
    `room_menu` LONGTEXT NULL,
    `basePrice` INT DEFAULT 0,
    `location` VARCHAR(50) DEFAULT 'suburbs',
    `condition` VARCHAR(50) DEFAULT 'good',
    `age` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_name` (`name`),
    INDEX `idx_property_id` (`property_id`),
    INDEX `idx_owner_citizenid` (`owner_citizenid`),
    INDEX `idx_is_available` (`is_available`),
    INDEX `idx_property_type` (`property_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Owned Properties (Housing Ownership)
CREATE TABLE IF NOT EXISTS `owned_properties` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `property_id` INT NOT NULL,
    `owner` VARCHAR(60) NOT NULL,
    `price` INT NOT NULL,
    `rented` TINYINT(1) NOT NULL DEFAULT 0,
    INDEX `idx_property_id` (`property_id`),
    INDEX `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Property Rentals (Housing Rentals)
CREATE TABLE IF NOT EXISTS `property_rentals` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `property_id` INT NOT NULL,
    `owner` VARCHAR(60) NOT NULL,
    `tenant` VARCHAR(60) NOT NULL,
    `rent_amount` INT NOT NULL,
    `rent_due` TIMESTAMP NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_property_id` (`property_id`),
    INDEX `idx_tenant` (`tenant`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Property Transactions (Housing Sales History)
CREATE TABLE IF NOT EXISTS `property_transactions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `property_id` INT NOT NULL,
    `seller_citizenid` VARCHAR(50) NULL,
    `buyer_citizenid` VARCHAR(50) NULL,
    `price` INT NOT NULL,
    `transaction_type` VARCHAR(50) DEFAULT 'sale',
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_property_id` (`property_id`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- MODERATION FRAMEWORK TABLES
-- ============================================================================

-- Player Kicks (Framework Integration)
CREATE TABLE IF NOT EXISTS `player_kicks` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `kick_id` VARCHAR(100) NULL,
    `license` VARCHAR(100) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `reason` TEXT NOT NULL,
    `kicked_by` VARCHAR(100) NOT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_license` (`license`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player Bans (Framework Integration)
CREATE TABLE IF NOT EXISTS `player_bans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `ban_id` VARCHAR(100) NULL,
    `license` VARCHAR(100) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `reason` TEXT NOT NULL,
    `banned_by` VARCHAR(100) NOT NULL,
    `expire_time` BIGINT(20) NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_license` (`license`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bans (Alternative Ban System)
CREATE TABLE IF NOT EXISTS `bans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `license` VARCHAR(50) NOT NULL,
    `identifier` VARCHAR(50) NULL,
    `hwid` VARCHAR(100) NULL,
    `discord_id` VARCHAR(50) NULL,
    `player_name` VARCHAR(100) NULL,
    `reason` TEXT NOT NULL,
    `banned_by` VARCHAR(100) NULL,
    `ban_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expire_date` TIMESTAMP NULL,
    `permanent` TINYINT(1) DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `unban_date` TIMESTAMP NULL,
    `unban_reason` TEXT NULL,
    `unban_by` VARCHAR(100) NULL,
    INDEX `idx_license` (`license`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_hwid` (`hwid`),
    INDEX `idx_is_active` (`is_active`),
    INDEX `idx_expire_date` (`expire_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Warnings (Alternative Warning System)
CREATE TABLE IF NOT EXISTS `warnings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `license` VARCHAR(50) NOT NULL,
    `identifier` VARCHAR(50) NULL,
    `player_name` VARCHAR(100) NULL,
    `reason` TEXT NOT NULL,
    `warned_by` VARCHAR(100) NULL,
    `warning_count` INT DEFAULT 1,
    `warning_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_active` TINYINT(1) DEFAULT 1,
    INDEX `idx_license` (`license`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ban Appeals (Appeal System)
CREATE TABLE IF NOT EXISTS `ban_appeals` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `ban_id` INT NULL,
    `license` VARCHAR(100) NOT NULL,
    `identifier` VARCHAR(100) NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `appeal_reason` TEXT NOT NULL,
    `status` VARCHAR(50) DEFAULT 'pending',
    `reviewed_by` VARCHAR(100) NULL,
    `review_notes` TEXT NULL,
    `submitted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `reviewed_at` TIMESTAMP NULL,
    INDEX `idx_license` (`license`),
    INDEX `idx_status` (`status`),
    INDEX `idx_submitted_at` (`submitted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Audit Trail (Full Audit History)
CREATE TABLE IF NOT EXISTS `audit_trail` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_identifier` VARCHAR(100) NOT NULL,
    `admin_name` VARCHAR(100) NULL,
    `action` VARCHAR(100) NOT NULL,
    `target_identifier` VARCHAR(100) NULL,
    `target_name` VARCHAR(100) NULL,
    `details` TEXT NULL,
    `ip_address` VARCHAR(45) NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_admin` (`admin_identifier`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- PERFORMANCE & MONITORING
-- ============================================================================

-- Performance Logs (Server Performance Tracking)
CREATE TABLE IF NOT EXISTS `performance_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `resource_name` VARCHAR(100) NULL,
    `cpu_usage` FLOAT DEFAULT 0,
    `memory_usage` FLOAT DEFAULT 0,
    `players_online` INT DEFAULT 0,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_resource` (`resource_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DEVELOPMENT TOOLS
-- ============================================================================

-- Dev Scripts
CREATE TABLE IF NOT EXISTS `ec_dev_scripts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `language` VARCHAR(20) DEFAULT 'lua',
    `content` LONGTEXT NOT NULL,
    `category` VARCHAR(50) DEFAULT 'custom',
    `author` VARCHAR(100) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_type` (`type`),
    INDEX `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dev Console Logs
CREATE TABLE IF NOT EXISTS `ec_dev_console_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `type` VARCHAR(20) NOT NULL,
    `message` TEXT NOT NULL,
    `source` VARCHAR(100) NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_type` (`type`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dev Resources
CREATE TABLE IF NOT EXISTS `ec_dev_resources` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `author` VARCHAR(100) NULL,
    `version` VARCHAR(20) DEFAULT '1.0.0',
    `files` LONGTEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SYSTEM MANAGEMENT
-- ============================================================================

-- System Actions
CREATE TABLE IF NOT EXISTS `ec_system_actions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `action_type` VARCHAR(100) NOT NULL,
    `action_data` TEXT NULL,
    `performed_by` VARCHAR(100) NOT NULL,
    `status` VARCHAR(50) DEFAULT 'completed',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_action_type` (`action_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Server Restarts
CREATE TABLE IF NOT EXISTS `ec_server_restarts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `restart_type` VARCHAR(50) DEFAULT 'manual',
    `reason` TEXT NULL,
    `scheduled_time` TIMESTAMP NULL,
    `status` VARCHAR(50) DEFAULT 'pending',
    `created_by` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_status` (`status`),
    INDEX `idx_scheduled_time` (`scheduled_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Console Logs
CREATE TABLE IF NOT EXISTS `ec_console_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `log_type` VARCHAR(50) NOT NULL,
    `message` TEXT NOT NULL,
    `source` VARCHAR(100) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_log_type` (`log_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- MIGRATION TRACKING
-- ============================================================================

-- Migration Tracking (for auto-installer)
CREATE TABLE IF NOT EXISTS `ec_admin_migrations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `filename` VARCHAR(255) NOT NULL UNIQUE,
    `executed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `success` BOOLEAN DEFAULT TRUE,
    `error_message` TEXT NULL,
    INDEX `idx_filename` (`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Schema Version Tracking
CREATE TABLE IF NOT EXISTS `ec_admin_schema_version` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `version` INT NOT NULL,
    `description` VARCHAR(255) NULL,
    `applied_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `success` TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- GLOBAL BANS (Customer Side - receives from host)
-- ============================================================================

CREATE TABLE IF NOT EXISTS `ec_global_bans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `reason` TEXT NOT NULL,
    `banned_by` VARCHAR(100) NOT NULL,
    `server_count` INT DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NULL,
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- END OF CUSTOMER SCHEMA
-- ============================================================================

-- Insert default settings row (if not exists)
INSERT IGNORE INTO `ec_admin_settings` (`id`, `settings`, `webhooks`, `permissions`) 
VALUES (1, '{}', '{}', '{}');

-- Success message
SELECT 'EC ADMIN ULTIMATE - Customer database schema installed successfully!' AS Status;
SELECT CONCAT('Total Tables Created: ', COUNT(*)) AS TableCount 
FROM information_schema.tables 
WHERE table_schema = DATABASE() 
AND table_name LIKE 'ec_%' OR table_name LIKE 'ai_%' OR table_name IN ('player_reports', 'activity_logs', 'system_reports', 'error_logs', 'scheduled_reports');
