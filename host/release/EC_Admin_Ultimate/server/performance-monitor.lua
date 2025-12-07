--[[
    EC Admin Ultimate - Performance Monitoring System
    Real-time server performance tracking with historical data, trend analysis, and bottleneck detection
    Generated: December 4, 2025
]]

Logger.Success('📊 Initializing Performance Monitoring System')

-- =============================================================================
-- PERFORMANCE DATA STRUCTURE
-- =============================================================================

local PerfMon = {
    history = {},
    maxHistory = 300, -- 5 minutes at 1 sample/sec
    alerts = {},
    thresholds = {
        cpu = 80,           -- Warn if CPU > 80%
        memory = 85,        -- Warn if memory > 85%
        playerCount = 120,  -- Warn if players > 120
        resourceCount = 150, -- Warn if resources > 150
        eventQueue = 100000, -- Warn if event queue backing up
        packetsPerSec = 50000
    },
    config = {
        sampleInterval = 1000,  -- 1 second
        enableHistorical = true,
        enableAnomalyDetection = true,
        enableBottleneckDetection = true
    }
}

-- Create performance metrics table if needed
local function EnsureMetricsTable()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `ec_performance_metrics` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `server_time` BIGINT,
            `player_count` INT,
            `fps` INT,
            `ping_avg` INT,
            `ping_max` INT,
            `cpu_usage` DECIMAL(5,2),
            `memory_usage` DECIMAL(5,2),
            `resource_count` INT,
            `running_resources` INT,
            `event_queue_size` INT,
            `gc_collections` INT,
            `network_packets_in` INT,
            `network_packets_out` INT,
            INDEX idx_timestamp (timestamp)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]], {})
    
    Logger.Success('✅ Performance metrics table verified')
end

EnsureMetricsTable()

-- =============================================================================
-- SAMPLE COLLECTION
-- =============================================================================

-- Sample current performance metrics
local function CollectMetrics()
    local sample = {
        timestamp = os.time(),
        serverTime = GetGameTimer(),
        playerCount = #GetPlayers(),
        resourceCount = GetNumResources(),
        runningResources = 0,
        stoppedResources = 0
    }
    
    -- Count resources
    for i = 0, sample.resourceCount - 1 do
        local state = GetResourceState(GetResourceByFindIndex(i))
        if state == 'started' then
            sample.runningResources = sample.runningResources + 1
        else
            sample.stoppedResources = sample.stoppedResources + 1
        end
    end
    
    -- Calculate player metrics
    if sample.playerCount > 0 then
        local totalPing = 0
        local maxPing = 0
        
        for _, playerId in ipairs(GetPlayers()) do
            local ping = GetPlayerPing(playerId)
            totalPing = totalPing + ping
            if ping > maxPing then
                maxPing = ping
            end
        end
        
        sample.avgPing = math.floor(totalPing / sample.playerCount)
        sample.maxPing = maxPing
    else
        sample.avgPing = 0
        sample.maxPing = 0
    end
    
    -- Store in history
    table.insert(PerfMon.history, sample)
    
    -- Maintain history size
    if #PerfMon.history > PerfMon.maxHistory then
        table.remove(PerfMon.history, 1)
    end
    
    return sample
end

-- Start continuous monitoring
CreateThread(function()
    while true do
        Wait(PerfMon.config.sampleInterval)
        local sample = CollectMetrics()
        
        -- Store in database (async)
        if PerfMon.config.enableHistorical then
            MySQL.Async.execute([[
                INSERT INTO ec_performance_metrics 
                (server_time, player_count, resource_count, running_resources, event_queue_size)
                VALUES (@time, @players, @resources, @running, @queue)
            ]], {
                ['@time'] = sample.serverTime,
                ['@players'] = sample.playerCount,
                ['@resources'] = sample.resourceCount,
                ['@running'] = sample.runningResources,
                ['@queue'] = 0 -- FiveM doesn't expose this directly
            })
        end
        
        -- Check thresholds and create alerts
        CheckThresholds(sample)
    end
end)

-- =============================================================================
-- THRESHOLD CHECKING & ALERTS
-- =============================================================================

local function CheckThresholds(sample)
    -- Check player count
    if sample.playerCount >= PerfMon.thresholds.playerCount then
        CreateAlert('high_player_count', 
            string.format('High player count: %d/%d', sample.playerCount, PerfMon.thresholds.playerCount),
            'warning',
            sample)
    end
    
    -- Check resource count
    if sample.resourceCount >= PerfMon.thresholds.resourceCount then
        CreateAlert('high_resource_count',
            string.format('High resource count: %d/%d', sample.resourceCount, PerfMon.thresholds.resourceCount),
            'warning',
            sample)
    end
    
    -- Check average ping
    if sample.avgPing > 150 then
        CreateAlert('high_avg_ping',
            string.format('High average ping: %dms', sample.avgPing),
            'warning',
            sample)
    end
    
    -- Check max ping
    if sample.maxPing > 300 then
        CreateAlert('high_max_ping',
            string.format('High max ping: %dms', sample.maxPing),
            'error',
            sample)
    end
    
    -- Check for anomalies
    if PerfMon.config.enableAnomalyDetection then
        DetectAnomalies(sample)
    end
