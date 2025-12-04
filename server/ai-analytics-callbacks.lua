--[[
    EC Admin Ultimate - AI Analytics System
    Advanced analytics and reporting for AI/Bot detection patterns
    Real-time data collection, predictive modeling, and trend analysis
    Generated: December 4, 2025
    Enhanced: Real-time metrics, predictive models, chart generation
]]

Logger.Success('📊 Initializing AI Analytics System with Real-Time Metrics')

-- =============================================================================
-- ANALYTICS ENGINE - CORE STATE
-- =============================================================================

local AnalyticsEngine = {
    realTimeData = {},
    predictions = {},
    trends = {},
    chartCache = {},
    config = {
        trendWindow = 30,        -- 30-day trend analysis
        predictionWindow = 7,    -- 7-day forecast
        updateInterval = 60000,  -- Update every minute
        chartCacheTTL = 300000,  -- 5-minute cache for charts
        predictionEnabled = true,
        anomalyDetection = true
    },
    lastUpdate = 0,
    playerRiskCache = {}
}

-- =============================================================================
-- REAL-TIME DATA COLLECTION
-- =============================================================================

-- Collect real-time AI detection metrics
local function CollectRealtimeMetrics()
    local metrics = {
        timestamp = os.time(),
        activeDetections = 0,
        newDetectionsLast1h = 0,
        flaggedPlayers = 0,
        botConfidence = 0.0
    }
    
    -- Get current active detections
    local active = MySQL.Sync.fetchAll([[
        SELECT COUNT(*) as count FROM ec_ai_detections 
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    ]], {})
    
    if active and #active > 0 then
        metrics.newDetectionsLast1h = active[1].count or 0
    end
    
    -- Get flagged players count
    local flagged = MySQL.Sync.fetchAll([[
        SELECT COUNT(DISTINCT player_id) as count FROM ec_ai_player_patterns
        WHERE bot_probability >= 0.5
    ]], {})
    
    if flagged and #flagged > 0 then
        metrics.flaggedPlayers = flagged[1].count or 0
    end
    
    -- Get average confidence
    local confidence = MySQL.Sync.fetchAll([[
        SELECT AVG(bot_probability) as avg_conf FROM ec_ai_player_patterns
    ]], {})
    
    if confidence and #confidence > 0 then
        metrics.botConfidence = confidence[1].avg_conf or 0
    end
    
    AnalyticsEngine.realTimeData = metrics
    return metrics
end

-- Start continuous collection
CreateThread(function()
    while true do
        Wait(AnalyticsEngine.config.updateInterval)
        CollectRealtimeMetrics()
    end
end)

-- =============================================================================
-- TREND ANALYSIS
-- =============================================================================

-- Calculate detection trends
local function CalculateTrends()
    local trends = {
        detection_trend = 0,
        bot_probability_trend = 0,
        activity_trend = 0
    }
    
    -- 30-day detection trend
    local detectionTrend = MySQL.Sync.fetchAll([[
        SELECT 
            WEEK(created_at) as week,
            COUNT(*) as count
        FROM ec_ai_detections
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY WEEK(created_at)
        ORDER BY week DESC
        LIMIT 2
    ]], {})
    
    if detectionTrend and #detectionTrend >= 2 then
        local thisWeek = detectionTrend[1].count
        local lastWeek = detectionTrend[2].count
        if lastWeek > 0 then
            trends.detection_trend = ((thisWeek - lastWeek) / lastWeek) * 100
        end
    end
    
    -- Bot probability trend
    local probTrend = MySQL.Sync.fetchAll([[
        SELECT 
            DATE(created_at) as date,
            AVG(bot_probability) as avg_prob
        FROM ec_ai_player_patterns
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY DATE(created_at)
        ORDER BY date DESC
        LIMIT 2
    ]], {})
    
    if probTrend and #probTrend >= 2 then
        local thisDay = probTrend[1].avg_prob or 0
        local lastDay = probTrend[2].avg_prob or 0
        trends.bot_probability_trend = thisDay - lastDay
    end
    
    AnalyticsEngine.trends = trends
    return trends
