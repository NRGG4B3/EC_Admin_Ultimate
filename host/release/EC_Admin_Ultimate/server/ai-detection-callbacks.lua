--[[
    EC Admin Ultimate - AI Detection System
    Advanced bot and AI behavior detection with pattern analysis
    Detections: Bots, Automated Scripts, Farming Bots, Movement Patterns, Repetitive Behavior
]]

local QBCore = nil
local ESX = nil
local Framework = 'unknown'

-- Initialize framework
CreateThread(function()
    Wait(1000)
    
    if GetResourceState('qbx_core') == 'started' then
        QBCore = exports.qbx_core -- QBX uses direct export
        Framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
    else
        Framework = 'standalone'
    end
    
    Logger.Info('AI Detection System Initialized: ' .. Framework)
end)

-- AI Detection tables are automatically created by auto-migrate-sql.lua
-- This ensures consistent schema for both customers and host mode
CreateThread(function()
    Wait(2000)
    Logger.Debug('AI Detection system ready - tables created by auto-migration system')
end)

-- Active monitoring
local PlayerBehavior = {}

-- AI Detection Configuration
local AIConfig = {
    -- Thresholds
    BotProbabilityThreshold = 0.75,      -- 75% confidence = bot
    FarmingScoreThreshold = 0.70,        -- 70% = farming bot
    RepetitionThreshold = 0.80,          -- 80% repetitive actions
    
    -- Reaction time (milliseconds)
    MinHumanReactionTime = 150,          -- Humans can't react faster
    MaxHumanReactionTime = 3000,         -- Too slow might be AFK/bot
    
    -- Movement patterns
    MinMovementEntropy = 0.3,            -- Too predictable = bot
    
    -- Chat patterns
    MinChatEntropy = 0.4,                -- Repetitive chat = bot
    
    -- Actions per minute
    MaxActionsPerMinute = 120,           -- Inhuman speed
    
    -- Auto actions
    AutoKickBots = true,
    AutoFlagSuspicious = true
}

-- Helper: Get player identifier
local function GetPlayerIdentifier(src)
    if Framework == 'qbx' then
        -- QBX uses direct exports
        local Player = exports.qbx_core:GetPlayer(src)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'qb-core' then
        -- QB-Core uses GetCoreObject
        local Player = QBCore.Functions.GetPlayer(src)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier or nil
    else
        return GetPlayerIdentifiers(src)[1] or nil
    end
end

