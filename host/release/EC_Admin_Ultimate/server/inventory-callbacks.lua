--[[
    EC Admin Ultimate - Inventory Management Callbacks
    Handles all inventory operations with multi-framework support
    Supports: QB-Core, QBX, ox_inventory, ESX
]]

local QBCore = nil
local ESX = nil
local InventorySystem = 'unknown'
local Framework = 'unknown'

-- Initialize framework
CreateThread(function()
    if GetResourceState('qbx_core') == 'started' then
        QBCore = exports.qbx_core
        Framework = 'qbx'
        
        -- Detect inventory system
        if GetResourceState('ox_inventory') == 'started' then
            InventorySystem = 'ox_inventory'
        elseif GetResourceState('ps-inventory') == 'started' then
            InventorySystem = 'ps-inventory'
        elseif GetResourceState('qb-inventory') == 'started' then
            InventorySystem = 'qb-inventory'
        else
            InventorySystem = 'qbx-core'
        end
        
        Logger.Debug('Detected QBX framework with inventory system: ' .. InventorySystem)
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb-core'
        
        -- Detect inventory system
        if GetResourceState('ox_inventory') == 'started' then
            InventorySystem = 'ox_inventory'
        elseif GetResourceState('ps-inventory') == 'started' then
            InventorySystem = 'ps-inventory'
        elseif GetResourceState('qb-inventory') == 'started' then
            InventorySystem = 'qb-inventory'
        else
            InventorySystem = 'qb-core'
        end
        
        Logger.Debug('Detected QB-Core framework with inventory system: ' .. InventorySystem)
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
        InventorySystem = 'esx'
        Logger.Debug('Detected ESX inventory system')
    end
end)

-- Get all items from shared items
local function GetAllItems()
    local items = {}
    
    if QBCore then
        -- QBX uses exports, QB-Core uses QBCore.Shared
        local QBItems = nil
        if Framework == 'qbx' then
            -- For QBX, items are in require or exports
            -- Try to get items directly from shared config
            local success, qbxItems = pcall(function()
                return require '@qbx_core/shared/items'
            end)
            if success and qbxItems then
                QBItems = qbxItems
            else
                -- Fallback: try ox_inventory items
                local oxItems = exports.ox_inventory:Items() or {}
                QBItems = oxItems
            end
        else
            -- For QB-Core, use Shared.Items
            QBItems = QBCore.Shared.Items or {}
        end
        
        for itemName, itemData in pairs(QBItems) do
            items[itemName] = {
                name = itemName,
                label = itemData.label or itemName,
                weight = itemData.weight or 0,
                type = itemData.type or 'item',
                image = itemData.image or (itemName .. '.png'),
                unique = itemData.unique or false,
                useable = itemData.useable or false,
                shouldClose = itemData.shouldClose or false,
                combinable = itemData.combinable or nil,
                description = itemData.description or ''
            }
        end
    elseif ESX then
        -- ESX items from database (use async with pcall for safety)
        local success, result = pcall(function()
            return MySQL.query.await('SELECT * FROM items', {})
        end)
        
        if success and result then
            for _, item in ipairs(result) do
                items[item.name] = {
                    name = item.name,
                    label = item.label,
                    weight = item.weight or 0,
                    type = 'item',
                    image = item.name .. '.png',
                    unique = false,
                    useable = item.can_remove == 1,
                    description = ''
                }
            end
        else
            Logger.Error('Failed to load ESX items from database', '❌')
        end
    end
    
    return items
end

