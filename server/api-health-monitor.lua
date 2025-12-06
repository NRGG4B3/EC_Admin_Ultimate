-- EC Admin Ultimate - API Health Monitor
-- Checks API connection status every 5 minutes
-- Version: 1.0.0

-- SILENT LOAD - No startup message
-- Logger.Info('🏥 API Health Monitor loaded')

local APIHealth = {
    status = {
        GlobalBans = { online = false, lastCheck = 0, url = nil },
        AIDetection = { online = false, lastCheck = 0, url = nil },
        Analytics = { online = false, lastCheck = 0, url = nil },
        ServerMetrics = { online = false, lastCheck = 0, url = nil },
        Reports = { online = false, lastCheck = 0, url = nil },
        AntiCheat = { online = false, lastCheck = 0, url = nil },
        Backups = { online = false, lastCheck = 0, url = nil },
        Inventory = { online = false, lastCheck = 0, url = nil },
        Webhooks = { online = false, lastCheck = 0, url = nil },
        Community = { online = false, lastCheck = 0, url = nil },
        LiveMap = { online = false, lastCheck = 0, url = nil },
        Economy = { online = false, lastCheck = 0, url = nil },
        Whitelist = { online = false, lastCheck = 0, url = nil },
        DiscordSync = { online = false, lastCheck = 0, url = nil },
        VehicleData = { online = false, lastCheck = 0, url = nil },
        Housing = { online = false, lastCheck = 0, url = nil },
        Jobs = { online = false, lastCheck = 0, url = nil },
        HostDashboard = { online = false, lastCheck = 0, url = nil },
        SystemManagement = { online = false, lastCheck = 0, url = nil },
        AIAnalytics = { online = false, lastCheck = 0, url = nil },
        Moderation = { online = false, lastCheck = 0, url = nil },
        VehicleManagement = { online = false, lastCheck = 0, url = nil }
    },
    checkInterval = 300000, -- 5 minutes in milliseconds
    isHostMode = false,
    usingFallback = false,
    lastWarningTime = 0
}

-- Detect host mode
local function DetectHostMode()
    -- Check if host config exists
    if Config.Host and Config.Host.enabled then
        APIHealth.isHostMode = true
        return true
    end
    
    -- Check if /host/ folder exists by trying to load host config
    local hostExists = LoadResourceFile(GetCurrentResourceName(), 'host/config.json')
    if hostExists then
        APIHealth.isHostMode = true
        return true
    end
    
    return false
end

-- Check if specific API is online
local function CheckAPI(apiName, url)
    if not url or url == "" then
        return false
    end
    
    -- Perform HTTP request with timeout and X-Host-Secret header
    local success = false
    local hostSecret = nil
    if Config and Config.HostApi and Config.HostApi.secret then
        hostSecret = Config.HostApi.secret
    end
    local headers = { ['Content-Type'] = 'application/json' }
    if hostSecret then
        headers['X-Host-Secret'] = hostSecret
    end
    PerformHttpRequest(url .. '/health', function(statusCode, response, respHeaders)
        if statusCode == 200 then
            success = true
        end
    end, 'GET', '', headers)
    -- Wait for response (with timeout)
    local timeout = 0
    while success == false and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    return success
end

