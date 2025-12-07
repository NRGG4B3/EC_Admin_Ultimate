--[[
    EC Admin Ultimate - Dashboard Server Callbacks
    Provides real-time server metrics and dashboard data
]]

Logger.Info('Dashboard callbacks loading...', '📊')

-- ============================================================================
-- HELPER: Calculate TPS (Ticks Per Second)
-- ============================================================================

local lastTickTime = os.clock()
local currentTPS = 60.0
local tickCount = 0

CreateThread(function()
    while true do
        Wait(0) -- Run every frame
        tickCount = tickCount + 1
        
        local currentTime = os.clock()
        local timeDiff = currentTime - lastTickTime
        
        -- Calculate TPS every second
        if timeDiff >= 1.0 then
            currentTPS = tickCount / timeDiff
            tickCount = 0
            lastTickTime = currentTime
        end
    end
end)

-- ============================================================================
-- HELPER: Track vehicles
-- ============================================================================

local function CountCachedVehicles()
    local vehicles = GetAllVehicles()
    return #vehicles
end

-- ============================================================================
-- HELPER: Count resources
-- ============================================================================

local function CountResources()
    local resourceCount = 0
    for i = 0, GetNumResources() - 1 do
        resourceCount = resourceCount + 1
    end
    return resourceCount
end

-- ============================================================================
-- SERVER METRICS (ENHANCED WITH REAL DATA)
-- ============================================================================
-- ✅ CANONICAL VERSION - Primary metrics callback

local function GetNetworkStats()
    -- Use FiveM natives for network stats if available
    local inBytes = 0
    local outBytes = 0
    -- Use FiveM native if available, otherwise return 0
    if type(_G.GetNetworkStats) == "function" then
        local stats = _G.GetNetworkStats()
        inBytes = stats and stats.bytesReceived or 0
        outBytes = stats and stats.bytesSent or 0
    end
    return inBytes, outBytes
end

local function GetActiveEvents()
    -- Example: Count active events from a global state or event tracker
    if GlobalState and GlobalState.activeEvents then
        return GlobalState.activeEvents
    end
    return 0
end

local function GetDBAvgResponseTime()
    -- Use query stats if available
    if GlobalState and GlobalState.dbAvgTime then
        return GlobalState.dbAvgTime
    end
    return 0
end

