--[[
    EC Admin Ultimate - Host Management NUI Bridge
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
        print(string.format("^1[NUI Host Management]^7 Error in %s: %s^0", callbackName, tostring(response)))
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end

-- Register NUI callbacks and forward to server with error handling
RegisterNUICallback('getHostSystemStats', function(data, cb)
    safeCallback('getHostSystemStats', 'ec_admin:getHostSystemStats', data, cb)
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

RegisterNUICallback('getHostActionLogs', function(data, cb)
    safeCallback('getHostActionLogs', 'ec_admin:getHostActionLogs', data, cb)
end)

RegisterNUICallback('getSystemLogs', function(data, cb)
    safeCallback('getSystemLogs', 'ec_admin:getSystemLogs', data, cb)
end)

RegisterNUICallback('getPerformanceMetrics', function(data, cb)
    safeCallback('getPerformanceMetrics', 'ec_admin:getPerformanceMetrics', data, cb)
end)

