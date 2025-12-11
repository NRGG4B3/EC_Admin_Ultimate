--[[
    EC Admin Ultimate - Topbar NUI Bridge
    Client-side bridge for topbar callbacks
]]

-- Register NUI callback: topbar:getAdminProfile
RegisterNUICallback('topbar:getAdminProfile', function(data, cb)
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await('ec_admin:topbar:getAdminProfile', false, data)
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print("^1[NUI Topbar]^7 Error in topbar:getAdminProfile: " .. tostring(response) .. "^0")
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end)

-- Register NUI callback: topbar:getQuickStats
RegisterNUICallback('topbar:getQuickStats', function(data, cb)
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await('ec_admin:topbar:getQuickStats', false, data)
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print("^1[NUI Topbar]^7 Error in topbar:getQuickStats: " .. tostring(response) .. "^0")
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end)

print("^2[NUI Topbar]^7 Topbar bridge loaded^0")
