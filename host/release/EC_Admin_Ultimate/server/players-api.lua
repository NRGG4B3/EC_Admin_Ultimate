--[[
    EC Admin Ultimate - Players API
    Provides complete player management functionality
    Backend integration for players page and player profiles
]]

-- No ECAdmin object needed - using server natives directly

-- Cache for player data
local playerDataCache = {}
local cacheUpdateInterval = 2000 -- Update every 2 seconds

--[[
    Get comprehensive player data
    Returns detailed information for all online players
]]
local function GetAllPlayersData()
    local players = GetPlayers()
    local playersList = {}
    
    for _, playerId in ipairs(players) do
        local playerData = GetPlayerFullData(playerId)
        if playerData then
            playersList[#playersList + 1] = playerData
        end
    end
    
    return playersList
end

--[[
    Get complete data for a single player
    Includes all player information, inventory, vehicles, properties, etc.
]]
function GetPlayerFullData(playerId)
    if not playerId or not GetPlayerName(playerId) then
        return nil
    end
    
    local playerName = GetPlayerName(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local steamId, license, discord, ip = nil, nil, nil, nil
    
    -- Extract identifiers
    local hwid = nil
    for _, identifier in ipairs(identifiers) do
        if string.match(identifier, 'steam:') then
            steamId = identifier
        elseif string.match(identifier, 'license:') then
            license = identifier
            -- License IS the hardware ID in FiveM
            hwid = string.gsub(identifier, 'license:', '')
        elseif string.match(identifier, 'discord:') then
            discord = identifier
        elseif string.match(identifier, 'ip:') then
            ip = string.gsub(identifier, 'ip:', '')
        end
    end
    
    -- Get player position
    local ped = GetPlayerPed(playerId)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Get health and armor
    local health = GetEntityHealth(ped)
    local armor = GetPedArmour(ped)
    
    -- Check if in vehicle
    local vehicle = GetVehiclePedIsIn(ped, false)
    local inVehicle = vehicle ~= 0
    local currentVehicle = nil
    
    if inVehicle then
        local plate = GetVehicleNumberPlateText(vehicle)
        local model = GetEntityModel(vehicle)
        currentVehicle = {
            plate = plate,
            model = model
        }
    end
    
    -- Get framework specific data (QB-Core/ESX)
    local frameworkData = GetFrameworkPlayerData(playerId)
    
    -- Build comprehensive player object
    local playerData = {
        id = tonumber(playerId),
        name = playerName,
        steamId = steamId or 'Unknown',
        license = license or 'Unknown',
        discord = discord or 'Unknown',
        discordId = string.gsub(discord or '', 'discord:', ''),
        ip = ip or 'Unknown',
        hwid = hwid or 'Unknown', -- Real hardware ID from license
        ping = GetPlayerPing(playerId),
        status = 'online',
        location = GetPlayerLocation(coords),
        coords = { x = coords.x, y = coords.y, z = coords.z },
        heading = heading,
        health = health,
        armor = armor,
        isDead = health <= 0,
        inVehicle = inVehicle,
        currentVehicle = currentVehicle,
        
        -- Framework data
        job = frameworkData.job or 'Unemployed',
        jobGrade = frameworkData.jobGrade or 'None',
        jobGradeLevel = frameworkData.jobGradeLevel or 0,
        jobSalary = frameworkData.jobSalary or 0,
        gang = frameworkData.gang or 'None',
        gangGrade = frameworkData.gangGrade or 'None',
        money = frameworkData.money or { cash = 0, bank = 0, crypto = 0 },
        
        -- Additional stats
        playtime = GetPlayerPlaytime(playerId),
        firstJoined = GetPlayerFirstJoined(playerId),
        lastSeen = os.date('%Y-%m-%d %H:%M:%S'),
        warnings = GetPlayerWarnings(playerId),
        bans = GetPlayerBans(playerId),
        kicks = GetPlayerKicks(playerId)
    }
    
    return playerData
end

--[[
    Get framework-specific player data (QB/ESX)
]]
function GetFrameworkPlayerData(playerId)
    local frameworkData = {
        job = 'Unemployed',
        jobGrade = 'None',
        jobGradeLevel = 0,
        jobSalary = 0,
        gang = 'None',
        gangGrade = 'None',
        money = { cash = 0, bank = 0, crypto = 0 }
    }
    
    -- Try QBX
    if GetResourceState('qbx_core') == 'started' then
        local Player = exports.qbx_core:GetPlayer(tonumber(playerId))
        
        if Player then
            return {
                money = Player.PlayerData.money or {},
                job = Player.PlayerData.job or { name = 'unemployed', grade = { level = 0 } },
                gang = Player.PlayerData.gang or { name = 'none', grade = { level = 0 } },
                citizenid = Player.PlayerData.citizenid,
                charinfo = Player.PlayerData.charinfo or {}
            }
        end
    -- Try QB-Core
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        
        if Player then
            frameworkData.job = Player.PlayerData.job.label or 'Unemployed'
            frameworkData.jobGrade = Player.PlayerData.job.grade.name or 'None'
            frameworkData.jobGradeLevel = Player.PlayerData.job.grade.level or 0
            frameworkData.jobSalary = Player.PlayerData.job.payment or 0
            
            if Player.PlayerData.gang then
                frameworkData.gang = Player.PlayerData.gang.label or 'None'
                frameworkData.gangGrade = Player.PlayerData.gang.grade.name or 'None'
            end
            
            frameworkData.money = {
                cash = Player.PlayerData.money.cash or 0,
                bank = Player.PlayerData.money.bank or 0,
                crypto = Player.PlayerData.money.crypto or 0
            }
        end
    -- Try ESX
    elseif GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(tonumber(playerId))
        
        if xPlayer then
            frameworkData.job = xPlayer.job.label or 'Unemployed'
            frameworkData.jobGrade = xPlayer.job.grade_label or 'None'
            frameworkData.jobGradeLevel = xPlayer.job.grade or 0
            frameworkData.jobSalary = xPlayer.job.grade_salary or 0
            
            frameworkData.money = {
                cash = xPlayer.getMoney() or 0,
                bank = xPlayer.getAccount('bank').money or 0,
                crypto = xPlayer.getAccount('crypto') and xPlayer.getAccount('crypto').money or 0
            }
        end
    end
    
    return frameworkData
end

--[[
    Get player location name from coordinates
]]
function GetPlayerLocation(coords)
    -- This would normally use a zones resource
    -- For now, return a simple location
    return 'Los Santos'
end

--[[
    Get player playtime
]]
function GetPlayerPlaytime(playerId)
    -- This should query database
    return '120h 45m'
end

--[[
    Get player first joined date
]]
function GetPlayerFirstJoined(playerId)
    -- This should query database
    return os.date('%Y-%m-%d %H:%M:%S', os.time() - (86400 * 30))
end

--[[
    Get player warnings
]]
function GetPlayerWarnings(playerId)
    -- This should query database
    return 0
end

--[[
    Get player bans
]]
function GetPlayerBans(playerId)
    -- This should query database
    return 0
end

--[[
    Get player kicks
]]
function GetPlayerKicks(playerId)
    -- This should query database
    return 0
end

--[[
    Get player inventory
]]
function GetPlayerInventory(playerId)
    local inventory = {}
    
    -- Try QBX inventory
    if GetResourceState('qbx_core') == 'started' then
        local Player = exports.qbx_core:GetPlayer(tonumber(playerId))
        
        if Player and Player.PlayerData.items then
            for slot, item in pairs(Player.PlayerData.items) do
                if item then
                    inventory[#inventory + 1] = {
                        id = slot,
                        name = item.name,
                        label = item.label,
                        quantity = item.amount,
                        type = item.type or 'item',
                        weight = item.weight or 0,
                        useable = item.useable or false,
                        slot = slot,
                        metadata = item.info or {}
                    }
                end
            end
        end
    -- Try QB-Core inventory
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        
        if Player and Player.PlayerData.items then
            for slot, item in pairs(Player.PlayerData.items) do
                if item then
                    inventory[#inventory + 1] = {
                        id = slot,
                        name = item.name,
                        label = item.label,
                        quantity = item.amount,
                        type = item.type or 'item',
                        weight = item.weight or 0,
                        useable = item.useable or false,
                        slot = slot,
                        metadata = item.info or {}
                    }
                end
            end
        end
    -- Try ESX inventory
    elseif GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(tonumber(playerId))
        
        if xPlayer then
            local items = xPlayer.getInventory()
            for i, item in ipairs(items) do
                if item.count > 0 then
                    inventory[#inventory + 1] = {
                        id = i,
                        name = item.name,
                        label = item.label,
                        quantity = item.count,
                        type = 'item',
                        weight = item.weight or 0,
                        useable = item.useable or false,
                        slot = i,
                        metadata = {}
                    }
                end
            end
        end
    end
    
    return inventory
end

--[[
    Get player vehicles
]]
function GetPlayerVehicles(playerId)
    local vehicles = {}
    
    -- This should query database
    -- For now, return empty array
    
    return vehicles
end

--[[
    Get player properties
]]
function GetPlayerProperties(playerId)
    local properties = {}
    
    -- This should query database
    -- For now, return empty array
    
    return properties
end

--[[
    SERVER EVENTS (NOT NUI CALLBACKS - those are CLIENT-SIDE only)
    NUI Callbacks must be registered on the CLIENT side, not server!
]]

-- NOTE: These were INCORRECTLY using RegisterNUICallback (client-side function)
-- Server should expose these via server events that the client can trigger
-- The client will then use RegisterNUICallback to communicate with the UI

-- Server event to get all players data
RegisterServerEvent('ec_admin:server:getPlayers')
AddEventHandler('ec_admin:server:getPlayers', function(callbackId)
    local src = source
    local players = GetAllPlayersData()
    TriggerClientEvent('ec_admin:client:receivePlayersData', src, { success = true, players = players }, callbackId or 0)
end)

-- Server event to get single player profile
RegisterServerEvent('ec_admin:server:getPlayerProfile')
AddEventHandler('ec_admin:server:getPlayerProfile', function(playerId, callbackId)
    local src = source
    local playerData = GetPlayerFullData(playerId)
    TriggerClientEvent('ec_admin:client:receivePlayerProfile', src, { success = true, player = playerData }, callbackId or 0)
end)

-- Kick player (server event)
RegisterServerEvent('ec_admin:server:kickPlayer')
AddEventHandler('ec_admin:server:kickPlayer', function(playerId, reason)
    local src = source
    reason = reason or 'No reason provided'
    
    if GetPlayerName(playerId) then
        DropPlayer(playerId, reason)
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = true, message = 'Player kicked' })
    else
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = false, message = 'Player not found' })
    end
