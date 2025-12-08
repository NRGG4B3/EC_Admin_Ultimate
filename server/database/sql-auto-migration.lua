--[[
    EC Admin Ultimate - SQL Auto-Migration System
    Automatically installs all SQL files from server/ folder on resource start
    
    Features:
    - Scans server/ folder for all .sql files
    - Executes them in proper order
    - Tracks executed migrations to avoid duplicates
    - Handles errors gracefully
    - Logs all operations
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[SQL Auto-Migration] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Migration tracking table name
local MIGRATION_TABLE = 'ec_sql_migrations'

-- SQL files execution order (dependencies first)
local SQL_EXECUTION_ORDER = {
    'admin_profile.sql',      -- Admin profiles (base tables)
    'player_database.sql',     -- Player database (base tables)
    'player_profile.sql',      -- Player profiles (depends on player_database)
    'quick_actions.sql',       -- Quick actions logging
    'dashboard.sql',           -- Dashboard metrics
    'vehicles.sql',            -- Vehicle management
    'server_monitor.sql',      -- Server monitoring
    'economy_global_tools.sql', -- Economy & global tools (depends on others)
    'jobs_gangs.sql',          -- Jobs & gangs management (depends on player_database)
    'inventory.sql',           -- Inventory management (depends on player_database)
    'housing.sql',             -- Housing management (depends on player_database)
    'moderation.sql',          -- Moderation management (base tables)
    'anticheat.sql',           -- Anticheat & AI detection (base tables)
    'system_management.sql',  -- System management (base tables)
    'community.sql',           -- Community management (base tables)
    'whitelist.sql',          -- Whitelist management (base tables)
    'settings.sql'            -- Settings management (base tables)
}

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Log message
local function log(message, level)
    level = level or 'info'
    local prefix = '^2[SQL Auto-Migration]^7'
    if level == 'error' then
        prefix = '^1[SQL Auto-Migration] ERROR^7'
    elseif level == 'warn' then
        prefix = '^3[SQL Auto-Migration] WARN^7'
    end
    print(string.format('%s %s^0', prefix, message))
end

-- Helper: Create migration tracking table
local function createMigrationTable()
    local query = string.format([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `file_name` VARCHAR(255) UNIQUE NOT NULL,
            `executed_at` BIGINT NOT NULL,
            `execution_time_ms` INT DEFAULT 0,
            `success` TINYINT(1) DEFAULT 1,
            `error_message` TEXT,
            `checksum` VARCHAR(64),
            INDEX `idx_file_name` (`file_name`),
            INDEX `idx_executed_at` (`executed_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]], MIGRATION_TABLE)
    
    local success, err = pcall(function()
        MySQL.query.await(query, {})
    end)
    
    if not success then
        log('Failed to create migration tracking table: ' .. tostring(err), 'error')
        return false
    end
    
    return true
end

-- Helper: Check if migration already executed
local function isMigrationExecuted(fileName)
    local result = MySQL.query.await(
        string.format('SELECT success FROM %s WHERE file_name = ?', MIGRATION_TABLE),
        {fileName}
    )
    
    if result and result[1] and result[1].success == 1 then
        return true
    end
    
    return false
end

-- Helper: Calculate file checksum (simple hash)
local function calculateChecksum(content)
    local hash = 0
    for i = 1, #content do
        hash = ((hash * 31) + string.byte(content, i)) % 2147483647
    end
    return tostring(hash)
end

-- Helper: Read SQL file (using FiveM's LoadResourceFile)
local function readSQLFile(fileName)
    local resourceName = GetCurrentResourceName()
    local filePath = 'server/' .. fileName
    
    local content = LoadResourceFile(resourceName, filePath)
    
    if not content or content == '' then
        return nil, 'File not found or empty: ' .. filePath
    end
    
    return content, nil
end

-- Helper: Execute SQL statements
local function executeSQLStatements(sqlContent, fileName)
    local startTime = os.clock()
    
    -- Split SQL into individual statements
    local statements = {}
    local currentStatement = ''
    local inMultiLineComment = false
    
    for line in sqlContent:gmatch('[^\r\n]+') do
        -- Handle multi-line comments
        if line:match('/%*') then
            inMultiLineComment = true
        end
        if line:match('%*/') then
            inMultiLineComment = false
            goto continue
        end
        if inMultiLineComment then
            goto continue
        end
        
        -- Skip single-line comments
        if line:match('^%s*%-%-') then
            goto continue
        end
        
        -- Trim whitespace
        line = line:match('^%s*(.-)%s*$')
        
        if line ~= '' then
            currentStatement = currentStatement .. line .. ' '
            
            -- Check if statement is complete (ends with semicolon)
            if line:match(';%s*$') then
                local trimmed = currentStatement:match('^%s*(.-)%s*$')
                if trimmed and trimmed ~= '' then
                    table.insert(statements, trimmed)
                end
                currentStatement = ''
            end
        end
        
        ::continue::
    end
    
    -- Execute each statement
    local executed = 0
    local errors = {}
    
    for i, statement in ipairs(statements) do
        if statement and statement ~= '' then
            local success, err = pcall(function()
                MySQL.query.await(statement, {})
            end)
            
            if success then
                executed = executed + 1
            else
                local errorMsg = string.format('Statement %d: %s', i, tostring(err))
                table.insert(errors, errorMsg)
                log(string.format('Error in statement %d: %s', i, string.sub(statement, 1, 100)), 'warn')
            end
        end
    end
    
    local executionTime = math.floor((os.clock() - startTime) * 1000)
    
    return executed, errors, executionTime
end

-- Helper: Record migration execution
local function recordMigration(fileName, success, executionTime, errorMessage, checksum)
    local query = string.format([[
        INSERT INTO %s (file_name, executed_at, execution_time_ms, success, error_message, checksum)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            executed_at = VALUES(executed_at),
            execution_time_ms = VALUES(execution_time_ms),
            success = VALUES(success),
            error_message = VALUES(error_message),
            checksum = VALUES(checksum)
    ]], MIGRATION_TABLE)
    
    MySQL.insert.await(query, {
        fileName,
        getCurrentTimestamp(),
        executionTime,
        success and 1 or 0,
        errorMessage or nil,
        checksum or nil
    })
end

-- Helper: Process SQL file
local function processSQLFile(fileName)
    -- Check if already executed
    if isMigrationExecuted(fileName) then
        log(string.format('Skipping %s (already executed)', fileName), 'info')
        return true
    end
    
    log(string.format('Executing %s...', fileName), 'info')
    
    -- Read file
    local sqlContent, err = readSQLFile(fileName)
    if not sqlContent then
        log(string.format('Failed to read %s: %s', fileName, err), 'error')
        recordMigration(fileName, false, 0, err, nil)
        return false
    end
    
    -- Calculate checksum
    local checksum = calculateChecksum(sqlContent)
    
    -- Execute SQL
    local executed, errors, executionTime = executeSQLStatements(sqlContent, fileName)
    
    if #errors > 0 then
        local errorMsg = table.concat(errors, '; ')
        log(string.format('Completed %s with %d errors: %s', fileName, #errors, errorMsg), 'warn')
        recordMigration(fileName, false, executionTime, errorMsg, checksum)
        return false
    else
        log(string.format('✓ %s executed successfully (%d statements, %dms)', fileName, executed, executionTime), 'info')
        recordMigration(fileName, true, executionTime, nil, checksum)
        return true
    end
end

-- Main migration function
local function runMigrations()
    log('Starting SQL auto-migration system...', 'info')
    
    -- Create migration tracking table
    if not createMigrationTable() then
        log('Failed to initialize migration system', 'error')
        return
    end
    
    -- Process SQL files in order
    local successCount = 0
    local failCount = 0
    
    for _, fileName in ipairs(SQL_EXECUTION_ORDER) do
        if processSQLFile(fileName) then
            successCount = successCount + 1
        else
            failCount = failCount + 1
        end
    end
    
    -- Summary
    log(string.format('Migration complete: %d succeeded, %d failed', successCount, failCount), 'info')
    
    if failCount == 0 then
        log('All SQL files installed successfully!', 'info')
    else
        log('Some SQL files failed to install. Check logs above.', 'warn')
    end
end

-- Run migrations on resource start
CreateThread(function()
    -- Wait for MySQL to be ready
    Wait(2000)
    
    -- Run migrations
    runMigrations()
end)

print("^2[SQL Auto-Migration]^7 System loaded - Will auto-install SQL files on resource start^0")

