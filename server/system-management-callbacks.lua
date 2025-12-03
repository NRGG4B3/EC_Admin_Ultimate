--[[
    EC Admin Ultimate - System Management Callbacks
    Complete system control: resources, performance, server control, database management
]]

local QBCore = nil
local ESX = nil
local Framework = 'unknown'

-- Initialize framework
CreateThread(function()
    Wait(1000)
    
    if GetResourceState('qbx_core') == 'started' then
        QBCore = exports.qbx_core -- QBX uses direct export
        Framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
    else
        Framework = 'standalone'
    end
    
    Logger.Info('System Management Initialized: ' .. Framework)
end)

-- Create system management tables
CreateThread(function()
    Wait(2000)
    
    -- Use modern async MySQL API with error handling
    local success1, err1 = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS ec_system_actions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                admin_id VARCHAR(50) NOT NULL,
                admin_name VARCHAR(100) NOT NULL,
                action_type VARCHAR(50) NOT NULL,
                target VARCHAR(255) NULL,
                details TEXT NULL,
                success BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_admin (admin_id),
                INDEX idx_action (action_type),
                INDEX idx_created (created_at)
            )
        ]], {})
    end)
    
    if not success1 then
        Logger.Info('' .. tostring(err1) .. '^0')
    end
    
    local success2, err2 = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS ec_server_restarts (
                id INT AUTO_INCREMENT PRIMARY KEY,
                scheduled_by VARCHAR(100) NOT NULL,
                scheduled_time TIMESTAMP NOT NULL,
                reason TEXT NULL,
                status ENUM('scheduled', 'completed', 'cancelled') DEFAULT 'scheduled',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_status (status),
                INDEX idx_scheduled (scheduled_time)
            )
        ]], {})
    end)
    
    if not success2 then
        Logger.Info('' .. tostring(err2) .. '^0')
    end
    
    local success3, err3 = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS ec_console_logs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                log_type ENUM('info', 'warning', 'error', 'debug') DEFAULT 'info',
                message TEXT NOT NULL,
                source VARCHAR(100) NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_type (log_type),
                INDEX idx_created (created_at)
            )
        ]], {})
    end)
    
    if not success3 then
        Logger.Info('' .. tostring(err3) .. '^0')
    else
        Logger.Info('✅ System Management tables initialized')
    end
end)

-- Performance tracking
local PerformanceData = {
    cpu = 0,
    memory = 0,
    fps = 0,
    ping = {},
    playerCount = 0,
    tickTime = 0,
    resourceCount = 0,
    uptime = 0
}

-- Resource monitoring
local ResourceStats = {}

-- Helper function to get player identifier
local function GetPlayerIdentifier(src)
    if Framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'qb-core' then
        local Player = QBCore.Functions.GetPlayer(src)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier or nil
    else
        return GetPlayerIdentifiers(src)[1] or nil
    end
end

