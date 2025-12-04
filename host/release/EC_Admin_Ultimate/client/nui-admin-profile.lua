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

Logger.Info('✅ Admin Profile NUI callbacks loaded')