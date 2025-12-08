--[[
    EC Admin Ultimate - Testing Checklist NUI Bridge
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
        print(string.format("^1[NUI Testing Checklist]^7 Error in %s: %s^0", callbackName, tostring(response)))
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end

-- Register NUI callbacks and forward to server with error handling
RegisterNUICallback('testing:getChecklist', function(data, cb)
    safeCallback('testing:getChecklist', 'ec_admin:testing:getChecklist', data, cb)
end)

RegisterNUICallback('testing:updateItem', function(data, cb)
    safeCallback('testing:updateItem', 'ec_admin:testing:updateItem', data, cb)
end)

RegisterNUICallback('testing:getProgress', function(data, cb)
    safeCallback('testing:getProgress', 'ec_admin:testing:getProgress', data, cb)
end)

RegisterNUICallback('testing:resetProgress', function(data, cb)
    safeCallback('testing:resetProgress', 'ec_admin:testing:resetProgress', data, cb)
end)