-- Helper: Log system action
local function LogAction(adminSrc, actionType, target, details, success)
    local adminId = GetPlayerIdentifier(adminSrc)
    local adminName = GetPlayerName(adminSrc)
    
    MySQL.Async.execute([[
        INSERT INTO ec_system_actions (admin_id, admin_name, action_type, target, details, success)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {adminId, adminName, actionType, target, details, success})
end

-- Helper: Log to console
local function LogToConsole(logType, message, source)
    MySQL.Async.execute([[
        INSERT INTO ec_console_logs (log_type, message, source)
        VALUES (?, ?, ?)
    ]], {logType, message, source})
end

-- Get all system data
lib.callback.register('ec_admin:getSystemData', function(source, _)
    local src = source
    -- Get all resources
    local resources = {}
    local resourceCount = GetNumResources()
    for i = 0, resourceCount - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local state = GetResourceState(resourceName)
            local metadata = GetResourceMetadata(resourceName, 'description', 0) or 'No description'
            local version = GetResourceMetadata(resourceName, 'version', 0) or 'Unknown'
            local author = GetResourceMetadata(resourceName, 'author', 0) or 'Unknown'
            table.insert(resources, { name = resourceName, state = state, description = metadata, version = version, author = author })
        end
    end
    local serverInfo = {
        hostname = GetConvar('sv_hostname', 'Unknown Server'),
        maxPlayers = GetConvarInt('sv_maxclients', 48),
        currentPlayers = #GetPlayers(),
        gametype = GetConvar('gametype', 'FiveM'),
        mapname = GetConvar('mapname', 'San Andreas'),
        version = GetConvar('version', 'Unknown'),
        build = GetConvar('sv_enforceGameBuild', 'Unknown'),
        scriptHookAllowed = GetConvar('sv_scriptHookAllowed', '0') == '1',
        oneSync = GetConvar('onesync', 'off'),
        txAdminAvailable = GetResourceState('monitor') == 'started'
    }
    local performanceStats = {
        playerCount = #GetPlayers(),
        resourceCount = resourceCount,
        uptime = os.time() - GlobalState.serverStartTime or 0,
        tickTime = PerformanceData.tickTime,
        memoryUsage = collectgarbage('count') / 1024,
        averagePing = 0
    }
    local totalPing = 0
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        totalPing = totalPing + GetPlayerPing(playerId)
    end
    if #players > 0 then
        performanceStats.averagePing = totalPing / #players
    end
    local recentActions = MySQL.Sync.fetchAll([[SELECT * FROM ec_system_actions ORDER BY created_at DESC LIMIT 100]], {})
    local scheduledRestarts = MySQL.Sync.fetchAll([[SELECT * FROM ec_server_restarts WHERE status = 'scheduled' AND scheduled_time > NOW() ORDER BY scheduled_time ASC]], {})
    local consoleLogs = MySQL.Sync.fetchAll([[SELECT * FROM ec_console_logs ORDER BY created_at DESC LIMIT 500]], {})
    local stats = { totalResources = resourceCount, runningResources = 0, stoppedResources = 0, totalActions = #recentActions, scheduledRestarts = #scheduledRestarts, uptime = performanceStats.uptime, playerCount = performanceStats.playerCount, memoryUsage = performanceStats.memoryUsage }
    for _, resource in ipairs(resources) do
        if resource.state == 'started' or resource.state == 'starting' then
            stats.runningResources = stats.runningResources + 1
        else
            stats.stoppedResources = stats.stoppedResources + 1
        end
    end
    return { success = true, data = { resources = resources, serverInfo = serverInfo, performanceStats = performanceStats, recentActions = recentActions, scheduledRestarts = scheduledRestarts, consoleLogs = consoleLogs, stats = stats, framework = Framework } }
end)

RegisterNetEvent('ec_admin_ultimate:server:getSystemData', function()
    local src = source
    
    -- Get all resources
    local resources = {}
    local resourceCount = GetNumResources()
    
    for i = 0, resourceCount - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local state = GetResourceState(resourceName)
            local metadata = GetResourceMetadata(resourceName, 'description', 0) or 'No description'
            local version = GetResourceMetadata(resourceName, 'version', 0) or 'Unknown'
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
    
    -- Get server info
    local serverInfo = {
        hostname = GetConvar('sv_hostname', 'Unknown Server'),
        maxPlayers = GetConvarInt('sv_maxclients', 48),
        currentPlayers = #GetPlayers(),
        gametype = GetConvar('gametype', 'FiveM'),
        mapname = GetConvar('mapname', 'San Andreas'),
        version = GetConvar('version', 'Unknown'),
        build = GetConvar('sv_enforceGameBuild', 'Unknown'),
        scriptHookAllowed = GetConvar('sv_scriptHookAllowed', '0') == '1',
        oneSync = GetConvar('onesync', 'off'),
        txAdminAvailable = GetResourceState('monitor') == 'started'
    }
    
    -- Get performance data
    local performanceStats = {
        playerCount = #GetPlayers(),
        resourceCount = resourceCount,
        uptime = os.time() - GlobalState.serverStartTime or 0,
        tickTime = PerformanceData.tickTime,
        memoryUsage = collectgarbage('count') / 1024, -- MB
        averagePing = 0
    }
    
    -- Calculate average ping
    local totalPing = 0
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        totalPing = totalPing + GetPlayerPing(playerId)
    end
    if #players > 0 then
        performanceStats.averagePing = totalPing / #players
    end
    
    -- Get recent actions
    local recentActions = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_system_actions 
        ORDER BY created_at DESC 
        LIMIT 100
    ]], {})
    
    -- Get scheduled restarts
    local scheduledRestarts = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_server_restarts 
        WHERE status = 'scheduled' AND scheduled_time > NOW()
        ORDER BY scheduled_time ASC
    ]], {})
    
    -- Get console logs
    local consoleLogs = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_console_logs 
        ORDER BY created_at DESC 
        LIMIT 500
    ]], {})
    
    -- Calculate stats
    local stats = {
        totalResources = resourceCount,
        runningResources = 0,
        stoppedResources = 0,
        totalActions = #recentActions,
        scheduledRestarts = #scheduledRestarts,
        uptime = performanceStats.uptime,
        playerCount = performanceStats.playerCount,
        memoryUsage = performanceStats.memoryUsage
    }
    
    for _, resource in ipairs(resources) do
        if resource.state == 'started' or resource.state == 'starting' then
            stats.runningResources = stats.runningResources + 1
        else
            stats.stoppedResources = stats.stoppedResources + 1
        end
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:receiveSystemData', src, {
        success = true,
        data = {
            resources = resources,
            serverInfo = serverInfo,
            performanceStats = performanceStats,
            recentActions = recentActions,
            scheduledRestarts = scheduledRestarts,
            consoleLogs = consoleLogs,
            stats = stats,
            framework = Framework
        }
    })