-- Get player inventory
local function GetPlayerInventory(src)
    local inventory = {
        items = {},
        weight = 0,
        maxWeight = 120000,
        slots = 0,
        maxSlots = 41
    }
    
    if InventorySystem == 'ox_inventory' then
        local oxInv = exports.ox_inventory:GetInventory(src)
        if oxInv then
            inventory.weight = oxInv.weight or 0
            inventory.maxWeight = oxInv.maxWeight or 120000
            inventory.slots = #(oxInv.items or {})
            inventory.maxSlots = oxInv.slots or 41
            
            for slot, item in pairs(oxInv.items or {}) do
                if item then
                    table.insert(inventory.items, {
                        slot = slot,
                        name = item.name,
                        amount = item.count or item.amount or 1,
                        info = item.metadata or item.info or {},
                        weight = item.weight or 0,
                        type = 'item',
                        unique = false,
                        useable = true,
                        image = item.name .. '.png',
                        label = item.label or item.name
                    })
                end
            end
        end
    elseif QBCore then
        local Player = nil
        if Framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(src)
        else
            Player = QBCore.Functions.GetPlayer(src)
        end
        
        if Player and Player.PlayerData then
            local playerItems = Player.PlayerData.items or {}
            
            -- Safe weight retrieval
            if Player.Functions and Player.Functions.GetTotalWeight then
                inventory.weight = Player.Functions.GetTotalWeight() or 0
            else
                -- Calculate weight manually
                local totalWeight = 0
                for _, item in pairs(playerItems) do
                    if item then
                        totalWeight = totalWeight + ((item.weight or 0) * (item.amount or 1))
                    end
                end
                inventory.weight = totalWeight
            end
            
            -- Safe max weight retrieval
            if QBCore.Config and QBCore.Config.Player and QBCore.Config.Player.MaxWeight then
                inventory.maxWeight = QBCore.Config.Player.MaxWeight
            else
                inventory.maxWeight = 120000  -- Default
            end
            
            for slot, item in pairs(playerItems) do
                if item and item.name then
                    inventory.slots = inventory.slots + 1
                    table.insert(inventory.items, {
                        slot = slot,
                        name = item.name,
                        amount = item.amount or 1,
                        info = item.info or {},
                        weight = item.weight or 0,
                        type = item.type or 'item',
                        unique = item.unique or false,
                        useable = item.useable or true,
                        image = item.image or (item.name .. '.png'),
                        label = item.label or item.name
                    })
                end
            end
            
            inventory.maxSlots = Player.PlayerData.maxItems or 41
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            -- Get items
            for _, item in ipairs(xPlayer.inventory or {}) do
                if item.count > 0 then
                    inventory.slots = inventory.slots + 1
                    table.insert(inventory.items, {
                        slot = inventory.slots,
                        name = item.name,
                        amount = item.count,
                        info = {},
                        weight = item.weight or 0,
                        type = 'item',
                        unique = false,
                        useable = true,
                        image = item.name .. '.png',
                        label = item.label or item.name
                    })
                    inventory.weight = inventory.weight + (item.weight * item.count)
                end
            end
            
            -- Get weapons
            for _, weapon in ipairs(xPlayer.getLoadout() or {}) do
                inventory.slots = inventory.slots + 1
                table.insert(inventory.items, {
                    slot = inventory.slots,
                    name = weapon.name,
                    amount = 1,
                    info = { ammo = weapon.ammo or 0 },
                    weight = 1000,
                    type = 'weapon',
                    unique = true,
                    useable = true,
                    image = weapon.name .. '.png',
                    label = weapon.label or weapon.name
                })
            end
            
            inventory.maxWeight = xPlayer.getMaxWeight() or 120000
            inventory.maxSlots = 41
        end
    end
    
    return inventory
end

-- Modern callback for inventory data
lib.callback.register('ec_admin:getInventoryData', function(source, _)
    -- Get all online players
    local players = {}
    local allPlayers = GetPlayers()
    
    for _, playerId in ipairs(allPlayers) do
        local pId = tonumber(playerId)
        local playerName = GetPlayerName(pId)
        
        if playerName then
            local inventory = GetPlayerInventory(pId)
            
            table.insert(players, {
                id = pId,
                name = playerName,
                itemCount = inventory.itemCount or 0,
                weight = inventory.weight or 0,
                maxWeight = inventory.maxWeight or 100000,
                items = inventory.items or {}
            })
        end
    end
    
    return {
        success = true,
        players = players,
        inventorySystem = InventorySystem,
        framework = Framework
    }
end)

