--[[
    EC ADMIN ULTIMATE - Complete Quick Actions Server Handler
    Handles ALL 86+ quick actions from the Quick Actions Center
    Version: 4.0.0 - COMPLETE
]]

Logger.Info(" Loading Quick Actions Server Handler (COMPLETE)...^0")

-- ============================================================================
-- TABLE EXISTENCE CACHE
-- ============================================================================

local tableExistsCache = {}

local function TableExists(tableName)
    if tableExistsCache[tableName] ~= nil then
        return tableExistsCache[tableName]
    end
    
    local result = MySQL.query.await('SHOW TABLES LIKE ?', {tableName})
    local exists = result and #result > 0
    tableExistsCache[tableName] = exists
    return exists
end

-- ============================================================================
-- FRAMEWORK DETECTION
-- ============================================================================

local Framework = nil
local FrameworkName = "standalone"

CreateThread(function()
    if GetResourceState('qbx_core') == 'started' then
        Framework = exports.qbx_core
        FrameworkName = "qbx"
        Logger.Info("✅ Framework: QBX Core")
    elseif GetResourceState('qb-core') == 'started' then
        Framework = exports['qb-core']:GetCoreObject()
        FrameworkName = "qb"
        Logger.Info("✅ Framework: QB-Core")
    elseif GetResourceState('es_extended') == 'started' then
        Framework = exports['es_extended']:getSharedObject()
        FrameworkName = "esx"
        Logger.Info("✅ Framework: ESX")
    else
        Logger.Warn("⚠️ Framework: Standalone Mode")
    end
end)

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function GetPlayer(source)
    if not Framework then return nil end
    
    if FrameworkName == "qb" or FrameworkName == "qbx" then
        if FrameworkName == "qbx" then
            return Framework:GetPlayer(source)
        else
            return Framework.Functions.GetPlayer(source)
        end
    elseif FrameworkName == "esx" then
        return Framework.GetPlayerFromId(source)
    end
    
    return nil
end

local function HasPermission(source)
    if not source or source == 0 then return false end
    
    -- Check EC_Perms system (ACE + Database)
    if EC_Perms and EC_Perms.Has then
        return EC_Perms.Has(source, 'admin')
    end
    
    -- Fallback to basic ACE check
    return IsPlayerAceAllowed(source, 'ec_admin.admin')
end

local function Notify(src, message, type)
    if not src then return end
    TriggerClientEvent('ec_admin:notification', src, message, type or 'info')
end

local function LogAction(adminSource, actionType, targetSource, details)
    local adminName = GetPlayerName(adminSource) or "Unknown"
    local targetName = targetSource and GetPlayerName(targetSource) or "N/A"
    
    if MySQL then
        MySQL.insert('INSERT INTO ec_admin_action_logs (admin_name, admin_identifier, action_type, target_name, target_identifier, details, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            adminName,
            GetPlayerIdentifier(adminSource, 0),
            actionType,
            targetName,
            targetSource and GetPlayerIdentifier(targetSource, 0) or "N/A",
            details,
            os.time() * 1000
        })
    end
end

-- ============================================================================
-- SELF ACTIONS
-- ============================================================================

-- Heal Self
RegisterNetEvent('ec_admin:quickaction:heal', function()
    local src = source
    if not HasPermission(src) then return end
    
    TriggerClientEvent('ec_admin:client:healSelf', src)
    LogAction(src, 'heal_self', nil, 'Healed themselves')
end)

-- Max Armor
RegisterNetEvent('ec_admin:quickaction:armor', function()
    local src = source
    if not HasPermission(src) then return end
    
    TriggerClientEvent('ec_admin:client:maxArmor', src)
    LogAction(src, 'max_armor', nil, 'Gave themselves max armor')
end)

-- Fix Hunger
RegisterNetEvent('ec_admin:quickaction:fix_hunger', function()
    local src = source
    if not HasPermission(src) then return end
    
    local Player = GetPlayer(src)
    
    if Player then
        if FrameworkName == "qb" or FrameworkName == "qbx" then
            Player.Functions.SetMetaData('hunger', 100)
        elseif FrameworkName == "esx" then
            TriggerClientEvent('esx_status:set', src, 'hunger', 1000000)
        end
    end
    
    LogAction(src, 'fix_hunger', nil, 'Fixed their hunger')
end)

