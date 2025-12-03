--[[
    EC Admin Ultimate - Metrics Database Persistence
    Production-ready metrics tracking with database storage
    
    Features:
    - Real-time metrics sampling (every 60s)
    - Database persistence for historical data
    - Action logging for admin accountability
    - Automatic cleanup of old data (30 days retention)
]]

local MetricsDB = {
    initialized = false,
    lastCleanup = 0,
    cleanupInterval = 3600000, -- 1 hour
    dataRetention = 30 * 24 * 60 * 60 -- 30 days in seconds
}

-- ============================================================================
-- DATABASE SCHEMA VERIFICATION (Failsafe - auto-setup creates these first)
-- ============================================================================

local function InitializeMetricsTables()
    if not MySQL then
        print('^1[Metrics DB] MySQL not available^0')
        return false
    end
    
    -- Note: database-auto-setup.lua creates these tables on startup
    -- This is a failsafe check to ensure they exist
    
    -- Create metrics history table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ec_admin_metrics_history` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `timestamp` BIGINT NOT NULL,
            `players_online` INT NOT NULL DEFAULT 0,
            `max_players` INT NOT NULL DEFAULT 64,
            `avg_ping` INT NOT NULL DEFAULT 0,
            `max_ping` INT NOT NULL DEFAULT 0,
            `memory_mb` FLOAT NOT NULL DEFAULT 0,
            `resources_started` INT NOT NULL DEFAULT 0,
            `resources_total` INT NOT NULL DEFAULT 0,
            `tps` INT NOT NULL DEFAULT 60,
            `metadata` LONGTEXT DEFAULT NULL,
            INDEX `idx_timestamp` (`timestamp`),
            INDEX `idx_players` (`players_online`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Create webhook tracking table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ec_admin_webhook_logs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `webhook_url` VARCHAR(255) NOT NULL,
            `webhook_type` VARCHAR(50) NOT NULL,
            `event_type` VARCHAR(100) NOT NULL,
            `status_code` INT DEFAULT NULL,
            `success` BOOLEAN DEFAULT FALSE,
            `error_message` TEXT DEFAULT NULL,
            `payload_size` INT DEFAULT 0,
            `response_time_ms` INT DEFAULT NULL,
            `timestamp` BIGINT NOT NULL,
            INDEX `idx_timestamp` (`timestamp`),
            INDEX `idx_webhook_type` (`webhook_type`),
            INDEX `idx_success` (`success`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    -- Create API usage tracking table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ec_admin_api_usage` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `api_name` VARCHAR(100) NOT NULL,
            `endpoint` VARCHAR(255) NOT NULL,
            `method` VARCHAR(10) NOT NULL DEFAULT 'GET',
            `status_code` INT DEFAULT NULL,
            `success` BOOLEAN DEFAULT FALSE,
            `response_time_ms` INT DEFAULT NULL,
            `error_message` TEXT DEFAULT NULL,
            `timestamp` BIGINT NOT NULL,
            INDEX `idx_timestamp` (`timestamp`),
            INDEX `idx_api_name` (`api_name`),
            INDEX `idx_success` (`success`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
    
    print('^2[Metrics DB] ✅ Database tables initialized^0')
    MetricsDB.initialized = true
    return true
end

-- ============================================================================
-- METRICS PERSISTENCE
-- ============================================================================

-- Save metrics snapshot to database
function MetricsDB.SaveSnapshot(snapshot)
    if not MySQL or not MetricsDB.initialized then return false end
    
    MySQL.insert([[
        INSERT INTO ec_admin_metrics_history 
        (timestamp, players_online, max_players, avg_ping, max_ping, memory_mb, resources_started, resources_total, tps, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        os.time(),
        snapshot.players or 0,
        snapshot.maxPlayers or 64,
        snapshot.avgPing or 0,
        snapshot.maxPing or 0,
        snapshot.memory or 0,
        snapshot.resources and snapshot.resources.started or 0,
        snapshot.resources and snapshot.resources.total or 0,
        snapshot.tps or 60,
        snapshot.metadata and json.encode(snapshot.metadata) or nil
    })
    
    return true
end

-- Get metrics history from database
function MetricsDB.GetHistory(hours)
    if not MySQL or not MetricsDB.initialized then
        return {success = false, error = 'Database not initialized', data = {}}
    end
    
    hours = hours or 24 -- Default 24 hours
    local sinceTimestamp = os.time() - (hours * 3600)
    
    local result = MySQL.query.await([[
        SELECT * FROM ec_admin_metrics_history
        WHERE timestamp >= ?
        ORDER BY timestamp ASC
    ]], {sinceTimestamp})
    
    return {
        success = true,
        data = result or {},
        count = #(result or {}),
        hours = hours
    }
end

-- Get aggregated metrics stats
function MetricsDB.GetStats(hours)
    if not MySQL or not MetricsDB.initialized then
        return {success = false, error = 'Database not initialized'}
    end
    
    hours = hours or 24
    local sinceTimestamp = os.time() - (hours * 3600)
    
    local result = MySQL.query.await([[
        SELECT 
            COUNT(*) as sample_count,
            AVG(players_online) as avg_players,
            MAX(players_online) as peak_players,
            MIN(players_online) as min_players,
            AVG(avg_ping) as avg_ping,
            MAX(max_ping) as peak_ping,
            AVG(memory_mb) as avg_memory,
            MAX(memory_mb) as peak_memory
        FROM ec_admin_metrics_history
        WHERE timestamp >= ?
    ]], {sinceTimestamp})
    
    if result and result[1] then
        return {
            success = true,
            stats = result[1],
            hours = hours
        }
    end
    
    return {success = false, error = 'No data available'}
end

-- ============================================================================
-- WEBHOOK TRACKING
-- ============================================================================

function MetricsDB.LogWebhookExecution(webhookData)
    if not MySQL or not MetricsDB.initialized then return false end
    
    MySQL.insert([[
        INSERT INTO ec_admin_webhook_logs
        (webhook_url, webhook_type, event_type, status_code, success, error_message, payload_size, response_time_ms, timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        webhookData.url or '',
        webhookData.type or 'unknown',
        webhookData.event or 'unknown',
        webhookData.statusCode,
        webhookData.success and 1 or 0,
        webhookData.error,
        webhookData.payloadSize or 0,
        webhookData.responseTime,
        os.time()
    })
    
    return true
end

function MetricsDB.GetWebhookStats(hours)
    if not MySQL or not MetricsDB.initialized then
        return {success = false, executions24h = 0, successRate = 0}
    end
    
    hours = hours or 24
    local sinceTimestamp = os.time() - (hours * 3600)
    
    local result = MySQL.query.await([[
        SELECT 
            COUNT(*) as total_executions,
            SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful,
            AVG(response_time_ms) as avg_response_time
        FROM ec_admin_webhook_logs
        WHERE timestamp >= ?
    ]], {sinceTimestamp})
    
    if result and result[1] then
        local stats = result[1]
        return {
            success = true,
            executions24h = stats.total_executions or 0,
            successful = stats.successful or 0,
            failed = (stats.total_executions or 0) - (stats.successful or 0),
            successRate = stats.total_executions > 0 and math.floor((stats.successful / stats.total_executions) * 100) or 0,
            avgResponseTime = stats.avg_response_time and math.floor(stats.avg_response_time) or 0
        }
    end
    
    return {success = false, executions24h = 0, successRate = 0}
end

-- ============================================================================
-- API USAGE TRACKING
-- ============================================================================

function MetricsDB.LogAPICall(apiData)
    if not MySQL or not MetricsDB.initialized then return false end
    
    MySQL.insert([[
        INSERT INTO ec_admin_api_usage
        (api_name, endpoint, method, status_code, success, response_time_ms, error_message, timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        apiData.apiName or 'unknown',
        apiData.endpoint or '',
        apiData.method or 'GET',
        apiData.statusCode,
        apiData.success and 1 or 0,
        apiData.responseTime,
        apiData.error,
        os.time()
    })
    
    return true
end

function MetricsDB.GetAPIStats(hours)
    if not MySQL or not MetricsDB.initialized then
        return {success = false, totalCalls = 0, successRate = 0}
    end
    
    hours = hours or 24
    local sinceTimestamp = os.time() - (hours * 3600)
    
    local result = MySQL.query.await([[
        SELECT 
            api_name,
            COUNT(*) as total_calls,
            SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful,
            AVG(response_time_ms) as avg_response_time
        FROM ec_admin_api_usage
        WHERE timestamp >= ?
        GROUP BY api_name
    ]], {sinceTimestamp})
    
    return {
        success = true,
        apis = result or {},
        totalCalls = #(result or {})
    }
end

-- ============================================================================
-- ADMIN ACTION LOGGING
-- ============================================================================

function MetricsDB.LogAdminAction(actionData)
    if not MySQL then return false end
    
    MySQL.insert([[
        INSERT INTO ec_admin_action_logs
        (admin_identifier, admin_name, action, category, target_identifier, target_name, details, metadata, timestamp, action_type)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        actionData.adminIdentifier or '',
        actionData.adminName or 'System',
        actionData.action or 'unknown',
        actionData.category or 'general',
        actionData.targetIdentifier,
        actionData.targetName,
        actionData.details,
        actionData.metadata and json.encode(actionData.metadata) or nil,
        os.time(),
        actionData.actionType or actionData.category
    })
    
    return true
end

-- ============================================================================
-- DATA CLEANUP
-- ============================================================================

function MetricsDB.CleanupOldData()
    if not MySQL or not MetricsDB.initialized then return false end
    
    local cutoffTimestamp = os.time() - MetricsDB.dataRetention
    
    -- Clean metrics
    MySQL.query('DELETE FROM ec_admin_metrics_history WHERE timestamp < ?', {cutoffTimestamp})
    
    -- Clean webhooks
    MySQL.query('DELETE FROM ec_admin_webhook_logs WHERE timestamp < ?', {cutoffTimestamp})
    
    -- Clean API logs
    MySQL.query('DELETE FROM ec_admin_api_usage WHERE timestamp < ?', {cutoffTimestamp})
    
    print(string.format('^2[Metrics DB] ✅ Cleaned data older than %d days^0', MetricsDB.dataRetention / 86400))
    return true
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

CreateThread(function()
    Wait(5000) -- Wait for MySQL
    
    if InitializeMetricsTables() then
        print('^2[Metrics DB] 📊 Metrics database system initialized^0')
        
        -- Cleanup thread
        CreateThread(function()
            while true do
                Wait(MetricsDB.cleanupInterval)
                MetricsDB.CleanupOldData()
            end
        end)
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

_G.MetricsDB = MetricsDB

return MetricsDB