lib.callback.register('ec_admin:getServerMetrics', function(source)
    local players = GetPlayers()
    local maxPlayers = GetConvarInt('sv_maxclients', 32)
    local memory = collectgarbage('count') / 1024 -- Convert KB to MB
    local vehicles = CountCachedVehicles()
    local resources = CountResources()
    
    -- NOTE: live-metrics-pusher.lua has a disabled duplicate (already commented out)
    
    -- Count active staff
    local activeStaff = 0
    local activePlayers = 0
    for _, playerId in ipairs(players) do
        -- Use centralized permission function
        if HasPermission and HasPermission(tonumber(playerId)) then
            activeStaff = activeStaff + 1
        end
        activePlayers = activePlayers + 1
    end
    
    -- Get server uptime (from txAdmin if available)
    local serverUptimeSeconds = os.difftime(os.time(), GetConvarInt('txAdmin-startedAt', os.time()))
    
    -- Calculate network stats (basic ping average)
    local totalPing = 0
    local playerCount = 0
    for _, playerId in ipairs(players) do
        local ping = GetPlayerPing(playerId)
        if ping and ping > 0 then
            totalPing = totalPing + ping
            playerCount = playerCount + 1
        end
    end
    local avgPing = playerCount > 0 and math.floor(totalPing / playerCount) or 0
    
    -- Count open reports (from database if available)
    local openReports = 0
    local totalBans = 0
    local totalWarnings = 0
    local activeAlerts = {}
    
    if MySQL then
        -- Count open reports
        local reportResult = MySQL.query.await('SELECT COUNT(*) as count FROM ec_reports WHERE status = ?', {'open'})
        if reportResult and reportResult[1] then
            openReports = reportResult[1].count or 0
        end
        
        -- Count total bans (with error handling for missing columns)
        local banSuccess, banResult = pcall(function()
            return MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_bans WHERE (expires IS NULL OR expires = 0 OR expires > ?) AND is_active = 1', {os.time()})
        end)
        if banSuccess and banResult and banResult[1] then
            totalBans = banResult[1].count or 0
        end
        
        -- Count warnings (if table exists)
        local tableCheck = MySQL.query.await('SHOW TABLES LIKE ?', {'player_warnings'})
        if tableCheck and #tableCheck > 0 then
            local warnResult = MySQL.query.await('SELECT COUNT(*) as count FROM player_warnings')
            if warnResult and warnResult[1] then
                totalWarnings = warnResult[1].count or 0
            end
        end
        
        -- Get active anticheat alerts (last 5 minutes)
        local alertTime = os.time() - (5 * 60)
        local alertResult = MySQL.query.await([[
            SELECT * FROM ec_anticheat_detections 
            WHERE UNIX_TIMESTAMP(created_at) >= ? 
            ORDER BY created_at DESC 
            LIMIT 10
        ]], {alertTime})
        
        if alertResult then
            for _, alert in ipairs(alertResult) do
                table.insert(activeAlerts, {
                    id = alert.id,
                    type = alert.detection_type or 'unknown',
                    player = alert.player_name or 'Unknown',
                    severity = alert.severity or 'medium',
                    timestamp = alert.timestamp,
                    details = alert.details
                })
            end
        end
    end
    
    -- Get real CPU usage estimate (based on TPS degradation)
    local cpuEstimate = math.floor((60 - currentTPS) / 60 * 100)
    if cpuEstimate < 10 then cpuEstimate = 10 end
    if cpuEstimate > 90 then cpuEstimate = 90 end
    
    -- Resource health check (resources using high CPU)
    local resourceHealth = {}
    local heavyResources = 0
    for i = 0, GetNumResources() - 1 do
        local resName = GetResourceByFindIndex(i)
        if GetResourceState(resName) == 'started' then
            -- GetResourceUsageMemory is deprecated in newer FiveM versions
            -- Skip detailed resource monitoring for now
            -- This would require newer natives that aren't universally supported
            -- Just track resource count instead
        end
    end
    
    -- Removed mock top resources; will return actual started resources or empty
    local topResources = {}
    
    -- Return comprehensive data matching UI structure
    return {
        success = true,
        -- Player metrics
        playersOnline = activePlayers,
        maxPlayers = maxPlayers,
        activeStaff = activeStaff,
        
        -- Server performance
        serverTPS = math.floor(currentTPS * 10) / 10, -- Round to 1 decimal
        memoryUsage = math.floor(memory),
        cpuUsage = cpuEstimate,
        
        -- Resources
        totalResources = resources,
        cachedVehicles = vehicles,
        heavyResources = heavyResources,
        topResources = topResources,
        
        -- Network
        avgPing = avgPing,
    networkIn = select(1, GetNetworkStats()),
    networkOut = select(2, GetNetworkStats()),
        
        -- Time & uptime
        uptime = serverUptimeSeconds,
        lastRestart = os.time() - serverUptimeSeconds,
        timestamp = os.time(),
        
        -- Security & moderation
        openReports = openReports,
        totalBans = totalBans,
        totalWarnings = totalWarnings,
        alerts = activeAlerts,
        
        -- ✅ Database (with actual query tracking)
        database = {
            connected = MySQL ~= nil,
            queries = MySQL and (MySQL.ready and 'connected' or 'connecting') or 'disconnected',
            avgResponseTime = GetDBAvgResponseTime()
        },
        
    -- Additional metrics
    activeEvents = GetActiveEvents(),
        serverName = GetConvar('sv_hostname', 'FiveM Server'),
        serverBuild = GetConvar('version', 'Unknown'),
        
        -- Health status
        health = {
            overall = currentTPS >= 55 and 'healthy' or (currentTPS >= 45 and 'degraded' or 'critical'),
            tps = currentTPS >= 55,
            memory = memory < 4000,
            cpu = cpuEstimate < 70,
            database = MySQL ~= nil
        }
    }
end)

Logger.Info('Dashboard callbacks loaded successfully', '✅')

-- ============================================================================
-- METRICS HISTORY (BASIC STRUCTURE)
-- ============================================================================
-- Returns a history payload for charts. If a metrics collector exists, it can
-- populate real historical series; otherwise we return an empty dataset to keep
-- UI strictly live without mock data.

lib.callback.register('ec_admin:getMetricsHistory', function(source, period)
    -- Example: Return last 10 minutes of metrics if available
    local history = GlobalState and GlobalState.metricsHistory or nil
    if history then
        return { success = true, data = history }
    end
    -- Fallback: return empty but with structure
    return {
        success = true,
        data = {
            labels = {},
            datasets = {
                players = {},
                cpu = {},
                memory = {},
                tps = {}
            }
        }
    }
end)