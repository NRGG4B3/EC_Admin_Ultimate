--[[
    EC Admin Ultimate - AI Detection API Integration
    Sends player behavior data to real AI detection engine on Port 3002
]]--

Logger.Info('🤖 Loading AI Detection API Integration...')

local AI_ENABLED = Config and Config.APIs and Config.APIs.AIDetection and Config.APIs.AIDetection.enabled or false

-- Get API URL based on mode
local function GetAIDetectionURL()
    local hostFolderExists = LoadResourceFile(GetCurrentResourceName(), 'host/README.md') ~= nil
    
    if hostFolderExists then
        -- HOST MODE: Use local server (Port 3002)
        return 'http://127.0.0.1:3002/api/ai-detection'
    else
        -- CUSTOMER MODE: Use production API
        return 'https://api.ecbetasolutions.com/ai-detection'
    end
end

local AI_API_URL = GetAIDetectionURL()

-- Load host secret (check convar first, then environment)
local HOST_SECRET = GetConvar('ec_host_secret', '')
if not HOST_SECRET or HOST_SECRET == '' then
    -- Try to load from host-config.lua (secure file)
    local hostConfigPath = 'host/config/host-config.lua'
    local hostConfigFile = LoadResourceFile(GetCurrentResourceName(), hostConfigPath)
    if hostConfigFile then
        -- Parse the host secret from the file
        local secretMatch = hostConfigFile:match('HOST_SECRET%s*=%s*["\']([^"\']+)["\']')
        if secretMatch then
            HOST_SECRET = secretMatch
        end
    end
end

-- Check if we're in HOST mode
local hostFolderExists = LoadResourceFile(GetCurrentResourceName(), 'host/README.md') ~= nil

-- If still no secret AND we're in HOST mode, warn
if (not HOST_SECRET or HOST_SECRET == '') and hostFolderExists then
    Logger.Warn('[AI Detection] No host secret configured - AI Detection will use fallback mode', '⚠️')
    AI_ENABLED = false  -- Disable to prevent spam
elseif not hostFolderExists then
    -- CUSTOMER MODE: Don't need HOST_SECRET, use API key
    AI_ENABLED = false -- Will be enabled if they have API access
end

-- Player behavior tracking
local playerBehaviorData = {}

-- ============================================================================
-- BEHAVIOR DATA COLLECTION
-- ============================================================================

-- Track player movement
RegisterNetEvent('ec_ai:trackMovement', function(data)
    local src = source
    
    if not AI_ENABLED then return end
    if not playerBehaviorData[src] then
        playerBehaviorData[src] = {
            movement = {},
            combat = {},
            economy = {},
            lastUpdate = os.time()
        }
    end
    
    table.insert(playerBehaviorData[src].movement, {
        coords = data.coords,
        speed = data.speed,
        vehicle = data.vehicle,
        timestamp = os.time() * 1000
    })
    
    -- Analyze if movement is suspicious
    AnalyzeMovementBehavior(src, data)
end)

-- Track combat actions
RegisterNetEvent('ec_ai:trackCombat', function(data)
    local src = source
    
    if not AI_ENABLED then return end
    if not playerBehaviorData[src] then
        playerBehaviorData[src] = {
            movement = {},
            combat = {},
            economy = {},
            lastUpdate = os.time()
        }
    end
    
    table.insert(playerBehaviorData[src].combat, {
        weapon = data.weapon,
        target = data.target,
        headshot = data.headshot,
        damage = data.damage,
        timestamp = os.time() * 1000
    })
    
    -- Analyze if combat is suspicious
    AnalyzeCombatBehavior(src, data)
end)

-- Track economy actions
RegisterNetEvent('ec_ai:trackEconomy', function(data)
    local src = source
    
    if not AI_ENABLED then return end
    if not playerBehaviorData[src] then
        playerBehaviorData[src] = {
            movement = {},
            combat = {},
            economy = {},
            lastUpdate = os.time()
        }
    end
    
    table.insert(playerBehaviorData[src].economy, {
        action = data.action,
        amount = data.amount,
        timestamp = os.time() * 1000
    })
    
    -- Analyze if economy behavior is suspicious
    AnalyzeEconomyBehavior(src, data)
end)

-- ============================================================================
-- ANALYSIS FUNCTIONS
-- ============================================================================

