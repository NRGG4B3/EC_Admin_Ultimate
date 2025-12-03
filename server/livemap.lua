-- EC Admin Ultimate - Live Map System (PRODUCTION STABLE)
-- Version: 1.0.0 - Complete real-time player tracking and map management

Logger.Info('🗺️  Loading live map system...')

local LiveMap = {}

-- Framework detection
local Framework = nil
local FrameworkObject = nil

-- Configuration
local config = {
    updateInterval = 1000,      -- Update every second
    trackEvents = true,
    trackVehicles = true,
    maxEventHistory = 50,
    eventExpireTime = 300000    -- 5 minutes
}

-- Event storage
local activeEvents = {}
local eventIdCounter = 0

-- Safe framework detection
local function DetectFramework()
    -- Detect QBCore
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('🗺️  QBCore (qbx_core) detected')
        
        local success, coreObj = pcall(function()
            return exports['qbx_core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('🗺️  QBCore framework successfully connected')
            return true
        end
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('🗺️  QBCore (qb-core) detected')
        
        local success, coreObj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('🗺️  QBCore framework successfully connected')
            return true
        end
    end
    
    -- Detect ESX
    if GetResourceState('es_extended') == 'started' then
        Framework = 'ESX'
        local success, esxObj = pcall(function()
            return exports["es_extended"]:getSharedObject()
        end)
        if success and esxObj then
            FrameworkObject = esxObj
            Logger.Info('🗺️  ESX framework detected')
            return true
        end
    end
    
    Logger.Info('⚠️ No supported framework detected for live map')
    return false
end

-- Get street and area name
local function GetStreetAndArea(coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local crossing = GetStreetNameFromHashKey(crossingHash)
    local area = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    
    return {
        street = street ~= '' and street or 'Unknown Street',
        crossing = crossing ~= '' and crossing or nil,
        area = area ~= 'Unknown' and area or 'Unknown Area'
    }
end

-- Get player data
function LiveMap.GetPlayerData(source)
    local playerData = {
        id = source,
        name = GetPlayerName(source),
        citizenid = nil,
        x = 0,
        y = 0,
        z = 0,
        heading = 0,
        area = 'Unknown',
        street = 'Unknown',
        vehicle = nil,
        vehicleModel = nil,
        vehiclePlate = nil,
        job = nil,
        gang = nil,
        health = 200,
        armor = 0,
        isAdmin = false,
        isDead = false,
        isInVehicle = false,
        speed = 0,
        ping = GetPlayerPing(source)
    }
    
    -- Get coordinates
    local ped = GetPlayerPed(source)
    if ped ~= 0 then
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        playerData.x = coords.x
        playerData.y = coords.y
        playerData.z = coords.z
        playerData.heading = heading
        
        -- Get street and area
        local location = GetStreetAndArea(coords)
        playerData.street = location.street
        playerData.area = location.area
        
        -- Check if in vehicle
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 then
            playerData.isInVehicle = true
            playerData.vehicleModel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            playerData.vehiclePlate = GetVehicleNumberPlateText(vehicle)
            
            -- Get speed
            local speed = GetEntitySpeed(vehicle)
            playerData.speed = math.floor(speed * 2.23694) -- Convert to MPH
        end
    end
    
    -- Get framework data
    if Framework == 'QBCore' and FrameworkObject then
        local Player = FrameworkObject.Functions.GetPlayer(source)
        if Player then
            playerData.citizenid = Player.PlayerData.citizenid
            playerData.job = Player.PlayerData.job.name
            playerData.gang = Player.PlayerData.gang and Player.PlayerData.gang.name or nil
            
            -- Get admin status
            if Player.PlayerData.permission and Player.PlayerData.permission == 'admin' then
                playerData.isAdmin = true
            end
        end
    elseif Framework == 'ESX' and FrameworkObject then
        local xPlayer = FrameworkObject.GetPlayerFromId(source)
        if xPlayer then
            playerData.citizenid = xPlayer.identifier
            playerData.job = xPlayer.getJob().name
            
            -- Check for admin group
            if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' then
                playerData.isAdmin = true
            end
        end
    end
    
    -- Check permissions
    if _G.ECPermissions and _G.ECPermissions.HasPermission(source, 'admin') then
        playerData.isAdmin = true
    end
    
    return playerData
end

-- Get all players
function LiveMap.GetAllPlayers()
    local players = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        local playerData = LiveMap.GetPlayerData(tonumber(playerId))
        if playerData then
            table.insert(players, playerData)
        end
    end
    
    return players
end

-- Get all vehicles
function LiveMap.GetAllVehicles()
    local vehicles = {}
    
    -- This would need a vehicle tracking system
    -- For now, we'll return empty as it requires additional setup
    
    return vehicles
end

-- Add event marker
function LiveMap.AddEvent(eventType, coords, label, description, severity)
    eventIdCounter = eventIdCounter + 1
    local eventId = 'evt_' .. eventIdCounter
    
    local event = {
        id = eventId,
        type = eventType or 'custom',
        x = coords.x,
        y = coords.y,
        z = coords.z,
        label = label or 'Event',
        description = description or '',
        timestamp = os.time() * 1000,
        severity = severity or 'medium',
        active = true
    }
    
    activeEvents[eventId] = event
    
    -- Clean old events
    local currentTime = os.time() * 1000
    for id, evt in pairs(activeEvents) do
        if currentTime - evt.timestamp > config.eventExpireTime then
            activeEvents[id] = nil
        end
    end
    
    -- Limit max events
    local eventCount = 0
    for _ in pairs(activeEvents) do
        eventCount = eventCount + 1
    end
    
    if eventCount > config.maxEventHistory then
        -- Remove oldest event
        local oldestId = nil
        local oldestTime = currentTime
        for id, evt in pairs(activeEvents) do
            if evt.timestamp < oldestTime then
                oldestTime = evt.timestamp
                oldestId = id
            end
        end
        if oldestId then
            activeEvents[oldestId] = nil
        end
    end
    
    return eventId
end

-- Remove event
function LiveMap.RemoveEvent(eventId)
    if activeEvents[eventId] then
        activeEvents[eventId] = nil
        return true
    end
    return false
end

-- Get all events
function LiveMap.GetEvents()
    local events = {}
    
    for _, event in pairs(activeEvents) do
        table.insert(events, event)
    end
    
    return events
end

-- Get blips (static map markers)
function LiveMap.GetBlips()
    local blips = {}
    
    -- You can add static blips here for important locations
    -- This would typically come from a configuration file
    
    return blips
end

-- Get comprehensive map data
function LiveMap.GetAllData()
    local players = LiveMap.GetAllPlayers()
    local events = LiveMap.GetEvents()
    local vehicles = LiveMap.GetAllVehicles()
    local blips = LiveMap.GetBlips()
    
    local stats = {
        totalPlayers = #players,
        playersInVehicles = 0,
        activeEvents = #events,
        policeOnline = 0,
        adminOnline = 0,
        avgSpeed = 0
    }
    
    local totalSpeed = 0
    for _, player in ipairs(players) do
        if player.isInVehicle then
            stats.playersInVehicles = stats.playersInVehicles + 1
            totalSpeed = totalSpeed + player.speed
        end
        if player.job == 'police' then
            stats.policeOnline = stats.policeOnline + 1
        end
        if player.isAdmin then
            stats.adminOnline = stats.adminOnline + 1
        end
    end
    
    if stats.playersInVehicles > 0 then
        stats.avgSpeed = math.floor(totalSpeed / stats.playersInVehicles)
    end
    
    return {
        players = players,
        events = events,
        vehicles = vehicles,
        blips = blips,
        framework = Framework,
        stats = stats
    }
end

-- Teleport player to another player
function LiveMap.TeleportToPlayer(adminSource, targetPlayerId)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'teleport') then
        return false, 'Insufficient permissions'
    end
    
    local targetSource = tonumber(targetPlayerId)
    if not targetSource then
        return false, 'Invalid player ID'
    end
    
    local targetPed = GetPlayerPed(targetSource)
    if targetPed == 0 then
        return false, 'Player not found'
    end
    
    local targetCoords = GetEntityCoords(targetPed)
    
    -- Teleport admin to target
    TriggerClientEvent('ec-admin:livemap:teleport', adminSource, {
        x = targetCoords.x,
        y = targetCoords.y,
        z = targetCoords.z
    })
    
    Logger.Info(string.format('', adminSource, targetSource))
    return true, 'Teleported to player'
end

-- Teleport player to coordinates
function LiveMap.TeleportToCoords(adminSource, coords)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'teleport') then
        return false, 'Insufficient permissions'
    end
    
    if not coords or not coords.x or not coords.y or not coords.z then
        return false, 'Invalid coordinates'
    end
    
    TriggerClientEvent('ec-admin:livemap:teleport', adminSource, coords)
    
    Logger.Info(string.format('', 
        adminSource, coords.x, coords.y, coords.z))
    return true, 'Teleported to coordinates'
end

-- Bring player to admin
function LiveMap.BringPlayer(adminSource, targetPlayerId)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'bringPlayer') then
        return false, 'Insufficient permissions'
    end
    
    local targetSource = tonumber(targetPlayerId)
    if not targetSource then
        return false, 'Invalid player ID'
    end
    
    local adminPed = GetPlayerPed(adminSource)
    if adminPed == 0 then
        return false, 'Admin ped not found'
    end
    
    local adminCoords = GetEntityCoords(adminPed)
    
    TriggerClientEvent('ec-admin:livemap:teleport', targetSource, {
        x = adminCoords.x,
        y = adminCoords.y,
        z = adminCoords.z
    })
    
    Logger.Info(string.format('', targetSource, adminSource))
    return true, 'Player brought to you'