-- Legacy event for backward compatibility
RegisterNetEvent('ec_admin_ultimate:server:getInventoryData', function()
    local src = source
    
    -- Get all online players
    local players = {}
    local allPlayers = GetPlayers()
    
    for _, playerId in ipairs(allPlayers) do
        local pId = tonumber(playerId)
        local playerName = GetPlayerName(pId)
        
        if playerName then
            local inventory = GetPlayerInventory(pId)
            
            table.insert(players, {
                id = pId,
                name = playerName,
                citizenid = GetPlayerIdentifier(pId, 0),
                itemCount = #inventory.items,
                weight = inventory.weight,
                maxWeight = inventory.maxWeight,
                online = true
            })
        end
    end
    
    -- Get all items
    local allItems = GetAllItems()
    
    -- Calculate stats
    local stats = {
        totalPlayers = #players,
        totalItems = 0,
        totalWeight = 0,
        uniqueItems = 0
    }
    
    local uniqueItemsMap = {}
    for _, player in ipairs(players) do
        stats.totalItems = stats.totalItems + player.itemCount
        stats.totalWeight = stats.totalWeight + player.weight
        
        local inv = GetPlayerInventory(player.id)
        for _, item in ipairs(inv.items) do
            uniqueItemsMap[item.name] = true
        end
    end
    
    for _ in pairs(uniqueItemsMap) do
        stats.uniqueItems = stats.uniqueItems + 1
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:receiveInventoryData', src, {
        success = true,
        data = {
            players = players,
            items = allItems,
            stats = stats,
            inventorySystem = InventorySystem
        }
    })
end)

-- Get specific player inventory
RegisterNetEvent('ec_admin_ultimate:server:getPlayerInventory', function(data)
    local src = source
    local targetId = tonumber(data.playerId)
    
    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('ec_admin_ultimate:client:inventoryError', src, 'Player not found')
        return
    end
    
    local inventory = GetPlayerInventory(targetId)
    local playerName = GetPlayerName(targetId)
    
    TriggerClientEvent('ec_admin_ultimate:client:receivePlayerInventory', src, {
        success = true,
        playerId = targetId,
        playerName = playerName,
        inventory = inventory
    })
end)

-- Give item to player (callback version for NUI)
lib.callback.register('ec_admin:giveItem', function(source, data)
    local targetId = tonumber(data.playerId)
    local itemName = data.itemName
    local amount = tonumber(data.amount) or 1
    local metadata = data.metadata or {}
    
    if not targetId or GetPlayerName(targetId) == nil then
        return { success = false, message = 'Player not found' }
    end
    
    local success = false
    local message = 'Failed to give item'
    
    if InventorySystem == 'ox_inventory' then
        success = exports.ox_inventory:AddItem(targetId, itemName, amount, metadata)
        message = success and 'Item given successfully' or 'Failed to give item - inventory full?'
    elseif QBCore then
        local Player = nil
        if Framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(targetId)
        else
            Player = QBCore.Functions.GetPlayer(targetId)
        end
        
        if Player then
            success = Player.Functions.AddItem(itemName, amount, false, metadata)
            TriggerClientEvent('inventory:client:ItemBox', targetId, QBCore.Shared.Items[itemName], 'add', amount)
            message = success and 'Item given successfully' or 'Failed to give item - inventory full?'
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            xPlayer.addInventoryItem(itemName, amount)
            success = true
            message = 'Item given successfully'
        end
    end
    
    -- Log the action
    local adminName = GetPlayerName(source)
    Logger.Info(string.format('', adminName, amount, itemName, GetPlayerName(targetId), targetId))
    
    return { success = success, message = message }
end)

