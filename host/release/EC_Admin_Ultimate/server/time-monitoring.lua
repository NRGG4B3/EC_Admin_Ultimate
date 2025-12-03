-- EC Admin Ultimate - Time Monitoring System
-- Comprehensive time tracking for server uptime, player sessions, and performance history
-- Version: 1.0.0

Logger.Info('⏱️  Loading time monitoring system...')

local TimeMonitoring = {}

-- Time tracking state
local timeData = {
    server = {
        bootTime = os.time(),
        gameStartTime = GetGameTimer(),
        lastRestart = os.time(),
        totalUptime = 0,
        restartCount = 0,
        peakHourStart = 18, -- 6 PM
        peakHourEnd = 23,   -- 11 PM
        totalServerTime = 0
    },
    playerSessions = {},
    performanceHistory = {},
    sessionStats = {
        totalSessions = 0,
        totalSessionTime = 0,
        longestSession = 0,
        shortestSession = 999999999
    },
    peakTimes = {
        dailyPeak = {},
        hourlyActivity = {}
    }
}

-- Configuration
local config = {
    performanceSnapshotInterval = 5000,  -- 5 seconds
    sessionUpdateInterval = 1000,        -- 1 second for live updates
    historyLimit = 60,                   -- Keep last 60 snapshots (5 minutes)
    afkThreshold = 300,                  -- 5 minutes before marking as AFK
    idleThreshold = 120,                 -- 2 minutes before marking as idle
    saveInterval = 300000,               -- Save stats every 5 minutes
    enablePersistence = true
}

-- Initialize hourly activity tracking
for hour = 0, 23 do
    timeData.peakTimes.hourlyActivity[hour] = {
        totalPlayers = 0,
        peakPlayers = 0,
        samples = 0
    }
end

-- Utility functions
local function GetCurrentHour()
    return tonumber(os.date('%H'))
end

local function GetCurrentDay()
    return os.date('%A')
end

local function FormatTime(timestamp)
    return os.date('%Y-%m-%d %H:%M:%S', timestamp)
end

local function GetPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, 'steam:') then
            return identifier
        end
    end
    
    -- Fallback to license
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, 'license:') then
            return identifier
        end
    end
    
    return nil
end

-- Session Management
function TimeMonitoring.StartPlayerSession(source)
    if not source or source == 0 then return false end
    
    local identifier = GetPlayerIdentifier(source)
    if not identifier then return false end
    
    local currentTime = os.time()
    local gameTime = GetGameTimer()
    
    -- Initialize or update player session
    timeData.playerSessions[identifier] = {
        id = source,
        name = GetPlayerName(source) or 'Unknown',
        joinTime = currentTime,
        gameJoinTime = gameTime,
        lastActivity = currentTime,
        totalSessionTime = 0,
        status = 'active',
        afkWarnings = 0
    }
    
    timeData.sessionStats.totalSessions = timeData.sessionStats.totalSessions + 1
    
    Logger.Info(string.format('', 
        GetPlayerName(source), identifier))
    
    return true
end

function TimeMonitoring.EndPlayerSession(source)
    if not source or source == 0 then return false end
    
    local identifier = GetPlayerIdentifier(source)
    if not identifier or not timeData.playerSessions[identifier] then 
        return false 
    end
    
    local session = timeData.playerSessions[identifier]
    local currentTime = os.time()
    local sessionDuration = currentTime - session.joinTime
    
    -- Update session statistics
    timeData.sessionStats.totalSessionTime = timeData.sessionStats.totalSessionTime + sessionDuration
    
    if sessionDuration > timeData.sessionStats.longestSession then
        timeData.sessionStats.longestSession = sessionDuration
    end
    
    if sessionDuration < timeData.sessionStats.shortestSession then
        timeData.sessionStats.shortestSession = sessionDuration
    end
    
    Logger.Info(string.format('', 
        session.name, sessionDuration))
    
    -- Remove session
    timeData.playerSessions[identifier] = nil
    
    return true
end

function TimeMonitoring.UpdatePlayerActivity(source)
    if not source or source == 0 then return false end
    
    local identifier = GetPlayerIdentifier(source)
    if not identifier or not timeData.playerSessions[identifier] then 
        return false 
    end
    
    local session = timeData.playerSessions[identifier]
    local currentTime = os.time()
    local timeSinceLastActivity = currentTime - session.lastActivity
    
    -- Update activity timestamp
    session.lastActivity = currentTime
    
    -- Update status based on activity
    if timeSinceLastActivity >= config.afkThreshold then
        session.status = 'afk'
    elseif timeSinceLastActivity >= config.idleThreshold then
        session.status = 'idle'
    else
        session.status = 'active'
    end
    
    return true
end

