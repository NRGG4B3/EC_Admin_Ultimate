-- EC Admin Ultimate - Auto Migration Script
-- Ensures ec_admin_settings table is always correct


CREATE TABLE IF NOT EXISTS `ec_admin_settings` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(50) NOT NULL,
  `settings_data` LONGTEXT NOT NULL,
  `updated_by` VARCHAR(100) DEFAULT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- If you need to add columns manually, use these commands one at a time and ignore errors if the column exists:
-- ALTER TABLE `ec_admin_settings` ADD COLUMN `category` VARCHAR(50) NOT NULL;
-- ALTER TABLE `ec_admin_settings` ADD COLUMN `settings_data` LONGTEXT NOT NULL;
-- ALTER TABLE `ec_admin_settings` ADD COLUMN `updated_by` VARCHAR(100) DEFAULT NULL;
-- ALTER TABLE `ec_admin_settings` ADD COLUMN `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
-- ALTER TABLE `ec_admin_settings` ADD UNIQUE KEY `category` (`category`);
