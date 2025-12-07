-- EC Admin Ultimate - Host API Management
-- Main logic for managing all API services
-- Author: NRG Development
-- Version: 1.0.0

-- List of all API services
local API_SERVICES = {
    {
        name = 'Global Ban API',
        key = 'global_bans',
        port = 3001,
        serviceName = 'global-ban-api',
        critical = true
    },
    {
        name = 'Analytics API',
        key = 'analytics',
        port = 3002,
        serviceName = 'analytics-api',
        critical = false
    },
    {
        name = 'Anticheat Sync API',
        key = 'anticheat_sync',
        port = 3003,
        serviceName = 'anticheat-sync-api',
        critical = true
    },
    {
        name = 'Authentication API',
        key = 'authentication',
        port = 3004,
        serviceName = 'authentication-api',
        critical = true
    },
    {
        name = 'Backup Storage API',
        key = 'backup_storage',
        port = 3005,
        serviceName = 'backup-storage-api',
        critical = false
    },
    {
        name = 'Config Sync API',
        key = 'config_sync',
        port = 3006,
        serviceName = 'config-sync-api',
        critical = false
    },
    {
        name = 'Emergency Control API',
        key = 'emergency_control',
        port = 3007,
        serviceName = 'emergency-control-api',
        critical = true
    },
    {
        name = 'Global Chat API',
        key = 'global_chat',
        port = 3008,
        serviceName = 'global-chat-api',
        critical = false
    },
    {
        name = 'License Validation API',
        key = 'license_validation',
        port = 3009,
        serviceName = 'license-validation-api',
        critical = true
    },
    {
        name = 'Marketplace Sync API',
        key = 'marketplace_sync',
        port = 3010,
        serviceName = 'marketplace-sync-api',
        critical = false
    },
    {
        name = 'Notification Hub API',
        key = 'notification_hub',
        port = 3011,
        serviceName = 'notification-hub-api',
        critical = false
    },
    {
        name = 'Performance Monitor API',
        key = 'performance_monitor',
        port = 3012,
        serviceName = 'performance-monitor-api',
        critical = false
    },
    {
        name = 'Player Tracking API',
        key = 'player_tracking',
        port = 3013,
        serviceName = 'player-tracking-api',
        critical = true
    },
    {
        name = 'Report System API',
        key = 'report_system',
        port = 3014,
        serviceName = 'report-system-api',
        critical = false
    },
    {
        name = 'Resource Hub API',
        key = 'resource_hub',
        port = 3015,
        serviceName = 'resource-hub-api',
        critical = false
    },
    {
        name = 'Screenshot Storage API',
        key = 'screenshot_storage',
        port = 3016,
        serviceName = 'screenshot-storage-api',
        critical = false
    },
    {
        name = 'Server Registry API',
        key = 'server_registry',
        port = 3017,
        serviceName = 'server-registry-api',
        critical = true
    },
    {
        name = 'Vehicle Registry API',
        key = 'vehicle_registry',
        port = 3018,
        serviceName = 'vehicle-registry-api',
        critical = false
    },
    {
        name = 'Webhook Relay API',
        key = 'webhook_relay',
        port = 3019,
        serviceName = 'webhook-relay-api',
        critical = false
    },
    {
        name = 'Master Gateway',
        key = 'master_gateway',
        port = 3000,
        serviceName = 'master-gateway',
        critical = true
    }
}

-- Get all API statuses
function GetAllAPIStatuses()
    local statuses = {}
    
    for _, api in ipairs(API_SERVICES) do
        local status = GetAPIStatus(api)
        table.insert(statuses, status)
    end
    
    return statuses
end

-- Get individual API status
function GetAPIStatus(api)
    -- Query database for API status
    local dbStatus = MySQL.scalar.await('SELECT status FROM ec_host_api_status WHERE api_key = ? LIMIT 1', {api.key})
    local dbMetrics = MySQL.single.await([[
        SELECT uptime_seconds, total_requests, requests_today, avg_response_time, 
               error_rate, version, last_restart, memory_usage_mb, cpu_usage_percent,
               active_connections, error_count_24h, warning_count_24h, auto_restart_enabled
        FROM ec_host_api_metrics 
        WHERE api_key = ? 
        ORDER BY timestamp DESC 
        LIMIT 1
    ]], {api.key})
    
    local status = {
        name = api.name,
        key = api.key,
        port = api.port,
        status = dbStatus or 'unknown',
        uptime = dbMetrics and dbMetrics.uptime_seconds or 0,
        requests = dbMetrics and dbMetrics.total_requests or 0,
        requestsToday = dbMetrics and dbMetrics.requests_today or 0,
        avgResponseTime = dbMetrics and dbMetrics.avg_response_time or 0,
        errorRate = dbMetrics and dbMetrics.error_rate or 0,
        version = dbMetrics and dbMetrics.version or '1.0.0',
        lastRestart = dbMetrics and dbMetrics.last_restart or nil,
        healthStatus = DetermineHealthStatus(dbMetrics),
        memoryUsage = dbMetrics and dbMetrics.memory_usage_mb or nil,
        cpuUsage = dbMetrics and dbMetrics.cpu_usage_percent or nil,
        activeConnections = dbMetrics and dbMetrics.active_connections or nil,
        errorCount = dbMetrics and dbMetrics.error_count_24h or nil,
        warningCount = dbMetrics and dbMetrics.warning_count_24h or nil,
        autoRestart = dbMetrics and (dbMetrics.auto_restart_enabled == 1) or false,
        enabled = true
    }
    
    return status
