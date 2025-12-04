-- EC Admin Ultimate - Host Webhooks Management
-- Webhook configuration and management for host
-- Author: NRG Development
-- Version: 1.0.0

-- Get all configured webhooks
function GetHostWebhooks()
    local webhooks = MySQL.query.await([[
        SELECT * FROM ec_host_webhooks 
        ORDER BY event_type ASC
    ]]) or {}
    
    return webhooks
end

-- Get webhook logs
function GetWebhookLogs(filters)
    local query = [[
        SELECT wl.*, hw.event_type, hw.webhook_name
        FROM ec_host_webhook_logs wl
        LEFT JOIN ec_host_webhooks hw ON wl.webhook_id = hw.id
        WHERE 1=1
    ]]
    local params = {}
    
    if filters then
        if filters.webhookId then
            query = query .. ' AND wl.webhook_id = ?'
            table.insert(params, filters.webhookId)
        end
        
        if filters.eventType then
            query = query .. ' AND hw.event_type = ?'
            table.insert(params, filters.eventType)
        end
        
        if filters.status then
            query = query .. ' AND wl.status = ?'
            table.insert(params, filters.status)
        end
        
        if filters.startTime then
            query = query .. ' AND wl.timestamp >= ?'
            table.insert(params, filters.startTime)
        end
    end
    
    query = query .. ' ORDER BY wl.timestamp DESC LIMIT 500'
    
    return MySQL.query.await(query, params) or {}
end

