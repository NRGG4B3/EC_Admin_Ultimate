--[[
    EC Admin Ultimate - Dashboard NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callbacks and forward to server with error handling
RegisterNUICallback('getServerMetrics', function(data, cb)
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await('ec_admin:getServerMetrics', false, data)
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print("^1[NUI Dashboard]^7 Error in getServerMetrics: " .. tostring(response) .. "^0")
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end)

RegisterNUICallback('getMetricsHistory', function(data, cb)
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await('ec_admin:getMetricsHistory', false, data)
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print("^1[NUI Dashboard]^7 Error in getMetricsHistory: " .. tostring(response) .. "^0")
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end)

