-- EC Admin Ultimate - AI Detection Database Migration
-- Creates missing ai_detections_live table

Logger.Info('📊 Loading AI Detection database migration...')

-- Wait for MySQL to be ready with better checking
CreateThread(function()
    -- Wait for MySQL with timeout
    local attempts = 0
    while not MySQL and attempts < 100 do
        Wait(100)
        attempts = attempts + 1
    end
    
    if not MySQL then
        Logger.Info('❌ MySQL not available, AI detection tables not created')
        return
    end
    
    -- Wait for database connection to be fully established
    Wait(3000)
    
    -- Test database connection before creating tables
    local dbReady = false
    MySQL.query('SELECT 1', {}, function(result)
        if result then
            dbReady = true
            Logger.Info('✅ Database connection verified')
        end
    end)
    
    -- Wait for connection test
    Wait(2000)
    
    if not dbReady then
        Logger.Info('⚠️  Database not ready, retrying in 5 seconds...')
        Wait(5000)
    end
    
    -- Create ai_detections_live table if it doesn't exist
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ai_detections_live` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `player` VARCHAR(255) NOT NULL,
            `player_id` INT NOT NULL,
            `citizenid` VARCHAR(50) DEFAULT NULL,
            `type` VARCHAR(100) NOT NULL,
            `category` VARCHAR(50) NOT NULL,
            `severity` VARCHAR(20) NOT NULL,
            `confidence` FLOAT NOT NULL,
            `status` VARCHAR(50) NOT NULL DEFAULT 'analyzing',
            `auto_action` VARCHAR(50) DEFAULT NULL,
            `details` TEXT DEFAULT NULL,
            `false_positive` TINYINT(1) DEFAULT 0,
            `timestamp` BIGINT NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_player_id` (`player_id`),
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_timestamp` (`timestamp`),
            INDEX `idx_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(result)
        if result then
            Logger.Info('✅ ai_detections_live table ready')
        end
    end)
    
    -- Create ai_detection_whitelist table if it doesn't exist
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ai_detection_whitelist` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `type` VARCHAR(50) NOT NULL,
            `reason` TEXT DEFAULT NULL,
            `added_by` VARCHAR(255) NOT NULL,
            `added_at` BIGINT NOT NULL,
            `expires_at` BIGINT DEFAULT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `identifier_unique` (`identifier`),
            INDEX `idx_identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(result)
        if result then
            Logger.Info('✅ ai_detection_whitelist table ready')
        end
    end)
    
    -- Create ai_detection_rules table if it doesn't exist
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ai_detection_rules` (
            `id` VARCHAR(50) PRIMARY KEY,
            `name` VARCHAR(255) NOT NULL,
            `category` VARCHAR(50) NOT NULL,
            `enabled` TINYINT(1) DEFAULT 1,
            `sensitivity` INT NOT NULL DEFAULT 75,
            `auto_action` VARCHAR(50) DEFAULT NULL,
            `threshold` INT NOT NULL DEFAULT 80,
            `description` TEXT DEFAULT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_category` (`category`),
            INDEX `idx_enabled` (`enabled`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(result)
        if result then
            Logger.Info('✅ ai_detection_rules table ready')
        end
    end)
end)

Logger.Info('✅ AI Detection database migration loaded')