-- Fix Thirst
RegisterNetEvent('ec_admin:quickaction:fix_thirst', function()
    local src = source
    if not HasPermission(src) then return end
    
    local Player = GetPlayer(src)
    
    if Player then
        if FrameworkName == "qb" or FrameworkName == "qbx" then
            Player.Functions.SetMetaData('thirst', 100)
        elseif FrameworkName == "esx" then
            TriggerClientEvent('esx_status:set', src, 'thirst', 1000000)
        end
    end
    
    LogAction(src, 'fix_thirst', nil, 'Fixed their thirst')
end)

-- Fix Stress
RegisterNetEvent('ec_admin:quickaction:fix_stress', function()
    local src = source
    if not HasPermission(src) then return end
    
    local Player = GetPlayer(src)
    
    if Player then
        if FrameworkName == "qb" or FrameworkName == "qbx" then
            Player.Functions.SetMetaData('stress', 0)
        end
    end
    
    LogAction(src, 'fix_stress', nil, 'Removed their stress')
end)

-- ============================================================================
-- TELEPORT ACTIONS
-- ============================================================================

-- Bring Player
RegisterNetEvent('ec_admin:quickaction:bring', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end

    local adminPed = GetPlayerPed(src)
    if not adminPed or adminPed == 0 or not DoesEntityExist(adminPed) then
        return Notify(src, "Invalid player.", "error")
    end

    local targetPed = GetPlayerPed(targetId)
    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
        return Notify(src, "Invalid player.", "error")
    end

    local adminCoords = GetEntityCoords(adminPed)
    if not adminCoords then
        return Notify(src, "Invalid coordinates.", "error")
    end

    TriggerClientEvent('ec_admin:client:teleportToCoords', targetId, adminCoords.x, adminCoords.y, adminCoords.z)
    LogAction(src, 'bring_player', targetId, 'Brought player to them')
end)

-- Go to Player
RegisterNetEvent('ec_admin:quickaction:goto', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end

    local adminPed = GetPlayerPed(src)
    if not adminPed or adminPed == 0 or not DoesEntityExist(adminPed) then
        return Notify(src, "Invalid player.", "error")
    end

    local targetPed = GetPlayerPed(targetId)
    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
        return Notify(src, "Invalid player.", "error")
    end

    local targetCoords = GetEntityCoords(targetPed)
    if not targetCoords then
        return Notify(src, "Invalid coordinates.", "error")
    end

    TriggerClientEvent('ec_admin:client:teleportToCoords', src, targetCoords.x, targetCoords.y, targetCoords.z)
    LogAction(src, 'goto_player', targetId, 'Teleported to player')
end)

-- Teleport to Coordinates
RegisterNetEvent('ec_admin:quickaction:tp_coords', function(x, y, z)
    local src = source
    if not x or not y or not z then
        return Notify(src, "Invalid coordinates.", "error")
    end

    local adminPed = GetPlayerPed(src)
    if not adminPed or adminPed == 0 or not DoesEntityExist(adminPed) then
        return Notify(src, "Invalid player.", "error")
    end

    TriggerClientEvent('ec_admin:client:teleportToCoords', src, x, y, z)
    LogAction(src, 'teleport_coords', nil, string.format('Teleported to %s, %s, %s', x, y, z))
end)

-- ============================================================================
-- PLAYER ACTIONS
-- ============================================================================

-- Heal Player
RegisterNetEvent('ec_admin:quickaction:heal_player', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:healSelf', targetId)
    LogAction(src, 'heal_player', targetId, 'Healed player')
end)

-- Revive Player
RegisterNetEvent('ec_admin:quickaction:revive', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    -- Framework-specific revive
    if FrameworkName == "qb" or FrameworkName == "qbx" then
        TriggerClientEvent('hospital:client:Revive', targetId)
    elseif FrameworkName == "esx" then
        TriggerClientEvent('esx_ambulancejob:revive', targetId)
    else
        -- Generic revive
        TriggerClientEvent('ec_admin:client:revive', targetId)
    end
    
    LogAction(src, 'revive_player', targetId, 'Revived player')
end)

