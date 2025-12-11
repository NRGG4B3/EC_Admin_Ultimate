--[[
    EC Admin Ultimate - Settings UI Backend
    Server-side logic for settings management
    
    Handles:
    - settings:getData: Get all settings data
    - settings:save: Save settings for a category
    - settings:saveWebhooks: Save webhook settings
    - settings:testWebhook: Test a webhook URL
    - settings:reset: Reset settings to defaults
    
    Framework Support: QB-Core, QBX, ESX
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Settings] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Settings] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local serverStartTime = os.time()
local settingsCache = {}
local CACHE_TTL = 30 -- Cache for 30 seconds

-- Default settings
local DEFAULT_SETTINGS = {
    general = {
        serverName = GetConvar('sv_hostname', 'FiveM Server'),
        serverLogo = '',
        language = 'en',
        timezone = 'UTC',
        dateFormat = 'YYYY-MM-DD',
        timeFormat = '24h',
        theme = 'dark',
        compactMode = false,
        autoRefresh = true,
        refreshInterval = 10
    },
    permissions = {
        enablePermissions = true,
        defaultPermissionLevel = 'user',
        requirePermissionForActions = true
    },
    webhooks = {
        enabled = true,
        retryOnFailure = true,
        maxRetries = 3,
        timeout = 30
    },
    notifications = {
        enabled = true,
        soundEnabled = true,
        desktopNotifications = false,
        notificationDuration = 5000
    },
    limits = {
        maxPlayers = GetConvarInt('sv_maxclients', 32),
        maxVehicles = 500,
        maxItems = 1000,
        maxMoney = 999999999
    },
    anticheat = {
        enabled = true,
        autoActions = true,
        aiAnalysis = true,
        sensitivity = 'medium',
        logLevel = 'info'
    },
    aiDetection = {
        enabled = true,
        confidenceThreshold = 0.7,
        patternDetection = true,
        autoBan = false
    },
    economy = {
        enabled = true,
        allowNegativeBalance = false,
        transactionLogging = true,
        maxTransactionAmount = 1000000
    },
    whitelist = {
        enabled = true,
        requireApproval = false,
        autoApprove = false
    },
    logging = {
        enabled = true,
        logLevel = 'info',
        logToFile = true,
        logToDatabase = true,
        maxLogAge = 30 -- days
    },
    performance = {
        cacheEnabled = true,
        cacheTTL = 10,
        maxCacheSize = 1000,
        enableMetrics = true
    },
    ui = {
        theme = 'dark',
        compactMode = false,
        animationsEnabled = true,
        showTooltips = true,
        accentColor = '#3b82f6',
        enableSounds = true,
        dateFormat = 'YYYY-MM-DD',
        timeFormat = '24h',
        timezone = 'UTC',
        autoRefresh = true,
        refreshInterval = 10
    }
}

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Get admin info
local function getAdminInfo(source)
    return {
        id = GetPlayerIdentifier(source, 0) or 'system',
        name = GetPlayerName(source) or 'System'
    }
end

-- Helper: Get setting value
local function getSetting(category, key, defaultValue)
    local result = MySQL.query.await([[
        SELECT setting_value FROM ec_settings 
        WHERE category = ? AND setting_key = ?
        LIMIT 1
    ]], {category, key})
    
    if result and result[1] and result[1].setting_value then
        local value = result[1].setting_value
        -- Try to parse as JSON
        local success, parsed = pcall(json.decode, value)
        if success then
            return parsed
        end
        -- Try to parse as boolean
        if value == 'true' then
            return true
        elseif value == 'false' then
            return false
        end
        -- Try to parse as number
        local num = tonumber(value)
        if num then
            return num
        end
        return value
    end
    
    return defaultValue
end

-- Helper: Set setting value
local function setSetting(category, key, value, adminId)
    local valueStr = tostring(value)
    if type(value) == 'table' then
        valueStr = json.encode(value)
    elseif type(value) == 'boolean' then
        valueStr = value and 'true' or 'false'
    end
    
    MySQL.insert.await([[
        INSERT INTO ec_settings (category, setting_key, setting_value, updated_at, updated_by)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        setting_value = VALUES(setting_value),
        updated_at = VALUES(updated_at),
        updated_by = VALUES(updated_by)
    ]], {category, key, valueStr, getCurrentTimestamp(), adminId})
