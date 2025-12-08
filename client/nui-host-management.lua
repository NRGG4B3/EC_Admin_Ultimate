--[[
    EC Admin Ultimate - Host Management NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callbacks and forward to server
RegisterNUICallback('getHostSystemStats', function(data, cb)
    lib.callback('ec_admin:getHostSystemStats', false, function(response)
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

RegisterNUICallback('getHostActionLogs', function(data, cb)
    lib.callback('ec_admin:getHostActionLogs', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getSystemLogs', function(data, cb)
    lib.callback('ec_admin:getSystemLogs', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPerformanceMetrics', function(data, cb)
    lib.callback('ec_admin:getPerformanceMetrics', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

