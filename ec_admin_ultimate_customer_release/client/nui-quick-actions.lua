--[[
    EC Admin Ultimate - Quick Actions NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callback for quick actions with error handling
RegisterNUICallback('quickAction', function(data, cb)
    local action = data.action
    local actionData = data.data or {}
    
    if not action or action == '' then
        cb({ success = false, error = 'Action required' })
        return
    end
    
    -- Forward to server with error handling
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await('ec_admin:quickAction', false, { action = action, data = actionData })
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print(string.format("^1[NUI Quick Actions]^7 Error in quickAction (%s): %s^0", action, tostring(response)))
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end)

