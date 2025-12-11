--[[
    EC Admin Ultimate - Economy & Global Tools NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
    
    Note: economy:getData and server:getSettings are handled directly by RegisterNUICallback
    on the server side. Only globaltools/execute uses fetchNui and needs this bridge.
]]

-- Register NUI callback for globaltools/execute with error handling
RegisterNUICallback('globaltools/execute', function(data, cb)
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await('ec_admin:executeGlobalTool', false, data)
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print("^1[NUI Economy Tools]^7 Error in globaltools/execute: " .. tostring(response) .. "^0")
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, message = 'No response from server' })
    end
end)