-- Helper: Calculate entropy (randomness measure)
local function CalculateEntropy(data)
    if not data or #data < 2 then return 0.0 end
    
    local frequency = {}
    for _, value in ipairs(data) do
        frequency[value] = (frequency[value] or 0) + 1
    end
    
    local entropy = 0.0
    local total = #data
    
    for _, count in pairs(frequency) do
        local p = count / total
        entropy = entropy - (p * math.log(p) / math.log(2))
    end
    
    return entropy / math.log(#data) -- Normalized entropy
end

-- Helper: Analyze player behavior
local function AnalyzePlayerBehavior(playerId, playerName)
    -- Get recent behavior logs
    local logs = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_ai_behavior_logs 
        WHERE player_id = ? 
        AND timestamp > DATE_SUB(NOW(), INTERVAL 1 HOUR)
        ORDER BY timestamp DESC
    ]], {playerId})
    
    if not logs or #logs < 10 then
        return nil -- Not enough data
    end
    
    -- Extract patterns
    local actions = {}
    local reactionTimes = {}
    local movements = {}
    local chatMessages = {}
    
    for i, log in ipairs(logs) do
        table.insert(actions, log.action_type)
        
        if log.action_data then
            local data = json.decode(log.action_data)
            if data then
                if data.reactionTime then
                    table.insert(reactionTimes, data.reactionTime)
                end
                if data.movement then
                    table.insert(movements, data.movement)
                end
                if data.chat then
                    table.insert(chatMessages, data.chat)
                end
            end
        end
    end
    
    -- Calculate metrics
    local totalActions = #actions
    local uniqueActions = 0
    local actionCounts = {}
    
    for _, action in ipairs(actions) do
        if not actionCounts[action] then
            uniqueActions = uniqueActions + 1
            actionCounts[action] = 0
        end
        actionCounts[action] = actionCounts[action] + 1
    end
    
    local repetitionRate = 1.0 - (uniqueActions / totalActions)
    
    -- Calculate average reaction time
    local avgReactionTime = 0
    if #reactionTimes > 0 then
        local sum = 0
        for _, rt in ipairs(reactionTimes) do
            sum = sum + rt
        end
        avgReactionTime = sum / #reactionTimes
    end
    
    -- Calculate movement entropy
    local movementEntropy = CalculateEntropy(movements)
    
    -- Calculate chat entropy
    local chatEntropy = CalculateEntropy(chatMessages)
    
    -- Calculate actions per minute
    local timeRange = 60 -- 1 hour = 60 minutes
    local actionsPerMinute = totalActions / timeRange
    
    -- Calculate farming score
    local farmingScore = 0.0
    if repetitionRate > 0.5 and movementEntropy < 0.4 then
        farmingScore = (repetitionRate + (1.0 - movementEntropy)) / 2
    end
    
    -- Calculate bot probability using multiple factors
    local botProbability = 0.0
    local factors = 0
    
    -- Factor 1: Repetition rate
    if repetitionRate > AIConfig.RepetitionThreshold then
        botProbability = botProbability + repetitionRate
        factors = factors + 1
    end
    
    -- Factor 2: Reaction time
    if avgReactionTime < AIConfig.MinHumanReactionTime then
        botProbability = botProbability + 1.0
        factors = factors + 1
    end
    
    -- Factor 3: Movement entropy
    if movementEntropy < AIConfig.MinMovementEntropy then
        botProbability = botProbability + (1.0 - movementEntropy)
        factors = factors + 1
    end
    
    -- Factor 4: Actions per minute
    if actionsPerMinute > AIConfig.MaxActionsPerMinute then
        botProbability = botProbability + math.min(1.0, actionsPerMinute / AIConfig.MaxActionsPerMinute)
        factors = factors + 1
    end
    
    if factors > 0 then
        botProbability = botProbability / factors
    end
    
    -- Store pattern analysis
    MySQL.Async.execute([[
        INSERT INTO ec_ai_player_patterns 
        (player_id, player_name, total_actions, unique_actions, repetition_rate, avg_reaction_time, 
         movement_entropy, chat_entropy, farming_score, bot_probability, last_analysis)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE
            total_actions = ?,
            unique_actions = ?,
            repetition_rate = ?,
            avg_reaction_time = ?,
            movement_entropy = ?,
            chat_entropy = ?,
            farming_score = ?,
            bot_probability = ?,
            last_analysis = NOW()
    ]], {
        playerId, playerName, totalActions, uniqueActions, repetitionRate, avgReactionTime,
        movementEntropy, chatEntropy, farmingScore, botProbability,
        totalActions, uniqueActions, repetitionRate, avgReactionTime,
        movementEntropy, chatEntropy, farmingScore, botProbability
    })
    
    return {
        totalActions = totalActions,
        uniqueActions = uniqueActions,
        repetitionRate = repetitionRate,
        avgReactionTime = avgReactionTime,
        movementEntropy = movementEntropy,
        chatEntropy = chatEntropy,
        farmingScore = farmingScore,
        botProbability = botProbability
    }
end

