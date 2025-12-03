-- EC Admin Ultimate - Webhook System (PRODUCTION STABLE)
-- Version: 1.0.0 - Safe Discord notifications with rate limiting

Logger.Info('Loading webhook system...', '📨')

-- Safety check: Ensure Config exists
if not Config then
    Logger.Error('Webhooks ERROR: Config not loaded! Disabling webhooks.', '❌')
    Config = {}
end

local Webhooks = {}

-- Webhook configuration
local webhookConfig = {
    enabled = Config.Discord and Config.Discord.enabled or false,
    webhookUrl = Config.Discord and (Config.Discord.webhookUrl or Config.Discord.webhook) or '',  -- Support both property names
    rateLimit = {
        maxRequests = 5,     -- Max 5 requests per minute
        interval = 60000,    -- 1 minute
        requests = {},
        enabled = true
    },
    timeout = 10000,         -- 10 second timeout
    retries = 2,             -- Max 2 retries
    colors = {
        info = 3447003,      -- Blue
        success = 3066993,   -- Green
        warning = 15844367,  -- Gold
        error = 15158332,    -- Red
        admin = 10181046     -- Purple
    }
}

-- Rate limiting
local function CheckRateLimit()
    if not webhookConfig.rateLimit.enabled then return true end
    
    local currentTime = GetGameTimer()
    local requests = webhookConfig.rateLimit.requests
    
    -- Clean old requests
    for i = #requests, 1, -1 do
        if currentTime - requests[i] > webhookConfig.rateLimit.interval then
            table.remove(requests, i)
        end
    end
    
    -- Check if we're within rate limit
    if #requests >= webhookConfig.rateLimit.maxRequests then
        Logger.Warn('Webhook rate limit exceeded, dropping message', '⚠️')
        return false
    end
    
    -- Add current request
    table.insert(requests, currentTime)
    return true
end

-- ✅ PRODUCTION READY: Safe HTTP request function with database logging
local function SafeHttpRequest(url, data, callback, webhookType, eventType)
    local startTime = GetGameTimer()
    
    if not url or url == '' then
        if callback then callback(false, 'No webhook URL configured') end
        return
    end
    
    if not CheckRateLimit() then
        if callback then callback(false, 'Rate limit exceeded') end
        return
    end
    
    local jsonData = json.encode(data)
    if not jsonData then
        if callback then callback(false, 'Failed to encode JSON') end
        return
    end
    
    local payloadSize = #jsonData
    
    -- Use a timeout timer
    local completed = false
    local timeoutTimer = SetTimeout(webhookConfig.timeout, function()
        if not completed then
            completed = true
            local responseTime = GetGameTimer() - startTime
            
            -- Database logging for timeout
            if _G.MetricsDB then
                _G.MetricsDB.LogWebhookExecution({
                    url = url,
                    type = webhookType or 'unknown',
                    event = eventType or 'unknown',
                    statusCode = nil,
                    success = false,
                    error = 'Request timeout',
                    payloadSize = payloadSize,
                    responseTime = responseTime
                })
            end
            
            if callback then callback(false, 'Request timeout') end
        end
    end)
    
    -- Make the HTTP request
    PerformHttpRequest(url, function(statusCode, response, headers)
        if completed then return end
        completed = true
        
        if timeoutTimer then
            ClearTimeout(timeoutTimer)
        end
        
        local responseTime = GetGameTimer() - startTime
        local success = (statusCode == 204 or statusCode == 200)
        
        -- ✅ Database logging for webhook execution
        if _G.MetricsDB then
            _G.MetricsDB.LogWebhookExecution({
                url = url,
                type = webhookType or 'unknown',
                event = eventType or 'unknown',
                statusCode = statusCode,
                success = success,
                error = success and nil or ('HTTP ' .. tostring(statusCode)),
                payloadSize = payloadSize,
                responseTime = responseTime
            })
        end
        
        if success then
            if callback then callback(true, 'Message sent successfully') end
        else
            Logger.Error('Webhook request failed with status: ' .. tostring(statusCode), '❌')
            if callback then callback(false, 'HTTP request failed: ' .. tostring(statusCode)) end
        end
    end, 'POST', jsonData, {
        ['Content-Type'] = 'application/json',
        ['User-Agent'] = 'EC-Admin-Ultimate/1.0'
    })
end

-- Format Discord embed
local function CreateEmbed(title, description, color, fields)
    local embed = {
        title = title or 'EC Admin Notification',
        description = description or '',
        color = color or webhookConfig.colors.info,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        footer = {
            text = 'EC Admin Ultimate',
            icon_url = 'https://i.imgur.com/your-icon.png' -- Replace with your icon
        }
    }
    
    if fields and #fields > 0 then
        embed.fields = fields
    end
    
    return embed
