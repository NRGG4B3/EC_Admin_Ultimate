-- ============================================================================
-- EC ADMIN ULTIMATE - AUTO SQL MIGRATION
-- Automatically imports SQL schemas on startup
-- ============================================================================

Logger.Info('🔄 Starting SQL Auto-Migration System...')

local function ImportSQLFile(filePath)
    local file = LoadResourceFile(GetCurrentResourceName(), filePath)
    if not file then
        Logger.Warn('Could not read SQL file: ' .. filePath)
        return false
    end
    
    -- Split SQL file into individual statements
    local statements = {}
    local currentStatement = ''
    
    for line in file:gmatch("[^\n]+") do
        -- Skip comments
        if not line:match("^%s*%-%-") and not line:match("^%s*$") then
            currentStatement = currentStatement .. ' ' .. line
            
            -- Check if statement ends
            if line:match(";%s*$") then
                table.insert(statements, currentStatement:match("^%s*(.-)%s*$"))
                currentStatement = ''
            end
        end
    end
    
    -- Execute all statements
    local executed = 0
    for _, statement in ipairs(statements) do
        if statement and statement ~= '' then
            MySQL.query(statement, {}, function(result)
                executed = executed + 1
            end)
        end
    end
    
    Logger.Info(string.format('✅ Executed %d SQL statements from %s', executed, filePath))
    return true
end

-- Auto-run SQL migrations on startup
AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Wait(2000) -- Wait for oxmysql to initialize
        
        Logger.Info('📊 Auto-migrating SQL schemas...')
        
        -- Import main SQL file
        ImportSQLFile('sql/ec_admin_ultimate.sql')
        
        Logger.Info('✅ SQL Auto-Migration Complete')
    end
end)
