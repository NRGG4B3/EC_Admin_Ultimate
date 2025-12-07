--[[
    EC Admin Ultimate - Auto Database Migration
    Automatically runs missing schema fixes on startup
]]

local function RunMigration()
    -- Check if admin_profiles exists
    local profilesResult = MySQL.query.await([[CREATE TABLE IF NOT EXISTS `admin_profiles` (
          `id` INT AUTO_INCREMENT PRIMARY KEY,
          `identifier` VARCHAR(64) NOT NULL UNIQUE,
          `name` VARCHAR(64) DEFAULT NULL,
          `status` ENUM('active','inactive') NOT NULL DEFAULT 'inactive',
          `uptime` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
          `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX `identifier_idx` (`identifier`),
          INDEX `status_idx` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]])
    if profilesResult then
        Logger.Info('')
    end

    -- Check if ec_admin_bans has expires column
    local expiresCheck = MySQL.query.await([[SELECT COUNT(*) as count
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'ec_admin_bans'
        AND COLUMN_NAME = 'expires']])

    if expiresCheck and expiresCheck[1] and expiresCheck[1].count == 0 then
        local alterResult = MySQL.query.await([[ALTER TABLE `ec_admin_bans`
                ADD COLUMN `expires` BIGINT(20) NOT NULL DEFAULT 0 AFTER `reason`,
                ADD INDEX `expires_idx` (`expires`)]])
        if alterResult then
            Logger.Info('')
        end
    else
        Logger.Info('')
    end
end

-- Wait for database to be ready
CreateThread(function()
    Wait(2000) -- Give oxmysql time to connect
    
    local dbReady = MySQL.ready
    if dbReady then
        dbReady(RunMigration)
    else
        -- Fallback if MySQL.ready not available
        Wait(3000)
        RunMigration()
    end
end)

Logger.Info('')
