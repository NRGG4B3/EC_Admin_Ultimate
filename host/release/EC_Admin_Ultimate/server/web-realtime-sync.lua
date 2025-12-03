--[[
    EC Admin Ultimate - Real-Time Web Sync
    
    Allows web browser admins to perform actions in real-time
    Syncs with in-game admins via HTTP endpoints
    
    Flow:
    1. Admin opens web browser → http://SERVER_IP:8080
    2. Admin clicks "Ban Player" in web UI
    3. Web server sends POST to FiveM server
    4. This script handles the action
    5. Result broadcasts to all clients (web + in-game)
]]

local QBCore = nil
local ESX = nil

-- Detect framework
CreateThread(function()
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Logger.Info('QBCore detected', '🌐')
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Logger.Info('ESX detected', '🌐')
    end
end)

-- HTTP endpoint for web actions
lib.callback.register('ec_admin:webAction', function(source, data)
    local action = data.action
    local payload = data.payload
    local adminId = data.adminId or 'web-admin'
    
    Logger.Info(string.format('Action from web: %s', action), '🌐')
    
    -- Verify permission (you can add ACE checks here)
    -- For now, we assume web access is authenticated
    
    local success = false
    local result = {}
    
    -- Route action to appropriate handler
    if action == 'banPlayer' then
        success, result = HandleWebBan(payload)
    elseif action == 'kickPlayer' then
        success, result = HandleWebKick(payload)
    elseif action == 'warnPlayer' then
        success, result = HandleWebWarn(payload)
    elseif action == 'giveItem' then
        success, result = HandleWebGiveItem(payload)
    elseif action == 'setJob' then
        success, result = HandleWebSetJob(payload)
    elseif action == 'teleportPlayer' then
        success, result = HandleWebTeleport(payload)
    elseif action == 'healPlayer' then
        success, result = HandleWebHeal(payload)
    elseif action == 'freezePlayer' then
        success, result = HandleWebFreeze(payload)
    elseif action == 'giveVehicle' then
        success, result = HandleWebGiveVehicle(payload)
    else
        success = false
        result = { error = 'Unknown action: ' .. action }
    end
    
    -- Broadcast result to all connected clients
    if success then
        TriggerClientEvent('ec_admin:updateData', -1, action, result)
    end
    
    return {
        success = success,
        result = result,
        timestamp = os.time(),
        action = action
    }
end)

-- ==========================================
-- WEB ACTION HANDLERS
-- ==========================================

function HandleWebBan(payload)
    local targetId = payload.playerId
    local reason = payload.reason or 'Banned by admin'
    local duration = payload.duration or 0
    local adminName = payload.adminName or 'Web Admin'
    
    if not targetId then
        return false, { error = 'Missing playerId' }
    end
    
    -- Get player identifiers
    local target = tonumber(targetId)
    if not target or GetPlayerName(target) == nil then
        return false, { error = 'Player not found' }
    end
    
    local identifiers = GetPlayerIdentifiers(target)
    local license = nil
    
    for _, id in pairs(identifiers) do
        if string.find(id, 'license:') then
            license = id
            break
        end
    end
    
    if not license then
        return false, { error = 'Could not get player license' }
    end
    
    -- Insert ban into database
    local expiresAt = duration > 0 and (os.time() + (duration * 3600)) or nil
    
    MySQL.insert('INSERT INTO bans (license, reason, banned_by, expires_at, created_at) VALUES (?, ?, ?, ?, ?)', {
        license,
        reason,
        adminName,
        expiresAt,
        os.time()
    }, function(insertId)
        if insertId then
            -- Kick the player
            DropPlayer(target, string.format('[EC Admin] %s\nReason: %s', 
                duration > 0 and ('Banned for ' .. duration .. ' hours') or 'Permanently banned',
                reason
            ))
            
            -- Log the action
            TriggerEvent('ec_admin:logAction', {
                action = 'ban',
                admin = adminName,
                target = GetPlayerName(target),
                reason = reason,
                duration = duration,
                source = 'web'
            })
            
            print(string.format('^1[EC Web Sync] %s banned %s (%s)^0', adminName, GetPlayerName(target), reason))
        end
    end)
    
    return true, {
        message = 'Player banned successfully',
        playerName = GetPlayerName(target),
        reason = reason,
        duration = duration
    }
end

function HandleWebKick(payload)
    local targetId = payload.playerId
    local reason = payload.reason or 'Kicked by admin'
    local adminName = payload.adminName or 'Web Admin'
    
    if not targetId then
        return false, { error = 'Missing playerId' }
    end
    
    local target = tonumber(targetId)
    if not target or GetPlayerName(target) == nil then
        return false, { error = 'Player not found' }
    end
    
    local playerName = GetPlayerName(target)
    DropPlayer(target, string.format('[EC Admin] Kicked\nReason: %s', reason))
    
    -- Log the action
    TriggerEvent('ec_admin:logAction', {
        action = 'kick',
        admin = adminName,
        target = playerName,
        reason = reason,
        source = 'web'
    })
    
    print(string.format('^3[EC Web Sync] %s kicked %s (%s)^0', adminName, playerName, reason))
    
    return true, {
        message = 'Player kicked successfully',
        playerName = playerName,
        reason = reason
    }