end

local function CreateAlert(alertType, message, severity, sample)
    local alert = {
        type = alertType,
        message = message,
        severity = severity,
        timestamp = os.time(),
        sample = sample
    }
    
    -- Store alert
    table.insert(PerfMon.alerts, alert)
    if #PerfMon.alerts > 100 then
        table.remove(PerfMon.alerts, 1)
    end
    
    -- Log it
    if severity == 'error' then
        Logger.Error('📊 Performance Alert: ' .. message)
    elseif severity == 'warning' then
        Logger.Warn('📊 Performance Alert: ' .. message)
    else
        Logger.Info('📊 Performance Alert: ' .. message)
    end
    
    -- Notify online admins
    BroadcastAlert(alert)
end

local function BroadcastAlert(alert)
    TriggerClientEvent('ec_admin:performanceAlert', -1, alert)
end

-- =============================================================================
-- ANOMALY DETECTION
-- =============================================================================

local function DetectAnomalies(sample)
    if #PerfMon.history < 10 then return end -- Need baseline
    
    -- Calculate average of last 10 samples
    local recentAvg = {
        playerCount = 0,
        avgPing = 0
    }
    
    local recent = 10
    local start = math.max(1, #PerfMon.history - recent + 1)
    
    for i = start, #PerfMon.history do
        local s = PerfMon.history[i]
        recentAvg.playerCount = recentAvg.playerCount + s.playerCount
        recentAvg.avgPing = recentAvg.avgPing + (s.avgPing or 0)
    end
    
    recentAvg.playerCount = recentAvg.playerCount / recent
    recentAvg.avgPing = recentAvg.avgPing / recent
    
    -- Check for sudden changes (anomalies)
    local playerDelta = math.abs(sample.playerCount - recentAvg.playerCount)
    local pingDelta = math.abs((sample.avgPing or 0) - recentAvg.avgPing)
    
    -- If player count jumped by more than 10 players
    if playerDelta > 10 then
        CreateAlert('player_count_spike',
            string.format('Player count spike: %d (average: %.0f)', sample.playerCount, recentAvg.playerCount),
            'info',
            sample)
    end
    
    -- If ping jumped by more than 50ms
    if pingDelta > 50 then
        CreateAlert('ping_spike',
            string.format('Ping spike: %dms (average: %.0f)', sample.avgPing or 0, recentAvg.avgPing),
            'warning',
            sample)
    end
end

-- =============================================================================
-- BOTTLENECK DETECTION
-- =============================================================================

local function DetectBottlenecks()
    if #PerfMon.history < 20 then return {} end
    
    local bottlenecks = {}
    
    -- Analyze trends
    local start = math.max(1, #PerfMon.history - 20)
    local pingTrend = CalculateTrend('avgPing', start)
    local playerTrend = CalculateTrend('playerCount', start)
    
    -- If ping is steadily increasing
    if pingTrend > 0.5 then
        table.insert(bottlenecks, {
            type = 'increasing_latency',
            severity = 'warning',
            description = 'Ping trending upward - potential network bottleneck',
            trend = pingTrend
        })
    end
    
    -- If too many resources
    local avgResources = 0
    for _, sample in ipairs(PerfMon.history) do
        avgResources = avgResources + sample.resourceCount
    end
    avgResources = avgResources / #PerfMon.history
    
    if avgResources > 100 then
        table.insert(bottlenecks, {
            type = 'high_resource_count',
            severity = 'warning',
            description = 'Too many resources loaded - consider disabling unused resources',
            count = avgResources
        })
    end
    
    -- If ping is consistently high
    local highPingCount = 0
    for _, sample in ipairs(PerfMon.history) do
        if (sample.avgPing or 0) > 100 then
            highPingCount = highPingCount + 1
        end
    end
    
    if highPingCount / #PerfMon.history > 0.7 then
        table.insert(bottlenecks, {
            type = 'consistent_high_latency',
            severity = 'error',
            description = 'Consistently high latency - network issues',
            percentage = (highPingCount / #PerfMon.history) * 100
        })
    end
    
    return bottlenecks
end

-- Calculate trend of a metric (positive = increasing)
local function CalculateTrend(metric, startIndex)
    local firstValue = PerfMon.history[startIndex][metric] or 0
    local lastValue = PerfMon.history[#PerfMon.history][metric] or 0
    
    if firstValue == 0 then return 0 end
    
    return (lastValue - firstValue) / firstValue
end

-- =============================================================================
-- STATISTICS CALCULATION
-- =============================================================================

local function CalculateStats(metric, samples)
    samples = samples or 60 -- Last 60 samples (1 minute)
    
    local values = {}
    local start = math.max(1, #PerfMon.history - samples + 1)
    
    for i = start, #PerfMon.history do
        local val = PerfMon.history[i][metric]
        if val then
            table.insert(values, val)
        end
    end
    
    if #values == 0 then
        return { avg = 0, min = 0, max = 0, current = 0 }
    end
    
    -- Calculate stats
    local sum = 0
    local min = values[1]
    local max = values[1]
    
    for _, val in ipairs(values) do
        sum = sum + val
        if val < min then min = val end
        if val > max then max = val end
    end
    
    return {
        avg = math.floor(sum / #values),
        min = min,
        max = max,
        current = values[#values],
        samples = #values
    }
end

-- =============================================================================
-- CLIENT EVENTS
-- =============================================================================

-- Get current performance status
RegisterNetEvent('ec_admin:getPerformanceStatus', function()
    local src = source
    
    if #PerfMon.history == 0 then
        TriggerClientEvent('ec_admin:receivePerformanceStatus', src, {
            success = false,
            message = 'No data collected yet'
        })
        return
    end
    
    local current = PerfMon.history[#PerfMon.history]
    
    TriggerClientEvent('ec_admin:receivePerformanceStatus', src, {
        success = true,
        data = {
            current = current,
            playerStats = CalculateStats('playerCount'),
            pingStats = CalculateStats('avgPing'),
            resourceStats = CalculateStats('resourceCount'),
            alerts = #PerfMon.alerts,
            thresholds = PerfMon.thresholds
        }
    })
end)

-- Get performance history
RegisterNetEvent('ec_admin:getPerformanceHistory', function()
    local src = source
    
    TriggerClientEvent('ec_admin:receivePerformanceHistory', src, {
        success = true,
        data = PerfMon.history,
        count = #PerfMon.history
    })
end)

-- Get alerts
RegisterNetEvent('ec_admin:getPerformanceAlerts', function()
    local src = source
    
    TriggerClientEvent('ec_admin:receivePerformanceAlerts', src, {
        success = true,
        alerts = PerfMon.alerts,
        count = #PerfMon.alerts
    })
end)

-- Get bottlenecks
RegisterNetEvent('ec_admin:detectBottlenecks', function()
    local src = source
    
    local bottlenecks = DetectBottlenecks()
    
    TriggerClientEvent('ec_admin:receiveBottlenecks', src, {
        success = true,
        bottlenecks = bottlenecks,
        count = #bottlenecks
    })
end)

-- Update thresholds
RegisterNetEvent('ec_admin:updatePerformanceThresholds', function(newThresholds)
    local src = source
    
    for key, value in pairs(newThresholds) do
        if PerfMon.thresholds[key] ~= nil then
            PerfMon.thresholds[key] = value
        end
    end
    
    Logger.Info(string.format('Updated performance thresholds by admin %s', GetPlayerName(src)))
    
    TriggerClientEvent('ec_admin:actionSuccess', src, {
        message = 'Thresholds updated'
    })
end)

-- Get recommendations
RegisterNetEvent('ec_admin:getPerformanceRecommendations', function()
    local src = source
    
    local recommendations = {}
    local bottlenecks = DetectBottlenecks()
    
    for _, bn in ipairs(bottlenecks) do
        if bn.type == 'increasing_latency' then
            table.insert(recommendations, 'Consider checking network stability and player connections')
        elseif bn.type == 'high_resource_count' then
            table.insert(recommendations, 'Review and disable unnecessary resources to free up server resources')
        elseif bn.type == 'consistent_high_latency' then
            table.insert(recommendations, 'Network issues detected - check ISP or VPS network quality')
        end
    end
    
    -- Player-based recommendations
    local playerStats = CalculateStats('playerCount')
    if playerStats.current > 100 then
        table.insert(recommendations, 'Server approaching capacity - consider implementing queue system')
    end
    
    TriggerClientEvent('ec_admin:receiveRecommendations', src, {
        success = true,
        recommendations = recommendations
    })
end)

-- Export performance data
RegisterNetEvent('ec_admin:exportPerformanceData', function(data)
    local src = source
    local format = data and data.format or 'json'
    
    if format == 'json' then
        TriggerClientEvent('ec_admin:receiveExport', src, {
            success = true,
            format = 'json',
            filename = 'perf_' .. os.date('%Y%m%d_%H%M%S') .. '.json',
            data = json.encode({
                history = PerfMon.history,
                alerts = PerfMon.alerts
            })
        })
    elseif format == 'csv' then
        local csv = 'Time,Players,AvgPing,MaxPing,Resources\n'
        for _, sample in ipairs(PerfMon.history) do
            csv = csv .. string.format('%d,%d,%d,%d,%d\n',
                sample.timestamp,
                sample.playerCount,
                sample.avgPing or 0,
                sample.maxPing or 0,
                sample.resourceCount
            )
        end
        
        TriggerClientEvent('ec_admin:receiveExport', src, {
            success = true,
            format = 'csv',
            filename = 'perf_' .. os.date('%Y%m%d_%H%M%S') .. '.csv',
            data = csv
        })
    end
end)

Logger.Success('✅ Performance Monitoring System loaded')

