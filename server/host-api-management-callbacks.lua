-- EC Admin Ultimate - Host API Management Callbacks
-- All lib.callback.register for API management features
-- Author: NRG Development
-- Version: 1.0.0

-- Get all API statuses
lib.callback.register('ec_admin:host:getAPIStatuses', function(source)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetAllAPIStatuses()
end)

-- Get specific API status
lib.callback.register('ec_admin:host:getAPIStatus', function(source, apiKey)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api') then
        return nil
    end
    
    local api = {
        name = apiKey,
        key = apiKey,
        port = 3000
    }
    
    return exports['ec_admin_ultimate']:GetAPIStatus(api)
end)

-- Get API logs
lib.callback.register('ec_admin:host:getAPILogs', function(source, data)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api') then
        return nil
    end
    
    local apiKey = data.apiKey
    local limit = data.limit or 100
    
    if not apiKey then
        -- Get logs for all APIs
        local allLogs = MySQL.query.await([[
            SELECT id, api_key as api_name, log_level, message, details, source, timestamp
            FROM ec_host_api_logs
            ORDER BY timestamp DESC
            LIMIT ?
        ]], {limit})
        
        return allLogs or {}
    end
    
    return exports['ec_admin_ultimate']:GetAPILogs(apiKey, limit)
end)

-- Get API metrics
lib.callback.register('ec_admin:host:getAPIMetrics', function(source, data)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api') then
        return nil
    end
    
    local apiKey = data and data.apiKey
    local timeRange = data and data.timeRange or 3600
    
    if not apiKey then
        -- Get metrics for all APIs
        local allMetrics = MySQL.query.await([[
            SELECT api_key, uptime_seconds, total_requests, avg_response_time, 
                   error_rate, memory_usage_mb, cpu_usage_percent, timestamp
            FROM ec_host_api_metrics
            WHERE timestamp >= UNIX_TIMESTAMP() - ?
            ORDER BY timestamp DESC
        ]], {timeRange})
        
        return allMetrics or {}
    end
    
    return exports['ec_admin_ultimate']:GetAPIMetrics(apiKey, timeRange)
end)

-- Get API health summary
lib.callback.register('ec_admin:host:getAPIHealthSummary', function(source)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.api') then
        return nil
    end
    
    local statuses = exports['ec_admin_ultimate']:GetAllAPIStatuses()
    
    local summary = {
        total = #statuses,
        online = 0,
        offline = 0,
        degraded = 0,
        healthy = 0,
        unhealthy = 0,
        criticalOffline = 0,
        totalRequests = 0,
        avgResponseTime = 0,
        totalErrors = 0
    }
    
    local totalResponseTime = 0
    local responseTimeCount = 0
    
    for _, api in ipairs(statuses) do
        -- Count by status
        if api.status == 'online' then
            summary.online = summary.online + 1
        elseif api.status == 'offline' then
            summary.offline = summary.offline + 1
        elseif api.status == 'degraded' then
            summary.degraded = summary.degraded + 1
        end
        
        -- Count by health
        if api.healthStatus == 'healthy' then
            summary.healthy = summary.healthy + 1
        elseif api.healthStatus == 'unhealthy' then
            summary.unhealthy = summary.unhealthy + 1
        end
        
        -- Aggregate metrics
        summary.totalRequests = summary.totalRequests + (api.requestsToday or 0)
        
        if api.avgResponseTime and api.avgResponseTime > 0 then
            totalResponseTime = totalResponseTime + api.avgResponseTime
            responseTimeCount = responseTimeCount + 1
        end
        
        if api.errorCount then
            summary.totalErrors = summary.totalErrors + api.errorCount
        end
    end
    
    if responseTimeCount > 0 then
        summary.avgResponseTime = math.floor(totalResponseTime / responseTimeCount)
    end
    
    return summary
end)

Logger.Success('Host API Management Callbacks loaded', '📡')
