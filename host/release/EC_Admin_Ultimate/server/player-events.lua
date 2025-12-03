-- EC Admin Ultimate - Centralized Player Event Handler
-- This is the ONLY file that handles playerJoining events
-- All other systems are initialized through function calls, not separate event handlers

local PlayerEvents = {}

-- Track initialized systems
local initializedSystems = {
    permissions = false,
    monitoring = false,
    timeMonitoring = false,
    economy = false,
    antiCheat = false,
    adminAbuse = false,
    security = false,
    dataSync = false
}

-- Safe function caller with error handling
local function SafeCall(functionName, func, ...)
    local success, err = pcall(func, ...)
    if not success then
        Logger.Info(string.format('', functionName, tostring(err)))
    end
    return success
end

-- Initialize a player session across all systems
function PlayerEvents.InitializePlayer(source)
    if not source or source == 0 then return end
    
    -- Use async thread to prevent blocking
    Citizen.CreateThread(function()
        -- Small delay to ensure player is fully connected
        Wait(1500)
        
        -- Verify player still connected
        if not source or source == 0 then return end
        local playerName = GetPlayerName(source)
        if not playerName then return end
        
        Logger.Info(string.format('', playerName, source))
        
        -- Initialize each system with error protection
        -- Permissions System
        if _G.ECPermissions and initializedSystems.permissions then
            SafeCall('Permissions', function()
                local identifier = GetPlayerIdentifier(source)
                if identifier then
                    local permission = _G.ECPermissions.GetPlayerPermission(source, identifier)
                    if permission ~= 'user' then
                        Logger.Info(string.format('', playerName, permission))
                    end
                end
            end)
            Wait(100)
        end
        
        -- Monitoring System
        if _G.ECMonitoring and initializedSystems.monitoring then
            SafeCall('Monitoring', function()
                _G.ECMonitoring.UpdatePlayerData(source)
            end)
            Wait(100)
        end
        
        -- Time Monitoring System
        if _G.ECTimeMonitoring and initializedSystems.timeMonitoring then
            SafeCall('TimeMonitoring', function()
                _G.ECTimeMonitoring.StartPlayerSession(source)
            end)
            Wait(100)
        end
        
        -- Economy System
        if _G.ECEconomy and initializedSystems.economy then
            SafeCall('Economy', function()
                _G.ECEconomy.UpdatePlayerBalance(source)
            end)
            Wait(100)
        end
        
        -- Anti-Cheat System
        if _G.ECAntiCheat and initializedSystems.antiCheat then
            SafeCall('AntiCheat', function()
                -- Anti-cheat initializes trust scores automatically
            end)
            Wait(100)
        end
        
        -- Admin Abuse Monitoring
        if _G.ECAdminAbuse and initializedSystems.adminAbuse then
            SafeCall('AdminAbuse', function()
                if _G.ECPermissions then
                    if _G.ECPermissions.HasPermission(source, 'admin') or
                       _G.ECPermissions.HasPermission(source, 'moderator') or
                       _G.ECPermissions.HasPermission(source, 'owner') then
                        -- Admin abuse system handles initialization internally
                    end
                end
            end)
            Wait(100)
        end
        
        -- Security System
        if _G.ECSecurity and initializedSystems.security then
            SafeCall('Security', function()
                -- Security checks are done in playerConnecting, not here
            end)
        end
        
        -- Data Sync System
        if _G.ECAdminSync and initializedSystems.dataSync then
            SafeCall('DataSync', function()
                -- Update global state
                GlobalState.recentJoins = (GlobalState.recentJoins or 0) + 1
            end)
        end
        
        -- Webhook Notification
        if _G.ECWebhooks then
            SafeCall('Webhooks', function()
                Citizen.SetTimeout(1000, function()
                    local playerCount = 0
                    for i = 0, GetNumPlayerIndices() - 1 do
                        if GetPlayerFromIndex(i) then
                            playerCount = playerCount + 1
                        end
                    end
                    local maxPlayers = GetConvarInt('sv_maxclients', 32)
                    _G.ECWebhooks.SendPlayerJoin(playerName, playerCount, maxPlayers)
                end)
            end)
        end
        
        Logger.Info(string.format('', playerName))
    end)
end

-- Handle player disconnect across all systems
function PlayerEvents.CleanupPlayer(source, reason)
    if not source or source == 0 then return end
    
    local playerName = GetPlayerName(source) or 'Unknown'
    Logger.Info(string.format('', playerName, source, reason or 'Unknown'))
    
    -- Use async thread to prevent blocking
    Citizen.CreateThread(function()
        -- Time Monitoring cleanup
        if _G.ECTimeMonitoring and initializedSystems.timeMonitoring then
            SafeCall('TimeMonitoring.EndSession', function()
                _G.ECTimeMonitoring.EndPlayerSession(source)
            end)
        end
        
        -- Monitoring cleanup
        if _G.ECMonitoring and initializedSystems.monitoring then
            SafeCall('Monitoring.Remove', function()
                _G.ECMonitoring.RemovePlayerData(source)
            end)
        end
        
        -- Data Sync cleanup
        if _G.ECAdminSync and initializedSystems.dataSync then
            SafeCall('DataSync.Leave', function()
                GlobalState.recentLeaves = (GlobalState.recentLeaves or 0) + 1
            end)
        end
        
        -- Webhook notification
        if _G.ECWebhooks then
            SafeCall('Webhooks.Leave', function()
                local playerCount = 0
                for i = 0, GetNumPlayerIndices() - 1 do
                    if GetPlayerFromIndex(i) then
                        playerCount = playerCount + 1
                    end
                end
                local maxPlayers = GetConvarInt('sv_maxclients', 32)
                _G.ECWebhooks.SendPlayerLeave(playerName, reason or 'Disconnected', playerCount - 1, maxPlayers)
            end)
        end
    end)
end

-- Register system as initialized
function PlayerEvents.RegisterSystem(systemName)
    if initializedSystems[systemName] ~= nil then
        initializedSystems[systemName] = true
        Logger.Info(string.format('', systemName))
    end
end

-- THE ONLY playerJoining event handler in the entire resource
AddEventHandler('playerJoining', function()
    local source = source
    PlayerEvents.InitializePlayer(source)
end)

-- THE ONLY playerDropped event handler in the entire resource
AddEventHandler('playerDropped', function(reason)
    local source = source
    PlayerEvents.CleanupPlayer(source, reason)
end)

-- Initialize
Logger.Info('🎮 Centralized Player Event Handler loaded')
Logger.Info('ℹ️  This is the ONLY playerJoining/playerDropped handler')

-- Export for other systems to register themselves
_G.ECPlayerEvents = PlayerEvents

return PlayerEvents
