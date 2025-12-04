--[[
    EC Admin Ultimate - Dev Tools Server (Real-Time Logging & Monitoring)
    Server-side backend for development tools, resource monitoring, and performance profiling
    Generated: December 4, 2025
]]

Logger.Success('🔧 Initializing Dev Tools Server')

-- =============================================================================
-- LOG STREAMING SYSTEM
-- =============================================================================

local LogBuffer = {
    logs = {},
    maxSize = 1000,
    listeners = {}
}

-- Add log entry to buffer
local function AddLog(level, category, message, data)
    local logEntry = {
        timestamp = os.time(),
        formattedTime = os.date('%H:%M:%S'),
        level = level,
        category = category,
        message = message,
        data = data or nil
    }
    
    table.insert(LogBuffer.logs, logEntry)
    
    -- Keep buffer size under control
    if #LogBuffer.logs > LogBuffer.maxSize then
        table.remove(LogBuffer.logs, 1)
    end
    
    -- Notify active listeners
    BroadcastLogUpdate(logEntry)
    
    return logEntry
end

-- Broadcast new log to all listening admins
function BroadcastLogUpdate(logEntry)
    if LogBuffer.listeners and next(LogBuffer.listeners) then
        for adminId, _ in pairs(LogBuffer.listeners) do
            if GetPlayerPing(adminId) >= 0 then -- Player still connected
                TriggerClientEvent('ec_admin:receiveLogUpdate', adminId, logEntry)
            else
                LogBuffer.listeners[adminId] = nil
            end
        end
    end
end

-- =============================================================================
-- RESOURCE MONITORING
-- =============================================================================

local ResourceMonitor = {
    resourceMetrics = {},
    updateInterval = 5000 -- 5 seconds
}

-- Get current resource metrics
local function GetResourceMetrics()
    local resources = GetNumResources()
    local metrics = {}
    
    for i = 0, resources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        local state = GetResourceState(resourceName)
        
        metrics[resourceName] = {
            name = resourceName,
            state = state,
            running = state == 'started',
            index = i
        }
    end
    
    ResourceMonitor.resourceMetrics = metrics
    return metrics
end

-- Get individual resource info
local function GetResourceInfo(resourceName)
    if not resourceName then return nil end
    
    local state = GetResourceState(resourceName)
    local metadata = GetResourceMetadata(resourceName, 'version') or 'unknown'
    
    return {
        name = resourceName,
        state = state,
        running = state == 'started',
        version = metadata,
        authors = GetResourceMetadata(resourceName, 'author') or 'unknown'
    }
end

-- =============================================================================
-- PERFORMANCE MONITORING
-- =============================================================================

local PerformanceMonitor = {
    history = {},
    samples = 0,
    updateInterval = 1000
}

-- Sample current performance metrics
local function SamplePerformance()
    local sample = {
        timestamp = os.time(),
        ticks = GetGameTimer(),
        serverPlayers = #GetPlayers()
    }
    
    table.insert(PerformanceMonitor.history, sample)
    
    -- Keep last 300 samples (5 minutes at 1 sample/sec)
    if #PerformanceMonitor.history > 300 then
        table.remove(PerformanceMonitor.history, 1)
    end
    
    return sample
end

-- Start performance sampling thread
CreateThread(function()
    while true do
        Wait(PerformanceMonitor.updateInterval)
        SamplePerformance()
    end
end)

-- =============================================================================
-- DEBUG INFORMATION
-- =============================================================================

-- Get comprehensive server debug info
local function GetDebugInfo()
    local onlinePlayers = GetPlayers()
    local resources = GetNumResources()
    
    return {
        server = {
            uptime = math.floor(GetGameTimer() / 1000),
            players = #onlinePlayers,
            maxPlayers = GetConvar('sv_maxclients', '32'),
            build = 'FiveM',
            version = GetConvarInt('sv_enforceGameBuild', 0)
        },
        resources = {
            total = resources,
            running = 0,
            stopped = 0,
            errored = 0
        },
        performance = {
            ping = {},
            samples = #PerformanceMonitor.history
        },
        debug = {
            logBufferSize = #LogBuffer.logs,
            activeListeners = next(LogBuffer.listeners) ~= nil and table.count(LogBuffer.listeners) or 0
        }
    }
end

