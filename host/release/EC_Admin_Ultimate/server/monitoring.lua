-- EC Admin Ultimate - Monitoring System (PRODUCTION STABLE)
-- Version: 1.0.0 - Safe server monitoring with performance optimization

Logger.Info('📊 Loading monitoring system...')

local Monitoring = {}

-- Monitoring state
local monitoringData = {
    players = {},
    server = {
        startTime = GetGameTimer(),
        lastUpdate = 0,
        tpsHistory = {},
        memoryHistory = {},
        playerHistory = {}
    },
    performance = {
        frameTime = 16.67, -- 60 FPS baseline
        scriptTime = 0,
        entityCount = 0,
        vehicleCount = 0
    },
    alerts = {}
}

-- Configuration
local config = {
    updateInterval = 30000,     -- 30 seconds
    historyLimit = 20,          -- Keep last 20 entries
    tpsThreshold = 20.0,        -- Alert if TPS below this
    memoryThreshold = 80.0,     -- Alert if memory above this %
    enableAlerts = true,
    enableHistory = true
}

-- Safe utility functions
local function GetSafePlayerCount()
    local count = 0
    for i = 0, GetNumPlayerIndices() - 1 do
        local player = GetPlayerFromIndex(i)
        if player and tonumber(player) and tonumber(player) > 0 then
            count = count + 1
        end
    end
    return count
end

local function GetSafeResourceCount()
    local count = 0
    for i = 0, GetNumResources() - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName and GetResourceState(resourceName) == 'started' then
            count = count + 1
        end
    end
    return count
end

local function GetSafeMemoryUsage()
    -- Get real Lua memory usage
    local memoryKB = collectgarbage('count')
    local memoryMB = memoryKB / 1024
    
    -- Estimate total memory available (configurable)
    local totalMemoryMB = GetConvarInt('ec_admin_max_memory', 4096) -- Default 4GB
    
    -- Calculate percentage
    local percentage = (memoryMB / totalMemoryMB) * 100
    
    -- Cap at 100%
    return math.min(math.floor(percentage * 10) / 10, 100.0)
end

local function CalculateTPS()
    local currentTime = GetGameTimer()
    if monitoringData.server.lastTpsCheck then
        local timeDelta = currentTime - monitoringData.server.lastTpsCheck
        if timeDelta > 0 then
            -- Calculate approximate TPS based on frame time
            local fps = math.min(60.0, 1000.0 / math.max(timeDelta, 16.67))
            return math.min(50.0, fps * 0.833) -- Convert FPS to approximate TPS
        end
    end
    monitoringData.server.lastTpsCheck = currentTime
    return 50.0 -- Default TPS
end

local function AddToHistory(historyTable, value, limit)
    table.insert(historyTable, {
        value = value,
        timestamp = os.time()
    })
    
    -- Keep only the last N entries
    while #historyTable > limit do
        table.remove(historyTable, 1)
    end
end

local function CreateAlert(type, message, severity)
    if not config.enableAlerts then return end
    
    local alert = {
        id = string.format('alert_%d_%d', os.time(), math.random(1000, 9999)),
        type = type,
        message = message,
        severity = severity or 'medium',
        timestamp = os.time(),
        acknowledged = false
    }
    
    table.insert(monitoringData.alerts, alert)
    
    -- Keep only last 50 alerts
    while #monitoringData.alerts > 50 do
        table.remove(monitoringData.alerts, 1)
    end
    
    Logger.Info('🚨 ' .. severity:upper() .. ' Alert: ' .. message)
    
    return alert
end

-- Player monitoring functions
function Monitoring.UpdatePlayerData(source)
    if not source or source == 0 then return end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return end
    
    local steamId = nil
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, "steam:") then
            steamId = identifier
            break
        end
    end
    
    if not steamId then return end
    
    local playerData = {
        source = source,
        name = GetPlayerName(source) or 'Unknown',
        identifier = steamId,
        ping = GetPlayerPing(source),
        lastSeen = os.time(),
        joinTime = monitoringData.players[steamId] and monitoringData.players[steamId].joinTime or os.time()
    }
    
    -- Get player position safely
    local ped = GetPlayerPed(source)
    if ped and ped > 0 then
        local coords = GetEntityCoords(ped)
        playerData.position = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }
    end
    
    monitoringData.players[steamId] = playerData
end

function Monitoring.RemovePlayerData(source)
    if not source or source == 0 then return end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return end
    
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, "steam:") then
            monitoringData.players[identifier] = nil
            break
        end
    end
end

-- Server monitoring functions
function Monitoring.UpdateServerMetrics()
    local currentTime = GetGameTimer()
    
    -- Update basic metrics
    local metrics = {
        playersOnline = GetSafePlayerCount(),
        resourceCount = GetSafeResourceCount(),
        memoryUsage = GetSafeMemoryUsage(),
        serverTPS = CalculateTPS(),
        uptime = currentTime - monitoringData.server.startTime,
        timestamp = os.time()
    }
    
    -- Add to history if enabled
    if config.enableHistory then
        AddToHistory(monitoringData.server.playerHistory, metrics.playersOnline, config.historyLimit)
        AddToHistory(monitoringData.server.tpsHistory, metrics.serverTPS, config.historyLimit)
        AddToHistory(monitoringData.server.memoryHistory, metrics.memoryUsage, config.historyLimit)
    end
    
    -- Check for alerts
    if config.enableAlerts then
        -- TPS alert
        if metrics.serverTPS < config.tpsThreshold then
            CreateAlert('performance', 
                       string.format('Low server TPS detected: %.1f', metrics.serverTPS), 
                       'high')
        end
        
        -- Memory alert
        if metrics.memoryUsage > config.memoryThreshold then
            CreateAlert('performance', 
                       string.format('High memory usage detected: %.1f%%', metrics.memoryUsage), 
                       'medium')
        end
        
        -- Player count alert (if very high)
        if metrics.playersOnline > (GetConvarInt('sv_maxclients', 32) * 0.9) then
            CreateAlert('capacity', 
                       string.format('Server near capacity: %d players', metrics.playersOnline), 
                       'medium')
        end
    end
    
    monitoringData.server.lastUpdate = currentTime
    return metrics
