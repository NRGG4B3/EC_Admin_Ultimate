--[[
    EC ADMIN ULTIMATE - API REDUNDANCY SYSTEM
    Automatic fallback to local Lua when NRG APIs are offline
    Ensures 100% uptime with zero downtime
]]

-- SILENT LOADING - No startup message

-- Track API status
local apiStatus = {
    connected = false,
    lastCheck = 0,
    consecutiveFailures = 0,
    usingFallback = false,
    endpoints = {}
}

-- Initialize all 20 API endpoints
local API_ENDPOINTS = {
    { id = 1, name = "Main Gateway", port = 3000 },
    { id = 2, name = "Global Ban System", port = 3001 },
    { id = 3, name = "AI Detection Engine", port = 3002 },
    { id = 4, name = "Cross-Server Chat", port = 3003 },
    { id = 5, name = "Shared Warnings", port = 3004 },
    { id = 6, name = "Analytics Hub", port = 3005 },
    { id = 7, name = "Session Manager", port = 3006 },
    { id = 8, name = "Backup Storage", port = 3007 },
    { id = 9, name = "Screenshot Storage", port = 3008 },
    { id = 10, name = "Webhook Relay", port = 3009 },
    { id = 11, name = "Global Chat Hub", port = 3010 },
    { id = 12, name = "Player Tracking", port = 3011 },
    { id = 13, name = "Server Registry", port = 3012 },
    { id = 14, name = "License Validation", port = 3013 },
    { id = 15, name = "Update Checker", port = 3014 },
    { id = 16, name = "Audit Logging", port = 3015 },
    { id = 17, name = "Performance Monitor", port = 3016 },
    { id = 18, name = "Resource Hub", port = 3017 },
    { id = 19, name = "Emergency Control", port = 3018 },
    { id = 20, name = "Host Dashboard", port = 3019 }
}

-- Initialize endpoint status
for _, endpoint in ipairs(API_ENDPOINTS) do
    apiStatus.endpoints[endpoint.id] = {
        name = endpoint.name,
        port = endpoint.port,
        online = false,
        lastCheck = 0,
        consecutiveFailures = 0
    }
end

-- Check if in host mode
local function IsHostMode()
    return Config.Host and Config.Host.enabled or false
end

-- Check if API is enabled
local function IsAPIEnabled()
    return Config.API and Config.API.enabled or false
end

-- Get API base URL
local function GetAPIBaseUrl()
    if IsHostMode() then
        return "http://localhost:3000"
    else
        return Config.API and Config.API.baseUrl or "https://api.ecbetasolutions.com"
    end
end

-- Check single API endpoint
local function CheckAPIEndpoint(endpointId)
    local endpoint = apiStatus.endpoints[endpointId]
    if not endpoint then return false end
    
    local baseUrl = GetAPIBaseUrl()
    local url = string.format("%s/health", baseUrl:gsub(":3000", ":" .. endpoint.port))
    
    -- Try to perform HTTP request (non-blocking)
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            endpoint.online = true
            endpoint.consecutiveFailures = 0
            endpoint.lastCheck = os.time()
        else
            endpoint.online = false
            endpoint.consecutiveFailures = endpoint.consecutiveFailures + 1
            endpoint.lastCheck = os.time()
            
            -- Warn after 3 consecutive failures
            if endpoint.consecutiveFailures == 3 then
                Logger.Warn(string.format("%s (:%d) offline - using Lua fallback", 
                    endpoint.name, endpoint.port), '⚠️')
            end
        end
    end, "GET", "", { ["Content-Type"] = "application/json" })
end

