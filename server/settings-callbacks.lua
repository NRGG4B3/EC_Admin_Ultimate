--[[
    EC Admin Ultimate - Settings Management Callbacks (SERVER)
    Complete settings system with database persistence
]]

Logger.Info('Loading Settings callbacks...')

-- ============================================================================
-- SETTINGS STORAGE
-- ============================================================================

local Settings = {
    general = {
        serverName = GetConvar('sv_projectName', 'FiveM Server'),
        serverLogo = '', -- Empty by default, configurable
        maxPlayers = GetConvar('sv_maxclients', '48'),
        frameworkDetected = 'qbx',
        allowPublicReports = true,
        enabledFeatures = {
            inventory = true,
            housing = true,
            jobs = true,
            economy = true,
            vehicles = true
        }
    },
    security = {
        twoFactorAuth = false,
        sessionTimeout = 30,
        ipWhitelist = false,
        allowedIPs = {}
    },
    notifications = {
        enableDesktop = true,
        enableSound = true,
        criticalOnly = false,
        discordWebhook = ''
    },
    performance = {
        autoRestart = false,
        restartTime = '04:00',
        cleanupInterval = 30,
        maxLogs = 10000
    },
    webhooks = {
        playerActions = '',
        adminActions = '',
        bans = '',
        reports = '',
        economy = ''
    }
}

-- ============================================================================
-- DATABASE SETUP
-- ============================================================================
-- Note: Tables are automatically created by auto-migrate-sql.lua
-- This ensures consistent schema for both customers and host mode

CreateThread(function()
    Wait(2000)
    
    -- Load settings from database
    local savedSettings = MySQL.query.await('SELECT * FROM ec_admin_settings', {})
    
    if savedSettings and #savedSettings > 0 then
        for _, row in ipairs(savedSettings) do
            if row.category and row.settings_data then
                local decoded = json.decode(row.settings_data)
                if decoded then
                    Settings[row.category] = decoded
                    Logger.Info('Loaded settings for: ' .. row.category)
                end
            end
        end
    end

    -- Sync missing webhook categories and URLs from config
    if not Settings.webhooks then Settings.webhooks = {} end
    local configWebhooks = Config.Webhooks or {}
        -- Ensure all config webhook categories exist in Settings.webhooks
        for k, v in pairs(configWebhooks) do
            if not Settings.webhooks[k] or Settings.webhooks[k] == '' then
                Settings.webhooks[k] = v
                Logger.Info('Synced missing webhook: ' .. k)
            end
        end
        -- Ensure all required settings categories exist in DB
        local requiredCategories = { 'general', 'security', 'notifications', 'performance', 'webhooks' }
        for _, cat in ipairs(requiredCategories) do
            if not Settings[cat] then
                Settings[cat] = {}
                Logger.Info('Created missing settings category: ' .. cat)
            end
            -- Save to DB if missing
            local exists = false
            for _, row in ipairs(savedSettings or {}) do
                if row.category == cat then exists = true break end
            end
            if not exists then
                MySQL.query.await([[INSERT INTO ec_admin_settings (category, settings_data, updated_by)
                    VALUES (?, ?, ?)
                    ON DUPLICATE KEY UPDATE 
                        settings_data = VALUES(settings_data),
                        updated_by = VALUES(updated_by),
                        updated_at = CURRENT_TIMESTAMP]], {
                    cat,
                    json.encode(Settings[cat]),
                    'system'
                })
                Logger.Info('Upserted missing settings category to DB: ' .. cat)
            end
        end
    -- Sync toggles
    if configWebhooks.toggles then
        for k,v in pairs(configWebhooks.toggles) do
            if Settings.webhooks[k] == nil then Settings.webhooks[k] = v end
        end
    end
    -- Sync URLs
    if configWebhooks.urls then
        if not Settings.webhooks.urls then Settings.webhooks.urls = {} end
        for k,v in pairs(configWebhooks.urls) do
            if Settings.webhooks.urls[k] == nil then Settings.webhooks.urls[k] = v end
        end
    end
    -- Sync defaultWebhookUrl
    if configWebhooks.defaultWebhookUrl and not Settings.webhooks.defaultWebhookUrl then
        Settings.webhooks.defaultWebhookUrl = configWebhooks.defaultWebhookUrl
    end
    -- Sync enabled
    if configWebhooks.enabled ~= nil and Settings.webhooks.enabled == nil then
        Settings.webhooks.enabled = configWebhooks.enabled
    end
end)

