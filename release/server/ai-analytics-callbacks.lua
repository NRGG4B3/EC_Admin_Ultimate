--[[
    EC Admin Ultimate - AI Analytics System
    Advanced analytics and reporting for AI/Bot detection patterns
]]

-- Get AI analytics data
RegisterNetEvent('ec_admin_ultimate:server:getAIAnalytics', function()
    local src = source
    
    -- Get detection trends (last 30 days)
    local detectionTrends = MySQL.Sync.fetchAll([[
        SELECT 
            DATE(created_at) as date,
            COUNT(*) as count,
            detection_type,
            AVG(confidence) as avg_confidence
        FROM ec_ai_detections
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY DATE(created_at), detection_type
        ORDER BY date DESC
    ]], {})
    
    -- Get player risk distribution
    local riskDistribution = MySQL.Sync.fetchAll([[
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
    
    -- Get top suspicious players
    local topSuspicious = MySQL.Sync.fetchAll([[
        SELECT 
            p.*,
            COUNT(d.id) as detection_count
        FROM ec_ai_player_patterns p
        LEFT JOIN ec_ai_detections d ON p.player_id = d.player_id
        WHERE p.bot_probability >= 0.5
        GROUP BY p.player_id
        ORDER BY p.bot_probability DESC, detection_count DESC
        LIMIT 20
    ]], {})
    
    -- Get detection type breakdown
    local detectionTypes = MySQL.Sync.fetchAll([[
        SELECT 
            detection_type,
            COUNT(*) as count,
            AVG(confidence) as avg_confidence,
            SUM(CASE WHEN is_bot = 1 THEN 1 ELSE 0 END) as confirmed_bots
        FROM ec_ai_detections
        GROUP BY detection_type
        ORDER BY count DESC
    ]], {})
    
    -- Get hourly activity patterns (detect farming times)
    local hourlyActivity = MySQL.Sync.fetchAll([[
        SELECT 
            HOUR(timestamp) as hour,
            COUNT(*) as action_count,
            COUNT(DISTINCT player_id) as unique_players
        FROM ec_ai_behavior_logs
        WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        GROUP BY HOUR(timestamp)
        ORDER BY hour
    ]], {})
    
    -- Get bot detection accuracy (if admin reviewed)
    local accuracy = MySQL.Sync.fetchAll([[
        SELECT 
            COUNT(*) as total_reviewed,
            SUM(CASE WHEN is_bot = 1 THEN 1 ELSE 0 END) as confirmed_bots,
            AVG(CASE WHEN is_bot = 1 THEN confidence ELSE 0 END) as true_positive_confidence,
            AVG(CASE WHEN is_bot = 0 THEN confidence ELSE 0 END) as false_positive_confidence
        FROM ec_ai_detections
        WHERE admin_reviewed = 1
    ]], {})
    
    -- Calculate advanced stats
    local stats = {
        totalAnalyzed = 0,
        confirmedBots = 0,
        falsePositives = 0,
        accuracy = 0.0,
        avgDetectionTime = 0.0,
        mostCommonPattern = 'none',
        peakActivityHour = 0,
        automatedKicks = 0
    }
    
    if accuracy and #accuracy > 0 and accuracy[1].total_reviewed > 0 then
        stats.totalAnalyzed = accuracy[1].total_reviewed
        stats.confirmedBots = accuracy[1].confirmed_bots
        stats.falsePositives = stats.totalAnalyzed - stats.confirmedBots
        stats.accuracy = (stats.confirmedBots / stats.totalAnalyzed) * 100
    end
    
    -- Find most common detection type
    if detectionTypes and #detectionTypes > 0 then
        stats.mostCommonPattern = detectionTypes[1].detection_type
    end
    
    -- Find peak activity hour
    local maxActions = 0
    for _, hour in ipairs(hourlyActivity) do
        if hour.action_count > maxActions then
            maxActions = hour.action_count
            stats.peakActivityHour = hour.hour
        end
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:receiveAIAnalytics', src, {
        success = true,
        data = {
            detectionTrends = detectionTrends,
            riskDistribution = riskDistribution,
            topSuspicious = topSuspicious,
            detectionTypes = detectionTypes,
            hourlyActivity = hourlyActivity,
            stats = stats
        }
    })
end)

-- Export report
RegisterNetEvent('ec_admin_ultimate:server:exportAIReport', function(data)
    local src = source
    local reportType = data.reportType or 'full'
    
    -- Generate comprehensive report
    local report = {
        generated_at = os.date('%Y-%m-%d %H:%M:%S'),
        report_type = reportType,
        summary = {},
        detections = {},
        patterns = {},
        recommendations = {}
    }
    
    -- Get summary data
    local summaryData = MySQL.Sync.fetchAll([[
        SELECT 
            COUNT(DISTINCT d.player_id) as total_players_flagged,
            COUNT(d.id) as total_detections,
            SUM(CASE WHEN d.is_bot = 1 THEN 1 ELSE 0 END) as confirmed_bots,
            AVG(d.confidence) as avg_confidence,
            AVG(p.bot_probability) as avg_bot_probability
        FROM ec_ai_detections d
        LEFT JOIN ec_ai_player_patterns p ON d.player_id = p.player_id
        WHERE d.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    ]], {})
    
    if summaryData and #summaryData > 0 then
        report.summary = summaryData[1]
    end
    
    -- Get top detections
    report.detections = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_ai_detections
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        ORDER BY confidence DESC
        LIMIT 100
    ]], {})
    
    -- Get patterns
    report.patterns = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_ai_player_patterns
        ORDER BY bot_probability DESC
        LIMIT 50
    ]], {})
    
    -- Generate recommendations
    if report.summary.avg_bot_probability and report.summary.avg_bot_probability > 0.3 then
        table.insert(report.recommendations, 'High bot activity detected - consider increasing monitoring frequency')
    end
    
    if report.summary.confirmed_bots and report.summary.confirmed_bots > 10 then
        table.insert(report.recommendations, 'Multiple confirmed bots - review security measures')
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:aiReportGenerated', src, {
        success = true,
        report = report
    })
end)

Logger.Info('AI Analytics callbacks loaded')
