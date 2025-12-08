--[[
    EC Admin Ultimate - System Management UI Backend
    Server-side logic for system management
    
    Handles:
    - system:getData: Get all system data (resources, server info, performance stats, recent actions, console logs, stats)
    - system:startResource: Start a resource
    - system:stopResource: Stop a resource
    - system:restartResource: Restart a resource
    - system:serverAnnouncement: Send server announcement
    - system:kickAllPlayers: Kick all players
    - system:clearCache: Clear cache
    - system:databaseCleanup: Cleanup database
    
    Framework Support: QB-Core, QBX, ESX
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[System Management] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[System Management] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local dataCache = {}
local CACHE_TTL = 10 -- Cache for 10 seconds
local serverStartTime = os.time()

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Get admin info
local function getAdminInfo(source)
    return {
        id = GetPlayerIdentifier(source, 0) or 'system',
        name = GetPlayerName(source) or 'System'
    }
end

-- Helper: Log system action
local function logSystemAction(adminId, adminName, actionType, target, details, success, errorMsg)
    MySQL.insert.await([[
        INSERT INTO ec_system_actions_log 
        (admin_id, admin_name, action_type, target, details, success, error_message, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        adminId, adminName, actionType, target,
        details and json.encode(details) or nil,
        success and 1 or 0, errorMsg, getCurrentTimestamp()
    })
end

-- Helper: Log console message
local function logConsoleMessage(logType, message, source)
    MySQL.insert.await([[
        INSERT INTO ec_system_console_logs 
        (log_type, message, source, created_at)
        VALUES (?, ?, ?, ?)
    ]], {logType, message, source or 'system', getCurrentTimestamp()})
    
    -- Keep only last 1000 logs
    MySQL.query.await([[
        DELETE FROM ec_system_console_logs 
        WHERE id NOT IN (
            SELECT id FROM (
                SELECT id FROM ec_system_console_logs 
                ORDER BY created_at DESC 
                LIMIT 1000
            ) AS temp
        )
    ]], {})
end

-- Helper: Get all resources
local function getAllResources()
    local resources = {}
    local resourceList = GetNumResources()
    
    for i = 0, resourceList - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local state = GetResourceState(resourceName)
            local metadata = GetResourceMetadata(resourceName, 'description', 0) or ''
            local version = GetResourceMetadata(resourceName, 'version', 0) or '1.0.0'
            local author = GetResourceMetadata(resourceName, 'author', 0) or 'Unknown'
            
            table.insert(resources, {
                name = resourceName,
                state = state,
                description = metadata,
                version = version,
                author = author
            })
        end
    end
    
    return resources
end

-- Helper: Get server info
local function getServerInfo()
    return {
        hostname = GetConvar('sv_hostname', 'FiveM Server'),
        maxPlayers = GetConvarInt('sv_maxclients', 32),
        currentPlayers = GetNumPlayerIndices() or 0,
        gametype = GetConvar('gametype', ''),
        mapname = GetConvar('mapname', ''),
        version = GetConvar('version', ''),
        build = GetConvar('sv_build', ''),
        scriptHookAllowed = GetConvar('sv_scriptHookAllowed', 'false') == 'true',
        oneSync = GetConvar('onesync', 'off'),
        txAdminAvailable = GetConvar('txAdmin-version', '') ~= ''
    }
end

-- Helper: Get performance stats
local function getPerformanceStats()
    local playerCount = GetNumPlayerIndices() or 0
    local resourceCount = GetNumResources()
    local uptime = getCurrentTimestamp() - serverStartTime
    
    -- Get server tick time (approximate)
    local tickTime = 0
    if GetGameTimer then
        -- This is a rough estimate
        tickTime = 16.67 -- Default tick time in ms
    end
    
    -- Get memory usage (approximate)
    local memoryUsage = 0
    -- Memory usage would need to be tracked separately or via external tools
    
    -- Get average ping
    local totalPing = 0
    local pingCount = 0
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            local ping = GetPlayerPing(source)
            if ping and ping > 0 then
                totalPing = totalPing + ping
                pingCount = pingCount + 1
            end
        end
    end
    local averagePing = pingCount > 0 and (totalPing / pingCount) or 0
    
    return {
        playerCount = playerCount,
        resourceCount = resourceCount,
        uptime = uptime,
        tickTime = tickTime,
        memoryUsage = memoryUsage,
        averagePing = math.floor(averagePing)
    }
end

-- Helper: Get recent actions
local function getRecentActions(limit)
    limit = limit or 50
    local actions = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_system_actions_log
        ORDER BY created_at DESC
        LIMIT ?
    ]], {limit})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(actions, {
                id = row.id,
                admin_name = row.admin_name,
                action_type = row.action_type,
                target = row.target,
                details = row.details,
                success = (row.success == 1 or row.success == true),
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at)
            })
        end
    end
    
    return actions