-- Remove item from player (callback version for NUI)
lib.callback.register('ec_admin:removeItem', function(source, data)
    local targetId = tonumber(data.playerId)
    local itemName = data.itemName
    local amount = tonumber(data.amount) or 1
    local slot = tonumber(data.slot)
    
    if not targetId or GetPlayerName(targetId) == nil then
        return { success = false, message = 'Player not found' }
    end
    
    local success = false
    local message = 'Failed to remove item'
    
    if InventorySystem == 'ox_inventory' then
        success = exports.ox_inventory:RemoveItem(targetId, itemName, amount, nil, slot)
        message = success and 'Item removed successfully' or 'Failed to remove item'
    elseif QBCore then
        local Player = nil
        if Framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(targetId)
        else
            Player = QBCore.Functions.GetPlayer(targetId)
        end
        
        if Player then
            success = Player.Functions.RemoveItem(itemName, amount, slot)
            TriggerClientEvent('inventory:client:ItemBox', targetId, QBCore.Shared.Items[itemName], 'remove', amount)
            message = success and 'Item removed successfully' or 'Failed to remove item'
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            xPlayer.removeInventoryItem(itemName, amount)
            success = true
            message = 'Item removed successfully'
        end
    end
    
    -- Log the action
    local adminName = GetPlayerName(source)
    Logger.Info(string.format('', adminName, amount, itemName, GetPlayerName(targetId), targetId))
    
    return { success = success, message = message }
end)

-- Clear player inventory (callback version for NUI)
-- ✅ PRODUCTION READY: Clear player inventory with database logging
lib.callback.register('ec_admin:clearInventory', function(source, data)
    local targetId = tonumber(data.playerId)
    
    if not targetId or GetPlayerName(targetId) == nil then
        return { success = false, message = 'Player not found' }
    end
    
    local success = false
    local message = 'Failed to clear inventory'
    
    if InventorySystem == 'ox_inventory' then
        exports.ox_inventory:ClearInventory(targetId)
        success = true
        message = 'Inventory cleared successfully'
    elseif QBCore then
        local Player = nil
        if Framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(targetId)
        else
            Player = QBCore.Functions.GetPlayer(targetId)
        end
        
        if Player then
            Player.Functions.ClearInventory()
            success = true
            message = 'Inventory cleared successfully'
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            for _, item in pairs(xPlayer.inventory) do
                if item.count > 0 then
                    xPlayer.setInventoryItem(item.name, 0)
                end
            end
            success = true
            message = 'Inventory cleared successfully'
        end
    end
    
    -- Log the action
    local adminName = GetPlayerName(source)
    Logger.Info(string.format('%s cleared inventory for %s (ID: %d)', adminName, GetPlayerName(targetId), targetId), '✅')
    
    -- Database logging for admin accountability
    if success and _G.MetricsDB then
        _G.MetricsDB.LogAdminAction({
            adminIdentifier = GetPlayerIdentifiers(source)[1] or 'system',
            adminName = adminName,
            action = 'clear_inventory',
            category = 'inventory',
            targetIdentifier = GetPlayerIdentifiers(targetId)[1] or '',
            targetName = GetPlayerName(targetId) or 'Unknown',
            details = string.format('Cleared all items from inventory'),
            metadata = { inventory_system = InventorySystem }
        })
    end
    
    return { success = success, message = message }
end)

-- Give item to player (event version for backwards compatibility)
RegisterNetEvent('ec_admin_ultimate:server:giveItem', function(data)
    local src = source
    local targetId = tonumber(data.playerId)
    local itemName = data.itemName
    local amount = tonumber(data.amount) or 1
    local metadata = data.metadata or {}
    
    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('ec_admin_ultimate:client:inventoryError', src, 'Player not found')
        return
    end
    
    local success = false
    local message = 'Failed to give item'
    
    if InventorySystem == 'ox_inventory' then
        success = exports.ox_inventory:AddItem(targetId, itemName, amount, metadata)
        message = success and 'Item given successfully' or 'Failed to give item - inventory full?'
    elseif QBCore then
        local Player = nil
        if Framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(targetId)
        else
            Player = QBCore.Functions.GetPlayer(targetId)
        end
        
        if Player then
            success = Player.Functions.AddItem(itemName, amount, false, metadata)
            TriggerClientEvent('inventory:client:ItemBox', targetId, QBCore.Shared.Items[itemName], 'add', amount)
            message = success and 'Item given successfully' or 'Failed to give item - inventory full?'
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            xPlayer.addInventoryItem(itemName, amount)
            success = true
            message = 'Item given successfully'
        end
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:inventoryResponse', src, {
        success = success,
        message = message
    })
    
    -- Log the action
    local adminName = GetPlayerName(src)
    Logger.Info(string.format('', adminName, amount, itemName, GetPlayerName(targetId), targetId))