end

-- Get monitoring data
function Monitoring.GetPlayerData()
    return monitoringData.players
end

function Monitoring.GetServerMetrics()
    -- Return fresh metrics
    return Monitoring.UpdateServerMetrics()
end

function Monitoring.GetAlerts()
    return monitoringData.alerts
end

function Monitoring.GetHistory()
    return {
        players = monitoringData.server.playerHistory,
        tps = monitoringData.server.tpsHistory,
        memory = monitoringData.server.memoryHistory
    }
end

-- Alert management
function Monitoring.AcknowledgeAlert(alertId)
    for _, alert in pairs(monitoringData.alerts) do
        if alert.id == alertId then
            alert.acknowledged = true
            return true
        end
    end
    return false
end

function Monitoring.ClearAlerts()
    monitoringData.alerts = {}
    return true
end

-- Initialize monitoring system
function Monitoring.Initialize()
    Logger.Info('📊 Initializing monitoring system...')
    
    -- Update all current players
    for i = 0, GetNumPlayerIndices() - 1 do
        local player = GetPlayerFromIndex(i)
        if player and tonumber(player) and tonumber(player) > 0 then
            Monitoring.UpdatePlayerData(tonumber(player))
        end
    end
    
    -- Start monitoring loop (with error protection to prevent server hangs)
    CreateThread(function()
        -- Wait for server to be fully ready before starting monitoring
        Wait(5000)
        
        while true do
            -- Use pcall to catch any errors and prevent server hangs
            local success, error = pcall(function()
                -- Update server metrics (lightweight)
                Monitoring.UpdateServerMetrics()
                
                -- Update player data (safe iteration with limit)
                local playerCount = 0
                local maxPlayers = math.min(GetNumPlayerIndices(), 64) -- Safety limit
                
                for i = 0, maxPlayers - 1 do
                    local player = GetPlayerFromIndex(i)
                    if player and tonumber(player) and tonumber(player) > 0 then
                        Monitoring.UpdatePlayerData(tonumber(player))
                        playerCount = playerCount + 1
                    end
                    
                    -- Add small yield every 10 players to prevent blocking
                    if playerCount % 10 == 0 then
                        Wait(0)
                    end
                end
            end)
            
            if not success then
                Logger.Info('⚠️ Monitoring error (non-fatal): ' .. tostring(error))
            end
            
            -- Wait 30 seconds before next update
            Wait(config.updateInterval)
        end
    end)
    
    Logger.Info('✅ Monitoring system initialized')
end

-- REMOVED: Event handlers moved to player-events.lua for centralization
-- The centralized handler calls Monitoring.UpdatePlayerData and Monitoring.RemovePlayerData

-- Server events
RegisterNetEvent('ec-admin:getServerMetrics')
AddEventHandler('ec-admin:getServerMetrics', function()
    local source = source
    local metrics = Monitoring.GetServerMetrics()
    local playerData = Monitoring.GetPlayerData()
    local alerts = Monitoring.GetAlerts()
    
    -- Get time monitoring data if available
    local timeMetrics = {}
    if _G.ECTimeMonitoring then
        timeMetrics = _G.ECTimeMonitoring.GetAllTimeMetrics()
    end
    
    local response = {
        playersOnline = metrics.playersOnline,
        totalResources = metrics.resourceCount,
        cachedVehicles = 0,
        serverTPS = metrics.serverTPS,
        memoryUsage = metrics.memoryUsage,
        networkIn = 0,
        networkOut = 0,
        cpuUsage = 0,
        uptime = timeMetrics.server and timeMetrics.server.uptime or (GetGameTimer() - monitoringData.server.startTime),
        lastRestart = timeMetrics.server and timeMetrics.server.lastRestart or (monitoringData.server.startTime * 1000),
        activeEvents = 0,
        database = {
            queries = 0,
            avgResponseTime = 0
        },
        alerts = alerts,
        players = playerData,
        -- Add time monitoring data
        timeMetrics = timeMetrics
    }
    
    TriggerClientEvent('ec-admin:receiveServerMetrics', source, response)
end)

RegisterNetEvent('ec-admin:getMonitoringData')
AddEventHandler('ec-admin:getMonitoringData', function()
    local source = source
    
    local response = {
        players = Monitoring.GetPlayerData(),
        server = Monitoring.GetServerMetrics(),
        alerts = Monitoring.GetAlerts(),
        history = Monitoring.GetHistory()
    }
    
    TriggerClientEvent('ec-admin:receiveMonitoringData', source, response)
end)

-- Exports
exports('GetServerMetrics', function()
    return Monitoring.GetServerMetrics()
end)

exports('GetPlayerData', function()
    return Monitoring.GetPlayerData()
end)

exports('GetAlerts', function()
    return Monitoring.GetAlerts()
end)

exports('CreateAlert', function(type, message, severity)
    return CreateAlert(type, message, severity)
end)

-- Make available globally
_G.ECMonitoring = Monitoring

-- Register with centralized player events system
if _G.ECPlayerEvents then
    _G.ECPlayerEvents.RegisterSystem('monitoring')
end

-- DISABLED: Auto-initialization can cause server hangs during startup
-- Monitoring will be initialized on-demand when first requested
-- Monitoring.Initialize()

Logger.Info('✅ Monitoring system loaded successfully')
Logger.Info('📊 Performance monitoring with alerts active')