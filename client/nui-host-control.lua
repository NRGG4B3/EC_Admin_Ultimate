--[[
    EC Admin Ultimate - Host Control NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callbacks and forward to server
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

RegisterNUICallback('getHostSystemStats', function(data, cb)
    lib.callback('ec_admin:getHostSystemStats', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

