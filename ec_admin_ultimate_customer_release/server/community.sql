-- ============================================================================
-- EC Admin Ultimate - Community Management Database Schema
-- ============================================================================
-- SQL migration file for community management tables
-- Run this SQL to create the required tables for the community system
-- ============================================================================

-- Table: Groups
CREATE TABLE IF NOT EXISTS `ec_community_groups` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT,
  `group_type` VARCHAR(50) DEFAULT 'custom',
  `leader_id` VARCHAR(50) NOT NULL,
  `leader_name` VARCHAR(100) NOT NULL,
  `member_count` INT DEFAULT 0,
  `max_members` INT DEFAULT 50,
  `is_public` TINYINT(1) DEFAULT 1,
  `color` VARCHAR(7) DEFAULT '#3b82f6',
  `created_at` BIGINT NOT NULL,
  INDEX `idx_leader_id` (`leader_id`),
  INDEX `idx_group_type` (`group_type`),
  INDEX `idx_is_public` (`is_public`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Group Members
CREATE TABLE IF NOT EXISTS `ec_community_group_members` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `group_id` INT NOT NULL,
  `player_id` VARCHAR(50) NOT NULL,
  `player_name` VARCHAR(100) NOT NULL,
  `role` VARCHAR(50) DEFAULT 'member',
  `joined_at` BIGINT NOT NULL,
  INDEX `idx_group_id` (`group_id`),
  INDEX `idx_player_id` (`player_id`),
  FOREIGN KEY (`group_id`) REFERENCES `ec_community_groups`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Events
CREATE TABLE IF NOT EXISTS `ec_community_events` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT,
  `event_type` VARCHAR(50) DEFAULT 'custom',
  `organizer_id` VARCHAR(50) NOT NULL,
  `organizer_name` VARCHAR(100) NOT NULL,
  `start_time` BIGINT NOT NULL,
  `duration` INT DEFAULT 60,
  `location` VARCHAR(255),
  `max_participants` INT DEFAULT 50,
  `participant_count` INT DEFAULT 0,
  `prize_pool` DECIMAL(15,2) DEFAULT 0,
  `status` VARCHAR(20) DEFAULT 'scheduled',
  `created_at` BIGINT NOT NULL,
  INDEX `idx_organizer_id` (`organizer_id`),
  INDEX `idx_event_type` (`event_type`),
  INDEX `idx_status` (`status`),
  INDEX `idx_start_time` (`start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Event Participants
CREATE TABLE IF NOT EXISTS `ec_community_event_participants` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `event_id` INT NOT NULL,
  `player_id` VARCHAR(50) NOT NULL,
  `player_name` VARCHAR(100) NOT NULL,
  `joined_at` BIGINT NOT NULL,
  INDEX `idx_event_id` (`event_id`),
  INDEX `idx_player_id` (`player_id`),
  FOREIGN KEY (`event_id`) REFERENCES `ec_community_events`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Achievements
CREATE TABLE IF NOT EXISTS `ec_community_achievements` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT,
  `category` VARCHAR(50) DEFAULT 'general',
  `icon` VARCHAR(50) DEFAULT 'trophy',
  `points` INT DEFAULT 10,
  `requirement_type` VARCHAR(50) DEFAULT 'manual',
  `requirement_value` INT DEFAULT 1,
  `is_secret` TINYINT(1) DEFAULT 0,
  `unlocked_count` INT DEFAULT 0,
  `created_at` BIGINT NOT NULL,
  INDEX `idx_category` (`category`),
  INDEX `idx_requirement_type` (`requirement_type`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Player Achievements
CREATE TABLE IF NOT EXISTS `ec_community_player_achievements` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `player_id` VARCHAR(50) NOT NULL,
  `achievement_id` INT NOT NULL,
  `unlocked_at` BIGINT NOT NULL,
  `unlocked_by` VARCHAR(50),
  UNIQUE KEY `unique_player_achievement` (`player_id`, `achievement_id`),
  INDEX `idx_player_id` (`player_id`),
  INDEX `idx_achievement_id` (`achievement_id`),
  FOREIGN KEY (`achievement_id`) REFERENCES `ec_community_achievements`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Announcements
CREATE TABLE IF NOT EXISTS `ec_community_announcements` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(255) NOT NULL,
  `message` TEXT NOT NULL,
  `announcement_type` VARCHAR(50) DEFAULT 'info',
  `posted_by` VARCHAR(50) NOT NULL,
  `posted_by_name` VARCHAR(100) NOT NULL,
  `priority` INT DEFAULT 1,
  `is_pinned` TINYINT(1) DEFAULT 0,
  `created_at` BIGINT NOT NULL,
  INDEX `idx_posted_by` (`posted_by`),
  INDEX `idx_announcement_type` (`announcement_type`),
  INDEX `idx_is_pinned` (`is_pinned`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Community Actions Log
CREATE TABLE IF NOT EXISTS `ec_community_actions_log` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `admin_name` VARCHAR(100) NOT NULL,
  `action_type` VARCHAR(50) NOT NULL,
  `target_type` VARCHAR(50),
  `target_id` INT,
  `target_name` VARCHAR(255),
  `details` TEXT,
  `created_at` BIGINT NOT NULL,
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_action_type` (`action_type`),
  INDEX `idx_target_type` (`target_type`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