-- Analyze movement behavior
function AnalyzeMovementBehavior(source, data)
    local playerName = GetPlayerName(source)
    
    -- Calculate average speed
    local recentMovement = playerBehaviorData[source].movement
    if #recentMovement < 10 then return end -- Need enough samples
    
    local totalSpeed = 0
    local speedSpikes = 0
    local lastSpeed = recentMovement[1].speed or 0
    
    for i = 1, math.min(10, #recentMovement) do
        local movement = recentMovement[#recentMovement - i + 1]
        totalSpeed = totalSpeed + (movement.speed or 0)
        
        if movement.speed and movement.speed > lastSpeed * 2 then
            speedSpikes = speedSpikes + 1
        end
        lastSpeed = movement.speed or 0
    end
    
    local averageSpeed = totalSpeed / math.min(10, #recentMovement)
    local currentSpeed = data.speed or 0
    
    -- Send to AI API if suspicious
    if currentSpeed > 100 or averageSpeed > 50 or speedSpikes > 2 then
        SendToAIAPI(source, playerName, 'movement', {
            speed = currentSpeed,
            averageSpeed = averageSpeed,
            speedSpikes = speedSpikes,
            vehicle = data.vehicle
        })
    end
end

-- Analyze combat behavior
function AnalyzeCombatBehavior(source, data)
    local playerName = GetPlayerName(source)
    
    local recentCombat = playerBehaviorData[source].combat
    if #recentCombat < 10 then return end
    
    -- Calculate headshot ratio
    local headshots = 0
    local total = math.min(10, #recentCombat)
    
    for i = 1, total do
        local combat = recentCombat[#recentCombat - i + 1]
        if combat.headshot then
            headshots = headshots + 1
        end
    end
    
    local headshotRatio = headshots / total
    
    -- Send to AI API if suspicious
    if headshotRatio > 0.8 then
        SendToAIAPI(source, playerName, 'combat', {
            headshotRatio = headshotRatio,
            weapon = data.weapon,
            accuracy = 0.95, -- Calculate from hit/miss ratio
            snapSpeed = 0.1 -- Calculate from aim time
        })
    end
end

-- Analyze economy behavior
function AnalyzeEconomyBehavior(source, data)
    local playerName = GetPlayerName(source)
    
    local recentEconomy = playerBehaviorData[source].economy
    if #recentEconomy < 5 then return end
    
    -- Calculate money gain rate
    local totalGain = 0
    local gainSpikes = 0
    local timeWindow = 60000 -- 1 minute
    local now = os.time() * 1000
    
    for i = 1, #recentEconomy do
        local transaction = recentEconomy[i]
        if now - transaction.timestamp < timeWindow then
            if transaction.action == 'gain' then
                totalGain = totalGain + (transaction.amount or 0)
                
                if transaction.amount > 50000 then
                    gainSpikes = gainSpikes + 1
                end
            end
        end
    end
    
    local gainRate = totalGain / (timeWindow / 60000) -- per minute
    
    -- Send to AI API if suspicious
    if gainRate > 100000 or gainSpikes > 2 then
        SendToAIAPI(source, playerName, 'economy', {
            gainRate = gainRate,
            gainSpikes = gainSpikes,
            transactionPattern = 'irregular'
        })
    end
end

-- ============================================================================
-- AI API INTEGRATION
-- ============================================================================

-- Send behavior data to AI API for analysis
function SendToAIAPI(source, playerName, behaviorType, dataPoints)
    if not AI_ENABLED then return end
    -- Only check for HOST_SECRET if AI is enabled (already filtered above)
    if not HOST_SECRET or HOST_SECRET == '' then
        return -- Silently fail in customer mode
    end
    
    local payload = {
        playerId = source,
        playerName = playerName,
        behaviorType = behaviorType,
        dataPoints = dataPoints,
        timestamp = os.time() * 1000
    }
    
    local url = AI_API_URL .. '/analyze'
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(json.decode, response)
            if success and data and data.success then
                -- Handle detections
                if data.detections and #data.detections > 0 then
                    for _, detection in ipairs(data.detections) do
                        HandleAIDetection(source, playerName, detection)
                    end
                end
            end
        else
            print(string.format('[AI Detection] ⚠️  API error (Status: %s)', statusCode))
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
        ['X-Host-Secret'] = HOST_SECRET
    })
end

-- Handle AI detection result
function HandleAIDetection(source, playerName, detection)
    print(string.format('[AI Detection] 🚨 %s: %s (Confidence: %d%%, Action: %s)',
        playerName,
        detection.ruleName,
        math.floor(detection.confidence * 100),
        detection.autoAction
    ))
    
    -- Notify admins
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if _G.ECPermissions and _G.ECPermissions.HasPermission(pid, 'admin') then
            TriggerClientEvent('chat:addMessage', pid, {
                color = {255, 0, 0},
                args = {
                    '[AI Detection]',
                    string.format('%s: %s (%d%% confidence)',
                        playerName,
                        detection.ruleName,
                        math.floor(detection.confidence * 100)
                    )
                }
            })
        end
    end
    
    -- Add to local AI detection system
    if _G.AIDetection and _G.AIDetection.AddDetection then
        _G.AIDetection.AddDetection(
            source,
            detection.ruleName,
            detection.category,
            math.floor(detection.confidence * 100),
            table.concat(detection.evidence, ', ')
        )
    end
    
    -- Execute auto action if enabled
    local autoActions = GetConvar('ec_ai_auto_actions', 'false') == 'true'
    if autoActions and detection.autoAction ~= 'none' and detection.autoAction ~= 'warn' then
        SetTimeout(5000, function() -- 5 second delay
            if detection.autoAction == 'ban' then
                -- Ban player
                if _G.ECModeration then
                    _G.ECModeration.AddBan('ai_detection', source, detection.ruleName .. ' (AI: ' .. math.floor(detection.confidence * 100) .. '%)', 'permanent', false, false)
                else
                    DropPlayer(source, string.format('🤖 AI Detection: %s (%d%% confidence)', detection.ruleName, math.floor(detection.confidence * 100)))
                end
            elseif detection.autoAction == 'kick' then
                DropPlayer(source, string.format('🤖 AI Detection: %s (%d%% confidence)', detection.ruleName, math.floor(detection.confidence * 100)))
            end
        end)
    end
end

-- ============================================================================
-- GET AI STATISTICS
-- ============================================================================

lib.callback.register('ec_admin:getAIDetectionStats', function(source)
    if not AI_ENABLED then
        return {
            success = false,
            error = 'AI Detection disabled'
        }
    end
    
    local url = AI_API_URL .. '/status'
    local result = nil
    local completed = false
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(json.decode, response)
            if success and data then
                result = data
            end
        end
        completed = true
    end, 'GET', '', {
        ['X-Host-Secret'] = HOST_SECRET
    })
    
    -- Wait for response (max 2 seconds)
    local waited = 0
    while not completed and waited < 2000 do
        Wait(100)
        waited = waited + 100
    end
    
    return result or { success = false, error = 'Timeout' }
end)

-- ============================================================================
-- CLEANUP
-- ============================================================================

AddEventHandler('playerDropped', function(reason)
    local source = source
    if playerBehaviorData[source] then
        playerBehaviorData[source] = nil
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('SendToAIAPI', SendToAIAPI)
exports('TrackMovement', function(source, data)
    TriggerEvent('ec_ai:trackMovement', data)
end)
exports('TrackCombat', function(source, data)
    TriggerEvent('ec_ai:trackCombat', data)
end)
exports('TrackEconomy', function(source, data)
    TriggerEvent('ec_ai:trackEconomy', data)
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

if AI_ENABLED then
    Logger.Info('✅ AI Detection API Integration loaded')
    Logger.Info('🤖 Real AI engine: Port 3002')
    Logger.Info('📊 Behavior tracking active')
    
    -- Test connection
    CreateThread(function()
        Wait(5000) -- Wait for server to start
        
        PerformHttpRequest(AI_API_URL .. '/status', function(statusCode, response, headers)
            if statusCode == 200 then
                Logger.Info('✅ AI Detection API connected')
            else
                Logger.Info('⚠️  AI Detection API not reachable')
            end
        end, 'GET', '', {
            ['X-Host-Secret'] = HOST_SECRET
        })
    end)
else
    Logger.Info('⚠️  AI Detection API Integration disabled in config')
end

return {
    SendToAIAPI = SendToAIAPI,
    AnalyzeMovementBehavior = AnalyzeMovementBehavior,
    AnalyzeCombatBehavior = AnalyzeCombatBehavior,
    AnalyzeEconomyBehavior = AnalyzeEconomyBehavior
}