end

-- Helper: Get console logs
local function getConsoleLogs(limit)
    limit = limit or 500
    local logs = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_system_console_logs
        ORDER BY created_at DESC
        LIMIT ?
    ]], {limit})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(logs, {
                id = row.id,
                log_type = row.log_type,
                message = row.message,
                source = row.source,
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at)
            })
        end
    end
    
    return logs
end

-- Helper: Get scheduled restarts
local function getScheduledRestarts()
    local restarts = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_system_scheduled_restarts
        WHERE completed = 0
        ORDER BY scheduled_at ASC
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(restarts, {
                id = row.id,
                scheduled_by = row.scheduled_by_name,
                scheduled_at = row.scheduled_at,
                reason = row.reason,
                completed = (row.completed == 1 or row.completed == true)
            })
        end
    end
    
    return restarts
end

-- Helper: Get system data (shared logic)
local function getSystemData()
    -- Check cache
    if dataCache.data and (getCurrentTimestamp() - dataCache.timestamp) < CACHE_TTL then
        return dataCache.data
    end
    
    local resources = getAllResources()
    local serverInfo = getServerInfo()
    local performanceStats = getPerformanceStats()
    local recentActions = getRecentActions(50)
    local scheduledRestarts = getScheduledRestarts()
    local consoleLogs = getConsoleLogs(500)
    
    -- Calculate statistics
    local stats = {
        totalResources = #resources,
        runningResources = 0,
        stoppedResources = 0,
        totalActions = #recentActions,
        scheduledRestarts = #scheduledRestarts,
        uptime = performanceStats.uptime,
        playerCount = performanceStats.playerCount,
        memoryUsage = performanceStats.memoryUsage
    }
    
    for _, resource in ipairs(resources) do
        if resource.state == 'started' then
            stats.runningResources = stats.runningResources + 1
        else
            stats.stoppedResources = stats.stoppedResources + 1
        end
    end
    
    local data = {
        resources = resources,
        serverInfo = serverInfo,
        performanceStats = performanceStats,
        recentActions = recentActions,
        scheduledRestarts = scheduledRestarts,
        consoleLogs = consoleLogs,
        stats = stats,
        framework = getFramework()
    }
    
    -- Cache data
    dataCache = {
        data = data,
        timestamp = getCurrentTimestamp()
    }
    
    return data
end

-- ============================================================================
-- REGISTERNUICALLBACK HANDLERS (Direct fetch from UI)
-- ============================================================================

-- Callback: Get system data
RegisterNUICallback('system:getData', function(data, cb)
    local response = getSystemData()
    cb({ success = true, data = response })
end)