-- Helper: Log detection
local function LogAIDetection(src, detectionType, confidence, patternData, behavioralScore)
    local playerId = GetPlayerIdentifier(src)
    local playerName = GetPlayerName(src)
    
    if not playerId then return end
    
    local autoFlagged = confidence >= AIConfig.BotProbabilityThreshold
    local isBot = confidence >= 0.90
    
    MySQL.Async.execute([[
        INSERT INTO ec_ai_detections 
        (player_id, player_name, detection_type, confidence, pattern_data, behavioral_score, auto_flagged, is_bot)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {playerId, playerName, detectionType, confidence, json.encode(patternData), behavioralScore, autoFlagged, isBot})
    
    -- Notify admins
    TriggerClientEvent('ec_admin_ultimate:client:aiDetectionAlert', -1, {
        playerId = src,
        playerName = playerName,
        detectionType = detectionType,
        confidence = confidence,
        isBot = isBot
    })
    
    -- Auto kick if high confidence bot
    if AIConfig.AutoKickBots and isBot then
        DropPlayer(src, '🤖 Automated behavior detected\nReason: Bot-like patterns identified\nConfidence: ' .. math.floor(confidence * 100) .. '%')
        Logger.Error(string.format('🤖 AUTO-KICKED BOT: %s (ID: %d) - Confidence: %.2f%%', playerName, src, confidence * 100))
    end
end

-- Get all AI detection data
lib.callback.register('ec_admin:getAIDetectionData', function(source, _)
    local src = source
    local detections = MySQL.Sync.fetchAll([[SELECT * FROM ec_ai_detections ORDER BY created_at DESC LIMIT 500]], {})
    local patterns = MySQL.Sync.fetchAll([[SELECT * FROM ec_ai_player_patterns ORDER BY bot_probability DESC LIMIT 200]], {})
    local stats = { totalDetections = #detections, confirmedBots = 0, suspiciousPlayers = 0, farmingBots = 0, avgBotProbability = 0.0, detectionsToday = 0, detectionsByType = {} }
    for _, detection in ipairs(detections) do
        if detection.is_bot == 1 then stats.confirmedBots = stats.confirmedBots + 1 end
        stats.detectionsByType[detection.detection_type] = (stats.detectionsByType[detection.detection_type] or 0) + 1
    end
    local botProbSum = 0
    for _, pattern in ipairs(patterns) do
        botProbSum = botProbSum + pattern.bot_probability
        if pattern.bot_probability >= 0.5 and pattern.bot_probability < 0.75 then stats.suspiciousPlayers = stats.suspiciousPlayers + 1 end
        if pattern.farming_score >= AIConfig.FarmingScoreThreshold then stats.farmingBots = stats.farmingBots + 1 end
    end
    if #patterns > 0 then stats.avgBotProbability = botProbSum / #patterns end
    local today = os.time() - (24 * 60 * 60)
    for _, detection in ipairs(detections) do
        local detTime = os.time({ year = tonumber(string.sub(detection.created_at, 1, 4)), month = tonumber(string.sub(detection.created_at, 6, 7)), day = tonumber(string.sub(detection.created_at, 9, 10)), hour = tonumber(string.sub(detection.created_at, 12, 13)), min = tonumber(string.sub(detection.created_at, 15, 16)), sec = tonumber(string.sub(detection.created_at, 18, 19)) })
        if detTime >= today then stats.detectionsToday = stats.detectionsToday + 1 end
    end
    return { success = true, data = { detections = detections, patterns = patterns, stats = stats, framework = Framework, config = AIConfig } }
end)

RegisterNetEvent('ec_admin_ultimate:server:getAIDetectionData', function()
    local src = source
    
    -- Get detections
    local detections = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_ai_detections 
        ORDER BY created_at DESC 
        LIMIT 500
    ]], {})
    
    -- Get player patterns
    local patterns = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_ai_player_patterns 
        ORDER BY bot_probability DESC 
        LIMIT 200
    ]], {})
    
    -- Calculate stats
    local stats = {
        totalDetections = #detections,
        confirmedBots = 0,
        suspiciousPlayers = 0,
        farmingBots = 0,
        avgBotProbability = 0.0,
        detectionsToday = 0,
        detectionsByType = {}
    }
    
    for _, detection in ipairs(detections) do
        if detection.is_bot == 1 then
            stats.confirmedBots = stats.confirmedBots + 1
        end
        
        stats.detectionsByType[detection.detection_type] = (stats.detectionsByType[detection.detection_type] or 0) + 1
    end
    
    local botProbSum = 0
    for _, pattern in ipairs(patterns) do
        botProbSum = botProbSum + pattern.bot_probability
        
        if pattern.bot_probability >= 0.5 and pattern.bot_probability < 0.75 then
            stats.suspiciousPlayers = stats.suspiciousPlayers + 1
        end
        
        if pattern.farming_score >= AIConfig.FarmingScoreThreshold then
            stats.farmingBots = stats.farmingBots + 1
        end
    end
    
    if #patterns > 0 then
        stats.avgBotProbability = botProbSum / #patterns
    end
    
    -- Count detections today
    local today = os.time() - (24 * 60 * 60)
    for _, detection in ipairs(detections) do
        local detTime = os.time({
            year = tonumber(string.sub(detection.created_at, 1, 4)),
            month = tonumber(string.sub(detection.created_at, 6, 7)),
            day = tonumber(string.sub(detection.created_at, 9, 10)),
            hour = tonumber(string.sub(detection.created_at, 12, 13)),
            min = tonumber(string.sub(detection.created_at, 15, 16)),
            sec = tonumber(string.sub(detection.created_at, 18, 19))
        })
        if detTime >= today then
            stats.detectionsToday = stats.detectionsToday + 1
        end
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:receiveAIDetectionData', src, {
        success = true,
        data = {
            detections = detections,
            patterns = patterns,
            stats = stats,
            framework = Framework,
            config = AIConfig
        }
    })