end

function HandleWebWarn(payload)
    local targetId = payload.playerId
    local reason = payload.reason or 'Warning'
    local adminName = payload.adminName or 'Web Admin'
    
    if not targetId then
        return false, { error = 'Missing playerId' }
    end
    
    local target = tonumber(targetId)
    if not target or GetPlayerName(target) == nil then
        return false, { error = 'Player not found' }
    end
    
    local identifiers = GetPlayerIdentifiers(target)
    local license = nil
    
    for _, id in pairs(identifiers) do
        if string.find(id, 'license:') then
            license = id
            break
        end
    end
    
    if not license then
        return false, { error = 'Could not get player license' }
    end
    
    -- Insert warning into database
    MySQL.insert('INSERT INTO warnings (license, reason, warned_by, created_at) VALUES (?, ?, ?, ?)', {
        license,
        reason,
        adminName,
        os.time()
    })
    
    -- Notify the player in-game
    TriggerClientEvent('ec_admin:notify', target, {
        title = 'Warning',
        message = reason,
        type = 'warning'
    })
    
    -- Log the action
    TriggerEvent('ec_admin:logAction', {
        action = 'warn',
        admin = adminName,
        target = GetPlayerName(target),
        reason = reason,
        source = 'web'
    })
    
    print(string.format('^3[EC Web Sync] %s warned %s (%s)^0', adminName, GetPlayerName(target), reason))
    
    return true, {
        message = 'Player warned successfully',
        playerName = GetPlayerName(target),
        reason = reason
    }
end

function HandleWebGiveItem(payload)
    local targetId = payload.playerId
    local itemName = payload.itemName
    local amount = payload.amount or 1
    local adminName = payload.adminName or 'Web Admin'
    
    if not targetId or not itemName then
        return false, { error = 'Missing required fields' }
    end
    
    local target = tonumber(targetId)
    if not target or GetPlayerName(target) == nil then
        return false, { error = 'Player not found' }
    end
    
    -- Give item based on framework
    if QBCore then
        local Player = QBCore.Functions.GetPlayer(target)
        if Player then
            Player.Functions.AddItem(itemName, amount)
            TriggerClientEvent('inventory:client:ItemBox', target, QBCore.Shared.Items[itemName], 'add', amount)
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(target)
        if xPlayer then
            xPlayer.addInventoryItem(itemName, amount)
        end
    end
    
    -- Log the action
    TriggerEvent('ec_admin:logAction', {
        action = 'giveItem',
        admin = adminName,
        target = GetPlayerName(target),
        item = itemName,
        amount = amount,
        source = 'web'
    })
    
    print(string.format('^2[EC Web Sync] %s gave %s x%d %s^0', adminName, GetPlayerName(target), amount, itemName))
    
    return true, {
        message = 'Item given successfully',
        playerName = GetPlayerName(target),
        itemName = itemName,
        amount = amount
    }
end

function HandleWebSetJob(payload)
    local targetId = payload.playerId
    local jobName = payload.jobName
    local grade = payload.grade or 0
    local adminName = payload.adminName or 'Web Admin'
    
    if not targetId or not jobName then
        return false, { error = 'Missing required fields' }
    end
    
    local target = tonumber(targetId)
    if not target or GetPlayerName(target) == nil then
        return false, { error = 'Player not found' }
    end
    
    -- Set job based on framework
    if QBCore then
        local Player = QBCore.Functions.GetPlayer(target)
        if Player then
            Player.Functions.SetJob(jobName, grade)
        end
    elseif ESX then
        local xPlayer = ESX.GetPlayerFromId(target)
        if xPlayer then
            xPlayer.setJob(jobName, grade)
        end
    end
    
    -- Log the action
    TriggerEvent('ec_admin:logAction', {
        action = 'setJob',
        admin = adminName,
        target = GetPlayerName(target),
        job = jobName,
        grade = grade,
        source = 'web'
    })
    
    print(string.format('^2[EC Web Sync] %s set %s job to %s (grade %d)^0', adminName, GetPlayerName(target), jobName, grade))
    
    return true, {
        message = 'Job set successfully',
        playerName = GetPlayerName(target),
        jobName = jobName,
        grade = grade
    }
end

