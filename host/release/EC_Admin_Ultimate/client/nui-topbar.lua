--[[
    EC Admin Ultimate - Topbar NUI Callbacks (CLIENT)
    Uses ox_lib callback system for proper async handling
]]

Logger.Info('✅ Topbar NUI callbacks registered (CLIENT)')

-- ============================================================================
-- UI READY HANDSHAKE
-- ============================================================================

-- UI Ready - React sends this when mounted
RegisterNUICallback('uiReady', function(data, cb)
    Logger.Info('✅ UI Ready - React mounted successfully')
    cb({ success = true, message = 'Server acknowledged' })
end)

-- Close Panel - React sends this when close button clicked
RegisterNUICallback('closePanel', function(data, cb)
    Logger.Info('🔒 Close panel requested from UI')
    TriggerEvent('ec_admin:client:closePanel')
    cb({ success = true })
end)

-- ============================================================================
-- ADMIN PROFILE DATA
-- ============================================================================

-- Get admin profile
RegisterNUICallback('topbar:getAdminProfile', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getAdminProfile', false)
    end)
    
    if success and result then
        cb(result)
    else
        -- Fallback data if server callback fails
        cb({
            success = true,
            data = {
                name = GetPlayerName(PlayerId()),
                username = GetPlayerName(PlayerId()),
                email = 'admin@ecadmin.local',
                role = 'admin',
                roleLabel = 'Admin',
                avatar = nil,
                permissions = {},
                lastLogin = GetGameTimer(), -- Use GetGameTimer() instead of os.time() on client
                isSuperUser = false
            }
        })
    end
end)

-- Get quick stats
RegisterNUICallback('topbar:getQuickStats', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getQuickStats', false)
    end)
    
    if success and result then
        cb(result)
    else
        -- Fallback stats
        local players = GetActivePlayers()
        cb({
            success = true,
            data = {
                playersOnline = #players,
                maxPlayers = GetConvarInt('sv_maxclients', 32),
                openReports = 0,
                activeStaff = 1,
                serverUptime = '0h 0m',
                avgPing = 0
            }
        })
    end
end)

-- ============================================================================
-- QUICK ACTIONS - SELF ACTIONS
-- ============================================================================

-- NoClip Toggle
RegisterNUICallback('topbar:toggleNoclip', function(data, cb)
    TriggerEvent('ec_admin:toggleNoclip') -- FIXED: Was ec_admin:client:toggleNoclip
    cb({ success = true, message = 'NoClip toggled' })
end)

-- God Mode Toggle
RegisterNUICallback('topbar:toggleGodmode', function(data, cb)
    TriggerEvent('ec_admin:client:toggleGodmode')
    cb({ success = true, message = 'God Mode toggled' })
end)

-- Invisibility Toggle
RegisterNUICallback('topbar:toggleInvisibility', function(data, cb)
    TriggerEvent('ec_admin:client:toggleInvisibility')
    cb({ success = true, message = 'Invisibility toggled' })
end)

-- Teleport to Waypoint
RegisterNUICallback('topbar:teleportToWaypoint', function(data, cb)
    TriggerEvent('ec_admin:client:teleportToWaypoint')
    cb({ success = true, message = 'Teleporting...' })
end)

-- Heal Self
RegisterNUICallback('topbar:healSelf', function(data, cb)
    TriggerServerEvent('ec_admin:server:healSelf')
    cb({ success = true, message = 'Healed' })
end)

-- Fix Vehicle
RegisterNUICallback('topbar:fixVehicle', function(data, cb)
    TriggerEvent('ec_admin:client:fixVehicle')
    cb({ success = true, message = 'Vehicle fixed' })
end)

-- ============================================================================
-- SERVER CONTROL ACTIONS
-- ============================================================================

-- Restart Server
RegisterNUICallback('topbar:restartServer', function(data, cb)
    TriggerServerEvent('ec_admin:server:restartServer', data.delay or 60)
    cb({ success = true, message = 'Server restart scheduled' })
end)

-- Announcement
RegisterNUICallback('topbar:sendAnnouncement', function(data, cb)
    TriggerServerEvent('ec_admin:server:sendAnnouncement', data.message, data.type or 'info')
    cb({ success = true, message = 'Announcement sent' })
end)

-- Weather Control
RegisterNUICallback('topbar:setWeather', function(data, cb)
    TriggerServerEvent('ec_admin:server:setWeather', data.weather)
    cb({ success = true, message = 'Weather changed' })
end)

-- Time Control
RegisterNUICallback('topbar:setTime', function(data, cb)
    TriggerServerEvent('ec_admin:server:setTime', data.hour, data.minute)
    cb({ success = true, message = 'Time changed' })
end)

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

-- Get Online Players
RegisterNUICallback('topbar:getOnlinePlayers', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getOnlinePlayers', false)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = true, data = {} })
    end
end)

-- Kick Player
RegisterNUICallback('topbar:kickPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:server:kickPlayer', data.playerId, data.reason or 'Kicked by admin')
    cb({ success = true, message = 'Player kicked' })
end)

-- Ban Player
RegisterNUICallback('topbar:banPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:server:banPlayer', data.playerId, data.reason, data.duration)
    cb({ success = true, message = 'Player banned' })
end)

-- Teleport to Player
RegisterNUICallback('topbar:teleportToPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:server:teleportToPlayer', data.playerId)
    cb({ success = true, message = 'Teleporting...' })
end)

-- Bring Player
RegisterNUICallback('topbar:bringPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:server:bringPlayer', data.playerId)
    cb({ success = true, message = 'Player brought' })
end)

-- Freeze Player
RegisterNUICallback('topbar:freezePlayer', function(data, cb)
    TriggerServerEvent('ec_admin:server:freezePlayer', data.playerId)
    cb({ success = true, message = 'Player frozen' })
end)

-- Spectate Player
RegisterNUICallback('topbar:spectatePlayer', function(data, cb)
    TriggerServerEvent('ec_admin:server:spectatePlayer', data.playerId)
    cb({ success = true, message = 'Spectating player' })
end)

-- ============================================================================
-- RESOURCES & SCRIPTS
-- ============================================================================

-- Get Resources
RegisterNUICallback('topbar:getResources', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getResources', false)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = true, data = {} })
    end
end)

-- Restart Resource
RegisterNUICallback('topbar:restartResource', function(data, cb)
    TriggerServerEvent('ec_admin:server:restartResource', data.resourceName)
    cb({ success = true, message = 'Resource restarting' })
end)

-- Stop Resource
RegisterNUICallback('topbar:stopResource', function(data, cb)
    TriggerServerEvent('ec_admin:server:stopResource', data.resourceName)
    cb({ success = true, message = 'Resource stopped' })
end)

-- Start Resource
RegisterNUICallback('topbar:startResource', function(data, cb)
    TriggerServerEvent('ec_admin:server:startResource', data.resourceName)
    cb({ success = true, message = 'Resource started' })
end)

Logger.Info('✅ Topbar callbacks initialized - All actions ready')