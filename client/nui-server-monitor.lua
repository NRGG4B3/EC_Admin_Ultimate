--[[
    EC Admin Ultimate - Server Monitor NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callbacks and forward to server
RegisterNUICallback('getServerMetrics', function(data, cb)
    lib.callback('ec_admin:getServerMetrics', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getNetworkMetrics', function(data, cb)
    lib.callback('ec_admin:getNetworkMetrics', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getResources', function(data, cb)
    lib.callback('ec_admin:getResources', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getDatabaseMetrics', function(data, cb)
    lib.callback('ec_admin:getDatabaseMetrics', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPlayerPositions', function(data, cb)
    lib.callback('ec_admin:getPlayerPositions', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('restartResource', function(data, cb)
    lib.callback('ec_admin:restartResource', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

