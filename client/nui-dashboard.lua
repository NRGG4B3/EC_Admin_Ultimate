--[[
    EC Admin Ultimate - Dashboard NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callbacks and forward to server
RegisterNUICallback('getServerMetrics', function(data, cb)
    lib.callback('ec_admin:getServerMetrics', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end)
end)

RegisterNUICallback('getMetricsHistory', function(data, cb)
    lib.callback('ec_admin:getMetricsHistory', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end)
end)

