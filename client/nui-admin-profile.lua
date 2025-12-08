--[[
    EC Admin Ultimate - Admin Profile NUI Bridge
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
        print(string.format("^1[NUI Admin Profile]^7 Error in %s: %s^0", callbackName, tostring(response)))
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end

-- Register NUI callbacks and forward to server with error handling
RegisterNUICallback('getAdminProfileFull', function(data, cb)
    local adminId = data.adminId or data.admin_id or data
    if type(adminId) == 'table' then
        adminId = adminId.adminId or adminId.admin_id
    end
    if not adminId or adminId == '' then
        cb({ success = false, error = 'Admin ID is required' })
        return
    end
    
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await('ec_admin:getAdminProfileFull', false, adminId)
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print("^1[NUI Admin Profile]^7 Error in getAdminProfileFull: " .. tostring(response) .. "^0")
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        if response and response.success then
            cb(response)
        else
            cb(response or { success = false, error = 'No response from server' })
        end
    end
end)

RegisterNUICallback('updateAdminProfile', function(data, cb)
    safeCallback('updateAdminProfile', 'ec_admin:updateAdminProfile', data, cb)
end)

RegisterNUICallback('updateAdminPassword', function(data, cb)
    safeCallback('updateAdminPassword', 'ec_admin:updateAdminPassword', data, cb)
end)

RegisterNUICallback('updateAdminPreferences', function(data, cb)
    safeCallback('updateAdminPreferences', 'ec_admin:updateAdminPreferences', data, cb)
end)

RegisterNUICallback('endAdminSession', function(data, cb)
    safeCallback('endAdminSession', 'ec_admin:endAdminSession', data, cb)
end)

RegisterNUICallback('clearAdminActivity', function(data, cb)
    safeCallback('clearAdminActivity', 'ec_admin:clearAdminActivity', data, cb)
end)

RegisterNUICallback('exportAdminProfile', function(data, cb)
    safeCallback('exportAdminProfile', 'ec_admin:exportAdminProfile', data, cb)
end)