end)

-- Ban player (server event)
RegisterServerEvent('ec_admin:server:banPlayer')
AddEventHandler('ec_admin:server:banPlayer', function(playerId, reason, duration)
    local src = source
    reason = reason or 'No reason provided'
    duration = duration or 0  -- 0 = permanent
    
    if GetPlayerName(playerId) then
        local playerName = GetPlayerName(playerId)
        local adminName = GetPlayerName(src)
        
        -- Get player identifiers
        local identifiers = GetPlayerIdentifiers(playerId)
        local license, steam, fivem, discord, ip = nil, nil, nil, nil, nil
        
        for _, id in pairs(identifiers) do
            if string.find(id, 'license:') then license = id end
            if string.find(id, 'steam:') then steam = id end
            if string.find(id, 'fivem:') then fivem = id end
            if string.find(id, 'discord:') then discord = id end
            if string.find(id, 'ip:') then ip = id end
        end
        
        -- Add ban to local database
        if MySQL and MySQL.Async then
            MySQL.Async.execute([[
                INSERT INTO bans (license, name, reason, bannedby, expire, timestamp)
                VALUES (@license, @name, @reason, @bannedby, @expire, @timestamp)
            ]], {
                ['@license'] = license,
                ['@name'] = playerName,
                ['@reason'] = reason,
                ['@bannedby'] = adminName,
                ['@expire'] = duration == 0 and 0 or (os.time() + duration),
                ['@timestamp'] = os.time()
            })
        end
        
        -- Sync to Global Ban API if enabled
        if exports['EC_admin_ultimate'] and exports['EC_admin_ultimate'].SyncBanToGlobalAPI then
            local banData = {
                license = license,
                steam = steam,
                fivem = fivem,
                discord = discord,
                ip = ip,
                playerName = playerName,
                reason = reason,
                bannedBy = adminName,
                duration = duration
            }
            
            exports['EC_admin_ultimate']:SyncBanToGlobalAPI(banData, function(success, message)
                if success then
                    Logger.Success(string.format('✅ Synced ban to global API: %s', playerName))
                end
            end)
        end
        
        -- Kick player
        DropPlayer(playerId, string.format('🚫 BANNED\n\nReason: %s\nBanned By: %s', reason, adminName))
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = true, message = 'Player banned' })
    else
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = false, message = 'Player not found' })
    end
