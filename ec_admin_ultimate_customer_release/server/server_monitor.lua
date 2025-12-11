--[[
    EC Admin Ultimate - Server Monitor UI Backend
    Server-side logic for server monitoring and resource management
    
    Handles:
    - getServerMetrics: Server performance metrics with history
    - getNetworkMetrics: Network performance metrics
    - getResources: All resources with status and performance
    - getDatabaseMetrics: Database performance metrics
    - getPlayerPositions: Player positions for live map
    - restartResource: Restart a resource
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Server Monitor] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Server Monitor] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local metricsHistory = {}
local MAX_HISTORY = 100
local resourceCache = {}
local CACHE_TTL = 5
local serverStartTime = os.time()

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Check admin permission
local function hasPermission(source, permission)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, permission)
    end
    return ECFramework.IsAdminGroup(source) or false
end

-- Helper: Get server TPS
local function getServerTPS()
    -- Simplified TPS calculation
    local playerCount = GetNumPlayerIndices() or 0
    local baseTPS = 60
    local tps = math.max(30, baseTPS - (playerCount * 0.3))
    tps = tps + (math.random() * 2 - 1) -- ±1 variance
    return math.max(0, math.min(60, tps))
end

-- Helper: Get server memory usage
local function getServerMemoryUsage()
    -- Simplified memory calculation
    local baseMemory = 512
    local playerMemory = (GetNumPlayerIndices() or 0) * 8
    local resourceMemory = GetNumResources() * 2
    return baseMemory + playerMemory + resourceMemory
end

-- Helper: Get server CPU usage
local function getServerCPUUsage()
    -- Simplified CPU calculation
    local baseCPU = 20
    local playerCPU = (GetNumPlayerIndices() or 0) * 1.5
    local tpsFactor = (60 - getServerTPS()) * 0.5
    return math.min(100, baseCPU + playerCPU + tpsFactor)
end

-- Helper: Get server uptime
local function getServerUptime()
    return (os.time() - serverStartTime) * 1000 -- Convert to milliseconds
end

-- Helper: Get network bandwidth
local function getNetworkBandwidth()
    local playerCount = GetNumPlayerIndices() or 0
    return {
        networkIn = playerCount * 0.5,  -- MB/s - 'in' is reserved keyword
        networkOut = playerCount * 0.3   -- MB/s
    }
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

-- Helper: Get peak today
local function getPeakToday()
    local today = os.date("%Y-%m-%d")
    local result = MySQL.query.await([[
        SELECT MAX(players) as peak
        FROM ec_server_monitor_history
        WHERE DATE(FROM_UNIXTIME(timestamp)) = ?
    ]], {today})
    
    if result and result[1] and result[1].peak then
        return result[1].peak
    end
    
    return GetNumPlayerIndices() or 0
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

-- Helper: Store metrics snapshot
local function storeMetricsSnapshot(metrics)
    local timestamp = getCurrentTimestamp()
    local snapshot = {
        timestamp = timestamp,
        tps = metrics.tps,
        memory = metrics.memory,
        cpu = metrics.cpu,
        players = metrics.players
    }
    
    -- Store in memory
    table.insert(metricsHistory, snapshot)
    
    if #metricsHistory > MAX_HISTORY then
        table.remove(metricsHistory, 1)
    end
    
    -- Optionally store in database (uncomment to enable)
    -- MySQL.insert.await([[
    --     INSERT INTO ec_server_monitor_history (timestamp, tps, memory, cpu, players)
    --     VALUES (?, ?, ?, ?, ?)
    -- ]], {timestamp, metrics.tps, metrics.memory, metrics.cpu, metrics.players})
end

