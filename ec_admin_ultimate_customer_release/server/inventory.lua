--[[
    EC Admin Ultimate - Inventory UI Backend
    Server-side logic for inventory management
    
    Handles:
    - inventory:getData: Get all inventory data (players, items, stats)
    - inventory:getPlayerInventory: Get specific player's inventory
    - inventory:giveItem: Give item to player
    - inventory:removeItem: Remove item from player
    - inventory:setItemAmount: Edit item amount
    - inventory:clearInventory: Clear player's inventory
    
    Framework Support: QB-Core, QBX, ESX
    Inventory System Support: qb-inventory, ox_inventory, esx_inventory
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Inventory] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Inventory] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local dataCache = {}
local CACHE_TTL = 10 -- Cache for 10 seconds

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Get player object
local function getPlayerObject(source)
    return ECFramework.GetPlayerObject(source)
end

-- Helper: Check admin permission
local function hasPermission(source, permission)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, permission)
    end
    return ECFramework.IsAdminGroup(source) or false
end

-- Helper: Get admin info
local function getAdminInfo(source)
    return {
        id = GetPlayerIdentifier(source, 0) or 'system',
        name = GetPlayerName(source) or 'System'
    }
end

-- Helper: Detect inventory system
local function detectInventorySystem()
    -- Check for ox_inventory
    if GetResourceState('ox_inventory') == 'started' then
        return 'ox_inventory'
    end
    
    -- Check for qb-inventory
    if GetResourceState('qb-inventory') == 'started' then
        return 'qb-inventory'
    end
    
    -- Check for esx_inventory
    if GetResourceState('esx_inventory') == 'started' then
        return 'esx_inventory'
    end
    
    -- Check for qs-inventory
    if GetResourceState('qs-inventory') == 'started' then
        return 'qs-inventory'
    end
    
    -- Default to framework inventory
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        return 'qb-inventory'
    elseif framework == 'esx' then
        return 'esx_inventory'
    end
    
    return 'unknown'
end

