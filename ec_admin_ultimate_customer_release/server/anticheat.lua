--[[
    EC Admin Ultimate - Anticheat & AI Detection UI Backend
    Server-side logic for anticheat and AI detection management
    
    Handles:
    - getAnticheatAlerts (lib.callback): Get live detections, violation history, or AI patterns
    - handleDetection (RegisterNUICallback): Handle a detection (warn, kick, ban, dismiss)
    - updateAnticheatConfig (RegisterNUICallback): Update anticheat configuration
    
    Framework Support: QB-Core, QBX, ESX
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Anticheat] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Anticheat] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local detectionsCache = {}
local historyCache = {}
local patternsCache = {}
local CACHE_TTL = 5 -- Cache for 5 seconds (short for real-time data)

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Get player object
local function getPlayerObject(source)
    return ECFramework.GetPlayerObject(source)
end

-- Helper: Check admin permission
local function hasPermission(source, permission)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, permission)
    end
    return ECFramework.IsAdminGroup(source) or false
end

-- Helper: Get admin info
local function getAdminInfo(source)
    return {
        id = GetPlayerIdentifier(source, 0) or 'system',
        name = GetPlayerName(source) or 'System'
    }
end

-- Helper: Get player identifier from source
local function getPlayerIdentifierFromSource(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    -- Try license first
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    
    return identifiers[1]
end

-- Helper: Get player source from identifier
local function getPlayerSourceByIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            local ids = GetPlayerIdentifiers(source)
            if ids then
                for _, id in ipairs(ids) do
                    if id == identifier then
                        return source
                    end
                end
            end
        end
    end
    return nil
end

-- Helper: Get player name from identifier
local function getPlayerNameByIdentifier(identifier)
    -- Try online first
    local source = getPlayerSourceByIdentifier(identifier)
    if source then
        return GetPlayerName(source) or 'Unknown'
    end
    
    -- Try database
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        local success, result = pcall(function()
            return MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ? LIMIT 1', {identifier})
        end)
        if success and result and result[1] then
            local charinfo = json.decode(result[1].charinfo or '{}')
            if charinfo then
                return (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
            end
        end
    elseif framework == 'esx' then
        local result = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = ? LIMIT 1', {identifier})
        if result and result[1] then
            return (result[1].firstname or '') .. ' ' .. (result[1].lastname or '')
        end
    end
    
    return 'Unknown'
end

-- Helper: Generate unique ID
local function generateId()
    return tostring(os.time()) .. '_' .. tostring(math.random(1000, 9999))
end

-- Helper: Get all detections
local function getAllDetections()
    local detections = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_anticheat_detections
        WHERE resolved = 0
        ORDER BY timestamp DESC
        LIMIT 500
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            local evidence = {}
            if row.evidence then
                evidence = json.decode(row.evidence) or {}
            end
            
            table.insert(detections, {
                id = row.id,
                player = row.player_id,
                playerName = row.player_name,
                type = row.type,
                category = row.category,
                severity = row.severity or 'medium',
                confidence = tonumber(row.confidence) or 0,
                timestamp = row.timestamp,
                date = os.date('%Y-%m-%dT%H:%M:%SZ', row.timestamp),
                location = row.location or 'Unknown',
                coords = {
                    x = tonumber(row.coords_x) or 0.0,
                    y = tonumber(row.coords_y) or 0.0,
                    z = tonumber(row.coords_z) or 0.0
                },
                evidence = evidence,
                action = row.action or 'none',
                aiAnalyzed = (row.ai_analyzed == 1 or row.ai_analyzed == true),
                pattern = row.pattern
            })
        end
    end
    
    return detections
end

-- Helper: Get violation history
local function getViolationHistory()
    local violations = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_anticheat_violations
        ORDER BY timestamp DESC
        LIMIT 500
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(violations, {
                id = row.id,
                player = row.player_id,
                playerName = row.player_name,
                type = row.type,
                action = row.action,
                timestamp = row.timestamp,
                date = os.date('%Y-%m-%dT%H:%M:%SZ', row.timestamp),
                bannedBy = row.banned_by_name or row.banned_by
            })
        end
    end
    
    return violations
end

-- Helper: Get AI patterns
local function getAIPatterns()
    local patterns = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_anticheat_ai_patterns
        ORDER BY last_seen DESC
        LIMIT 100
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(patterns, {
                id = row.id,
                name = row.name,
                type = row.type,
                confidence = tonumber(row.confidence) or 0,
                occurrences = tonumber(row.occurrences) or 1,
                lastSeen = os.date('%Y-%m-%dT%H:%M:%SZ', row.last_seen),
                risk = row.risk or 'low'
            })
        end
    end
    
    return patterns
end

-- Helper: Get anticheat config
local function getAnticheatConfig()
    local config = {
        enabled = true,
        autoActions = true,
        aiAnalysis = true,
        sensitivity = 'medium',
        logLevel = 'info'
    }
    
    local result = MySQL.query.await('SELECT * FROM ec_anticheat_config', {})
    if result then
        for _, row in ipairs(result) do
            local key = row.config_key
            local value = row.config_value
            
            -- Parse boolean values
            if value == 'true' then
                value = true
            elseif value == 'false' then
                value = false
            end
            
            config[key] = value
        end
    end
    
    return config
end

-- Helper: Update anticheat config
local function updateAnticheatConfig(key, value, adminId)
    local valueStr = tostring(value)
    if type(value) == 'boolean' then
        valueStr = value and 'true' or 'false'
    end
    
    MySQL.insert.await([[
        INSERT INTO ec_anticheat_config (config_key, config_value, updated_at, updated_by)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        config_value = VALUES(config_value),
        updated_at = VALUES(updated_at),
        updated_by = VALUES(updated_by)
    ]], {key, valueStr, getCurrentTimestamp(), adminId})
end

-- ============================================================================
-- LIB.CALLBACK HANDLERS (fetchNui from UI)
-- ============================================================================

-- Callback: Get anticheat alerts (detections, history, or patterns)
lib.callback.register('getAnticheatAlerts', function(source, data)
    local history = data.history == true
    local patterns = data.patterns == true
    
    -- Check cache
    local cacheKey = history and 'history' or (patterns and 'patterns' or 'detections')
    local cache = history and historyCache or (patterns and patternsCache or detectionsCache)
    
    if cache.data and (getCurrentTimestamp() - cache.timestamp) < CACHE_TTL then
        if history then
            return { success = true, history = cache.data }
        elseif patterns then
            return { success = true, patterns = cache.data }
        else
            return { success = true, detections = cache.data }
        end
    end
    
    if history then
        local violations = getViolationHistory()
        historyCache = {
            data = violations,
            timestamp = getCurrentTimestamp()
        }
        return { success = true, history = violations }
    elseif patterns then
        local aiPatterns = getAIPatterns()
        patternsCache = {
            data = aiPatterns,
            timestamp = getCurrentTimestamp()
        }
        return { success = true, patterns = aiPatterns }
    else
        local detections = getAllDetections()
        detectionsCache = {
            data = detections,
            timestamp = getCurrentTimestamp()
        }
        return { success = true, detections = detections }
    end
end)

-- ============================================================================
-- REGISTERNUICALLBACK HANDLERS (Direct fetch from UI)
-- ============================================================================

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('handleDetection', function(data, cb)
--     local detectionId = data.detectionId
--     local action = data.action -- 'warn', 'kick', 'ban', 'dismiss'
--     
--     if not detectionId or not action then
--         cb({ success = false, message = 'Detection ID and action required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Detection handled successfully'
--     
--     -- Get detection info
--     local result = MySQL.query.await('SELECT * FROM ec_anticheat_detections WHERE id = ? LIMIT 1', {detectionId})
--     if not result or not result[1] then
--         cb({ success = false, message = 'Detection not found' })
--         return
--     end
--     
--     local detection = result[1]
--     
--     if action == 'dismiss' then
--         -- Mark as resolved
--         MySQL.update.await([[
--             UPDATE ec_anticheat_detections 
--             SET resolved = 1, resolved_by = ?, resolved_at = ?
--             WHERE id = ?
--         ]], {adminInfo.id, getCurrentTimestamp(), detectionId})
--         success = true
--     else
--         -- Get player source
--         local playerSource = getPlayerSourceByIdentifier(detection.player_id)
--         
--         if action == 'warn' then
--             if playerSource then
--                 TriggerClientEvent('ec_admin:notify', playerSource, 'warning', 'Anticheat: ' .. detection.type)
--             end
--             -- Log violation
--             MySQL.insert.await([[
--                 INSERT INTO ec_anticheat_violations 
--                 (id, player_id, player_name, type, action, timestamp, banned_by, banned_by_name, reason)
--                 VALUES (?, ?, ?, ?, 'warn', ?, ?, ?, ?)
--             ]], {
--                 generateId(), detection.player_id, detection.player_name, detection.type,
--                 getCurrentTimestamp(), adminInfo.id, adminInfo.name, 'Anticheat detection: ' .. detection.type
--             })
--             success = true
--         elseif action == 'kick' then
--             if playerSource then
--                 DropPlayer(playerSource, 'Kicked by Anticheat: ' .. detection.type)
--             end
--             -- Log violation
--             MySQL.insert.await([[
--                 INSERT INTO ec_anticheat_violations 
--                 (id, player_id, player_name, type, action, timestamp, banned_by, banned_by_name, reason)
--                 VALUES (?, ?, ?, ?, 'kick', ?, ?, ?, ?)
--             ]], {
--                 generateId(), detection.player_id, detection.player_name, detection.type,
--                 getCurrentTimestamp(), adminInfo.id, adminInfo.name, 'Anticheat detection: ' .. detection.type
--             })
--             success = true
--         elseif action == 'ban' then
--             if playerSource then
--                 -- Trigger ban (integrate with your ban system)
--                 TriggerEvent('ec_admin:banPlayer', playerSource, detection.player_id, 'Anticheat: ' .. detection.type, adminInfo.id)
--                 DropPlayer(playerSource, 'Banned by Anticheat: ' .. detection.type)
--             end
--             -- Log violation
--             MySQL.insert.await([[
--                 INSERT INTO ec_anticheat_violations 
--                 (id, player_id, player_name, type, action, timestamp, banned_by, banned_by_name, reason)
--                 VALUES (?, ?, ?, ?, 'ban', ?, ?, ?, ?)
--             ]], {
--                 generateId(), detection.player_id, detection.player_name, detection.type,
--                 getCurrentTimestamp(), adminInfo.id, adminInfo.name, 'Anticheat detection: ' .. detection.type
--             })
--             success = true
--         end
--         
--         -- Mark detection as action taken
--         MySQL.update.await([[
--             UPDATE ec_anticheat_detections 
--             SET action = ?, action_taken = 1, resolved = 1, resolved_by = ?, resolved_at = ?
--             WHERE id = ?
--         ]], {action, adminInfo.id, getCurrentTimestamp(), detectionId})
--     end
--     
--     -- Clear cache
--     detectionsCache = {}
--     historyCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to handle detection' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('updateAnticheatConfig', function(data, cb)
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Configuration updated successfully'
--     
--     -- Update each config key-value pair
--     for key, value in pairs(data) do
--         if key ~= 'source' then -- Skip source if present
--             updateAnticheatConfig(key, value, adminInfo.id)
--         end
--     end
--     
--     success = true
--     
--     cb({ success = success, message = success and message or 'Failed to update configuration' })
-- end)

-- Export function for other resources to log detections
exports('LogDetection', function(playerId, detectionType, category, severity, confidence, location, coords, evidence, aiAnalyzed, pattern)
    local playerIdentifier = nil
    local playerName = 'Unknown'
    
    if tonumber(playerId) then
        local source = tonumber(playerId)
        playerIdentifier = getPlayerIdentifierFromSource(source)
        playerName = GetPlayerName(source) or 'Unknown'
    else
        playerIdentifier = playerId
        playerName = getPlayerNameByIdentifier(playerIdentifier)
    end
    
    if not playerIdentifier then
        return false
    end
    
    local detectionId = generateId()
    local evidenceJson = json.encode(evidence or {})
    
    MySQL.insert.await([[
        INSERT INTO ec_anticheat_detections 
        (id, player_id, player_name, type, category, severity, confidence, timestamp, location, coords_x, coords_y, coords_z, evidence, ai_analyzed, pattern, resolved, action_taken)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0)
    ]], {
        detectionId, playerIdentifier, playerName, detectionType, category, severity or 'medium',
        confidence or 0, getCurrentTimestamp(), location or 'Unknown',
        coords and coords.x or 0.0, coords and coords.y or 0.0, coords and coords.z or 0.0,
        evidenceJson, aiAnalyzed and 1 or 0, pattern or nil
    })
    
    -- Clear cache
    detectionsCache = {}
    
    return true
end)

print("^2[Anticheat]^7 UI Backend loaded^0")

