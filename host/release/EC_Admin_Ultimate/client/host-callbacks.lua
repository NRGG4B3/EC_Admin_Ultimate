-- EC Admin Ultimate - Host Control Callbacks (Client)
-- All callbacks for fetching host data
-- Author: NRG Development
-- Version: 1.0.0

-- Note: This file registers client-side event handlers for host data
-- The actual callbacks are registered on the server side

-- Handle host mode status update from server
RegisterNetEvent('ec_admin:host:statusUpdate', function(status)
    SendNUIMessage({
        action = 'hostStatusUpdate',
        data = status
    })
end)

-- Handle API status update
RegisterNetEvent('ec_admin:host:apiStatusUpdate', function(apiName, status)
    SendNUIMessage({
        action = 'apiStatusUpdate',
        data = {
            apiName = apiName,
            status = status
        }
    })
end)

-- Handle city connection update
RegisterNetEvent('ec_admin:host:cityConnectionUpdate', function(cityId, status)
    SendNUIMessage({
        action = 'cityConnectionUpdate',
        data = {
            cityId = cityId,
            status = status
        }
    })
end)

-- Handle API control result
RegisterNetEvent('ec_admin:host:controlResult', function(success, message, apiName, action)
    SendNUIMessage({
        action = 'apiControlResult',
        data = {
            success = success,
            message = message,
            apiName = apiName,
            action = action
        }
    })
    
    if success then
        exports['ec_admin_ultimate']:toastSuccess(message or 'API action completed')
    else
        exports['ec_admin_ultimate']:toastError(message or 'API action failed')
    end
end)

-- Handle city command result
RegisterNetEvent('ec_admin:host:cityCommandResult', function(success, message, cityId, command)
    SendNUIMessage({
        action = 'cityCommandResult',
        data = {
            success = success,
            message = message,
            cityId = cityId,
            command = command
        }
    })
    
    if success then
        exports['ec_admin_ultimate']:toastSuccess(message or 'City command executed')
    else
        exports['ec_admin_ultimate']:toastError(message or 'City command failed')
    end
end)

-- Handle global stats update
RegisterNetEvent('ec_admin:host:globalStatsUpdate', function(stats)
    SendNUIMessage({
        action = 'globalStatsUpdate',
        data = stats
    })
end)

-- Handle API alert
RegisterNetEvent('ec_admin:host:apiAlert', function(alert)
    SendNUIMessage({
        action = 'apiAlert',
        data = alert
    })
    
    -- Show notification for critical alerts
    if alert.severity == 'critical' or alert.severity == 'high' then
        exports['ec_admin_ultimate']:toastError(alert.message)
    end
end)

-- Handle city alert
RegisterNetEvent('ec_admin:host:cityAlert', function(alert)
    SendNUIMessage({
        action = 'cityAlert',
        data = alert
    })
    
    if alert.severity == 'critical' then
        exports['ec_admin_ultimate']:toastError(alert.message)
    end
end)

-- Handle real-time API metrics update
RegisterNetEvent('ec_admin:host:metricsUpdate', function(apiName, metrics)
    SendNUIMessage({
        action = 'apiMetricsUpdate',
        data = {
            apiName = apiName,
            metrics = metrics
        }
    })
end)

-- Handle API log entry
RegisterNetEvent('ec_admin:host:newLogEntry', function(apiName, logEntry)
    SendNUIMessage({
        action = 'apiNewLog',
        data = {
            apiName = apiName,
            log = logEntry
        }
    })
end)

-- Handle city data update
RegisterNetEvent('ec_admin:host:cityDataUpdate', function(cityId, data)
    SendNUIMessage({
        action = 'cityDataUpdate',
        data = {
            cityId = cityId,
            data = data
        }
    })
end)

-- Handle emergency shutdown notification
RegisterNetEvent('ec_admin:host:emergencyShutdown', function(apiName, reason)
    SendNUIMessage({
        action = 'emergencyShutdown',
        data = {
            apiName = apiName,
            reason = reason
        }
    })
    
    exports['ec_admin_ultimate']:toastError('Emergency shutdown: ' .. apiName .. ' - ' .. reason)
end)

-- Handle API restart notification
RegisterNetEvent('ec_admin:host:apiRestarted', function(apiName)
    SendNUIMessage({
        action = 'apiRestarted',
        data = {
            apiName = apiName
        }
    })
    
    exports['ec_admin_ultimate']:toastSuccess('API restarted: ' .. apiName)
end)

-- Handle config update confirmation
RegisterNetEvent('ec_admin:host:configUpdated', function(apiName)
    SendNUIMessage({
        action = 'apiConfigUpdated',
        data = {
            apiName = apiName
        }
    })
    
    exports['ec_admin_ultimate']:toastSuccess('API config updated: ' .. apiName)
end)

Logger.Info('🏢 Host Control callbacks loaded')