end)

-- Start resource
lib.callback.register('ec_admin:startResource', function(source, data)
    local src = source
    local resourceName = data and data.resourceName
    if not resourceName then
        return { success = false, message = 'Invalid resource name' }
    end
    if GetResourceState(resourceName) == 'missing' then
        LogAction(src, 'start_resource', resourceName, 'Failed: Resource not found', false)
        return { success = false, message = 'Resource not found: ' .. resourceName }
    end
    local ok = StartResource(resourceName)
    if ok then
        LogAction(src, 'start_resource', resourceName, 'Successfully started', true)
        LogToConsole('info', 'Resource started: ' .. resourceName, GetPlayerName(src))
        return { success = true, message = 'Resource started: ' .. resourceName }
    else
        LogAction(src, 'start_resource', resourceName, 'Failed to start', false)
        return { success = false, message = 'Failed to start resource: ' .. resourceName }
    end
end)

RegisterNetEvent('ec_admin_ultimate:server:startResource', function(data)
    local src = source
    local resourceName = data.resourceName
    
    if not resourceName then
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = false,
            message = 'Invalid resource name'
        })
        return
    end
    
    -- Check if resource exists
    if GetResourceState(resourceName) == 'missing' then
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = false,
            message = 'Resource not found: ' .. resourceName
        })
        LogAction(src, 'start_resource', resourceName, 'Failed: Resource not found', false)
        return
    end
    
    -- Start resource
    local success = StartResource(resourceName)
    
    if success then
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = true,
            message = 'Resource started: ' .. resourceName
        })
        LogAction(src, 'start_resource', resourceName, 'Successfully started', true)
        LogToConsole('info', 'Resource started: ' .. resourceName, GetPlayerName(src))
    else
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = false,
            message = 'Failed to start resource: ' .. resourceName
        })
        LogAction(src, 'start_resource', resourceName, 'Failed to start', false)
    end
end)

-- Stop resource
lib.callback.register('ec_admin:stopResource', function(source, data)
    local src = source
    local resourceName = data and data.resourceName
    if not resourceName then
        return { success = false, message = 'Invalid resource name' }
    end
    local protectedResources = { 'ec_admin_ultimate', 'monitor', 'sessionmanager', 'hardcap', 'rconlog', 'baseevents', 'chat', 'spawnmanager' }
    for _, protected in ipairs(protectedResources) do
        if resourceName == protected then
            LogAction(src, 'stop_resource', resourceName, 'Failed: Protected resource', false)
            return { success = false, message = 'Cannot stop protected resource: ' .. resourceName }
        end
    end
    local ok = StopResource(resourceName)
    if ok then
        LogAction(src, 'stop_resource', resourceName, 'Successfully stopped', true)
        LogToConsole('info', 'Resource stopped: ' .. resourceName, GetPlayerName(src))
        return { success = true, message = 'Resource stopped: ' .. resourceName }
    else
        LogAction(src, 'stop_resource', resourceName, 'Failed to stop', false)
        return { success = false, message = 'Failed to stop resource: ' .. resourceName }
    end
end)