end)

-- Warn player (server event)
RegisterServerEvent('ec_admin:server:warnPlayer')
AddEventHandler('ec_admin:server:warnPlayer', function(playerId, reason)
    local src = source
    reason = reason or 'No reason provided'
    
    if GetPlayerName(playerId) then
        -- Add warning to database
        TriggerClientEvent('chat:addMessage', playerId, {
            color = {255, 0, 0},
            multiline = true,
            args = {'Warning', reason}
        })
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = true, message = 'Player warned' })
    else
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = false, message = 'Player not found' })
    end
end)

-- Teleport to player (server event)
RegisterServerEvent('ec_admin:server:teleportToPlayer')
AddEventHandler('ec_admin:server:teleportToPlayer', function(adminId, playerId)
    local src = source
    
    if GetPlayerName(playerId) and GetPlayerName(adminId) then
        local targetPed = GetPlayerPed(playerId)
        local coords = GetEntityCoords(targetPed)
        
        TriggerClientEvent('ec_admin:teleportToCoords', adminId, coords)
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = true, message = 'Teleporting to player' })
    else
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = false, message = 'Player not found' })
    end
end)

-- Bring player (server event)
RegisterServerEvent('ec_admin:server:bringPlayer')
AddEventHandler('ec_admin:server:bringPlayer', function(adminId, playerId)
    local src = source
    
    if GetPlayerName(playerId) and GetPlayerName(adminId) then
        local adminPed = GetPlayerPed(adminId)
        local coords = GetEntityCoords(adminPed)
        
        TriggerClientEvent('ec_admin:teleportToCoords', playerId, coords)
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = true, message = 'Bringing player to you' })
    else
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = false, message = 'Player not found' })
    end
