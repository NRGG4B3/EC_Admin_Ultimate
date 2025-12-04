-- EC Admin Ultimate - Host API Management Actions
-- All RegisterNetEvent for API management actions
-- Author: NRG Development
-- Version: 1.0.0

-- Start API
RegisterNetEvent('ec_admin:host:startAPI', function(data)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api.control') then
        TriggerClientEvent('ec_admin:client:showNotification', source, {
            type = 'error',
            title = 'Access Denied',
            message = 'You do not have permission to control APIs'
        })
        return
    end
    
    local apiKey = data.apiKey
    if not apiKey then
        return
    end
    
    local success, message = exports['ec_admin_ultimate']:StartAPIService(apiKey, source)
    
    TriggerClientEvent('ec_admin:client:showNotification', source, {
        type = success and 'success' or 'error',
        title = success and 'API Starting' or 'Error',
        message = message
    })
end)

-- Stop API
RegisterNetEvent('ec_admin:host:stopAPI', function(data)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api.control') then
        TriggerClientEvent('ec_admin:client:showNotification', source, {
            type = 'error',
            title = 'Access Denied',
            message = 'You do not have permission to control APIs'
        })
        return
    end
    
    local apiKey = data.apiKey
    if not apiKey then
        return
    end
    
    local success, message = exports['ec_admin_ultimate']:StopAPIService(apiKey, source)
    
    TriggerClientEvent('ec_admin:client:showNotification', source, {
        type = success and 'success' or 'error',
        title = success and 'API Stopping' or 'Error',
        message = message
    })
end)

-- Restart API
RegisterNetEvent('ec_admin:host:restartAPI', function(data)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api.control') then
        TriggerClientEvent('ec_admin:client:showNotification', source, {
            type = 'error',
            title = 'Access Denied',
            message = 'You do not have permission to control APIs'
        })
        return
    end
    
    local apiKey = data.apiKey
    if not apiKey then
        return
    end
    
    local success, message = exports['ec_admin_ultimate']:RestartAPIService(apiKey, source)
    
    TriggerClientEvent('ec_admin:client:showNotification', source, {
        type = success and 'success' or 'error',
        title = success and 'API Restarting' or 'Error',
        message = message
    })
end)

-- Toggle API auto-restart
RegisterNetEvent('ec_admin:host:toggleAPIAutoRestart', function(data)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api.control') then
        TriggerClientEvent('ec_admin:client:showNotification', source, {
            type = 'error',
            title = 'Access Denied',
            message = 'You do not have permission to control APIs'
        })
        return
    end
    
    local apiKey = data.apiKey
    local enabled = data.enabled
    
    if not apiKey then
        return
    end
    
    local success, message = exports['ec_admin_ultimate']:ToggleAPIAutoRestart(apiKey, enabled, source)
    
    TriggerClientEvent('ec_admin:client:showNotification', source, {
        type = success and 'success' or 'error',
        title = success and 'Auto-Restart Updated' or 'Error',
        message = message
    })
end)

-- Start all APIs
RegisterNetEvent('ec_admin:host:startAllAPIs', function()
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api.control') then
        TriggerClientEvent('ec_admin:client:showNotification', source, {
            type = 'error',
            title = 'Access Denied',
            message = 'You do not have permission to control APIs'
        })
        return
    end
    
    local success, message = exports['ec_admin_ultimate']:StartAllAPIs(source)
    
    TriggerClientEvent('ec_admin:client:showNotification', source, {
        type = success and 'success' or 'error',
        title = success and 'Starting All APIs' or 'Error',
        message = message
    })
    
    -- Send webhook notification
    exports['ec_admin_ultimate']:TriggerHostWebhook('api_bulk_action', {
        action = 'start_all',
        admin = GetPlayerName(source),
        timestamp = os.time()
    })
end)

-- Stop all APIs
RegisterNetEvent('ec_admin:host:stopAllAPIs', function()
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api.control') then
        TriggerClientEvent('ec_admin:client:showNotification', source, {
            type = 'error',
            title = 'Access Denied',
            message = 'You do not have permission to control APIs'
        })
        return
    end
    
    local success, message = exports['ec_admin_ultimate']:StopAllAPIs(source)
    
    TriggerClientEvent('ec_admin:client:showNotification', source, {
        type = success and 'success' or 'error',
        title = success and 'Stopping All APIs' or 'Error',
        message = message
    })
    
    -- Send webhook notification (critical action)
    exports['ec_admin_ultimate']:TriggerHostWebhook('api_bulk_action', {
        action = 'stop_all',
        admin = GetPlayerName(source),
        timestamp = os.time(),
        severity = 'critical'
    })
end)

-- Restart all APIs
RegisterNetEvent('ec_admin:host:restartAllAPIs', function()
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api.control') then
        TriggerClientEvent('ec_admin:client:showNotification', source, {
            type = 'error',
            title = 'Access Denied',
            message = 'You do not have permission to control APIs'
        })
        return
    end
    
    local success, message = exports['ec_admin_ultimate']:RestartAllAPIs(source)
    
    TriggerClientEvent('ec_admin:client:showNotification', source, {
        type = success and 'success' or 'error',
        title = success and 'Restarting All APIs' or 'Error',
        message = message
    })
    
    -- Send webhook notification
    exports['ec_admin_ultimate']:TriggerHostWebhook('api_bulk_action', {
        action = 'restart_all',
        admin = GetPlayerName(source),
        timestamp = os.time(),
        severity = 'high'
    })
end)

-- Clear API logs
RegisterNetEvent('ec_admin:host:clearAPILogs', function(data)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api.logs') then
        TriggerClientEvent('ec_admin:client:showNotification', source, {
            type = 'error',
            title = 'Access Denied',
            message = 'You do not have permission to manage API logs'
        })
        return
    end
    
    local apiKey = data.apiKey
    if not apiKey then
        return
    end
    
    local success, message = exports['ec_admin_ultimate']:ClearAPILogs(apiKey, source)
    
    TriggerClientEvent('ec_admin:client:showNotification', source, {
        type = success and 'success' or 'error',
        title = success and 'Logs Cleared' or 'Error',
        message = message
    })
end)

Logger.Success('Host API Management Actions loaded', '⚙️')