-- Helper: Get player identifier from source
local function getPlayerIdentifierFromSource(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    -- Try license first
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    
    return identifiers[1]
end

-- Helper: Get player source from identifier
local function getPlayerSourceByIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            local ids = GetPlayerIdentifiers(source)
            if ids then
                for _, id in ipairs(ids) do
                    if id == identifier then
                        return source
                    end
                end
            end
        end
    end
    return nil
end

-- Helper: Get player identifier from player ID
local function getPlayerIdentifierFromId(playerId)
    local source = tonumber(playerId)
    if not source then return nil end
    return getPlayerIdentifierFromSource(source)
end

-- Helper: Log inventory action
local function logInventoryAction(actionType, playerId, playerIdentifier, playerName, adminId, adminName, itemName, itemLabel, oldAmount, newAmount, slot, metadata, reason, success, errorMsg)
    MySQL.insert.await([[
        INSERT INTO ec_inventory_actions_log 
        (action_type, player_id, player_identifier, player_name, admin_id, admin_name, item_name, item_label, old_amount, new_amount, slot, metadata, reason, timestamp, success, error_message)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        actionType, playerId, playerIdentifier, playerName, adminId, adminName,
        itemName, itemLabel, oldAmount, newAmount, slot,
        metadata and json.encode(metadata) or nil, reason,
        getCurrentTimestamp(), success and 1 or 0, errorMsg
    })
end

-- Helper: Get all players with inventory data
local function getAllPlayersWithInventory()
    local players = {}
    local framework = getFramework()
    local inventorySystem = detectInventorySystem()
    
    -- Get online players
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            local player = getPlayerObject(source)
            local name = GetPlayerName(source) or 'Unknown'
            local identifier = getPlayerIdentifierFromSource(source) or ''
            local citizenid = ''
            
            -- Get citizenid
            if framework == 'qb' or framework == 'qbx' then
                if player and player.PlayerData then
                    citizenid = player.PlayerData.citizenid or ''
                end
            elseif framework == 'esx' then
                if player and player.identifier then
                    identifier = player.identifier
                end
            end
            
            -- Get inventory stats
            local itemCount = 0
            local weight = 0
            local maxWeight = 0
            
            if inventorySystem == 'ox_inventory' then
                -- ox_inventory: Get inventory weight
                if exports.ox_inventory and exports.ox_inventory.GetInventory then
                    local inv = exports.ox_inventory:GetInventory(source)
                    if inv then
                        itemCount = inv.count or 0
                        weight = inv.weight or 0
                        maxWeight = inv.maxWeight or 0
                    end
                end
            elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
                -- QB inventory: Count items
                if player and player.PlayerData and player.PlayerData.items then
                    for _, item in pairs(player.PlayerData.items) do
                        if item and item.name then
                            itemCount = itemCount + 1
                            weight = weight + ((item.weight or 0.1) * (item.amount or item.count or 1))
                        end
                    end
                    maxWeight = player.PlayerData.metadata and player.PlayerData.metadata.maxweight or 120000
                end
            elseif inventorySystem == 'esx_inventory' then
                -- ESX inventory
                if player and player.getInventory then
                    local items = player:getInventory()
                    if items then
                        for _, item in pairs(items) do
                            if item then
                                itemCount = itemCount + 1
                                weight = weight + ((item.weight or 0.1) * (item.count or 1))
                            end
                        end
                    end
                    maxWeight = 120000 -- ESX default
                end
            end
            
            table.insert(players, {
                id = source,
                name = name,
                citizenid = citizenid,
                itemCount = itemCount,
                weight = weight,
                maxWeight = maxWeight,
                online = true
            })
        end
    end
    
    -- Get offline players from database (if needed)
    -- This would require querying the database for players with inventory
    
    return players
end

-- Helper: Get all item definitions
local function getAllItemDefinitions()
    local items = {}
    local inventorySystem = detectInventorySystem()
    
    if inventorySystem == 'ox_inventory' then
        -- ox_inventory: Get items from exports
        if exports.ox_inventory and exports.ox_inventory.Items then
            local oxItems = exports.ox_inventory:Items()
            if oxItems then
                for itemName, itemData in pairs(oxItems) do
                    items[itemName] = {
                        name = itemName,
                        label = itemData.label or itemName,
                        weight = itemData.weight or 0.1,
                        type = itemData.type or 'item',
                        image = itemData.image or '',
                        unique = itemData.unique or false,
                        useable = itemData.usable or false,
                        description = itemData.description or ''
                    }
                end
            end
        end
    elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
        -- QB inventory: Get items from shared/items.lua or exports
        if exports['qb-core'] and exports['qb-core'].GetItems then
            local qbItems = exports['qb-core']:GetItems()
            if qbItems then
                for itemName, itemData in pairs(qbItems) do
                    items[itemName] = {
                        name = itemName,
                        label = itemData.label or itemName,
                        weight = itemData.weight or 0.1,
                        type = itemData.type or 'item',
                        image = itemData.image or '',
                        unique = itemData.unique or false,
                        useable = itemData.useable or false,
                        description = itemData.description or ''
                    }
                end
            end
        end
    elseif inventorySystem == 'esx_inventory' then
        -- ESX: Get items from database
        local result = MySQL.query.await('SELECT * FROM items', {})
        if result then
            for _, row in ipairs(result) do
                items[row.name] = {
                    name = row.name,
                    label = row.label or row.name,
                    weight = row.weight or 0.1,
                    type = row.type or 'item',
                    image = '',
                    unique = row.rare == 1,
                    useable = row.usable == 1,
                    description = row.description or ''
                }
            end
        end
    end
    
    return items
end

-- Helper: Get player inventory
local function getPlayerInventoryData(playerId)
    local source = tonumber(playerId)
    if not source then
        return { success = false, error = 'Invalid player ID' }
    end
    
    local player = getPlayerObject(source)
    if not player then
        return { success = false, error = 'Player not found' }
    end
    
    local framework = getFramework()
    local inventorySystem = detectInventorySystem()
    local items = {}
    local weight = 0
    local maxWeight = 0
    local slots = 0
    local maxSlots = 0
    
    if inventorySystem == 'ox_inventory' then
        -- ox_inventory
        if exports.ox_inventory and exports.ox_inventory.GetInventory then
            local inv = exports.ox_inventory:GetInventory(source)
            if inv then
                for slot, item in pairs(inv.items or {}) do
                    if item and item.name then
                        table.insert(items, {
                            slot = slot,
                            name = item.name,
                            amount = item.count or 1,
                            info = item.metadata or {},
                            weight = item.weight or 0.1,
                            type = item.type or 'item',
                            unique = item.unique or false,
                            useable = item.usable or false,
                            image = item.image or '',
                            label = item.label or item.name
                        })
                        weight = weight + ((item.weight or 0.1) * (item.count or 1))
                    end
                end
                maxWeight = inv.maxWeight or 120000
                maxSlots = inv.maxSlots or 50
                slots = #items
            end
        end
    elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
        -- QB inventory
        if player and player.PlayerData and player.PlayerData.items then
            for slot, item in pairs(player.PlayerData.items) do
                if item and item.name then
                    table.insert(items, {
                        slot = tonumber(slot) or #items + 1,
                        name = item.name,
                        amount = item.amount or item.count or 1,
                        info = item.info or item.metadata or {},
                        weight = item.weight or 0.1,
                        type = item.type or 'item',
                        unique = item.unique or false,
                        useable = item.useable or false,
                        image = item.image or '',
                        label = item.label or item.name
                    })
                    weight = weight + ((item.weight or 0.1) * (item.amount or item.count or 1))
                end
            end
            maxWeight = player.PlayerData.metadata and player.PlayerData.metadata.maxweight or 120000
            maxSlots = 50 -- QB default
            slots = #items
        end
    elseif inventorySystem == 'esx_inventory' then
        -- ESX inventory
        if player and player.getInventory then
            local invItems = player:getInventory()
            if invItems then
                for _, item in pairs(invItems) do
                    if item then
                        table.insert(items, {
                            slot = item.slot or #items + 1,
                            name = item.name,
                            amount = item.count or 1,
                            info = item.metadata or {},
                            weight = item.weight or 0.1,
                            type = item.type or 'item',
                            unique = false,
                            useable = item.usable or false,
                            image = '',
                            label = item.label or item.name
                        })
                        weight = weight + ((item.weight or 0.1) * (item.count or 1))
                    end
                end
            end
            maxWeight = 120000 -- ESX default
            maxSlots = 50
            slots = #items
        end
    end
    
    return {
        success = true,
        inventory = {
            items = items,
            weight = weight,
            maxWeight = maxWeight,
            slots = slots,
            maxSlots = maxSlots
        }
    }
end

-- Helper: Give item to player
local function giveItemToPlayer(playerId, itemName, amount, metadata)
    local source = tonumber(playerId)
    if not source then
        return { success = false, message = 'Invalid player ID' }
    end
    
    local player = getPlayerObject(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    local inventorySystem = detectInventorySystem()
    local success = false
    local message = 'Item given successfully'
    
    if inventorySystem == 'ox_inventory' then
        -- ox_inventory: Add item
        if exports.ox_inventory and exports.ox_inventory.AddItem then
            local result = exports.ox_inventory:AddItem(source, itemName, amount, metadata)
            success = result == true or result == 'success'
        end
    elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
        -- QB inventory: Add item
        if player and player.Functions and player.Functions.AddItem then
            local result = player.Functions.AddItem(itemName, amount, false, metadata or {})
            success = result == true
        end
    elseif inventorySystem == 'esx_inventory' then
        -- ESX inventory: Add item
        if player and player.addInventoryItem then
            player:addInventoryItem(itemName, amount)
            success = true
        end
    end
    
    return { success = success, message = success and message or 'Failed to give item' }
end

-- Helper: Remove item from player
local function removeItemFromPlayer(playerId, itemName, amount, slot)
    local source = tonumber(playerId)
    if not source then
        return { success = false, message = 'Invalid player ID' }
    end
    
    local player = getPlayerObject(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    local inventorySystem = detectInventorySystem()
    local success = false
    local message = 'Item removed successfully'
    
    if inventorySystem == 'ox_inventory' then
        -- ox_inventory: Remove item
        if exports.ox_inventory and exports.ox_inventory.RemoveItem then
            local result = exports.ox_inventory:RemoveItem(source, itemName, amount)
            success = result == true or result == 'success'
        end
    elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
        -- QB inventory: Remove item
        if player and player.Functions and player.Functions.RemoveItem then
            local result = player.Functions.RemoveItem(itemName, amount, slot)
            success = result == true
        end
    elseif inventorySystem == 'esx_inventory' then
        -- ESX inventory: Remove item
        if player and player.removeInventoryItem then
            player:removeInventoryItem(itemName, amount)
            success = true
        end
    end
    
    return { success = success, message = success and message or 'Failed to remove item' }
end

-- Helper: Set item amount
local function setItemAmount(playerId, itemName, newAmount, slot)
    local source = tonumber(playerId)
    if not source then
        return { success = false, message = 'Invalid player ID' }
    end
    
    local player = getPlayerObject(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    -- Get current amount
    local currentAmount = 0
    local inventoryData = getPlayerInventoryData(playerId)
    if inventoryData.success and inventoryData.inventory then
        for _, item in ipairs(inventoryData.inventory.items) do
            if item.name == itemName and (not slot or item.slot == slot) then
                currentAmount = item.amount
                break
            end
        end
    end
    
    local diff = newAmount - currentAmount
    
    if diff > 0 then
        -- Add items
        return giveItemToPlayer(playerId, itemName, diff, {})
    elseif diff < 0 then
        -- Remove items
        return removeItemFromPlayer(playerId, itemName, math.abs(diff), slot)
    else
        -- No change
        return { success = true, message = 'Amount unchanged' }
    end
end

-- Helper: Clear player inventory
local function clearPlayerInventory(playerId)
    local source = tonumber(playerId)
    if not source then
        return { success = false, message = 'Invalid player ID' }
    end
    
    local player = getPlayerObject(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    local inventorySystem = detectInventorySystem()
    local success = false
    local message = 'Inventory cleared successfully'
    
    if inventorySystem == 'ox_inventory' then
        -- ox_inventory: Clear inventory
        if exports.ox_inventory and exports.ox_inventory.ClearInventory then
            exports.ox_inventory:ClearInventory(source)
            success = true
        end
    elseif inventorySystem == 'qb-inventory' or inventorySystem == 'qs-inventory' then
        -- QB inventory: Clear items
        if player and player.Functions and player.Functions.ClearItems then
            player.Functions.ClearItems()
            success = true
        end
    elseif inventorySystem == 'esx_inventory' then
        -- ESX inventory: Remove all items
        if player and player.getInventory then
            local items = player:getInventory()
            if items then
                for itemName, item in pairs(items) do
                    if player.removeInventoryItem then
                        player:removeInventoryItem(itemName, item.count or item.amount or 0)
                    end
                end
            end
            success = true
        end
    end
    
    return { success = success, message = success and message or 'Failed to clear inventory' }
end

-- Helper: Get inventory data (shared logic)
local function getInventoryData()
    -- Check cache
    if dataCache.data and (getCurrentTimestamp() - dataCache.timestamp) < CACHE_TTL then
        return dataCache.data
    end
    
    local players = getAllPlayersWithInventory()
    local items = getAllItemDefinitions()
    
    -- Calculate statistics
    local stats = {
        totalPlayers = #players,
        totalItems = 0,
        totalWeight = 0,
        uniqueItems = 0
    }
    
    -- Count unique items
    local uniqueItemNames = {}
    for itemName, _ in pairs(items) do
        uniqueItemNames[itemName] = true
    end
    stats.uniqueItems = 0
    for _ in pairs(uniqueItemNames) do
        stats.uniqueItems = stats.uniqueItems + 1
    end
    
    -- Calculate total weight
    for _, player in ipairs(players) do
        stats.totalWeight = stats.totalWeight + player.weight
    end
    
    local data = {
        players = players,
        items = items,
        stats = stats,
        inventorySystem = detectInventorySystem()
    }
    
    -- Cache data
    dataCache = {
        data = data,
        timestamp = getCurrentTimestamp()
    }
    
    return data
end

-- ============================================================================
-- REGISTERNUICALLBACK HANDLERS (Direct fetch from UI)
-- ============================================================================

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('inventory:getData', function(data, cb)
--     local response = getInventoryData()
--     cb({ success = true, data = response })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('inventory:getPlayerInventory', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     if not playerId then
--         cb({ success = false, error = 'Player ID required' })
--         return
--     end
--     local response = getPlayerInventoryData(playerId)
--     cb(response)
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('inventory:giveItem', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     local itemName = data.itemName
--     local amount = tonumber(data.amount) or 1
--     local metadata = data.metadata or {}
--     
--     if not playerId or not itemName then
--         cb({ success = false, message = 'Player ID and item name required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = getPlayerIdentifierFromId(playerId) or ''
--     
--     local response = giveItemToPlayer(playerId, itemName, amount, metadata)
--     
--     -- Log action
--     logInventoryAction('give', playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, itemName, itemName, 0, amount, nil, metadata, nil, response.success, response.message)
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb(response)
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('inventory:removeItem', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     local itemName = data.itemName
--     local amount = tonumber(data.amount) or 1
--     local slot = tonumber(data.slot)
--     
--     if not playerId or not itemName then
--         cb({ success = false, message = 'Player ID and item name required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = getPlayerIdentifierFromId(playerId) or ''
--     
--     local response = removeItemFromPlayer(playerId, itemName, amount, slot)
--     
--     -- Log action
--     logInventoryAction('remove', playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, itemName, itemName, amount, 0, slot, nil, nil, response.success, response.message)
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb(response)
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('inventory:setItemAmount', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     local itemName = data.itemName
--     local newAmount = tonumber(data.amount)
--     local slot = tonumber(data.slot)
--     
--     if not playerId or not itemName or not newAmount then
--         cb({ success = false, message = 'Player ID, item name, and amount required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = getPlayerIdentifierFromId(playerId) or ''
--     
--     -- Get old amount
--     local oldAmount = 0
--     local inventoryData = getPlayerInventoryData(playerId)
--     if inventoryData.success and inventoryData.inventory then
--         for _, item in ipairs(inventoryData.inventory.items) do
--             if item.name == itemName and (not slot or item.slot == slot) then
--                 oldAmount = item.amount
--                 break
--             end
--         end
--     end
--     
--     local response = setItemAmount(playerId, itemName, newAmount, slot)
--     
--     -- Log action
--     logInventoryAction('set_amount', playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, itemName, itemName, oldAmount, newAmount, slot, nil, nil, response.success, response.message)
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb(response)
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('inventory:clearInventory', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     
--     if not playerId then
--         cb({ success = false, message = 'Player ID required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = getPlayerIdentifierFromId(playerId) or ''
--     
--     local response = clearPlayerInventory(playerId)
--     
--     -- Log action
--     logInventoryAction('clear', playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, nil, nil, nil, nil, nil, nil, nil, response.success, response.message)
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb(response)
-- end)

print("^2[Inventory]^7 UI Backend loaded - Inventory System: " .. detectInventorySystem() .. "^0")