-- ============================================================================
-- HELPER: DETECT FRAMEWORK
-- ============================================================================

local function DetectFramework()
    if GetResourceState('qbx_core') == 'started' then
        return 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        return 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx'
    end
    return 'standalone'
end

Settings.general.frameworkDetected = DetectFramework()

-- ============================================================================
-- GET SETTINGS
-- ============================================================================

lib.callback.register('ec_admin:getSettings', function(source, _)
    return {
        success = true,
        data = Settings
    }
end)

RegisterNetEvent('ec_admin_ultimate:server:getSettings', function()
    local src = source
    TriggerClientEvent('ec_admin_ultimate:client:receiveSettings', src, {
        success = true,
        data = Settings
    })
    Logger.Info(string.format('', src))
end)

-- ============================================================================
-- SAVE SETTINGS
-- ============================================================================

lib.callback.register('ec_admin:saveSettings', function(source, data)
    local src = source
    if not data or not data.category or not data.values then
        return { success = false, message = 'Invalid settings data' }
    end
    -- Update in memory
    Settings[data.category] = data.values
    -- Save to database
    local settingsJson = json.encode(data.values)
    local adminName = GetPlayerName(src)
    local ok, err = pcall(function()
        MySQL.query.await([[
            INSERT INTO ec_admin_settings (category, settings_data, updated_by)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE 
                settings_data = VALUES(settings_data),
                updated_by = VALUES(updated_by),
                updated_at = CURRENT_TIMESTAMP
        ]], {
            data.category,
            settingsJson,
            adminName
        })
    end)
    if not ok then
        Logger.Info('' .. tostring(err) .. '^0')
        return { success = false, message = 'Database error' }
    end
    Logger.Info(string.format('', adminName, data.category))
    return { success = true, message = 'Settings saved successfully' }
end)

RegisterNetEvent('ec_admin_ultimate:server:saveSettings', function(data)
    local src = source
    
    if not data or not data.category or not data.values then
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = false,
            message = 'Invalid settings data'
        })
        return
    end
    
    CreateThread(function()
        -- Update in memory
        Settings[data.category] = data.values
        
        -- Save to database
        local settingsJson = json.encode(data.values)
        local adminName = GetPlayerName(src)
        
        local success, err = pcall(function()
            MySQL.query.await([[
                INSERT INTO ec_admin_settings (category, settings_data, updated_by)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE 
                    settings_data = VALUES(settings_data),
                    updated_by = VALUES(updated_by),
                    updated_at = CURRENT_TIMESTAMP
            ]], {
                data.category,
                settingsJson,
                adminName
            })
        end)
        
        if not success then
            Logger.Info('' .. tostring(err) .. '^0')
            TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
                success = false,
                message = 'Database error'
            })
            return
        end
        
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = true,
            message = 'Settings saved successfully'
        })
        
        Logger.Info(string.format('', adminName, data.category))
    end)
end)

-- ============================================================================
-- SAVE WEBHOOKS
-- ============================================================================

