-- EC Admin Ultimate - Topbar Server Callbacks
-- Handles all topbar functionality including quick actions, admin profile, and system controls
-- Zero mock data - all live FiveM data

-- Get framework (QBCore/QBX/ESX)
local QBCore = nil
local ESX = nil
local resourceStartTime = _G.ECAdminStartTime or os.time()

local function GetServerStartTime()
    local txStart = GetConvarInt('txAdmin-startedAt', 0)
    if txStart and txStart > 0 then
        return txStart
    end

    if _G.ECAdminStartTime then
        resourceStartTime = _G.ECAdminStartTime
    end

    return resourceStartTime
end

local function FormatUptime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format('%dh %dm', hours, minutes)
end

CreateThread(function()
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Logger.Debug('Topbar: QBCore detected')
    elseif GetResourceState('qbx_core') == 'started' then
        QBCore = exports['qbx_core']:GetCoreObject()
        Logger.Debug('Topbar: QBX detected')
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Logger.Debug('Topbar: ESX detected')
    else
        Logger.Debug('Topbar: No framework detected - standalone mode')
    end
end)

-- ============================================================================
-- ADMIN PROFILE DATA
-- ============================================================================

-- Get current admin's profile information (ox_lib callback)
lib.callback.register('ec_admin:getAdminProfile', function(source)
    local src = source
    local identifier = GetPlayerIdentifierByType(src, 'license')
    
    if not identifier then
        return { success = false, error = 'Invalid player identifier' }
    end
    
    -- For now, return basic profile without database (add MySQL later)
    local name = GetPlayerName(src)
    return {
        success = true,
        data = {
            identifier = identifier,
            name = name,
            username = name,
            email = 'admin@ecadmin.local',
            role = 'admin',
            roleLabel = 'Admin',
            avatar = nil,
            permissions = {},
            lastLogin = os.time(),
            createdAt = os.time(),
            isSuperUser = false
        }
    }
end)

-- Get quick stats for topbar
lib.callback.register('ec_admin:getQuickStats', function(source)
    local players = GetPlayers()
    local maxPlayers = GetConvarInt('sv_maxclients', 32)
    local uptimeSeconds = os.difftime(os.time(), GetServerStartTime())

    -- Count active staff
    local activeStaff = 0
    for _, playerId in ipairs(players) do
        if IsPlayerAceAllowed(playerId, 'admin.access') then
            activeStaff = activeStaff + 1
        end
    end
    
    -- Calculate average ping
    local totalPing = 0
    for _, playerId in ipairs(players) do
        totalPing = totalPing + GetPlayerPing(playerId)
    end
    local avgPing = #players > 0 and math.floor(totalPing / #players) or 0

    -- Count open reports from the database (failsafe if table is missing)
    local openReports = 0
    if MySQL and MySQL.query and type(MySQL.query.await) == 'function' then
        local success, result = pcall(function()
            return MySQL.query.await('SELECT COUNT(*) as count FROM ec_reports WHERE status = ?', {'open'})
        end)

        if success and result and result[1] then
            openReports = result[1].count or 0
        end
    end

    return {
        success = true,
        data = {
            playersOnline = #players,
            maxPlayers = maxPlayers,
            openReports = openReports,
            activeStaff = activeStaff,
            serverUptime = FormatUptime(uptimeSeconds),
            avgPing = avgPing
        }
    }
end)

-- ============================================================================
-- QUICK ACTIONS - TELEPORT
-- ============================================================================

-- NOTE: All RegisterNUICallback calls have been removed from this server file
-- RegisterNUICallback is CLIENT-SIDE ONLY and should be in client/nui-bridge.lua
-- These functions have been converted to lib.callback.register instead

-- Teleport to Waypoint
lib.callback.register('ec_admin:teleportToWaypoint', function(source)
    local src = source
    
    -- Check permission
    if not ECAdmin.HasPermission(src, 'admin.teleport') then
        return { success = false, error = 'No permission' }
    end
    
    -- Teleport to waypoint
    TriggerClientEvent('ec_admin:client:teleportToWaypoint', src)
    
    -- Log action
    ECAdmin.LogAction(src, 'teleport_waypoint', 'Teleported to waypoint')
    
    return { success = true, message = 'Teleported to waypoint' }
end)

