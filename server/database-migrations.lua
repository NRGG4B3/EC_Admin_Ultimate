--[[
    EC Admin Ultimate - Database Migration System
    PRD Section 9: Database & Migrations
    
    Features:
    - Schema versioning table
    - Safe single-statement execution
    - Migration tracking
    - Rollback support
]]

local Migrations = {
    currentVersion = 0,
    targetVersion = 8 -- v1.0.0 Production: Added metrics, webhook, and API tracking tables
}

-- Schema version table (must exist first)
local function CreateVersionTable()
    if not MySQL then
        Logger.Error('MySQL not available')
        return false
    end
    
    local success = MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ec_admin_schema_version` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `version` INT NOT NULL,
            `description` VARCHAR(255) NOT NULL,
            `applied_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `success` BOOLEAN DEFAULT TRUE,
            INDEX `idx_version` (`version`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]], {})
    
    if success then
        Logger.Success("[Migrations] Schema version table ready")
        return true
    else
        Logger.Error("[Migrations] Failed to create version table")
        return false
    end
end

-- Get current schema version
local function GetCurrentVersion()
    if not MySQL then return 0 end
    
    local result = MySQL.query.await('SELECT MAX(version) as version FROM ec_admin_schema_version WHERE success = TRUE', {})
    
    if result and result[1] then
        return result[1].version or 0
    end
    
    return 0
end

-- Record migration
local function RecordMigration(version, description, success)
    if not MySQL then return end
    
    MySQL.insert.await('INSERT INTO ec_admin_schema_version (version, description, success) VALUES (?, ?, ?)', {
        version,
        description,
        success
    })
end

