-- EC Admin Ultimate - Host Control NUI Callbacks
-- Only active when Config.Role == 'host'

-- Host service action (start/stop/restart)
RegisterNUICallback('hostServiceAction', function(data, cb)
    local service = data.service
    local action = data.action
    
    print(string.format('^3[Host Control] Service action: %s %s^0', action, service))
    
    -- Forward to server
    TriggerServerEvent('ec_admin:host:serviceAction', service, action)
    
    cb({ success = true, message = string.format('%s %s initiated', service, action) })
end)

-- Host uninstall service
RegisterNUICallback('hostUninstallService', function(data, cb)
    local service = data.service
    
    print(string.format('^3[Host Control] Uninstall service: %s^0', service))
    
    -- Forward to server
    TriggerServerEvent('ec_admin:host:uninstallService', service)
    
    cb({ success = true, message = string.format('%s uninstall initiated', service) })
end)

-- Host toggle web admin
RegisterNUICallback('hostToggleWebAdmin', function(data, cb)
    local enabled = data.enabled
    
    print(string.format('^3[Host Control] Toggle web admin: %s^0', enabled and 'ENABLED' or 'DISABLED'))
    
    -- Forward to server (use the new event that triggers full toggle)
    TriggerServerEvent('ec_admin:host:toggleAdminMenu', enabled)
    
    cb({ success = true, message = string.format('Admin menu %s', enabled and 'enabled' or 'disabled') })
end)

-- Host get logs
RegisterNUICallback('hostGetLogs', function(data, cb)
    local service = data.service
    
    print(string.format('^3[Host Control] Get logs: %s^0', service))
    
    -- Return mock logs for now (would fetch real logs from server)
    cb({
        success = true,
        logs = {
            '[2025-11-07 10:30:15] Service started successfully',
            '[2025-11-07 10:30:16] Listening on assigned port',
            '[2025-11-07 10:30:20] Incoming request processed',
            '[2025-11-07 10:30:20] Response: 200 OK (12ms)',
            '[2025-11-07 10:31:05] Health check passed',
        }
    })
end)

print('^2[Host Control] NUI callbacks registered^0')