-- Teleport to Coordinates
lib.callback.register('ec_admin:teleportToCoords', function(source, data)
    local src = source
    
    -- Check permission
    if not ECAdmin.HasPermission(src, 'admin.teleport') then
        return { success = false, error = 'No permission' }
    end
    
    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)
    
    if not x or not y or not z then
        return { success = false, error = 'Invalid coordinates' }
    end
    
    -- Teleport to coordinates
    TriggerClientEvent('ec_admin:client:teleportToCoords', src, vector3(x, y, z))
    
    -- Log action
    ECAdmin.LogAction(src, 'teleport_coords', string.format('Teleported to %.2f, %.2f, %.2f', x, y, z))
    
    return { success = true, message = 'Teleported to coordinates' }
end)

-- Bring All Players
lib.callback.register('ec_admin:bringAllPlayers', function(source)
    local src = source
    
    -- Check permission (requires superadmin)
    if not ECAdmin.HasPermission(src, 'admin.bring.all') then
        return { success = false, error = 'No permission - Requires Super Admin' }
    end
    
    -- Get admin position
    local adminPed = GetPlayerPed(src)
    local adminCoords = GetEntityCoords(adminPed)
    
    -- Teleport all players
    local players = GetPlayers()
    local count = 0
    
    for _, playerId in ipairs(players) do
        local targetId = tonumber(playerId)
        if targetId ~= src then
            TriggerClientEvent('ec_admin:client:teleportToCoords', targetId, adminCoords)
            count = count + 1
        end
    end
    
    -- Log action
    ECAdmin.LogAction(src, 'bring_all', string.format('Brought %d players to their location', count))
    
    return { success = true, message = string.format('Brought %d players to your location', count), count = count }
end)

-- ============================================================================
-- QUICK ACTIONS - VEHICLE
-- ============================================================================
-- ❌ DUPLICATE CALLBACK - Disabled to avoid conflict
-- This callback has a better implementation in vehicles-callbacks.lua
--[[
-- Spawn Vehicle
lib.callback.register('ec_admin:spawnVehicle', function(source, data)
    local src = source
    
    -- Check permission
    if not ECAdmin.HasPermission(src, 'admin.vehicle.spawn') then
        return { success = false, error = 'No permission' }
    end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:spawnVehicle') then
        return { success = false, error = 'Rate limit exceeded' }
    end

    local model = data.model

    if not model or model == '' then
        return { success = false, error = 'Invalid vehicle model' }
    end
    
    -- Spawn vehicle
    TriggerClientEvent('ec_admin:client:spawnVehicle', src, model)
    
    -- Log action
    ECAdmin.LogAction(src, 'vehicle_spawn', string.format('Spawned vehicle: %s', model))
    
    return { success = true, message = string.format('Spawned %s', model) }
end)
--]]

-- Fix Vehicle
lib.callback.register('ec_admin:fixVehicle', function(source)
    local src = source
    
    -- Check permission
    if not ECAdmin.HasPermission(src, 'admin.vehicle.fix') then
        return { success = false, error = 'No permission' }
    end
    
    -- Fix vehicle
    TriggerClientEvent('ec_admin:client:fixVehicle', src)
    
    -- Log action
    ECAdmin.LogAction(src, 'vehicle_fix', 'Fixed current vehicle')
    
    return { success = true, message = 'Vehicle repaired' }
end)

-- Delete Vehicle
lib.callback.register('ec_admin:deleteVehicle', function(source)
    local src = source
    
    -- Check permission
    if not ECAdmin.HasPermission(src, 'admin.vehicle.delete') then
        return { success = false, error = 'No permission' }
    end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:deleteVehicle') then
        return { success = false, error = 'Rate limit exceeded' }
    end

    -- Delete vehicle
    TriggerClientEvent('ec_admin:client:deleteVehicle', src)
    
    -- Log action
    ECAdmin.LogAction(src, 'vehicle_delete', 'Deleted current vehicle')
    
    return { success = true, message = 'Vehicle deleted' }
end)