end)

-- Remove item from player (event version for backwards compatibility)
RegisterNetEvent('ec_admin_ultimate:server:removeItem', function(data)
    local src = source
    local targetId = tonumber(data.playerId)
    local itemName = data.itemName
    local amount = tonumber(data.amount) or 1
    local slot = tonumber(data.slot)
    
    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('ec_admin_ultimate:client:inventoryError', src, 'Player not found')
        return
    end
    
    local success = false
    local message = 'Failed to remove item'
    
    if InventorySystem == 'ox_inventory' then
        success = exports.ox_inventory:RemoveItem(targetId, itemName, amount, nil, slot)
        message = success and 'Item removed successfully' or 'Failed to remove item'
    elseif QBCore then
        local Player = nil
        if Framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(targetId)
        else
            Player = QBCore.Functions.GetPlayer(targetId)
        end
        
        if Player then
            success = Player.Functions.RemoveItem(itemName, amount, slot)
            TriggerClientEvent('inventory:client:ItemBox', targetId, QBCore.Shared.Items[itemName], 'remove', amount)
            message = success and 'Item removed successfully' or 'Failed to remove item'
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            xPlayer.removeInventoryItem(itemName, amount)
            success = true
            message = 'Item removed successfully'
        end
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:inventoryResponse', src, {
        success = success,
        message = message
    })
    
    -- Log the action
    local adminName = GetPlayerName(src)
    Logger.Info(string.format('', adminName, amount, itemName, GetPlayerName(targetId), targetId))
end)

-- Clear player inventory (event version for backwards compatibility)
RegisterNetEvent('ec_admin_ultimate:server:clearInventory', function(data)
    local src = source
    local targetId = tonumber(data.playerId)
    
    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('ec_admin_ultimate:client:inventoryError', src, 'Player not found')
        return
    end
    
    local success = false
    local message = 'Failed to clear inventory'
    
    if InventorySystem == 'ox_inventory' then
        exports.ox_inventory:ClearInventory(targetId)
        success = true
        message = 'Inventory cleared successfully'
    elseif QBCore then
        local Player = nil
        if Framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(targetId)
        else
            Player = QBCore.Functions.GetPlayer(targetId)
        end
        
        if Player then
            Player.Functions.ClearInventory()
            success = true
            message = 'Inventory cleared successfully'
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            for _, item in ipairs(xPlayer.inventory or {}) do
                if item.count > 0 then
                    xPlayer.setInventoryItem(item.name, 0)
                end
            end
            success = true
            message = 'Inventory cleared successfully'
        end
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:inventoryResponse', src, {
        success = success,
        message = message
    })
    
    -- Log the action
    local adminName = GetPlayerName(src)
    Logger.Info(string.format('', adminName, GetPlayerName(targetId), targetId))
end)

