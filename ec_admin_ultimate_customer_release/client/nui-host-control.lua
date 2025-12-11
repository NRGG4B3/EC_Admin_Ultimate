--[[
    EC Admin Ultimate - Host Control NUI Bridge
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
        print(string.format("^1[NUI Host Control]^7 Error in %s: %s^0", callbackName, tostring(response)))
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end

-- Register NUI callbacks and forward to server with error handling
RegisterNUICallback('getHostAPIStatuses', function(data, cb)
    safeCallback('getHostAPIStatuses', 'ec_admin:getHostAPIStatuses', data, cb)
end)

RegisterNUICallback('getConnectedCities', function(data, cb)
    safeCallback('getConnectedCities', 'ec_admin:getConnectedCities', data, cb)
end)

RegisterNUICallback('getHostSystemStats', function(data, cb)
    safeCallback('getHostSystemStats', 'ec_admin:getHostSystemStats', data, cb)
end)