end

-- Webhook functions
function Webhooks.SendMessage(title, description, color, fields)
    if not webhookConfig.enabled or webhookConfig.webhookUrl == '' then
        return false, 'Webhooks not configured'
    end
    
    local embed = CreateEmbed(title, description, color, fields)
    local payload = {
        embeds = { embed }
    }
    
    Citizen.CreateThread(function()
        SafeHttpRequest(webhookConfig.webhookUrl, payload, function(success, message)
            if not success then
                Logger.Error('Failed to send webhook: ' .. message, '❌')
            end
        end, 'discord', 'custom_message')
    end)
    
    return true, 'Message queued for sending'
end

function Webhooks.SendAlert(alertType, message, severity)
    local color = webhookConfig.colors.warning
    local title = '🚨 Server Alert'
    
    if severity == 'critical' then
        color = webhookConfig.colors.error
        title = '🔥 Critical Alert'
    elseif severity == 'high' then
        color = webhookConfig.colors.error
        title = '⚠️ High Priority Alert'
    elseif severity == 'low' then
        color = webhookConfig.colors.info
        title = 'ℹ️ Information'
    end
    
    local fields = {
        {
            name = 'Alert Type',
            value = alertType,
            inline = true
        },
        {
            name = 'Severity',
            value = severity:upper(),
            inline = true
        },
        {
            name = 'Server',
            value = GetConvar('sv_hostname', 'Unknown Server'),
            inline = true
        }
    }
    
    return Webhooks.SendMessage(title, message, color, fields)
end

function Webhooks.SendAdminAction(adminName, action, targetName, details)
    local title = '👑 Admin Action'
    local color = webhookConfig.colors.admin
    
    local description = string.format('**%s** performed **%s**', adminName, action)
    if targetName then
        description = description .. string.format(' on **%s**', targetName)
    end
    
    local fields = {
        {
            name = 'Action',
            value = action,
            inline = true
        },
        {
            name = 'Admin',
            value = adminName,
            inline = true
        }
    }
    
    if targetName then
        table.insert(fields, {
            name = 'Target',
            value = targetName,
            inline = true
        })
    end
    
    if details and details ~= '' then
        table.insert(fields, {
            name = 'Details',
            value = details,
            inline = false
        })
    end
    
    return Webhooks.SendMessage(title, description, color, fields)
end

function Webhooks.SendPlayerJoin(playerName, playerCount, maxPlayers)
    local title = '✅ Player Connected'
    local color = webhookConfig.colors.success
    
    local description = string.format('**%s** joined the server', playerName)
    
    local fields = {
        {
            name = 'Player Count',
            value = string.format('%d/%d', playerCount, maxPlayers),
            inline = true
        },
        {
            name = 'Server',
            value = GetConvar('sv_hostname', 'Unknown Server'),
            inline = true
        }
    }
    
    return Webhooks.SendMessage(title, description, color, fields)
end

function Webhooks.SendPlayerLeave(playerName, reason, playerCount, maxPlayers)
    local title = '❌ Player Disconnected'
    local color = webhookConfig.colors.warning
    
    local description = string.format('**%s** left the server', playerName)
    if reason and reason ~= '' then
        description = description .. '\nReason: ' .. reason
    end
    
    local fields = {
        {
            name = 'Player Count',
            value = string.format('%d/%d', playerCount, maxPlayers),
            inline = true
        },
        {
            name = 'Server',
            value = GetConvar('sv_hostname', 'Unknown Server'),
            inline = true
        }
    }
    
    return Webhooks.SendMessage(title, description, color, fields)
end

function Webhooks.SendServerStart()
    local title = '🚀 Server Started'
    local color = webhookConfig.colors.success
    
    local description = 'Server has started successfully'
    
    local fields = {
        {
            name = 'Server Name',
            value = GetConvar('sv_hostname', 'Unknown Server'),
            inline = true
        },
        {
            name = 'Max Players',
            value = tostring(GetConvarInt('sv_maxclients', 32)),
            inline = true
        },
        {
            name = 'OneSync',
            value = GetConvar('onesync', 'off'):upper(),
            inline = true
        }
    }
    
    return Webhooks.SendMessage(title, description, color, fields)
end

-- REMOVED: Event handlers moved to player-events.lua for centralization
-- The centralized handler calls Webhooks.SendPlayerJoin and Webhooks.SendPlayerLeave

-- Note: playerDropped handler also removed

-- Send server start notification
Citizen.CreateThread(function()
    -- Wait for server to fully start
    Citizen.Wait(10000)
    
    if webhookConfig.enabled then
        Webhooks.SendServerStart()
    end
end)

