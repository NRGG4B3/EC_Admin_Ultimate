-- EC Admin Ultimate - Database System (PRODUCTION STABLE)
-- Version: 1.0.0 - Safe database operations with fallbacks

Logger.Info('💾 Loading database system...')

local Database = {}

-- Database state
local databaseReady = false
local connectionAttempts = 0
local maxConnectionAttempts = 3

-- Query statistics tracking
local QueryStats = {
    totalQueries = 0,
    queryTimes = {},
    maxSamples = 100,
    failedQueries = 0
}

-- Calculate average query time
local function CalculateAverageQueryTime()
    if #QueryStats.queryTimes == 0 then return 0 end
    local sum = 0
    for _, time in ipairs(QueryStats.queryTimes) do
        sum = sum + time
    end
    return math.floor((sum / #QueryStats.queryTimes) * 10) / 10
end

-- Safe utility functions
local function SafeExecute(query, parameters, callback)
    if not databaseReady then
        QueryStats.failedQueries = QueryStats.failedQueries + 1
        if callback then callback(false, 'Database not ready') end
        return false
    end
    
    -- Track query start time
    QueryStats.totalQueries = QueryStats.totalQueries + 1
    local startTime = os.clock()
    
    -- Use a timeout to prevent hanging
    local timeoutTimer = nil
    local completed = false
    
    timeoutTimer = SetTimeout(10000, function()
        if not completed then
            completed = true
            QueryStats.failedQueries = QueryStats.failedQueries + 1
            if callback then callback(false, 'Database query timeout') end
        end
    end)
    
    exports.oxmysql:execute(query, parameters, function(result)
        if completed then return end
        completed = true
        
        if timeoutTimer then
            ClearTimeout(timeoutTimer)
        end
        
        -- Calculate query time
        local endTime = os.clock()
        local queryTime = (endTime - startTime) * 1000 -- Convert to milliseconds
        
        -- Store query time
        table.insert(QueryStats.queryTimes, queryTime)
        if #QueryStats.queryTimes > QueryStats.maxSamples then
            table.remove(QueryStats.queryTimes, 1)
        end
        
        -- Update GlobalState for UI
        GlobalState.dbQueries = QueryStats.totalQueries
        GlobalState.dbAvgTime = CalculateAverageQueryTime()
        GlobalState.dbFailedQueries = QueryStats.failedQueries
        
        if callback then
            callback(result ~= nil, result)
        end
    end)
    
    return true
end

-- Initialize database connection (safe, non-blocking)
function Database.Initialize()
    Logger.Info('💾 Initializing database system...')
    
    -- Check if database is enabled in config
    if not Config or not Config.Database or not Config.Database.enabled then
        Logger.Info('⚠️  Database disabled in config - using memory-only mode')
        Logger.Info('ℹ️  To enable database: Set Config.Database.enabled = true in config.lua')
        return false
    end
    
    -- Check if oxmysql is available
    if GetResourceState('oxmysql') ~= 'started' then
        Logger.Warn('❌ oxmysql resource not found or not started')
        Logger.Info('ℹ️  Using memory-only mode (data will not persist)')
        Logger.Info('📝 To fix this:')
        Logger.Info('   1. Ensure oxmysql is in your resources folder')
        Logger.Info('   2. Add to server.cfg: ensure oxmysql')
        Logger.Info('   3. Add to server.cfg: set mysql_connection_string "mysql://user:pass@localhost/database"')
        return false
    end
    
    -- Test database connection in a safe way
    CreateThread(function()
        Wait(3000) -- Wait for oxmysql to be fully ready
        
        Database.TestConnection(function(success)
            if success then
                Logger.Success('✅ Database connection established')
                Logger.Info('✅ Data will persist across restarts')
                databaseReady = true
                Database.CreateTables()
            else
                Logger.Error('❌ Database connection failed - using memory-only mode')
                Logger.Warn('⚠️  Data will NOT persist across restarts')
                Logger.Info('📝 Possible causes:')
                Logger.Info('   1. MySQL server is not running')
                Logger.Info('   2. Wrong credentials in server.cfg')
                Logger.Info('   3. Database does not exist')
                Logger.Info('   4. mysql_connection_string not set in server.cfg')
                Logger.Info('💡 To fix: Check your server.cfg for mysql_connection_string')
                Logger.Info('   Example: set mysql_connection_string "mysql://root:password@localhost/fivem"')
                databaseReady = false
            end
        end)
    end)
    
    return true
end

-- Test database connection (safe)
function Database.TestConnection(callback)
    connectionAttempts = connectionAttempts + 1
    
    if connectionAttempts > maxConnectionAttempts then
        Logger.Info('❌ Max database connection attempts reached')
        if callback then callback(false) end
        return
    end
    
    -- CRITICAL FIX: Test connection WITHOUT using SafeExecute (which requires databaseReady)
    -- Use oxmysql directly for the initial connection test
    local success = pcall(function()
        exports.oxmysql:execute('SELECT 1 as test', {}, function(result)
            if result and #result > 0 then
                Logger.Info('✅ Database test query successful')
                if callback then callback(true) end
            else
                Logger.Info('❌ Database test query failed: No result returned')
                if callback then callback(false) end
            end
        end)
    end)
    
    if not success then
        Logger.Info('❌ Database test query failed: oxmysql error')
        if callback then callback(false) end
    end
end

-- Create database tables (safe, non-blocking)
function Database.CreateTables()
    if not databaseReady then
        Logger.Warn('⚠️ Cannot create tables - database not ready')
        return
    end
    
    Logger.Info('📋 Creating database tables...')
    
    CreateThread(function()
        local queries = {
            -- Admin permissions table
            {
                name = 'ec_admin_permissions',
                query = [[
                CREATE TABLE IF NOT EXISTS `ec_admin_permissions` (
                    `id` int(11) NOT NULL AUTO_INCREMENT,
                    `identifier` varchar(60) NOT NULL,
                    `player_name` varchar(100) NOT NULL,
                    `permission_level` varchar(20) NOT NULL DEFAULT 'user',
                    `granted_by` varchar(60) DEFAULT NULL,
                    `granted_at` timestamp DEFAULT CURRENT_TIMESTAMP,
                    `last_login` timestamp NULL DEFAULT NULL,
                    `active` tinyint(1) DEFAULT 1,
                    PRIMARY KEY (`id`),
                    UNIQUE KEY `identifier_unique` (`identifier`),
                    INDEX `permission_level_index` (`permission_level`),
                    INDEX `active_index` (`active`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
                ]]
            },
            
            -- Admin general logs
            {
                name = 'ec_admin_logs',
                query = [[
                CREATE TABLE IF NOT EXISTS `ec_admin_logs` (
                    `id` int(11) NOT NULL AUTO_INCREMENT,
                    `admin_identifier` varchar(60) NOT NULL,
                    `admin_name` varchar(100) NOT NULL,
                    `action` varchar(50) NOT NULL,
                    `target_identifier` varchar(60) DEFAULT NULL,
                    `target_name` varchar(100) DEFAULT NULL,
                    `details` TEXT DEFAULT NULL,
                    `server_id` int(11) DEFAULT 1,
                    `timestamp` timestamp DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (`id`),
                    INDEX `admin_identifier_index` (`admin_identifier`),
                    INDEX `action_index` (`action`),
                    INDEX `timestamp_index` (`timestamp`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
                ]]
            },
            
            -- Player bans table
            {
                name = 'ec_admin_bans',
                query = [[
                CREATE TABLE IF NOT EXISTS `ec_admin_bans` (
                    `id` int(11) NOT NULL AUTO_INCREMENT,
                    `identifier` varchar(60) NOT NULL,
                    `license` varchar(100) DEFAULT NULL,
                    `discord` varchar(100) DEFAULT NULL,
                    `fivem` varchar(100) DEFAULT NULL,
                    `player_name` varchar(100) NOT NULL,
                    `reason` TEXT NOT NULL,
                    `banned_by` varchar(60) NOT NULL,
                    `ip` varchar(45) DEFAULT NULL,
                    `banned_by_name` varchar(100) NOT NULL,
                    `ban_date` timestamp DEFAULT CURRENT_TIMESTAMP,
                    `expires` BIGINT(20) DEFAULT 0,
                    `active` tinyint(1) DEFAULT 1,
                    `server_id` int(11) DEFAULT 1,
                    PRIMARY KEY (`id`),
                    INDEX `identifier_index` (`identifier`),
                    INDEX `active_index` (`active`),
                    INDEX `expires_index` (`expires`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
                ]]
            },
            
            -- Player warnings table
            {
                name = 'ec_admin_warnings',
                query = [[
                CREATE TABLE IF NOT EXISTS `ec_admin_warnings` (
                    `id` int(11) NOT NULL AUTO_INCREMENT,
                    `identifier` varchar(60) NOT NULL,
                    `player_name` varchar(100) NOT NULL,
                    `reason` TEXT NOT NULL,
                    `warned_by` varchar(60) NOT NULL,
                    `warned_by_name` varchar(100) NOT NULL,
                    `warning_date` timestamp DEFAULT CURRENT_TIMESTAMP,
                    `server_id` int(11) DEFAULT 1,
                    PRIMARY KEY (`id`),
                    INDEX `identifier_index` (`identifier`),
                    INDEX `warning_date_index` (`warning_date`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
                ]]
            },
            
            -- Admin action logs (detailed tracking)
            {
                name = 'ec_admin_action_logs',
                query = [[
                CREATE TABLE IF NOT EXISTS `ec_admin_action_logs` (
                    `id` int(11) NOT NULL AUTO_INCREMENT,
                    `admin_identifier` varchar(60) NOT NULL,
                    `admin_name` varchar(100) NOT NULL,
                    `action` varchar(50) NOT NULL,
                    `action_type` varchar(50) DEFAULT NULL,
                    `target_identifier` varchar(60) DEFAULT NULL,
                    `target_name` varchar(100) DEFAULT NULL,
                    `details` TEXT DEFAULT NULL,
                    `server_id` int(11) DEFAULT 1,
                    `timestamp` timestamp DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (`id`),
                    INDEX `admin_identifier_index` (`admin_identifier`),
                    INDEX `action_index` (`action`),
                    INDEX `timestamp_index` (`timestamp`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
                ]]
            },
            {
                name = 'ec_admin_reports',
                query = [[
                CREATE TABLE IF NOT EXISTS `ec_admin_reports` (
                    `id` int(11) NOT NULL AUTO_INCREMENT,
                    `reporter_identifier` varchar(60) NOT NULL,
                    `reporter_name` varchar(100) NOT NULL,
                    `reported_identifier` varchar(60) DEFAULT NULL,
                    `reported_name` varchar(100) DEFAULT NULL,
                    `category` varchar(50) NOT NULL DEFAULT 'other',
                    `reason` TEXT NOT NULL,
                    `details` TEXT DEFAULT NULL,
                    `status` varchar(20) NOT NULL DEFAULT 'open',
                    `priority` varchar(20) NOT NULL DEFAULT 'medium',
                    `assigned_to` varchar(60) DEFAULT NULL,
                    `assigned_name` varchar(100) DEFAULT NULL,
                    `resolution` TEXT DEFAULT NULL,
                    `server_id` int(11) DEFAULT 1,
                    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
                    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    `resolved_at` timestamp NULL DEFAULT NULL,
                    PRIMARY KEY (`id`),
                    INDEX `reporter_index` (`reporter_identifier`),
                    INDEX `status_index` (`status`),
                    INDEX `priority_index` (`priority`),
                    INDEX `created_index` (`created_at`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
                ]]
            }
        }
        
        -- Execute each table creation query
        for _, tableData in ipairs(queries) do
            SafeExecute(tableData.query, {}, function(success, result)
                if success then
                    Logger.Success('✅ Table created/verified: ' .. tableData.name)
                else
                    Logger.Error('❌ Failed to create table ' .. tableData.name .. ': ' .. tostring(result))
                end
            end)
            
            -- Small delay between queries to prevent overwhelming the database
            Wait(500)
        end
        
        -- Add missing columns to existing tables (for upgrades)
        Logger.Info('🔧 Checking for missing columns...')
        
        -- Check if action_type column exists, if not add it
        SafeExecute([[
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'ec_admin_action_logs' 
            AND COLUMN_NAME = 'action_type'
        ]], {}, function(success, result)
            if success and result and #result == 0 then
                -- Column doesn't exist, add it
                SafeExecute([[
                    ALTER TABLE ec_admin_action_logs 
                    ADD COLUMN action_type varchar(50) DEFAULT NULL 
                    AFTER action
                ]], {}, function(alterSuccess, alterResult)
                    if alterSuccess then
                        Logger.Info('✅ Added action_type column to ec_admin_action_logs')
                    else
                        Logger.Info('❌ Failed to add action_type column: ' .. tostring(alterResult))
                    end
                end)
            else
                Logger.Info('ℹ️  action_type column already exists')
            end
        end)
        
        Wait(500)
        
        Logger.Success('✅ Database table creation completed')
    end)
end

-- Database query functions (safe)
function Database.Query(query, parameters, callback)
    return SafeExecute(query, parameters, callback)
end

function Database.Insert(table, data, callback)
    if not databaseReady then
        if callback then callback(false, 'Database not ready') end
        return false
    end
    
    local columns = {}
    local values = {}
    local placeholders = {}
    
    for column, value in pairs(data) do
        table.insert(columns, '`' .. column .. '`')
        table.insert(values, value)
        table.insert(placeholders, '?')
    end
    
    local query = string.format('INSERT INTO `%s` (%s) VALUES (%s)', 
                               table, 
                               table.concat(columns, ', '), 
                               table.concat(placeholders, ', '))
    
    return SafeExecute(query, values, callback)
end

function Database.Update(table, data, where, callback)
    if not databaseReady then
        if callback then callback(false, 'Database not ready') end
        return false
    end
    
    local setParts = {}
    local values = {}
    
    for column, value in pairs(data) do
        table.insert(setParts, '`' .. column .. '` = ?')
        table.insert(values, value)
    end
    
    local query = string.format('UPDATE `%s` SET %s WHERE %s', 
                               table, 
                               table.concat(setParts, ', '), 
                               where)
    
    return SafeExecute(query, values, callback)
end

-- Player permission functions (safe)
function Database.GetPlayerPermission(identifier, callback)
    if not databaseReady then
        if callback then callback('user') end
        return 'user'
    end
    
    SafeExecute('SELECT permission_level FROM ec_admin_permissions WHERE identifier = ? AND active = 1', 
               {identifier}, 
               function(success, result)
                   if success and result and result[1] then
                       if callback then callback(result[1].permission_level) end
                   else
                       if callback then callback('user') end
                   end
               end)
end

function Database.SetPlayerPermission(identifier, playerName, level, grantedBy, callback)
    if not databaseReady then
        if callback then callback(false, 'Database not ready') end
        return false
    end
    
    local data = {
        identifier = identifier,
        player_name = playerName,
        permission_level = level,
        granted_by = grantedBy,
        granted_at = os.date('%Y-%m-%d %H:%M:%S'),
        active = 1
    }
    
    -- Try insert first, update on duplicate key
    local query = [[
    INSERT INTO ec_admin_permissions (identifier, player_name, permission_level, granted_by, granted_at, active) 
    VALUES (?, ?, ?, ?, ?, ?) 
    ON DUPLICATE KEY UPDATE 
    permission_level = VALUES(permission_level), 
    granted_by = VALUES(granted_by), 
    granted_at = VALUES(granted_at),
    active = VALUES(active)
    ]]
    
    return SafeExecute(query, {data.identifier, data.player_name, data.permission_level, data.granted_by, data.granted_at, data.active}, callback)
end

-- Admin action logging (safe)
function Database.LogAdminAction(adminIdentifier, adminName, action, targetIdentifier, targetName, details, callback)
    if not databaseReady then
        if callback then callback(false, 'Database not ready') end
        return false
    end
    
    local data = {
        admin_identifier = adminIdentifier,
        admin_name = adminName,
        action = action,
        target_identifier = targetIdentifier,
        target_name = targetName,
        details = details,
        server_id = 1,
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    return Database.Insert('ec_admin_action_logs', data, callback)
end

-- Export functions (safe)
exports('Query', function(query, parameters, callback)
    return Database.Query(query, parameters, callback)
end)

exports('GetPlayerPermission', function(identifier, callback)
    return Database.GetPlayerPermission(identifier, callback)
end)

exports('LogAdminAction', function(adminIdentifier, adminName, action, targetIdentifier, targetName, details, callback)
    return Database.LogAdminAction(adminIdentifier, adminName, action, targetIdentifier, targetName, details, callback)
end)

-- Export query statistics
exports('GetQueryStats', function()
    return {
        total = QueryStats.totalQueries,
        avgTime = CalculateAverageQueryTime(),
        failed = QueryStats.failedQueries,
        samples = #QueryStats.queryTimes
    }
end)

-- Initialize when script loads
Database.Initialize()

-- Make available globally
_G.ECDatabase = Database

Logger.Info('✅ Database system loaded successfully')
Logger.Info('💾 Safe database operations with timeout protection active')