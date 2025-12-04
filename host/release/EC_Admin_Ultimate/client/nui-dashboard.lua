--[[
    EC Admin Ultimate - Dashboard NUI Callbacks (CLIENT)
    Handles all dashboard data requests
]]

Logger.Info('✅ Dashboard NUI callbacks registered (CLIENT)')

-- ============================================================================
-- REAL-TIME DASHBOARD ENGINE
-- ============================================================================

local DashboardEngine = {
    liveMetrics = {
        playersOnline = 0,
        playersIdle = 0,
        activePlayers = 0,
        vehiclesActive = 0,
        serverHealth = 100,
        networkHealth = 100,
        cpuUsage = 0,
        memoryUsage = 0,
        serverTPS = 60,
        scriptCount = 0,
        resourceCount = 0
    },
    alerts = {},
    chartData = {
        playerTrends = {},
        performanceTrends = {},
        activityTrends = {}
    },
    refreshIntervals = {
        metrics = 5000,      -- 5 seconds
        charts = 30000,      -- 30 seconds
        alerts = 10000       -- 10 seconds
    }
}

-- ============================================================================
-- METRICS HISTORY FOR PERCENTAGE CALCULATIONS
-- ============================================================================

local metricsHistory = {
    playersOnline = {},
    cachedVehicles = {},
    memoryUsage = {},
    serverTPS = {}
}

local function AddToHistory(metric, value)
    table.insert(metricsHistory[metric], value)
    -- Keep only last 60 entries (1 minute of history)
    if #metricsHistory[metric] > 60 then
        table.remove(metricsHistory[metric], 1)
    end
end

local function CalculatePercentageChange(metric, currentValue)
    local history = metricsHistory[metric]
    if #history < 10 then
        return 0 -- Not enough data
    end
    
    -- Compare current to average of last 10 values
    local sum = 0
    for i = math.max(1, #history - 10), #history do
        sum = sum + history[i]
    end
    local average = sum / math.min(10, #history)
    
    if average == 0 then return 0 end
    
    local change = ((currentValue - average) / average) * 100
    return math.floor(change)
end

local function GetHealthStatus(metric, value)
    if metric == 'serverTPS' then
        if value >= 58 then return 'Excellent'
        elseif value >= 50 then return 'Good'
        elseif value >= 40 then return 'Fair'
        elseif value >= 30 then return 'Poor'
        else return 'Critical' end
    elseif metric == 'memoryUsage' then
        if value < 500 then return 'Healthy'
        elseif value < 1000 then return 'Good'
        elseif value < 2000 then return 'Fair'
        elseif value < 4000 then return 'Poor'
        else return 'Critical' end
    end
    return 'Unknown'
end

-- ============================================================================
-- DASHBOARD METRICS
-- ============================================================================

-- Get server metrics (main dashboard data)
RegisterNUICallback('getServerMetrics', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getServerMetrics', false)
    end)
    
    if success and result and result.success then
        -- Add to history for percentage calculations
        AddToHistory('playersOnline', result.playersOnline or 0)
        AddToHistory('cachedVehicles', result.cachedVehicles or 0)
        AddToHistory('memoryUsage', result.memoryUsage or 0)
        AddToHistory('serverTPS', result.serverTPS or 0)
        
        -- Calculate percentage changes
        local playersChange = CalculatePercentageChange('playersOnline', result.playersOnline or 0)
        local vehiclesChange = CalculatePercentageChange('cachedVehicles', result.cachedVehicles or 0)
        
        -- Calculate health statuses
        local tpsStatus = GetHealthStatus('serverTPS', result.serverTPS or 0)
        local memoryStatus = GetHealthStatus('memoryUsage', result.memoryUsage or 0)
        
        -- Add calculated fields to response
        result.percentageChanges = {
            players = playersChange,
            vehicles = vehiclesChange
        }
        result.healthStatus = {
            tps = tpsStatus,
            memory = memoryStatus
        }
        
        cb(result)
    else
        -- Fallback metrics
        local players = GetActivePlayers()
        cb({
            success = true,
            playersOnline = #players,
            maxPlayers = GetConvarInt('sv_maxclients', 32),
            totalResources = 0,
            cachedVehicles = 0,
            serverTPS = 60.0,
            memoryUsage = 0,
            networkIn = 0,
            networkOut = 0,
            cpuUsage = 0,
            uptime = 0,
            lastRestart = 0,
            activeEvents = 0,
            database = {
                queries = 0,
                avgResponseTime = 0
            },
            openReports = 0,
            activeStaff = 1,
            percentageChanges = {
                players = 0,
                vehicles = 0
            },
            healthStatus = {
                tps = 'Good',
                memory = 'Healthy'
            }
        })
    end
end)

-- Get AI analytics
RegisterNUICallback('getAIAnalytics', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getAIAnalytics', false)
    end)
    
    if success and result then
        cb(result)
    else
        cb({
            success = true,
            data = {}
        })
    end
end)

-- Get economy stats
RegisterNUICallback('getEconomyStats', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getEconomyStats', false)
    end)
    
    if success and result then
        cb(result)
    else
        cb({
            success = true,
            data = {}
        })
    end
end)

-- Get performance metrics
RegisterNUICallback('getPerformanceMetrics', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getPerformanceMetrics', false)
    end)
    
    if success and result then
        cb(result)
    else
        cb({
            success = true,
            data = {}
        })
    end