-- Utility function to get safe player count
function GetSafePlayerCount()
    local count = 0
    for i = 0, GetNumPlayerIndices() - 1 do
        local player = GetPlayerFromIndex(i)
        if player and tonumber(player) and tonumber(player) > 0 then
            count = count + 1
        end
    end
    return count
end

-- Whitelist Application Notification with Discord Buttons
function Webhooks.SendApplicationNotification(application, webhookUrl)
    if not webhookUrl or webhookUrl == '' then
        return false, 'No webhook URL provided'
    end
    
    local embed = {
        title = '📝 New Whitelist Application',
        description = string.format('**%s** has submitted a whitelist application', application.applicantName),
        color = 3447003, -- Blue
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        fields = {
            { name = 'Name', value = application.applicantName or 'N/A', inline = true },
            { name = 'Age', value = tostring(application.age or 'N/A'), inline = true },
            { name = 'Discord', value = application.discord or 'N/A', inline = true },
            { name = 'Reason for Joining', value = application.reason or 'N/A', inline = false },
            { name = 'RP Experience', value = application.experience or 'N/A', inline = false },
            { name = 'Referral', value = application.referral or 'None', inline = true },
            { name = 'Application ID', value = application.id, inline = false },
            { name = 'Submitted', value = os.date('!%Y-%m-%d %H:%M:%S', application.submittedAt / 1000), inline = true }
        },
        footer = {
            text = 'EC Admin Ultimate - Whitelist System'
        }
    }
    
    local payload = {
        embeds = { embed },
        content = '@here New whitelist application requires review!',
        components = {
            {
                type = 1, -- Action Row
                components = {
                    {
                        type = 2, -- Button
                        style = 3, -- Success/Green
                        label = '✅ Approve',
                        custom_id = 'whitelist_approve_' .. application.id
                    },
                    {
                        type = 2, -- Button
                        style = 4, -- Danger/Red
                        label = '❌ Deny',
                        custom_id = 'whitelist_deny_' .. application.id
                    },
                    {
                        type = 2, -- Button
                        style = 2, -- Secondary/Gray
                        label = 'ℹ️ View Details',
                        custom_id = 'whitelist_details_' .. application.id
                    }
                }
            }
        }
    }
    
    Citizen.CreateThread(function()
        SafeHttpRequest(webhookUrl, payload, function(success, message)
            if success then
                Logger.Debug(string.format('Application notification sent to Discord (ID: %s)', application.id), '📨')
            else
                Logger.Error(string.format('Failed to send application notification: %s', message), '❌')
            end
        end)
    end)
    
    return true, 'Notification sent'
end

-- Simplified log function for various events
function Webhooks.SendLog(logType, data, customWebhook)
    local url = customWebhook or webhookConfig.webhookUrl
    if not webhookConfig.enabled or url == '' then
        return false, 'Webhooks not configured'
    end
    
    -- Build embed with all provided data
    local embed = {
        title = data.title or 'EC Admin Log',
        description = data.description or '',
        color = data.color or webhookConfig.colors.info,
        fields = data.fields or {},
        timestamp = data.timestamp or os.date('!%Y-%m-%dT%H:%M:%SZ'),
        footer = data.footer or {
            text = 'EC Admin Ultimate',
            icon_url = 'https://i.imgur.com/4M34hi2.png'
        }
    }
    
    local payload = {
        embeds = { embed },
        content = data.content or nil
    }
    
    Citizen.CreateThread(function()
        SafeHttpRequest(url, payload, function(success, message)
            if not success then
                Logger.Error('Failed to send ' .. logType .. ' log: ' .. message, '❌')
            end
        end)
    end)
    
    return true, 'Log queued for sending'
end

-- Exports
exports('SendMessage', function(title, description, color, fields)
    return Webhooks.SendMessage(title, description, color, fields)
end)

exports('SendAlert', function(alertType, message, severity)
    return Webhooks.SendAlert(alertType, message, severity)
end)

exports('SendAdminAction', function(adminName, action, targetName, details)
    return Webhooks.SendAdminAction(adminName, action, targetName, details)
end)

exports('SendApplicationNotification', function(application, webhookUrl)
    return Webhooks.SendApplicationNotification(application, webhookUrl)
end)

exports('SendLog', function(logType, data, customWebhook)
    return Webhooks.SendLog(logType, data, customWebhook)
end)

-- Make available globally
_G.ECWebhooks = Webhooks

-- Register with centralized player events system
if _G.ECPlayerEvents then
    _G.ECPlayerEvents.RegisterSystem('webhooks')
end

if webhookConfig.enabled then
    Logger.Info('Webhook system loaded successfully', '✅')
    Logger.Info('Discord notifications active with rate limiting', '📨')
    Logger.Info('Application notifications with interactive buttons enabled', '📝')
else
    Logger.Warn('Webhook system loaded but disabled in config', '⚠️')
end