end

-- Helper: Log setting change
local function logSettingChange(adminId, adminName, category, key, oldValue, newValue)
    MySQL.insert.await([[
        INSERT INTO ec_settings_changes_log 
        (admin_id, admin_name, category, setting_key, old_value, new_value, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        adminId, adminName, category, key,
        oldValue and tostring(oldValue) or nil,
        newValue and tostring(newValue) or nil,
        getCurrentTimestamp()
    })
end

-- Helper: Get all settings for category
local function getCategorySettings(category)
    local settings = {}
    local defaults = DEFAULT_SETTINGS[category] or {}
    
    -- Get from database
    local result = MySQL.query.await([[
        SELECT setting_key, setting_value FROM ec_settings 
        WHERE category = ?
    ]], {category})
    
    if result then
        for _, row in ipairs(result) do
            local value = row.setting_value
            -- Try to parse as JSON
            local success, parsed = pcall(json.decode, value)
            if success then
                settings[row.setting_key] = parsed
            elseif value == 'true' then
                settings[row.setting_key] = true
            elseif value == 'false' then
                settings[row.setting_key] = false
            else
                local num = tonumber(value)
                settings[row.setting_key] = num or value
            end
        end
    end
    
    -- Merge with defaults
    for key, defaultValue in pairs(defaults) do
        if settings[key] == nil then
            settings[key] = defaultValue
        end
    end
    
    return settings
end

-- Helper: Get all settings
local function getAllSettings()
    local settings = {}
    
    for category, _ in pairs(DEFAULT_SETTINGS) do
        settings[category] = getCategorySettings(category)
    end
    
    return settings
end

-- Helper: Get all webhooks
local function getAllWebhooks()
    local webhooks = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_webhooks
        ORDER BY created_at DESC
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            local headers = {}
            if row.headers then
                headers = json.decode(row.headers) or {}
            end
            
            table.insert(webhooks, {
                id = row.id,
                name = row.name,
                url = row.url,
                event_type = row.event_type,
                enabled = (row.enabled == 1 or row.enabled == true),
                method = row.method or 'POST',
                headers = headers,
                format = row.format or 'json',
                retry_count = tonumber(row.retry_count) or 3,
                timeout = tonumber(row.timeout) or 30,
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at),
                updated_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.updated_at)
            })
        end
    end
    
    return webhooks
end

-- Helper: Get recent changes
local function getRecentChanges(limit)
    limit = limit or 50
    local changes = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_settings_changes_log
        ORDER BY created_at DESC
        LIMIT ?
    ]], {limit})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(changes, {
                id = row.id,
                admin_name = row.admin_name,
                category = row.category,
                setting_key = row.setting_key,
                old_value = row.old_value,
                new_value = row.new_value,
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at)
            })
        end
    end
    
    return changes
end

-- Helper: Get server info
local function getServerInfo()
    return {
        hostname = GetConvar('sv_hostname', 'FiveM Server'),
        maxPlayers = GetConvarInt('sv_maxclients', 32),
        version = GetConvar('version', ''),
        framework = getFramework(),
        resourceName = GetCurrentResourceName(),
        uptime = getCurrentTimestamp() - serverStartTime
    }
end

-- Helper: Get settings data (shared logic)
local function getSettingsData()
    -- Check cache
    if settingsCache.data and (getCurrentTimestamp() - settingsCache.timestamp) < CACHE_TTL then
        return settingsCache.data
    end
    
    local settings = getAllSettings()
    local webhooks = getAllWebhooks()
    local permissions = {} -- Placeholder for permissions
    local serverInfo = getServerInfo()
    local recentChanges = getRecentChanges(50)
    
    local data = {
        settings = settings,
        webhooks = webhooks,
        permissions = permissions,
        serverInfo = serverInfo,
        recentChanges = recentChanges,
        defaults = DEFAULT_SETTINGS
    }
    
    -- Cache data
    settingsCache = {
        data = data,
        timestamp = getCurrentTimestamp()
    }
    
    return data
