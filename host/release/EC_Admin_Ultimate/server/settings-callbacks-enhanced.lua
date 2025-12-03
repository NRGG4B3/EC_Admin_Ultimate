--[[
    EC Admin Ultimate - Enhanced Settings Management
    Complete settings system with categories, validation, and webhooks
]]

local QBCore = nil
local ESX = nil
local Framework = 'unknown'

-- Initialize framework
CreateThread(function()
    Wait(1000)
    
    if GetResourceState('qbx_core') == 'started' then
        QBCore = exports.qbx_core -- QBX uses direct export
        Framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
    else
        Framework = 'standalone'
    end
    
    Logger.Info('Settings Management Initialized: ' .. Framework)
end)

-- Create settings table
CreateThread(function()
    Wait(2000)
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_admin_settings (
            id INT PRIMARY KEY DEFAULT 1,
            settings LONGTEXT NULL,
            webhooks LONGTEXT NULL,
            permissions LONGTEXT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            updated_by VARCHAR(100) NULL
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_settings_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            category VARCHAR(50) NOT NULL,
            changed_by VARCHAR(100) NOT NULL,
            old_value LONGTEXT NULL,
            new_value LONGTEXT NULL,
            change_description TEXT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_category (category),
            INDEX idx_created (created_at)
        )
    ]], {})
    
    Logger.Info('Settings tables initialized')
end)

-- Default settings structure
local DEFAULT_SETTINGS = {
    general = {
        serverName = GetConvar('sv_hostname', 'FiveM Server'),
        language = 'en',
        timezone = 'UTC',
        dateFormat = 'MM/DD/YYYY',
        timeFormat = '12h',
        theme = 'dark',
        accentColor = '#3b82f6',
        enableSounds = true,
        enableAnimations = true
    },
    permissions = {
        requireAdminForPanel = true,
        allowPlayerReports = true,
        autoModeration = false,
        enableAnticheat = true,
        enableAIDetection = false,
        enableWhitelist = false,
        allowGuestView = false,
        requireTwoFactor = false
    },
    webhooks = {
        enabled = false,
        adminActionsWebhook = '',
        banWebhook = '',
        reportWebhook = '',
        economyWebhook = '',
        anticheatWebhook = '',
        aiDetectionWebhook = '',
        whitelistWebhook = '',
        systemWebhook = ''
    },
    notifications = {
        enabled = true,
        playerJoin = true,
        playerLeave = true,
        adminActions = true,
        anticheat = true,
        aiDetection = true,
        reports = true,
        economy = false,
        vehicles = false,
        housing = false,
        position = 'top-right',
        duration = 5000
    },
    limits = {
        maxBanDuration = 365,
        maxWarnCount = 5,
        autoKickOnWarnings = true,
        maxMoneyGive = 1000000,
        maxMoneyRemove = 500000,
        vehicleSpawnCooldown = 5,
        maxTeleportDistance = 10000,
        maxPlayersPerPage = 50,
        maxReportsPerPage = 25
    },
    anticheat = {
        enabled = true,
        godModeDetection = true,
        speedHackDetection = true,
        teleportDetection = true,
        weaponDetection = true,
        noclipDetection = true,
        resourceInjection = true,
        autoban = false,
        autokick = true,
        autolog = true,
        sensitivity = 'medium'
    },
    aiDetection = {
        enabled = false,
        behaviorAnalysis = true,
        patternRecognition = true,
        movementTracking = true,
        actionSequencing = true,
        autoFlag = true,
        autoReport = false,
        threshold = 75
    },
    economy = {
        logTransactions = true,
        maxTransaction = 100000,
        enableTaxes = false,
        taxRate = 0,
        allowNegativeBalance = false,
        currencySymbol = '$',
        currencyFormat = 'before'
    },
    whitelist = {
        enabled = false,
        requireApplication = true,
        autoApprove = false,
        allowMultipleApplications = false,
        applicationCooldown = 24,
        enableQueue = true,
        maxQueueSize = 150,
        queueRefreshRate = 5000
    },
    logging = {
        logAllActions = true,
        logPlayerActions = true,
        logAdminActions = true,
        logEconomy = true,
        logVehicles = true,
        logAnticheat = true,
        logAIDetection = true,
        retentionDays = 30,
        enableFileLogging = false,
        logLevel = 'info'
    },
    performance = {
        enableOptimization = true,
        lowMemoryMode = false,
        cachePlayerData = true,
        cacheVehicleData = true,
        updateInterval = 5000,
        cleanupInterval = 300000,
        maxCacheSize = 1000
    },
    ui = {
        compactMode = false,
        showPlayerAvatars = true,
        showVehicleImages = true,
        enableMapView = true,
        defaultPage = 'dashboard',
        sidebarCollapsed = false,
        enableKeyboardShortcuts = true
    }
}