RegisterNetEvent('ec_admin_ultimate:server:stopResource', function(data)
    local src = source
    local resourceName = data.resourceName
    
    if not resourceName then
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = false,
            message = 'Invalid resource name'
        })
        return
    end
    
    -- Protect critical resources
    local protectedResources = {
        'ec_admin_ultimate',
        'monitor',
        'sessionmanager',
        'hardcap',
        'rconlog',
        'baseevents',
        'chat',
        'spawnmanager'
    }
    
    for _, protected in ipairs(protectedResources) do
        if resourceName == protected then
            TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
                success = false,
                message = 'Cannot stop protected resource: ' .. resourceName
            })
            LogAction(src, 'stop_resource', resourceName, 'Failed: Protected resource', false)
            return
        end
    end
    
    -- Stop resource
    local success = StopResource(resourceName)
    
    if success then
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = true,
            message = 'Resource stopped: ' .. resourceName
        })
        LogAction(src, 'stop_resource', resourceName, 'Successfully stopped', true)
        LogToConsole('info', 'Resource stopped: ' .. resourceName, GetPlayerName(src))
    else
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = false,
            message = 'Failed to stop resource: ' .. resourceName
        })
        LogAction(src, 'stop_resource', resourceName, 'Failed to stop', false)
    end
end)

-- Restart resource
lib.callback.register('ec_admin:restartResource', function(source, data)
    local src = source
    local resourceName = data and data.resourceName
    if not resourceName then
        return { success = false, message = 'Invalid resource name' }
    end
    if GetResourceState(resourceName) == 'missing' then
        return { success = false, message = 'Resource not found: ' .. resourceName }
    end
    StopResource(resourceName)
    Wait(500)
    local ok = StartResource(resourceName)
    if ok then
        LogAction(src, 'restart_resource', resourceName, 'Successfully restarted', true)
        LogToConsole('info', 'Resource restarted: ' .. resourceName, GetPlayerName(src))
        return { success = true, message = 'Resource restarted: ' .. resourceName }
    else
        LogAction(src, 'restart_resource', resourceName, 'Failed to restart', false)
        return { success = false, message = 'Failed to restart resource: ' .. resourceName }
    end
end)

RegisterNetEvent('ec_admin_ultimate:server:restartResource', function(data)
    local src = source
    local resourceName = data.resourceName
    
    if not resourceName then
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = false,
            message = 'Invalid resource name'
        })
        return
    end
    
    -- Check if resource exists
    if GetResourceState(resourceName) == 'missing' then
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = false,
            message = 'Resource not found: ' .. resourceName
        })
        return
    end
    
    -- Restart resource
    StopResource(resourceName)
    Wait(500)
    local success = StartResource(resourceName)
    
    if success then
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = true,
            message = 'Resource restarted: ' .. resourceName
        })
        LogAction(src, 'restart_resource', resourceName, 'Successfully restarted', true)
        LogToConsole('info', 'Resource restarted: ' .. resourceName, GetPlayerName(src))
    else
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = false,
            message = 'Failed to restart resource: ' .. resourceName
        })
        LogAction(src, 'restart_resource', resourceName, 'Failed to restart', false)
    end
end)

-- Server announcement
RegisterNetEvent('ec_admin_ultimate:server:serverAnnouncement', function(data)
    local src = source
    local message = data.message
    local duration = tonumber(data.duration) or 10000
    
    if not message then
        TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
            success = false,
            message = 'Invalid announcement message'
        })
        return
    end
    
    -- Send announcement to all players
    TriggerClientEvent('ec_admin_ultimate:client:serverAnnouncement', -1, {
        message = message,
        duration = duration,
        admin = GetPlayerName(src)
    })
    
    TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
        success = true,
        message = 'Announcement sent to all players'
    })
    
    LogAction(src, 'server_announcement', nil, message, true)
    LogToConsole('info', 'Server announcement: ' .. message, GetPlayerName(src))
end)

lib.callback.register('ec_admin:serverAnnouncement', function(source, data)
    local src = source
    local message = data and data.message
    local duration = tonumber(data and data.duration) or 10000
    if not message or message == '' then
        return { success = false, message = 'Invalid announcement message' }
    end
    TriggerClientEvent('ec_admin_ultimate:client:serverAnnouncement', -1, { message = message, duration = duration, admin = GetPlayerName(src) })
    LogAction(src, 'server_announcement', nil, message, true)
    LogToConsole('info', 'Server announcement: ' .. message, GetPlayerName(src))
    return { success = true, message = 'Announcement sent to all players' }
end)