function TimeMonitoring.GetActiveSessions()
    local sessions = {}
    local currentTime = os.time()
    local gameTime = GetGameTimer()
    
    for identifier, session in pairs(timeData.playerSessions) do
        -- Calculate live session time
        local sessionTime = currentTime - session.joinTime
        local timeSinceActivity = currentTime - session.lastActivity
        
        -- Update status
        local status = 'active'
        if timeSinceActivity >= config.afkThreshold then
            status = 'afk'
        elseif timeSinceActivity >= config.idleThreshold then
            status = 'idle'
        end
        
        table.insert(sessions, {
            id = session.id,
            name = session.name,
            sessionTime = sessionTime * 1000, -- Convert to milliseconds for JS
            joinTime = session.joinTime * 1000,
            status = status
        })
    end
    
    return sessions
end

function TimeMonitoring.GetSessionStats()
    local activeSessions = 0
    local totalCurrentSessionTime = 0
    
    for _, session in pairs(timeData.playerSessions) do
        activeSessions = activeSessions + 1
        totalCurrentSessionTime = totalCurrentSessionTime + (os.time() - session.joinTime)
    end
    
    local averageSessionTime = 0
    if timeData.sessionStats.totalSessions > 0 then
        averageSessionTime = (timeData.sessionStats.totalSessionTime + totalCurrentSessionTime) / 
                           (timeData.sessionStats.totalSessions)
    end
    
    return {
        totalSessions = timeData.sessionStats.totalSessions,
        activeSessions = activeSessions,
        averageSessionTime = averageSessionTime * 1000, -- Convert to milliseconds
        longestSession = timeData.sessionStats.longestSession * 1000,
        shortestSession = timeData.sessionStats.shortestSession < 999999999 and 
                         timeData.sessionStats.shortestSession * 1000 or 0
    }
end

-- Performance History Tracking
function TimeMonitoring.CreatePerformanceSnapshot()
    local currentTime = os.time()
    local gameTime = GetGameTimer()
    
    -- Get current metrics (integrate with existing monitoring system)
    local playerCount = 0
    for i = 0, GetNumPlayerIndices() - 1 do
        local player = GetPlayerFromIndex(i)
        if player and tonumber(player) and tonumber(player) > 0 then
            playerCount = playerCount + 1
        end
    end
    
    -- Create snapshot
    local snapshot = {
        timestamp = currentTime * 1000, -- JS timestamp
        cpu = 0,      -- No mock; server does not expose CPU
        memory = 0,   -- No mock
        tps = 0,      -- No mock
        players = playerCount
    }
    
    -- Add to history
    table.insert(timeData.performanceHistory, snapshot)
    
    -- Keep only recent history
    while #timeData.performanceHistory > config.historyLimit do
        table.remove(timeData.performanceHistory, 1)
    end
    
    -- Update hourly activity tracking
    local currentHour = GetCurrentHour()
    if timeData.peakTimes.hourlyActivity[currentHour] then
        local hourData = timeData.peakTimes.hourlyActivity[currentHour]
        hourData.totalPlayers = hourData.totalPlayers + playerCount
        hourData.samples = hourData.samples + 1
        
        if playerCount > hourData.peakPlayers then
            hourData.peakPlayers = playerCount
        end
    end
    
    return snapshot
end

function TimeMonitoring.GetPerformanceHistory()
    return timeData.performanceHistory
end

-- Server Uptime Tracking
function TimeMonitoring.GetUptimeMetrics()
    local currentTime = os.time()
    local gameTime = GetGameTimer()
    
    local uptime = currentTime - timeData.server.bootTime
    local lastRestart = timeData.server.lastRestart
    
    return {
        serverUptime = uptime * 1000,           -- Milliseconds
        lastRestart = lastRestart * 1000,       -- JS timestamp
        bootTime = timeData.server.bootTime * 1000,
        restartCount = timeData.server.restartCount,
        totalServerTime = (timeData.server.totalUptime + uptime) * 1000
    }
end

function TimeMonitoring.RegisterRestart()
    local currentTime = os.time()
    local uptime = currentTime - timeData.server.bootTime
    
    -- Add this session's uptime to total
    timeData.server.totalUptime = timeData.server.totalUptime + uptime
    timeData.server.lastRestart = currentTime
    timeData.server.restartCount = timeData.server.restartCount + 1
    timeData.server.bootTime = currentTime
    
    Logger.Info(string.format('', uptime))
    
    return true
end

-- Peak Time Analysis
function TimeMonitoring.GetPeakTimeAnalysis()
    local peakHour = 0
    local peakPlayers = 0
    
    for hour, data in pairs(timeData.peakTimes.hourlyActivity) do
        if data.peakPlayers > peakPlayers then
            peakPlayers = data.peakPlayers
            peakHour = hour
        end
    end
    
    return {
        peakHourStart = peakHour,
        peakHourEnd = (peakHour + 3) % 24,
        peakPlayers = peakPlayers,
        hourlyActivity = timeData.peakTimes.hourlyActivity
    }
