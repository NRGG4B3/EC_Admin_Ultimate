--[[
    EC Admin Ultimate - Host Dashboard NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callbacks and forward to server
RegisterNUICallback('getHostSystemStats', function(data, cb)
    lib.callback('ec_admin:getHostSystemStats', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getHostAPIStatuses', function(data, cb)
    lib.callback('ec_admin:getHostAPIStatuses', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getConnectedCities', function(data, cb)
    lib.callback('ec_admin:getConnectedCities', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getGlobalBans', function(data, cb)
    lib.callback('ec_admin:getGlobalBans', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getBanAppeals', function(data, cb)
    lib.callback('ec_admin:getBanAppeals', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getGlobalWarnings', function(data, cb)
    lib.callback('ec_admin:getGlobalWarnings', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getHostWebhooks', function(data, cb)
    lib.callback('ec_admin:getHostWebhooks', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getSystemLogs', function(data, cb)
    lib.callback('ec_admin:getSystemLogs', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getHostActionLogs', function(data, cb)
    lib.callback('ec_admin:getHostActionLogs', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPerformanceMetrics', function(data, cb)
    lib.callback('ec_admin:getPerformanceMetrics', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getSalesProjections', function(data, cb)
    lib.callback('ec_admin:getSalesProjections', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

-- Host API management
RegisterNUICallback('startHostAPI', function(data, cb)
    lib.callback('ec_admin:startHostAPI', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('stopHostAPI', function(data, cb)
    lib.callback('ec_admin:stopHostAPI', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('restartHostAPI', function(data, cb)
    lib.callback('ec_admin:restartHostAPI', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('startAllHostAPIs', function(data, cb)
    lib.callback('ec_admin:startAllHostAPIs', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('stopAllHostAPIs', function(data, cb)
    lib.callback('ec_admin:stopAllHostAPIs', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

-- Global ban management
RegisterNUICallback('removeGlobalBan', function(data, cb)
    lib.callback('ec_admin:removeGlobalBan', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('processBanAppeal', function(data, cb)
    lib.callback('ec_admin:processBanAppeal', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

-- Global warnings
RegisterNUICallback('issueGlobalWarning', function(data, cb)
    lib.callback('ec_admin:issueGlobalWarning', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('removeGlobalWarning', function(data, cb)
    lib.callback('ec_admin:removeGlobalWarning', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

-- Webhook management
RegisterNUICallback('testHostWebhook', function(data, cb)
    lib.callback('ec_admin:testHostWebhook', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('toggleHostWebhook', function(data, cb)
    lib.callback('ec_admin:toggleHostWebhook', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('updateHostWebhook', function(data, cb)
    lib.callback('ec_admin:updateHostWebhook', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('createHostWebhook', function(data, cb)
    lib.callback('ec_admin:createHostWebhook', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('deleteHostWebhook', function(data, cb)
    lib.callback('ec_admin:deleteHostWebhook', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

-- System management
RegisterNUICallback('resolveSystemAlert', function(data, cb)
    lib.callback('ec_admin:resolveSystemAlert', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('disconnectCity', function(data, cb)
    lib.callback('ec_admin:disconnectCity', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

