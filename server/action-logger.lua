-- ============================================================================
-- EC ADMIN ULTIMATE - CENTRALIZED ACTION LOGGER
-- ============================================================================
-- Logs ALL menu clicks, admin actions, and UI interactions
-- Supports both console logging and Discord webhooks
-- ============================================================================

Logger.Info('📋 Centralized Action Logger - Loading...')

local ActionLogger = {}

-- Action Categories
ActionLogger.Categories = {
    MENU_CLICK = 'Menu Click',
    MENU_OPEN = 'Menu Open',
    MENU_CLOSE = 'Menu Close',
    PAGE_CHANGE = 'Page Change',
    PLAYER_SELECT = 'Player Select',
    ADMIN_ACTION = 'Admin Action',
    CONFIG_CHANGE = 'Config Change',
    PLAYER_ACTION = 'Player Action',
    SYSTEM = 'System'
}

-- Webhook Colors
local WEBHOOK_COLORS = {
    MENU_CLICK = 3447003,  -- Blue
    MENU_OPEN = 3066993,   -- Green
    MENU_CLOSE = 10181046, -- Purple
    PAGE_CHANGE = 15844367, -- Gold
    PLAYER_SELECT = 3447003, -- Blue
    ADMIN_ACTION = 15158332, -- Red
    CONFIG_CHANGE = 15105570, -- Orange
    PLAYER_ACTION = 3447003, -- Blue
    SYSTEM = 9807270       -- Gray
}

-- ============================================================================
-- LOG TO CONSOLE (Detailed Console Output)
-- ============================================================================
function ActionLogger.LogToConsole(adminSource, category, action, details)
    if not Config.Discord or not Config.Discord.consoleLogging or not Config.Discord.consoleLogging.enabled then
        return
    end
    
    local adminName = GetPlayerName(adminSource) or 'Unknown'
    local adminIdentifiers = GetPlayerIdentifiers(adminSource)
    local adminLicense = 'Unknown'
    
    for _, id in ipairs(adminIdentifiers) do
        if string.match(id, 'license:') then
            adminLicense = id
            break
        end
    end
    
    -- Build log message
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    local logMessage = string.format(
        '[%s] 👤 %s [%s] | 📂 %s | 🎯 %s',
        timestamp,
        adminName,
        adminSource,
        category,
        action
    )
    
    -- Add details if provided
    if details and type(details) == 'table' then
        if details.targetName then
            logMessage = logMessage .. string.format(' | 🎭 Target: %s', details.targetName)
        end
        if details.page then
            logMessage = logMessage .. string.format(' | 📄 Page: %s', details.page)
        end
        if details.button then
            logMessage = logMessage .. string.format(' | 🔘 Button: %s', details.button)
        end
        if details.value then
            logMessage = logMessage .. string.format(' | 💾 Value: %s', tostring(details.value))
        end
        if details.reason then
            logMessage = logMessage .. string.format(' | 📝 Reason: %s', details.reason)
        end
    end
    
    Logger.Info(logMessage)
end