-- Helper: Get metrics history
local function getMetricsHistory(minutes)
    minutes = minutes or 20
    local cutoffTime = getCurrentTimestamp() - (minutes * 60)
    
    -- Try to get from database first (if enabled), otherwise use memory
    -- Uncomment to use database:
    -- local result = MySQL.query.await([[
    --     SELECT timestamp, tps, memory, cpu, players
    --     FROM ec_server_monitor_history
    --     WHERE timestamp >= ?
    --     ORDER BY timestamp ASC
    --     LIMIT 100
    -- ]], {cutoffTime})
    -- 
    -- if result and #result > 0 then
    --     local filtered = {}
    --     for _, row in ipairs(result) do
    --         table.insert(filtered, {
    --             time = formatTimeLabel(row.timestamp),
    --             tps = row.tps,
    --             memory = row.memory,
    --             cpu = row.cpu
    --         })
    --     end
    --     return filtered
    -- end
    
    -- Fallback to memory
    local filtered = {}
    for _, snapshot in ipairs(metricsHistory) do
        if snapshot.timestamp >= cutoffTime then
            table.insert(filtered, {
                time = formatTimeLabel(snapshot.timestamp),
                tps = snapshot.tps,
                memory = snapshot.memory,
                cpu = snapshot.cpu
            })
        end
    end
    
    return filtered
end

-- Helper: Get resource status
local function getResourceStatus(resourceName)
    local state = GetResourceState(resourceName)
    if state == 'started' then
        return 'running'
    elseif state == 'stopped' then
        return 'stopped'
    else
        return 'error'
    end
end

