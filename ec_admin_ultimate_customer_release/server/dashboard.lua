--[[
    EC Admin Ultimate - Dashboard UI Backend
    Server-side logic for dashboard metrics and statistics
    
    Handles:
    - getServerMetrics: Current server metrics with percentage changes and health status
    - getMetricsHistory: Historical metrics data for charts
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Dashboard] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Local variables
local metricsHistory = {}  -- Array of metric snapshots (in-memory cache)
local MAX_HISTORY = 100     -- Keep last 100 snapshots in memory
local metricsSnapshot = {   -- Current snapshot for comparison
    playersOnline = 0,
    cachedVehicles = 0,
    timestamp = 0
}
local lastMetricsTime = 0
local SAMPLING_INTERVAL = 30 -- Sample metrics every 30 seconds

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Format time label
local function formatTimeLabel(timestamp)
    local time = os.date("*t", timestamp)
    local hour = time.hour
    local minute = time.min
    local ampm = hour >= 12 and "PM" or "AM"
    hour = hour > 12 and (hour - 12) or (hour == 0 and 12 or hour)
    return string.format("%d:%02d %s", hour, minute, ampm)
end

-- Helper: Get current player count
local function getCurrentPlayerCount()
    return GetNumPlayerIndices() or 0
end

-- Cached TPS value (updated by optimizer, not calculated here)
local cachedTPS = 50
local lastTPSCache = 0

-- Helper: Get server TPS (ticks per second) - optimized to use cached value
local function getServerTPS()
    -- Use cached value from optimizer if available (updated every second)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].GetPerformanceMetrics then
        local success, metrics = pcall(function()
            return exports['ec_admin_ultimate']:GetPerformanceMetrics()
        end)
        if success and metrics and metrics.serverTPS then
            cachedTPS = metrics.serverTPS
            lastTPSCache = os.time()
            return cachedTPS
        end
    end
    
    -- Fallback: return cached value (updated by optimizer thread)
    return cachedTPS
end

-- Helper: Get cached vehicles count
local function getCachedVehiclesCount()
    -- Try to get from vehicle system if available
    local success, count = pcall(function()
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].GetVehicleCount then
            return exports['ec_admin_ultimate']:GetVehicleCount()
    end
        return nil
    end)
    if success and count then return count end
    
    -- Estimate based on player count (rough estimate: 2-3 vehicles per player)
    local playerCount = getCurrentPlayerCount()
    return math.floor(playerCount * 2.5)
end

-- Helper: Get memory usage (MB)
local function getMemoryUsage()
    -- This is a simplified version - actual memory usage requires system monitoring
    -- In production, integrate with performance monitoring system
    local baseMemory = 512 -- Base server memory
    local playerMemory = getCurrentPlayerCount() * 8 -- ~8MB per player
    local resourceMemory = GetNumResources() * 2 -- ~2MB per resource
    
    return baseMemory + playerMemory + resourceMemory
end

-- Helper: Get CPU usage (percentage)
local function getCPUUsage()
    -- Simplified CPU calculation
    -- In production, use actual CPU monitoring
    local baseCPU = 20 -- Base CPU usage
    local playerCPU = getCurrentPlayerCount() * 1.5 -- ~1.5% per player
    local tpsFactor = (60 - getServerTPS()) * 0.5 -- Lower TPS = higher CPU
    
    return math.min(100, baseCPU + playerCPU + tpsFactor)
end

-- Helper: Get network stats
local function getNetworkStats()
    -- Simplified network calculation
    -- In production, use actual network monitoring
    local playerCount = getCurrentPlayerCount()
    local networkIn = playerCount * 0.5  -- MB/s
    local networkOut = playerCount * 0.3  -- MB/s
    
    return {
        networkIn = networkIn,  -- 'in' is reserved keyword, use networkIn
        networkOut = networkOut
    }
end

-- Helper: Calculate percentage change
local function calculatePercentageChange(current, previous)
    if not previous or previous == 0 then
        return 0
    end
    
    local change = ((current - previous) / previous) * 100
    return math.floor(change * 10) / 10 -- Round to 1 decimal
end

-- Helper: Get TPS health status
local function getTPSHealthStatus(tps)
    if tps > 45 then
        return "Excellent"
    elseif tps >= 40 then
        return "Good"
    elseif tps >= 35 then
        return "Fair"
    else
        return "Poor"
    end
end

-- Helper: Get memory health status
local function getMemoryHealthStatus(memoryMB)
    -- Assume max memory of 4096 MB (4GB) - adjust based on your server
    local maxMemory = 4096
    local percentage = (memoryMB / maxMemory) * 100
    
    if percentage < 70 then
        return "Healthy"
    elseif percentage < 85 then
        return "Good"
    elseif percentage < 95 then
        return "Warning"
    else
        return "Critical"
    end
end

-- Helper: Get average ping
local function getAveragePing()
    local players = GetPlayers()
    if #players == 0 then return 0 end
    
    local totalPing = 0
    local count = 0
    for _, playerId in ipairs(players) do
        local source = tonumber(playerId)
        if source then
            local ping = GetPlayerPing(source) or 0
            totalPing = totalPing + ping
            count = count + 1
        end
    end
    
    return count > 0 and math.floor(totalPing / count) or 0