-- Kick all players
RegisterNetEvent('ec_admin_ultimate:server:kickAllPlayers', function(data)
    local src = source
    local reason = data.reason or 'Server maintenance'
    
    local players = GetPlayers()
    local kicked = 0
    
    for _, playerId in ipairs(players) do
        local id = tonumber(playerId)
        if id ~= src then -- Don't kick the admin
            DropPlayer(id, '🔧 Server Maintenance\n' .. reason)
            kicked = kicked + 1
        end
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
        success = true,
        message = 'Kicked ' .. kicked .. ' players'
    })
    
    LogAction(src, 'kick_all', nil, 'Reason: ' .. reason .. ' - Kicked: ' .. kicked, true)
    LogToConsole('warning', 'Kicked all players - Reason: ' .. reason, GetPlayerName(src))
end)

lib.callback.register('ec_admin:kickAllPlayers', function(source, data)
    local src = source
    local reason = (data and data.reason) or 'Server maintenance'
    local players = GetPlayers()
    local kicked = 0
    for _, playerId in ipairs(players) do
        local id = tonumber(playerId)
        if id ~= src then
            DropPlayer(id, '🔧 Server Maintenance\n' .. reason)
            kicked = kicked + 1
        end
    end
    LogAction(src, 'kick_all', nil, 'Reason: ' .. reason .. ' - Kicked: ' .. kicked, true)
    LogToConsole('warning', 'Kicked all players - Reason: ' .. reason, GetPlayerName(src))
    return { success = true, message = ('Kicked %d players'):format(kicked) }
end)

-- Clear cache
RegisterNetEvent('ec_admin_ultimate:server:clearCache', function(data)
    local src = source
    
    -- Force garbage collection
    collectgarbage('collect')
    
    TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
        success = true,
        message = 'Server cache cleared'
    })
    
    LogAction(src, 'clear_cache', nil, 'Cache cleared', true)
    LogToConsole('info', 'Server cache cleared', GetPlayerName(src))
end)

lib.callback.register('ec_admin:clearCache', function(source, _)
    local src = source
    collectgarbage('collect')
    LogAction(src, 'clear_cache', nil, 'Cache cleared', true)
    LogToConsole('info', 'Server cache cleared', GetPlayerName(src))
    return { success = true, message = 'Server cache cleared' }
end)

-- Database cleanup
RegisterNetEvent('ec_admin_ultimate:server:databaseCleanup', function(data)
    local src = source
    local days = tonumber(data.days) or 30
    
    -- Clean old logs
    local deleted = 0
    
    -- Clean console logs
    local result1 = MySQL.Sync.execute([[
        DELETE FROM ec_console_logs 
        WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
    ]], {days})
    deleted = deleted + (result1 or 0)
    
    -- Clean old system actions
    local result2 = MySQL.Sync.execute([[
        DELETE FROM ec_system_actions 
        WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
    ]], {days})
    deleted = deleted + (result2 or 0)
    
    -- Clean old behavior logs
    local result3 = MySQL.Sync.execute([[
        DELETE FROM ec_ai_behavior_logs 
        WHERE timestamp < DATE_SUB(NOW(), INTERVAL ? DAY)
    ]], {days})
    deleted = deleted + (result3 or 0)
    
    -- Optimize tables
    MySQL.Async.execute('OPTIMIZE TABLE ec_console_logs', {})
    MySQL.Async.execute('OPTIMIZE TABLE ec_system_actions', {})
    MySQL.Async.execute('OPTIMIZE TABLE ec_ai_behavior_logs', {})
    
    TriggerClientEvent('ec_admin_ultimate:client:systemResponse', src, {
        success = true,
        message = 'Database cleaned: ' .. deleted .. ' records deleted'
    })
    
    LogAction(src, 'database_cleanup', nil, 'Deleted ' .. deleted .. ' old records (>' .. days .. ' days)', true)
    LogToConsole('info', 'Database cleanup completed: ' .. deleted .. ' records deleted', GetPlayerName(src))
end)

lib.callback.register('ec_admin:databaseCleanup', function(source, data)
    local src = source
    local days = tonumber(data and data.days) or 30
    local deleted = 0
    local result1 = MySQL.Sync.execute([[DELETE FROM ec_console_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)]], {days})
    deleted = deleted + (result1 or 0)
    local result2 = MySQL.Sync.execute([[DELETE FROM ec_system_actions WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)]], {days})
    deleted = deleted + (result2 or 0)
    local result3 = MySQL.Sync.execute([[DELETE FROM ec_ai_behavior_logs WHERE timestamp < DATE_SUB(NOW(), INTERVAL ? DAY)]], {days})
    deleted = deleted + (result3 or 0)
    MySQL.Async.execute('OPTIMIZE TABLE ec_console_logs', {})
    MySQL.Async.execute('OPTIMIZE TABLE ec_system_actions', {})
    MySQL.Async.execute('OPTIMIZE TABLE ec_ai_behavior_logs', {})
    LogAction(src, 'database_cleanup', nil, 'Deleted ' .. deleted .. ' old records (>' .. days .. ' days)', true)
    LogToConsole('info', 'Database cleanup completed: ' .. deleted .. ' records deleted', GetPlayerName(src))
    return { success = true, message = 'Database cleaned: ' .. deleted .. ' records deleted' }
