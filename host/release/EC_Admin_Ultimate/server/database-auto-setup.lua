--[[
    EC Admin Ultimate - AUTOMATIC Database Setup
    Loads SQL files automatically on startup
    ZERO manual SQL required!
]]

-- Simple logger replacement (no external dependencies)
local Logger = {
    System = function(msg) print('[EC Admin DB] ' .. msg) end,
    Debug = function(msg) print('[EC Admin DB] ' .. msg) end,
    Error = function(msg) print('^1[EC Admin DB ERROR]^7 ' .. msg) end,
    Success = function(msg) print('^2[EC Admin DB SUCCESS]^7 ' .. msg) end,
    Warning = function(msg) print('^3[EC Admin DB WARNING]^7 ' .. msg) end,
    Info = function(msg) print('[EC Admin DB] ' .. msg) end
}

local DB_AUTO = {}

-- SQL Files to load (ONLY 2 FILES - Customer and Host)
DB_AUTO.SQL_FILES = {
    customer = 'ec_admin_customer.sql',  -- All customer-side tables
    -- host = 'host/ec_admin_host.sql'   -- Uncomment if this is a host installation
}

-- Auto-migrate missing columns for action logs
function DB_AUTO.MigrateActionLogsTable()
    local checkColumn = MySQL.query.await([[SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ec_admin_action_logs' AND COLUMN_NAME = 'metadata']], {})
    if not checkColumn or not checkColumn[1] then
        Logger.System('🔄 Migrating ec_admin_action_logs: Adding missing metadata column...')
        local success, err = pcall(function()
            MySQL.query.await([[ALTER TABLE ec_admin_action_logs ADD COLUMN metadata TEXT DEFAULT NULL]], {})
        end)
        if success then
            Logger.Success('✅ metadata column added to ec_admin_action_logs')
        else
            Logger.Error('❌ Failed to add metadata column: ' .. tostring(err))
        end
    end
end

-- Load SQL file content
function DB_AUTO.LoadSQLFile(filename)
    local resourceName = GetCurrentResourceName()
    local filePath = GetResourcePath(resourceName) .. '/' .. filename
    
    local file = io.open(filePath, 'r')
    if not file then
        Logger.Error('❌ Could not find SQL file: ' .. filename)
        return nil
    end
    
    local content = file:read('*all')
    file:close()
    
    return content
end

-- Execute SQL file with statement splitting
function DB_AUTO.ExecuteSQLFile(filename)
    Logger.System('📄 Loading SQL file: ' .. filename)
    
    local content = DB_AUTO.LoadSQLFile(filename)
    if not content then
        return false, 'File not found'
    end
    
    -- Split SQL statements by semicolons (but ignore inside strings/comments)
    local statements = {}
    local currentStatement = ''
    local inComment = false
    local inString = false
    local stringChar = nil
    
    for i = 1, #content do
        local char = content:sub(i, i)
        local nextChar = content:sub(i + 1, i + 1)
        local prevChar = content:sub(i - 1, i - 1)
        
        -- Handle comments
        if char == '-' and nextChar == '-' and not inString then
            inComment = true
        elseif char == '\n' and inComment then
            inComment = false
            currentStatement = currentStatement .. char
            goto continue
        end
        
        if inComment then
            currentStatement = currentStatement .. char
            goto continue
        end
        
        -- Handle strings
        if (char == '"' or char == "'") and prevChar ~= '\\' and not inString then
            inString = true
            stringChar = char
        elseif char == stringChar and prevChar ~= '\\' and inString then
            inString = false
            stringChar = nil
        end
        
        -- Split on semicolon
        if char == ';' and not inString and not inComment then
            table.insert(statements, currentStatement)
            currentStatement = ''
        else
            currentStatement = currentStatement .. char
        end
        
        ::continue::
    end
    
    -- Add last statement if exists
    if #currentStatement:gsub('%s', '') > 0 then
        table.insert(statements, currentStatement)
    end
    
    -- Execute statements
    local successCount = 0
    local errorCount = 0
    local errors = {}
    
    for i, statement in ipairs(statements) do
        -- Skip empty statements and comments
        local trimmed = statement:gsub('^%s+', ''):gsub('%s+$', '')
        if #trimmed > 0 and not trimmed:match('^%-%-') and not trimmed:match('^SELECT') then
            local success, err = pcall(function()
                MySQL.query.await(statement, {})
            end)
            
            if success then
                successCount = successCount + 1
            else
                errorCount = errorCount + 1
                table.insert(errors, { statement = trimmed:sub(1, 100) .. '...', error = tostring(err) })
            end
        end
    end
    
    Logger.System(string.format('   ✅ Executed %d statements successfully', successCount))
    if errorCount > 0 then
        Logger.Error(string.format('   ❌ %d statements failed', errorCount))
        for _, err in ipairs(errors) do
            Logger.Error('      ' .. err.error)
        end
    end
    
    return errorCount == 0, errors
end

-- Initialize database from SQL files
function DB_AUTO.InitializeDatabase()
    Logger.System('🔍 Initializing database from SQL files...')
    
    local totalSuccess = 0
    local totalFailed = 0
    
    for dbType, filename in pairs(DB_AUTO.SQL_FILES) do
        Logger.System('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        Logger.System(string.format('Loading %s database: %s', dbType, filename))
        
        local success, err = DB_AUTO.ExecuteSQLFile(filename)
        if success then
            totalSuccess = totalSuccess + 1
            Logger.Success('✅ ' .. dbType .. ' database loaded successfully!')
        else
            totalFailed = totalFailed + 1
            Logger.Error('❌ ' .. dbType .. ' database failed to load')
        end
    end
    
    return totalSuccess, totalFailed
end

-- Initialize on EVERY startup (loads SQL files if tables don't exist)
CreateThread(function()
    Wait(5000) -- Wait for oxmysql to load
    
    if not MySQL then
        Logger.Error('❌ MySQL not detected - cannot initialize database')
        Logger.Error('   Make sure oxmysql is started BEFORE EC_Admin_Ultimate')
        return
    end
    
    Logger.System('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    Logger.System('🗄️  EC ADMIN ULTIMATE - DATABASE AUTO-SETUP')
    Logger.System('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    
    -- Check if database is already initialized
    local result = MySQL.query.await([[
        SELECT COUNT(*) as count 
        FROM information_schema.tables 
        WHERE table_schema = DATABASE() 
        AND table_name = 'ec_admin_permissions'
    ]], {})
    
    local dbInitialized = result and result[1] and result[1].count > 0
    
    if dbInitialized then
        Logger.Success('✅ Database already initialized - All tables exist!')
    else
        Logger.System('📦 First-time setup detected - Installing database schema...')
        Logger.System('')
        
        local success, failed = DB_AUTO.InitializeDatabase()
        
        Logger.System('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
        if failed == 0 then
            Logger.Success('🎉 Database installation complete!')
            Logger.Success(string.format('   ✅ %d SQL file(s) loaded successfully', success))
        else
            Logger.Error('⚠️  Database installation completed with errors')
            Logger.Error(string.format('   ✅ Success: %d | ❌ Failed: %d', success, failed))
        end
    end

    -- Always run migration for missing columns
    DB_AUTO.MigrateActionLogsTable()
    
    Logger.System('')
    Logger.System('🚀 EC Admin Ultimate ready!')
    Logger.System('   Press F2 in-game to open admin panel')
    Logger.System('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
end)

return DB_AUTO
