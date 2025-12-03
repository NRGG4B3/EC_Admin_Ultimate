--[[
    EC Admin Ultimate - Enhanced Settings NUI Callbacks (Client)
]]

-- Get settings
RegisterNUICallback('settings:getData', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getSettings', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:getSettings')
        cb({ success = true })
    end
end)

-- Save settings
RegisterNUICallback('settings:save', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:saveSettings', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:saveSettings', data)
        cb({ success = true })
    end
end)

-- Save webhooks
RegisterNUICallback('settings:saveWebhooks', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:saveWebhooks', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:saveWebhooks', data)
        cb({ success = true })
    end
end)

-- Test webhook
RegisterNUICallback('settings:testWebhook', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:testWebhook', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:testWebhook', data)
        cb({ success = true })
    end
end)

-- Reset settings
RegisterNUICallback('settings:reset', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:resetSettings', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:resetSettings', data)
        cb({ success = true })
    end
end)

-- Receive settings data
RegisterNetEvent('ec_admin_ultimate:client:receiveSettings', function(result)
    SendNUIMessage({
        action = 'settingsData',
        data = result
    })
end)

-- Receive settings response
RegisterNetEvent('ec_admin_ultimate:client:settingsResponse', function(result)
    SendNUIMessage({
        action = 'settingsResponse',
        data = result
    })
end)

Logger.Info('Enhanced Settings NUI callbacks loaded')
