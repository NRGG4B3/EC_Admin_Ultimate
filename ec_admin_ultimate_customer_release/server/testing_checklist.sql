-- ============================================================================
-- EC Admin Ultimate - Testing Checklist Database Schema
-- ============================================================================
-- SQL migration file for testing checklist tracking
-- ============================================================================

-- Table: Testing Checklist Progress
CREATE TABLE IF NOT EXISTS `ec_testing_checklist` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_id` VARCHAR(50) NOT NULL,
  `item_id` VARCHAR(255) NOT NULL,
  `category` VARCHAR(100) NOT NULL,
  `checked` TINYINT(1) DEFAULT 0,
  `checked_at` BIGINT,
  `notes` TEXT,
  `created_at` BIGINT NOT NULL,
  `updated_at` BIGINT NOT NULL,
  UNIQUE KEY `unique_admin_item` (`admin_id`, `item_id`),
  INDEX `idx_admin_id` (`admin_id`),
  INDEX `idx_category` (`category`),
  INDEX `idx_checked` (`checked`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