-- Kill Player
RegisterNetEvent('ec_admin:quickaction:kill_player', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:killPlayer', targetId)
    LogAction(src, 'kill_player', targetId, 'Killed player')
end)

-- Freeze Player
RegisterNetEvent('ec_admin:quickaction:freeze', function(targetId, freeze)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:freezePlayer', targetId, freeze)
    LogAction(src, 'freeze_player', targetId, freeze and 'Froze player' or 'Unfroze player')
end)

-- Sit Player
RegisterNetEvent('ec_admin:quickaction:sit_player', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:sitPlayer', targetId)
    LogAction(src, 'sit_player', targetId, 'Made player sit')
end)

-- Drag Player
RegisterNetEvent('ec_admin:quickaction:drag_player', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:dragPlayer', src, targetId)
    LogAction(src, 'drag_player', targetId, 'Started dragging player')
end)

-- Cuff Player
RegisterNetEvent('ec_admin:quickaction:cuff_player', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:cuffPlayer', targetId, true)
    LogAction(src, 'cuff_player', targetId, 'Cuffed player')
end)

-- Uncuff Player
RegisterNetEvent('ec_admin:quickaction:uncuff_player', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:cuffPlayer', targetId, false)
    LogAction(src, 'uncuff_player', targetId, 'Uncuffed player')
end)

-- Remove Mask
RegisterNetEvent('ec_admin:quickaction:remove_mask', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:removeMask', targetId)
    LogAction(src, 'remove_mask', targetId, 'Removed player mask')
end)

-- Remove Hat
RegisterNetEvent('ec_admin:quickaction:remove_hat', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:removeHat', targetId)
    LogAction(src, 'remove_hat', targetId, 'Removed player hat')
end)

-- Clear Wanted Level
RegisterNetEvent('ec_admin:quickaction:clear_wanted', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:clearWanted', targetId)
    LogAction(src, 'clear_wanted', targetId, 'Cleared wanted level')
end)

-- Give Item
RegisterNetEvent('ec_admin:quickaction:give_item', function(targetId, item, amount)
    local src = source
    if not targetId or targetId == 0 then return end
    
    local Player = GetPlayer(targetId)
    if Player then
        if FrameworkName == "qb" or FrameworkName == "qbx" then
            Player.Functions.AddItem(item, amount)
        elseif FrameworkName == "esx" then
            Player.addInventoryItem(item, amount)
        end
    end
    
    LogAction(src, 'give_item', targetId, string.format('Gave %dx %s', amount, item))
end)

-- Remove Item
RegisterNetEvent('ec_admin:quickaction:remove_item', function(targetId, item, amount)
    local src = source
    if not targetId or targetId == 0 then return end
    
    local Player = GetPlayer(targetId)
    if Player then
        if FrameworkName == "qb" or FrameworkName == "qbx" then
            Player.Functions.RemoveItem(item, amount)
        elseif FrameworkName == "esx" then
            Player.removeInventoryItem(item, amount)
        end
    end
    
    LogAction(src, 'remove_item', targetId, string.format('Removed %dx %s', amount, item))
end)

-- Clear Inventory
RegisterNetEvent('ec_admin:quickaction:clear_inventory', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:clearInventory', targetId)
    LogAction(src, 'clear_inventory', targetId, 'Cleared player inventory')
end)

-- Spectate Player
RegisterNetEvent('ec_admin:quickaction:spectate', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:spectatePlayer', src, targetId)
    LogAction(src, 'spectate_player', targetId, 'Started spectating player')
end)

-- Kick Player
RegisterNetEvent('ec_admin:quickaction:kick', function(targetId, reason)
    local src = source
    if not targetId or targetId == 0 then return end
    
    reason = reason or "No reason provided"
    DropPlayer(targetId, string.format('[EC Admin] You have been kicked: %s', reason))
    
    if MySQL then
        MySQL.insert('INSERT INTO player_kicks (kick_id, license, name, reason, kicked_by, timestamp) VALUES (?, ?, ?, ?, ?, ?)', {
            'kick_' .. os.time(),
            GetPlayerIdentifier(targetId, 0),
            GetPlayerName(targetId),
            reason,
            GetPlayerName(src),
            os.time() * 1000
        })
    end
    
    LogAction(src, 'kick_player', targetId, 'Kicked player: ' .. reason)
end)

