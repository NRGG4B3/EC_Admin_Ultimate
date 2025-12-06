-- ============================================================================
-- EC ADMIN ULTIMATE - AUTOMATIC SQL MIGRATION SYSTEM
-- ============================================================================
-- Automatically detects and runs SQL files on server startup
-- Ensures database is always up-to-date with the latest schema
-- ============================================================================

Logger.Info('🔄 Auto-Migration System - Starting...')

local AutoMigrate = {}
AutoMigrate.CompletedMigrations = {}
AutoMigrate.MigrationHistory = {}

-- ============================================================================
-- CHECK IF MIGRATION TRACKING TABLE EXISTS
-- ============================================================================
local function EnsureMigrationTable()
    local createTableQuery = [[
        CREATE TABLE IF NOT EXISTS ec_admin_migrations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            filename VARCHAR(255) NOT NULL UNIQUE,
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            success BOOLEAN DEFAULT TRUE,
            error_message TEXT NULL,
            INDEX idx_filename (filename)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    
    MySQL.Async.execute(createTableQuery, {}, function(result)
        if result then
            Logger.Success('✅ Migration tracking table verified')
            AutoMigrate.LoadMigrationHistory()
        else
            Logger.Error('❌ Failed to create migration tracking table')
        end
    end)
end

-- ============================================================================
-- LOAD MIGRATION HISTORY FROM DATABASE
-- ============================================================================
function AutoMigrate.LoadMigrationHistory()
    MySQL.Async.fetchAll('SELECT filename, executed_at FROM ec_admin_migrations WHERE success = 1', {}, function(results)
        if results then
            for _, migration in ipairs(results) do
                AutoMigrate.CompletedMigrations[migration.filename] = true
            end
            Logger.Success(string.format('✅ Loaded migration history: %d completed migrations', #results))
            AutoMigrate.ScanAndRunMigrations()
        else
            Logger.Warn('⚠️ No migration history found - first run?')
            AutoMigrate.ScanAndRunMigrations()
        end
    end)
end

-- ============================================================================
-- SCAN SQL DIRECTORY AND RUN PENDING MIGRATIONS
-- ============================================================================
function AutoMigrate.ScanAndRunMigrations()
    -- Main SQL file (single consolidated database schema)
    local sqlFiles = {
        'sql/ec_admin_ultimate.sql',  -- ALL tables in one file (REQUIRED)
    }
    
    -- Scan migrations directory
    local migrationDir = 'sql/migrations/'
    local migrationFiles = {}
    
    -- Helper function to load migration files from directory
    local function ScanMigrationDirectory()
        -- Try to load numbered migration files
        for i = 1, 100 do  -- Support up to 100 migrations
            local migrationPath = string.format('%s%03d_*.sql', migrationDir, i)
            -- Since we can't directly scan directories, we'll check common patterns
            for attempt = 1, 50 do
                local testPath = string.format('%s%03d_%s.sql', migrationDir, i, tostring(attempt))
                local content = LoadResourceFile(GetCurrentResourceName(), testPath)
                if content and content ~= '' then
                    table.insert(migrationFiles, testPath)
                    break
                end
            end
        end
        
        -- Also try direct migration files if they exist
        local standardMigrations = {
            'sql/migrations/001_add_category_to_action_logs.sql',
            'sql/migrations/002_add_admin_abuse_columns.sql',
            'sql/migrations/003_add_ai_analytics_tables.sql',
        }
        
        for _, migration in ipairs(standardMigrations) do
            local content = LoadResourceFile(GetCurrentResourceName(), migration)
            if content and content ~= '' then
                local alreadyAdded = false
                for _, added in ipairs(migrationFiles) do
                    if added == migration then
                        alreadyAdded = true
                        break
                    end
                end
                if not alreadyAdded then
                    table.insert(migrationFiles, migration)
                end
            end
        end
        
        return migrationFiles
    end
    
    -- Add scanned migration files
    for _, migrationFile in ipairs(ScanMigrationDirectory()) do
        table.insert(sqlFiles, migrationFile)
    end
    
    local pendingMigrations = {}
    
    -- Check which files haven't been run yet
    for _, sqlFile in ipairs(sqlFiles) do
        local filename = sqlFile:match('([^/]+)$')  -- Extract filename
        
        -- Verify file exists before adding to pending
        local content = LoadResourceFile(GetCurrentResourceName(), sqlFile)
        if not content or content == '' then
            Logger.Warn(string.format('⚠️ SQL file not found: %s', sqlFile))
        else
            if not AutoMigrate.CompletedMigrations[filename] then
                Logger.Info(string.format('🔍 Pending migration found: %s (%.1f KB)', filename, #content / 1024))
                table.insert(pendingMigrations, { path = sqlFile, filename = filename })
            else
                Logger.Debug(string.format('✅ Migration already completed: %s', filename))
            end
        end
    end
    
    if #pendingMigrations == 0 then
        Logger.Success('✅ Database is up-to-date - no pending migrations')
        return
    end
    
    Logger.Info(string.format('🔄 Running %d pending migrations...', #pendingMigrations))
    
    -- Run migrations sequentially
    AutoMigrate.RunMigrationsBatch(pendingMigrations, 1)
end

-- ============================================================================
-- RUN MIGRATIONS IN BATCH (Recursive)
-- ============================================================================
function AutoMigrate.RunMigrationsBatch(migrations, index)
    if index > #migrations then
        Logger.Success('✅ All migrations completed successfully!')
        return
    end
    
    local migration = migrations[index]
    Logger.Info(string.format('🔄 Running migration %d/%d: %s', index, #migrations, migration.filename))
    
    -- Read SQL file content
    local sqlContent = LoadResourceFile(GetCurrentResourceName(), migration.path)
    
    if not sqlContent or sqlContent == '' then
        Logger.Error(string.format('❌ Failed to load SQL file: %s', migration.path))
        -- Record failed migration
        AutoMigrate.RecordMigration(migration.filename, false, 'File not found or empty')
        -- Continue with next migration
        AutoMigrate.RunMigrationsBatch(migrations, index + 1)
        return
    end
    
    -- Split SQL into individual statements (separated by semicolons)
    local statements = {}
    for statement in sqlContent:gmatch('[^;]+') do
        local trimmed = statement:match('^%s*(.-)%s*$')  -- Trim whitespace
        if trimmed and trimmed ~= '' and not trimmed:match('^%-%-') then  -- Skip comments
            table.insert(statements, trimmed)
        end
    end
    
    Logger.Debug(string.format('📝 Executing %d SQL statements from %s', #statements, migration.filename))
    
    -- Execute all statements
    AutoMigrate.ExecuteStatements(statements, 1, migration, function(success)
        if success then
            Logger.Success(string.format('✅ Migration completed: %s', migration.filename))
            AutoMigrate.RecordMigration(migration.filename, true, nil)
        else
            Logger.Error(string.format('❌ Migration failed: %s', migration.filename))
            AutoMigrate.RecordMigration(migration.filename, false, 'Statement execution failed')
        end
        
        -- Continue with next migration
        Wait(500)  -- Small delay between migrations
        AutoMigrate.RunMigrationsBatch(migrations, index + 1)
    end)
end

-- ============================================================================
-- EXECUTE SQL STATEMENTS RECURSIVELY (With Better Error Handling)
-- ============================================================================
function AutoMigrate.ExecuteStatements(statements, index, migration, callback)
    if index > #statements then
        callback(true)
        return
    end
    
    local statement = statements[index]
    
    -- Skip empty statements
    if not statement or statement == '' then
        AutoMigrate.ExecuteStatements(statements, index + 1, migration, callback)
        return
    end
    
    -- Execute statement with error capture
    local success = false
    pcall(function()
        MySQL.Async.execute(statement, {}, function(result)
            if result or result == 0 then
                Logger.Debug(string.format('✅ Statement %d/%d executed', index, #statements))
                success = true
                -- Continue with next statement
                AutoMigrate.ExecuteStatements(statements, index + 1, migration, callback)
            else
                Logger.Error(string.format('❌ Statement %d/%d failed', index, #statements))
                Logger.Error(string.format('Failed SQL: %s', statement:sub(1, 200)))
                callback(false)
            end
        end)
    end)
    
    -- Timeout protection (30 seconds per statement)
    CreateThread(function()
        Wait(30000)
        if not success then
            Logger.Error(string.format('⏱️ Statement %d/%d timed out after 30s', index, #statements))
            callback(false)
        end
    end)
end

-- ============================================================================
-- RECORD MIGRATION IN TRACKING TABLE
-- ============================================================================
function AutoMigrate.RecordMigration(filename, success, errorMessage)
    MySQL.Async.execute(
        'INSERT INTO ec_admin_migrations (filename, success, error_message) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE executed_at = CURRENT_TIMESTAMP, success = ?, error_message = ?',
        { filename, success, errorMessage, success, errorMessage },
        function(result)
            if result then
                if success then
                    AutoMigrate.CompletedMigrations[filename] = true
                end
                Logger.Debug(string.format('📝 Migration recorded: %s (success: %s)', filename, tostring(success)))
            else
                Logger.Error(string.format('❌ Failed to record migration: %s', filename))
            end
        end
    )
end

-- ============================================================================
-- GET MIGRATION STATUS (Check what's been run)
-- ============================================================================
function AutoMigrate.GetStatus()
    local status = {
        tracking_table_exists = true,
        completed_migrations = {},
        total_completed = 0
    }
    
    for filename, _ in pairs(AutoMigrate.CompletedMigrations) do
        table.insert(status.completed_migrations, filename)
        status.total_completed = status.total_completed + 1
    end
    
    return status
end

-- ============================================================================
-- MANUAL MIGRATION TRIGGER (Admin Command)
-- ============================================================================
RegisterCommand('ec:migrate', function(source, args, rawCommand)
    if source ~= 0 then
        Logger.Warn('Migration command can only be run from server console')
        return
    end
    
    Logger.Info('🔄 Manual migration triggered from console')
    AutoMigrate.ScanAndRunMigrations()
end, false)

-- Show migration status
RegisterCommand('ec:migrate:status', function(source, args, rawCommand)
    if source ~= 0 then
        Logger.Warn('Migration status command can only be run from server console')
        return
    end
    
    local status = AutoMigrate.GetStatus()
    Logger.Info('========================================')
    Logger.Info('📊 MIGRATION STATUS')
    Logger.Info('========================================')
    Logger.Info(string.format('✅ Completed Migrations: %d', status.total_completed))
    
    if status.total_completed > 0 then
        Logger.Info('Files:')
        for _, filename in ipairs(status.completed_migrations) do
            Logger.Info(string.format('  - %s', filename))
        end
    else
        Logger.Warn('No migrations have been run yet')
    end
    Logger.Info('========================================')
end, false)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Always check and fix ec_admin_settings table structure on startup
CreateThread(function()
    Wait(2000)  -- Wait for database to be ready
    if MySQL and MySQL.ready then
        Logger.Info('🔄 Starting automatic database migration...')
        -- Ensure migration tracking table and run normal migrations
        EnsureMigrationTable()

        -- Only add columns/keys if they do NOT exist
        local function columnExists(table, column)
            local result = MySQL.Sync.fetchScalar([[SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @table AND COLUMN_NAME = @column]], {['@table'] = table, ['@column'] = column})
            return result and tonumber(result) > 0
        end
        local function keyExists(table, key)
            local result = MySQL.Sync.fetchScalar([[SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_NAME = @table AND INDEX_NAME = @key]], {['@table'] = table, ['@key'] = key})
            return result and tonumber(result) > 0
        end
        if not columnExists('ec_admin_settings', 'category') then
            MySQL.Async.execute([[ALTER TABLE ec_admin_settings ADD COLUMN category VARCHAR(50) NOT NULL]], {}, function() end)
        end
        if not columnExists('ec_admin_settings', 'settings_data') then
            MySQL.Async.execute([[ALTER TABLE ec_admin_settings ADD COLUMN settings_data LONGTEXT NOT NULL]], {}, function() end)
        end
        if not columnExists('ec_admin_settings', 'updated_by') then
            MySQL.Async.execute([[ALTER TABLE ec_admin_settings ADD COLUMN updated_by VARCHAR(100) DEFAULT NULL]], {}, function() end)
        end
        if not columnExists('ec_admin_settings', 'updated_at') then
            MySQL.Async.execute([[ALTER TABLE ec_admin_settings ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP]], {}, function() end)
        end
        if not keyExists('ec_admin_settings', 'category') then
            MySQL.Async.execute([[ALTER TABLE ec_admin_settings ADD UNIQUE KEY category (category)]], {}, function() end)
        end
        Logger.Success('✅ ec_admin_settings table structure checked and fixed (if needed)')
    else
        Logger.Error('❌ Database (MySQL) not available - migration skipped')
        Logger.Warn('Ensure oxmysql is started BEFORE EC_Admin_Ultimate')
    end
end)

Logger.Success('✅ Auto-Migration system loaded (Commands: ec:migrate, ec:migrate:status)')

return AutoMigrate