end

-- Helper: Send HTTP request (for webhook testing)
local function sendHTTPRequest(url, method, headers, body)
    -- Use PerformHttpRequest if available
    if PerformHttpRequest then
        local requestId = math.random(1000000, 9999999)
        local success = false
        local responseCode = 0
        local responseBody = ''
        
        PerformHttpRequest(url, function(code, body, headers)
            success = (code >= 200 and code < 300)
            responseCode = code
            responseBody = body or ''
        end, method or 'POST', body or '', headers or {})
        
        -- Wait for response (with timeout)
        local timeout = 0
        while timeout < 30 and not success and responseCode == 0 do
            Wait(100)
            timeout = timeout + 0.1
        end
        
        return success, responseCode, responseBody
    end
    
    return false, 0, 'HTTP requests not available'
end

-- ============================================================================
-- REGISTERNUICALLBACK HANDLERS (Direct fetch from UI)
-- ============================================================================

-- Note: RegisterNUICallback is CLIENT-side only
-- Use lib.callback.register for server-side callbacks
lib.callback.register('ec_admin:settings:getData', function(source)
    local response = getSettingsData()
    return { success = true, data = response }
end)

-- Note: RegisterNUICallback is CLIENT-side only - removed
-- Use lib.callback.register for server-side callbacks
lib.callback.register('ec_admin:settings:save', function(source, category, values)
    if not category or not values then
        return { success = false, message = 'Category and values required' }
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Settings saved successfully'
    
    -- Save each setting
    for key, value in pairs(values) do
        local oldValue = getSetting(category, key, nil)
        setSetting(category, key, value, adminInfo.id)
        
        -- Log change
        if oldValue ~= value then
            logSettingChange(adminInfo.id, adminInfo.name, category, key, oldValue, value)
        end
    end
    
    success = true
    
    -- Clear cache
    settingsCache = {}
    
    return { success = success, message = success and message or 'Failed to save settings' }
end)