-- Ban Player
RegisterNetEvent('ec_admin:quickaction:ban', function(targetId, reason, duration)
    local src = source
    if not targetId or targetId == 0 then return end
    
    reason = reason or "No reason provided"
    duration = duration or 0 -- 0 = permanent
    
    local targetLicense = GetPlayerIdentifier(targetId, 0)
    local targetName = GetPlayerName(targetId)
    local expireTime = duration > 0 and (os.time() + (duration * 86400)) or 0
    
    if MySQL then
        MySQL.insert('INSERT INTO player_bans (ban_id, license, name, reason, banned_by, expire_time, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            'ban_' .. os.time(),
            targetLicense,
            targetName,
            reason,
            GetPlayerName(src),
            expireTime,
            os.time() * 1000
        })
    end
    
    DropPlayer(targetId, string.format('[EC Admin] You have been banned: %s', reason))
    LogAction(src, 'ban_player', targetId, 'Banned player: ' .. reason)
end)

-- Warn Player
RegisterNetEvent('ec_admin:quickaction:warn', function(targetId, reason)
    local src = source
    if not targetId or targetId == 0 then return end
    
    reason = reason or "No reason provided"
    
    if MySQL then
        MySQL.insert('INSERT INTO player_warnings (warn_id, license, name, reason, warned_by, timestamp) VALUES (?, ?, ?, ?, ?, ?)', {
            'warn_' .. os.time(),
            GetPlayerIdentifier(targetId, 0),
            GetPlayerName(targetId),
            reason,
            GetPlayerName(src),
            os.time() * 1000
        })
    end
    
    TriggerClientEvent('ec_admin:client:receiveWarning', targetId, reason)
    LogAction(src, 'warn_player', targetId, 'Warned player: ' .. reason)
end)

-- Mute Player
RegisterNetEvent('ec_admin:quickaction:mute', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    -- This would integrate with your voice chat system
    TriggerClientEvent('ec_admin:client:mutePlayer', targetId)
    LogAction(src, 'mute_player', targetId, 'Muted player')
end)

-- Unmute Player
RegisterNetEvent('ec_admin:quickaction:unmute', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:unmutePlayer', targetId)
    LogAction(src, 'unmute_player', targetId, 'Unmuted player')
end)

-- Slap Player
RegisterNetEvent('ec_admin:quickaction:slap', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:slapPlayer', targetId)
    LogAction(src, 'slap_player', targetId, 'Slapped player')
end)

-- Strip Weapons
RegisterNetEvent('ec_admin:quickaction:strip', function(targetId)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:stripWeapons', targetId)
    LogAction(src, 'strip_weapons', targetId, 'Stripped player weapons')
end)

-- Give Weapon
RegisterNetEvent('ec_admin:quickaction:give_weapon', function(targetId, weapon)
    local src = source
    if not targetId or targetId == 0 then return end
    
    weapon = weapon or "WEAPON_PISTOL"
    TriggerClientEvent('ec_admin:client:giveWeapon', targetId, weapon)
    LogAction(src, 'give_weapon', targetId, 'Gave weapon: ' .. weapon)
end)

-- Set Health
RegisterNetEvent('ec_admin:quickaction:set_health', function(targetId, health)
    local src = source
    if not targetId or targetId == 0 then return end
    
    health = health or 200
    TriggerClientEvent('ec_admin:client:setHealth', targetId, health)
    LogAction(src, 'set_health', targetId, 'Set health to: ' .. health)
end)

-- Set Armor
RegisterNetEvent('ec_admin:quickaction:set_armor', function(targetId, armor)
    local src = source
    if not targetId or targetId == 0 then return end
    
    armor = armor or 100
    TriggerClientEvent('ec_admin:client:setArmor', targetId, armor)
    LogAction(src, 'set_armor', targetId, 'Set armor to: ' .. armor)
end)