-- Create or update webhook
function SaveHostWebhook(source, webhookData)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.webhooks') then
        return false, 'No permission'
    end
    
    local adminName = GetPlayerName(source)
    
    if webhookData.id then
        -- Update existing webhook
        MySQL.update([[
            UPDATE ec_host_webhooks 
            SET webhook_name = ?, webhook_url = ?, event_type = ?, enabled = ?, 
                config = ?, updated_by = ?, updated_at = ?
            WHERE id = ?
        ]], {
            webhookData.name,
            webhookData.url,
            webhookData.eventType,
            webhookData.enabled and 1 or 0,
            json.encode(webhookData.config or {}),
            adminName,
            os.time(),
            webhookData.id
        })
        
        LogHostAction(source, 'WEBHOOK_UPDATED', {
            webhookId = webhookData.id,
            eventType = webhookData.eventType
        })
        
        return true, 'Webhook updated', webhookData.id
    else
        -- Create new webhook
        local insertId = MySQL.insert.await([[
            INSERT INTO ec_host_webhooks 
            (webhook_name, webhook_url, event_type, enabled, config, created_by, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            webhookData.name,
            webhookData.url,
            webhookData.eventType,
            webhookData.enabled and 1 or 0,
            json.encode(webhookData.config or {}),
            adminName,
            os.time()
        })
        
        if insertId then
            LogHostAction(source, 'WEBHOOK_CREATED', {
                webhookId = insertId,
                eventType = webhookData.eventType
            })
            
            return true, 'Webhook created', insertId
        end
        
        return false, 'Failed to create webhook'
    end
end

-- Delete webhook
function DeleteHostWebhook(source, webhookId)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.webhooks') then
        return false, 'No permission'
    end
    
    MySQL.execute('DELETE FROM ec_host_webhooks WHERE id = ?', {webhookId})
    
    LogHostAction(source, 'WEBHOOK_DELETED', {
        webhookId = webhookId
    })
    
    return true, 'Webhook deleted'
end

-- Test webhook
function TestHostWebhook(source, webhookId)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.webhooks') then
        return false, 'No permission'
    end
    
    local webhook = MySQL.single.await('SELECT * FROM ec_host_webhooks WHERE id = ?', {webhookId})
    
    if not webhook then
        return false, 'Webhook not found'
    end
    
    -- Send test webhook via webhook-relay API
    exports['ec_admin_ultimate']:CallHostAPI('/api/v1/webhooks/send', 'POST', {
        webhookUrl = webhook.webhook_url,
        eventType = 'test',
        data = {
            message = 'Test webhook from EC Admin Ultimate',
            timestamp = os.time(),
            testedBy = GetPlayerName(source)
        }
    }, function(success, response)
        -- Log the test
        LogWebhookExecution(webhookId, 'test', success, response)
        
        if success then
            TriggerClientEvent('ec_admin:host:webhookTestResult', source, true, 'Webhook test successful')
        else
            TriggerClientEvent('ec_admin:host:webhookTestResult', source, false, 'Webhook test failed')
        end
    end)
    
    return true, 'Webhook test initiated'
end

-- Send webhook (internal function)
function SendWebhook(eventType, data)
    -- Get all enabled webhooks for this event type
    local webhooks = MySQL.query.await([[
        SELECT * FROM ec_host_webhooks 
        WHERE event_type = ? AND enabled = 1
    ]], {eventType})
    
    if not webhooks then return end
    
    for _, webhook in ipairs(webhooks) do
        if webhook.webhook_url and webhook.webhook_url ~= '' then
            -- Parse config
            local config = {}
            if webhook.config then
                local ok, decoded = pcall(json.decode, webhook.config)
                if ok then config = decoded end
            end

            -- Build webhook payload
            local payload = {
                event = eventType,
                timestamp = os.time(),
                data = data
            }

            -- Add custom fields from config
            if config.customFields then
                for key, value in pairs(config.customFields) do
                    payload[key] = value
                end
            end

            -- Send via webhook-relay API
            exports['ec_admin_ultimate']:CallHostAPI('/api/v1/webhooks/send', 'POST', {
                webhookUrl = webhook.webhook_url,
                eventType = eventType,
                payload = payload
            }, function(success, response)
                -- Log the execution
                LogWebhookExecution(webhook.id, eventType, success, response)
            end)
        else
            Logger.Info('⚠️ Skipping webhook send: missing URL for event type ' .. tostring(eventType))
        end
    end
end

-- Log webhook execution
function LogWebhookExecution(webhookId, eventType, success, response)
    local status = success and 'success' or 'failed'
    local responseText = type(response) == 'string' and response or json.encode(response or {})
    
    MySQL.insert([[
        INSERT INTO ec_host_webhook_logs 
        (webhook_id, event_type, status, response, timestamp)
        VALUES (?, ?, ?, ?, ?)
    ]], {webhookId, eventType, status, responseText, os.time()})
end

-- Get webhook statistics
function GetWebhookStats(webhookId, timeRange)
    local startTime = os.time() - (timeRange or 86400) -- Default 24h
    
    local stats = MySQL.query.await([[
        SELECT 
            COUNT(*) as total_executions,
            SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as successful,
            SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
            AVG(CASE WHEN status = 'success' THEN 1 ELSE 0 END) * 100 as success_rate
        FROM ec_host_webhook_logs
        WHERE webhook_id = ? AND timestamp >= ?
    ]], {webhookId, startTime})
    
    return stats and stats[1] or {
        total_executions = 0,
        successful = 0,
        failed = 0,
        success_rate = 0
    }
end

-- Available webhook event types
local WEBHOOK_EVENT_TYPES = {
    'global_ban',
    'global_unban',
    'global_warning',
    'ban_appeal_submitted',
    'ban_appeal_processed',
    'bans',
    'kicks',
    'teleports',
    'warnings',
    'permissions_violations',
    'city_connected',
    'city_disconnected',
    'api_offline',
    'api_online',
    'api_error',
    'emergency_stop',
    'config_sync',
    'backup_completed',
    'restore_completed',
    'player_threshold',
    'performance_alert',
    'security_alert',
    'admin_action',
    'system_alert'
}

function GetWebhookEventTypes()
    return WEBHOOK_EVENT_TYPES
end

-- Export functions
exports('GetHostWebhooks', GetHostWebhooks)
exports('GetWebhookLogs', GetWebhookLogs)
exports('SaveHostWebhook', SaveHostWebhook)
exports('DeleteHostWebhook', DeleteHostWebhook)
exports('TestHostWebhook', TestHostWebhook)
exports('SendWebhook', SendWebhook)
exports('GetWebhookStats', GetWebhookStats)
exports('GetWebhookEventTypes', GetWebhookEventTypes)

-- Re-export for compatibility
_G.SendHostWebhook = SendWebhook
_G.LogHostAction = function(source, actionType, details)
    local identifier = GetPlayerIdentifiers(source)[1]
    local playerName = GetPlayerName(source)
    
    MySQL.insert([[
        INSERT INTO ec_host_actions (admin_id, admin_name, action_type, details, timestamp)
        VALUES (?, ?, ?, ?, ?)
    ]], {identifier, playerName, actionType, json.encode(details), os.time()})
end

Logger.Info('🪝 Host Webhooks system loaded')
