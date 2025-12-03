--[[
    EC Admin Ultimate - Unified API Connection Manager
    Manages connections to all 20 NRG APIs with retry logic and health checks
    
    Features:
    - Wait for Host API to be online before connecting
    - Retry failed connections with exponential backoff
    - Health checks for all APIs
    - Connection status tracking
    - Graceful fallback handling
]]

local APIConnectionManager = {
    connections = {},
    initialized = false,
    hostApiReady = false,
    maxRetries = 5,
    retryDelay = 2000,  -- 2 seconds initial delay
}

-- Check if running in HOST MODE or CUSTOMER MODE
local function IsHostMode()
    -- Check if host folder exists
    return LoadResourceFile(GetCurrentResourceName(), 'host/README.md') ~= nil
end

-- Get API base URL based on mode
local function GetAPIBaseURL(port)
    if IsHostMode() then
        -- HOST MODE: Use localhost
        return string.format('http://127.0.0.1:%d', port or 3000)
    else
        -- CUSTOMER MODE: Use production API server
        if port and port ~= 3000 then
            return string.format('https://api.ecbetasolutions.com:%d', port)
        else
            return 'https://api.ecbetasolutions.com'
        end
    end
end

-- List of all 20 NRG APIs
local NRG_APIS = {
    {
        name = 'Global Ban API',
        key = 'global_ban',
        url = GetAPIBaseURL(3001) .. '/api/global-bans',
        healthUrl = GetAPIBaseURL(3001) .. '/health',
        required = false,
        enabled = function() 
            return Config and Config.APIs and Config.APIs.GlobalBans and Config.APIs.GlobalBans.enabled 
        end
    },
    {
        name = 'Player Analytics API',
        key = 'player_analytics',
        url = GetAPIBaseURL(3003) .. '/api/player-analytics',
        healthUrl = GetAPIBaseURL(3003) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Server Metrics API',
        key = 'server_metrics',
        url = GetAPIBaseURL(3004) .. '/api/server-metrics',
        healthUrl = GetAPIBaseURL(3004) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Economy API',
        key = 'economy',
        url = GetAPIBaseURL(3009) .. '/api/economy',
        healthUrl = GetAPIBaseURL(3009) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Reports API',
        key = 'reports',
        url = GetAPIBaseURL(3005) .. '/api/reports',
        healthUrl = GetAPIBaseURL(3005) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Vehicle Management API',
        key = 'vehicle_management',
        url = GetAPIBaseURL(3000) .. '/api/vehicles',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Jobs & Gangs API',
        key = 'jobs_gangs',
        url = GetAPIBaseURL(3000) .. '/api/jobs',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Housing API',
        key = 'housing',
        url = GetAPIBaseURL(3000) .. '/api/housing',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Inventory API',
        key = 'inventory',
        url = GetAPIBaseURL(3000) .. '/api/inventory',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Moderation API',
        key = 'moderation',
        url = GetAPIBaseURL(3000) .. '/api/moderation',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Whitelist API',
        key = 'whitelist',
        url = GetAPIBaseURL(3000) .. '/api/whitelist',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Community API',
        key = 'community',
        url = GetAPIBaseURL(3000) .. '/api/community',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'AI Detection API',
        key = 'ai_detection',
        url = GetAPIBaseURL(3000) .. '/api/ai-detection',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'AI Analytics API',
        key = 'ai_analytics',
        url = GetAPIBaseURL(3000) .. '/api/ai-analytics',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Anticheat API',
        key = 'anticheat',
        url = GetAPIBaseURL(3000) .. '/api/anticheat',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Live Map API',
        key = 'livemap',
        url = GetAPIBaseURL(3000) .. '/api/livemap',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Dashboard API',
        key = 'dashboard',
        url = GetAPIBaseURL(3000) .. '/api/dashboard',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'System Management API',
        key = 'system_management',
        url = GetAPIBaseURL(3000) .. '/api/system-management',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Resource Management API',
        key = 'resource_management',
        url = GetAPIBaseURL(3000) .. '/api/resource-management',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    },
    {
        name = 'Backup & Restore API',
        key = 'backup_restore',
        url = GetAPIBaseURL(3000) .. '/api/backup-restore',
        healthUrl = GetAPIBaseURL(3000) .. '/health',
        required = false,
        enabled = function() 
            return true 
        end
    }
}