end

-- =============================================================================
-- PREDICTIVE ANALYTICS
-- =============================================================================

-- Generate simple predictions based on trends
local function GeneratePredictions()
    local predictions = {
        expected_detections_next_week = 0,
        predicted_bot_risk = 0,
        confidence = 0.0
    }
    
    -- Get last 7 days of data
    local history = MySQL.Sync.fetchAll([[
        SELECT 
            DATE(created_at) as date,
            COUNT(*) as count
        FROM ec_ai_detections
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        GROUP BY DATE(created_at)
        ORDER BY date
    ]], {})
    
    if history and #history > 0 then
        -- Calculate moving average
        local sum = 0
        for _, day in ipairs(history) do
            sum = sum + day.count
        end
        local average = sum / #history
        
        -- Simple linear extrapolation
        predictions.expected_detections_next_week = math.ceil(average * 7)
        
        -- Estimate confidence (higher count = higher confidence)
        predictions.confidence = math.min((#history / 30) * 100, 95)
    end
    
    -- Predict bot risk
    local riskData = MySQL.Sync.fetchAll([[
        SELECT 
            CASE 
                WHEN bot_probability >= 0.75 THEN 'critical'
                WHEN bot_probability >= 0.5 THEN 'high'
                WHEN bot_probability >= 0.25 THEN 'medium'
                ELSE 'low'
            END as risk_level,
            COUNT(*) as count
        FROM ec_ai_player_patterns
        GROUP BY risk_level
    ]], {})
    
    local totalRisk = 0
    local totalPlayers = 0
    if riskData then
        for _, risk in ipairs(riskData) do
            if risk.risk_level == 'critical' then
                totalRisk = totalRisk + (risk.count * 4)
            elseif risk.risk_level == 'high' then
                totalRisk = totalRisk + (risk.count * 2)
            elseif risk.risk_level == 'medium' then
                totalRisk = totalRisk + (risk.count * 1)
            end
            totalPlayers = totalPlayers + risk.count
        end
    end
    
    if totalPlayers > 0 then
        predictions.predicted_bot_risk = (totalRisk / totalPlayers) * 100
    end
    
    AnalyticsEngine.predictions = predictions
    return predictions
end

-- =============================================================================
-- CHART DATA GENERATION
-- =============================================================================

-- Generate chart-ready data for detection trends
local function GenerateDetectionTrendChart()
    local chartData = {
        type = 'line',
        labels = {},
        datasets = {
            {
                label = 'Daily Detections',
                data = {},
                borderColor = '#FF6B6B',
                backgroundColor = 'rgba(255, 107, 107, 0.1)',
                tension = 0.4
            }
        }
    }
    
    local data = MySQL.Sync.fetchAll([[
        SELECT 
            DATE(created_at) as date,
            COUNT(*) as count
        FROM ec_ai_detections
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY DATE(created_at)
        ORDER BY date
    ]], {})
    
    if data then
        for _, row in ipairs(data) do
            table.insert(chartData.labels, row.date)
            table.insert(chartData.datasets[1].data, row.count)
        end
    end
    
    return chartData
end

-- Generate chart-ready data for bot probability distribution
local function GenerateBotProbabilityChart()
    local chartData = {
        type = 'pie',
        labels = { 'Low', 'Medium', 'High', 'Critical' },
        datasets = {
            {
                label = 'Player Risk Distribution',
                data = { 0, 0, 0, 0 },
                backgroundColor = {
                    '#4CAF50',  -- green for low
                    '#FFC107',  -- yellow for medium
                    '#FF9800',  -- orange for high
                    '#F44336'   -- red for critical
                }
            }
        }
    }
    
    local data = MySQL.Sync.fetchAll([[
        SELECT 
            CASE 
                WHEN bot_probability < 0.25 THEN 'Low'
                WHEN bot_probability < 0.50 THEN 'Medium'
                WHEN bot_probability < 0.75 THEN 'High'
                ELSE 'Critical'
            END as risk_level,
            COUNT(*) as count
        FROM ec_ai_player_patterns
        GROUP BY risk_level
    ]], {})
    
    if data then
        for _, row in ipairs(data) do
            if row.risk_level == 'Low' then
                chartData.datasets[1].data[1] = row.count
            elseif row.risk_level == 'Medium' then
                chartData.datasets[1].data[2] = row.count
            elseif row.risk_level == 'High' then
                chartData.datasets[1].data[3] = row.count
            elseif row.risk_level == 'Critical' then
                chartData.datasets[1].data[4] = row.count
            end
        end
    end
    
    return chartData
end

-- Generate chart-ready data for detection types
local function GenerateDetectionTypeChart()
    local chartData = {
        type = 'bar',
        labels = {},
        datasets = {
            {
                label = 'Detections by Type',
                data = {},
                backgroundColor = '#2196F3'
            }
        }
    }
    
    local data = MySQL.Sync.fetchAll([[
        SELECT 
            detection_type,
            COUNT(*) as count
        FROM ec_ai_detections
        GROUP BY detection_type
        ORDER BY count DESC
        LIMIT 10
    ]], {})
    
    if data then
        for _, row in ipairs(data) do
            table.insert(chartData.labels, row.detection_type)
            table.insert(chartData.datasets[1].data, row.count)
        end
    end
    
    return chartData
end

-- =============================================================================
-- CLIENT EVENTS
-- =============================================================================

-- Get AI analytics data with real-time metrics
-- =============================================================================
-- REAL-TIME METRICS COLLECTION
-- =============================================================================

local function CollectRealtimeMetrics()
    local metrics = {
        timestamp = os.time(),
        activeDetections = 0,
        newDetectionsLast1h = 0,
        flaggedPlayers = 0,
        botConfidence = 0.0,
        detectionRate = 0.0,
        avgProcessingTime = 0.0
    }
    
    -- Get detections in last hour
    local active = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM ec_ai_detections WHERE created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)', {})
    metrics.newDetectionsLast1h = active or 0
    
    -- Get flagged players
    local flagged = MySQL.Sync.fetchScalar('SELECT COUNT(DISTINCT player_id) FROM ec_ai_player_patterns WHERE bot_probability >= 0.5', {})
    metrics.flaggedPlayers = flagged or 0
    
    -- Get average bot confidence
    local confidence = MySQL.Sync.fetchScalar('SELECT AVG(bot_probability) FROM ec_ai_player_patterns', {})
    metrics.botConfidence = confidence or 0.0
    
    AnalyticsEngine.realTimeData = metrics
    return metrics
end

-- Start continuous collection thread
CreateThread(function()
    while true do
        Wait(AnalyticsEngine.config.updateInterval)
        CollectRealtimeMetrics()
        AnalyticsEngine.lastUpdate = os.time()
    end
end)

-- =============================================================================
-- PREDICTION ENGINE
-- =============================================================================

local function GeneratePredictions()
    local predictions = {
        expected_detections_next_week = 0,
        predicted_bot_risk = 0.0,
        confidence = 0.0,
        trend_direction = 'stable',
        recommendations = {}
    }
    
    -- Get last 7 days detection data
    local history = MySQL.Sync.fetchAll([[
        SELECT 
            DATE(created_at) as date,
            COUNT(*) as count,
            AVG(bot_probability) as avg_prob
        FROM ec_ai_detections
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        GROUP BY DATE(created_at)
        ORDER BY date
    ]], {})
    
    if history and #history > 1 then
        -- Calculate trend
        local firstWeekCount = 0
        for i = 1, math.floor(#history / 2) do
            firstWeekCount = firstWeekCount + history[i].count
        end
        
        local secondWeekCount = 0
        for i = math.floor(#history / 2) + 1, #history do
            secondWeekCount = secondWeekCount + history[i].count
        end
        
        -- Predict using linear extrapolation
        local sum = 0
        for _, day in ipairs(history) do
            sum = sum + day.count
        end
        local average = sum / #history
        predictions.expected_detections_next_week = math.ceil(average * 7)
        
        -- Determine trend direction
        if secondWeekCount > firstWeekCount * 1.1 then
            predictions.trend_direction = 'increasing'
            table.insert(predictions.recommendations, '⚠️ Detection rate increasing - heightened alert')
        elseif secondWeekCount < firstWeekCount * 0.9 then
            predictions.trend_direction = 'decreasing'
            table.insert(predictions.recommendations, '✅ Detection rate decreasing - good sign')
        end
        
        predictions.confidence = math.min((#history / 7) * 100, 95)
    end
    
    -- Predict bot risk based on player patterns
    local riskData = MySQL.Sync.fetchAll([[
        SELECT 
            CASE 
                WHEN bot_probability >= 0.75 THEN 'critical'
                WHEN bot_probability >= 0.5 THEN 'high'
                WHEN bot_probability >= 0.25 THEN 'medium'
                ELSE 'low'
            END as risk_level,
            COUNT(*) as count,
            AVG(bot_probability) as avg_prob
        FROM ec_ai_player_patterns
        GROUP BY risk_level
    ]], {})
    
    local totalRisk = 0
    local totalPlayers = 0
    if riskData then
        for _, risk in ipairs(riskData) do
            if risk.risk_level == 'critical' then
                totalRisk = totalRisk + (risk.count * 4)
            elseif risk.risk_level == 'high' then
                totalRisk = totalRisk + (risk.count * 2)
            elseif risk.risk_level == 'medium' then
                totalRisk = totalRisk + (risk.count * 1)
            end
            totalPlayers = totalPlayers + risk.count
        end
    end
    
    if totalPlayers > 0 then
        predictions.predicted_bot_risk = (totalRisk / totalPlayers) * 100
        if predictions.predicted_bot_risk > 30 then
            table.insert(predictions.recommendations, '🚨 Elevated bot risk - recommended to boost monitoring')
        end
    end
    
    AnalyticsEngine.predictions = predictions
    return predictions
end

-- =============================================================================
-- CHART DATA GENERATION
-- =============================================================================

local function GenerateDetectionTrendChart()
    local chartData = {
        type = 'line',
        labels = {},
        datasets = {
            {
                label = 'Daily Detections',
                data = {},
                borderColor = '#FF6B6B',
                backgroundColor = 'rgba(255, 107, 107, 0.1)',
                tension = 0.4,
                fill = true
            }
        }
    }
    
    local data = MySQL.Sync.fetchAll([[
        SELECT 
            DATE(created_at) as date,
            COUNT(*) as count
        FROM ec_ai_detections
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY DATE(created_at)
        ORDER BY date
    ]], {})
    
    if data then
        for _, row in ipairs(data) do
            table.insert(chartData.labels, row.date)
            table.insert(chartData.datasets[1].data, row.count)
        end
    end
    
    return chartData
end

local function GenerateBotProbabilityChart()
    local chartData = {
        type = 'doughnut',
        labels = { 'Low', 'Medium', 'High', 'Critical' },
        datasets = {
            {
                label = 'Player Risk Distribution',
                data = { 0, 0, 0, 0 },
                backgroundColor = {
                    '#4CAF50',  -- green
                    '#FFC107',  -- yellow
                    '#FF9800',  -- orange
                    '#F44336'   -- red
                }
            }
        }
    }
    
    local data = MySQL.Sync.fetchAll([[
        SELECT 
            CASE 
                WHEN bot_probability < 0.25 THEN 'Low'
                WHEN bot_probability < 0.50 THEN 'Medium'
                WHEN bot_probability < 0.75 THEN 'High'
                ELSE 'Critical'
            END as risk_level,
            COUNT(*) as count
        FROM ec_ai_player_patterns
        GROUP BY risk_level
    ]], {})
    
    if data then
        for _, row in ipairs(data) do
            if row.risk_level == 'Low' then
                chartData.datasets[1].data[1] = row.count
            elseif row.risk_level == 'Medium' then
                chartData.datasets[1].data[2] = row.count
            elseif row.risk_level == 'High' then
                chartData.datasets[1].data[3] = row.count
            elseif row.risk_level == 'Critical' then
                chartData.datasets[1].data[4] = row.count
            end
        end
    end
    
    return chartData
end

local function GenerateDetectionTypeChart()
    local chartData = {
        type = 'bar',
        labels = {},
        datasets = {
            {
                label = 'Detections by Type',
                data = {},
                backgroundColor = '#2196F3'
            }
        }
    }
    
    local data = MySQL.Sync.fetchAll([[
        SELECT
            detection_type,
            COUNT(*) as count
        FROM ec_ai_detections
        GROUP BY detection_type
        ORDER BY count DESC
        LIMIT 10
    ]], {})
    
    if data then
        for _, row in ipairs(data) do
            table.insert(chartData.labels, row.detection_type)
            table.insert(chartData.datasets[1].data, row.count)
        end
    end
    
    return chartData
end

-- =============================================================================
-- CLIENT EVENTS
-- =============================================================================

RegisterNetEvent('ec_admin_ultimate:server:getAIAnalytics', function()
    local src = source
    
    -- Ensure real-time data is collected
    CollectRealtimeMetrics()
    
    local analytics = {
        status = 'success',
        timestamp = os.time(),
        realtime = AnalyticsEngine.realTimeData,
        trends = CalculateTrends(),
        predictions = GeneratePredictions(),
        
        -- Detection trends
        detectionTrends = MySQL.Sync.fetchAll([[
            SELECT 
                DATE(created_at) as date,
                COUNT(*) as count,
                AVG(bot_probability) as avg_confidence
            FROM ec_ai_detections
            WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
            GROUP BY DATE(created_at)
            ORDER BY date DESC
        ]], {}),
        
        -- Risk distribution
        riskDistribution = MySQL.Sync.fetchAll([[
            SELECT
                CASE 
                    WHEN bot_probability >= 0.75 THEN 'Critical'
                    WHEN bot_probability >= 0.50 THEN 'High'
                    WHEN bot_probability >= 0.25 THEN 'Medium'
                    ELSE 'Low'
                END as risk_level,
                COUNT(*) as count
            FROM ec_ai_player_patterns
            GROUP BY risk_level
        ]], {}),
        
        -- Top suspicious players
        topSuspicious = MySQL.Sync.fetchAll([[
            SELECT 
                player_id,
                player_name,
                ROUND(bot_probability, 3) as bot_probability,
                total_interactions,
                last_flagged_at,
                flag_count
            FROM ec_ai_player_patterns
            ORDER BY bot_probability DESC
            LIMIT 20
        ]], {}),
        
        -- Detection types
        detectionTypes = MySQL.Sync.fetchAll([[
            SELECT
                detection_type,
                COUNT(*) as count,
                ROUND(AVG(bot_probability), 3) as avg_confidence
            FROM ec_ai_detections
            GROUP BY detection_type
            ORDER BY count DESC
        ]], {}),
        
        -- Hourly activity
        hourlyActivity = MySQL.Sync.fetchAll([[
            SELECT 
                HOUR(created_at) as hour,
                COUNT(*) as detection_count,
                AVG(bot_probability) as avg_probability
            FROM ec_ai_detections
            WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
            GROUP BY HOUR(created_at)
            ORDER BY hour
        ]], {}),
        
        -- Chart data
        charts = {
            detectionTrend = GenerateDetectionTrendChart(),
            botProbability = GenerateBotProbabilityChart(),
            detectionType = GenerateDetectionTypeChart()
        }
    }
    
    TriggerClientEvent('ec_admin_ultimate:client:updateAIAnalytics', src, analytics)
end)
-- Calculate trends for analysis
local function CalculateTrends()
    local trends = {
        detection_trend = 0,
        bot_probability_trend = 0,
        activity_trend = 0,
        week_over_week = 0
    }
    
    -- Week over week trend
    local weekTrend = MySQL.Sync.fetchAll([[
        SELECT 
            WEEK(created_at) as week,
            COUNT(*) as count
        FROM ec_ai_detections
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 14 DAY)
        GROUP BY WEEK(created_at)
        ORDER BY week DESC
        LIMIT 2
    ]], {})
    
    if weekTrend and #weekTrend >= 2 then
        local thisWeek = weekTrend[1].count
        local lastWeek = weekTrend[2].count
        if lastWeek > 0 then
            trends.week_over_week = ((thisWeek - lastWeek) / lastWeek) * 100
        end
    end
    
    return trends
end

-- Request detailed player analysis
RegisterNetEvent('ec_admin_ultimate:server:getPlayerAIAnalysis', function(playerId)
    local src = source
    
    local playerData = MySQL.Sync.fetchAll([[
        SELECT
            player_id,
            player_name,
            bot_probability,
            total_interactions,
            flag_count,
            last_flagged_at
        FROM ec_ai_player_patterns
        WHERE player_id = ?
    ]], { playerId })
    
    if playerData and #playerData > 0 then
        local player = playerData[1]
        
        -- Get recent detections for this player
        player.recent_detections = MySQL.Sync.fetchAll([[
            SELECT
                detection_type,
                bot_probability,
                created_at
            FROM ec_ai_detections
            WHERE player_id = ?
            ORDER BY created_at DESC
            LIMIT 20
        ]], { playerId })
        
        TriggerClientEvent('ec_admin_ultimate:client:playerAIAnalysisData', src, player)
    end
end)

-- Get prediction data
RegisterNetEvent('ec_admin_ultimate:server:getAIPredictions', function()
    local src = source
    local predictions = GeneratePredictions()
    TriggerClientEvent('ec_admin_ultimate:client:updateAIPredictions', src, predictions)
end)

-- Get specific chart data
RegisterNetEvent('ec_admin_ultimate:server:getAIChartData', function(chartType)
    local src = source
    local chartData = nil
    
    if chartType == 'detection_trend' then
        chartData = GenerateDetectionTrendChart()
    elseif chartType == 'bot_probability' then
        chartData = GenerateBotProbabilityChart()
    elseif chartType == 'detection_type' then
        chartData = GenerateDetectionTypeChart()
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:chartDataUpdate', src, {
        type = chartType,
        data = chartData
    })
end)

-- Generate custom report
RegisterNetEvent('ec_admin_ultimate:server:generateCustomAIReport', function(reportType)
    local src = source
    local admin = GetPlayerName(src)
    
    local report = {
        type = reportType,
        generated_at = os.date('%Y-%m-%d %H:%M:%S'),
        generated_by = admin,
        data = {}
    }
    
    if reportType == 'daily' then
        report.data = MySQL.Sync.fetchAll([[
            SELECT
                DATE(created_at) as date,
                COUNT(*) as total_detections,
                COUNT(DISTINCT player_id) as unique_players,
                AVG(bot_probability) as avg_confidence,
                MAX(bot_probability) as max_confidence,
                MIN(bot_probability) as min_confidence
            FROM ec_ai_detections
            WHERE DATE(created_at) = CURDATE()
            GROUP BY DATE(created_at)
        ]], {})
        
    elseif reportType == 'weekly' then
        report.data = MySQL.Sync.fetchAll([[
            SELECT
                WEEK(created_at) as week,
                COUNT(*) as total_detections,
                COUNT(DISTINCT player_id) as unique_players,
                AVG(bot_probability) as avg_confidence
            FROM ec_ai_detections
            WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
            GROUP BY WEEK(created_at)
        ]], {})
        
    elseif reportType == 'monthly' then
        report.data = MySQL.Sync.fetchAll([[
            SELECT
                MONTH(created_at) as month,
                COUNT(*) as total_detections,
                COUNT(DISTINCT player_id) as unique_players,
                AVG(bot_probability) as avg_confidence
            FROM ec_ai_detections
            WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
            GROUP BY MONTH(created_at)
        ]], {})
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:customAIReport', src, report)
end)

Logger.Success('✅ AI Analytics System initialized successfully')
Logger.Info('Features: Real-time metrics | Predictions | Chart generation | Trend analysis')
Logger.Info('📊 System ready for monitoring and reporting')
