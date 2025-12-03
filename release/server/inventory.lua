-- EC Admin Ultimate - Inventory Management System (PRODUCTION STABLE)
-- Version: 1.0.0 - Complete inventory tracking and management

Logger.Info('📦 Loading inventory management system...')

local Inventory = {}

-- Framework detection
local Framework = nil
local FrameworkObject = nil

-- Inventory cache
local inventoryCache = {
    players = {},
    stashes = {},
    vehicles = {},
    lastUpdate = 0
}

-- Configuration
local config = {
    updateInterval = 30000,     -- 30 seconds
    cacheEnabled = true
}

-- Safe framework detection
local function DetectFramework()
    -- Detect QBCore (QBX variant)
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('📦 QBCore (qbx_core) detected')
        
        local success, coreObj = pcall(function()
            return exports['qbx_core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('📦 QBCore framework successfully connected')
        else
            Logger.Info('⚠️ QBX Core detected but GetCoreObject() not available yet')
            Logger.Info('⚠️ Inventory will use basic mode until core loads')
        end
        return true  -- Return true even if core object isn't ready yet
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('📦 QBCore (qb-core) detected')
        
        local success, coreObj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('📦 QBCore framework successfully connected')
        else
            Logger.Info('⚠️ QB Core detected but GetCoreObject() not available yet')
        end
        return true  -- Return true even if core object isn't ready yet
    end
    
    -- Detect ESX
    if GetResourceState('es_extended') == 'started' then
        Framework = 'ESX'
        local success, esxObj = pcall(function()
            return exports["es_extended"]:getSharedObject()
        end)
        if success and esxObj then
            FrameworkObject = esxObj
            Logger.Info('📦 ESX framework detected')
        end
        return true  -- Return true even if ESX object isn't ready yet
    end
    
    -- Check for ox_inventory (standalone)
    if GetResourceState('ox_inventory') == 'started' then
        Framework = 'ox_inventory'
        Logger.Info('📦 ox_inventory detected (standalone mode)')
        return true
    end
    
    Logger.Info('⚠️ No supported framework detected for inventory')
    return false
end

-- Get all player inventories
function Inventory.GetPlayerInventories()
    local inventories = {}
    
    if not Framework or not FrameworkObject then
        return inventories
    end
    
    if Framework == 'QBCore' then
        -- Get all players
        for _, playerId in pairs(GetPlayers()) do
            local Player = FrameworkObject.Functions.GetPlayer(tonumber(playerId))
            if Player then
                local inventory = Player.PlayerData.items or {}
                local totalItems = 0
                local totalWeight = 0
                local weapons = 0
                local items = 0
                
                for _, item in pairs(inventory) do
                    if item and item.amount and item.amount > 0 then
                        totalItems = totalItems + item.amount
                        totalWeight = totalWeight + (item.weight * item.amount)
                        
                        if item.type == 'weapon' then
                            weapons = weapons + 1
                        else
                            items = items + 1
                        end
                    end
                end
                
                table.insert(inventories, {
                    identifier = Player.PlayerData.license,
                    citizenid = Player.PlayerData.citizenid,
                    name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                    totalItems = totalItems,
                    totalWeight = totalWeight,
                    maxWeight = FrameworkObject.Config.Player.MaxWeight or 50000,
                    weapons = weapons,
                    items = items,
                    online = true
                })
            end
        end
        
        -- Get offline players from database
        if MySQL and MySQL.query then
            local result = MySQL.query.await('SELECT citizenid, charinfo, inventory FROM players LIMIT 100')
            if result then
                for _, row in ipairs(result) do
                    local charinfo = json.decode(row.charinfo or '{}')
                    local inventory = json.decode(row.inventory or '[]')
                    local totalItems = 0
                    local totalWeight = 0
                    local weapons = 0
                    local items = 0
                    
                    -- Check if player is online
                    local isOnline = false
                    for _, inv in pairs(inventories) do
                        if inv.citizenid == row.citizenid then
                            isOnline = true
                            break
                        end
                    end
                    
                    if not isOnline then
                        for _, item in pairs(inventory) do
                            if item and item.amount and item.amount > 0 then
                                totalItems = totalItems + item.amount
                                totalWeight = totalWeight + ((item.weight or 0) * item.amount)
                                
                                if item.type == 'weapon' then
                                    weapons = weapons + 1
                                else
                                    items = items + 1
                                end
                            end
                        end
                        
                        table.insert(inventories, {
                            identifier = 'offline',
                            citizenid = row.citizenid,
                            name = (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or 'Player'),
                            totalItems = totalItems,
                            totalWeight = totalWeight,
                            maxWeight = FrameworkObject.Config.Player.MaxWeight or 50000,
                            weapons = weapons,
                            items = items,
                            online = false
                        })
                    end
                end
            end
        end
    elseif Framework == 'ESX' then
        -- ESX implementation
        for _, playerId in pairs(GetPlayers()) do
            local xPlayer = FrameworkObject.GetPlayerFromId(tonumber(playerId))
            if xPlayer then
                local inventory = xPlayer.getInventory()
                local totalItems = 0
                local totalWeight = 0
                local weapons = 0
                local items = 0
                
                for _, item in pairs(inventory) do
                    if item.count > 0 then
                        totalItems = totalItems + item.count
                        totalWeight = totalWeight + (item.weight * item.count)
                        items = items + 1
                    end
                end
                
                -- Get weapons separately
                local loadout = xPlayer.getLoadout()
                weapons = #loadout
                
                table.insert(inventories, {
                    identifier = xPlayer.identifier,
                    citizenid = xPlayer.identifier,
                    name = xPlayer.getName(),
                    totalItems = totalItems,
                    totalWeight = totalWeight,
                    maxWeight = FrameworkObject.Config.MaxWeight or 50000,
                    weapons = weapons,
                    items = items,
                    online = true
                })
            end
        end
    end
    
    return inventories
end

-- Get all stashes
function Inventory.GetStashes()
    local stashes = {}
    
    if not Framework or not FrameworkObject then
        return stashes
    end
    
    -- Get stashes from database (QB-Core / ox_inventory)
    if MySQL and MySQL.query then
        local result = MySQL.query.await('SELECT * FROM stashitems')
        if result then
            local stashData = {}
            
            -- Group items by stash
            for _, row in ipairs(result) do
                if not stashData[row.stash] then
                    stashData[row.stash] = {
                        items = {},
                        totalWeight = 0,
                        totalItems = 0
                    }
                end
                
                local items = json.decode(row.items or '[]')
                for _, item in pairs(items) do
                    if item and item.amount and item.amount > 0 then
                        table.insert(stashData[row.stash].items, item)
                        stashData[row.stash].totalItems = stashData[row.stash].totalItems + item.amount
                        stashData[row.stash].totalWeight = stashData[row.stash].totalWeight + ((item.weight or 0) * item.amount)
                    end
                end
            end
            
            -- Convert to stash list
            for stashName, data in pairs(stashData) do
                local stashType = 'shared'
                local owner = nil
                local job = nil
                local gang = nil
                
                -- Determine stash type
                if string.find(stashName, 'personal_') then
                    stashType = 'personal'
                    owner = string.gsub(stashName, 'personal_', '')
                elseif string.find(stashName, '_stash') or string.find(stashName, '_storage') then
                    if string.find(stashName, 'police') or string.find(stashName, 'ems') or string.find(stashName, 'mechanic') then
                        stashType = 'job'
                        job = string.match(stashName, '(%w+)_')
                    elseif string.find(stashName, 'ballas') or string.find(stashName, 'vagos') or string.find(stashName, 'families') then
                        stashType = 'gang'
                        gang = string.match(stashName, '(%w+)_')
                    end
                elseif string.find(stashName, 'motel') or string.find(stashName, 'apartment') or string.find(stashName, 'house') then
                    stashType = 'property'
                end
                
                table.insert(stashes, {
                    id = stashName,
                    name = stashName,
                    label = stashName:gsub('_', ' '):gsub("(%a)([%w_']*)", function(a,b) return string.upper(a)..b end),
                    type = stashType,
                    owner = owner,
                    job = job,
                    gang = gang,
                    maxWeight = 500000, -- Default 500kg
                    totalWeight = data.totalWeight,
                    slots = 50,
                    totalItems = data.totalItems
                })
            end
        end
    end
    
    return stashes
end

-- Get vehicle storages
function Inventory.GetVehicleStorages()
    local vehicles = {}
    
    if not Framework or not FrameworkObject then
        return vehicles
    end
    
    -- Get vehicle trunks and gloveboxes
    if MySQL and MySQL.query then
        local result = MySQL.query.await('SELECT * FROM trunkitems LIMIT 100')
        if result then
            for _, row in ipairs(result) do
                local items = json.decode(row.items or '[]')
                local trunkWeight = 0
                local trunkItems = 0
                
                for _, item in pairs(items) do
                    if item and item.amount and item.amount > 0 then
                        trunkItems = trunkItems + item.amount
                        trunkWeight = trunkWeight + ((item.weight or 0) * item.amount)
                    end
                end
                
                -- Get glovebox
                local gloveboxWeight = 0
                local gloveboxItems = 0
                local gloveboxResult = MySQL.query.await('SELECT * FROM gloveboxitems WHERE plate = ?', {row.plate})
                if gloveboxResult and gloveboxResult[1] then
                    local gloveboxData = json.decode(gloveboxResult[1].items or '[]')
                    for _, item in pairs(gloveboxData) do
                        if item and item.amount and item.amount > 0 then
                            gloveboxItems = gloveboxItems + item.amount
                            gloveboxWeight = gloveboxWeight + ((item.weight or 0) * item.amount)
                        end
                    end
                end
                
                table.insert(vehicles, {
                    plate = row.plate,
                    model = 'Unknown',
                    owner = 'Unknown',
                    trunkWeight = trunkWeight,
                    trunkMaxWeight = 50000,
                    trunkItems = trunkItems,
                    gloveboxWeight = gloveboxWeight,
                    gloveboxMaxWeight = 10000,
                    gloveboxItems = gloveboxItems
                })
            end
        end
    end
    
    return vehicles
end

-- Get item database (all registered items)
function Inventory.GetItemDatabase()
    local items = {}
    
    if not Framework or not FrameworkObject then
        return items
    end
    
    if Framework == 'QBCore' then
        local QBShared = FrameworkObject.Shared
        if QBShared and QBShared.Items then
            for itemName, itemData in pairs(QBShared.Items) do
                local totalInCity = 0
                
                -- Count total items in circulation (this would be heavy on performance in production)
                -- In a real scenario, you'd cache this or calculate on demand
                
                table.insert(items, {
                    name = itemName,
                    label = itemData.label or itemName,
                    type = itemData.type or 'item',
                    weight = itemData.weight or 0,
                    usable = itemData.usable or false,
                    unique = itemData.unique or false,
                    description = itemData.description or '',
                    totalInCity = totalInCity,
                    value = itemData.price or 0
                })
            end
        end
    elseif Framework == 'ESX' then
        -- ESX items
        if MySQL and MySQL.query then
            local result = MySQL.query.await('SELECT * FROM items')
            if result then
                for _, row in ipairs(result) do
                    table.insert(items, {
                        name = row.name,
                        label = row.label,
                        type = 'item',
                        weight = row.weight or 0,
                        usable = row.can_remove == 1,
                        unique = row.unique == 1,
                        totalInCity = 0,
                        value = 0
                    })
                end
            end
        end
    end
    
    return items
end

-- Get specific inventory items
function Inventory.GetInventoryItems(inventoryType, inventoryId)
    local items = {}
    
    if not Framework or not FrameworkObject then
        return items
    end
    
    if Framework == 'QBCore' then
        if inventoryType == 'player' then
            -- Get player by citizenid
            for _, playerId in pairs(GetPlayers()) do
                local Player = FrameworkObject.Functions.GetPlayer(tonumber(playerId))
                if Player and Player.PlayerData.citizenid == inventoryId then
                    local inventory = Player.PlayerData.items or {}
                    for slot, item in pairs(inventory) do
                        if item and item.amount and item.amount > 0 then
                            table.insert(items, {
                                slot = slot,
                                name = item.name,
                                label = item.label,
                                count = item.amount,
                                weight = (item.weight or 0) * item.amount,
                                type = item.type or 'item',
                                info = item.info or {},
                                unique = item.unique or false
                            })
                        end
                    end
                    break
                end
            end
            
            -- If not online, get from database
            if #items == 0 and MySQL and MySQL.query then
                local result = MySQL.query.await('SELECT inventory FROM players WHERE citizenid = ?', {inventoryId})
                if result and result[1] then
                    local inventory = json.decode(result[1].inventory or '[]')
                    for slot, item in pairs(inventory) do
                        if item and item.amount and item.amount > 0 then
                            table.insert(items, {
                                slot = slot,
                                name = item.name,
                                label = item.label,
                                count = item.amount,
                                weight = (item.weight or 0) * item.amount,
                                type = item.type or 'item',
                                info = item.info or {},
                                unique = item.unique or false
                            })
                        end
                    end
                end
            end
        elseif inventoryType == 'stash' then
            -- Get stash items
            if MySQL and MySQL.query then
                local result = MySQL.query.await('SELECT items FROM stashitems WHERE stash = ?', {inventoryId})
                if result and result[1] then
                    local inventory = json.decode(result[1].items or '[]')
                    for slot, item in pairs(inventory) do
                        if item and item.amount and item.amount > 0 then
                            table.insert(items, {
                                slot = slot,
                                name = item.name,
                                label = item.label,
                                count = item.amount,
                                weight = (item.weight or 0) * item.amount,
                                type = item.type or 'item',
                                info = item.info or {}
                            })
                        end
                    end
                end
            end
        elseif inventoryType == 'vehicle' then
            -- Get trunk items
            if MySQL and MySQL.query then
                local result = MySQL.query.await('SELECT items FROM trunkitems WHERE plate = ?', {inventoryId})
                if result and result[1] then
                    local inventory = json.decode(result[1].items or '[]')
                    for slot, item in pairs(inventory) do
                        if item and item.amount and item.amount > 0 then
                            table.insert(items, {
                                slot = slot,
                                name = item.name,
                                label = item.label .. ' (Trunk)',
                                count = item.amount,
                                weight = (item.weight or 0) * item.amount,
                                type = item.type or 'item',
                                info = item.info or {}
                            })
                        end
                    end
                end
                
                -- Get glovebox items
                result = MySQL.query.await('SELECT items FROM gloveboxitems WHERE plate = ?', {inventoryId})
                if result and result[1] then
                    local inventory = json.decode(result[1].items or '[]')
                    for slot, item in pairs(inventory) do
                        if item and item.amount and item.amount > 0 then
                            table.insert(items, {
                                slot = slot + 100, -- Offset to avoid slot conflicts
                                name = item.name,
                                label = item.label .. ' (Glovebox)',
                                count = item.amount,
                                weight = (item.weight or 0) * item.amount,
                                type = item.type or 'item',
                                info = item.info or {}
                            })
                        end
                    end
                end
            end
        end
    end
    
    return items
end

-- Get comprehensive inventory data
function Inventory.GetAllData()
    local data = {
        players = Inventory.GetPlayerInventories(),
        stashes = Inventory.GetStashes(),
        vehicles = Inventory.GetVehicleStorages(),
        items = Inventory.GetItemDatabase(),
        framework = Framework,
        stats = {
            totalPlayers = 0,
            totalStashes = 0,
            totalVehicles = 0,
            totalItems = 0,
            totalWeight = 0,
            totalWeapons = 0
        }
    }
    
    -- Calculate stats
    for _, player in ipairs(data.players) do
        data.stats.totalPlayers = data.stats.totalPlayers + 1
        data.stats.totalItems = data.stats.totalItems + player.totalItems
        data.stats.totalWeight = data.stats.totalWeight + player.totalWeight
        data.stats.totalWeapons = data.stats.totalWeapons + player.weapons
    end
    
    data.stats.totalStashes = #data.stashes
    data.stats.totalVehicles = #data.vehicles
    
    return data
end

-- Add item to inventory
function Inventory.AddItem(adminSource, inventoryType, inventoryId, itemName, count, metadata)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'manageInventory') then
        return false, 'Insufficient permissions'
    end
    
    if Framework == 'QBCore' then
        if inventoryType == 'player' then
            for _, playerId in pairs(GetPlayers()) do
                local Player = FrameworkObject.Functions.GetPlayer(tonumber(playerId))
                if Player and Player.PlayerData.citizenid == inventoryId then
                    Player.Functions.AddItem(itemName, count, false, metadata or {})
                    return true, string.format('Added %dx %s', count, itemName)
                end
            end
        end
    end
    
    return false, 'Failed to add item'
end

-- Remove item from inventory
function Inventory.RemoveItem(adminSource, inventoryType, inventoryId, slot, itemName)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'manageInventory') then
        return false, 'Insufficient permissions'
    end
    
    if Framework == 'QBCore' then
        if inventoryType == 'player' then
            for _, playerId in pairs(GetPlayers()) do
                local Player = FrameworkObject.Functions.GetPlayer(tonumber(playerId))
                if Player and Player.PlayerData.citizenid == inventoryId then
                    local item = Player.PlayerData.items[slot]
                    if item then
                        Player.Functions.RemoveItem(itemName, item.amount, slot)
                        return true, 'Item removed successfully'
                    end
                end
            end
        end
    end
    
    return false, 'Failed to remove item'