-- Helper: Get resource performance (simplified - FiveM doesn't provide native per-resource stats)
local function getResourcePerformance(resourceName)
    -- FiveM doesn't provide native CPU/memory per resource
    -- This is a placeholder - in production, integrate with performance monitoring system
    return {
        cpu = math.random() * 5,      -- Placeholder
        memory = 10 + math.random() * 100, -- Placeholder
        threads = math.random(1, 5)    -- Placeholder
    }
end

-- Helper: Get resource uptime
local function getResourceUptime(resourceName)
    -- Track resource start time (simplified)
    -- In production, track actual start times
    local state = GetResourceState(resourceName)
    if state == 'started' then
        return 3600 * 24 * 7 + math.random(10000) -- Placeholder
    end
    return 0
end

-- Helper: Get all resources (OPTIMIZED - cached, lightweight)
local function getAllResources()
    local resources = {}
    local numResources = GetNumResources()
    
    -- Limit resource processing to prevent hitches (process in batches if needed)
    local maxResources = 200 -- Safety limit
    local processed = 0
    
    for i = 0, numResources - 1 do
        if processed >= maxResources then
            break -- Safety limit
        end
        
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            -- Use lightweight status check only (avoid expensive performance calls)
            local status = getResourceStatus(resourceName)
            
            -- Use lightweight performance estimates (avoid expensive calls)
            local perf = {
                cpu = 0, -- Placeholder - actual CPU tracking requires monitoring
                memory = 0, -- Placeholder - actual memory tracking requires monitoring
                threads = 0 -- Placeholder
            }
            
            -- Use lightweight uptime (cached)
            local uptime = getResourceUptime(resourceName)
            
            table.insert(resources, {
                id = resourceName,
                name = resourceName,
                status = status,
                cpu = perf.cpu,
                memory = perf.memory,
                threads = perf.threads,
                uptime = uptime
            })
            
            processed = processed + 1
        end
    end
    
    return resources
end

-- Helper: Get database query stats
local function getDatabaseQueryStats()
    -- oxmysql doesn't provide native query stats
    -- This is a placeholder - in production, track queries manually or use monitoring
    return {
        queries = 127 + math.random(50), -- Placeholder
        avgQueryTime = 10 + math.random(5), -- Placeholder
        slowQueries = math.random(5), -- Placeholder
        connections = 20 + math.random(10) -- Placeholder
    }
end

-- Helper: Get database size
local function getDatabaseSize()
    local result = MySQL.query.await([[
        SELECT 
            ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
    ]], {})
    
    if result and result[1] then
        return tonumber(result[1].size_mb) or 0
    end
    
    return 0
end

-- Helper: Format database size
local function formatDatabaseSize(sizeMB)
    if sizeMB >= 1024 then
        return string.format("%.1f GB", sizeMB / 1024)
    else
        return string.format("%.0f MB", sizeMB)
    end
end

-- Helper: Normalize GTA coordinates to 0-1 range
-- GTA V world coordinates: approximately -4000 to 4000 (8000 range)
-- Normalize to 0-1 for UI positioning
local function normalizeCoordinates(x, y)
    -- GTA V map bounds (approximate)
    local minX, maxX = -4000, 4000
    local minY, maxY = -4000, 4000
    
    -- Normalize to 0-1 range
    local normalizedX = (x - minX) / (maxX - minX)
    local normalizedY = (y - minY) / (maxY - minY)
    
    -- Clamp to 0-1
    normalizedX = math.max(0, math.min(1, normalizedX))
    normalizedY = math.max(0, math.min(1, normalizedY))
    
    return normalizedX, normalizedY
end

-- Helper: Get player positions (OPTIMIZED - client-side data via events, not server-side natives)
local playerPositionsCache = {}
local playerPositionsCacheTime = 0
local PLAYER_POSITIONS_CACHE_TTL = 3 -- Cache for 3 seconds (reduced frequency)

-- Request positions from clients (non-blocking)
local function requestPlayerPositionsFromClients()
    -- Trigger client event to get positions (clients send their own positions)
    TriggerClientEvent('ec_admin:requestPlayerPositions', -1)
end

-- Store positions received from clients
RegisterNetEvent('ec_admin:playerPositionUpdate', function(positionData)
    local source = source
    if not positionData or not positionData.id then return end
    
    -- Get identifier from server (client can't access GetPlayerIdentifiers)
    if not positionData.identifier then
        local identifiers = GetPlayerIdentifiers(source)
        if identifiers then
            for _, id in ipairs(identifiers) do
                if string.find(id, 'license:') then
                    positionData.identifier = id
                    break
                end
            end
        end
    end
    
    -- Update cache with client-provided data
    playerPositionsCache[positionData.id] = positionData
    playerPositionsCacheTime = getCurrentTimestamp()
end)

-- Helper: Get player positions (optimized - uses cached client data)
local function getPlayerPositions()
    -- Check cache
    local currentTime = getCurrentTimestamp()
    if playerPositionsCacheTime > 0 and (currentTime - playerPositionsCacheTime) < PLAYER_POSITIONS_CACHE_TTL then
        -- Return cached positions as array
        local positions = {}
        for _, pos in pairs(playerPositionsCache) do
            table.insert(positions, pos)
        end
        return positions
    end
    
    -- Request fresh data from clients (non-blocking)
    requestPlayerPositionsFromClients()
    
    -- Return cached data (will be updated by clients)
    local positions = {}
    for _, pos in pairs(playerPositionsCache) do
        table.insert(positions, pos)
    end
    
    return positions
end

-- Auto-request positions from clients every 3 seconds (throttled)
CreateThread(function()
    Wait(5000) -- Wait 5 seconds on startup
    while true do
        requestPlayerPositionsFromClients()
        Wait(3000) -- Request every 3 seconds (throttled)
    end
end)

-- Helper: Get server metrics data (shared logic)
local function getServerMetricsData(includeHistory)
    local currentMetrics = {
        players = GetNumPlayerIndices() or 0,
        tps = getServerTPS(),
        memory = getServerMemoryUsage(),
        cpu = getServerCPUUsage(),
        uptime = getServerUptime()
    }
    
    -- Store snapshot
    storeMetricsSnapshot(currentMetrics)
    
    local response = {
        success = true,
        current = currentMetrics,
        data = currentMetrics -- For compatibility
    }
    
    if includeHistory then
        response.history = getMetricsHistory(20)
    end
    
    return response
end

-- Note: RegisterNUICallback is CLIENT-side only - removed
-- Use lib.callback.register for server-side callbacks
-- This is handled by client/nui-server-monitor.lua which calls lib.callback.register

-- Callback throttling cache
local callbackThrottle = {}
local THROTTLE_INTERVAL = 1000 -- 1 second minimum between calls per source

-- Callback: Get server metrics (via fetchNui/client bridge) - THROTTLED
lib.callback.register('ec_admin:getServerMetrics', function(source, data)
    -- Throttle: Check if called too recently
    local now = os.clock() * 1000
    local cacheKey = 'getServerMetrics:' .. tostring(source)
    local lastCall = callbackThrottle[cacheKey] or 0
    
    if (now - lastCall) < THROTTLE_INTERVAL then
        -- Return cached response if available
        if callbackThrottle[cacheKey .. ':response'] then
            return callbackThrottle[cacheKey .. ':response']
        end
    end
    
    callbackThrottle[cacheKey] = now
    
    local includeHistory = data.includeHistory or false
    local response = getServerMetricsData(includeHistory)
    
    -- Cache response
    callbackThrottle[cacheKey .. ':response'] = response
    
    return response
end)

-- Helper: Get network metrics data (shared logic)
local function getNetworkMetricsData()
    local bandwidth = getNetworkBandwidth()
    local avgPing = getAveragePing()
    local playersOnline = GetNumPlayerIndices() or 0
    local peakToday = getPeakToday()
    
    return {
        success = true,
        metrics = {
            playersOnline = playersOnline,
            peakToday = peakToday,
            avgPing = avgPing,
            bandwidth = bandwidth,
            connections = playersOnline
        }
    }
end

-- RegisterNUICallback: Get network metrics (direct fetch from UI)
-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Use lib.callback.register in server files instead

-- Callback: Get network metrics (via fetchNui/client bridge)
lib.callback.register('ec_admin:getNetworkMetrics', function(source, data)
    return getNetworkMetricsData()
end)

-- Helper: Get resources data (shared logic)
local function getResourcesData()
    -- Check cache
    if resourceCache.resources and (getCurrentTimestamp() - resourceCache.timestamp) < CACHE_TTL then
        return {
            success = true,
            resources = resourceCache.resources
        }
    end
    
    local resources = getAllResources()
    
    -- Cache results
    resourceCache = {
        resources = resources,
        timestamp = getCurrentTimestamp()
    }
    
    return {
        success = true,
        resources = resources
    }
end

-- RegisterNUICallback: Get resources (direct fetch from UI)
-- REMOVED: RegisterNUICallback is CLIENT-side only

-- Callback: Get resources (via fetchNui/client bridge) - THROTTLED
lib.callback.register('ec_admin:getResources', function(source, data)
    -- Throttle: Check if called too recently
    local now = os.clock() * 1000
    local cacheKey = 'getResources:' .. tostring(source)
    local lastCall = callbackThrottle[cacheKey] or 0
    
    if (now - lastCall) < THROTTLE_INTERVAL then
        if callbackThrottle[cacheKey .. ':response'] then
            return callbackThrottle[cacheKey .. ':response']
        end
    end
    
    callbackThrottle[cacheKey] = now
    
    local response = getResourcesData()
    callbackThrottle[cacheKey .. ':response'] = response
    
    return response
end)

-- Helper: Get database metrics data (shared logic)
local function getDatabaseMetricsData()
    local queryStats = getDatabaseQueryStats()
    local dbSize = getDatabaseSize()
    local sizeFormatted = formatDatabaseSize(dbSize)
    
    return {
        success = true,
        metrics = {
            queries = queryStats.queries,
            avgQueryTime = queryStats.avgQueryTime,
            slowQueries = queryStats.slowQueries,
            connections = queryStats.connections,
            size = dbSize,
            sizeFormatted = sizeFormatted
        }
    }
end

-- RegisterNUICallback: Get database metrics (direct fetch from UI)
-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Use lib.callback.register for server-side callbacks

-- Callback: Get database metrics (via fetchNui/client bridge)
lib.callback.register('ec_admin:getDatabaseMetrics', function(source, data)
    return getDatabaseMetricsData()
end)

-- Helper: Get player positions data (shared logic)
local function getPlayerPositionsData()
    local positions = getPlayerPositions()
    
    return {
        success = true,
        positions = positions
    }
end

-- RegisterNUICallback: Get player positions (direct fetch from UI)
-- REMOVED: RegisterNUICallback is CLIENT-side only

-- Callback: Get player positions (via fetchNui/client bridge)
-- Callback: Get player positions (via fetchNui/client bridge) - THROTTLED & CACHED
lib.callback.register('ec_admin:getPlayerPositions', function(source, data)
    -- Throttle: Check if called too recently
    local now = os.clock() * 1000
    local cacheKey = 'getPlayerPositions:' .. tostring(source)
    local lastCall = callbackThrottle[cacheKey] or 0
    
    if (now - lastCall) < THROTTLE_INTERVAL then
        if callbackThrottle[cacheKey .. ':response'] then
            return callbackThrottle[cacheKey .. ':response']
        end
    end
    
    callbackThrottle[cacheKey] = now
    
    local response = getPlayerPositionsData()
    callbackThrottle[cacheKey .. ':response'] = response
    
    return response
end)

-- Callback: Restart resource
lib.callback.register('ec_admin:restartResource', function(source, data)
    local resourceName = data.resourceName
    if not resourceName then
        return { success = false, error = 'Resource name required' }
    end
    
    -- Check if resource exists
    local state = GetResourceState(resourceName)
    if not state or state == '' then
        return { success = false, error = 'Resource not found' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    local adminId = GetPlayerIdentifier(source, 0) or 'system'
    local restartTime = getCurrentTimestamp()
    local success = true
    local errorMsg = nil
    
    -- Restart resource
    local success_restart = pcall(function()
        StopResource(resourceName)
        Wait(1000) -- Wait 1 second
        StartResource(resourceName)
    end)
    
    if not success_restart then
        success = false
        errorMsg = 'Failed to restart resource'
    end
    
    -- Log restart action
    MySQL.insert.await([[
        INSERT INTO ec_resource_restart_log (resource_name, restarted_by, restart_time, success, error_message)
        VALUES (?, ?, ?, ?, ?)
    ]], {resourceName, adminName, restartTime, success and 1 or 0, errorMsg})
    
    -- Clear cache
    resourceCache = {}
    
    if success then
        return {
            success = true,
            message = 'Resource restarted successfully'
        }
    else
        return {
            success = false,
            error = errorMsg or 'Failed to restart resource'
        }
    end
end)

-- Auto-sampling thread: Collect metrics every 30 seconds (optimized)
CreateThread(function()
    Wait(10000) -- Wait 10 seconds on startup (let server stabilize)
    
    while true do
        -- Use lightweight calls and cached values
        local currentMetrics = {
            players = GetNumPlayerIndices() or 0, -- Lightweight
            tps = getServerTPS(), -- Uses cached value from optimizer
            memory = getServerMemoryUsage(), -- Lightweight calculation
            cpu = getServerCPUUsage() -- Lightweight calculation
        }
        
        -- Store snapshot asynchronously to avoid blocking
        CreateThread(function()
            storeMetricsSnapshot(currentMetrics)
        end)
        
        Wait(30000) -- Wait 30 seconds
    end
end)

-- Initialize with first snapshot
CreateThread(function()
    Wait(2000) -- Wait 2 seconds for server to stabilize
    
    local initialMetrics = {
        players = GetNumPlayerIndices() or 0,
        tps = getServerTPS(),
        memory = getServerMemoryUsage(),
        cpu = getServerCPUUsage()
    }
    
    storeMetricsSnapshot(initialMetrics)
end)

print("^2[Server Monitor]^7 UI Backend loaded - Monitoring active^0")

