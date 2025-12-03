-- EC Admin Ultimate - Host Control NUI Callbacks
-- Bridges UI host-control actions to server callbacks; active only for Host users

-- Host service action (start/stop/restart)
-- Deprecated: legacy hostServiceAction. Use 'controlAPI' from UI.
RegisterNUICallback('hostServiceAction', function(data, cb)
    local result = lib.callback.await('ec_admin:host:controlAPI', false, {
        apiName = data.service,
        action = data.action,
        params = data.params
    })
    cb(result or { success = false, error = 'No response from server' })
end)

-- Host uninstall service
RegisterNUICallback('hostUninstallService', function(data, cb)
    local result = lib.callback.await('ec_admin:host:controlAPI', false, {
        apiName = data.service,
        action = 'uninstall'
    })
    cb(result or { success = false, error = 'No response from server' })
end)

-- Host toggle web admin
RegisterNUICallback('hostToggleWebAdmin', function(data, cb)
    local result = lib.callback.await('ec_admin:host:controlAPI', false, {
        apiName = 'web-admin',
        action = data.enabled and 'enable' or 'disable'
    })
    cb(result or { success = false, error = 'No response from server' })
end)

-- Host get logs
RegisterNUICallback('hostGetLogs', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getAPILogs', false, {
        apiName = data.service,
        filters = data.filters
    })
    cb(result or { success = false, error = 'No response from server' })
end)

if Logger and Logger.Info then
    Logger.Info('[Host Control] NUI callbacks registered')
else
    print('^2[Host Control] NUI callbacks registered^0')
end

-- New UI endpoints used by pages/host-control.tsx
RegisterNUICallback('controlAPI', function(data, cb)
    local result = lib.callback.await('ec_admin:host:controlAPI', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('executeCityCommand', function(data, cb)
    local result = lib.callback.await('ec_admin:host:executeCityCommand', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('emergencyStopAPI', function(data, cb)
    local result = lib.callback.await('ec_admin:host:emergencyStopAPI', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('restartAPI', function(data, cb)
    local result = lib.callback.await('ec_admin:host:restartAPI', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)