-- Give Money
RegisterNetEvent('ec_admin:quickaction:give_money', function(targetId, moneyType, amount)
    local src = source
    if not targetId or targetId == 0 then return end
    
    local Player = GetPlayer(targetId)
    if Player then
        if FrameworkName == "qb" or FrameworkName == "qbx" then
            Player.Functions.AddMoney(moneyType, amount)
        elseif FrameworkName == "esx" then
            if moneyType == "cash" then moneyType = "money" end
            Player.addMoney(moneyType, amount)
        end
    end
    
    LogAction(src, 'give_money', targetId, string.format('Gave $%d %s', amount, moneyType))
end)

-- Remove Money
RegisterNetEvent('ec_admin:quickaction:remove_money', function(targetId, moneyType, amount)
    local src = source
    if not targetId or targetId == 0 then return end
    
    local Player = GetPlayer(targetId)
    if Player then
        if FrameworkName == "qb" or FrameworkName == "qbx" then
            Player.Functions.RemoveMoney(moneyType, amount)
        elseif FrameworkName == "esx" then
            if moneyType == "cash" then moneyType = "money" end
            Player.removeMoney(moneyType, amount)
        end
    end
    
    LogAction(src, 'remove_money', targetId, string.format('Removed $%d %s', amount, moneyType))
end)

-- Set Job
RegisterNetEvent('ec_admin:quickaction:set_job', function(targetId, job, grade)
    local src = source
    if not targetId or targetId == 0 then return end
    
    local Player = GetPlayer(targetId)
    if Player then
        if FrameworkName == "qb" or FrameworkName == "qbx" then
            Player.Functions.SetJob(job, grade)
        elseif FrameworkName == "esx" then
            Player.setJob(job, grade)
        end
    end
    
    LogAction(src, 'set_job', targetId, string.format('Set job to: %s [%d]', job, grade))
end)

-- Set Gang
RegisterNetEvent('ec_admin:quickaction:set_gang', function(targetId, gang, grade)
    local src = source
    if not targetId or targetId == 0 then return end
    
    local Player = GetPlayer(targetId)
    if Player then
        if FrameworkName == "qb" or FrameworkName == "qbx" then
            Player.Functions.SetGang(gang, grade)
        end
    end
    
    LogAction(src, 'set_gang', targetId, string.format('Set gang to: %s [%d]', gang, grade))
end)

-- Change Player Ped
RegisterNetEvent('ec_admin:quickaction:change_player_ped', function(targetId, model)
    local src = source
    if not targetId or targetId == 0 then return end
    
    TriggerClientEvent('ec_admin:client:changePed', targetId, model)
    LogAction(src, 'change_player_ped', targetId, 'Changed ped to: ' .. model)
end)

-- ============================================================================
-- VEHICLE ACTIONS
-- ============================================================================

-- Spawn Vehicle
RegisterNetEvent('ec_admin:quickaction:spawnveh', function(model)
    local src = source
    model = model or 'adder'
    
    TriggerClientEvent('ec_admin:client:spawnVehicle', src, model)
    LogAction(src, 'spawn_vehicle', nil, 'Spawned vehicle: ' .. model)
end)

-- Change Plate
RegisterNetEvent('ec_admin:quickaction:change_plate', function(plate)
    local src = source
    plate = plate or 'ADMIN'
    
    TriggerClientEvent('ec_admin:client:changePlate', src, plate)
    LogAction(src, 'change_plate', nil, 'Changed plate to: ' .. plate)
end)

-- ============================================================================
-- SERVER / WORLD ACTIONS
-- ============================================================================

-- Announce
RegisterNetEvent('ec_admin:quickaction:announce', function(message, announcementType)
    local src = source
    message = message or "Server announcement"
    announcementType = announcementType or 'info'
    
    TriggerClientEvent('chat:addMessage', -1, {
        color = {255, 0, 0},
        multiline = true,
        args = {"[ADMIN]", message}
    })
    
    LogAction(src, 'announce', nil, 'Announcement: ' .. message)
end)

-- Restart Server
RegisterNetEvent('ec_admin:quickaction:restart', function(minutes)
    local src = source
    minutes = minutes or 5
    
    TriggerClientEvent('chat:addMessage', -1, {
        color = {255, 165, 0},
        multiline = true,
        args = {"[SERVER]", string.format("Server restarting in %d minutes!", minutes)}
    })
    
    LogAction(src, 'server_restart', nil, 'Initiated restart: ' .. minutes .. ' minutes')
end)