-- Check all API endpoints
function APIHealth.CheckAllAPIs()
    local currentTime = os.time()
    local statusChanged = false
    local offlineAPIs = {}
    
    -- Only check if we're in customer mode or host mode with remote APIs
    if APIHealth.isHostMode then
        -- Host mode - check localhost APIs (correct port mapping)
        local apis = {
            { name = 'GlobalBans', url = 'http://127.0.0.1:3001' },
            { name = 'AIDetection', url = 'http://127.0.0.1:3002' },
            { name = 'Analytics', url = 'http://127.0.0.1:3003' },
            { name = 'ServerMetrics', url = 'http://127.0.0.1:3004' },
            { name = 'Reports', url = 'http://127.0.0.1:3005' },
            { name = 'AntiCheat', url = 'http://127.0.0.1:3006' },
            { name = 'Backups', url = 'http://127.0.0.1:3007' },
            { name = 'Inventory', url = 'http://127.0.0.1:3008' },
            { name = 'Webhooks', url = 'http://127.0.0.1:3009' },
            { name = 'Community', url = 'http://127.0.0.1:3010' },
            { name = 'LiveMap', url = 'http://127.0.0.1:3012' },
            { name = 'Economy', url = 'http://127.0.0.1:3013' },
            { name = 'Whitelist', url = 'http://127.0.0.1:3014' },
            { name = 'DiscordSync', url = 'http://127.0.0.1:3015' },
            { name = 'VehicleData', url = 'http://127.0.0.1:3016' },
            { name = 'Housing', url = 'http://127.0.0.1:3017' },
            { name = 'Jobs', url = 'http://127.0.0.1:3009' },
            { name = 'HostDashboard', url = 'http://127.0.0.1:3018' },
            { name = 'SystemManagement', url = 'http://127.0.0.1:3019' },
            { name = 'AIAnalytics', url = 'http://127.0.0.1:3003' },
            { name = 'Moderation', url = 'http://127.0.0.1:3010' },
            { name = 'VehicleManagement', url = 'http://127.0.0.1:3016' }
        }
        
        for _, api in ipairs(apis) do
            local previousStatus = APIHealth.status[api.name].online
            local currentStatus = CheckAPI(api.name, api.url)
            
            APIHealth.status[api.name].online = currentStatus
            APIHealth.status[api.name].lastCheck = currentTime
            APIHealth.status[api.name].url = api.url
            
            -- Check if status changed
            if previousStatus ~= currentStatus then
                statusChanged = true
                
                if not currentStatus then
                    table.insert(offlineAPIs, api.name)
                end
            end
        end
    else
        -- Customer mode - check remote NRG APIs
        if Config.NRG_API and Config.NRG_API.endpoints then
            for apiName, endpoint in pairs(Config.NRG_API.endpoints) do
                if APIHealth.status[apiName] then
                    local previousStatus = APIHealth.status[apiName].online
                    local currentStatus = CheckAPI(apiName, endpoint)
                    
                    APIHealth.status[apiName].online = currentStatus
                    APIHealth.status[apiName].lastCheck = currentTime
                    APIHealth.status[apiName].url = endpoint
                    
                    -- Check if status changed
                    if previousStatus ~= currentStatus then
                        statusChanged = true
                        
                        if not currentStatus then
                            table.insert(offlineAPIs, apiName)
                        end
                    end
                end
            end
        end
    end
    
    -- If any API went offline, enable fallback and warn
    if #offlineAPIs > 0 then
        APIHealth.usingFallback = true
        
        -- Only show warning once every 5 minutes
        if currentTime - APIHealth.lastWarningTime >= 300 then
            local mode = APIHealth.isHostMode and "Host Mode" or "Customer Mode"
            Logger.Warn('⚠️  API Health Warning (' .. mode .. ')')
            Logger.Warn(string.format('🚨 %d API(s) offline!', #offlineAPIs))
            
            for _, apiName in ipairs(offlineAPIs) do
                Logger.Error(apiName .. ' API: OFFLINE')
            end
            
            APIHealth.lastWarningTime = currentTime
        end
    else
        -- All APIs online
        if APIHealth.usingFallback then
            -- APIs came back online
            Logger.Success('✅ All APIs now online - Fallback mode disabled')
            APIHealth.usingFallback = false
        end
    end
    
    return statusChanged
end

-- Get API status
function APIHealth.GetStatus()
    return {
        status = APIHealth.status,
        usingFallback = APIHealth.usingFallback,
        isHostMode = APIHealth.isHostMode
    }
end

-- Check if using fallback mode
function APIHealth.IsUsingFallback()
    return APIHealth.usingFallback
end

-- Initialize and start monitoring
function APIHealth.Initialize()
    DetectHostMode()
    
    local mode = APIHealth.isHostMode and "Host Mode" or "Customer Mode"
    Logger.Info('🏥 Starting API Health Monitor (' .. mode .. ')...')
    
    -- Initial check
    CreateThread(function()
        Wait(5000) -- Wait 5 seconds for APIs to initialize
        
        Logger.Info('🔍 Performing initial API health check...')
        APIHealth.CheckAllAPIs()
        
        -- Start 5-minute interval checks
        while true do
            Wait(APIHealth.checkInterval) -- 5 minutes
            
            Logger.Debug('🔍 Performing scheduled API health check...')
            APIHealth.CheckAllAPIs()
        end
    end)
end

-- Export functions
exports('GetAPIHealth', function()
    return APIHealth.GetStatus()
end)

exports('IsUsingFallback', function()
    return APIHealth.IsUsingFallback()
end)

-- Global access
_G.APIHealth = APIHealth

-- Auto-initialize
CreateThread(function()
    Wait(2000) -- Wait for config to load
    APIHealth.Initialize()
end)