-- Check all API endpoints
local function CheckAllAPIs()
    if not IsAPIEnabled() then
        return
    end
    
    local connectedCount = 0
    local failedCount = 0
    
    for id, endpoint in pairs(apiStatus.endpoints) do
        CheckAPIEndpoint(id)
        
        if endpoint.online then
            connectedCount = connectedCount + 1
        else
            failedCount = failedCount + 1
        end
    end
    
    apiStatus.connected = connectedCount > 0
    
    -- Update global status
    if failedCount > 0 and not apiStatus.usingFallback then
        apiStatus.usingFallback = true
        Logger.Warn(string.format("%d/%d APIs offline - Lua fallback active", 
            failedCount, #API_ENDPOINTS), '⚠️')
    elseif failedCount == 0 and apiStatus.usingFallback then
        apiStatus.usingFallback = false
        Logger.Info("All APIs restored - back to normal operation", '✅')
    end
    
    return connectedCount, failedCount
end

-- Periodic health check (every 30 seconds)
CreateThread(function()
    while true do
        Wait(30000) -- 30 seconds
        
        if IsAPIEnabled() and not IsHostMode() then
            CheckAllAPIs()
        end
    end
end)

-- REMOVED: Duplicate initial check - now handled by startup event only

-- Event handler for startup API check
RegisterNetEvent('ec_admin:performInitialAPICheck', function()
    if not IsAPIEnabled() or IsHostMode() then
        return
    end
    
    -- SILENT CHECK - only show result
    
    Wait(1000)
    
    local connected, failed = CheckAllAPIs()
    
    Wait(2000) -- Wait for all async checks to complete
    
    -- Recount after async checks
    connected = 0
    failed = 0
    
    for _, endpoint in pairs(apiStatus.endpoints) do
        if endpoint.online then
            connected = connected + 1
        else
            failed = failed + 1
        end
    end
    
    -- Only show final result
    if failed == 0 then
        print(string.format("^2✓ API Status: %d/%d Online - All systems operational^0", connected, #API_ENDPOINTS))
    elseif failed > 0 and failed < #API_ENDPOINTS then
        print(string.format("^3⚠ API Status: %d Online | %d Offline (Lua fallback active)^0", connected, failed))
    else
        print(string.format("^1✗ API Status: All %d APIs Offline (Full Lua fallback active)^0", #API_ENDPOINTS))
    end
end)

-- API Request with automatic fallback
-- This function wraps all API calls and automatically falls back to Lua
function APIRequest(endpoint, data, luaFallback)
    if not IsAPIEnabled() then
        -- API disabled, use Lua fallback immediately
        if luaFallback then
            return luaFallback(data)
        end
        return nil, "API disabled"
    end
    
    local baseUrl = GetAPIBaseUrl()
    local url = baseUrl .. endpoint
    
    -- Try API first
    local success = false
    local result = nil
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            success = true
            result = json.decode(response)
        else
            success = false
            
            -- Log API failure
            Logger.Warn(string.format("Request to %s failed (HTTP %d) - using Lua fallback", 
                endpoint, statusCode or 0), '⚠️')
        end
    end, "POST", json.encode(data), { ["Content-Type"] = "application/json" })
    
    -- Wait for response (max 5 seconds)
    local timeout = 0
    while not success and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    -- Use fallback if API failed or timed out
    if not success or timeout >= 5000 then
        if timeout >= 5000 then
            Logger.Warn(string.format("Request to %s timed out - using Lua fallback", endpoint), '⚠️')
        end
        
        if luaFallback then
            return luaFallback(data)
        end
        
        return nil, "API unavailable"
    end
    
    return result, nil
end

-- Export API status for monitoring
function GetAPIStatus()
    local connected = 0
    local failed = 0
    local endpoints = {}
    
    for id, endpoint in pairs(apiStatus.endpoints) do
        if endpoint.online then
            connected = connected + 1
        else
            failed = failed + 1
        end
        
        table.insert(endpoints, {
            id = id,
            name = endpoint.name,
            port = endpoint.port,
            online = endpoint.online,
            consecutiveFailures = endpoint.consecutiveFailures,
            lastCheck = endpoint.lastCheck
        })
    end
    
    return {
        connected = connected,
        failed = failed,
        total = #API_ENDPOINTS,
        usingFallback = apiStatus.usingFallback,
        endpoints = endpoints
    }
end

-- ❌ DUPLICATE CALLBACK - Disabled to avoid conflict
-- This callback is already registered in api-connection-manager.lua (more comprehensive)
-- lib.callback.register('ec_admin:getAPIStatus', function(source)
--     return GetAPIStatus()
-- end)

-- Example: Global ban with fallback
function GlobalBan(identifier, reason, bannedBy)
    return APIRequest('/api/bans/create', {
        identifier = identifier,
        reason = reason,
        bannedBy = bannedBy
    }, function(data)
        -- LUA FALLBACK: Store in local database
        Logger.Debug("Storing global ban locally (API offline)", '⚠️')
        
        MySQL.insert('INSERT INTO ec_global_bans (identifier, reason, banned_by, banned_at) VALUES (?, ?, ?, ?)', {
            data.identifier,
            data.reason,
            data.bannedBy,
            os.date('%Y-%m-%d %H:%M:%S')
        }, function(insertId)
            -- Will sync to API when back online
            Logger.Debug("Global ban stored locally (ID: " .. insertId .. ") - will sync when API restores", '✅')
        end)
        
        return { success = true, fallback = true }
    end)
end

-- Example: AI detection with fallback
function ReportAIDetection(playerId, detectionType, evidence)
    return APIRequest('/api/ai/detect', {
        serverId = GetConvar('ec_server_id', 'unknown'),
        playerId = playerId,
        detectionType = detectionType,
        evidence = evidence
    }, function(data)
        -- LUA FALLBACK: Store locally
        Logger.Debug("Storing AI detection locally (API offline)", '⚠️')
        
        MySQL.insert('INSERT INTO ec_ai_detections (player_id, detection_type, evidence, detected_at) VALUES (?, ?, ?, ?)', {
            data.playerId,
            data.detectionType,
            json.encode(data.evidence),
            os.date('%Y-%m-%d %H:%M:%S')
        }, function(insertId)
            Logger.Debug("AI detection stored locally (ID: " .. insertId .. ") - will sync when API restores", '✅')
        end)
        
        return { success = true, fallback = true }
    end)
end

-- Sync queued data when API comes back online
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        if IsAPIEnabled() and not IsHostMode() then
            -- Check if API is back online after being offline
            if apiStatus.connected and apiStatus.usingFallback then
                Logger.Info("API restored - syncing queued data...", '✅')
                
                -- Sync global bans
                MySQL.query('SELECT * FROM ec_global_bans WHERE synced = 0', {}, function(bans)
                    if bans and #bans > 0 then
                        Logger.Debug(string.format("Syncing %d queued global bans...", #bans))
                        
                        for _, ban in ipairs(bans) do
                            -- Send to API
                            PerformHttpRequest(GetAPIBaseUrl() .. '/api/bans/create', function(statusCode, response, headers)
                                if statusCode == 200 then
                                    -- Mark as synced
                                    MySQL.update('UPDATE ec_global_bans SET synced = 1 WHERE ban_id = ?', { ban.ban_id })
                                end
                            end, "POST", json.encode({
                                identifier = ban.identifier,
                                reason = ban.reason,
                                bannedBy = ban.banned_by
                            }), { ["Content-Type"] = "application/json" })
                        end
                        
                        Logger.Info("Global bans synced successfully", '✅')
                    end
                end)
                
                -- Sync AI detections
                MySQL.query('SELECT * FROM ec_ai_detections WHERE synced = 0', {}, function(detections)
                    if detections and #detections > 0 then
                        Logger.Debug(string.format("Syncing %d queued AI detections...", #detections))
                        
                        for _, detection in ipairs(detections) do
                            -- Send to API
                            PerformHttpRequest(GetAPIBaseUrl() .. '/api/ai/detect', function(statusCode, response, headers)
                                if statusCode == 200 then
                                    -- Mark as synced
                                    MySQL.update('UPDATE ec_ai_detections SET synced = 1 WHERE detection_id = ?', { detection.detection_id })
                                end
                            end, "POST", json.encode({
                                serverId = GetConvar('ec_server_id', 'unknown'),
                                playerId = detection.player_id,
                                detectionType = detection.detection_type,
                                evidence = json.decode(detection.evidence)
                            }), { ["Content-Type"] = "application/json" })
                        end
                        
                        Logger.Info("AI detections synced successfully", '✅')
                    end
                end)
                
                apiStatus.usingFallback = false
            end
        end
    end
end)

-- SILENT - System loaded without message