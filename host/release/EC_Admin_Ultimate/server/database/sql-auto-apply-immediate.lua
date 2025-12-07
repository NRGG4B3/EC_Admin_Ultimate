-- ============================================================================
-- EC ADMIN ULTIMATE - IMMEDIATE SQL AUTO-APPLY (HOST + CUSTOMER)
-- ============================================================================
-- This file runs FIRST on server startup
-- Applies ALL SQL migrations immediately for both HOST and CUSTOMER modes
-- NO tracking table needed - uses simple flag system
-- ============================================================================

Logger.Info('🚀 [STARTUP] SQL Auto-Apply System Starting...')

local SQLAutoApply = {}
SQLAutoApply.AppliedMigrations = {}
SQLAutoApply.MigrationFlags = {}

-- ============================================================================
-- CRITICAL: Apply all SQL immediately (non-blocking)
-- ============================================================================
local function ApplyAllSQLNow()
    Logger.Info('⏱️  [STARTUP] Applying SQL migrations immediately...')
    
    -- All SQL statements that MUST run on startup
    local criticalSQL = {
        -- FIX 1: Add missing 'category' column to action logs
        {
            name = 'Add category column to ec_admin_action_logs',
            sql = 'ALTER TABLE `ec_admin_action_logs` ADD COLUMN IF NOT EXISTS `category` VARCHAR(50) DEFAULT \'general\' AFTER `action`'
        },
        {
            name = 'Add index on category column',
            sql = 'ALTER TABLE `ec_admin_action_logs` ADD INDEX IF NOT EXISTS `idx_category` (`category`)'
        },
        -- FIX 2: Ensure migration tracking table exists
        {
            name = 'Create migration tracking table',
            sql = [[
                CREATE TABLE IF NOT EXISTS `ec_admin_migrations` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `filename` VARCHAR(255) NOT NULL UNIQUE,
                    `executed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    `success` BOOLEAN DEFAULT TRUE,
                    `error_message` TEXT NULL,
                    INDEX `idx_filename` (`filename`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            ]]
        },
        -- FIX 3: Ensure main action logs table has all columns
        {
            name = 'Ensure admin action logs table structure',
            sql = [[
                CREATE TABLE IF NOT EXISTS `ec_admin_action_logs` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `admin_identifier` VARCHAR(100),
                    `admin_name` VARCHAR(50),
                    `action` VARCHAR(100),
                    `category` VARCHAR(50) DEFAULT 'general',
                    `target_identifier` VARCHAR(100),
                    `target_name` VARCHAR(50),
                    `details` TEXT,
                    `metadata` JSON,
                    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    `action_type` VARCHAR(50),
                    INDEX `idx_admin` (`admin_identifier`),
                    INDEX `idx_timestamp` (`timestamp`),
                    INDEX `idx_category` (`category`),
                    INDEX `idx_action_type` (`action_type`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            ]]
        }
    }
    
    -- Execute all SQL immediately
    local executedCount = 0
    for _, migration in ipairs(criticalSQL) do
        MySQL.Async.execute(migration.sql, {}, function(result)
            if result or result == 0 then
                Logger.Success(string.format('✅ [SQL] %s', migration.name))
                executedCount = executedCount + 1
            else
                Logger.Error(string.format('❌ [SQL] %s - FAILED', migration.name))
            end
        end)
    end
    
    Logger.Info(string.format('📊 [STARTUP] Queued %d SQL statements for immediate execution', #criticalSQL))
end

-- ============================================================================
-- LOAD MIGRATION FILES FROM SQL DIRECTORY
-- ============================================================================
local function LoadMigrationFiles()
    Logger.Info('📂 [STARTUP] Loading ALL SQL schema files...')
    
    local sqlFiles = {
        'sql/ec_admin_complete_schema.sql',  -- MAIN: Complete schema with all tables
        'sql/migrations/001_add_category_to_action_logs.sql',
        'sql/migrations/002_add_admin_abuse_columns.sql',
        'sql/migrations/003_add_ai_analytics_tables.sql',
    }
    
    for _, sqlPath in ipairs(sqlFiles) do
        local content = LoadResourceFile(GetCurrentResourceName(), sqlPath)
        if content and content ~= '' then
            Logger.Info(string.format('📄 [SQL] Loading: %s (%d bytes)', sqlPath, #content))
            
            -- Split into statements and execute
            local statementCount = 0
            for statement in content:gmatch('[^;]+') do
                local trimmed = statement:match('^%s*(.-)%s*$')
                if trimmed and trimmed ~= '' and not trimmed:match('^%-%-') and not trimmed:match('^%s*$') then
                    statementCount = statementCount + 1
                    MySQL.Async.execute(trimmed, {}, function(result)
                        if result or result == 0 then
                            Logger.Success(string.format('✅ [SQL-Statement] Executed'))
                        else
                            Logger.Error(string.format('❌ [SQL-Statement] Failed'))
                        end
                    end)
                end
            end
            Logger.Info(string.format('✔️  [SQL] Queued %d statements from %s', statementCount, sqlPath:match('([^/]+)$')))
        else
            Logger.Debug(string.format('⚠️  [SQL] File not found or empty: %s', sqlPath))
        end
    end
end

-- ============================================================================
-- ENSURE ALL TABLES EXIST ON STARTUP
-- ============================================================================
local function EnsureTablesExist()
    Logger.Info('✔️  [STARTUP] Verifying all required tables exist...')
    
    -- Check and create essential tables
    local tables = {
        'ec_admin_action_logs',
        'ec_admin_migrations',
        'ec_admin_config',
        'player_reports',
        'ec_admin_abuse_logs'
    }
    
    for _, tableName in ipairs(tables) do
        MySQL.Async.fetchAll(string.format('SHOW TABLES LIKE \'%s\'', tableName), {}, function(results)
            if results and #results > 0 then
                Logger.Success(string.format('✅ [Tables] Found: %s', tableName))
            else
                Logger.Warn(string.format('⚠️  [Tables] Missing: %s (will be created by migrations)', tableName))
            end
        end)
    end
end

-- ============================================================================
-- STARTUP SEQUENCE (Called immediately)
-- ============================================================================
CreateThread(function()
    -- Wait for oxmysql to initialize
    local maxWait = 50  -- 5 seconds
    local waited = 0
    
    while not MySQL or not MySQL.Async or not MySQL.Async.execute do
        Wait(100)
        waited = waited + 1
        if waited % 10 == 0 then
            Logger.Info(string.format('⏳ [STARTUP] Waiting for oxmysql... (%d/50)', waited))
        end
        if waited >= maxWait then
            Logger.Error('❌ [STARTUP] oxmysql failed to initialize in time!')
            return
        end
    end
    
    Logger.Success('✅ [STARTUP] oxmysql initialized - applying migrations now')
    
    -- Apply all SQL immediately
    ApplyAllSQLNow()
    
    -- Load external migration files
    LoadMigrationFiles()
    
    -- Verify tables exist
    Wait(1000)  -- Give SQL time to execute
    EnsureTablesExist()
    
    Logger.Success('✅ [STARTUP] SQL Auto-Apply completed - system ready!')
end)

-- ============================================================================
-- EXPORT: Manual trigger for SQL migrations (admin command)
-- ============================================================================
exports('ApplySQLMigrations', function()
    Logger.Info('🔄 [Admin] Manual SQL migration triggered')
    ApplyAllSQLNow()
    LoadMigrationFiles()
    return true
end)

Logger.Info('✅ [Loaded] SQL Auto-Apply System - Migrations will run automatically on startup')
