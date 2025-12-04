--[[
    EC Admin Ultimate - Inventory NUI Callbacks (Client)
    Handles inventory management communication between NUI and server
]]

-- Get inventory data
RegisterNUICallback('inventory:getData', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getInventoryData', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:getInventoryData')
        cb({ success = true })
    end
end)

-- Get specific player inventory
RegisterNUICallback('inventory:getPlayerInventory', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getPlayerInventory', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:getPlayerInventory', data)
        cb({ success = true })
    end
end)

-- Give item to player
RegisterNUICallback('inventory:giveItem', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:giveItem', data)
    cb({ success = true })
end)

-- Remove item from player
RegisterNUICallback('inventory:removeItem', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:removeItem', data)
    cb({ success = true })
end)

-- Clear player inventory
RegisterNUICallback('inventory:clearInventory', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:clearInventory', data)
    cb({ success = true })
end)

-- Set item amount
RegisterNUICallback('inventory:setItemAmount', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:setItemAmount', data)
    cb({ success = true })
end)

-- Receive inventory data from server
RegisterNetEvent('ec_admin_ultimate:client:receiveInventoryData', function(result)
    SendNUIMessage({
        action = 'inventoryData',
        data = result
    })
end)

-- Receive player inventory from server
RegisterNetEvent('ec_admin_ultimate:client:receivePlayerInventory', function(result)
    SendNUIMessage({
        action = 'playerInventory',
        data = result
    })
end)

-- Receive inventory response
RegisterNetEvent('ec_admin_ultimate:client:inventoryResponse', function(result)
    SendNUIMessage({
        action = 'inventoryResponse',
        data = result
    })
end)

-- Receive inventory error
RegisterNetEvent('ec_admin_ultimate:client:inventoryError', function(message)
    SendNUIMessage({
        action = 'inventoryError',
        data = { message = message }
    })
end)

Logger.Info('Inventory NUI callbacks loaded')