end

-- Spectate player
function LiveMap.SpectatePlayer(adminSource, targetPlayerId)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'spectate') then
        return false, 'Insufficient permissions'
    end
    
    local targetSource = tonumber(targetPlayerId)
    if not targetSource then
        return false, 'Invalid player ID'
    end
    
    TriggerClientEvent('ec-admin:livemap:spectate', adminSource, targetSource)
    
    Logger.Info(string.format('', adminSource, targetSource))
    return true, 'Spectating player'
end

-- Initialize
function LiveMap.Initialize()
    Logger.Info('🗺️  Initializing live map system...')
    
    local frameworkDetected = DetectFramework()
    if not frameworkDetected then
        Logger.Info('⚠️ Live map system running without framework')
    end
    
    -- Register events for automatic event tracking
    if config.trackEvents then
        -- You can add event listeners here for automatic event detection
        -- For example: robberies, shootings, police calls, etc.
    end
    
    Logger.Info('✅ Live map system initialized')
    return true
end

-- Server events
RegisterNetEvent('ec-admin:getLiveMapData')
AddEventHandler('ec-admin:getLiveMapData', function()
    local source = source
    local data = LiveMap.GetAllData()
    TriggerClientEvent('ec-admin:receiveLiveMapData', source, data)
end)

-- Admin action events
RegisterNetEvent('ec-admin:livemap:teleportToPlayer')
AddEventHandler('ec-admin:livemap:teleportToPlayer', function(data, cb)
    local source = source
    local success, message = LiveMap.TeleportToPlayer(source, data.playerId)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:livemap:teleportToCoords')
AddEventHandler('ec-admin:livemap:teleportToCoords', function(data, cb)
    local source = source
    local success, message = LiveMap.TeleportToCoords(source, data)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:livemap:bringPlayer')
AddEventHandler('ec-admin:livemap:bringPlayer', function(data, cb)
    local source = source
    local success, message = LiveMap.BringPlayer(source, data.playerId)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:livemap:spectatePlayer')
AddEventHandler('ec-admin:livemap:spectatePlayer', function(data, cb)
    local source = source
    local success, message = LiveMap.SpectatePlayer(source, data.playerId)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

-- Exports
exports('GetAllPlayers', function()
    return LiveMap.GetAllPlayers()
end)

exports('GetPlayerData', function(source)
    return LiveMap.GetPlayerData(source)
end)

exports('GetEvents', function()
    return LiveMap.GetEvents()
end)

exports('AddEvent', function(eventType, coords, label, description, severity)
    return LiveMap.AddEvent(eventType, coords, label, description, severity)
end)

exports('RemoveEvent', function(eventId)
    return LiveMap.RemoveEvent(eventId)
end)

exports('GetAllMapData', function()
    return LiveMap.GetAllData()
end)

-- Initialize
LiveMap.Initialize()

-- Make available globally
_G.ECLiveMap = LiveMap

Logger.Info('✅ Live map system loaded successfully')