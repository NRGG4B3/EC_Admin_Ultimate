--[[
    EC Admin Ultimate - Admin Profile NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callbacks and forward to server
RegisterNUICallback('getAdminProfileFull', function(data, cb)
    local adminId = data.adminId or data.admin_id or data
    if type(adminId) == 'table' then
        adminId = adminId.adminId or adminId.admin_id
    end
    if not adminId or adminId == '' then
        cb({ success = false, error = 'Admin ID is required' })
        return
    end
    
    lib.callback('ec_admin:getAdminProfileFull', false, function(response)
        if response and response.success then
            -- Return data directly (without success wrapper) for the wrapper function
            cb(response)
        else
            cb(response or { success = false, error = 'No response from server' })
        end
    end, adminId)
end)

RegisterNUICallback('updateAdminProfile', function(data, cb)
    lib.callback('ec_admin:updateAdminProfile', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('updateAdminPassword', function(data, cb)
    lib.callback('ec_admin:updateAdminPassword', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('updateAdminPreferences', function(data, cb)
    lib.callback('ec_admin:updateAdminPreferences', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('endAdminSession', function(data, cb)
    lib.callback('ec_admin:endAdminSession', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('clearAdminActivity', function(data, cb)
    lib.callback('ec_admin:clearAdminActivity', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('exportAdminProfile', function(data, cb)
    lib.callback('ec_admin:exportAdminProfile', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