lib.callback.register('ec_admin:saveWebhooks', function(source, data)
    local src = source
    if not data or not data.webhooks then
        return { success = false, message = 'Invalid webhook data' }
    end
    Settings.webhooks = data.webhooks
    local webhooksJson = json.encode(data.webhooks)
    local adminName = GetPlayerName(src)
    local ok, err = pcall(function()
        MySQL.query.await([[
            INSERT INTO ec_admin_settings (category, settings_data, updated_by)
            VALUES ('webhooks', ?, ?)
            ON DUPLICATE KEY UPDATE 
                settings_data = VALUES(settings_data),
                updated_by = VALUES(updated_by),
                updated_at = CURRENT_TIMESTAMP
        ]], {
            webhooksJson,
            adminName
        })
    end)
    if not ok then
        Logger.Info('' .. tostring(err) .. '^0')
        return { success = false, message = 'Database error' }
    end
    Logger.Info(string.format('', adminName))
    return { success = true, message = 'Webhooks saved successfully' }
end)

RegisterNetEvent('ec_admin_ultimate:server:saveWebhooks', function(data)
    local src = source
    
    if not data or not data.webhooks then
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = false,
            message = 'Invalid webhook data'
        })
        return
    end
    
    CreateThread(function()
        Settings.webhooks = data.webhooks
        
        local webhooksJson = json.encode(data.webhooks)
        local adminName = GetPlayerName(src)
        
        local success, err = pcall(function()
            MySQL.query.await([[
                INSERT INTO ec_admin_settings (category, settings_data, updated_by)
                VALUES ('webhooks', ?, ?)
                ON DUPLICATE KEY UPDATE 
                    settings_data = VALUES(settings_data),
                    updated_by = VALUES(updated_by),
                    updated_at = CURRENT_TIMESTAMP
            ]], {
                webhooksJson,
                adminName
            })
        end)
        
        if not success then
            Logger.Info('' .. tostring(err) .. '^0')
            TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
                success = false,
                message = 'Database error'
            })
            return
        end
        
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = true,
            message = 'Webhooks saved successfully'
        })
        
        Logger.Info(string.format('', adminName))
    end)
end)

-- ============================================================================
-- TEST WEBHOOK
-- ============================================================================

lib.callback.register('ec_admin:testWebhook', function(source, data)
    local src = source
    if not data or not data.url then
        return { success = false, message = 'No webhook URL provided' }
    end
    local testEmbed = {
        {
            title = "🧪 EC Admin - Webhook Test",
            description = "This is a test message from EC Admin Ultimate.",
            color = 3447003,
            fields = {
                { name = "Server", value = Settings.general.serverName, inline = true },
                { name = "Tested By", value = GetPlayerName(src), inline = true },
                { name = "Status", value = "✅ Webhook is working correctly!", inline = false }
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    local result = nil
    PerformHttpRequest(data.url, function(statusCode, responseText, headers)
        if statusCode == 200 or statusCode == 204 then
            result = { success = true, message = 'Webhook test successful! Check your Discord channel.' }
            Logger.Info('Webhook test succeeded (Status: ' .. statusCode .. ')')
        else
            result = { success = false, message = 'Webhook test failed. Status code: ' .. statusCode }
            Logger.Info('Webhook test failed (Status: ' .. statusCode .. ')')
        end
    end, 'POST', json.encode({ username = "EC Admin", embeds = testEmbed }), { ['Content-Type'] = 'application/json' })
    -- Synchronous return is not ideal for HTTP; if ox_lib supports async, consider moving to an event+await. Here we fallback to immediate response.
    return result or { success = false, message = 'Webhook test initiated; check logs for result.' }
end)

RegisterNetEvent('ec_admin_ultimate:server:testWebhook', function(data)
    local src = source
    
    if not data or not data.url then
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = false,
            message = 'No webhook URL provided'
        })
        return
    end
    
    CreateThread(function()
        local testEmbed = {
            {
                title = "🧪 EC Admin - Webhook Test",
                description = "This is a test message from EC Admin Ultimate.",
                color = 3447003,
                fields = {
                    {
                        name = "Server",
                        value = Settings.general.serverName,
                        inline = true
                    },
                    {
                        name = "Tested By",
                        value = GetPlayerName(src),
                        inline = true
                    },
                    {
                        name = "Status",
                        value = "✅ Webhook is working correctly!",
                        inline = false
                    }
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
        
        PerformHttpRequest(data.url, function(statusCode, responseText, headers)
            if statusCode == 200 or statusCode == 204 then
                TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
                    success = true,
                    message = 'Webhook test successful! Check your Discord channel.'
                })
                Logger.Info('Webhook test succeeded (Status: ' .. statusCode .. ')')
            else
                TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
                    success = false,
                    message = 'Webhook test failed. Status code: ' .. statusCode
                })
                Logger.Info('Webhook test failed (Status: ' .. statusCode .. ')')
            end
        end, 'POST', json.encode({
            username = "EC Admin",
            embeds = testEmbed
        }), {
            ['Content-Type'] = 'application/json'
        })
    end)
end)