end)

-- Get database stats
RegisterNetEvent('ec_admin_ultimate:server:getDatabaseStats', function()
    local src = source
    
    -- Get table sizes
    local stats = {
        tables = {},
        totalSize = 0,
        totalRecords = 0
    }
    
    local tables = {
        'ec_anticheat_detections',
        'ec_anticheat_player_scores',
        'ec_anticheat_bans',
        'ec_ai_detections',
        'ec_ai_player_patterns',
        'ec_ai_behavior_logs',
        'ec_warnings',
        'ec_kicks',
        'ec_mutes',
        'ec_reports',
        'ec_mod_actions',
        'ec_console_logs',
        'ec_system_actions'
    }
    
    for _, tableName in ipairs(tables) do
        local result = MySQL.Sync.fetchAll([[
            SELECT 
                COUNT(*) as record_count,
                ROUND(((data_length + index_length) / 1024 / 1024), 2) as size_mb
            FROM information_schema.TABLES
            WHERE table_schema = DATABASE() AND table_name = ?
        ]], {tableName})
        
        if result and #result > 0 then
            local count = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM ' .. tableName, {}) or 0
            
            table.insert(stats.tables, {
                name = tableName,
                records = count,
                size = result[1].size_mb or 0
            })
            
            stats.totalRecords = stats.totalRecords + count
            stats.totalSize = stats.totalSize + (result[1].size_mb or 0)
        end
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:receiveDatabaseStats', src, {
        success = true,
        data = stats
    })
end)

lib.callback.register('ec_admin:getDatabaseStats', function(source, _)
    local src = source
    local stats = { tables = {}, totalSize = 0, totalRecords = 0 }
    local tables = {
        'ec_anticheat_detections','ec_anticheat_player_scores','ec_anticheat_bans','ec_ai_detections','ec_ai_player_patterns','ec_ai_behavior_logs','ec_warnings','ec_kicks','ec_mutes','ec_reports','ec_mod_actions','ec_console_logs','ec_system_actions'
    }
    for _, tableName in ipairs(tables) do
        local result = MySQL.Sync.fetchAll([[SELECT COUNT(*) as record_count, ROUND(((data_length + index_length) / 1024 / 1024), 2) as size_mb FROM information_schema.TABLES WHERE table_schema = DATABASE() AND table_name = ?]], {tableName})
        if result and #result > 0 then
            local count = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM ' .. tableName, {}) or 0
            table.insert(stats.tables, { name = tableName, records = count, size = result[1].size_mb or 0 })
            stats.totalRecords = stats.totalRecords + count
            stats.totalSize = stats.totalSize + (result[1].size_mb or 0)
        end
    end
    return { success = true, data = stats }
end)

-- Performance monitoring thread
CreateThread(function()
    while true do
        Wait(5000) -- Update every 5 seconds
        
        -- Calculate tick time
        local startTime = GetGameTimer()
        Wait(0)
        PerformanceData.tickTime = GetGameTimer() - startTime
        
        -- Update player count
        PerformanceData.playerCount = #GetPlayers()
        
        -- Update resource count
        PerformanceData.resourceCount = GetNumResources()
        
        -- Send to all connected admins
        TriggerClientEvent('ec_admin_ultimate:client:performanceUpdate', -1, PerformanceData)
    end
end)

-- Console log capture
local function CaptureConsoleLog(logType, message)
    LogToConsole(logType, message, 'SYSTEM')
    
    -- Broadcast to admins in real-time
    TriggerClientEvent('ec_admin_ultimate:client:consoleLog', -1, {
        type = logType,
        message = message,
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    })
end

-- Export for other resources to log
exports('LogToConsole', CaptureConsoleLog)

-- Set server start time
if not GlobalState.serverStartTime then
    GlobalState.serverStartTime = os.time()
end

Logger.Info('System Management callbacks loaded')