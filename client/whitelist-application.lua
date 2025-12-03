-- EC Admin Ultimate - Client-Side Whitelist Application UI

-- NUI Callback: Open whitelist application form
RegisterNetEvent('ec-admin:whitelist:showApplication')
AddEventHandler('ec-admin:whitelist:showApplication', function()
    SendNUIMessage({
        type = 'showWhitelistApplication',
        data = {}
    })
    
    SetNuiFocus(true, true)
end)

-- Handle application submission from NUI
RegisterNUICallback('submitWhitelistApplication', function(data, cb)
    TriggerServerEvent('ec-admin:application:submit', data, function(result)
        cb(result)
        if result.success then
            SendNUIMessage({
                type = 'hideWhitelistApplication'
            })
            SetNuiFocus(false, false)
        end
    end)
end)

-- Close application UI
RegisterNUICallback('closeWhitelistApplication', function(data, cb)
    SendNUIMessage({
        type = 'hideWhitelistApplication'
    })
    SetNuiFocus(false, false)
    cb({ success = true })
end)

Logger.Info('✅ Whitelist Application System loaded', '📋')