--[[
    EC Admin Ultimate - Admin Abuse NUI Callbacks (CLIENT)
]]

Logger.Info('👁️ Admin Abuse tracking NUI callbacks loading...')

RegisterNUICallback('getAdminAbuse', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getAdminAbuse', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, logs = {}, stats = {} })
    end
end)

Logger.Info('✅ Admin Abuse tracking NUI callbacks loaded')
