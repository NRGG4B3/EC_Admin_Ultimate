--[[
    EC Admin Ultimate - Host Dashboard NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Helper: Safe callback wrapper
local function safeCallback(callbackName, serverCallback, data, cb)
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await(serverCallback, false, data)
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print(string.format("^1[NUI Host Dashboard]^7 Error in %s: %s^0", callbackName, tostring(response)))
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end

-- Register NUI callbacks and forward to server with error handling
RegisterNUICallback('getHostSystemStats', function(data, cb)
    safeCallback('getHostSystemStats', 'ec_admin:getHostSystemStats', data, cb)
end)

RegisterNUICallback('getHostAPIStatuses', function(data, cb)
    safeCallback('getHostAPIStatuses', 'ec_admin:getHostAPIStatuses', data, cb)
end)

RegisterNUICallback('getConnectedCities', function(data, cb)
    safeCallback('getConnectedCities', 'ec_admin:getConnectedCities', data, cb)
end)

RegisterNUICallback('getGlobalBans', function(data, cb)
    safeCallback('getGlobalBans', 'ec_admin:getGlobalBans', data, cb)
end)

RegisterNUICallback('getBanAppeals', function(data, cb)
    safeCallback('getBanAppeals', 'ec_admin:getBanAppeals', data, cb)
end)

RegisterNUICallback('getGlobalWarnings', function(data, cb)
    safeCallback('getGlobalWarnings', 'ec_admin:getGlobalWarnings', data, cb)
end)

RegisterNUICallback('getHostWebhooks', function(data, cb)
    safeCallback('getHostWebhooks', 'ec_admin:getHostWebhooks', data, cb)
end)

RegisterNUICallback('getSystemLogs', function(data, cb)
    safeCallback('getSystemLogs', 'ec_admin:getSystemLogs', data, cb)
end)

RegisterNUICallback('getHostActionLogs', function(data, cb)
    safeCallback('getHostActionLogs', 'ec_admin:getHostActionLogs', data, cb)
end)

RegisterNUICallback('getPerformanceMetrics', function(data, cb)
    safeCallback('getPerformanceMetrics', 'ec_admin:getPerformanceMetrics', data, cb)
end)

RegisterNUICallback('getSalesProjections', function(data, cb)
    safeCallback('getSalesProjections', 'ec_admin:getSalesProjections', data, cb)
end)

-- Host API management
RegisterNUICallback('startHostAPI', function(data, cb)
    safeCallback('startHostAPI', 'ec_admin:startHostAPI', data, cb)
end)

RegisterNUICallback('stopHostAPI', function(data, cb)
    safeCallback('stopHostAPI', 'ec_admin:stopHostAPI', data, cb)
end)

RegisterNUICallback('restartHostAPI', function(data, cb)
    safeCallback('restartHostAPI', 'ec_admin:restartHostAPI', data, cb)
end)

RegisterNUICallback('startAllHostAPIs', function(data, cb)
    safeCallback('startAllHostAPIs', 'ec_admin:startAllHostAPIs', data, cb)
end)

RegisterNUICallback('stopAllHostAPIs', function(data, cb)
    safeCallback('stopAllHostAPIs', 'ec_admin:stopAllHostAPIs', data, cb)
end)

-- Global ban management
RegisterNUICallback('removeGlobalBan', function(data, cb)
    safeCallback('removeGlobalBan', 'ec_admin:removeGlobalBan', data, cb)
end)

RegisterNUICallback('processBanAppeal', function(data, cb)
    safeCallback('processBanAppeal', 'ec_admin:processBanAppeal', data, cb)
end)

-- Global warnings
RegisterNUICallback('issueGlobalWarning', function(data, cb)
    safeCallback('issueGlobalWarning', 'ec_admin:issueGlobalWarning', data, cb)
end)

RegisterNUICallback('removeGlobalWarning', function(data, cb)
    safeCallback('removeGlobalWarning', 'ec_admin:removeGlobalWarning', data, cb)
end)

-- Webhook management
RegisterNUICallback('testHostWebhook', function(data, cb)
    safeCallback('testHostWebhook', 'ec_admin:testHostWebhook', data, cb)
end)

RegisterNUICallback('toggleHostWebhook', function(data, cb)
    safeCallback('toggleHostWebhook', 'ec_admin:toggleHostWebhook', data, cb)
end)

RegisterNUICallback('updateHostWebhook', function(data, cb)
    safeCallback('updateHostWebhook', 'ec_admin:updateHostWebhook', data, cb)
end)

RegisterNUICallback('createHostWebhook', function(data, cb)
    safeCallback('createHostWebhook', 'ec_admin:createHostWebhook', data, cb)
end)

RegisterNUICallback('deleteHostWebhook', function(data, cb)
    safeCallback('deleteHostWebhook', 'ec_admin:deleteHostWebhook', data, cb)
end)

-- System management
RegisterNUICallback('resolveSystemAlert', function(data, cb)
    safeCallback('resolveSystemAlert', 'ec_admin:resolveSystemAlert', data, cb)
end)

RegisterNUICallback('disconnectCity', function(data, cb)
    safeCallback('disconnectCity', 'ec_admin:disconnectCity', data, cb)
end)