end)

-- Freeze player (server event)
RegisterServerEvent('ec_admin:server:freezePlayer')
AddEventHandler('ec_admin:server:freezePlayer', function(playerId, freeze)
    local src = source
    
    if GetPlayerName(playerId) then
        TriggerClientEvent('ec_admin:freezePlayer', playerId, freeze)
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = true, message = freeze and 'Player frozen' or 'Player unfrozen' })
    else
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = false, message = 'Player not found' })
    end
end)

-- Spectate player (server event)
RegisterServerEvent('ec_admin:server:spectatePlayer')
AddEventHandler('ec_admin:server:spectatePlayer', function(adminId, playerId)
    local src = source
    
    if GetPlayerName(playerId) and GetPlayerName(adminId) then
        TriggerClientEvent('ec_admin:spectatePlayer', adminId, playerId)
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = true, message = 'Spectating player' })
    else
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = false, message = 'Player not found' })
    end
end)

--[[
    Live player data updates
]]
CreateThread(function()
    while true do
        Wait(2000)
        
        local players = GetAllPlayersData()
        
        -- Send to all admins with panel open
        local allPlayers = GetPlayers()
        for _, playerId in ipairs(allPlayers) do
            if IsPlayerAdmin(playerId) then
                TriggerClientEvent('ec_admin:playersUpdate', playerId, players)
            end
        end
    end
end)