-- ============================================================================
-- LOG TO DISCORD WEBHOOK (Rich Embeds)
-- ============================================================================
function ActionLogger.LogToWebhook(adminSource, category, action, details)
    if not Config.Discord or not Config.Discord.enabled or not Config.Discord.webhook or Config.Discord.webhook == '' then
        return
    end
    
    -- Check if this category should be logged to webhook
    local shouldLog = false
    if category == ActionLogger.Categories.MENU_CLICK and Config.Discord.logMenuClicks then
        shouldLog = true
    elseif category == ActionLogger.Categories.MENU_OPEN and Config.Discord.logMenuOpens then
        shouldLog = true
    elseif category == ActionLogger.Categories.PAGE_CHANGE and Config.Discord.logPageChanges then
        shouldLog = true
    elseif category == ActionLogger.Categories.PLAYER_SELECT and Config.Discord.logPlayerSelection then
        shouldLog = true
    elseif category == ActionLogger.Categories.CONFIG_CHANGE and Config.Discord.logConfigChanges then
        shouldLog = true
    elseif category == ActionLogger.Categories.ADMIN_ACTION and Config.Discord.logAdminActions then
        shouldLog = true
    end
    
    if not shouldLog then
        return
    end
    
    local adminName = GetPlayerName(adminSource) or 'Unknown'
    local adminIdentifiers = GetPlayerIdentifiers(adminSource)
    local adminLicense = 'Unknown'
    local adminDiscord = 'Not Linked'
    
    for _, id in ipairs(adminIdentifiers) do
        if string.match(id, 'license:') then
            adminLicense = id
        elseif string.match(id, 'discord:') then
            adminDiscord = string.gsub(id, 'discord:', '')
        end
    end
    
    -- Build embed fields
    local fields = {
        {
            name = '👤 Admin',
            value = string.format('%s [%s]', adminName, adminSource),
            inline = true
        },
        {
            name = '🎯 Action',
            value = action,
            inline = true
        }
    }
    
    -- Add details fields
    if details and type(details) == 'table' then
        if details.targetName then
            table.insert(fields, {
                name = '🎭 Target Player',
                value = string.format('%s [%s]', details.targetName, details.targetId or 'N/A'),
                inline = true
            })
        end
        if details.page then
            table.insert(fields, {
                name = '📄 Page',
                value = details.page,
                inline = true
            })
        end
        if details.button then
            table.insert(fields, {
                name = '🔘 Button',
                value = details.button,
                inline = true
            })
        end
        if details.component then
            table.insert(fields, {
                name = '🧩 Component',
                value = details.component,
                inline = true
            })
        end
        if details.value then
            table.insert(fields, {
                name = '💾 Value',
                value = tostring(details.value),
                inline = true
            })
        end
        if details.oldValue then
            table.insert(fields, {
                name = '🔄 Old Value',
                value = tostring(details.oldValue),
                inline = true
            })
        end
        if details.newValue then
            table.insert(fields, {
                name = '✨ New Value',
                value = tostring(details.newValue),
                inline = true
            })
        end
        if details.reason then
            table.insert(fields, {
                name = '📝 Reason',
                value = details.reason,
                inline = false
            })
        end
    end
    
    -- Add license field
    table.insert(fields, {
        name = '🆔 License',
        value = '`' .. adminLicense .. '`',
        inline = false
    })
    
    -- Build webhook payload
    local embed = {
        title = '🎮 ' .. category,
        description = string.format('**%s** performed an action', adminName),
        color = WEBHOOK_COLORS[category:gsub(' ', '_')] or 3447003,
        fields = fields,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        footer = {
            text = 'EC Admin Ultimate - Action Logger',
            icon_url = 'https://i.imgur.com/4M34hi2.png'
        }
    }
    
    -- Add Discord tag if available
    if adminDiscord ~= 'Not Linked' then
        embed.author = {
            name = adminName,
            icon_url = string.format('https://cdn.discordapp.com/avatars/%s/avatar.png', adminDiscord)
        }
    end
    
    -- Send webhook
    PerformHttpRequest(Config.Discord.webhook, function(statusCode, response, headers)
        if statusCode ~= 204 and statusCode ~= 200 then
            Logger.Warn(string.format('Failed to send webhook: %d', statusCode))
        end
    end, 'POST', json.encode({
        username = 'EC Admin - Action Logger',
        avatar_url = 'https://i.imgur.com/4M34hi2.png',
        embeds = { embed }
    }), {
        ['Content-Type'] = 'application/json'
    })
end

-- ============================================================================
-- LOG TO DATABASE (Persistent Storage)
-- ============================================================================
function ActionLogger.LogToDatabase(adminSource, category, action, details)
    if not Config.Database or not Config.Database.enabled then
        return
    end
    
    local adminName = GetPlayerName(adminSource) or 'Unknown'
    local adminIdentifiers = GetPlayerIdentifiers(adminSource)
    local adminLicense = 'Unknown'
    
    for _, id in ipairs(adminIdentifiers) do
        if string.match(id, 'license:') then
            adminLicense = id
            break
        end
    end
    
    local targetIdentifier = details and details.targetLicense or nil
    local targetName = details and details.targetName or nil
    local metadata = details and json.encode(details) or nil
    
    MySQL.Async.execute(
        'INSERT INTO ec_admin_action_logs (admin_identifier, admin_name, action, category, target_identifier, target_name, details, metadata, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            adminLicense,
            adminName,
            action,
            category,
            targetIdentifier,
            targetName,
            action,  -- details column
            metadata,
            os.time()
        },
        function(result)
            if not result then
                Logger.Error('Failed to log action to database')
            end
        end
    )
end