end)

-- Log player behavior
RegisterNetEvent('ec_admin_ultimate:server:logBehavior', function(data)
    local src = source
    local playerId = GetPlayerIdentifier(src)
    
    if not playerId or not data or not data.actionType then return end
    
    MySQL.Async.execute([[
        INSERT INTO ec_ai_behavior_logs (player_id, action_type, action_data)
        VALUES (?, ?, ?)
    ]], {playerId, data.actionType, json.encode(data.actionData or {})})
end)

-- Analyze player (manual trigger)
RegisterNetEvent('ec_admin_ultimate:server:analyzePlayer', function(data)
    local src = source
    local targetId = tonumber(data.targetId)
    
    if not targetId then
        TriggerClientEvent('ec_admin_ultimate:client:aiDetectionResponse', src, {
            success = false,
            message = 'Invalid player ID'
        })
        return
    end
    
    local targetIdentifier = GetPlayerIdentifier(targetId)
    local targetName = GetPlayerName(targetId)
    
    if not targetIdentifier then
        TriggerClientEvent('ec_admin_ultimate:client:aiDetectionResponse', src, {
            success = false,
            message = 'Player not found'
        })
        return
    end
    
    local analysis = AnalyzePlayerBehavior(targetIdentifier, targetName)
    
    if not analysis then
        TriggerClientEvent('ec_admin_ultimate:client:aiDetectionResponse', src, {
            success = false,
            message = 'Not enough data to analyze (minimum 10 actions required)'
        })
        return
    end
    
    -- Check for bot behavior
    if analysis.botProbability >= AIConfig.BotProbabilityThreshold then
        LogAIDetection(targetId, 'bot_behavior', analysis.botProbability, analysis, analysis.botProbability)
    elseif analysis.farmingScore >= AIConfig.FarmingScoreThreshold then
        LogAIDetection(targetId, 'farming_bot', analysis.farmingScore, analysis, analysis.farmingScore)
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:aiDetectionResponse', src, {
        success = true,
        message = 'Analysis complete',
        data = analysis
    })
end)

-- Mark as bot
RegisterNetEvent('ec_admin_ultimate:server:markAsBot', function(data)
    local src = source
    local playerId = data.playerId
    
    if not playerId then
        TriggerClientEvent('ec_admin_ultimate:client:aiDetectionResponse', src, {
            success = false,
            message = 'Invalid player ID'
        })
        return
    end
    
    MySQL.Async.execute('UPDATE ec_ai_detections SET is_bot = 1, admin_reviewed = 1 WHERE player_id = ?', {playerId})
    MySQL.Async.execute('UPDATE ec_ai_player_patterns SET bot_probability = 1.0 WHERE player_id = ?', {playerId})
    
    TriggerClientEvent('ec_admin_ultimate:client:aiDetectionResponse', src, {
        success = true,
        message = 'Marked as bot'
    })
end)

-- Clear bot flag
RegisterNetEvent('ec_admin_ultimate:server:clearBotFlag', function(data)
    local src = source
    local playerId = data.playerId
    
    if not playerId then
        TriggerClientEvent('ec_admin_ultimate:client:aiDetectionResponse', src, {
            success = false,
            message = 'Invalid player ID'
        })
        return
    end
    
    MySQL.Async.execute('UPDATE ec_ai_detections SET is_bot = 0, admin_reviewed = 1 WHERE player_id = ?', {playerId})
    MySQL.Async.execute('UPDATE ec_ai_player_patterns SET bot_probability = 0.0 WHERE player_id = ?', {playerId})
    
    TriggerClientEvent('ec_admin_ultimate:client:aiDetectionResponse', src, {
        success = true,
        message = 'Bot flag cleared'
    })
end)

