-- ============================================================================
-- EC ADMIN ULTIMATE - DATABASE INITIALIZATION
-- Ensures critical tables exist on startup
-- ============================================================================

Logger.Info('💾 Database Initialization - Starting...')

-- Ensure ec_admin_config table exists
local function EnsureConfigTable()
    local configTableQuery = [[
        CREATE TABLE IF NOT EXISTS ec_admin_config (
            id INT(11) NOT NULL AUTO_INCREMENT,
            config_key VARCHAR(100) NOT NULL UNIQUE,
            config_value LONGTEXT NOT NULL,
            value_type VARCHAR(50) NOT NULL DEFAULT 'string',
            description TEXT,
            enabled TINYINT(1) NOT NULL DEFAULT 1,
            updated_by VARCHAR(100) DEFAULT NULL,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY config_key (config_key),
            KEY enabled (enabled)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    
    MySQL.Async.execute(configTableQuery, {}, function(result)
        if result then
            Logger.Success('✅ Config table ensured')
        else
            Logger.Error('❌ Failed to create config table')
        end
    end)
end

-- Wait for MySQL to be ready
local function EnsureCriticalTables()
    -- Ensure ec_admin_migrations table exists first (for migration tracking)
    local migrationTableQuery = [[
        CREATE TABLE IF NOT EXISTS ec_admin_migrations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            filename VARCHAR(255) NOT NULL UNIQUE,
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            success BOOLEAN DEFAULT TRUE,
            error_message TEXT NULL,
            INDEX idx_filename (filename)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    
    MySQL.Async.execute(migrationTableQuery, {}, function(result)
        if result then
            Logger.Success('✅ Migration table ensured')
            EnsureConfigTable()
        else
            Logger.Error('❌ Failed to create migration table')
        end
    end)
end

-- Initialize on startup with a small delay to ensure MySQL is ready
SetTimeout(1000, function()
    if MySQL and MySQL.Async then
        EnsureCriticalTables()
    else
        Logger.Warn('⚠️ MySQL not ready yet, retrying...')
        SetTimeout(2000, function()
            if MySQL and MySQL.Async then
                EnsureCriticalTables()
            end
        end)
    end
end)

Logger.Info('💾 Database initialization scheduled')