-- Set item amount
RegisterNetEvent('ec_admin_ultimate:server:setItemAmount', function(data)
    local src = source
    local targetId = tonumber(data.playerId)
    local itemName = data.itemName
    local newAmount = tonumber(data.amount)
    local slot = tonumber(data.slot)
    
    if not targetId or GetPlayerName(targetId) == nil then
        TriggerClientEvent('ec_admin_ultimate:client:inventoryError', src, 'Player not found')
        return
    end
    
    local success = false
    local message = 'Failed to set item amount'
    
    if InventorySystem == 'ox_inventory' then
        -- Remove old and add new
        local currentItem = exports.ox_inventory:GetItem(targetId, itemName, nil, false)
        if currentItem then
            exports.ox_inventory:RemoveItem(targetId, itemName, currentItem.count, currentItem.metadata, slot)
            success = exports.ox_inventory:AddItem(targetId, itemName, newAmount, currentItem.metadata)
        end
        message = success and 'Item amount updated' or 'Failed to update item amount'
    elseif QBCore then
        local Player = nil
        if Framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(targetId)
        else
            Player = QBCore.Functions.GetPlayer(targetId)
        end
        
        if Player then
            local item = Player.Functions.GetItemBySlot(slot)
            if item then
                local diff = newAmount - item.amount
                if diff > 0 then
                    Player.Functions.AddItem(itemName, diff, slot)
                elseif diff < 0 then
                    Player.Functions.RemoveItem(itemName, math.abs(diff), slot)
                end
                success = true
                message = 'Item amount updated'
            end
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            local item = xPlayer.getInventoryItem(itemName)
            if item then
                local diff = newAmount - item.count
                if diff > 0 then
                    xPlayer.addInventoryItem(itemName, diff)
                elseif diff < 0 then
                    xPlayer.removeInventoryItem(itemName, math.abs(diff))
                end
                success = true
                message = 'Item amount updated'
            end
        end
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:inventoryResponse', src, {
        success = success,
        message = message
    })
end)

-- Set item amount (lib.callback version for NUI)
lib.callback.register('ec_admin:setItemAmount', function(source, data)
    local targetId = tonumber(data.playerId)
    local itemName = data.itemName
    local newAmount = tonumber(data.amount)
    local slot = tonumber(data.slot)
    
    if not targetId or GetPlayerName(targetId) == nil then
        return { success = false, message = 'Player not found' }
    end
    
    if not itemName or not newAmount then
        return { success = false, message = 'Invalid item name or amount' }
    end
    
    local success = false
    local message = 'Failed to set item amount'
    
    if InventorySystem == 'ox_inventory' then
        -- Remove old and add new
        local currentItem = exports.ox_inventory:GetItem(targetId, itemName, nil, false)
        if currentItem then
            exports.ox_inventory:RemoveItem(targetId, itemName, currentItem.count, currentItem.metadata, slot)
            success = exports.ox_inventory:AddItem(targetId, itemName, newAmount, currentItem.metadata)
            message = success and 'Item amount updated successfully' or 'Failed to update item amount'
        else
            message = 'Item not found in inventory'
        end
    elseif QBCore then
        local Player = nil
        if Framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(targetId)
        else
            Player = QBCore.Functions.GetPlayer(targetId)
        end
        
        if Player then
            local item = slot and Player.Functions.GetItemBySlot(slot) or Player.Functions.GetItemByName(itemName)
            if item then
                local diff = newAmount - item.amount
                if diff > 0 then
                    Player.Functions.AddItem(itemName, diff, slot)
                elseif diff < 0 then
                    Player.Functions.RemoveItem(itemName, math.abs(diff), slot)
                end
                success = true
                message = 'Item amount updated successfully'
            else
                message = 'Item not found in inventory'
            end
        else
            message = 'Player not found'
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if xPlayer then
            local item = xPlayer.getInventoryItem(itemName)
            if item then
                local diff = newAmount - item.count
                if diff > 0 then
                    xPlayer.addInventoryItem(itemName, diff)
                elseif diff < 0 then
                    xPlayer.removeInventoryItem(itemName, math.abs(diff))
                end
                success = true
                message = 'Item amount updated successfully'
            else
                message = 'Item not found in inventory'
            end
        else
            message = 'Player not found'
        end
    end
    
    if success then
        local adminName = GetPlayerName(source)
        Logger.Info(string.format('%s set %s amount to %d for %s (ID: %d)', adminName, itemName, newAmount, GetPlayerName(targetId), targetId))
    end
    
    return { success = success, message = message }
end)

Logger.Info('Inventory callbacks loaded (with lib.callback handlers)')