-- Callback: Start resource
RegisterNUICallback('system:startResource', function(data, cb)
    local resourceName = data.resourceName
    
    if not resourceName then
        cb({ success = false, message = 'Resource name required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Resource started successfully'
    
    local currentState = GetResourceState(resourceName)
    if currentState == 'started' then
        cb({ success = false, message = 'Resource is already started' })
        return
    end
    
    -- Start resource
    StartResource(resourceName)
    
    -- Wait a moment and check
    Wait(500)
    local newState = GetResourceState(resourceName)
    success = (newState == 'started')
    
    -- Log action
    logSystemAction(adminInfo.id, adminInfo.name, 'start_resource', resourceName, nil, success, success and nil or 'Failed to start resource')
    
    -- Log console message
    if success then
        logConsoleMessage('info', string.format('Resource %s started by %s', resourceName, adminInfo.name), resourceName)
    else
        logConsoleMessage('error', string.format('Failed to start resource %s', resourceName), resourceName)
    end
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to start resource' })
end)

-- Callback: Stop resource
RegisterNUICallback('system:stopResource', function(data, cb)
    local resourceName = data.resourceName
    
    if not resourceName then
        cb({ success = false, message = 'Resource name required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Resource stopped successfully'
    
    local currentState = GetResourceState(resourceName)
    if currentState == 'stopped' then
        cb({ success = false, message = 'Resource is already stopped' })
        return
    end
    
    -- Prevent stopping this resource
    if resourceName == GetCurrentResourceName() then
        cb({ success = false, message = 'Cannot stop this resource' })
        return
    end
    
    -- Stop resource
    StopResource(resourceName)
    
    -- Wait a moment and check
    Wait(500)
    local newState = GetResourceState(resourceName)
    success = (newState == 'stopped')
    
    -- Log action
    logSystemAction(adminInfo.id, adminInfo.name, 'stop_resource', resourceName, nil, success, success and nil or 'Failed to stop resource')
    
    -- Log console message
    if success then
        logConsoleMessage('info', string.format('Resource %s stopped by %s', resourceName, adminInfo.name), resourceName)
    else
        logConsoleMessage('error', string.format('Failed to stop resource %s', resourceName), resourceName)
    end
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to stop resource' })
end)

-- Callback: Restart resource
RegisterNUICallback('system:restartResource', function(data, cb)
    local resourceName = data.resourceName
    
    if not resourceName then
        cb({ success = false, message = 'Resource name required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Resource restarted successfully'
    
    -- Prevent restarting this resource
    if resourceName == GetCurrentResourceName() then
        cb({ success = false, message = 'Cannot restart this resource' })
        return
    end
    
    -- Restart resource
    StopResource(resourceName)
    Wait(1000)
    StartResource(resourceName)
    
    -- Wait a moment and check
    Wait(500)
    local newState = GetResourceState(resourceName)
    success = (newState == 'started')
    
    -- Log action
    logSystemAction(adminInfo.id, adminInfo.name, 'restart_resource', resourceName, nil, success, success and nil or 'Failed to restart resource')
    
    -- Log console message
    if success then
        logConsoleMessage('info', string.format('Resource %s restarted by %s', resourceName, adminInfo.name), resourceName)
    else
        logConsoleMessage('error', string.format('Failed to restart resource %s', resourceName), resourceName)
    end
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to restart resource' })
end)

-- Callback: Server announcement
RegisterNUICallback('system:serverAnnouncement', function(data, cb)
    local message = data.message
    local duration = tonumber(data.duration) or 10000
    
    if not message then
        cb({ success = false, message = 'Message required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = true
    local message_text = 'Announcement sent successfully'
    
    -- Send announcement to all players
    TriggerClientEvent('chat:addMessage', -1, {
        color = {255, 255, 0},
        multiline = true,
        args = {'[SERVER]', message}
    })
    
    -- Log action
    logSystemAction(adminInfo.id, adminInfo.name, 'announcement', 'all', {
        message = message,
        duration = duration
    }, success, nil)
    
    -- Log console message
    logConsoleMessage('info', string.format('Server announcement by %s: %s', adminInfo.name, message), 'system')
    
    cb({ success = success, message = message_text })
end)

-- Callback: Kick all players
RegisterNUICallback('system:kickAllPlayers', function(data, cb)
    local reason = data.reason or 'Server maintenance'
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = true
    local message_text = 'All players kicked successfully'
    local playerCount = 0
    
    -- Kick all players
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            DropPlayer(source, reason)
            playerCount = playerCount + 1
        end
    end
    
    -- Log action
    logSystemAction(adminInfo.id, adminInfo.name, 'kick_all', tostring(playerCount), {
        reason = reason
    }, success, nil)
    
    -- Log console message
    logConsoleMessage('warning', string.format('All players kicked by %s: %s (%d players)', adminInfo.name, reason, playerCount), 'system')
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = message_text })
end)

-- Callback: Clear cache
RegisterNUICallback('system:clearCache', function(data, cb)
    local adminInfo = { id = 'system', name = 'System' }
    local success = true
    local message_text = 'Cache cleared successfully'
    
    -- Clear data cache
    dataCache = {}
    
    -- Log action
    logSystemAction(adminInfo.id, adminInfo.name, 'clear_cache', 'all', nil, success, nil)
    
    -- Log console message
    logConsoleMessage('info', string.format('Cache cleared by %s', adminInfo.name), 'system')
    
    cb({ success = success, message = message_text })
end)

-- Callback: Database cleanup
RegisterNUICallback('system:databaseCleanup', function(data, cb)
    local days = tonumber(data.days) or 30
    local cutoffTime = getCurrentTimestamp() - (days * 86400)
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message_text = 'Database cleanup completed successfully'
    local deletedCount = 0
    
    -- Cleanup old console logs
    local result = MySQL.query.await([[
        DELETE FROM ec_system_console_logs 
        WHERE created_at < ?
    ]], {cutoffTime})
    
    if result then
        deletedCount = deletedCount + (result.affectedRows or 0)
    end
    
    -- Cleanup old action logs (keep last 1000)
    MySQL.query.await([[
        DELETE FROM ec_system_actions_log 
        WHERE id NOT IN (
            SELECT id FROM (
                SELECT id FROM ec_system_actions_log 
                ORDER BY created_at DESC 
                LIMIT 1000
            ) AS temp
        ) AND created_at < ?
    ]], {cutoffTime})
    
    success = true
    
    -- Log action
    logSystemAction(adminInfo.id, adminInfo.name, 'database_cleanup', tostring(days), {
        days = days,
        deleted_count = deletedCount
    }, success, nil)
    
    -- Log console message
    logConsoleMessage('info', string.format('Database cleanup by %s: %d days, %d records deleted', adminInfo.name, days, deletedCount), 'system')
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = message_text })
end)

print("^2[System Management]^7 UI Backend loaded^0")

