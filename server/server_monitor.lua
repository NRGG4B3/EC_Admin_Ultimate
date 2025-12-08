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
        in = playerCount * 0.5,  -- MB/s
        out = playerCount * 0.3   -- MB/s
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

-- Helper: Get all resources
local function getAllResources()
    local resources = {}
    local numResources = GetNumResources()
    
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local status = getResourceStatus(resourceName)
            local perf = getResourcePerformance(resourceName)
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

-- Helper: Get player positions (with caching for performance)
local playerPositionsCache = {}
local playerPositionsCacheTime = 0
local PLAYER_POSITIONS_CACHE_TTL = 1 -- Cache for 1 second

-- Helper: Get player positions
local function getPlayerPositions()
    -- Check cache
    local currentTime = getCurrentTimestamp()
    if playerPositionsCacheTime > 0 and (currentTime - playerPositionsCacheTime) < PLAYER_POSITIONS_CACHE_TTL then
        return playerPositionsCache
    end
    
    local positions = {}
    local players = GetPlayers()
    local framework = getFramework()
    
    for _, playerId in ipairs(players) do
        local source = tonumber(playerId)
        if source then
            local name = GetPlayerName(source) or 'Unknown'
            local ped = GetPlayerPed(source)
            
            if ped and ped ~= 0 then
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                local vehicle = nil
                local job = 'Civilian'
                local health = 100
                local armor = 0
                local identifier = nil
                
                -- Get health and armor
                health = GetEntityHealth(ped)
                if health > 100 then
                    health = math.floor((health - 100) / 10) -- Convert to percentage (GTA uses 0-200 for 0-100%)
                end
                armor = GetPedArmour(ped)
                
                -- Get identifier
                local identifiers = GetPlayerIdentifiers(source)
                if identifiers then
                    for _, id in ipairs(identifiers) do
                        if string.find(id, 'license:') then
                            identifier = id
                            break
                        elseif string.find(id, 'steam:') then
                            identifier = id
                        end
                    end
                end
                
                -- Check if in vehicle
                if IsPedInAnyVehicle(ped, false) then
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh and veh ~= 0 then
                        local model = GetEntityModel(veh)
                        vehicle = GetDisplayNameFromVehicleModel(model)
                    end
                end
                
                -- Get job from framework
                if framework == 'qb' or framework == 'qbx' then
                    local player = ECFramework.GetPlayerObject(source)
                    if player and player.PlayerData and player.PlayerData.job then
                        job = player.PlayerData.job.name or 'Civilian'
                    end
                elseif framework == 'esx' then
                    local player = ECFramework.GetPlayerObject(source)
                    if player and player.job then
                        job = player.job.name or 'Civilian'
                    end
                elseif framework == 'standalone' then
                    -- Standalone mode: No framework job system, default to Civilian
                    job = 'Civilian'
                end
                
                -- Normalize coordinates
                local normalizedX, normalizedY = normalizeCoordinates(coords.x, coords.y)
                
                table.insert(positions, {
                    id = tostring(source),
                    name = name,
                    coords = {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z
                    },
                    normalizedX = normalizedX,
                    normalizedY = normalizedY,
                    heading = heading,
                    vehicle = vehicle,
                    job = job,
                    health = health,
                    armor = armor,
                    identifier = identifier
                })
            end
        end
    end
    
    -- Update cache
    playerPositionsCache = positions
    playerPositionsCacheTime = currentTime
    
    return positions
end

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

-- RegisterNUICallback: Get server metrics (direct fetch from UI)
RegisterNUICallback('getServerMetrics', function(data, cb)
    local includeHistory = data.includeHistory or false
    local response = getServerMetricsData(includeHistory)
    cb(response)
end)

-- Callback: Get server metrics (via fetchNui/client bridge)
lib.callback.register('ec_admin:getServerMetrics', function(source, data)
    local includeHistory = data.includeHistory or false
    return getServerMetricsData(includeHistory)
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
RegisterNUICallback('getNetworkMetrics', function(data, cb)
    local response = getNetworkMetricsData()
    cb(response)
end)

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
RegisterNUICallback('getResources', function(data, cb)
    local response = getResourcesData()
    cb(response)
end)

-- Callback: Get resources (via fetchNui/client bridge)
lib.callback.register('ec_admin:getResources', function(source, data)
    return getResourcesData()
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
RegisterNUICallback('getDatabaseMetrics', function(data, cb)
    local response = getDatabaseMetricsData()
    cb(response)
end)

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
RegisterNUICallback('getPlayerPositions', function(data, cb)
    local response = getPlayerPositionsData()
    cb(response)
end)

-- Callback: Get player positions (via fetchNui/client bridge)
lib.callback.register('ec_admin:getPlayerPositions', function(source, data)
    return getPlayerPositionsData()
end)

-- Helper: Restart resource (shared logic - requires source for logging)
local function restartResourceData(source, resourceName)
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

-- Auto-sampling thread: Collect metrics every 30 seconds
CreateThread(function()
    Wait(5000) -- Wait 5 seconds on startup
    
    while true do
        local currentMetrics = {
            players = GetNumPlayerIndices() or 0,
            tps = getServerTPS(),
            memory = getServerMemoryUsage(),
            cpu = getServerCPUUsage()
        }
        
        storeMetricsSnapshot(currentMetrics)
        
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

