--[[
    EC Admin Ultimate - Housing NUI Callbacks (Client)
    Handles housing management communication between NUI and server
]]

-- Get housing data
RegisterNUICallback('housing:getData', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getHousingData', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:getHousingData')
        cb({ success = true })
    end
end)

-- Transfer property
RegisterNUICallback('housing:transferProperty', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:transferProperty', data)
    cb({ success = true })
end)

-- Evict property
RegisterNUICallback('housing:evictProperty', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:evictProperty', data)
    cb({ success = true })
end)

-- Delete property
RegisterNUICallback('housing:deleteProperty', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:deleteProperty', data)
    cb({ success = true })
end)

-- Set property price
RegisterNUICallback('housing:setPropertyPrice', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:setPropertyPrice', data)
    cb({ success = true })
end)

-- Receive housing data from server
RegisterNetEvent('ec_admin_ultimate:client:receiveHousingData', function(result)
    SendNUIMessage({
        action = 'housingData',
        data = result
    })
end)

-- Receive housing response
RegisterNetEvent('ec_admin_ultimate:client:housingResponse', function(result)
    SendNUIMessage({
        action = 'housingResponse',
        data = result
    })
end)

Logger.Info('Housing NUI callbacks loaded')
