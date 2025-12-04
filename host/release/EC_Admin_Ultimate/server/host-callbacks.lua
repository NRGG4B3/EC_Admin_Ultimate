-- EC Admin Ultimate - Host Control Server Callbacks
-- Secures and processes host-control actions requested from UI

local function ensureHostAccess(source)
    local ok = false
    if exports and exports[GetCurrentResourceName()] and exports[GetCurrentResourceName()].IsHostModeEnabled then
        ok = exports[GetCurrentResourceName()]:IsHostModeEnabled()
    end
    if not ok then return false end
    if exports and exports[GetCurrentResourceName()] and exports[GetCurrentResourceName()].IsNRGStaff then
        return exports[GetCurrentResourceName()]:IsNRGStaff(source)
    end
    return false
end

local function safeLog(level, msg)
    if Logger and Logger[level] then
        Logger[level](msg)
    else
        Logger.Info(msg, '📝')
    end
end

lib.callback.register('ec_admin:host:controlAPI', function(source, data)
    if not ensureHostAccess(source) then
        safeLog('Error', ('[Host Control] Denied controlAPI from %s'):format(source))
        return { success = false, error = 'Access denied' }
    end
    local api = data.apiName
    local action = data.action
    local params = data.params or {}

    TriggerEvent('ec_admin:host:performAPIAction', api, action, params)
    safeLog('Info', ('[Host Control] %s -> %s requested by %s'):format(api or 'nil', action or 'nil', source))
    return { success = true }
end)

lib.callback.register('ec_admin:host:executeCityCommand', function(source, data)
    if not ensureHostAccess(source) then
        safeLog('Error', ('[Host Control] Denied executeCityCommand from %s'):format(source))
        return { success = false, error = 'Access denied' }
    end
    TriggerEvent('ec_admin:host:executeCityCommand', data.cityId, data.command, data.params)
    safeLog('Info', ('[Host Control] City %s command %s by %s'):format(tostring(data.cityId), tostring(data.command), source))
    return { success = true }
end)

lib.callback.register('ec_admin:host:emergencyStopAPI', function(source, data)
    if not ensureHostAccess(source) then
        safeLog('Error', ('[Host Control] Denied emergencyStopAPI from %s'):format(source))
        return { success = false, error = 'Access denied' }
    end
    TriggerEvent('ec_admin:host:performAPIAction', data.apiName, 'emergencyStop', { reason = data.reason })
    safeLog('Warn', ('[Host Control] Emergency stop %s by %s: %s'):format(tostring(data.apiName), source, tostring(data.reason)))
    return { success = true }
end)

lib.callback.register('ec_admin:host:restartAPI', function(source, data)
    if not ensureHostAccess(source) then
        safeLog('Error', ('[Host Control] Denied restartAPI from %s'):format(source))
        return { success = false, error = 'Access denied' }
    end
    TriggerEvent('ec_admin:host:performAPIAction', data.apiName, 'restart', {})
    safeLog('Info', ('[Host Control] Restart %s by %s'):format(tostring(data.apiName), source))
    return { success = true }
end)
-- EC Admin Ultimate - Host Control Callbacks (Server)
-- All lib.callback.register for host data
-- Author: NRG Development
-- Version: 1.0.0

-- Check if host mode is available
lib.callback.register('ec_admin:host:checkMode', function(source)
    local hostModeEnabled = false
    local hostSecretValid = false
    
    -- Check if /host/ folder exists
    local hostConfigPath = GetResourcePath(GetCurrentResourceName()) .. '/host/config.lua'
    local file = io.open(hostConfigPath, 'r')
    
    if file then
        file:close()
        hostModeEnabled = true
        
        -- Check for host_secret file
        local secretPath = GetResourcePath(GetCurrentResourceName()) .. '/host_secret'
        local secretFile = io.open(secretPath, 'r')
        
        if secretFile then
            local secret = secretFile:read('*all'):gsub('%s+', '')
            secretFile:close()
            
            if secret and #secret > 0 then
                hostSecretValid = true
            end
        end
    end
    
    return {
        enabled = hostModeEnabled,
        secretValid = hostSecretValid
    }
end)

-- Get APIs status
lib.callback.register('ec_admin:host:getAPIsStatus', function(source)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetAPIsStatus()
end)

-- Get connected cities
lib.callback.register('ec_admin:host:getConnectedCities', function(source)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetConnectedCities()
end)

-- Get global statistics
lib.callback.register('ec_admin:host:getGlobalStats', function(source)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetGlobalStats()
end)

-- Get city details
lib.callback.register('ec_admin:host:getCityDetails', function(source, cityId)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetCityDetails(cityId)
end)