end)

-- Get alerts
RegisterNUICallback('getAlerts', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getAlerts', false)
    end)
    
    if success and result then
        cb(result)
    else
        cb({
            success = true,
            data = {}
        })
    end
end)

-- Get metrics history (for charts)
RegisterNUICallback('getMetricsHistory', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getMetricsHistory', false, data.period or '24h')
    end)
    
    if success and result then
        cb(result)
    else
        -- Return empty history
        cb({
            success = true,
            data = {
                labels = {},
                datasets = {
                    players = {},
                    cpu = {},
                    memory = {}
                }
            }
        })
    end
end)

Logger.Info('✅ Dashboard callbacks initialized - All metrics ready')

-- ============================================================================
-- LIVE METRICS COLLECTION
-- ============================================================================

-- Update live metrics from server systems
local function UpdateLiveMetrics()
    TriggerServerEvent('ec_admin_ultimate:server:getLiveMetrics', function(metrics)
        if metrics then
            DashboardEngine.liveMetrics = metrics
            
            -- Add to chart history
            table.insert(DashboardEngine.chartData.playerTrends, {
                time = os.time(),
                value = metrics.playersOnline
            })
            table.insert(DashboardEngine.chartData.performanceTrends, {
                time = os.time(),
                value = metrics.serverTPS
            })
            table.insert(DashboardEngine.chartData.activityTrends, {
                time = os.time(),
                value = metrics.activePlayers
            })
            
            -- Keep only last 60 entries
            if #DashboardEngine.chartData.playerTrends > 60 then
                table.remove(DashboardEngine.chartData.playerTrends, 1)
            end
            if #DashboardEngine.chartData.performanceTrends > 60 then
                table.remove(DashboardEngine.chartData.performanceTrends, 1)
            end
            if #DashboardEngine.chartData.activityTrends > 60 then
                table.remove(DashboardEngine.chartData.activityTrends, 1)
            end
        end
    end)
end

-- Fetch and process alerts from all systems
local function UpdateAlerts()
    TriggerServerEvent('ec_admin_ultimate:server:getDashboardAlerts', function(alerts)
        if alerts then
            DashboardEngine.alerts = alerts
        end
    end)
end

-- Get real-time data from AI Analytics
local function GetAIAnalyticsData()
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getAIAnalyticsOverview', false)
    end)
    
    if success and result then
        return result
    end
    return {}
end

-- Get performance data
local function GetPerformanceData()
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getPerformanceOverview', false)
    end)
    
    if success and result then
        return result
    end
    return {}
end

-- Get anticheat data
local function GetAnticheatData()
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getAnticheatOverview', false)
    end)
    
    if success and result then
        return result
    end
    return {}
end

-- Compile comprehensive dashboard status
local function CompileDashboardStatus()
    return {
        timestamp = os.time(),
        metrics = DashboardEngine.liveMetrics,
        alerts = DashboardEngine.alerts,
        aiAnalytics = GetAIAnalyticsData(),
        performance = GetPerformanceData(),
        anticheat = GetAnticheatData(),
        chartData = DashboardEngine.chartData
    }
end

-- Generate alerts based on thresholds
local function GenerateDashboardAlerts()
    local alerts = {}
    
    -- Server TPS alert
    if DashboardEngine.liveMetrics.serverTPS < 40 then
        table.insert(alerts, {
            id = 'low_tps',
            type = 'warning',
            title = 'Low Server TPS',
            message = 'Server TPS dropped to ' .. DashboardEngine.liveMetrics.serverTPS,
            severity = DashboardEngine.liveMetrics.serverTPS < 20 and 'critical' or 'warning',
            timestamp = os.time()
        })
    end
    
    -- Memory usage alert
    if DashboardEngine.liveMetrics.memoryUsage > 80 then
        table.insert(alerts, {
            id = 'high_memory',
            type = 'warning',
            title = 'High Memory Usage',
            message = 'Server memory at ' .. DashboardEngine.liveMetrics.memoryUsage .. '%',
            severity = 'warning',
            timestamp = os.time()
        })
    end
    
    -- CPU usage alert
    if DashboardEngine.liveMetrics.cpuUsage > 75 then
        table.insert(alerts, {
            id = 'high_cpu',
            type = 'warning',
            title = 'High CPU Usage',
            message = 'CPU usage at ' .. DashboardEngine.liveMetrics.cpuUsage .. '%',
            severity = 'warning',
            timestamp = os.time()
        })
    end
    
    -- Network health alert
    if DashboardEngine.liveMetrics.networkHealth < 60 then
        table.insert(alerts, {
            id = 'network_health',
            type = 'error',
            title = 'Network Issues Detected',
            message = 'Network health: ' .. DashboardEngine.liveMetrics.networkHealth .. '%',
            severity = 'critical',
            timestamp = os.time()
        })
    end
    
    return alerts
end

-- ============================================================================
-- BACKGROUND UPDATE THREADS
-- ============================================================================

-- Refresh metrics every 5 seconds
CreateThread(function()
    while true do
        Wait(DashboardEngine.refreshIntervals.metrics)
        UpdateLiveMetrics()
    end
end)

-- Refresh alerts every 10 seconds
CreateThread(function()
    while true do
        Wait(DashboardEngine.refreshIntervals.alerts)
        DashboardEngine.alerts = GenerateDashboardAlerts()
    end
end)