-- ============================================================================
-- RESET SETTINGS
-- ============================================================================

lib.callback.register('ec_admin:resetSettings', function(source, data)
    local src = source
    if not data or not data.category then
        return { success = false, message = 'No category specified' }
    end
    local defaults = {
        general = {
            serverName = GetConvar('sv_projectName', 'FiveM Server'),
            serverLogo = '',
            maxPlayers = GetConvar('sv_maxclients', '48'),
            frameworkDetected = DetectFramework(),
            allowPublicReports = true,
            enabledFeatures = { inventory = true, housing = true, jobs = true, economy = true, vehicles = true }
        },
        security = { twoFactorAuth = false, sessionTimeout = 30, ipWhitelist = false, allowedIPs = {} },
        notifications = { enableDesktop = true, enableSound = true, criticalOnly = false, discordWebhook = '' },
        performance = { autoRestart = false, restartTime = '04:00', cleanupInterval = 30, maxLogs = 10000 }
    }
    if defaults[data.category] then
        Settings[data.category] = defaults[data.category]
        Logger.Info(string.format('', GetPlayerName(src), data.category))
        return { success = true, message = 'Settings reset to defaults', data = defaults[data.category] }
    else
        return { success = false, message = 'Invalid category' }
    end
end)

RegisterNetEvent('ec_admin_ultimate:server:resetSettings', function(data)
    local src = source
    
    if not data or not data.category then
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = false,
            message = 'No category specified'
        })
        return
    end
    
    -- Reset to default based on category
    local defaults = {
        general = {
            serverName = GetConvar('sv_projectName', 'FiveM Server'),
            serverLogo = '',
            maxPlayers = GetConvar('sv_maxclients', '48'),
            frameworkDetected = DetectFramework(),
            allowPublicReports = true,
            enabledFeatures = {
                inventory = true,
                housing = true,
                jobs = true,
                economy = true,
                vehicles = true
            }
        },
        security = {
            twoFactorAuth = false,
            sessionTimeout = 30,
            ipWhitelist = false,
            allowedIPs = {}
        },
        notifications = {
            enableDesktop = true,
            enableSound = true,
            criticalOnly = false,
            discordWebhook = ''
        },
        performance = {
            autoRestart = false,
            restartTime = '04:00',
            cleanupInterval = 30,
            maxLogs = 10000
        }
    }
    
    if defaults[data.category] then
        Settings[data.category] = defaults[data.category]
        
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = true,
            message = 'Settings reset to defaults',
            data = defaults[data.category]
        })
        
        Logger.Info(string.format('', GetPlayerName(src), data.category))
    else
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = false,
            message = 'Invalid category'
        })
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

-- Get a specific setting
exports('GetSetting', function(category, key)
    if not category then return nil end
    if not key then return Settings[category] end
    return Settings[category] and Settings[category][key] or nil
end)

-- Set a setting
exports('SetSetting', function(category, key, value)
    if not Settings[category] then
        Settings[category] = {}
    end
    Settings[category][key] = value
    return true
end)

Logger.Info('✅ Settings callbacks loaded successfully')
