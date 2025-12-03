-- EC Admin Ultimate - Host API Management NUI Callbacks
-- Client-side NUI callbacks for API management
-- Author: NRG Development
-- Version: 1.0.0

-- Get all API statuses
RegisterNUICallback('getHostAPIStatuses', function(data, cb)
    lib.callback('ec_admin:host:getAPIStatuses', false, function(statuses)
        cb(statuses or {})
    end)
end)

-- Get API logs
RegisterNUICallback('getHostAPILogs', function(data, cb)
    lib.callback('ec_admin:host:getAPILogs', false, function(logs)
        cb(logs or {})
    end, data)
end)

-- Get API metrics
RegisterNUICallback('getHostAPIMetrics', function(data, cb)
    lib.callback('ec_admin:host:getAPIMetrics', false, function(metrics)
        cb(metrics or {})
    end, data)
end)

-- Start API
RegisterNUICallback('startHostAPI', function(data, cb)
    TriggerServerEvent('ec_admin:host:startAPI', data)
    cb({ success = true })
end)

-- Stop API
RegisterNUICallback('stopHostAPI', function(data, cb)
    TriggerServerEvent('ec_admin:host:stopAPI', data)
    cb({ success = true })
end)

-- Restart API
RegisterNUICallback('restartHostAPI', function(data, cb)
    TriggerServerEvent('ec_admin:host:restartAPI', data)
    cb({ success = true })
end)

-- Toggle API auto-restart
RegisterNUICallback('toggleAPIAutoRestart', function(data, cb)
    TriggerServerEvent('ec_admin:host:toggleAPIAutoRestart', data)
    cb({ success = true })
end)

-- Start all APIs
RegisterNUICallback('startAllHostAPIs', function(data, cb)
    TriggerServerEvent('ec_admin:host:startAllAPIs')
    cb({ success = true })
end)

-- Stop all APIs
RegisterNUICallback('stopAllHostAPIs', function(data, cb)
    TriggerServerEvent('ec_admin:host:stopAllAPIs')
    cb({ success = true })
end)

-- Restart all APIs
RegisterNUICallback('restartAllHostAPIs', function(data, cb)
    TriggerServerEvent('ec_admin:host:restartAllAPIs')
    cb({ success = true })
end)

-- Clear API logs
RegisterNUICallback('clearHostAPILogs', function(data, cb)
    TriggerServerEvent('ec_admin:host:clearAPILogs', data)
    cb({ success = true })
end)

-- Get API health summary
RegisterNUICallback('getHostAPIHealthSummary', function(data, cb)
    lib.callback('ec_admin:host:getAPIHealthSummary', false, function(summary)
        if type(summary) == 'table' and summary.success == nil and summary[1] == nil then
            summary.success = true
        end
        cb(summary or { success = true })
    end)
end)

print('[EC Admin Ultimate] Host API Management NUI Callbacks loaded')