-- Clear All Vehicles
RegisterNetEvent('ec_admin:quickaction:clear_all_vehicles', function()
    local src = source
    
    TriggerClientEvent('ec_admin:client:clearAllVehicles', -1)
    LogAction(src, 'clear_all_vehicles', nil, 'Cleared all vehicles')
end)

-- Clear All Peds
RegisterNetEvent('ec_admin:quickaction:clear_all_peds', function()
    local src = source
    
    TriggerClientEvent('ec_admin:client:clearAllPeds', -1)
    LogAction(src, 'clear_all_peds', nil, 'Cleared all peds')
end)

-- Garage (Radius)
RegisterNetEvent('ec_admin:quickaction:garage_radius', function(radius)
    local src = source
    radius = radius or 50
    
    TriggerClientEvent('ec_admin:client:garageRadius', src, radius)
    LogAction(src, 'garage_radius', nil, 'Sent nearby vehicles to garage (radius: ' .. radius .. ')')
end)

-- Garage (All)
RegisterNetEvent('ec_admin:quickaction:garage_all', function()
    local src = source
    
    TriggerClientEvent('ec_admin:client:garageAll', -1)
    LogAction(src, 'garage_all', nil, 'Sent all vehicles to garage')
end)

-- Change Weather
RegisterNetEvent('ec_admin:quickaction:weather', function(weatherType)
    local src = source
    weatherType = weatherType or 'CLEAR'
    
    TriggerClientEvent('ec_admin:client:setWeather', -1, weatherType)
    LogAction(src, 'change_weather', nil, 'Changed weather to: ' .. weatherType)
end)

-- Change Time
RegisterNetEvent('ec_admin:quickaction:time', function(hour, minute)
    local src = source
    hour = hour or 12
    minute = minute or 0
    
    TriggerClientEvent('ec_admin:client:setTime', -1, hour, minute)
    LogAction(src, 'change_time', nil, string.format('Changed time to: %02d:%02d', hour, minute))
end)

-- Toggle Blackout
RegisterNetEvent('ec_admin:quickaction:blackout', function(enabled)
    local src = source
    
    TriggerClientEvent('ec_admin:client:toggleBlackout', -1, enabled)
    LogAction(src, 'toggle_blackout', nil, enabled and 'Enabled blackout' or 'Disabled blackout')
end)

-- Revive All
RegisterNetEvent('ec_admin:quickaction:revive_all', function()
    local src = source
    
    for _, playerId in ipairs(GetPlayers()) do
        if FrameworkName == "qb" or FrameworkName == "qbx" then
            TriggerClientEvent('hospital:client:Revive', tonumber(playerId))
        elseif FrameworkName == "esx" then
            TriggerClientEvent('esx_ambulancejob:revive', tonumber(playerId))
        else
            TriggerClientEvent('ec_admin:client:revive', tonumber(playerId))
        end
    end
    
    LogAction(src, 'revive_all', nil, 'Revived all players')
end)

-- Heal All
RegisterNetEvent('ec_admin:quickaction:heal_all', function()
    local src = source
    
    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent('ec_admin:client:healSelf', tonumber(playerId))
    end
    
    LogAction(src, 'heal_all', nil, 'Healed all players')
end)

-- Kick All (DANGEROUS!)
RegisterNetEvent('ec_admin:quickaction:kick_all', function(reason)
    local src = source
    reason = reason or "Server maintenance"
    
    local adminIdentifier = GetPlayerIdentifier(src, 0)
    
    for _, playerId in ipairs(GetPlayers()) do
        local pId = tonumber(playerId)
        if pId ~= src then
            -- Don't kick other admins
            local playerIdentifier = GetPlayerIdentifier(pId, 0)
            if not EC_Perms.Has(pId, 'admin') then
                DropPlayer(pId, string.format('[EC Admin] Server: %s', reason))
            end
        end
    end
    
    LogAction(src, 'kick_all', nil, 'Kicked all non-admin players: ' .. reason)
end)

Logger.Info('')