-- ============================================================================
-- UNIFIED LOG FUNCTION (Console + Webhook + Database)
-- ============================================================================
function ActionLogger.Log(adminSource, category, action, details)
    -- Log to console
    ActionLogger.LogToConsole(adminSource, category, action, details)
    
    -- Log to webhook
    ActionLogger.LogToWebhook(adminSource, category, action, details)
    
    -- Log to database
    ActionLogger.LogToDatabase(adminSource, category, action, details)
end

-- ============================================================================
-- CONVENIENCE FUNCTIONS (Specific Action Types)
-- ============================================================================

function ActionLogger.LogMenuClick(adminSource, button, page, component)
    ActionLogger.Log(adminSource, ActionLogger.Categories.MENU_CLICK, 'UI Click', {
        button = button,
        page = page,
        component = component
    })
end

function ActionLogger.LogMenuOpen(adminSource)
    ActionLogger.Log(adminSource, ActionLogger.Categories.MENU_OPEN, 'Opened Admin Menu', {})
end

function ActionLogger.LogMenuClose(adminSource)
    ActionLogger.Log(adminSource, ActionLogger.Categories.MENU_CLOSE, 'Closed Admin Menu', {})
end

function ActionLogger.LogPageChange(adminSource, fromPage, toPage)
    ActionLogger.Log(adminSource, ActionLogger.Categories.PAGE_CHANGE, 'Page Navigation', {
        oldValue = fromPage,
        newValue = toPage
    })
end

function ActionLogger.LogPlayerSelect(adminSource, targetId, targetName)
    ActionLogger.Log(adminSource, ActionLogger.Categories.PLAYER_SELECT, 'Selected Player', {
        targetId = targetId,
        targetName = targetName
    })
end

function ActionLogger.LogAdminAction(adminSource, action, targetId, targetName, reason, additionalDetails)
    local details = additionalDetails or {}
    details.targetId = targetId
    details.targetName = targetName
    details.reason = reason
    
    ActionLogger.Log(adminSource, ActionLogger.Categories.ADMIN_ACTION, action, details)
end

function ActionLogger.LogConfigChange(adminSource, configKey, oldValue, newValue)
    ActionLogger.Log(adminSource, ActionLogger.Categories.CONFIG_CHANGE, 'Config Updated', {
        button = configKey,
        oldValue = oldValue,
        newValue = newValue
    })
end

-- ============================================================================
-- LIB.CALLBACK: Log Action from Client
-- ============================================================================
lib.callback.register('ec_admin:logAction', function(source, data)
    if not data or not data.category or not data.action then
        return { success = false, error = 'Invalid data' }
    end
    
    ActionLogger.Log(source, data.category, data.action, data.details or {})
    
    return { success = true }
end)

-- ============================================================================
-- REGISTER NET EVENTS (For Client-Side Logging)
-- ============================================================================

RegisterNetEvent('ec_admin:log:menuClick', function(button, page, component)
    ActionLogger.LogMenuClick(source, button, page, component)
end)

RegisterNetEvent('ec_admin:log:menuOpen', function()
    ActionLogger.LogMenuOpen(source)
end)

RegisterNetEvent('ec_admin:log:menuClose', function()
    ActionLogger.LogMenuClose(source)
end)

RegisterNetEvent('ec_admin:log:pageChange', function(fromPage, toPage)
    ActionLogger.LogPageChange(source, fromPage, toPage)
end)

RegisterNetEvent('ec_admin:log:playerSelect', function(targetId, targetName)
    ActionLogger.LogPlayerSelect(source, targetId, targetName)
end)

-- ============================================================================
-- EXPORT FUNCTIONS
-- ============================================================================
exports('LogAction', function(adminSource, category, action, details)
    ActionLogger.Log(adminSource, category, action, details)
end)

exports('LogMenuClick', function(adminSource, button, page, component)
    ActionLogger.LogMenuClick(adminSource, button, page, component)
end)

exports('LogAdminAction', function(adminSource, action, targetId, targetName, reason, additionalDetails)
    ActionLogger.LogAdminAction(adminSource, action, targetId, targetName, reason, additionalDetails)
end)

-- Make globally available
_G.ActionLogger = ActionLogger

Logger.Success('✅ Centralized Action Logger Loaded')
Logger.Info('   📋 Logs: Console + Discord Webhooks + Database')
Logger.Info('   🎯 Tracks: Menu clicks, page changes, admin actions')
Logger.Info('   💾 Stores: All actions in ec_admin_action_logs table')