-- =============================================================================
-- PREDICTION ENGINE - NEW
-- =============================================================================

local PredictionEngine = {
    historicalData = {},
    modelCache = {},
    patterns = {},
    anomalyScores = {}
}

-- Calculate trend prediction (machine learning inspired)
local function PredictBotProbability(playerId, historicalScores)
    if not historicalScores or #historicalScores < 3 then
        return 0.0  -- Not enough data
    end
    
    -- Linear regression on scores
    local n = #historicalScores
    local sumX = n * (n + 1) / 2
    local sumY = 0
    local sumXY = 0
    local sumX2 = n * (n + 1) * (2 * n + 1) / 6
    
    for i, score in ipairs(historicalScores) do
        sumY = sumY + score
        sumXY = sumXY + (i * score)
    end
    
    local slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
    local intercept = (sumY - slope * sumX) / n
    
    -- Predict next 3 points
    local predictions = {}
    for i = 1, 3 do
        local predicted = intercept + slope * (n + i)
        table.insert(predictions, math.max(0, math.min(1, predicted)))
    end
    
    -- Average prediction with confidence based on trend strength
    local avgPrediction = (predictions[1] + predictions[2] + predictions[3]) / 3
    local trendStrength = math.abs(slope)
    
    -- If trend is strong and increasing, confidence is high
    local confidence = math.min(1.0, trendStrength * 2)
    
    return avgPrediction, confidence, predictions
end

-- Pattern learning algorithm
local function LearnPattern(playerId, behaviors)
    if not behaviors or #behaviors < 5 then
        return nil
    end
    
    local pattern = {
        playerId = playerId,
        behaviors = behaviors,
        learningScore = 0.0,
        patternType = 'unknown'
    }
    
    -- Analyze behavior sequence
    local actionTypes = {}
    for _, behavior in ipairs(behaviors) do
        actionTypes[behavior.type] = (actionTypes[behavior.type] or 0) + 1
    end
    
    -- Find dominant pattern
    local maxCount = 0
    local dominantType = nil
    for actionType, count in pairs(actionTypes) do
        if count > maxCount then
            maxCount = count
            dominantType = actionType
        end
    end
    
    -- Calculate pattern consistency
    pattern.consistency = maxCount / #behaviors
    
    -- Identify pattern type
    if pattern.consistency > 0.8 then
        if dominantType == 'movement' then
            pattern.patternType = 'repetitive_movement'
        elseif dominantType == 'action' then
            pattern.patternType = 'repetitive_action'
        elseif dominantType == 'chat' then
            pattern.patternType = 'spam_pattern'
        end
    end
    
    -- Learning score (consistency = how well the pattern matches)
    pattern.learningScore = pattern.consistency
    
    PredictionEngine.patterns[playerId] = pattern
    return pattern
end

-- Anomaly detection using Z-score
local function DetectAnomaly(playerId, currentScore, historicalScores)
    if not historicalScores or #historicalScores < 5 then
        return 0.0  -- Not enough data
    end
    
    -- Calculate mean
    local sum = 0
    for _, score in ipairs(historicalScores) do
        sum = sum + score
    end
    local mean = sum / #historicalScores
    
    -- Calculate standard deviation
    local variance = 0
    for _, score in ipairs(historicalScores) do
        variance = variance + (score - mean) ^ 2
    end
    variance = variance / #historicalScores
    local stdDev = math.sqrt(variance)
    
    -- Handle edge case where std dev is 0
    if stdDev == 0 then
        return 0.0
    end
    
    -- Calculate Z-score
    local zScore = math.abs((currentScore - mean) / stdDev)
    
    -- Convert to anomaly score (0-1)
    local anomalyScore = math.min(1.0, zScore / 3)
    
    PredictionEngine.anomalyScores[playerId] = anomalyScore
    return anomalyScore