end

-- Comprehensive time metrics
function TimeMonitoring.GetAllTimeMetrics()
    local uptimeMetrics = TimeMonitoring.GetUptimeMetrics()
    local sessionStats = TimeMonitoring.GetSessionStats()
    local peakAnalysis = TimeMonitoring.GetPeakTimeAnalysis()
    local activeSessions = TimeMonitoring.GetActiveSessions()
    local performanceHistory = TimeMonitoring.GetPerformanceHistory()
    
    return {
        server = {
            uptime = uptimeMetrics.serverUptime,
            lastRestart = uptimeMetrics.lastRestart,
            bootTime = uptimeMetrics.bootTime,
            restartCount = uptimeMetrics.restartCount,
            totalServerTime = uptimeMetrics.totalServerTime
        },
        sessions = {
            active = activeSessions,
            stats = sessionStats
        },
        peakTimes = peakAnalysis,
        performanceHistory = performanceHistory,
        currentTime = os.time() * 1000 -- JS timestamp
    }
end

-- Initialize system
function TimeMonitoring.Initialize()
    Logger.Info('⏱️  Initializing time monitoring system...')
    
    -- Start all current player sessions
    for i = 0, GetNumPlayerIndices() - 1 do
        local player = GetPlayerFromIndex(i)
        if player and tonumber(player) and tonumber(player) > 0 then
            TimeMonitoring.StartPlayerSession(tonumber(player))
        end
    end
    
    -- Performance snapshot thread
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(config.performanceSnapshotInterval)
            TimeMonitoring.CreatePerformanceSnapshot()
        end
    end)
    
    -- Session update thread (with error protection)
    Citizen.CreateThread(function()
        -- Wait for server to be fully ready
        Wait(5000)
        
        while true do
            -- Use pcall to prevent server hangs
            local success, error = pcall(function()
                local playerCount = 0
                local maxPlayers = math.min(GetNumPlayerIndices(), 64) -- Safety limit
                
                -- Update all active sessions
                for i = 0, maxPlayers - 1 do
                    local player = GetPlayerFromIndex(i)
                    if player and tonumber(player) and tonumber(player) > 0 then
                        -- Check for player activity
                        TimeMonitoring.UpdatePlayerActivity(tonumber(player))
                        playerCount = playerCount + 1
                    end
                    
                    -- Yield every 10 players to prevent blocking
                    if playerCount % 10 == 0 then
                        Wait(0)
                    end
                end
            end)
            
            if not success then
                Logger.Info('⚠️ Time monitoring error (non-fatal): ' .. tostring(error))
            end
            
            Citizen.Wait(config.sessionUpdateInterval)
        end
    end)
    
    Logger.Info('✅ Time monitoring system initialized')
    Logger.Info(string.format('', FormatTime(timeData.server.bootTime)))
end

-- REMOVED: Event Handlers moved to player-events.lua for centralization
-- The centralized handler calls TimeMonitoring.StartPlayerSession and TimeMonitoring.EndPlayerSession

-- Network Events
RegisterNetEvent('ec-admin:getTimeMetrics')
AddEventHandler('ec-admin:getTimeMetrics', function()
    local source = source
    local metrics = TimeMonitoring.GetAllTimeMetrics()
    TriggerClientEvent('ec-admin:receiveTimeMetrics', source, metrics)
end)

RegisterNetEvent('ec-admin:updatePlayerActivity')
AddEventHandler('ec-admin:updatePlayerActivity', function()
    local source = source
    TimeMonitoring.UpdatePlayerActivity(source)
end)

-- Exports
exports('GetTimeMetrics', function()
    return TimeMonitoring.GetAllTimeMetrics()
end)

exports('GetUptimeMetrics', function()
    return TimeMonitoring.GetUptimeMetrics()
end)

exports('GetActiveSessions', function()
    return TimeMonitoring.GetActiveSessions()
end)

exports('GetSessionStats', function()
    return TimeMonitoring.GetSessionStats()
end)

exports('GetPerformanceHistory', function()
    return TimeMonitoring.GetPerformanceHistory()
end)

exports('RegisterRestart', function()
    return TimeMonitoring.RegisterRestart()
end)

-- DISABLED: Auto-initialization can cause server hangs during startup  
-- Time monitoring will be initialized on-demand when first requested
-- TimeMonitoring.Initialize()

-- Make available globally (without auto-init)
_G.ECTimeMonitoring = TimeMonitoring

-- Register with centralized player events system
if _G.ECPlayerEvents then
    _G.ECPlayerEvents.RegisterSystem('timeMonitoring')
end

Logger.Info('✅ Time monitoring system loaded successfully')
Logger.Info('⏱️  Real-time session tracking active')