-- Migration definitions (ONE statement per migration)
local MigrationList = {
    -- Migration 1: Core admin tables
    {
        version = 1,
        description = "Create core admin tables (bans, warnings, permissions)",
        up = function()
            local queries = {
                -- Bans
                [[CREATE TABLE IF NOT EXISTS `ec_admin_bans` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `identifier` VARCHAR(100) NOT NULL,
                    `license` VARCHAR(100) DEFAULT NULL,
                    `discord` VARCHAR(100) DEFAULT NULL,
                    `fivem` VARCHAR(100) DEFAULT NULL,
                    `player_name` VARCHAR(255) NOT NULL,
                    `banned_by` VARCHAR(100) NOT NULL,
                    `reason` TEXT NOT NULL,
                    `ip` VARCHAR(45) DEFAULT NULL,
                    `ban_type` ENUM('permanent', 'temporary') DEFAULT 'permanent',
                    `expires` BIGINT DEFAULT 0,
                    `is_global` BOOLEAN DEFAULT FALSE,
                    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    `active` BOOLEAN DEFAULT TRUE,
                    INDEX `idx_identifier` (`identifier`),
                    INDEX `idx_active` (`active`),
                    INDEX `idx_expires` (`expires`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
                
                -- Warnings
                [[CREATE TABLE IF NOT EXISTS `ec_admin_warnings` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `identifier` VARCHAR(100) NOT NULL,
                    `player_name` VARCHAR(255) NOT NULL,
                    `warned_by` VARCHAR(100) NOT NULL,
                    `reason` TEXT NOT NULL,
                    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX `idx_identifier` (`identifier`),
                    INDEX `idx_created` (`created_at`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
                
                -- Permissions
                [[CREATE TABLE IF NOT EXISTS `ec_admin_permissions` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `identifier` VARCHAR(100) NOT NULL UNIQUE,
                    `player_name` VARCHAR(255) NOT NULL,
                    `role` ENUM('user', 'moderator', 'admin', 'superadmin', 'owner') DEFAULT 'user',
                    `permissions` JSON,
                    `granted_by` VARCHAR(100) DEFAULT NULL,
                    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    INDEX `idx_identifier` (`identifier`),
                    INDEX `idx_role` (`role`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]]
            }
            
            for _, query in ipairs(queries) do
                local success = MySQL.query.await(query, {})
                if not success then
                    return false
                end
                Wait(100) -- Prevent overwhelming DB
            end
            
            return true
        end
    },
    
    -- Migration 2: Audit logs
    {
        version = 2,
        description = "Create admin action audit log",
        up = function()
            return MySQL.query.await([[
                CREATE TABLE IF NOT EXISTS `ec_admin_logs` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `actor_identifier` VARCHAR(100) NOT NULL,
                    `actor_name` VARCHAR(255) NOT NULL,
                    `action_type` VARCHAR(50) NOT NULL,
                    `target_identifier` VARCHAR(100) DEFAULT NULL,
                    `target_name` VARCHAR(255) DEFAULT NULL,
                    `details` JSON,
                    `reason` TEXT,
                    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX `idx_actor` (`actor_identifier`),
                    INDEX `idx_target` (`target_identifier`),
                    INDEX `idx_action` (`action_type`),
                    INDEX `idx_created` (`created_at`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            ]], {})
        end
    },
    
    -- Migration 3: Sessions tracking
    {
        version = 3,
        description = "Create session tracking tables",
        up = function()
            local queries = {
                [[CREATE TABLE IF NOT EXISTS `ec_admin_sessions` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `identifier` VARCHAR(100) NOT NULL,
                    `player_name` VARCHAR(255) NOT NULL,
                    `join_time` BIGINT NOT NULL,
                    `leave_time` BIGINT DEFAULT NULL,
                    `duration` INT DEFAULT 0,
                    `ip_address` VARCHAR(45) DEFAULT NULL,
                    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX `idx_identifier` (`identifier`),
                    INDEX `idx_join_time` (`join_time`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
                
                [[CREATE TABLE IF NOT EXISTS `ec_admin_player_stats` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `identifier` VARCHAR(100) NOT NULL UNIQUE,
                    `player_name` VARCHAR(255) NOT NULL,
                    `total_playtime` BIGINT DEFAULT 0,
                    `total_sessions` INT DEFAULT 0,
                    `last_seen` BIGINT NOT NULL,
                    `first_seen` BIGINT NOT NULL,
                    `total_warnings` INT DEFAULT 0,
                    `total_kicks` INT DEFAULT 0,
                    `total_bans` INT DEFAULT 0,
                    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    INDEX `idx_identifier` (`identifier`),
                    INDEX `idx_last_seen` (`last_seen`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]]
            }
            
            for _, query in ipairs(queries) do
                local success = MySQL.query.await(query, {})
                if not success then return false end
                Wait(100)
            end
            
            return true
        end
    },
    
    -- Migration 4: Analytics (optional)
    {
        version = 4,
        description = "Create analytics tables (optional)",
        up = function()
            return MySQL.query.await([[
                CREATE TABLE IF NOT EXISTS `ec_admin_analytics` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `metric_type` VARCHAR(50) NOT NULL,
                    `metric_value` BIGINT NOT NULL,
                    `metadata` JSON,
                    `recorded_at` BIGINT NOT NULL,
                    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX `idx_type` (`metric_type`),
                    INDEX `idx_recorded` (`recorded_at`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            ]], {})
        end
    },
    
    -- Migration 5: Remote admin sessions
    {
        version = 5,
        description = "Create remote admin session table",
        up = function()
            return MySQL.query.await([[
                CREATE TABLE IF NOT EXISTS `ec_admin_remote_sessions` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `token` VARCHAR(255) NOT NULL UNIQUE,
                    `player_identifier` VARCHAR(100) NOT NULL,
                    `player_name` VARCHAR(255) NOT NULL,
                    `created_at` BIGINT NOT NULL,
                    `expires_at` BIGINT NOT NULL,
                    `last_used` BIGINT DEFAULT NULL,
                    `ip_address` VARCHAR(45) DEFAULT NULL,
                    `is_valid` BOOLEAN DEFAULT TRUE,
                    INDEX `idx_token` (`token`),
                    INDEX `idx_expires` (`expires_at`),
                    INDEX `idx_valid` (`is_valid`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            ]], {})
        end
    },
    
    -- Migration 6: Economy transaction tracking
    {
        version = 6,
        description = "Create economy transaction tracking table",
        up = function()
            return MySQL.query.await([[
                CREATE TABLE IF NOT EXISTS `ec_transactions` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `player_id` VARCHAR(100) NOT NULL,
                    `player_name` VARCHAR(255) DEFAULT NULL,
                    `transaction_type` ENUM('give', 'take', 'transfer', 'purchase', 'salary', 'other') DEFAULT 'other',
                    `amount` INT NOT NULL,
                    `balance_before` INT DEFAULT 0,
                    `balance_after` INT DEFAULT 0,
                    `reason` TEXT DEFAULT NULL,
                    `admin_identifier` VARCHAR(100) DEFAULT NULL,
                    `admin_name` VARCHAR(255) DEFAULT NULL,
                    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX `idx_player` (`player_id`),
                    INDEX `idx_type` (`transaction_type`),
                    INDEX `idx_created` (`created_at`),
                    INDEX `idx_admin` (`admin_identifier`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            ]], {})
        end
    },
    
    -- Migration 7: Fix ec_admin_logs column names
    {
        version = 7,
        description = "Rename admin_identifier to actor_identifier in ec_admin_logs",
        up = function()
            -- Check if the old column exists
            local result = MySQL.query.await([[
                SELECT COLUMN_NAME 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'ec_admin_logs' 
                AND COLUMN_NAME = 'admin_identifier'
            ]], {})
            
            -- If old column exists, rename it
            if result and #result > 0 then
                return MySQL.query.await([[
                    ALTER TABLE `ec_admin_logs` 
                    CHANGE COLUMN `admin_identifier` `actor_identifier` VARCHAR(100) NOT NULL,
                    CHANGE COLUMN `admin_name` `actor_name` VARCHAR(255) NOT NULL
                ]], {})
            end
            
            -- If columns don't exist or already renamed, migration is successful
            return true
        end
    },
    
    -- Migration 8: Production v1.0.0 - Metrics & Analytics
    {
        version = 8,
        description = "Create metrics history, webhook logs, and API usage tables",
        up = function()
            local queries = {
                -- Server metrics history
                [[CREATE TABLE IF NOT EXISTS `ec_admin_metrics_history` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `timestamp` BIGINT NOT NULL,
                    `players_online` INT NOT NULL DEFAULT 0,
                    `max_players` INT NOT NULL DEFAULT 64,
                    `avg_ping` INT NOT NULL DEFAULT 0,
                    `max_ping` INT NOT NULL DEFAULT 0,
                    `memory_mb` FLOAT NOT NULL DEFAULT 0,
                    `resources_started` INT NOT NULL DEFAULT 0,
                    `resources_total` INT NOT NULL DEFAULT 0,
                    `tps` INT NOT NULL DEFAULT 60,
                    `metadata` LONGTEXT DEFAULT NULL,
                    INDEX `idx_timestamp` (`timestamp`),
                    INDEX `idx_players` (`players_online`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
                
                -- Webhook execution logs
                [[CREATE TABLE IF NOT EXISTS `ec_admin_webhook_logs` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `webhook_url` VARCHAR(255) NOT NULL,
                    `webhook_type` VARCHAR(50) NOT NULL,
                    `event_type` VARCHAR(100) NOT NULL,
                    `status_code` INT DEFAULT NULL,
                    `success` TINYINT(1) DEFAULT 0,
                    `error_message` TEXT DEFAULT NULL,
                    `payload_size` INT DEFAULT 0,
                    `response_time_ms` INT DEFAULT NULL,
                    `timestamp` BIGINT NOT NULL,
                    INDEX `idx_timestamp` (`timestamp`),
                    INDEX `idx_webhook_type` (`webhook_type`),
                    INDEX `idx_success` (`success`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
                
                -- API usage tracking
                [[CREATE TABLE IF NOT EXISTS `ec_admin_api_usage` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `api_name` VARCHAR(100) NOT NULL,
                    `endpoint` VARCHAR(255) NOT NULL,
                    `method` VARCHAR(10) NOT NULL DEFAULT 'GET',
                    `status_code` INT DEFAULT NULL,
                    `success` TINYINT(1) DEFAULT 0,
                    `response_time_ms` INT DEFAULT NULL,
                    `error_message` TEXT DEFAULT NULL,
                    `timestamp` BIGINT NOT NULL,
                    INDEX `idx_timestamp` (`timestamp`),
                    INDEX `idx_api_name` (`api_name`),
                    INDEX `idx_success` (`success`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]]
            }
            
            for _, query in ipairs(queries) do
                local success = MySQL.query.await(query, {})
                if not success then
                    Logger.Error('Failed to create table')
                    return false
                end
                Wait(100) -- Prevent overwhelming DB
            end
            
            Logger.Success('✅ Created 3 metrics/analytics tables')
            return true
        end
    }
}

-- Run migrations
local function RunMigrations()
    -- Create version table first
    if not CreateVersionTable() then
        Logger.Error("❌ Failed to initialize version tracking")
        return false
    end
    
    Wait(500)
    
    -- Get current version
    local currentVersion = GetCurrentVersion()
    Migrations.currentVersion = currentVersion
    
    Logger.Info(string.format("[Migrations] Current schema version: %d", currentVersion))
    
    if currentVersion >= Migrations.targetVersion then
        Logger.Success("[Migrations] Schema is up to date")
        return true
    end
    
    -- Run pending migrations
    for _, migration in ipairs(MigrationList) do
        if migration.version > currentVersion then
            Logger.Info(string.format("▶️ Running migration %d: %s", migration.version, migration.description))
            
            local success, err = pcall(migration.up)
            
            if success and err ~= false then
                RecordMigration(migration.version, migration.description, true)
                Logger.Success(string.format("✅ Migration %d completed", migration.version))
                Wait(200)
            else
                RecordMigration(migration.version, migration.description, false)
                Logger.Error(string.format("❌ Migration %d failed: %s", migration.version, tostring(err)))
                return false
            end
        end
    end
    
    Logger.Success("✅ All migrations completed successfully")
    return true
end

-- Auto-run migrations on resource start
CreateThread(function()
    Wait(2000) -- Wait for MySQL to be ready
    
    if MySQL and MySQL.ready then
        RunMigrations()
    else
        Logger.Warn('⚠️ MySQL not ready, skipping migrations')
    end
end)

-- Export for manual runs
RegisterCommand('ec_migrate', function(source, args)
    if source ~= 0 then
        Logger.Warn("⚠️ This command can only be run from the server console")
        return
    end
    
    Logger.Info("▶️ Running migrations manually...")
    RunMigrations()
end, false)

RegisterCommand('ec_schema_version', function(source, args)
    if source ~= 0 then
        Logger.Warn("⚠️ This command can only be run from the server console")
        return
    end
    
    local version = GetCurrentVersion()
    Logger.Success(string.format("Current schema version: %d / %d", version, Migrations.targetVersion), '🗄️')
end, false)

Logger.Info("[Database Migrations] Initialized")
Logger.Info("  Commands: ec_migrate, ec_schema_version")
Logger.Info(string.format("  Target version: %d", Migrations.targetVersion))