-- Check if Host API is ready
function APIConnectionManager.CheckHostAPI(callback)
    Logger.Debug('Checking Host API availability...', '🔍')
    
    -- Try multiple endpoints to find one that works
    local endpoints = {
        'http://127.0.0.1:3000/api/health',
        'http://127.0.0.1:3000/api/status',
        'http://127.0.0.1:3000/',
        'http://127.0.0.1:3000/api/host/dashboard'
    }
    
    local function tryEndpoint(index)
        if index > #endpoints then
            Logger.Warn('Could not find valid Host API endpoint', '⚠️')
            if callback then callback(false) end
            return
        end
        
        PerformHttpRequest(endpoints[index], function(statusCode, response, headers)
            if statusCode == 200 or statusCode == 304 then
                Logger.Debug('Host API is ready (port 3000)', '✅')
                APIConnectionManager.hostApiReady = true
                if callback then callback(true) end
            else
                -- Try next endpoint
                tryEndpoint(index + 1)
            end
        end, 'GET', '', {})
    end
    
    tryEndpoint(1)
end

-- Connect to a single API with retry logic
function APIConnectionManager.ConnectAPI(api, retryCount)
    retryCount = retryCount or 0
    
    if not api.enabled() then
        Logger.Debug(string.format('%s is disabled in config', api.name), '⏭️')
        APIConnectionManager.connections[api.key] = {
            status = 'disabled',
            enabled = false
        }
        return
    end
    
    -- Check if it's a Host API endpoint
    local isHostAPI = string.match(api.url, '^/api/host/')
    
    if isHostAPI and not APIConnectionManager.hostApiReady then
        -- Wait for Host API to be ready
        Citizen.SetTimeout(1000, function()
            APIConnectionManager.ConnectAPI(api, retryCount)
        end)
        return
    end
    
    local fullUrl = api.url
    if isHostAPI then
        fullUrl = 'http://127.0.0.1:3000' .. api.url
    end
    
    Logger.Debug(string.format('Connecting to %s...', api.name), '🔌')
    
    -- Health check endpoint
    local healthUrl = api.healthUrl
    
    PerformHttpRequest(healthUrl, function(statusCode, response, headers)
        if statusCode == 200 or statusCode == 404 then  -- 404 is OK if health endpoint doesn't exist
            APIConnectionManager.connections[api.key] = {
                status = 'connected',
                enabled = true,
                url = fullUrl,
                connectedAt = os.time(),
                name = api.name
            }
            Logger.Debug(string.format('%s connected', api.name), '✅')
        elseif statusCode == 0 then
            -- Connection failed, retry
            if retryCount < APIConnectionManager.maxRetries then
                local delay = APIConnectionManager.retryDelay * (2 ^ retryCount)  -- Exponential backoff
                Logger.Debug(string.format('%s failed, retrying in %dms... (Attempt %d/%d)', 
                    api.name, delay, retryCount + 1, APIConnectionManager.maxRetries), '⚠️')
                
                Citizen.SetTimeout(delay, function()
                    APIConnectionManager.ConnectAPI(api, retryCount + 1)
                end)
            else
                APIConnectionManager.connections[api.key] = {
                    status = 'failed',
                    enabled = false,
                    error = 'Max retries reached',
                    name = api.name
                }
                Logger.Warn(string.format('%s failed after %d attempts', api.name, APIConnectionManager.maxRetries), '❌')
            end
        else
            APIConnectionManager.connections[api.key] = {
                status = 'error',
                enabled = false,
                statusCode = statusCode,
                name = api.name
            }
            Logger.Warn(string.format('%s returned status %d', api.name, statusCode), '⚠️')
        end
    end, 'GET', '', {})
end

