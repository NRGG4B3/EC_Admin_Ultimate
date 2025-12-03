-- EC Admin Ultimate - API Health Monitor
-- Checks API connection status every 5 minutes
-- Version: 1.0.0

-- SILENT LOAD - No startup message
-- Logger.Info('🏥 API Health Monitor loaded')

local APIHealth = {
    status = {
        playerData = { online = false, lastCheck = 0, url = nil },
        globalBans = { online = false, lastCheck = 0, url = nil },
        antiCheat = { online = false, lastCheck = 0, url = nil },
        analytics = { online = false, lastCheck = 0, url = nil },
        monitoring = { online = false, lastCheck = 0, url = nil }
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
    
    -- Perform HTTP request with timeout
    local success = false
    
    PerformHttpRequest(url .. '/health', function(statusCode, response, headers)
        if statusCode == 200 then
            success = true
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
    
    -- Wait for response (with timeout)
    local timeout = 0
    while success == false and timeout < 50 do
        Citizen.Wait(100)
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
            { name = 'playerData', url = 'http://127.0.0.1:3011' },   -- Player Tracking API
            { name = 'globalBans', url = 'http://127.0.0.1:3001' },   -- Global Ban System
            { name = 'antiCheat', url = 'http://127.0.0.1:3006' },    -- Anticheat Sync
            { name = 'analytics', url = 'http://127.0.0.1:3003' },    -- Player Analytics
            { name = 'monitoring', url = 'http://127.0.0.1:3016' }    -- Performance Monitor
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
            print('^3========================================^0')
            Logger.Info('')
            print('^3========================================^0')
            Logger.Info('' .. #offlineAPIs .. ' API(s) offline!^0')
            
            for _, apiName in ipairs(offlineAPIs) do
                Logger.Info('' .. apiName .. ' API: OFFLINE^0')
            end
            
            Logger.Info('')
            Logger.Info('')
            print('^3========================================^0')
            
            APIHealth.lastWarningTime = currentTime
        end
    else
        -- All APIs online
        if APIHealth.usingFallback then
            -- APIs came back online
            print('^2========================================^0')
            Logger.Info('')
            print('^2========================================^0')
            Logger.Info('')
            Logger.Info('')
            print('^2========================================^0')
            
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
    Citizen.CreateThread(function()
        Citizen.Wait(5000) -- Wait 5 seconds for APIs to initialize
        
        Logger.Info('🏥 Performing initial API health check...')
        APIHealth.CheckAllAPIs()
        
        -- Start 5-minute interval checks
        while true do
            Citizen.Wait(APIHealth.checkInterval) -- 5 minutes
            
            Logger.Info('🏥 Performing scheduled API health check...')
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
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Wait for config to load
    APIHealth.Initialize()
end)