end

-- Wipe entire inventory
function Inventory.WipeInventory(adminSource, inventoryType, inventoryId, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'wipeInventory') then
        return false, 'Insufficient permissions'
    end
    
    if Framework == 'QBCore' then
        if inventoryType == 'player' then
            for _, playerId in pairs(GetPlayers()) do
                local Player = FrameworkObject.Functions.GetPlayer(tonumber(playerId))
                if Player and Player.PlayerData.citizenid == inventoryId then
                    -- Clear all items
                    Player.PlayerData.items = {}
                    Player.Functions.Save()
                    
                    Logger.Info(string.format('', 
                          Player.PlayerData.name, inventoryId, reason))
                    return true, 'Inventory wiped successfully'
                end
            end
        end
    end
    
    return false, 'Failed to wipe inventory'
end

-- Initialize
function Inventory.Initialize()
    Logger.Info('📦 Initializing inventory system...')
    
    local frameworkDetected = DetectFramework()
    if not frameworkDetected then
        Logger.Info('⚠️ Inventory system disabled - no supported framework')
        return false
    end
    
    -- Update cache periodically
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(config.updateInterval)
            
            inventoryCache.players = Inventory.GetPlayerInventories()
            inventoryCache.stashes = Inventory.GetStashes()
            inventoryCache.vehicles = Inventory.GetVehicleStorages()
            inventoryCache.lastUpdate = os.time()
        end
    end)
    
    Logger.Info('✅ Inventory system initialized with ' .. Framework .. ' framework')
    return true
