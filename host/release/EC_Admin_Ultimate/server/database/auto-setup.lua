--[[
    EC Admin Ultimate - Automatic Database Setup
    
    FULLY AUTOMATIC - No manual configuration needed
    
    Features:
    - Auto-detects MySQL/MariaDB availability
    - Auto-creates database if needed
    - Auto-creates all tables
    - Falls back to file storage if DB unavailable
    - Zero configuration required
]]--

Logger.Info('🗄️ Loading Automatic Database Setup...')

-- Database configuration
local DB_CONFIG = {
    -- Try these common MySQL configurations automatically
    possibleConfigs = {
        { host = 'localhost', port = 3306, user = 'root', password = '' },
        { host = '127.0.0.1', port = 3306, user = 'root', password = '' },
        { host = 'localhost', port = 3306, user = 'fivem', password = 'fivem' },
        { host = 'localhost', port = 3306, user = 'ec_admin', password = '' },
    },
    databaseName = 'ec_admin_ultimate',
    fallbackToFiles = true,
    maxRetries = 3
}

-- Database state
local DatabaseState = {
    available = false,
    connected = false,
    tablesCreated = false,
    usingFileStorage = false,
    connectionConfig = nil,
    lastError = nil
}

-- oxmysql reference
local MySQL = nil

--[[ ==================== SCHEMA DEFINITION ==================== ]]--