function HandleWebTeleport(payload)
    local targetId = payload.playerId
    local coords = payload.coords
    local adminName = payload.adminName or 'Web Admin'
    
    if not targetId or not coords then
        return false, { error = 'Missing required fields' }
    end
    
    local target = tonumber(targetId)
    if not target or GetPlayerName(target) == nil then
        return false, { error = 'Player not found' }
    end
    
    -- Teleport player
    TriggerClientEvent('ec_admin:doTeleport', target, coords)
    
    -- Log the action
    TriggerEvent('ec_admin:logAction', {
        action = 'teleport',
        admin = adminName,
        target = GetPlayerName(target),
        coords = coords,
        source = 'web'
    })
    
    print(string.format('^2[EC Web Sync] %s teleported %s^0', adminName, GetPlayerName(target)))
    
    return true, {
        message = 'Player teleported successfully',
        playerName = GetPlayerName(target)
    }
end

function HandleWebHeal(payload)
    local targetId = payload.playerId
    local adminName = payload.adminName or 'Web Admin'
    
    if not targetId then
        return false, { error = 'Missing playerId' }
    end
    
    local target = tonumber(targetId)
    if not target or GetPlayerName(target) == nil then
        return false, { error = 'Player not found' }
    end
    
    -- Heal player based on framework
    if QBCore then
        TriggerClientEvent('hospital:client:Revive', target)
    elseif ESX then
        TriggerClientEvent('esx_ambulancejob:revive', target)
    else
        -- Generic heal
        TriggerClientEvent('ec_admin:healPlayer', target)
    end
    
    -- Log the action
    TriggerEvent('ec_admin:logAction', {
        action = 'heal',
        admin = adminName,
        target = GetPlayerName(target),
        source = 'web'
    })
    
    print(string.format('^2[EC Web Sync] %s healed %s^0', adminName, GetPlayerName(target)))
    
    return true, {
        message = 'Player healed successfully',
        playerName = GetPlayerName(target)
    }
end

function HandleWebFreeze(payload)
    local targetId = payload.playerId
    local freeze = payload.freeze or true
    local adminName = payload.adminName or 'Web Admin'
    
    if not targetId then
        return false, { error = 'Missing playerId' }
    end
    
    local target = tonumber(targetId)
    if not target or GetPlayerName(target) == nil then
        return false, { error = 'Player not found' }
    end
    
    -- Freeze player
    TriggerClientEvent('ec_admin:freezePlayer', target, freeze)
    
    -- Log the action
    TriggerEvent('ec_admin:logAction', {
        action = freeze and 'freeze' or 'unfreeze',
        admin = adminName,
        target = GetPlayerName(target),
        source = 'web'
    })
    
    print(string.format('^2[EC Web Sync] %s %s %s^0', adminName, freeze and 'froze' or 'unfroze', GetPlayerName(target)))
    
    return true, {
        message = freeze and 'Player frozen successfully' or 'Player unfrozen successfully',
        playerName = GetPlayerName(target)
    }
end

function HandleWebGiveVehicle(payload)
    local targetId = payload.playerId
    local vehicleModel = payload.vehicleModel
    local adminName = payload.adminName or 'Web Admin'
    
    if not targetId or not vehicleModel then
        return false, { error = 'Missing required fields' }
    end
    
    local target = tonumber(targetId)
    if not target or GetPlayerName(target) == nil then
        return false, { error = 'Player not found' }
    end
    
    -- Spawn vehicle for player
    TriggerClientEvent('ec_admin:spawnVehicle', target, {
        model = vehicleModel,
        coords = nil -- Will spawn at player location
    })
    
    -- Log the action
    TriggerEvent('ec_admin:logAction', {
        action = 'giveVehicle',
        admin = adminName,
        target = GetPlayerName(target),
        vehicle = vehicleModel,
        source = 'web'
    })
    
    print(string.format('^2[EC Web Sync] %s gave %s a %s^0', adminName, GetPlayerName(target), vehicleModel))
    
    return true, {
        message = 'Vehicle spawned successfully',
        playerName = GetPlayerName(target),
        vehicleModel = vehicleModel
    }
end

-- ==========================================
-- REAL-TIME DATA POLLING
-- ==========================================

-- Get current city data (for web dashboard)
lib.callback.register('ec_admin:getCityData', function(source)
    local players = {}
    
    -- Get all players
    for _, playerId in ipairs(GetPlayers()) do
        local playerData = {
            id = playerId,
            name = GetPlayerName(playerId),
            identifiers = GetPlayerIdentifiers(playerId),
            ping = GetPlayerPing(playerId)
        }
        
        -- Add framework data if available
        if QBCore then
            local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
            if Player then
                playerData.job = Player.PlayerData.job.name
                playerData.gang = Player.PlayerData.gang.name
                playerData.money = Player.PlayerData.money
            end
        elseif ESX then
            local xPlayer = ESX.GetPlayerFromId(tonumber(playerId))
            if xPlayer then
                playerData.job = xPlayer.job.name
                playerData.money = xPlayer.getMoney()
            end
        end
        
        table.insert(players, playerData)
    end
    
    return {
        success = true,
        players = players,
        totalPlayers = #players,
        maxPlayers = GetConvarInt('sv_maxclients', 32),
        serverName = GetConvar('sv_hostname', 'FiveM Server'),
        timestamp = os.time()
    }
end)

Logger.Info('')
