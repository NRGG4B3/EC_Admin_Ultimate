--[[
    EC Admin Ultimate - AUTOMATIC Database Setup
    Creates ALL tables automatically on startup
    ZERO manual SQL required!
]]

-- Simple logger replacement (no external dependencies)
local Logger = {
    System = function(msg) Logger.Info('[EC Admin DB] ' .. msg) end,
    Debug = function(msg) Logger.Info('[EC Admin DB] ' .. msg) end,
    Error = function(msg) Logger.Error('[EC Admin DB ERROR] ' .. msg) end,
    Success = function(msg) Logger.Success('[EC Admin DB] ' .. msg) end
}

local DB_AUTO = {}

-- All tables that EC Admin needs (COMPLETE LIST)
DB_AUTO.TABLES = {
    -- Core admin tables
    {
        name = 'ec_admin_permissions',
        sql = [[
            CREATE TABLE IF NOT EXISTS `ec_admin_permissions` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `identifier` VARCHAR(100) NOT NULL,
                `permission_level` INT DEFAULT 1,
                `permissions` TEXT NULL,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE KEY `identifier_unique` (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    {
        name = 'ec_admin_logs',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    {
        name = 'ec_admin_action_logs',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- Bans & Warnings
    {
        name = 'ec_admin_bans',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    {
        name = 'ec_admin_warnings',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- Reports
    {
        name = 'ec_admin_reports',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    {
        name = 'scheduled_reports',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- Admin Team
    {
        name = 'ec_admin_team',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- AI Detection
    {
        name = 'ai_detections_live',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    {
        name = 'ai_detection_rules',
        sql = [[
            CREATE TABLE IF NOT EXISTS `ai_detection_rules` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `rule_name` VARCHAR(100) NOT NULL,
                `detection_type` VARCHAR(100) NOT NULL,
                `threshold` FLOAT NOT NULL,
                `action` VARCHAR(50) NOT NULL,
                `enabled` TINYINT(1) DEFAULT 1,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX `idx_enabled` (`enabled`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    {
        name = 'ai_detection_whitelist',
        sql = [[
            CREATE TABLE IF NOT EXISTS `ai_detection_whitelist` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `identifier` VARCHAR(100) NOT NULL,
                `player_name` VARCHAR(100) NOT NULL,
                `reason` TEXT NULL,
                `added_by` VARCHAR(100) NOT NULL,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY `identifier_unique` (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- AI Analytics
    {
        name = 'ai_analytics_snapshots',
        sql = [[
            CREATE TABLE IF NOT EXISTS `ai_analytics_snapshots` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `snapshot_type` VARCHAR(50) NOT NULL,
                `data` TEXT NOT NULL,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX `idx_snapshot_type` (`snapshot_type`),
                INDEX `idx_created_at` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- Settings
    {
        name = 'ec_admin_settings',
        sql = [[
            CREATE TABLE IF NOT EXISTS `ec_admin_settings` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `setting_key` VARCHAR(100) NOT NULL,
                `setting_value` TEXT NULL,
                `setting_type` VARCHAR(50) DEFAULT 'string',
                `category` VARCHAR(50) DEFAULT 'general',
                `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE KEY `setting_key_unique` (`setting_key`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- Whitelist & Queue
    {
        name = 'ec_whitelist',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    {
        name = 'ec_whitelist_applications',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- Global Bans (Host only)
    {
        name = 'ec_global_bans',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- Customer Servers (Host only)
    {
        name = 'ec_customer_servers',
        sql = [[
            CREATE TABLE IF NOT EXISTS `ec_customer_servers` (
                `id` VARCHAR(50) PRIMARY KEY,
                `name` VARCHAR(100) NOT NULL,
                `ip` VARCHAR(50) NOT NULL,
                `status` VARCHAR(20) DEFAULT 'offline',
                `current_players` INT DEFAULT 0,
                `max_players` INT DEFAULT 48,
                `version` VARCHAR(20) DEFAULT '3.5.0',
                `framework` VARCHAR(20) DEFAULT 'unknown',
                `connected_apis` TEXT NULL,
                `last_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- Community Management
    {
        name = 'ec_community_messages',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- Performance Monitoring
    {
        name = 'ec_performance_snapshots',
        sql = [[
            CREATE TABLE IF NOT EXISTS `ec_performance_snapshots` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `snapshot_data` TEXT NOT NULL,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX `idx_created_at` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- Player History
    {
        name = 'ec_player_history',
        sql = [[
            CREATE TABLE IF NOT EXISTS `ec_player_history` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `identifier` VARCHAR(100) NOT NULL,
                `player_count` INT NOT NULL,
                `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX `idx_timestamp` (`timestamp`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- ✅ PRODUCTION v1.0.0 - Metrics & Analytics System
    
    -- Server Metrics History (auto-collected every 60s)
    {
        name = 'ec_admin_metrics_history',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- Webhook Execution Logs (Discord & external webhooks)
    {
        name = 'ec_admin_webhook_logs',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
    
    -- API Usage Tracking (external API calls)
    {
        name = 'ec_admin_api_usage',
        sql = [[
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    },
}

-- Check if table exists
function DB_AUTO.TableExists(tableName)
    local result = MySQL.query.await([[
        SELECT COUNT(*) as count 
        FROM information_schema.tables 
        WHERE table_schema = DATABASE() 
        AND table_name = ?
    ]], {tableName})
    
    return result and result[1] and result[1].count > 0
end

-- Create all tables automatically (runs on EVERY restart)
function DB_AUTO.CreateAllTables()
    Logger.System('🔍 Checking database tables...')
    
    local existingCount = 0
    local createdCount = 0
    local errorCount = 0
    local newTables = {}
    
    for _, table in ipairs(DB_AUTO.TABLES) do
        local exists = DB_AUTO.TableExists(table.name)
        
        if exists then
            existingCount = existingCount + 1
        else
            -- Table doesn't exist - create it
            local success, err = pcall(function()
                MySQL.query.await(table.sql, {})
            end)
            
            if success then
                createdCount = createdCount + 1
                table.insert(newTables, table.name)
                Logger.Success('✅ Created NEW table: ' .. table.name)
            else
                errorCount = errorCount + 1
                Logger.Error('❌ Failed to create table: ' .. table.name .. ' - ' .. tostring(err))
            end
        end
        
        Wait(50) -- Prevent overwhelming database
    end
    
    -- Summary
    Logger.System('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    Logger.System(string.format('📊 Database Status: %d total tables', #DB_AUTO.TABLES))
    Logger.System(string.format('   ✅ Existing: %d tables', existingCount))
    
    if createdCount > 0 then
        Logger.Success(string.format('   🆕 Created: %d NEW tables', createdCount))
        Logger.System('   📝 New tables added:')
        for _, name in ipairs(newTables) do
            Logger.System('      • ' .. name)
        end
    end
    
    if errorCount > 0 then
        Logger.Warning(string.format('   ⚠️  Errors: %d tables', errorCount))
    end
    
    Logger.System('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    
    if createdCount > 0 then
        Logger.Success('🎉 Database upgraded successfully! New tables added.')
    elseif existingCount == #DB_AUTO.TABLES then
        Logger.Success('✅ All tables exist - Database up to date!')
    end
end

-- Safe query wrapper - auto-creates table if it doesn't exist
function DB_AUTO.SafeQuery(query, params, callback)
    MySQL.Async.fetchAll(query, params or {}, function(result)
        if callback then
            callback(result)
        end
    end, function(error)
        -- Error occurred - check if table doesn't exist
        if error and string.find(error, "doesn't exist") then
            local tableName = error:match("Table '.-%.(%w+)'")
            if tableName then
                Logger.Info('Table missing: ' .. tableName .. ' - Creating now...')
                
                -- Find and create the table
                for _, table in ipairs(DB_AUTO.TABLES) do
                    if table.name == tableName then
                        pcall(function()
                            MySQL.Sync.execute(table.sql, {})
                            Logger.Success('Table created: ' .. tableName)
                            
                            -- Retry the original query
                            MySQL.Async.fetchAll(query, params or {}, function(result)
                                if callback then
                                    callback(result)
                                end
                            end)
                        end)
                        break
                    end
                end
            end
        else
            -- Other error - log but don't crash
            Logger.Warning('Database query error (non-critical): ' .. tostring(error))
            if callback then
                callback(nil)
            end
        end
    end)
end

-- Initialize on EVERY startup (checks for new tables on updates)
CreateThread(function()
    Wait(5000) -- Wait for oxmysql to load
    
    if not MySQL then
        Logger.Error('❌ MySQL not detected - cannot verify/create tables')
        Logger.Error('   Make sure oxmysql is started BEFORE EC_Admin_Ultimate')
        return
    end
    
    Logger.System('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    Logger.System('🗄️  EC ADMIN ULTIMATE - DATABASE AUTO-SETUP')
    Logger.System('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    
    DB_AUTO.CreateAllTables()
    
    Logger.System('')
    Logger.System('🚀 Database initialization complete!')
    Logger.System('   Press F2 in-game to open admin panel')
    Logger.System('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
end)

return DB_AUTO