-- Get API logs
-- ✅ CANONICAL VERSION - This is the primary implementation
lib.callback.register('ec_admin:host:getAPILogs', function(source, apiName, filters)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    -- Prefer MetricsDB if available; else return empty, non-mock result
    if _G.MetricsDB and _G.MetricsDB.GetAPILogs then
        return _G.MetricsDB.GetAPILogs(apiName, filters)
    end
    
    -- Attempt export-based retrieval if provided by host resource
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].GetAPILogs then
        return exports['ec_admin_ultimate']:GetAPILogs(apiName, filters)
    end
    
    return {
        success = false,
        apiName = apiName,
        logs = {},
        totalLogs = 0,
        filters = filters,
        error = 'APILog source unavailable'
    }
end)

-- Get API metrics
-- ✅ CANONICAL VERSION - This is the primary implementation
lib.callback.register('ec_admin:host:getAPIMetrics', function(source, apiName, timeRange)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    -- Prefer MetricsDB if available; else return empty, non-mock result
    if _G.MetricsDB and _G.MetricsDB.GetAPIMetrics then
        return _G.MetricsDB.GetAPIMetrics(apiName, timeRange)
    end
    
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].GetAPIMetrics then
        return exports['ec_admin_ultimate']:GetAPIMetrics(apiName, timeRange)
    end
    
    return {
        success = false,
        apiName = apiName,
        timeRange = timeRange or '1h',
        data = {},
        error = 'APIMetrics source unavailable'
    }
end)

-- Get API configuration
lib.callback.register('ec_admin:host:getAPIConfig', function(source, apiName)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].GetAPIConfig then
        return exports['ec_admin_ultimate']:GetAPIConfig(apiName)
    end
    
    if _G.MetricsDB and _G.MetricsDB.GetAPIConfig then
        return _G.MetricsDB.GetAPIConfig(apiName)
    end
    
    return {
        success = false,
        apiName = apiName,
        config = nil,
        error = 'API config source unavailable'
    }
end)

-- Get city analytics
lib.callback.register('ec_admin:host:getCityAnalytics', function(source, cityId, timeRange)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].GetCityAnalytics then
        return exports['ec_admin_ultimate']:GetCityAnalytics(cityId, timeRange)
    end
    
    if _G.MetricsDB and _G.MetricsDB.GetCityAnalytics then
        return _G.MetricsDB.GetCityAnalytics(cityId, timeRange)
    end
    
    return {
        success = false,
        cityId = cityId,
        timeRange = timeRange or '24h',
        analytics = nil,
        error = 'City analytics source unavailable'
    }
end)

-- Get all cities analytics (aggregate)
lib.callback.register('ec_admin:host:getAllCitiesAnalytics', function(source, timeRange)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].GetAllCitiesAnalytics then
        return exports['ec_admin_ultimate']:GetAllCitiesAnalytics(timeRange)
    end
    
    if _G.MetricsDB and _G.MetricsDB.GetAllCitiesAnalytics then
        return _G.MetricsDB.GetAllCitiesAnalytics(timeRange)
    end
    
    return {
        success = false,
        timeRange = timeRange or '24h',
        error = 'Aggregate analytics source unavailable'
    }
end)

-- Get API health checks
lib.callback.register('ec_admin:host:getAPIHealthChecks', function(source)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].RunAPIHealthChecks then
        return exports['ec_admin_ultimate']:RunAPIHealthChecks()
    end
    
    if _G.MetricsDB and _G.MetricsDB.RunAPIHealthChecks then
        return _G.MetricsDB.RunAPIHealthChecks()
    end
    
    return {
        success = false,
        error = 'Health check source unavailable'
    }
end)

-- ✅ PRODUCTION READY: Get webhook execution statistics from database
lib.callback.register('ec_admin:host:getWebhookStats', function(source, hours)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return { success = false, error = 'Permission denied' }
    end
    
    hours = hours or 24
    
    -- Get stats from MetricsDB
    if _G.MetricsDB then
        return _G.MetricsDB.GetWebhookStats(hours)
    end
    
    -- Fallback if database not available
    return {
        success = false,
        executions24h = 0,
        successRate = 0,
        error = 'Database not available'
    }
end)

-- ✅ PRODUCTION READY: Get API usage statistics from database
lib.callback.register('ec_admin:host:getAPIUsageStats', function(source, hours)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return { success = false, error = 'Permission denied' }
    end
    
    hours = hours or 24
    
    -- Get stats from MetricsDB
    if _G.MetricsDB then
        return _G.MetricsDB.GetAPIStats(hours)
    end
    
    -- Fallback if database not available
    return {
        success = false,
        totalCalls = 0,
        error = 'Database not available'
    }
end)

Logger.Info('Host Control callbacks registered (with webhook & API tracking)', '🏢')
