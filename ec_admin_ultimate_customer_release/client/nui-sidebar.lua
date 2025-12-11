--[[
    EC Admin Ultimate - Sidebar NUI Bridge
    Client-side bridge for sidebar callbacks
]]

-- Register NUI callback: sidebar:getSystemInfo
RegisterNUICallback('sidebar:getSystemInfo', function(data, cb)
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await('ec_admin:sidebar:getSystemInfo', false, data)
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print("^1[NUI Sidebar]^7 Error in sidebar:getSystemInfo: " .. tostring(response) .. "^0")
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end)

print("^2[NUI Sidebar]^7 Sidebar bridge loaded^0")