-- Count table items
function table.count(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- =============================================================================
-- CLIENT CALLBACKS
-- =============================================================================

-- Stream server logs to admin
RegisterNetEvent('ec_admin:requestLogs', function(data)
    local src = source
    local limit = data and data.limit or 100
    
    -- Register listener
    if not LogBuffer.listeners then
        LogBuffer.listeners = {}
    end
    LogBuffer.listeners[src] = true
    
    -- Send recent logs
    local sendLogs = {}
    local start = math.max(1, #LogBuffer.logs - limit + 1)
    
    for i = start, #LogBuffer.logs do
        table.insert(sendLogs, LogBuffer.logs[i])
    end
    
    TriggerClientEvent('ec_admin:receiveLogBuffer', src, {
        success = true,
        logs = sendLogs,
        totalLogs = #LogBuffer.logs
    })
    
    AddLog('info', 'admin', string.format('Admin streaming logs (received %d)', #sendLogs))
end)

-- Stop log streaming
RegisterNetEvent('ec_admin:stopLogs', function()
    local src = source
    if LogBuffer.listeners then
        LogBuffer.listeners[src] = nil
    end
    AddLog('info', 'admin', 'Admin stopped log streaming')
end)

-- Get resource list
RegisterNetEvent('ec_admin:getResources', function()
    local src = source
    local resourceList = GetResourceMetrics()
    local list = {}
    
    for name, info in pairs(resourceList) do
        table.insert(list, info)
    end
    
    -- Sort by name
    table.sort(list, function(a, b) return a.name < b.name end)
    
    TriggerClientEvent('ec_admin:receiveResources', src, {
        success = true,
        resources = list,
        total = #list
    })
    
    AddLog('info', 'admin', string.format('Admin retrieved resource list (%d total)', #list))
end)

-- Start resource
RegisterNetEvent('ec_admin:startResource', function(data)
    local src = source
    local resourceName = data.resource
    
    if not resourceName or resourceName == '' then
        TriggerClientEvent('ec_admin:actionFailed', src, 'Invalid resource name')
        return
    end
    
    -- Prevent starting critical resources
    local critical = {'fxserver', 'cfx-internal', 'sessionmanager'}
    for _, crit in ipairs(critical) do
        if string.lower(resourceName) == crit then
            TriggerClientEvent('ec_admin:actionFailed', src, 'Cannot start critical resource')
            AddLog('warn', 'admin', string.format('Admin tried to start critical resource: %s', resourceName))
            return
        end
    end
    
    StartResource(resourceName)
    
    TriggerClientEvent('ec_admin:actionSuccess', src, {
        message = 'Resource started: ' .. resourceName
    })
    
    AddLog('warn', 'admin', string.format('Started resource: %s', resourceName), {
        resource = resourceName,
        admin = GetPlayerName(src)
    })
end)

-- Stop resource
RegisterNetEvent('ec_admin:stopResource', function(data)
    local src = source
    local resourceName = data.resource
    
    if not resourceName or resourceName == '' then
        TriggerClientEvent('ec_admin:actionFailed', src, 'Invalid resource name')
        return
    end
    
    -- Prevent stopping critical resources
    local critical = {'fxserver', 'cfx-internal', 'sessionmanager'}
    for _, crit in ipairs(critical) do
        if string.lower(resourceName) == crit then
            TriggerClientEvent('ec_admin:actionFailed', src, 'Cannot stop critical resource')
            AddLog('warn', 'admin', string.format('Admin tried to stop critical resource: %s', resourceName))
            return
        end
    end
    
    StopResource(resourceName)
    
    TriggerClientEvent('ec_admin:actionSuccess', src, {
        message = 'Resource stopped: ' .. resourceName
    })
    
    AddLog('warn', 'admin', string.format('Stopped resource: %s', resourceName), {
        resource = resourceName,
        admin = GetPlayerName(src)
    })
end)

-- Restart resource
RegisterNetEvent('ec_admin:restartResource', function(data)
    local src = source
    local resourceName = data.resource
    
    if not resourceName or resourceName == '' then
        TriggerClientEvent('ec_admin:actionFailed', src, 'Invalid resource name')
        return
    end
    
    -- Prevent restarting critical resources
    local critical = {'fxserver', 'cfx-internal', 'sessionmanager'}
    for _, crit in ipairs(critical) do
        if string.lower(resourceName) == crit then
            TriggerClientEvent('ec_admin:actionFailed', src, 'Cannot restart critical resource')
            AddLog('warn', 'admin', string.format('Admin tried to restart critical resource: %s', resourceName))
            return
        end
    end
    
    StopResource(resourceName)
    Wait(500) -- Wait for resource to stop
    StartResource(resourceName)
    
    TriggerClientEvent('ec_admin:actionSuccess', src, {
        message = 'Resource restarted: ' .. resourceName
    })
    
    AddLog('warn', 'admin', string.format('Restarted resource: %s', resourceName), {
        resource = resourceName,
        admin = GetPlayerName(src)
    })
end)

-- Get debug info
RegisterNetEvent('ec_admin:getDebugInfo', function()
    local src = source
    local info = GetDebugInfo()
    
    TriggerClientEvent('ec_admin:receiveDebugInfo', src, {
        success = true,
        data = info
    })
end)

-- Get performance history
RegisterNetEvent('ec_admin:getPerformanceHistory', function()
    local src = source
    
    TriggerClientEvent('ec_admin:receivePerformanceHistory', src, {
        success = true,
        data = PerformanceMonitor.history,
        samples = #PerformanceMonitor.history
    })
end)

-- Get resource specific info
RegisterNetEvent('ec_admin:getResourceInfo', function(data)
    local src = source
    local resourceName = data.resource
    
    if not resourceName then
        TriggerClientEvent('ec_admin:actionFailed', src, 'Resource name required')
        return
    end
    
    local info = GetResourceInfo(resourceName)
    
    if not info then
        TriggerClientEvent('ec_admin:actionFailed', src, 'Resource not found')
        return
    end
    
    TriggerClientEvent('ec_admin:receiveResourceInfo', src, {
        success = true,
        data = info
    })
end)

-- Export logs (prepare for download)
RegisterNetEvent('ec_admin:exportLogs', function(data)
    local src = source
    local format = data and data.format or 'json'
    
    local exportData = LogBuffer.logs
    local exported = 'logs_' .. os.date('%Y%m%d_%H%M%S')
    
    if format == 'json' then
        -- JSON format
        TriggerClientEvent('ec_admin:receiveExport', src, {
            success = true,
            format = 'json',
            filename = exported .. '.json',
            data = json.encode(exportData)
        })
    else
        -- CSV format
        local csv = 'Time,Level,Category,Message\n'
        for _, log in ipairs(exportData) do
            csv = csv .. string.format('"%s","%s","%s","%s"\n', 
                log.formattedTime, 
                log.level, 
                log.category, 
                log.message)
        end
        
        TriggerClientEvent('ec_admin:receiveExport', src, {
            success = true,
            format = 'csv',
            filename = exported .. '.csv',
            data = csv
        })
    end
    
    AddLog('info', 'admin', string.format('Exported %d logs as %s', #exportData, format))
end)

-- Clear logs
RegisterNetEvent('ec_admin:clearLogs', function()
    local src = source
    local count = #LogBuffer.logs
    
    LogBuffer.logs = {}
    
    TriggerClientEvent('ec_admin:actionSuccess', src, {
        message = 'Cleared ' .. count .. ' logs'
    })
    
    AddLog('warn', 'admin', string.format('Admin cleared log buffer (%d logs)', count))
end)

-- =============================================================================
-- COMMAND CONSOLE (For Executingraw commands)
-- =============================================================================

-- Execute console command from admin panel
RegisterNetEvent('ec_admin:executeCommand', function(data)
    local src = source
    local cmd = data and data.command
    
    if not cmd or cmd == '' then
        TriggerClientEvent('ec_admin:commandFailed', src, 'Empty command')
        return
    end
    
    -- Log the command execution
    AddLog('warn', 'admin', string.format('Command executed: %s', cmd), {
        admin = GetPlayerName(src),
        adminId = src
    })
    
    -- Execute the command
    TriggerEvent('chat:addMessage', {
        args = { 'ADMIN', 'Command executed: ' .. cmd }
    })
    
    TriggerClientEvent('ec_admin:commandSuccess', src, {
        command = cmd,
        executed = true
    })
end)

-- =============================================================================
-- AUTO-LOGGING OF ADMIN ACTIONS
-- =============================================================================

-- Hook into admin action events to auto-log them
AddEventHandler('ec_admin:adminActionLogged', function(data)
    if data and data.action then
        AddLog('info', 'action', data.action, data)
    end
end)

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Start collecting metrics
GetResourceMetrics()

CreateThread(function()
    while true do
        Wait(10000) -- Every 10 seconds, refresh resource metrics
        GetResourceMetrics()
    end
end)

Logger.Success('✅ Dev Tools Server loaded - Real-time logging active')

