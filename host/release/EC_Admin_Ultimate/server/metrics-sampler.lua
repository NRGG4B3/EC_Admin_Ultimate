--[[
    EC Admin Ultimate - Metrics History Sampler
    Production-ready: Records server metrics snapshots every 60 seconds
    ✅ Keeps last 60 minutes in memory + database persistence for 30 days
]]

local MetricsDB = nil -- Will load after delay
local MetricsSampler = {
    history = {},
    maxHistory = 60, -- 60 minutes of data (memory)
    sampleInterval = 60000, -- 60 seconds
    startTime = os.time(),
    dbEnabled = false
}

-- Get current server metrics snapshot
local function GetMetricsSnapshot()
    local players = GetPlayers()
    local playerCount = #players
    
    -- Calculate average ping
    local totalPing = 0
    local maxPing = 0
    for _, playerId in ipairs(players) do
        local ping = GetPlayerPing(tonumber(playerId))
        totalPing = totalPing + ping
        if ping > maxPing then
            maxPing = ping
        end
    end
    local avgPing = playerCount > 0 and math.floor(totalPing / playerCount) or 0
    
    -- Get resource count
    local resourceCount = 0
    local totalResources = GetNumResources()
    for i = 0, totalResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName and GetResourceState(resourceName) == 'started' then
            resourceCount = resourceCount + 1
        end
    end
    
    -- Memory usage in MB
    local memoryUsage = collectgarbage('count') / 1024
    
    -- Create snapshot
    local snapshot = {
        time = os.time(),
        timeFormatted = os.date('%H:%M:%S', os.time()),
        players = playerCount,
        maxPlayers = GetConvarInt('sv_maxclients', 64),
        tps = 60, -- FiveM default server tick rate
        memory = math.floor(memoryUsage * 100) / 100, -- Round to 2 decimals
        cpu = 0, -- Placeholder - would need native support
        avgPing = avgPing,
        maxPing = maxPing,
        resources = {
            total = totalResources,
            started = resourceCount
        }
    }
    
    return snapshot
end

-- Add snapshot to history (memory + database)
local function AddToHistory(snapshot)
    -- Memory storage (fast access for recent data)
    table.insert(MetricsSampler.history, snapshot)
    
    -- Trim history to max size
    if #MetricsSampler.history > MetricsSampler.maxHistory then
        table.remove(MetricsSampler.history, 1)
    end
    
    -- ✅ Database persistence (production-ready)
    if MetricsSampler.dbEnabled and MetricsDB then
        MetricsDB.SaveSnapshot(snapshot)
    end
end

-- Get full history (memory for recent, database for historical)
function GetMetricsHistory(hours)
    -- If no hours specified or <=1 hour, return memory cache (faster)
    if not hours or hours <= 1 then
        return {
            success = true,
            source = 'memory',
            history = MetricsSampler.history,
            count = #MetricsSampler.history,
            maxHistory = MetricsSampler.maxHistory,
            uptime = os.time() - MetricsSampler.startTime
        }
    end
    
    -- For longer periods, fetch from database
    if MetricsSampler.dbEnabled and MetricsDB then
        local dbResult = MetricsDB.GetHistory(hours)
        if dbResult.success then
            dbResult.source = 'database'
            dbResult.uptime = os.time() - MetricsSampler.startTime
            return dbResult
        end
    end
    
    -- Fallback to memory
    return {
        success = true,
        source = 'memory_fallback',
        history = MetricsSampler.history,
        count = #MetricsSampler.history,
        uptime = os.time() - MetricsSampler.startTime
    }
end

-- Get current metrics (latest snapshot)
function GetCurrentMetrics()
    local snapshot = GetMetricsSnapshot()
    return {
        success = true,
        metrics = snapshot,
        uptime = os.time() - MetricsSampler.startTime
    }
end

-- Export globally for HTTP router
_G.GetMetricsHistory = GetMetricsHistory
_G.GetCurrentMetrics = GetCurrentMetrics

-- Load database module after delay
CreateThread(function()
    Wait(5000) -- Wait for MySQL
    
    local success, module = pcall(require, 'server.metrics-database')
    if success and module then
        MetricsDB = module
        MetricsSampler.dbEnabled = true
        Logger.Success('[Metrics Sampler] Database persistence enabled', '✅')
    else
        Logger.Warn('[Metrics Sampler] Running in memory-only mode (database not available)', '⚠️')
    end
end)

-- Sampler thread - runs every 60 seconds
CreateThread(function()
    -- Take initial snapshot immediately
    local initialSnapshot = GetMetricsSnapshot()
    AddToHistory(initialSnapshot)
    Logger.Success('✅ Initial metrics snapshot recorded', '📊')
    
    while true do
        Wait(MetricsSampler.sampleInterval)
        
        -- Take snapshot
        local startTime = GetGameTimer()
        local snapshot = GetMetricsSnapshot()
        AddToHistory(snapshot)
        local elapsed = GetGameTimer() - startTime
        
        -- Log sampling (only if it takes too long)
        if elapsed > 5 then
            Logger.Warn(string.format('[Metrics Sampler] Snapshot took %dms (warning: slow)', elapsed), '⚠️')
        end
    end
end)

-- Cleanup old history periodically (every 5 minutes)
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        
        -- Remove entries older than maxHistory
        local cutoffTime = os.time() - (MetricsSampler.maxHistory * 60)
        local removed = 0
        
        for i = #MetricsSampler.history, 1, -1 do
            if MetricsSampler.history[i].time < cutoffTime then
                table.remove(MetricsSampler.history, i)
                removed = removed + 1
            end
        end
        
        if removed > 0 then
            Logger.Debug(string.format('[Metrics Sampler] Cleaned up %d old history entries', removed))
        end
    end
end)

Logger.Success('[Metrics Sampler] Initialized', '📊')
Logger.Info(string.format('  Sample interval: %ds', MetricsSampler.sampleInterval / 1000))
Logger.Info(string.format('  Max history: %d snapshots (%d minutes)', MetricsSampler.maxHistory, MetricsSampler.maxHistory))
