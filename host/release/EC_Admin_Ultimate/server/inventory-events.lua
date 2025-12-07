--[[
    EC Admin Ultimate - Inventory Server Events
    Server-side implementation for inventory management
]]

Logger.Info('')

local function HasPermission(src, permission)
    return IsPlayerAceAllowed(src, 'ec_admin.' .. permission) or 
           IsPlayerAceAllowed(src, 'ec_admin.all')
end

local function GetFramework()
    if GetResourceState('qbx_core') == 'started' then
        return 'qbx', exports['qbx_core']:GetCoreObject()
    elseif GetResourceState('qb-core') == 'started' then
        return 'qb', exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx', exports['es_extended']:getSharedObject()
    end
    return nil, nil
end

RegisterNetEvent('ec:inventory:getPlayerInventory', function(data)
    local src = source
    
    if not HasPermission(src, 'inventory.view') then
        return
    end
    
    local targetId = data.playerId
    local fwType, fw = GetFramework()
    local inventory = {}
    
    if fwType == 'qbx' or fwType == 'qb' then
        local Player = fw.Functions.GetPlayer(targetId)
        if Player then
            inventory = Player.PlayerData.items or {}
        end
    elseif fwType == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            inventory = xPlayer.getInventory()
        end
    end
    
    TriggerClientEvent('ec:inventory:getPlayerInventoryResponse', src, inventory)
end)

RegisterNetEvent('ec:inventory:giveItem', function(data)
    local src = source
    
    if not HasPermission(src, 'inventory.give') then
        return
    end
    
    local targetId = data.playerId
    local itemName = data.item
    local amount = data.amount or 1
    
    local fwType, fw = GetFramework()
    
    if fwType == 'qbx' or fwType == 'qb' then
        local Player = fw.Functions.GetPlayer(targetId)
        if Player then
            Player.Functions.AddItem(itemName, amount)
            Logger.Info(string.format('', 
                src, amount, itemName, targetId))
        end
    elseif fwType == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            xPlayer.addInventoryItem(itemName, amount)
        end
    end
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Item Given',
        description = string.format('Gave %dx %s', amount, itemName),
        type = 'success'
    })
end)

RegisterNetEvent('ec:inventory:removeItem', function(data)
    local src = source
    
    if not HasPermission(src, 'inventory.remove') then
        return
    end
    
    local targetId = data.playerId
    local itemName = data.item
    local amount = data.amount or 1
    
    local fwType, fw = GetFramework()
    
    if fwType == 'qbx' or fwType == 'qb' then
        local Player = fw.Functions.GetPlayer(targetId)
        if Player then
            Player.Functions.RemoveItem(itemName, amount)
            Logger.Info(string.format('', 
                src, amount, itemName, targetId))
        end
    elseif fwType == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            xPlayer.removeInventoryItem(itemName, amount)
        end
    end
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Item Removed',
        description = string.format('Removed %dx %s', amount, itemName),
        type = 'success'
    })
end)

RegisterNetEvent('ec:inventory:clearInventory', function(data)
    local src = source
    
    if not HasPermission(src, 'inventory.clear') then
        return
    end
    
    local targetId = data.playerId
    local fwType, fw = GetFramework()
    
    if fwType == 'qbx' or fwType == 'qb' then
        local Player = fw.Functions.GetPlayer(targetId)
        if Player then
            Player.Functions.ClearInventory()
            Logger.Info(string.format('', src, targetId))
        end
    elseif fwType == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            for _, item in pairs(xPlayer.getInventory()) do
                if item.count > 0 then
                    xPlayer.setInventoryItem(item.name, 0)
                end
            end
        end
    end
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Inventory Cleared',
        description = 'Player inventory has been cleared',
        type = 'success'
    })
end)

RegisterNetEvent('ec:inventory:getItems', function(data)
    local src = source
    
    if not HasPermission(src, 'inventory.view') then
        return
    end
    
    local fwType, fw = GetFramework()
    local items = {}
    
    if fwType == 'qbx' or fwType == 'qb' then
        items = fw.Shared.Items or {}
    elseif fwType == 'esx' then
        items = ESX.GetItems() or {}
    end
    
    TriggerClientEvent('ec:inventory:getItemsResponse', src, items)
end)

Logger.Info('')