-- Get all settings
RegisterNetEvent('ec_admin_ultimate:server:getSettings', function()
    local src = source
    
    -- Get settings from database
    local result = MySQL.Sync.fetchAll('SELECT * FROM ec_admin_settings WHERE id = 1 LIMIT 1', {})
    
    local settings = DEFAULT_SETTINGS
    local webhooks = {}
    local permissions = {}
    
    if result and #result > 0 then
        local row = result[1]
        
        -- Parse settings
        if row.settings then
            local parsed = json.decode(row.settings)
            if parsed then
                -- Merge with defaults to ensure all keys exist
                for category, defaults in pairs(DEFAULT_SETTINGS) do
                    if parsed[category] then
                        settings[category] = {}
                        for key, defaultValue in pairs(defaults) do
                            settings[category][key] = parsed[category][key] ~= nil and parsed[category][key] or defaultValue
                        end
                    end
                end
            end
        end
        
        -- Parse webhooks
        if row.webhooks then
            local parsed = json.decode(row.webhooks)
            if parsed then
                webhooks = parsed
            end
        end
        
        -- Parse permissions
        if row.permissions then
            local parsed = json.decode(row.permissions)
            if parsed then
                permissions = parsed
            end
        end
    end
    
    -- Get server info
    local serverInfo = {
        hostname = GetConvar('sv_hostname', 'Unknown Server'),
        maxPlayers = GetConvarInt('sv_maxclients', 48),
        version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '3.5.0',
        framework = Framework,
        resourceName = GetCurrentResourceName(),
        uptime = os.time() - (GlobalState.serverStartTime or os.time())
    }
    
    -- Get recent changes
    local recentChanges = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_settings_history 
        ORDER BY created_at DESC 
        LIMIT 20
    ]], {})
    
    TriggerClientEvent('ec_admin_ultimate:client:receiveSettings', src, {
        success = true,
        data = {
            settings = settings,
            webhooks = webhooks,
            permissions = permissions,
            serverInfo = serverInfo,
            recentChanges = recentChanges,
            defaults = DEFAULT_SETTINGS
        }
    })
end)

-- Save settings
RegisterNetEvent('ec_admin_ultimate:server:saveSettings', function(data)
    local src = source
    local category = data.category
    local values = data.values
    
    if not category or not values then
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = false,
            message = 'Invalid data provided'
        })
        return
    end
    
    -- Get current settings
    local result = MySQL.Sync.fetchAll('SELECT settings FROM ec_admin_settings WHERE id = 1 LIMIT 1', {})
    
    local currentSettings = DEFAULT_SETTINGS
    if result and #result > 0 and result[1].settings then
        local parsed = json.decode(result[1].settings)
        if parsed then
            currentSettings = parsed
        end
    end
    
    -- Update category
    local oldValue = currentSettings[category]
    currentSettings[category] = values
    
    -- Save to database
    MySQL.Async.execute([[
        INSERT INTO ec_admin_settings (id, settings, updated_by, updated_at)
        VALUES (1, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE 
            settings = VALUES(settings),
            updated_by = VALUES(updated_by),
            updated_at = NOW()
    ]], {json.encode(currentSettings), GetPlayerName(src)})
    
    -- Log change
    MySQL.Async.execute([[
        INSERT INTO ec_settings_history (category, changed_by, old_value, new_value, change_description)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        category,
        GetPlayerName(src),
        json.encode(oldValue),
        json.encode(values),
        'Settings updated: ' .. category
    })
    
    TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
        success = true,
        message = 'Settings saved successfully'
    })
    
    Logger.Info(string.format('', category, GetPlayerName(src)))
