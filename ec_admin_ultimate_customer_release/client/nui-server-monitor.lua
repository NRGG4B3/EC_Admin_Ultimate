--[[
    EC Admin Ultimate - Server Monitor NUI Bridge
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
        print(string.format("^1[NUI Server Monitor]^7 Error in %s: %s^0", callbackName, tostring(response)))
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end

-- Register NUI callbacks and forward to server with error handling
RegisterNUICallback('getServerMetrics', function(data, cb)
    safeCallback('getServerMetrics', 'ec_admin:getServerMetrics', data, cb)
end)

RegisterNUICallback('getNetworkMetrics', function(data, cb)
    safeCallback('getNetworkMetrics', 'ec_admin:getNetworkMetrics', data, cb)
end)

RegisterNUICallback('getResources', function(data, cb)
    safeCallback('getResources', 'ec_admin:getResources', data, cb)
end)

RegisterNUICallback('getDatabaseMetrics', function(data, cb)
    safeCallback('getDatabaseMetrics', 'ec_admin:getDatabaseMetrics', data, cb)
end)

RegisterNUICallback('getPlayerPositions', function(data, cb)
    safeCallback('getPlayerPositions', 'ec_admin:getPlayerPositions', data, cb)
end)

RegisterNUICallback('restartResource', function(data, cb)
    safeCallback('restartResource', 'ec_admin:restartResource', data, cb)
end)

