--[[
    EC Admin Ultimate - Quick Actions NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callback for quick actions
RegisterNUICallback('quickAction', function(data, cb)
    local action = data.action
    local actionData = data.data or {}
    
    if not action or action == '' then
        cb({ success = false, error = 'Action required' })
        return
    end
    
    -- Forward to server
    lib.callback('ec_admin:quickAction', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, { action = action, data = actionData })
end)

