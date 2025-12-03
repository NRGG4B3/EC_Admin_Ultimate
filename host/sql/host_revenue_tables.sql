-- EC Admin Ultimate - Host Revenue & Customer Management Tables
-- Subscription vs Lifetime customer tracking

-- Host Customers Table (Updated with revenue tracking)
CREATE TABLE IF NOT EXISTS `nrg_host_customers` (
    `id` VARCHAR(50) PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(255) NOT NULL UNIQUE,
    `discord_id` VARCHAR(50) DEFAULT NULL,
    `phone` VARCHAR(20) DEFAULT NULL,
    `company` VARCHAR(100) DEFAULT NULL,
    `created_at` INT NOT NULL,
    `status` ENUM('active', 'suspended', 'trial', 'expired') DEFAULT 'trial',
    `tier` ENUM('basic', 'pro', 'enterprise', 'custom') DEFAULT 'basic',
    
    -- License Type (NEW)
    `license_type` ENUM('subscription', 'lifetime', 'one-time') DEFAULT 'trial',
    `subscription_plan` ENUM('monthly', 'yearly', 'custom') DEFAULT NULL,
    `subscription_status` ENUM('active', 'past_due', 'cancelled', 'expired') DEFAULT NULL,
    `mrr` DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Monthly Recurring Revenue for this customer',
    `subscription_started` INT DEFAULT NULL,
    `next_billing` INT DEFAULT NULL,
    
    -- Revenue tracking
    `total_spent` DECIMAL(10, 2) DEFAULT 0.00,
    `lifetime_value` DECIMAL(10, 2) DEFAULT 0.00,
    `last_payment` INT DEFAULT NULL,
    
    `notes` TEXT DEFAULT NULL,
    
    INDEX `idx_license_type` (`license_type`),
    INDEX `idx_subscription_status` (`subscription_status`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Customer Servers Table
CREATE TABLE IF NOT EXISTS `nrg_host_customer_servers` (
    `id` VARCHAR(50) PRIMARY KEY,
    `customer_id` VARCHAR(50) NOT NULL,
    `server_name` VARCHAR(100) NOT NULL,
    `server_ip` VARCHAR(50) NOT NULL,
    `cfx_license` VARCHAR(100) NOT NULL,
    `api_key` VARCHAR(255) NOT NULL UNIQUE,
    `status` ENUM('online', 'offline', 'maintenance') DEFAULT 'offline',
    `players_online` INT DEFAULT 0,
    `max_players` INT DEFAULT 32,
    `framework` ENUM('qbcore', 'esx', 'other') DEFAULT 'qbcore',
    `version` VARCHAR(20) DEFAULT '1.0.0',
    `connected_apis` TEXT DEFAULT NULL COMMENT 'JSON array of connected API keys',
    `created_at` INT NOT NULL,
    `last_seen` INT NOT NULL,
    `uptime` INT DEFAULT 0,
    `total_requests` INT DEFAULT 0,
    `last_restart` INT DEFAULT NULL,
    
    FOREIGN KEY (`customer_id`) REFERENCES `nrg_host_customers`(`id`) ON DELETE CASCADE,
    INDEX `idx_customer` (`customer_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Purchases Table (Updated with subscription tracking)
CREATE TABLE IF NOT EXISTS `nrg_host_purchases` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `customer_id` VARCHAR(50) NOT NULL,
    `product_name` VARCHAR(100) NOT NULL,
    `product_type` ENUM('license', 'api_access', 'support', 'subscription', 'custom') NOT NULL,
    `amount` DECIMAL(10, 2) NOT NULL,
    `currency` VARCHAR(3) DEFAULT 'USD',
    `status` ENUM('completed', 'pending', 'refunded', 'cancelled') DEFAULT 'pending',
    `purchased_at` INT NOT NULL,
    `expires_at` INT DEFAULT NULL,
    `transaction_id` VARCHAR(100) DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    
    FOREIGN KEY (`customer_id`) REFERENCES `nrg_host_customers`(`id`) ON DELETE CASCADE,
    INDEX `idx_customer` (`customer_id`),
    INDEX `idx_product_type` (`product_type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_purchased_at` (`purchased_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- API Keys Table
CREATE TABLE IF NOT EXISTS `nrg_host_api_keys` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `customer_id` VARCHAR(50) NOT NULL,
    `server_id` VARCHAR(50) DEFAULT NULL,
    `api_name` VARCHAR(50) NOT NULL,
    `api_key` VARCHAR(255) NOT NULL UNIQUE,
    `permissions` TEXT DEFAULT NULL COMMENT 'JSON array of permissions',
    `rate_limit` INT DEFAULT 60 COMMENT 'Requests per minute',
    `requests_today` INT DEFAULT 0,
    `requests_total` INT DEFAULT 0,
    `created_at` INT NOT NULL,
    `expires_at` INT DEFAULT NULL,
    `last_used` INT DEFAULT NULL,
    `enabled` TINYINT(1) DEFAULT 1,
    
    FOREIGN KEY (`customer_id`) REFERENCES `nrg_host_customers`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`server_id`) REFERENCES `nrg_host_customer_servers`(`id`) ON DELETE SET NULL,
    INDEX `idx_customer` (`customer_id`),
    INDEX `idx_server` (`server_id`),
    INDEX `idx_api_key` (`api_key`),
    INDEX `idx_enabled` (`enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Support Tickets Table
CREATE TABLE IF NOT EXISTS `nrg_support_tickets` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `customer_id` VARCHAR(50) NOT NULL,
    `customer_name` VARCHAR(100) NOT NULL,
    `subject` VARCHAR(255) NOT NULL,
    `priority` ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    `status` ENUM('open', 'in_progress', 'resolved', 'closed') DEFAULT 'open',
    `created_at` INT NOT NULL,
    `updated_at` INT NOT NULL,
    `assigned_to` VARCHAR(100) DEFAULT NULL,
    `messages_count` INT DEFAULT 0,
    
    FOREIGN KEY (`customer_id`) REFERENCES `nrg_host_customers`(`id`) ON DELETE CASCADE,
    INDEX `idx_customer` (`customer_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_priority` (`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- API Status Table
CREATE TABLE IF NOT EXISTS `nrg_api_status` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `api_key` VARCHAR(50) NOT NULL UNIQUE,
    `api_name` VARCHAR(100) NOT NULL,
    `port` INT NOT NULL,
    `status` ENUM('online', 'offline', 'degraded', 'starting', 'stopping') DEFAULT 'offline',
    `uptime` INT DEFAULT 0,
    `requests` INT DEFAULT 0,
    `requests_today` INT DEFAULT 0,
    `avg_response_time` INT DEFAULT 0,
    `error_rate` DECIMAL(5, 2) DEFAULT 0.00,
    `version` VARCHAR(20) DEFAULT '1.0.0',
    `last_restart` INT DEFAULT NULL,
    `health_status` ENUM('healthy', 'degraded', 'unhealthy') DEFAULT 'healthy',
    `memory_usage` INT DEFAULT 0,
    `cpu_usage` DECIMAL(5, 2) DEFAULT 0.00,
    `active_connections` INT DEFAULT 0,
    `error_count` INT DEFAULT 0,
    `warning_count` INT DEFAULT 0,
    `auto_restart` TINYINT(1) DEFAULT 1,
    `enabled` TINYINT(1) DEFAULT 1,
    
    INDEX `idx_status` (`status`),
    INDEX `idx_health` (`health_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Connected Cities Table
CREATE TABLE IF NOT EXISTS `nrg_connected_cities` (
    `id` VARCHAR(50) PRIMARY KEY,
    `city_name` VARCHAR(100) NOT NULL,
    `city_ip` VARCHAR(50) NOT NULL,
    `customer_id` VARCHAR(50) DEFAULT NULL,
    `status` ENUM('online', 'offline') DEFAULT 'offline',
    `connected_at` INT DEFAULT NULL,
    `last_seen` INT DEFAULT NULL,
    
    FOREIGN KEY (`customer_id`) REFERENCES `nrg_host_customers`(`id`) ON DELETE SET NULL,
    INDEX `idx_status` (`status`),
    INDEX `idx_customer` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Revenue Analytics Views
CREATE OR REPLACE VIEW `nrg_revenue_analytics` AS
SELECT 
    -- Customer breakdown
    COUNT(*) as total_customers,
    SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_customers,
    SUM(CASE WHEN license_type = 'subscription' AND status = 'active' THEN 1 ELSE 0 END) as subscription_customers,
    SUM(CASE WHEN license_type = 'lifetime' THEN 1 ELSE 0 END) as lifetime_customers,
    SUM(CASE WHEN status = 'trial' THEN 1 ELSE 0 END) as trial_customers,
    
    -- Revenue totals
    SUM(mrr) as total_mrr,
    SUM(mrr) * 12 as total_arr,
    SUM(CASE WHEN license_type = 'lifetime' THEN lifetime_value ELSE 0 END) as total_lifetime_revenue,
    SUM(total_spent) as total_revenue_all_time
FROM nrg_host_customers;

-- Insert default API statuses for 20 APIs
INSERT INTO `nrg_api_status` (`api_key`, `api_name`, `port`, `status`, `version`) VALUES
('auth_api', 'Authentication API', 3001, 'offline', '1.0.0'),
('player_api', 'Player Data API', 3002, 'offline', '1.0.0'),
('vehicle_api', 'Vehicle Management API', 3003, 'offline', '1.0.0'),
('inventory_api', 'Inventory API', 3004, 'offline', '1.0.0'),
('banking_api', 'Banking API', 3005, 'offline', '1.0.0'),
('housing_api', 'Housing API', 3006, 'offline', '1.0.0'),
('job_api', 'Job Management API', 3007, 'offline', '1.0.0'),
('gang_api', 'Gang Management API', 3008, 'offline', '1.0.0'),
('dispatch_api', 'Dispatch API', 3009, 'offline', '1.0.0'),
('mdt_api', 'MDT API', 3010, 'offline', '1.0.0'),
('business_api', 'Business API', 3011, 'offline', '1.0.0'),
('crafting_api', 'Crafting API', 3012, 'offline', '1.0.0'),
('phone_api', 'Phone API', 3013, 'offline', '1.0.0'),
('racing_api', 'Racing API', 3014, 'offline', '1.0.0'),
('drugs_api', 'Drugs API', 3015, 'offline', '1.0.0'),
('reports_api', 'Reports API', 3016, 'offline', '1.0.0'),
('logs_api', 'Logging API', 3017, 'offline', '1.0.0'),
('ban_api', 'Global Ban API', 3018, 'offline', '1.0.0'),
('webhook_api', 'Webhook API', 3019, 'offline', '1.0.0'),
('analytics_api', 'Analytics API', 3020, 'offline', '1.0.0')
ON DUPLICATE KEY UPDATE api_name = VALUES(api_name);

COMMIT;