end)

-- Save webhooks
RegisterNetEvent('ec_admin_ultimate:server:saveWebhooks', function(data)
    local src = source
    local webhooks = data.webhooks
    
    if not webhooks then
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = false,
            message = 'Invalid webhook data'
        })
        return
    end
    
    MySQL.Async.execute([[
        INSERT INTO ec_admin_settings (id, webhooks, updated_by, updated_at)
        VALUES (1, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE 
            webhooks = VALUES(webhooks),
            updated_by = VALUES(updated_by),
            updated_at = NOW()
    ]], {json.encode(webhooks), GetPlayerName(src)})
    
    TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
        success = true,
        message = 'Webhooks saved successfully'
    })
    
    Logger.Info(string.format('', GetPlayerName(src)))
end)

-- Test webhook
RegisterNetEvent('ec_admin_ultimate:server:testWebhook', function(data)
    local src = source
    local webhookUrl = data.webhookUrl
    
    if not webhookUrl or webhookUrl == '' then
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = false,
            message = 'Invalid webhook URL'
        })
        return
    end
    
    -- Send test message
    PerformHttpRequest(webhookUrl, function(errorCode, resultData, resultHeaders)
        if errorCode == 204 or errorCode == 200 then
            TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
                success = true,
                message = 'Webhook test successful!'
            })
        else
            TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
                success = false,
                message = 'Webhook test failed. Error code: ' .. errorCode
            })
        end
    end, 'POST', json.encode({
        username = 'EC Admin Ultimate',
        embeds = {{
            title = '🧪 Webhook Test',
            description = 'This is a test message from EC Admin Ultimate.',
            color = 3447003,
            footer = {
                text = 'EC Admin Ultimate v3.5.0'
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
        }}
    }), {['Content-Type'] = 'application/json'})
end)

-- Reset settings
RegisterNetEvent('ec_admin_ultimate:server:resetSettings', function(data)
    local src = source
    local category = data.category
    
    if not category then
        TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
            success = false,
            message = 'Invalid category'
        })
        return
    end
    
    -- Get current settings
    local result = MySQL.Sync.fetchAll('SELECT settings FROM ec_admin_settings WHERE id = 1 LIMIT 1', {})
    
    local currentSettings = DEFAULT_SETTINGS
    if result and #result > 0 and result[1].settings then
        local parsed = json.decode(result[1].settings)
        if parsed then
            currentSettings = parsed
        end
    end
    
    -- Reset category to defaults
    currentSettings[category] = DEFAULT_SETTINGS[category]
    
    -- Save to database
    MySQL.Async.execute([[
        UPDATE ec_admin_settings 
        SET settings = ?, updated_by = ?, updated_at = NOW()
        WHERE id = 1
    ]], {json.encode(currentSettings), GetPlayerName(src)})
    
    -- Log change
    MySQL.Async.execute([[
        INSERT INTO ec_settings_history (category, changed_by, old_value, new_value, change_description)
        VALUES (?, ?, NULL, ?, ?)
    ]], {
        category,
        GetPlayerName(src),
        json.encode(DEFAULT_SETTINGS[category]),
        'Settings reset to defaults: ' .. category
    })
    
    TriggerClientEvent('ec_admin_ultimate:client:settingsResponse', src, {
        success = true,
        message = 'Settings reset to defaults'
    })
    
    Logger.Info(string.format('', category, GetPlayerName(src)))
end)

-- Export settings getter
exports('GetSettings', function(category)
    local result = MySQL.Sync.fetchAll('SELECT settings FROM ec_admin_settings WHERE id = 1 LIMIT 1', {})
    
    if result and #result > 0 and result[1].settings then
        local settings = json.decode(result[1].settings)
        if settings then
            if category then
                return settings[category] or DEFAULT_SETTINGS[category]
            else
                return settings
            end
        end
    end
    
    if category then
        return DEFAULT_SETTINGS[category]
    else
        return DEFAULT_SETTINGS
    end
end)

Logger.Info('Enhanced Settings callbacks loaded')