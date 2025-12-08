--[[
    EC Admin Ultimate - Economy & Global Tools NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
    
    Note: economy:getData and server:getSettings are handled directly by RegisterNUICallback
    on the server side. Only globaltools/execute uses fetchNui and needs this bridge.
]]

-- Register NUI callback for globaltools/execute (uses fetchNui from UI)
RegisterNUICallback('globaltools/execute', function(data, cb)
    lib.callback('ec_admin:executeGlobalTool', false, function(response)
        cb(response or { success = false, message = 'No response from server' })
    end, data)
end)