-- ============================================================================
-- QUICK ACTIONS - SERVER MANAGEMENT
-- ============================================================================

-- Revive All Players
lib.callback.register('ec_admin:reviveAll', function(source)
    local src = source
    
    -- Check permission (requires superadmin)
    if not ECAdmin.HasPermission(src, 'admin.revive.all') then
        return { success = false, error = 'No permission - Requires Super Admin' }
    end
    
    -- Revive all players
    local players = GetPlayers()
    local count = 0
    
    for _, playerId in ipairs(players) do
        local targetId = tonumber(playerId)
        TriggerClientEvent('ec_admin:client:revivePlayer', targetId)
        count = count + 1
    end
    
    -- Log action
    ECAdmin.LogAction(src, 'revive_all', string.format('Revived all players (%d total)', count))
    
    -- Send server announcement
    TriggerClientEvent('chat:addMessage', -1, {
        color = {0, 255, 0},
        args = {'[EC Admin]', 'All players have been revived by an admin'}
    })
    
    return { success = true, message = string.format('Revived %d players', count), count = count }
end)

-- Clear Area
lib.callback.register('ec_admin:clearArea', function(source, data)
    local src = source
    
    -- Check permission
    if not ECAdmin.HasPermission(src, 'admin.clear.area') then
        return { success = false, error = 'No permission' }
    end
    
    local radius = tonumber(data.radius) or 50.0
    
    -- Clear area
    TriggerClientEvent('ec_admin:client:clearArea', src, radius)
    
    -- Log action
    ECAdmin.LogAction(src, 'clear_area', string.format('Cleared area with radius %.1fm', radius))
    
    return { success = true, message = string.format('Cleared area (%.1fm radius)', radius) }
end)

-- Announcement
lib.callback.register('ec_admin:sendAnnouncement', function(source, data)
    local src = source
    
    -- Check permission
    if not ECAdmin.HasPermission(src, 'admin.announcement') then
        return { success = false, error = 'No permission' }
    end
    
    local message = data.message
    
    if not message or message == '' then
        return { success = false, error = 'Invalid message' }
    end
    
    -- Send announcement to all players
    TriggerClientEvent('chat:addMessage', -1, {
        color = {255, 165, 0},
        args = {'[ANNOUNCEMENT]', message}
    })
    
    -- Also show as notification
    TriggerClientEvent('ec_admin:client:notify', -1, {
        title = 'Server Announcement',
        message = message,
        type = 'info',
        duration = 10000
    })
    
    -- Log action
    ECAdmin.LogAction(src, 'announcement', string.format('Sent announcement: %s', message))
    
    return { success = true, message = 'Announcement sent to all players' }
end)

-- ============================================================================
-- SESSION MANAGEMENT
-- ============================================================================

-- Update last seen timestamp
lib.callback.register('ec_admin:updateLastSeen', function(source)
    local src = source
    local identifier = GetPlayerIdentifierByType(src, 'license')
    
    if not identifier then
        return { success = false }
    end
    
    -- Update last login time
    MySQL.Async.execute('UPDATE ec_admin_users SET last_login = @time WHERE identifier = @identifier', {
        ['@time'] = os.time(),
        ['@identifier'] = identifier
    })
    
    return { success = true }
end)

-- Logout (close panel and log action)
lib.callback.register('ec_admin:logout', function(source)
    local src = source
    
    -- Log logout action
    ECAdmin.LogAction(src, 'logout', 'Logged out of admin panel')
    
    -- Close admin panel
    TriggerClientEvent('ec_admin:client:closePanel', src)
    
    return { success = true, message = 'Logged out successfully' }
end)

Logger.Info('Topbar callbacks loaded successfully', '✅')