-- Note: RegisterNUICallback is CLIENT-side only - removed
-- Use lib.callback.register for server-side callbacks
lib.callback.register('ec_admin:settings:saveWebhooks', function(source, webhooks)
    local webhooks = data.webhooks
    
    if not webhooks or type(webhooks) ~= 'table' then
        cb({ success = false, message = 'Webhooks data required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Webhooks saved successfully'
    
    -- Save/update webhooks
    for _, webhook in ipairs(webhooks) do
        if webhook.id then
            -- Update existing
            MySQL.update.await([[
                UPDATE ec_webhooks 
                SET name = ?, url = ?, event_type = ?, enabled = ?, method = ?, headers = ?, format = ?, retry_count = ?, timeout = ?, updated_at = ?
                WHERE id = ?
            ]], {
                webhook.name, webhook.url, webhook.event_type,
                webhook.enabled and 1 or 0, webhook.method or 'POST',
                webhook.headers and json.encode(webhook.headers) or nil,
                webhook.format or 'json', tonumber(webhook.retry_count) or 3,
                tonumber(webhook.timeout) or 30, getCurrentTimestamp(), webhook.id
            })
        else
            -- Insert new
            MySQL.insert.await([[
                INSERT INTO ec_webhooks 
                (name, url, event_type, enabled, method, headers, format, retry_count, timeout, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                webhook.name, webhook.url, webhook.event_type,
                webhook.enabled and 1 or 0, webhook.method or 'POST',
                webhook.headers and json.encode(webhook.headers) or nil,
                webhook.format or 'json', tonumber(webhook.retry_count) or 3,
                tonumber(webhook.timeout) or 30, getCurrentTimestamp(), getCurrentTimestamp()
            })
        end
    end
    
    success = true
    
    -- Clear cache
    settingsCache = {}
    
    return { success = success, message = success and message or 'Failed to save webhooks' }
end)

-- Note: RegisterNUICallback is CLIENT-side only - removed
-- Use lib.callback.register for server-side callbacks
lib.callback.register('ec_admin:settings:testWebhook', function(source, webhookUrl)
    if not webhookUrl then
        return { success = false, message = 'Webhook URL required' }
    end
    
    local success = false
    local message = 'Webhook test successful'
    local responseCode = 0
    local responseBody = ''
    
    -- Send test request
    local testData = {
        event = 'test',
        message = 'This is a test webhook from EC Admin Ultimate',
        timestamp = getCurrentTimestamp(),
        server = GetConvar('sv_hostname', 'FiveM Server')
    }
    
    local headers = {
        ['Content-Type'] = 'application/json'
    }
    
    success, responseCode, responseBody = sendHTTPRequest(webhookUrl, 'POST', headers, json.encode(testData))
    
    if success then
        message = string.format('Webhook test successful (Status: %d)', responseCode)
    else
        message = string.format('Webhook test failed (Status: %d): %s', responseCode, responseBody)
    end
    
    return { success = success, message = message, responseCode = responseCode }
end)

-- Note: RegisterNUICallback is CLIENT-side only - removed
-- Use lib.callback.register for server-side callbacks
lib.callback.register('ec_admin:settings:reset', function(source, category)
    if not category then
        return { success = false, message = 'Category required' }
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Settings reset successfully'
    
    local defaults = DEFAULT_SETTINGS[category]
    if not defaults then
        return { success = false, message = 'Invalid category' }
    end
    
    -- Delete all settings for category
    MySQL.query.await('DELETE FROM ec_settings WHERE category = ?', {category})
    
    -- Reset to defaults
    for key, value in pairs(defaults) do
        setSetting(category, key, value, adminInfo.id)
        logSettingChange(adminInfo.id, adminInfo.name, category, key, nil, value)
    end
    
    success = true
    
    -- Clear cache
    settingsCache = {}
    
    return { success = success, message = success and message or 'Failed to reset settings' }
end)

-- Export function to get setting
exports('GetSetting', function(category, key, defaultValue)
    return getSetting(category, key, defaultValue)
end)

-- Export function to set setting
exports('SetSetting', function(category, key, value, adminId)
    setSetting(category, key, value, adminId or 'system')
    settingsCache = {} -- Clear cache
end)

-- Webhook event type mapping (maps internal event types to config webhook URLs)
local WEBHOOK_EVENT_MAP = {
    -- Whitelist events
    ['whitelist_join_denied'] = 'adminWhitelist',
    ['whitelist_join_allowed'] = 'adminWhitelist',
    ['whitelist_entry_added'] = 'adminWhitelist',
    ['whitelist_entry_updated'] = 'adminWhitelist',
    ['whitelist_entry_removed'] = 'adminWhitelist',
    ['whitelist_application_submitted'] = 'adminWhitelist',
    ['whitelist_application_approved'] = 'adminWhitelist',
    ['whitelist_application_denied'] = 'adminWhitelist',
    
    -- Admin action events
    ['admin_action'] = 'adminActions',
    ['admin_ban'] = 'adminBans',
    ['admin_kick'] = 'adminActions',
    ['admin_warn'] = 'adminActions',
    ['admin_teleport'] = 'adminActions',
    ['admin_spectate'] = 'adminActions',
    ['admin_noclip'] = 'adminActions',
    ['admin_godmode'] = 'adminActions',
    ['admin_freeze'] = 'adminActions',
    ['admin_revive'] = 'adminActions',
    ['admin_give_weapon'] = 'adminActions',
    ['admin_give_item'] = 'adminEconomy',
    ['admin_give_money'] = 'adminEconomy',
    ['admin_job_change'] = 'adminActions',
    
    -- Anticheat events
    ['anticheat_detection'] = 'adminAntiCheat',
    ['ai_detection'] = 'adminAIDetection',
    
    -- Reports
    ['report_submitted'] = 'adminReports',
    ['report_resolved'] = 'adminReports',
    
    -- Server Events
    ['server_started'] = 'adminMain',
    ['server_stopped'] = 'adminMain',
    ['server_restarted'] = 'adminMain',
    ['player_joined'] = 'adminMain',
    
    -- General
    ['menu_open'] = 'adminMain',
    ['menu_close'] = 'adminMain',
    ['page_change'] = 'adminMain',
    ['player_select'] = 'adminMain',
}

-- Export function to trigger webhook
exports('TriggerWebhook', function(eventType, data)
    if not Config or not Config.Webhooks or not Config.Webhooks.enabled then
        return false
    end
    
    -- Map event type to webhook URL key
    local webhookKey = WEBHOOK_EVENT_MAP[eventType] or eventType
    
    -- Get webhook URL for event type
    local webhookUrl = nil
    if Config.Webhooks.urls and Config.Webhooks.urls[webhookKey] then
        webhookUrl = Config.Webhooks.urls[webhookKey]
    elseif Config.Webhooks.defaultWebhookUrl then
        webhookUrl = Config.Webhooks.defaultWebhookUrl
    end
    
    if not webhookUrl or webhookUrl == '' then
        return false
    end
    
    -- Check if this event type is toggled off
    local toggleKey = nil
    if eventType == 'whitelist_join_denied' or eventType == 'whitelist_join_allowed' or 
       eventType == 'whitelist_entry_added' or eventType == 'whitelist_entry_updated' or
       eventType == 'whitelist_entry_removed' or eventType == 'whitelist_application_submitted' or
       eventType == 'whitelist_application_approved' or eventType == 'whitelist_application_denied' then
        -- Whitelist events are always sent if webhooks enabled
    elseif Config.Webhooks.toggles then
        -- Check specific toggles
        if eventType == 'admin_ban' and Config.Webhooks.toggles.bans == false then
            return false
        elseif eventType == 'admin_kick' and Config.Webhooks.toggles.kicks == false then
            return false
        elseif eventType == 'admin_warn' and Config.Webhooks.toggles.warns == false then
            return false
        elseif Config.Webhooks.toggles.adminActions == false then
            return false
        end
    end
    
    -- Format Discord embed
    local embed = {
        title = data.title or string.gsub(eventType, '_', ' '):gsub('(%a)([%w_]+)', function(first, rest) return first:upper() .. rest:lower() end),
        description = data.description or '',
        color = data.color or (Config.Webhooks.embed and Config.Webhooks.embed.color and Config.Webhooks.embed.color.adminAction) or 3447003,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        fields = {}
    }
    
    -- Add custom fields if provided
    if data.fields and type(data.fields) == 'table' then
        for _, field in ipairs(data.fields) do
            if field.name and field.value then
                table.insert(embed.fields, {
                    name = tostring(field.name),
                    value = tostring(field.value),
                    inline = field.inline ~= false
                })
            end
        end
    end
    
    -- Add default fields from data if no custom fields
    if #embed.fields == 0 and data then
        for key, value in pairs(data) do
            if key ~= 'title' and key ~= 'description' and key ~= 'color' and key ~= 'footer' and key ~= 'fields' then
                table.insert(embed.fields, {
                    name = string.gsub(key, '_', ' '):gsub('(%a)([%w_]+)', function(first, rest) return first:upper() .. rest:lower() end),
                    value = tostring(value),
                    inline = true
                })
            end
        end
    end
    
    if data.footer then
        embed.footer = { text = tostring(data.footer) }
    elseif Config.Webhooks.embed and Config.Webhooks.embed.footer then
        embed.footer = { text = Config.Webhooks.embed.footer }
    end
    
    local payload = {
        username = Config.Webhooks.embed and Config.Webhooks.embed.username or 'EC Admin Logger',
        avatar_url = Config.Webhooks.embed and Config.Webhooks.embed.avatar or nil,
        embeds = { embed }
    }
    
    -- Send webhook asynchronously
    CreateThread(function()
        local success, code, body = sendHTTPRequest(webhookUrl, 'POST', {
            ['Content-Type'] = 'application/json'
        }, json.encode(payload))
        
        if not success then
            print(string.format("^3[Webhook]^7 Failed to send webhook %s: %s^0", eventType, tostring(body)))
        end
    end)
    
    return true
end)

print("^2[Settings]^7 UI Backend loaded^0")