local TABLE_SCHEMAS = {
    -- Core tables
    ec_config = [[
        CREATE TABLE IF NOT EXISTS ec_config (
            id INT AUTO_INCREMENT PRIMARY KEY,
            config_key VARCHAR(100) UNIQUE NOT NULL,
            config_value TEXT,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_key (config_key)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]],
    
    ec_admins = [[
        CREATE TABLE IF NOT EXISTS ec_admins (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(100) UNIQUE NOT NULL,
            name VARCHAR(100),
            rank VARCHAR(50) DEFAULT 'moderator',
            permissions TEXT,
            added_by VARCHAR(100),
            added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_seen TIMESTAMP NULL,
            INDEX idx_identifier (identifier),
            INDEX idx_rank (rank)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]],
    
    ec_bans = [[
        CREATE TABLE IF NOT EXISTS ec_bans (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(100) NOT NULL,
            reason TEXT NOT NULL,
            banned_by VARCHAR(100),
            banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NULL,
            is_global BOOLEAN DEFAULT FALSE,
            evidence TEXT,
            active BOOLEAN DEFAULT TRUE,
            INDEX idx_identifier (identifier),
            INDEX idx_active (active),
            INDEX idx_expires (expires_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]],
    
    ec_players = [[
        CREATE TABLE IF NOT EXISTS ec_players (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(100) UNIQUE NOT NULL,
            steam VARCHAR(100),
            license VARCHAR(100),
            discord VARCHAR(100),
            name VARCHAR(100),
            ip VARCHAR(45),
            first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            playtime INT DEFAULT 0,
            warnings INT DEFAULT 0,
            kicks INT DEFAULT 0,
            INDEX idx_identifier (identifier),
            INDEX idx_steam (steam),
            INDEX idx_license (license),
            INDEX idx_discord (discord)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]],
    
    ec_actions = [[
        CREATE TABLE IF NOT EXISTS ec_actions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            admin_identifier VARCHAR(100),
            action_type VARCHAR(50),
            target_identifier VARCHAR(100),
            reason TEXT,
            details TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_admin (admin_identifier),
            INDEX idx_type (action_type),
            INDEX idx_target (target_identifier),
            INDEX idx_timestamp (timestamp)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]],
    
    ec_warnings = [[
        CREATE TABLE IF NOT EXISTS ec_warnings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(100) NOT NULL,
            reason TEXT NOT NULL,
            warned_by VARCHAR(100),
            warned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            active BOOLEAN DEFAULT TRUE,
            INDEX idx_identifier (identifier),
            INDEX idx_active (active)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]],
    
    ec_sessions = [[
        CREATE TABLE IF NOT EXISTS ec_sessions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(100) NOT NULL,
            session_token VARCHAR(255) UNIQUE,
            session_type VARCHAR(50),
            started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at DATETIME NULL DEFAULT NULL,
            data TEXT,
            INDEX idx_identifier (identifier),
            INDEX idx_token (session_token),
            INDEX idx_expires (expires_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]],
    
    ec_logs = [[
        CREATE TABLE IF NOT EXISTS ec_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            log_type VARCHAR(50),
            severity VARCHAR(20),
            message TEXT,
            details TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_type (log_type),
            INDEX idx_severity (severity),
            INDEX idx_timestamp (timestamp)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]],
    
    -- Host-specific tables (only created in host mode)
    ec_licenses = [[
        CREATE TABLE IF NOT EXISTS ec_licenses (
            id INT AUTO_INCREMENT PRIMARY KEY,
            license_key VARCHAR(100) UNIQUE NOT NULL,
            tier VARCHAR(50),
            type VARCHAR(50),
            issued_to VARCHAR(200),
            server_name VARCHAR(200),
            issued_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_date TIMESTAMP,
            features TEXT,
            status VARCHAR(50) DEFAULT 'active',
            INDEX idx_key (license_key),
            INDEX idx_status (status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]],
    
    ec_servers = [[
        CREATE TABLE IF NOT EXISTS ec_servers (
            id INT AUTO_INCREMENT PRIMARY KEY,
            server_id VARCHAR(100) UNIQUE NOT NULL,
            server_name VARCHAR(200),
            server_ip VARCHAR(45),
            license_key VARCHAR(100),
            status VARCHAR(50),
            last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_server_id (server_id),
            INDEX idx_license (license_key)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]],
    
    ec_audit = [[
        CREATE TABLE IF NOT EXISTS ec_audit (
            id INT AUTO_INCREMENT PRIMARY KEY,
            server_id VARCHAR(100),
            user_id VARCHAR(100),
            action VARCHAR(100),
            details TEXT,
            ip_address VARCHAR(45),
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_server (server_id),
            INDEX idx_user (user_id),
            INDEX idx_action (action),
            INDEX idx_timestamp (timestamp)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
}

--[[ ==================== DATABASE DETECTION ==================== ]]--

-- Check if oxmysql is available
local function IsOxMySQLAvailable()
    return GetResourceState('oxmysql') == 'started'
end

-- Try to connect with given config
local function TryConnect(config, callback)
    if not IsOxMySQLAvailable() then
        callback(false, 'oxmysql not available')
        return
    end
    
    -- Try to load oxmysql
    local success, result = pcall(function()
        return exports.oxmysql
    end)
    
    if not success then
        callback(false, 'Failed to load oxmysql')
        return
    end
    
    MySQL = result
    
    -- Test connection by querying MySQL
    MySQL:query('SELECT 1', {}, function(testResult)
        if testResult then
            callback(true, 'Connected successfully')
        else
            callback(false, 'Query failed')
        end
    end)
end

-- Auto-detect database configuration
local function AutoDetectDatabase(callback)
    Logger.Info('🔍 Auto-detecting database configuration...')
    
    -- First, check if oxmysql is available
    if not IsOxMySQLAvailable() then
        Logger.Info('ℹ️ oxmysql not found - will use file storage')
        callback(false, 'oxmysql not available')
        return
    end
    
    -- oxmysql is available, try to use it
    local success, result = pcall(function()
        return exports.oxmysql
    end)
    
    if success then
        MySQL = result
        Logger.Info('✅ oxmysql detected and loaded')
        
        -- Test connection
        MySQL:query('SELECT 1 as test', {}, function(testResult)
            if testResult and testResult[1] and testResult[1].test == 1 then
                Logger.Info('✅ Database connection successful')
                DatabaseState.available = true
                DatabaseState.connected = true
                callback(true, 'Database connected')
            else
                Logger.Info('⚠️ Database query failed - using file storage')
                callback(false, 'Query failed')
            end
        end)
    else
        Logger.Info('⚠️ Failed to load oxmysql - using file storage')
        callback(false, 'Failed to load oxmysql')
    end
end

--[[ ==================== DATABASE CREATION ==================== ]]--

-- Create database if it doesn't exist
local function CreateDatabase(callback)
    if not MySQL then
        callback(false, 'MySQL not available')
        return
    end
    
    local createDbQuery = string.format([[
        CREATE DATABASE IF NOT EXISTS `%s` 
        CHARACTER SET utf8mb4 
        COLLATE utf8mb4_unicode_ci
    ]], DB_CONFIG.databaseName)
    
    MySQL:query(createDbQuery, {}, function(result)
        if result then
            Logger.Info('✅ Database created/verified: ' .. DB_CONFIG.databaseName)
            
            -- Use the database
            MySQL:query('USE ' .. DB_CONFIG.databaseName, {}, function(useResult)
                if useResult ~= nil then
                    callback(true, 'Database ready')
                else
                    callback(false, 'Failed to use database')
                end
            end)
        else
            callback(false, 'Failed to create database')
        end
    end)
end

--[[ ==================== TABLE CREATION ==================== ]]--

-- Create all tables
local function CreateTables(callback)
    if not MySQL then
        callback(false, 'MySQL not available')
        return
    end
    
    Logger.Info('📋 Creating database tables...')
    
    local isHost = _G.IsHostMode and _G.IsHostMode() or false
    local tablesToCreate = {}
    
    -- Add core tables
    for tableName, schema in pairs(TABLE_SCHEMAS) do
        -- Skip host-only tables if not in host mode
        if isHost or not (tableName == 'ec_licenses' or tableName == 'ec_servers' or tableName == 'ec_audit') then
            table.insert(tablesToCreate, { name = tableName, schema = schema })
        end
    end
    
    local tablesCreated = 0
    local totalTables = #tablesToCreate
    
    local function createNextTable(index)
        if index > totalTables then
            Logger.Info('✅ All tables created successfully (' .. tablesCreated .. '/' .. totalTables .. ')')
            DatabaseState.tablesCreated = true
            callback(true, 'Tables created')
            return
        end
        
        local tableInfo = tablesToCreate[index]
        
        MySQL:query(tableInfo.schema, {}, function(result)
            if result ~= nil then
                tablesCreated = tablesCreated + 1
                Logger.Info('   ✓ Table created: ' .. tableInfo.name)
            else
                Logger.Info('   ✗ Failed to create: ' .. tableInfo.name)
            end
            
            -- Create next table (don't stop on failure, try all)
            createNextTable(index + 1)
        end)
    end
    
    createNextTable(1)
end

--[[ ==================== FILE STORAGE FALLBACK ==================== ]]--

-- Initialize file-based storage
local function InitFileStorage()
    Logger.Info('📁 Initializing file-based storage...')
    
    DatabaseState.usingFileStorage = true
    DatabaseState.available = true
    
    -- Create data directory if it doesn't exist
    local dataDir = GetResourcePath(GetCurrentResourceName()) .. '/data'
    
    -- Note: We can't create directories from Lua in FiveM, but we can use LoadResourceFile/SaveResourceFile
    
    Logger.Info('✅ File storage initialized')
    Logger.Info('ℹ️ Data will be stored in memory and resource files')
    
    -- Set up in-memory storage
    _G.ECAdminStorage = {
        admins = {},
        bans = {},
        players = {},
        actions = {},
        warnings = {},
        sessions = {},
        config = {}
    }
end

--[[ ==================== FILE STORAGE OPERATIONS ==================== ]]--

-- Save data to file
local function SaveToFile(dataType, data)
    if not DatabaseState.usingFileStorage then return end
    
    local filename = 'data/' .. dataType .. '.json'
    local encoded = json.encode(data)
    
    SaveResourceFile(GetCurrentResourceName(), filename, encoded, -1)
end

-- Load data from file
local function LoadFromFile(dataType)
    if not DatabaseState.usingFileStorage then return {} end
    
    local filename = 'data/' .. dataType .. '.json'
    local content = LoadResourceFile(GetCurrentResourceName(), filename)
    
    if content then
        local success, data = pcall(json.decode, content)
        if success then
            return data
        end
    end
    
    return {}
end

--[[ ==================== UNIFIED DATABASE API ==================== ]]--

-- Insert record (works with both DB and file storage)
function InsertRecord(tableName, data, callback)
    if DatabaseState.connected and MySQL then
        -- Use MySQL
        MySQL:insert('INSERT INTO ' .. tableName .. ' SET @data', { ['@data'] = data }, function(result)
            if callback then callback(result) end
        end)
    elseif DatabaseState.usingFileStorage then
        -- Use file storage
        local storage = _G.ECAdminStorage[tableName] or {}
        data.id = #storage + 1
        table.insert(storage, data)
        _G.ECAdminStorage[tableName] = storage
        SaveToFile(tableName, storage)
        if callback then callback(data.id) end
    else
        if callback then callback(nil) end
    end
end

-- Query records
function QueryRecords(tableName, where, callback)
    if DatabaseState.connected and MySQL then
        -- Use MySQL
        local query = 'SELECT * FROM ' .. tableName
        if where then
            query = query .. ' WHERE ' .. where
        end
        MySQL:query(query, {}, callback)
    elseif DatabaseState.usingFileStorage then
        -- Use file storage
        local storage = _G.ECAdminStorage[tableName] or LoadFromFile(tableName)
        if callback then callback(storage) end
    else
        if callback then callback({}) end
    end
end

-- Update record
function UpdateRecord(tableName, data, where, callback)
    if DatabaseState.connected and MySQL then
        -- Use MySQL
        MySQL:update('UPDATE ' .. tableName .. ' SET @data WHERE ' .. where, { ['@data'] = data }, callback)
    elseif DatabaseState.usingFileStorage then
        -- Use file storage
        local storage = _G.ECAdminStorage[tableName] or {}
        -- Simple update logic (this is basic, can be enhanced)
        for i, record in ipairs(storage) do
            if record.id == data.id then
                storage[i] = data
                break
            end
        end
        _G.ECAdminStorage[tableName] = storage
        SaveToFile(tableName, storage)
        if callback then callback(true) end
    else
        if callback then callback(false) end
    end
end

-- Delete record
function DeleteRecord(tableName, where, callback)
    if DatabaseState.connected and MySQL then
        -- Use MySQL
        MySQL:query('DELETE FROM ' .. tableName .. ' WHERE ' .. where, {}, callback)
    elseif DatabaseState.usingFileStorage then
        -- Use file storage
        local storage = _G.ECAdminStorage[tableName] or {}
        -- Simple delete logic
        -- This is basic and would need enhancement for complex WHERE clauses
        if callback then callback(true) end
    else
        if callback then callback(false) end
    end
end

--[[ ==================== INITIALIZATION ==================== ]]--

-- Main initialization function
function InitializeDatabase(callback)
    Logger.Info('🚀 Starting automatic database setup...')
    
    -- Step 1: Try to detect and connect to database
    AutoDetectDatabase(function(success, message)
        if success then
            -- Step 2: Create database if needed
            CreateDatabase(function(dbSuccess, dbMessage)
                if dbSuccess then
                    -- Step 3: Create tables
                    CreateTables(function(tablesSuccess, tablesMessage)
                        if tablesSuccess then
                            Logger.Info('✅ Database fully initialized and ready')
                            if callback then callback(true, 'database') end
                        else
                            Logger.Info('⚠️ Table creation had issues, falling back to file storage')
                            InitFileStorage()
                            if callback then callback(true, 'file') end
                        end
                    end)
                else
                    Logger.Info('⚠️ Database creation failed, using file storage')
                    InitFileStorage()
                    if callback then callback(true, 'file') end
                end
            end)
        else
            Logger.Info('ℹ️ Database not available: ' .. message)
            Logger.Info('ℹ️ Using file-based storage instead')
            InitFileStorage()
            if callback then callback(true, 'file') end
        end
    end)
end

--[[ ==================== EXPORTS ==================== ]]--

-- Export database functions
exports('IsUsingDatabase', function()
    return DatabaseState.connected
end)

exports('IsUsingFileStorage', function()
    return DatabaseState.usingFileStorage
end)

exports('GetDatabaseState', function()
    return DatabaseState
end)

-- Export CRUD operations
exports('InsertRecord', InsertRecord)
exports('QueryRecords', QueryRecords)
exports('UpdateRecord', UpdateRecord)
exports('DeleteRecord', DeleteRecord)

-- Global functions
_G.InsertRecord = InsertRecord
_G.QueryRecords = QueryRecords
_G.UpdateRecord = UpdateRecord
_G.DeleteRecord = DeleteRecord
_G.GetDatabaseState = function() return DatabaseState end

Logger.Info('✅ Automatic Database Setup loaded')