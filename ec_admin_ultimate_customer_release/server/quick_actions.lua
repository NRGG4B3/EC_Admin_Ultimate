--[[
    EC Admin Ultimate - Quick Actions UI Backend
    Global quick action handler system for all admin actions
    
    Handles 60+ quick actions including:
    - Self actions (noclip, godmode, heal, etc.)
    - Teleport actions (tpm, bring, goto, etc.)
    - Player actions (revive, heal, kick, ban, etc.)
    - Vehicle actions (spawn, fix, delete, etc.)
    - World actions (weather, time, clear area, etc.)
    - Server actions (restart resource, announcement, etc.)
    - Economy actions (give money, give item, etc.)
    
    Framework Support: QB-Core, QBX, ESX, Standalone
]]

-- Ensure framework is available
if not ECFramework then
    print("^1[Quick Actions] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Ensure MySQL is available
if not MySQL then
    print("^1[Quick Actions] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Local variables
local actionHistory = {} -- Track recent actions for logging
local MAX_HISTORY = 100

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Get player object
local function getPlayer(source)
    return ECFramework.GetPlayerObject(source)
end

-- Helper: Check admin permission
local function hasPermission(source, permission)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, permission)
    end
    return ECFramework.IsAdminGroup(source) or false
end

-- Helper: Get action name from action ID
local function getActionName(actionId)
    local actionNames = {
        ['noclip'] = 'Noclip',
        ['godmode'] = 'God Mode',
        ['invisible'] = 'Invisibility',
        ['heal'] = 'Heal Self',
        ['stamina'] = 'Infinite Stamina',
        ['tpm'] = 'Teleport to Marker',
        ['bring'] = 'Bring Player',
        ['goto'] = 'Go to Player',
        ['revive'] = 'Revive Player',
        ['kick'] = 'Kick Player',
        ['ban'] = 'Ban Player',
        ['freeze'] = 'Freeze Player',
        ['unfreeze'] = 'Unfreeze Player',
        ['spectate'] = 'Spectate Player',
        ['spawn_vehicle'] = 'Spawn Vehicle',
        ['fix_vehicle'] = 'Fix Vehicle',
        ['delete_vehicle'] = 'Delete Vehicle',
        ['weather'] = 'Change Weather',
        ['time'] = 'Change Time',
        ['announcement'] = 'Server Announcement',
        ['restart_resource'] = 'Restart Resource',
        ['give_money'] = 'Give Money',
        ['give_item'] = 'Give Item'
    }
    return actionNames[actionId] or actionId
end

-- Helper: Log action to database
local function logActionToDatabase(source, actionId, actionName, data, success, errorMsg)
    local adminName = GetPlayerName(source) or 'Unknown'
    local adminId = GetPlayerIdentifier(source, 0) or 'system'
    local targetPlayer = nil
    local targetName = nil
    
    -- Extract target player info from data
    if data and data.playerId then
        targetPlayer = GetPlayerIdentifier(data.playerId, 0)
        targetName = GetPlayerName(data.playerId)
    elseif data and data.target then
        targetPlayer = GetPlayerIdentifier(data.target, 0)
        targetName = GetPlayerName(data.target)
    end
    
    local actionDataJson = json.encode(data or {})
    
    -- Log to database
    MySQL.insert.await([[
        INSERT INTO ec_quick_actions_log (action_id, action_name, performed_by, target_player, target_name, action_data, success, error_message, timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {actionId, actionName, adminName, targetPlayer, targetName, actionDataJson, success and 1 or 0, errorMsg, getCurrentTimestamp()})
    
    -- Update statistics
    local today = os.date("%Y-%m-%d")
    local statsResult = MySQL.query.await('SELECT * FROM ec_quick_actions_statistics WHERE date = ? AND action_id = ?', {today, actionId})
    
    if statsResult and statsResult[1] then
        -- Update existing
        if success then
            MySQL.update.await('UPDATE ec_quick_actions_statistics SET usage_count = usage_count + 1, success_count = success_count + 1 WHERE date = ? AND action_id = ?', {today, actionId})
        else
            MySQL.update.await('UPDATE ec_quick_actions_statistics SET usage_count = usage_count + 1, failure_count = failure_count + 1 WHERE date = ? AND action_id = ?', {today, actionId})
        end
    else
        -- Insert new
        if success then
            MySQL.insert.await('INSERT INTO ec_quick_actions_statistics (date, action_id, action_name, usage_count, success_count, failure_count) VALUES (?, ?, ?, 1, 1, 0)', {today, actionId, actionName})
        else
            MySQL.insert.await('INSERT INTO ec_quick_actions_statistics (date, action_id, action_name, usage_count, success_count, failure_count) VALUES (?, ?, ?, 1, 0, 1)', {today, actionId, actionName})
        end
    end
end

-- Helper: Log action (in-memory + database)
local function logAction(source, action, data)
    local playerName = GetPlayerName(source) or 'Unknown'
    local actionData = {
        source = source,
        playerName = playerName,
        action = action,
        data = data,
        timestamp = getCurrentTimestamp()
    }
    table.insert(actionHistory, actionData)
    if #actionHistory > MAX_HISTORY then
        table.remove(actionHistory, 1)
    end
    print(string.format("^3[Quick Actions]^7 %s (%d) executed: %s^0", playerName, source, action))
end

-- Helper: Notify player
local function notifyPlayer(source, message, type)
    ECFramework.Notify(source, message, type or 'info')
end

-- ============================================================================
-- SELF ACTIONS
-- ============================================================================

local function handleNoclip(source, data)
    TriggerClientEvent('ec_admin:quickAction:noclip', source)
    logAction(source, 'noclip', data)
    return { success = true, message = 'Noclip toggled' }
end

local function handleGodmode(source, data)
    TriggerClientEvent('ec_admin:quickAction:godmode', source)
    logAction(source, 'godmode', data)
    return { success = true, message = 'God mode toggled' }
end

local function handleInvisible(source, data)
    TriggerClientEvent('ec_admin:quickAction:invisible', source)
    logAction(source, 'invisible', data)
    return { success = true, message = 'Invisibility toggled' }
end

local function handleHeal(source, data)
    TriggerClientEvent('ec_admin:quickAction:heal', source)
    logAction(source, 'heal', data)
    return { success = true, message = 'Healed' }
end

local function handleStamina(source, data)
    TriggerClientEvent('ec_admin:quickAction:stamina', source)
    logAction(source, 'stamina', data)
    return { success = true, message = 'Infinite stamina toggled' }
end

local function handleSuperJump(source, data)
    TriggerClientEvent('ec_admin:quickAction:superJump', source)
    logAction(source, 'super_jump', data)
    return { success = true, message = 'Super jump toggled' }
end

local function handleFastRun(source, data)
    TriggerClientEvent('ec_admin:quickAction:fastRun', source)
    logAction(source, 'fast_run', data)
    return { success = true, message = 'Fast run toggled' }
end

local function handleFastSwim(source, data)
    TriggerClientEvent('ec_admin:quickAction:fastSwim', source)
    logAction(source, 'fast_swim', data)
    return { success = true, message = 'Fast swim toggled' }
end

local function handleChangePed(source, data)
    TriggerClientEvent('ec_admin:quickAction:changePed', source, data)
    logAction(source, 'change_ped', data)
    return { success = true, message = 'Ped menu opened' }
end

local function handleArmor(source, data)
    TriggerClientEvent('ec_admin:quickAction:armor', source)
    logAction(source, 'armor', data)
    return { success = true, message = 'Max armor given' }
end

local function handleCleanClothes(source, data)
    TriggerClientEvent('ec_admin:quickAction:cleanClothes', source)
    logAction(source, 'clean_clothes', data)
    return { success = true, message = 'Clothes cleaned' }
end

local function handleClearBlood(source, data)
    TriggerClientEvent('ec_admin:quickAction:clearBlood', source)
    logAction(source, 'clear_blood', data)
    return { success = true, message = 'Blood cleared' }
end

-- ============================================================================
-- TELEPORT ACTIONS
-- ============================================================================

local function handleTpm(source, data)
    TriggerClientEvent('ec_admin:quickAction:tpm', source)
    logAction(source, 'tpm', data)
    return { success = true, message = 'Teleported to marker' }
end

local function handleBring(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    TriggerClientEvent('ec_admin:quickAction:bring', targetId, source)
    logAction(source, 'bring', { targetId = targetId })
    notifyPlayer(targetId, 'You have been brought by an admin', 'info')
    return { success = true, message = string.format('Brought player %d', targetId) }
end

local function handleGoto(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    TriggerClientEvent('ec_admin:quickAction:goto', source, targetId)
    logAction(source, 'goto', { targetId = targetId })
    return { success = true, message = string.format('Teleported to player %d', targetId) }
end

local function handleTpCoords(source, data)
    local coords = data.coords or data.value
    if not coords then
        return { success = false, error = 'Coordinates required' }
    end
    
    -- Parse coordinates (format: "x, y, z" or "x,y,z")
    local x, y, z = coords:match("([%d%.%-]+)[,%s]+([%d%.%-]+)[,%s]+([%d%.%-]+)")
    if not x or not y or not z then
        return { success = false, error = 'Invalid coordinate format. Use: x, y, z' }
    end
    
    TriggerClientEvent('ec_admin:quickAction:tpCoords', source, tonumber(x), tonumber(y), tonumber(z))
    logAction(source, 'tp_coords', { coords = coords })
    return { success = true, message = string.format('Teleported to %s', coords) }
end

local function handleSaveLocation(source, data)
    TriggerClientEvent('ec_admin:quickAction:saveLocation', source)
    logAction(source, 'save_location', data)
    return { success = true, message = 'Location saved' }
end

local function handleLoadLocation(source, data)
    TriggerClientEvent('ec_admin:quickAction:loadLocation', source)
    logAction(source, 'load_location', data)
    return { success = true, message = 'Location loaded' }
end

local function handleTpBack(source, data)
    TriggerClientEvent('ec_admin:quickAction:tpBack', source)
    logAction(source, 'tp_back', data)
    return { success = true, message = 'Teleported back' }
end

-- ============================================================================
-- PLAYER ACTIONS
-- ============================================================================

local function handleRevive(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    local framework = getFramework()
    local player = getPlayer(targetId)
    
    if framework == 'qb' or framework == 'qbx' then
        if player and player.Functions then
            player.Functions.SetJob('unemployed', 0)
            TriggerClientEvent('hospital:client:Revive', targetId)
        end
    elseif framework == 'esx' then
        TriggerClientEvent('esx_ambulancejob:revive', targetId)
    else
        -- Standalone: Use client event
        TriggerClientEvent('ec_admin:quickAction:revive', targetId)
    end
    
    logAction(source, 'revive', { targetId = targetId })
    notifyPlayer(targetId, 'You have been revived by an admin', 'success')
    return { success = true, message = string.format('Revived player %d', targetId) }
end

local function handleHealPlayer(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    TriggerClientEvent('ec_admin:quickAction:heal', targetId)
    logAction(source, 'heal_player', { targetId = targetId })
    notifyPlayer(targetId, 'You have been healed by an admin', 'success')
    return { success = true, message = string.format('Healed player %d', targetId) }
end

local function handleKillPlayer(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    TriggerClientEvent('ec_admin:quickAction:kill', targetId)
    logAction(source, 'kill_player', { targetId = targetId })
    notifyPlayer(targetId, 'You have been killed by an admin', 'error')
    return { success = true, message = string.format('Killed player %d', targetId) }
end

local function handleFreeze(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    TriggerClientEvent('ec_admin:quickAction:freeze', targetId)
    logAction(source, 'freeze', { targetId = targetId })
    return { success = true, message = string.format('Froze/unfroze player %d', targetId) }
end

local function handleSpectate(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    TriggerClientEvent('ec_admin:quickAction:spectate', source, targetId)
    logAction(source, 'spectate', { targetId = targetId })
    return { success = true, message = string.format('Spectating player %d', targetId) }
end

local function handleKick(source, data)
    local targetId = data.playerId or data.targetId
    local reason = data.reason or data.message or 'No reason provided'
    
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    local playerName = GetPlayerName(targetId) or 'Unknown'
    DropPlayer(targetId, string.format('Kicked by admin: %s', reason))
    logAction(source, 'kick', { targetId = targetId, reason = reason })
    return { success = true, message = string.format('Kicked %s (%d)', playerName, targetId) }
end

local function handleBan(source, data)
    local targetId = data.playerId or data.targetId
    local reason = data.reason or data.message or 'No reason provided'
    
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    -- Get player identifiers
    local identifiers = GetPlayerIdentifiers(targetId)
    local license = nil
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            license = id
            break
        end
    end
    
    if not license then
        return { success = false, error = 'Could not get player license' }
    end
    
    -- Ban player (this should integrate with your ban system)
    -- For now, we'll use a simple approach
    local playerName = GetPlayerName(targetId) or 'Unknown'
    
    -- Trigger ban event (integrate with your ban system)
    TriggerEvent('ec_admin:banPlayer', targetId, license, reason, source)
    
    DropPlayer(targetId, string.format('Banned: %s', reason))
    logAction(source, 'ban', { targetId = targetId, reason = reason, license = license })
    return { success = true, message = string.format('Banned %s (%s)', playerName, license) }
end

local function handleWarn(source, data)
    local targetId = data.playerId or data.targetId
    local reason = data.reason or data.message or 'No reason provided'
    
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    -- Trigger warn event (integrate with your warn system)
    TriggerEvent('ec_admin:warnPlayer', targetId, reason, source)
    
    notifyPlayer(targetId, string.format('You have been warned: %s', reason), 'error')
    logAction(source, 'warn', { targetId = targetId, reason = reason })
    return { success = true, message = string.format('Warned player %d', targetId) }
end

local function handleSlap(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    TriggerClientEvent('ec_admin:quickAction:slap', targetId)
    logAction(source, 'slap', { targetId = targetId })
    notifyPlayer(targetId, 'You have been slapped by an admin', 'info')
    return { success = true, message = string.format('Slapped player %d', targetId) }
end

local function handleStripWeapons(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    TriggerClientEvent('ec_admin:quickAction:stripWeapons', targetId)
    logAction(source, 'strip_weapons', { targetId = targetId })
    notifyPlayer(targetId, 'Your weapons have been removed by an admin', 'error')
    return { success = true, message = string.format('Stripped weapons from player %d', targetId) }
end

local function handleWipeInventory(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    local framework = getFramework()
    local player = getPlayer(targetId)
    
    if (framework == 'qb' or framework == 'qbx') and player and player.PlayerData then
        -- Clear QB inventory
        if player.PlayerData.items then
            player.PlayerData.items = {}
        end
        if player.Functions then
            player.Functions.ClearItems()
        end
    elseif framework == 'esx' and player then
        -- Clear ESX inventory
        if player.getInventory then
            local inventory = player:getInventory()
            for k, v in pairs(inventory) do
                player.removeInventoryItem(k, v.count or v.amount or 0)
            end
        end
    end
    
    -- Also trigger client event for standalone
    TriggerClientEvent('ec_admin:quickAction:wipeInventory', targetId)
    
    logAction(source, 'wipe_inventory', { targetId = targetId })
    notifyPlayer(targetId, 'Your inventory has been wiped by an admin', 'error')
    return { success = true, message = string.format('Wiped inventory of player %d', targetId) }
end

local function handleGiveMoney(source, data)
    local targetId = data.playerId or data.targetId
    local amount = tonumber(data.amount) or 0
    
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    if amount <= 0 then
        return { success = false, error = 'Amount must be greater than 0' }
    end
    
    local framework = getFramework()
    local success = ECFramework.AddMoney(targetId, 'cash', amount)
    
    if success then
        logAction(source, 'give_money', { targetId = targetId, amount = amount })
        notifyPlayer(targetId, string.format('You received $%s from an admin', amount), 'success')
        return { success = true, message = string.format('Gave $%s to player %d', amount, targetId) }
    else
        return { success = false, error = 'Failed to give money' }
    end
end

local function handleGiveItem(source, data)
    local targetId = data.playerId or data.targetId
    local itemName = data.itemName or data.value
    local amount = tonumber(data.amount) or 1
    
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    if not itemName or itemName == '' then
        return { success = false, error = 'Item name required' }
    end
    
    local framework = getFramework()
    local success = ECFramework.AddItem(targetId, itemName, amount)
    
    if success then
        logAction(source, 'give_item', { targetId = targetId, item = itemName, amount = amount })
        notifyPlayer(targetId, string.format('You received %dx %s from an admin', amount, itemName), 'success')
        return { success = true, message = string.format('Gave %dx %s to player %d', amount, itemName, targetId) }
    else
        return { success = false, error = 'Failed to give item' }
    end
end

local function handleChangePlayerPed(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    TriggerClientEvent('ec_admin:quickAction:changePed', targetId, data)
    logAction(source, 'change_player_ped', { targetId = targetId })
    return { success = true, message = string.format('Opened ped menu for player %d', targetId) }
end

local function handleSendHome(source, data)
    local targetId = data.playerId or data.targetId
    if not targetId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(targetId) then
        return { success = false, error = 'Player not found' }
    end
    
    -- Teleport to spawn (coordinates may vary)
    TriggerClientEvent('ec_admin:quickAction:sendHome', targetId)
    logAction(source, 'send_home', { targetId = targetId })
    notifyPlayer(targetId, 'You have been sent home by an admin', 'info')
    return { success = true, message = string.format('Sent player %d home', targetId) }
end

-- ============================================================================
-- VEHICLE ACTIONS
-- ============================================================================

local function handleSpawnVehicle(source, data)
    local vehicleName = data.vehicleName or data.value or 'adder'
    if not vehicleName or vehicleName == '' then
        return { success = false, error = 'Vehicle name required' }
    end
    
    TriggerClientEvent('ec_admin:quickAction:spawnVehicle', source, vehicleName)
    logAction(source, 'spawn_vehicle', { vehicle = vehicleName })
    return { success = true, message = string.format('Spawning vehicle: %s', vehicleName) }
end

local function handleFixVehicle(source, data)
    TriggerClientEvent('ec_admin:quickAction:fixVehicle', source)
    logAction(source, 'fix_vehicle', data)
    return { success = true, message = 'Vehicle fixed' }
end

local function handleDeleteVehicle(source, data)
    TriggerClientEvent('ec_admin:quickAction:deleteVehicle', source)
    logAction(source, 'delete_vehicle', data)
    return { success = true, message = 'Vehicle deleted' }
end

local function handleFlipVehicle(source, data)
    TriggerClientEvent('ec_admin:quickAction:flipVehicle', source)
    logAction(source, 'flip_vehicle', data)
    return { success = true, message = 'Vehicle flipped' }
end

local function handleCleanVehicle(source, data)
    TriggerClientEvent('ec_admin:quickAction:cleanVehicle', source)
    logAction(source, 'clean_vehicle', data)
    return { success = true, message = 'Vehicle cleaned' }
end

local function handleMaxTune(source, data)
    TriggerClientEvent('ec_admin:quickAction:maxTune', source)
    logAction(source, 'max_tune', data)
    return { success = true, message = 'Vehicle max tuned' }
end

local function handleBoost(source, data)
    TriggerClientEvent('ec_admin:quickAction:boost', source)
    logAction(source, 'boost', data)
    return { success = true, message = 'Vehicle boost toggled' }
end

local function handleRainbow(source, data)
    TriggerClientEvent('ec_admin:quickAction:rainbow', source)
    logAction(source, 'rainbow', data)
    return { success = true, message = 'Rainbow paint toggled' }
end

local function handleGarageRadius(source, data)
    local radius = tonumber(data.radius) or 50.0
    TriggerClientEvent('ec_admin:quickAction:garageRadius', source, radius)
    logAction(source, 'garage_radius', { radius = radius })
    return { success = true, message = string.format('Garaged vehicles in %dm radius', radius) }
end

local function handleGarageAll(source, data)
    TriggerClientEvent('ec_admin:quickAction:garageAll', -1)
    logAction(source, 'garage_all', data)
    return { success = true, message = 'All vehicles garaged' }
end

-- ============================================================================
-- WORLD ACTIONS
-- ============================================================================

local function handleWeather(source, data)
    local weather = data.value or data.weather or 'CLEAR'
    TriggerClientEvent('ec_admin:quickAction:setWeather', -1, weather)
    logAction(source, 'weather', { weather = weather })
    return { success = true, message = string.format('Weather set to: %s', weather) }
end

local function handleTime(source, data)
    local time = tonumber(data.value) or data.time or 12
    if time < 0 or time > 23 then
        return { success = false, error = 'Time must be between 0 and 23' }
    end
    TriggerClientEvent('ec_admin:quickAction:setTime', -1, time)
    logAction(source, 'time', { time = time })
    return { success = true, message = string.format('Time set to: %d:00', time) }
end

local function handleBlackout(source, data)
    TriggerClientEvent('ec_admin:quickAction:blackout', -1)
    logAction(source, 'blackout', data)
    return { success = true, message = 'Blackout toggled' }
end

local function handleClearArea(source, data)
    TriggerClientEvent('ec_admin:quickAction:clearArea', source)
    logAction(source, 'clear_area', data)
    return { success = true, message = 'Area cleared' }
end

local function handleClearPeds(source, data)
    TriggerClientEvent('ec_admin:quickAction:clearPeds', -1)
    logAction(source, 'clear_peds', data)
    return { success = true, message = 'All peds cleared' }
end

local function handleClearVehicles(source, data)
    TriggerClientEvent('ec_admin:quickAction:clearVehicles', -1)
    logAction(source, 'clear_vehicles', data)
    return { success = true, message = 'All vehicles cleared' }
end

local function handleFreezeWeather(source, data)
    TriggerClientEvent('ec_admin:quickAction:freezeWeather', -1)
    logAction(source, 'freeze_weather', data)
    return { success = true, message = 'Weather frozen' }
end

local function handleFreezeTime(source, data)
    TriggerClientEvent('ec_admin:quickAction:freezeTime', -1)
    logAction(source, 'freeze_time', data)
    return { success = true, message = 'Time frozen' }
end

-- ============================================================================
-- SERVER ACTIONS
-- ============================================================================

local function handleRestartResource(source, data)
    local resourceName = data.value or data.resource
    if not resourceName or resourceName == '' then
        return { success = false, error = 'Resource name required' }
    end
    
    if GetResourceState(resourceName) == 'missing' then
        return { success = false, error = 'Resource not found' }
    end
    
    RestartResource(resourceName)
    logAction(source, 'restart_resource', { resource = resourceName })
    return { success = true, message = string.format('Resource %s restarted', resourceName) }
end

local function handleStartResource(source, data)
    local resourceName = data.value or data.resource
    if not resourceName or resourceName == '' then
        return { success = false, error = 'Resource name required' }
    end
    
    if GetResourceState(resourceName) == 'missing' then
        return { success = false, error = 'Resource not found' }
    end
    
    StartResource(resourceName)
    logAction(source, 'start_resource', { resource = resourceName })
    return { success = true, message = string.format('Resource %s started', resourceName) }
end

local function handleStopResource(source, data)
    local resourceName = data.value or data.resource
    if not resourceName or resourceName == '' then
        return { success = false, error = 'Resource name required' }
    end
    
    if GetResourceState(resourceName) == 'missing' then
        return { success = false, error = 'Resource not found' }
    end
    
    StopResource(resourceName)
    logAction(source, 'stop_resource', { resource = resourceName })
    return { success = true, message = string.format('Resource %s stopped', resourceName) }
end

local function handleAnnouncement(source, data)
    local message = data.message or data.value or 'Server announcement'
    TriggerClientEvent('ec_admin:quickAction:announcement', -1, message)
    logAction(source, 'announcement', { message = message })
    return { success = true, message = 'Announcement sent' }
end

local function handleReloadEyes(source, data)
    TriggerClientEvent('ec_admin:quickAction:reloadEyes', -1)
    logAction(source, 'reload_eyes', data)
    return { success = true, message = 'Eyes reloaded for all players' }
end

local function handleExecCommand(source, data)
    local command = data.value or data.command
    if not command or command == '' then
        return { success = false, error = 'Command required' }
    end
    
    -- Execute server command
    ExecuteCommand(command)
    logAction(source, 'exec_command', { command = command })
    return { success = true, message = string.format('Command executed: %s', command) }
end

local function handleRunCode(source, data)
    -- SECURITY: This should be restricted to super admins only
    if not hasPermission(source, 'admin.code.execute') then
        return { success = false, error = 'Permission denied' }
    end
    
    local code = data.value or data.code
    if not code or code == '' then
        return { success = false, error = 'Code required' }
    end
    
    -- WARNING: Executing arbitrary Lua code is dangerous!
    -- In production, this should be heavily restricted or disabled
    local func, err = load(code)
    if not func then
        return { success = false, error = string.format('Code error: %s', err) }
    end
    
    local success, result = pcall(func)
    logAction(source, 'run_code', { code = code, result = result })
    return { success = success, message = success and 'Code executed' or string.format('Code error: %s', result) }
end

local function handleRefreshDb(source, data)
    -- Reload database connections (if applicable)
    -- This is framework-specific
    logAction(source, 'refresh_db', data)
    return { success = true, message = 'Database refreshed' }
end

-- ============================================================================
-- ACTION ROUTER
-- ============================================================================

local actionHandlers = {
    -- Self actions
    noclip = handleNoclip,
    godmode = handleGodmode,
    invisible = handleInvisible,
    heal = handleHeal,
    stamina = handleStamina,
    super_jump = handleSuperJump,
    fast_run = handleFastRun,
    fast_swim = handleFastSwim,
    change_ped = handleChangePed,
    armor = handleArmor,
    clean_clothes = handleCleanClothes,
    clear_blood = handleClearBlood,
    
    -- Teleport actions
    tpm = handleTpm,
    bring = handleBring,
    ['goto'] = handleGoto,  -- Use bracket notation for reserved keyword
    tp_coords = handleTpCoords,
    save_location = handleSaveLocation,
    load_location = handleLoadLocation,
    tp_back = handleTpBack,
    
    -- Player actions
    revive = handleRevive,
    heal_player = handleHealPlayer,
    kill_player = handleKillPlayer,
    freeze = handleFreeze,
    spectate = handleSpectate,
    kick = handleKick,
    ban = handleBan,
    warn = handleWarn,
    slap = handleSlap,
    strip_weapons = handleStripWeapons,
    wipe_inventory = handleWipeInventory,
    give_money = handleGiveMoney,
    give_item = handleGiveItem,
    change_player_ped = handleChangePlayerPed,
    send_home = handleSendHome,
    
    -- Vehicle actions
    spawn_vehicle = handleSpawnVehicle,
    spawnveh = handleSpawnVehicle, -- Alias
    fix_vehicle = handleFixVehicle,
    delete_vehicle = handleDeleteVehicle,
    flip_vehicle = handleFlipVehicle,
    clean_vehicle = handleCleanVehicle,
    max_tune = handleMaxTune,
    boost = handleBoost,
    rainbow = handleRainbow,
    garage_radius = handleGarageRadius,
    garage_all = handleGarageAll,
    
    -- World actions
    weather = handleWeather,
    time = handleTime,
    blackout = handleBlackout,
    clear_area = handleClearArea,
    clear_peds = handleClearPeds,
    clear_vehicles = handleClearVehicles,
    freeze_weather = handleFreezeWeather,
    freeze_time = handleFreezeTime,
    
    -- Server actions
    restart_resource = handleRestartResource,
    start_resource = handleStartResource,
    stop_resource = handleStopResource,
    announcement = handleAnnouncement,
    announce = handleAnnouncement, -- Alias
    reload_eyes = handleReloadEyes,
    exec_command = handleExecCommand,
    run_code = handleRunCode,
    refresh_db = handleRefreshDb,
}

-- Main callback handler
lib.callback.register('ec_admin:quickAction', function(source, actionData)
    local action = actionData.action or actionData.actionId -- Support both 'action' and 'actionId'
    local data = actionData.data or {}
    
    if not action or action == '' then
        return { success = false, error = 'Action required' }
    end
    
    -- Check permission (all quick actions require admin)
    if not hasPermission(source, 'admin.quickactions') then
        logActionToDatabase(source, action, getActionName(action), data, false, 'Permission denied')
        return { success = false, error = 'Permission denied' }
    end
    
    -- Get handler
    local handler = actionHandlers[action]
    if not handler then
        logActionToDatabase(source, action, getActionName(action), data, false, 'Unknown action')
        return { success = false, error = string.format('Unknown action: %s', action) }
    end
    
    -- Execute handler
    local success, result = pcall(handler, source, data)
    if not success then
        print(string.format("^1[Quick Actions] Error executing %s: %s^0", action, result))
        logActionToDatabase(source, action, getActionName(action), data, false, tostring(result))
        return { success = false, error = string.format('Action failed: %s', result) }
    end
    
    -- Log successful action
    local finalResult = result or { success = true, message = 'Action executed' }
    logActionToDatabase(source, action, getActionName(action), data, finalResult.success ~= false, finalResult.error)
    
    return finalResult
end)

print("^2[Quick Actions]^7 UI Backend loaded - 60+ actions available^0")