end

-- Advanced confidence scoring
local function CalculateConfidenceScore(analysis, predictions, anomalyScore)
    local baseConfidence = analysis.botProbability
    
    -- Factor in prediction strength
    local predictionConfidence = 0.0
    if predictions then
        local avgPred = (predictions[1] + predictions[2] + predictions[3]) / 3
        predictionConfidence = math.abs(predictions[3] - predictions[1]) / 2
    end
    
    -- Factor in anomaly score
    local anomalyConfidence = anomalyScore or 0.0
    
    -- Weighted combination
    local finalConfidence = (baseConfidence * 0.5) + (predictionConfidence * 0.3) + (anomalyConfidence * 0.2)
    
    return math.min(1.0, finalConfidence)
end

-- Advanced reporting for predictions
local function GenerateAdvancedReport(playerId, analysis, predictions, anomaly)
    local report = {
        playerId = playerId,
        timestamp = os.time(),
        baseScore = analysis.botProbability,
        predictions = predictions or {},
        anomalyScore = anomaly or 0.0,
        confidence = CalculateConfidenceScore(analysis, predictions, anomaly),
        recommendation = 'Monitor',
        factors = {}
    }
    
    -- Generate recommendations
    if report.baseScore >= 0.9 then
        report.recommendation = 'High Confidence Bot - KICK/BAN'
        table.insert(report.factors, '🚨 Very high bot probability')
    elseif report.baseScore >= 0.75 then
        report.recommendation = 'Likely Bot - Monitor closely'
        table.insert(report.factors, '⚠️ High bot probability')
    elseif report.baseScore >= 0.5 then
        report.recommendation = 'Suspicious - Investigate'
        table.insert(report.factors, '⚡ Moderate bot probability')
    else
        report.recommendation = 'Normal - Continue monitoring'
        table.insert(report.factors, '✅ Low bot probability')
    end
    
    -- Add prediction factors
    if predictions and #predictions > 0 then
        if predictions[3] > 0.8 then
            table.insert(report.factors, '📈 Trend indicates increasing bot probability')
        elseif predictions[3] < 0.3 then
            table.insert(report.factors, '📉 Trend indicates decreasing bot probability')
        end
    end
    
    -- Add anomaly factors
    if report.anomalyScore > 0.7 then
        table.insert(report.factors, '🔍 Unusual behavior detected')
    end
    
    return report
end

-- =============================================================================
-- ENHANCED CLIENT EVENTS
-- =============================================================================

-- Get advanced detection analysis with predictions
RegisterNetEvent('ec_admin_ultimate:server:getAdvancedAnalysis', function(playerId)
    local src = source
    local targetIdentifier = GetPlayerIdentifier(tonumber(playerId))
    
    if not targetIdentifier then
        TriggerClientEvent('ec_admin_ultimate:client:advancedAnalysisResponse', src, {
            success = false,
            message = 'Player not found'
        })
        return
    end
    
    local analysis = AnalyzePlayerBehavior(targetIdentifier, GetPlayerName(tonumber(playerId)))
    
    if not analysis then
        TriggerClientEvent('ec_admin_ultimate:client:advancedAnalysisResponse', src, {
            success = false,
            message = 'Insufficient data'
        })
        return
    end
    
    -- Get historical scores
    local historical = MySQL.Sync.fetchAll([[
        SELECT bot_probability FROM ec_ai_detections 
        WHERE player_id = ? 
        ORDER BY created_at DESC 
        LIMIT 20
    ]], { playerId })
    
    local historicalScores = {}
    if historical then
        for _, record in ipairs(historical) do
            table.insert(historicalScores, record.bot_probability)
        end
    end
    
    -- Generate predictions
    local predictions, confidence, trendPredictions = nil, 0.0, {}
    if #historicalScores > 2 then
        predictions, confidence, trendPredictions = PredictBotProbability(playerId, historicalScores)
    end
    
    -- Detect anomalies
    local anomalyScore = DetectAnomaly(playerId, analysis.botProbability, historicalScores)
    
    -- Learn pattern
    LearnPattern(playerId, analysis.actions or {})
    
    -- Generate report
    local report = GenerateAdvancedReport(playerId, analysis, trendPredictions, anomalyScore)
    
    -- Get pattern info
    local pattern = PredictionEngine.patterns[playerId]
    
    TriggerClientEvent('ec_admin_ultimate:client:advancedAnalysisResponse', src, {
        success = true,
        analysis = analysis,
        predictions = {
            nextScore = predictions,
            confidence = confidence,
            trendPredictions = trendPredictions,
            anomalyScore = anomalyScore
        },
        report = report,
        pattern = pattern,
        historical = historicalScores
    })
end)