-- Initialize all API connections
function APIConnectionManager.Initialize()
    if APIConnectionManager.initialized then
        return
    end
    
    -- SILENT INIT - Only show summary at end
    -- print('[API Manager] 🚀 Initializing NRG API Suite (20 APIs)...')
    -- print('[API Manager] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    
    -- First check if Host API is ready
    APIConnectionManager.CheckHostAPI(function(ready)
        if ready then
            -- Connect to all APIs
            for _, api in ipairs(NRG_APIS) do
                Citizen.SetTimeout(100 * _, function()  -- Stagger connections by 100ms
                    APIConnectionManager.ConnectAPI(api)
                end)
            end
            
            -- Print summary after all attempts
            Citizen.SetTimeout(15000, function()  -- Wait 15 seconds for all retries
                APIConnectionManager.PrintSummary()
            end)
        else
            -- Host API not ready, retry after delay
            -- print('[API Manager] ⏳ Waiting for Host API to start...')
            Citizen.SetTimeout(5000, function()
                APIConnectionManager.Initialize()
            end)
        end
    end)
    
    APIConnectionManager.initialized = true
end

-- Print connection summary
function APIConnectionManager.PrintSummary()
    Logger.System('')
    Logger.System('========================================')
    Logger.System('[EC Admin] API Status')
    Logger.System('========================================')
    
    local connected = 0
    local disabled = 0
    local failed = 0
    
    -- Show all connected APIs
    for key, conn in pairs(APIConnectionManager.connections) do
        if conn.status == 'connected' then
            connected = connected + 1
            Logger.Success(conn.name)
        elseif conn.status == 'disabled' then
            disabled = disabled + 1
        elseif conn.status == 'failed' or conn.status == 'error' then
            failed = failed + 1
            Logger.Error(conn.name)
        end
    end
    
    Logger.System('')
    Logger.Info(string.format('Total: %d | Connected: %d | Failed: %d', #NRG_APIS, connected, failed))
    
    if connected + disabled == #NRG_APIS then
        Logger.Success('All APIs operational')
    elseif failed > 0 then
        Logger.Warn('Some APIs offline - using fallback')
    end
    
    Logger.System('========================================')
    Logger.System('')
end

-- Get API status
function APIConnectionManager.GetStatus(apiKey)
    return APIConnectionManager.connections[apiKey] or { status = 'unknown', enabled = false }
end

-- Get all API statuses
function APIConnectionManager.GetAllStatuses()
    return APIConnectionManager.connections
end

-- Retry failed connection
function APIConnectionManager.RetryConnection(apiKey)
    for _, api in ipairs(NRG_APIS) do
        if api.key == apiKey then
            Logger.Debug(string.format('Retrying %s...', api.name), '🔄')
            APIConnectionManager.ConnectAPI(api)
            return true
        end
    end
    return false
end

-- Retry all failed connections
function APIConnectionManager.RetryAllFailed()
    Logger.Debug('Retrying all failed connections...', '🔄')
    
    local retriedCount = 0
    for key, conn in pairs(APIConnectionManager.connections) do
        if conn.status == 'failed' or conn.status == 'error' then
            APIConnectionManager.RetryConnection(key)
            retriedCount = retriedCount + 1
        end
    end
    
    Logger.Debug(string.format('Retrying %d failed connections', retriedCount))
    
    -- Print summary after retries
    Citizen.SetTimeout(10000, function()
        APIConnectionManager.PrintSummary()
    end)
end

-- Manual command to check API status
RegisterCommand('api_status', function(source)
    if source ~= 0 then return end
    APIConnectionManager.PrintSummary()
end, true)

-- Manual command to retry failed APIs
RegisterCommand('api_retry', function(source)
    if source ~= 0 then return end
    APIConnectionManager.RetryAllFailed()
end, true)

-- Initialize on resource start
CreateThread(function()
    Wait(5000)  -- Wait 5 seconds for Host API to start
    APIConnectionManager.Initialize()
end)

-- Periodic health check (every 5 minutes)
CreateThread(function()
    while true do
        Wait(300000)  -- 5 minutes
        
        local disconnected = 0
        for key, conn in pairs(APIConnectionManager.connections) do
            if conn.status == 'failed' or conn.status == 'error' then
                disconnected = disconnected + 1
            end
        end
        
        if disconnected > 0 then
            Logger.Warn(string.format('%d APIs disconnected, attempting to reconnect...', disconnected), '⚠️')
            APIConnectionManager.RetryAllFailed()
        end
    end
end)

-- Exports
exports('GetAPIStatus', APIConnectionManager.GetStatus)
exports('GetAllAPIStatuses', APIConnectionManager.GetAllStatuses)
exports('RetryAPIConnection', APIConnectionManager.RetryConnection)
exports('RetryAllFailedAPIs', APIConnectionManager.RetryAllFailed)

-- NUI Callback for API status
-- ✅ CANONICAL VERSION - This is the primary implementation
lib.callback.register('ec_admin:getAPIStatus', function(source)
    return {
        success = true,
        apis = APIConnectionManager.GetAllStatuses(),
        hostApiReady = APIConnectionManager.hostApiReady,
        totalAPIs = #NRG_APIS
    }
end)

-- NOTE: api-redundancy.lua also had this callback but is less comprehensive

Logger.Info('API Connection Manager loaded', '📡')