end

-- Server events
RegisterNetEvent('ec-admin:getInventoryData')
AddEventHandler('ec-admin:getInventoryData', function()
    local source = source
    local data = Inventory.GetAllData()
    TriggerClientEvent('ec-admin:receiveInventoryData', source, data)
end)

RegisterNetEvent('ec-admin:getInventoryItems')
AddEventHandler('ec-admin:getInventoryItems', function(inventoryType, inventoryId)
    local source = source
    local items = Inventory.GetInventoryItems(inventoryType, inventoryId)
    TriggerClientEvent('ec-admin:receiveInventoryItems', source, items)
end)

-- Admin action events
RegisterNetEvent('ec-admin:inventory:addItem')
AddEventHandler('ec-admin:inventory:addItem', function(data, cb)
    local source = source
    local success, message = Inventory.AddItem(source, data.type, data.id, data.item, data.count, data.metadata)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:inventory:removeItem')
AddEventHandler('ec-admin:inventory:removeItem', function(data, cb)
    local source = source
    local success, message = Inventory.RemoveItem(source, data.type, data.id, data.slot, data.item)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:inventory:wipeInventory')
AddEventHandler('ec-admin:inventory:wipeInventory', function(data, cb)
    local source = source
    local success, message = Inventory.WipeInventory(source, data.type, data.id, data.reason)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

-- Exports
exports('GetPlayerInventories', function()
    return Inventory.GetPlayerInventories()
end)

exports('GetStashes', function()
    return Inventory.GetStashes()
end)

exports('GetVehicleStorages', function()
    return Inventory.GetVehicleStorages()
end)

exports('GetAllInventoryData', function()
    return Inventory.GetAllData()
end)

-- Initialize
Inventory.Initialize()

-- Make available globally
_G.ECInventory = Inventory

Logger.Info('✅ Inventory system loaded successfully')