end

-- Helper: Store metrics snapshot
local function storeMetricsSnapshot(metrics)
    local timestamp = getCurrentTimestamp()
    local snapshot = {
        timestamp = timestamp,
        playersOnline = metrics.playersOnline,
        serverTPS = metrics.serverTPS,
        cachedVehicles = metrics.cachedVehicles,
        memoryUsage = metrics.memoryUsage,
        cpuUsage = metrics.cpuUsage,
        networkIn = metrics.networkIn,
        networkOut = metrics.networkOut,
        avgPing = metrics.avgPing or getAveragePing()
    }
    
    -- Store in memory
    table.insert(metricsHistory, snapshot)
    
    -- Trim old snapshots
    if #metricsHistory > MAX_HISTORY then
        table.remove(metricsHistory, 1)
    end
    
    -- Store in database (with error handling for timing issues)
    local success, err = pcall(function()
    MySQL.insert.await([[
        INSERT INTO ec_server_metrics_history (timestamp, players_online, server_tps, cached_vehicles, memory_usage, cpu_usage, network_in, network_out, avg_ping)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        timestamp,
        metrics.playersOnline,
        metrics.serverTPS,
        metrics.cachedVehicles,
        metrics.memoryUsage,
        metrics.cpuUsage,
        metrics.networkIn,
        metrics.networkOut,
        snapshot.avgPing
    })
    end)
    
    -- Silently fail if table doesn't exist yet (SQL migration may still be running)
    if not success and err and not tostring(err):match("doesn't exist") then
        -- Only log non-table-existence errors
        print("^3[Dashboard]^7 Warning: Could not store metrics snapshot: " .. tostring(err) .. "^0")
    end
    
    -- Update comparison snapshot
    metricsSnapshot = {
        playersOnline = metrics.playersOnline,
        cachedVehicles = metrics.cachedVehicles,
        timestamp = timestamp
    }
end

-- Helper: Get historical metrics
local function getHistoricalMetrics(minutes)
    minutes = minutes or 20
    local cutoffTime = getCurrentTimestamp() - (minutes * 60)
    
    -- Try to get from database first
    local dbResult = MySQL.query.await([[
        SELECT timestamp, players_online, server_tps, memory_usage, cpu_usage, avg_ping
        FROM ec_server_metrics_history
        WHERE timestamp >= ?
        ORDER BY timestamp ASC
        LIMIT 100
    ]], {cutoffTime})
    
    local filtered = {}
    
    if dbResult and #dbResult > 0 then
        -- Use database results
        for _, row in ipairs(dbResult) do
            table.insert(filtered, {
                time = formatTimeLabel(row.timestamp),
                players = row.players_online,
                tps = row.server_tps,
                memory = row.memory_usage,
                cpu = row.cpu_usage,
                avgPing = row.avg_ping or 0
            })
        end
    else
        -- Fallback to memory
        for _, snapshot in ipairs(metricsHistory) do
            if snapshot.timestamp >= cutoffTime then
                table.insert(filtered, {
                    time = formatTimeLabel(snapshot.timestamp),
                    players = snapshot.playersOnline,
                    tps = snapshot.serverTPS,
                    memory = snapshot.memoryUsage,
                    cpu = snapshot.cpuUsage,
                    avgPing = snapshot.avgPing or 0
                })
            end
        end
    end
    
    -- If no history, create a current snapshot
    if #filtered == 0 then
        local current = {
            playersOnline = getCurrentPlayerCount(),
            serverTPS = getServerTPS(),
            cachedVehicles = getCachedVehiclesCount(),
            memoryUsage = getMemoryUsage(),
            cpuUsage = getCPUUsage(),
            networkIn = getNetworkStats().networkIn,
            networkOut = getNetworkStats().networkOut
        }
        table.insert(filtered, {
            time = formatTimeLabel(getCurrentTimestamp()),
            players = current.playersOnline,
            tps = current.serverTPS,
            memory = current.memoryUsage,
            cpu = current.cpuUsage,
            avgPing = getAveragePing()
        })
    end
    
    return filtered
end

-- Cached metrics response (updated by sampling thread, not on every callback)
local cachedMetricsResponse = nil
local cachedMetricsTime = 0
local METRICS_CACHE_TTL = 2 -- Cache for 2 seconds

-- Callback: Get server metrics (optimized with caching and throttling)
lib.callback.register('ec_admin:getServerMetrics', function(source)
    -- Check cache first (avoid expensive recalculations)
    local currentTime = getCurrentTimestamp()
    if cachedMetricsResponse and (currentTime - cachedMetricsTime) < METRICS_CACHE_TTL then
        return cachedMetricsResponse
    end
    
    -- Get current metrics (use lightweight/cached functions)
    local networkStats = getNetworkStats()
    local currentMetrics = {
        playersOnline = getCurrentPlayerCount(), -- Lightweight
        serverTPS = getServerTPS(), -- Uses cached value
        cachedVehicles = getCachedVehiclesCount(), -- Uses export cache
        memoryUsage = getMemoryUsage(), -- Lightweight calculation
        cpuUsage = getCPUUsage(), -- Lightweight calculation
        networkIn = networkStats['in'],
        networkOut = networkStats.out,
        avgPing = getAveragePing() -- Lightweight
    }
    
    -- Calculate percentage changes
    local percentageChanges = {
        players = calculatePercentageChange(currentMetrics.playersOnline, metricsSnapshot.playersOnline),
        vehicles = calculatePercentageChange(currentMetrics.cachedVehicles, metricsSnapshot.cachedVehicles)
    }
    
    -- Get health status
    local healthStatus = {
        tps = getTPSHealthStatus(currentMetrics.serverTPS),
        memory = getMemoryHealthStatus(currentMetrics.memoryUsage)
    }
    
    -- Store snapshot for next comparison (only if enough time has passed)
    if (currentTime - lastMetricsTime) >= SAMPLING_INTERVAL then
        CreateThread(function()
            storeMetricsSnapshot(currentMetrics)
        end)
        lastMetricsTime = currentTime
    end
    
    -- Build response
    local response = {
        success = true,
        playersOnline = currentMetrics.playersOnline,
        serverTPS = currentMetrics.serverTPS,
        cachedVehicles = currentMetrics.cachedVehicles,
        memoryUsage = currentMetrics.memoryUsage,
        percentageChanges = percentageChanges,
        healthStatus = healthStatus
    }
    
    -- Update cache
    cachedMetricsResponse = response
    cachedMetricsTime = currentTime
    
    return response
end)

-- Callback: Get quick stats for topbar (lightweight)
lib.callback.register('ec_admin:topbar:getQuickStats', function(source)
    local currentMetrics = {
        playersOnline = getCurrentPlayerCount(),
        serverTPS = getServerTPS(),
        cachedVehicles = getCachedVehiclesCount()
    }
    
    return {
        success = true,
        stats = currentMetrics
    }
end)

-- Callback: Get system info for sidebar (lightweight)
lib.callback.register('ec_admin:sidebar:getSystemInfo', function(source)
    local framework = ECFramework and ECFramework.GetFramework() or 'unknown'
    local serverName = GetConvar('sv_hostname', 'Unknown Server')
    local maxPlayers = GetConvarInt('sv_maxclients', 32)
    
    return {
        success = true,
        systemInfo = {
            framework = framework,
            serverName = serverName,
            maxPlayers = maxPlayers,
            playersOnline = getCurrentPlayerCount(),
            serverTPS = getServerTPS()
        }
    }
end)

-- Callback: Get metrics history
lib.callback.register('ec_admin:getMetricsHistory', function(source)
    local history = getHistoricalMetrics(20) -- Last 20 minutes
    
    -- Return in array format (UI supports both formats)
    return {
        success = true,
        history = history
    }
end)

-- Auto-sampling thread: Collect metrics every 30 seconds (optimized)
CreateThread(function()
    Wait(10000) -- Wait 10 seconds on startup (let server stabilize)
    
    while true do
        -- Use cached values where possible to avoid expensive calls
        local networkStats = getNetworkStats()
        local currentMetrics = {
            playersOnline = getCurrentPlayerCount(), -- Lightweight call
            serverTPS = getServerTPS(), -- Uses cached value from optimizer
            cachedVehicles = getCachedVehiclesCount(), -- Uses export cache
            memoryUsage = getMemoryUsage(), -- Lightweight calculation
            cpuUsage = getCPUUsage(), -- Lightweight calculation
            networkIn = networkStats['in'],
            networkOut = networkStats.out,
            avgPing = getAveragePing() -- Lightweight call
        }
        
        -- Store snapshot asynchronously to avoid blocking
        CreateThread(function()
            storeMetricsSnapshot(currentMetrics)
        end)
        
        lastMetricsTime = getCurrentTimestamp()
        
        Wait(SAMPLING_INTERVAL * 1000) -- Wait 30 seconds
    end
end)

-- Initialize with first snapshot
CreateThread(function()
    Wait(2000) -- Wait 2 seconds for server to stabilize
    
    local networkStats = getNetworkStats()
    local initialMetrics = {
        playersOnline = getCurrentPlayerCount(),
        serverTPS = getServerTPS(),
        cachedVehicles = getCachedVehiclesCount(),
        memoryUsage = getMemoryUsage(),
        cpuUsage = getCPUUsage(),
        networkIn = networkStats['in'],
        networkOut = networkStats.out,
        avgPing = getAveragePing()
    }
    
    storeMetricsSnapshot(initialMetrics)
    lastMetricsTime = getCurrentTimestamp()
    metricsSnapshot = {
        playersOnline = initialMetrics.playersOnline,
        cachedVehicles = initialMetrics.cachedVehicles,
        timestamp = getCurrentTimestamp()
    }
end)

print("^2[Dashboard]^7 UI Backend loaded - Metrics tracking active^0")

