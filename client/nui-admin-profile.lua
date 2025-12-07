--[[
    EC Admin Ultimate - Admin Profile NUI Callbacks (CLIENT)
]]

Logger.Info('👤 Admin Profile NUI callbacks loading...')


RegisterNUICallback('getAdminProfile', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('adminProfile:getData', false, data)
    end)
    if success and result then
        cb(result)
    else
        Logger.Info('⚠️ Failed to get admin profile:', result)
        cb({ success = false, message = 'Failed to fetch admin profile' })
    end
end)

RegisterNUICallback('updateAdminProfile', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('updateAdminProfile', false, data)
    end)
    cb(result)
end)

RegisterNUICallback('updateAdminPassword', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('updateAdminPassword', false, data)
    end)
    cb(result)
end)

RegisterNUICallback('updateAdminPreferences', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('updateAdminPreferences', false, data)
    end)
    cb(result)
end)

RegisterNUICallback('endAdminSession', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('endAdminSession', false, data)
    end)
    cb(result)
end)

RegisterNUICallback('clearAdminActivity', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('clearAdminActivity', false, data)
    end)
    cb(result)
end)

RegisterNUICallback('exportAdminProfile', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('exportAdminProfile', false, data)
    end)
    cb(result)
end)

Logger.Info('✅ Admin Profile NUI callbacks loaded')