end

-- Determine health status from metrics
function DetermineHealthStatus(metrics)
    if not metrics then return 'unhealthy' end
    
    local errorRate = metrics.error_rate or 0
    local avgResponseTime = metrics.avg_response_time or 0
    
    if errorRate > 10 or avgResponseTime > 1000 then
        return 'unhealthy'
    elseif errorRate > 5 or avgResponseTime > 500 then
        return 'degraded'
    else
        return 'healthy'
    end
end

-- Start API service
function StartAPIService(apiKey, adminSource)
    local api = GetAPIByKey(apiKey)
    if not api then
        return false, 'API not found'
    end
    
    -- Log action
    LogHostAction(adminSource, 'api_start', apiKey, {
        apiName = api.name,
        port = api.port
    })
    
    -- Update database status
    MySQL.update.await('UPDATE ec_host_api_status SET status = ?, updated_at = UNIX_TIMESTAMP() WHERE api_key = ?', {
        'starting', apiKey
    })
    
    -- In production, this would trigger actual service start via system commands
    -- For now, we'll simulate it
    Logger.Info(string.format('🚀 Starting %s on port %d', api.name, api.port))
    
    -- Simulate async start
    SetTimeout(2000, function()
        MySQL.update.await('UPDATE ec_host_api_status SET status = ?, updated_at = UNIX_TIMESTAMP() WHERE api_key = ?', {
            'online', apiKey
        })
        
        -- Update metrics
        MySQL.insert.await([[
            INSERT INTO ec_host_api_metrics (api_key, uptime_seconds, version, timestamp)
            VALUES (?, 0, '1.0.0', UNIX_TIMESTAMP())
        ]], {apiKey})
        
        Logger.Success(string.format('✅ %s started successfully', api.name))
    end)
    
    return true, 'API start initiated'
end

-- Stop API service
function StopAPIService(apiKey, adminSource)
    local api = GetAPIByKey(apiKey)
    if not api then
        return false, 'API not found'
    end
    
    -- Log action
    LogHostAction(adminSource, 'api_stop', apiKey, {
        apiName = api.name,
        port = api.port
    })
    
    -- Update database status
    MySQL.update.await('UPDATE ec_host_api_status SET status = ?, updated_at = UNIX_TIMESTAMP() WHERE api_key = ?', {
        'stopping', apiKey
    })
    
    Logger.Info(string.format('⏹️ Stopping %s', api.name))
    
    -- Simulate async stop
    SetTimeout(1000, function()
        MySQL.update.await('UPDATE ec_host_api_status SET status = ?, updated_at = UNIX_TIMESTAMP() WHERE api_key = ?', {
            'offline', apiKey
        })
        
        Logger.Success(string.format('✅ %s stopped successfully', api.name))
    end)
    
    return true, 'API stop initiated'
end

-- Restart API service
function RestartAPIService(apiKey, adminSource)
    local api = GetAPIByKey(apiKey)
    if not api then
        return false, 'API not found'
    end
    
    -- Log action
    LogHostAction(adminSource, 'api_restart', apiKey, {
        apiName = api.name,
        port = api.port
    })
    
    -- Stop first
    MySQL.update.await('UPDATE ec_host_api_status SET status = ?, updated_at = UNIX_TIMESTAMP() WHERE api_key = ?', {
        'stopping', apiKey
    })
    
    Logger.Info(string.format('🔄 Restarting %s', api.name))
    
    -- Then start after delay
    SetTimeout(2000, function()
        MySQL.update.await('UPDATE ec_host_api_status SET status = ?, updated_at = UNIX_TIMESTAMP() WHERE api_key = ?', {
            'starting', apiKey
        })
        
        SetTimeout(2000, function()
            MySQL.update.await([[
                UPDATE ec_host_api_status SET status = ?, updated_at = UNIX_TIMESTAMP() WHERE api_key = ?
            ]], {'online', apiKey})
            
            -- Update last restart time
            MySQL.update.await([[
                UPDATE ec_host_api_metrics SET last_restart = UNIX_TIMESTAMP() WHERE api_key = ?
            ]], {apiKey})
            
            Logger.Success(string.format('✅ %s restarted successfully', api.name))
        end)
    end)
    
    return true, 'API restart initiated'