-- Get trend predictions for multiple players
RegisterNetEvent('ec_admin_ultimate:server:getTrendPredictions', function()
    local src = source
    
    local predictions = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        local identifier = GetPlayerIdentifier(tonumber(playerId))
        if identifier then
            local historical = MySQL.Sync.fetchAll([[
                SELECT bot_probability FROM ec_ai_detections 
                WHERE player_id = ? 
                ORDER BY created_at DESC 
                LIMIT 20
            ]], { tonumber(playerId) })
            
            if historical and #historical > 2 then
                local scores = {}
                for _, record in ipairs(historical) do
                    table.insert(scores, record.bot_probability)
                end
                
                local prediction, confidence = PredictBotProbability(tonumber(playerId), scores)
                
                table.insert(predictions, {
                    playerId = tonumber(playerId),
                    playerName = GetPlayerName(tonumber(playerId)),
                    prediction = prediction,
                    confidence = confidence
                })
            end
        end
    end
    
    -- Sort by prediction
    table.sort(predictions, function(a, b)
        return a.prediction > b.prediction
    end)
    
    TriggerClientEvent('ec_admin_ultimate:client:trendPredictionsUpdate', src, predictions)
end)

-- Get pattern learning data
RegisterNetEvent('ec_admin_ultimate:server:getPatternAnalysis', function()
    local src = source
    
    local patterns = {}
    for playerId, pattern in pairs(PredictionEngine.patterns) do
        table.insert(patterns, pattern)
    end
    
    -- Sort by learning score
    table.sort(patterns, function(a, b)
        return a.learningScore > b.learningScore
    end)
    
    TriggerClientEvent('ec_admin_ultimate:client:patternAnalysisUpdate', src, patterns)
end)

-- Get anomaly detections
RegisterNetEvent('ec_admin_ultimate:server:getAnomalyDetections', function()
    local src = source
    
    local anomalies = {}
    for playerId, score in pairs(PredictionEngine.anomalyScores) do
        if score > 0.5 then
            table.insert(anomalies, {
                playerId = playerId,
                playerName = GetPlayerName(tonumber(playerId)),
                anomalyScore = score
            })
        end
    end
    
    -- Sort by anomaly score
    table.sort(anomalies, function(a, b)
        return a.anomalyScore > b.anomalyScore
    end)
    
    TriggerClientEvent('ec_admin_ultimate:client:anomalyDetectionsUpdate', src, anomalies)
end)

-- Auto-analyze active players every 5 minutes
CreateThread(function()
    while true do
        Wait(5 * 60 * 1000) -- 5 minutes
        
        for _, playerId in ipairs(GetPlayers()) do
            local identifier = GetPlayerIdentifier(tonumber(playerId))
            local playerName = GetPlayerName(tonumber(playerId))
            
            if identifier then
                local analysis = AnalyzePlayerBehavior(identifier, playerName)
                
                if analysis then
                    -- Check for bot behavior
                    if analysis.botProbability >= AIConfig.BotProbabilityThreshold then
                        LogAIDetection(tonumber(playerId), 'bot_behavior', analysis.botProbability, analysis, analysis.botProbability)
                    elseif analysis.farmingScore >= AIConfig.FarmingScoreThreshold then
                        LogAIDetection(tonumber(playerId), 'farming_bot', analysis.farmingScore, analysis, analysis.farmingScore)
                    end
                end
            end
        end
    end
end)

Logger.Success('✅ AI Detection System Enhanced with Predictions')
Logger.Info('Features: Prediction engine | Pattern learning | Anomaly detection | Advanced scoring')
Logger.Info('🤖 Advanced AI detection ready for deployment')