--[[
    EC Admin Ultimate - Admin Team Database Migration
    Creates ec_admin_team table
]]

CreateThread(function()
    -- Wait for MySQL to be ready
    while not MySQL do
        Wait(100)
    end
    
    Wait(2000)  -- Additional wait for database connection
    
    if not Config or not Config.Database or not Config.Database.enabled then
        return
    end
    
    Logger.Info('💾 Creating admin team database table...')
    
    -- Create ec_admin_team table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ec_admin_team` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(50) NOT NULL,
            `name` varchar(100) DEFAULT NULL,
            `rank` varchar(50) DEFAULT 'admin',
            `permissions` longtext DEFAULT NULL,
            `added_at` bigint(20) DEFAULT NULL,
            `added_by` varchar(50) DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier` (`identifier`),
            KEY `rank` (`rank`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function(success)
        if success then
            Logger.Info('✅ Admin team table created successfully')
        else
            Logger.Info('⚠️  Admin team table may already exist')
        end
    end)
end)