end

-- Toggle auto-restart
function ToggleAPIAutoRestart(apiKey, enabled, adminSource)
    -- Log action
    LogHostAction(adminSource, 'api_auto_restart_toggle', apiKey, {
        enabled = enabled
    })
    
    MySQL.update.await([[
        UPDATE ec_host_api_metrics SET auto_restart_enabled = ? WHERE api_key = ?
    ]], {enabled and 1 or 0, apiKey})
    
    return true, 'Auto-restart updated'
end

-- Start all APIs
function StartAllAPIs(adminSource)
    LogHostAction(adminSource, 'api_start_all', nil, {})
    
    local count = 0
    for _, api in ipairs(API_SERVICES) do
        StartAPIService(api.key, adminSource)
        count = count + 1
    end
    
    return true, string.format('Starting %d APIs', count)
end

-- Stop all APIs
function StopAllAPIs(adminSource)
    LogHostAction(adminSource, 'api_stop_all', nil, {})
    
    local count = 0
    for _, api in ipairs(API_SERVICES) do
        StopAPIService(api.key, adminSource)
        count = count + 1
    end
    
    return true, string.format('Stopping %d APIs', count)
end

-- Restart all APIs
function RestartAllAPIs(adminSource)
    LogHostAction(adminSource, 'api_restart_all', nil, {})
    
    local count = 0
    for _, api in ipairs(API_SERVICES) do
        -- Stagger restarts to avoid overload
        SetTimeout(count * 1000, function()
            RestartAPIService(api.key, adminSource)
        end)
        count = count + 1
    end
    
    return true, string.format('Restarting %d APIs', count)
end

-- Get API logs
function GetAPILogs(apiKey, limit)
    limit = limit or 100
    
    local logs = MySQL.query.await([[
        SELECT id, api_name, log_level, message, details, source, timestamp
        FROM ec_host_api_logs
        WHERE api_key = ?
        ORDER BY timestamp DESC
        LIMIT ?
    ]], {apiKey, limit})
    
    return logs or {}
end

-- Clear API logs
function ClearAPILogs(apiKey, adminSource)
    LogHostAction(adminSource, 'api_logs_clear', apiKey, {})
    
    MySQL.execute.await('DELETE FROM ec_host_api_logs WHERE api_key = ?', {apiKey})
    
    return true, 'Logs cleared'
end

-- Get API metrics
function GetAPIMetrics(apiKey, timeRange)
    timeRange = timeRange or 3600 -- Default 1 hour
    
    local metrics = MySQL.query.await([[
        SELECT api_key, uptime_seconds, total_requests, avg_response_time, 
               error_rate, memory_usage_mb, cpu_usage_percent, timestamp
        FROM ec_host_api_metrics
        WHERE api_key = ? AND timestamp >= UNIX_TIMESTAMP() - ?
        ORDER BY timestamp DESC
    ]], {apiKey, timeRange})
    
    return metrics or {}
end

-- Helper: Get API by key
function GetAPIByKey(key)
    for _, api in ipairs(API_SERVICES) do
        if api.key == key then
            return api
        end
    end
    return nil
end

-- Helper: Log host action
function LogHostAction(source, actionType, apiKey, details)
    local adminId = GetPlayerIdentifier(source, 0)
    local adminName = GetPlayerName(source)
    
    MySQL.insert.await([[
        INSERT INTO ec_host_action_logs (action_type, admin_id, admin_name, target_identifier, details, timestamp)
        VALUES (?, ?, ?, ?, ?, UNIX_TIMESTAMP())
    ]], {
        actionType,
        adminId,
        adminName,
        apiKey or '',
        json.encode(details)
    })
end

-- Exports
exports('GetAllAPIStatuses', GetAllAPIStatuses)
exports('GetAPIStatus', GetAPIStatus)
exports('StartAPIService', StartAPIService)
exports('StopAPIService', StopAPIService)
exports('RestartAPIService', RestartAPIService)
exports('ToggleAPIAutoRestart', ToggleAPIAutoRestart)
exports('StartAllAPIs', StartAllAPIs)
exports('StopAllAPIs', StopAllAPIs)
exports('RestartAllAPIs', RestartAllAPIs)
exports('GetAPILogs', GetAPILogs)
exports('ClearAPILogs', ClearAPILogs)
exports('GetAPIMetrics', GetAPIMetrics)

Logger.Success('Host API Management loaded', '🏢')