function IsPlayerAdmin(playerId)
    -- Use the permission system to check admin access
    if not playerId then return false end
    
    -- Check if permissions module is loaded
    if ECAdminPermissions and ECAdminPermissions.HasPermission then
        -- Check for admin.access permission or god mode
        return ECAdminPermissions.HasPermission(playerId, 'admin.access') or
               ECAdminPermissions.HasPermission(playerId, 'god')
    end
    
    -- Fallback: Check ACE permissions
    if IsPlayerAceAllowed(playerId, 'ec_admin.access') then
        return true
    end
    
    -- Fallback: Check if player is server owner (ID 1 often has special privileges)
    if tonumber(playerId) == 1 then
        return true
    end
    
    -- Default: deny access
    return false
end

-- Revive Player (server event)
RegisterServerEvent('ec_admin:server:revivePlayer')
AddEventHandler('ec_admin:server:revivePlayer', function(playerId)
    local src = source
    
    if GetPlayerName(playerId) then
        -- Trigger client revive
        TriggerClientEvent('ec_admin:client:revivePlayer', playerId)
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = true, message = 'Player revived' })
    else
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = false, message = 'Player not found' })
    end
end)

-- Broadcast Message (server event)
RegisterServerEvent('ec_admin:server:broadcast')
AddEventHandler('ec_admin:server:broadcast', function(message)
    local src = source
    
    if message and message ~= '' then
        -- Send to all players
        TriggerClientEvent('chat:addMessage', -1, {
            template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(52, 152, 219, 0.8); border-radius: 5px;"><b>[ADMIN]</b> {0}</div>',
            args = {message}
        })
        
        TriggerClientEvent('ec_admin:client:notify', -1, {
            title = 'Server Announcement',
            message = message,
            type = 'info',
            duration = 10000
        })
        
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = true, message = 'Broadcast sent' })
    else
        TriggerClientEvent('ec_admin:client:actionResult', src, { success = false, message = 'No message provided' })
    end
end)

-- Restart Warning (server event)
RegisterServerEvent('ec_admin:server:restartWarning')
AddEventHandler('ec_admin:server:restartWarning', function(minutes)
    local src = source
    minutes = minutes or 5
    
    local message = string.format('Server restart in %d minutes. Please finish your activities and find a safe location.', minutes)
    
    -- Send to all players
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(231, 76, 60, 0.8); border-radius: 5px;"><b>[RESTART WARNING]</b> {0}</div>',
        args = {message}
    })
    
    TriggerClientEvent('ec_admin:client:notify', -1, {
        title = 'Restart Warning',
        message = message,
        type = 'warning',
        duration = 15000
    })
    
    TriggerClientEvent('ec_admin:client:actionResult', src, { success = true, message = 'Restart warning sent' })
end)

--[[
    Exports
]]
exports('GetPlayerFullData', GetPlayerFullData)
exports('GetAllPlayersData', GetAllPlayersData)
exports('GetPlayerInventory', GetPlayerInventory)
exports('GetPlayerVehicles', GetPlayerVehicles)
exports('GetPlayerProperties', GetPlayerProperties)

Logger.Info('')