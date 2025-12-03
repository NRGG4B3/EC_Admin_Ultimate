--[[
    EC Admin Ultimate - Server Monitoring Callbacks
    Real-time resource and performance monitoring
]]

Logger.Info('📊 Loading server monitoring callbacks...')

-- ============================================================================
-- TRACK SERVER START TIME
-- ============================================================================

if not GlobalState.serverStartTime then
    GlobalState.serverStartTime = os.time()
end

-- ============================================================================
-- CALLBACK: GET MONITORING DATA
-- ============================================================================

lib.callback.register('ec_admin:getMonitoring', function(source, data)
    local resources = {}
    local numResources = GetNumResources()
    
    -- Get all resources
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local state = GetResourceState(resourceName)
            local memUsage = GetResourceMemoryUsage(resourceName, 0) / 1024 -- Convert to MB
            
            table.insert(resources, {
                name = resourceName,
                state = state,
                status = state == 'started' and 'running' or state,
                memory = math.floor(memUsage * 100) / 100, -- Round to 2 decimals
                memoryMB = math.floor(memUsage * 100) / 100,
                author = GetResourceMetadata(resourceName, 'author', 0) or 'Unknown',
                version = GetResourceMetadata(resourceName, 'version', 0) or '1.0.0',
                description = GetResourceMetadata(resourceName, 'description', 0) or 'No description'
            })
        end
    end
    
    -- Sort by memory usage
    table.sort(resources, function(a, b)
        return a.memory > b.memory
    end)
    
    -- Performance metrics
    local performance = {
        serverTPS = GetTickRate(),
        maxPlayers = GetConvarInt('sv_maxclients', 32),
        currentPlayers = #GetPlayers(),
        serverUptime = os.time() - (GlobalState.serverStartTime or os.time()),
        totalResources = numResources,
        runningResources = 0,
        stoppedResources = 0,
        totalMemory = 0,
        serverName = GetConvar('sv_hostname', 'Unknown Server'),
        gameType = GetConvar('gametype', 'FiveM'),
        mapName = GetConvar('mapname', 'San Andreas')
    }
    
    -- Calculate totals
    for _, resource in ipairs(resources) do
        if resource.state == 'started' then
            performance.runningResources = performance.runningResources + 1
        else
            performance.stoppedResources = performance.stoppedResources + 1
        end
        performance.totalMemory = performance.totalMemory + resource.memory
    end
    
    performance.totalMemory = math.floor(performance.totalMemory * 100) / 100
    
    return {
        success = true,
        resources = resources,
        performance = performance,
        total = #resources
    }
end)

-- ============================================================================
-- CALLBACK: GET RESOURCES (Detailed)
-- ============================================================================

lib.callback.register('ec_admin:getResources', function(source, data)
    local resources = {}
    local numResources = GetNumResources()
    
    -- Get all resources with detailed metrics
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local state = GetResourceState(resourceName)
            
            -- GetResourceMemoryUsage is deprecated in newer FiveM versions
            -- Use GetResourceKvpString or fallback to 0
            local memUsage = 0
            if GetResourceMemoryUsage then
                local success, mem = pcall(GetResourceMemoryUsage, resourceName, 0)
                if success and mem then
                    memUsage = mem / 1024 -- Convert to MB
                end
            end
            
            table.insert(resources, {
                id = resourceName,
                name = resourceName,
                status = state == 'started' and 'running' or (state == 'stopped' and 'stopped' or 'error'),
                cpu = 0, -- FiveM doesn't expose CPU per resource on server; return 0 (no mock)
                memory = math.floor(memUsage * 100) / 100,
                threads = 0,
                uptime = state == 'started' and (os.time() - (GlobalState.serverStartTime or os.time())) or 0
            })
        end
    end
    
    -- Sort by CPU usage
    table.sort(resources, function(a, b)
        return a.cpu > b.cpu
    end)
    
    return {
        success = true,
        resources = resources
    }
end)

-- ============================================================================
-- CALLBACK: GET NETWORK METRICS
-- ============================================================================

lib.callback.register('ec_admin:getNetworkMetrics', function(source, data)
    local players = GetPlayers()
    local totalPing = 0
    local peakPlayers = GlobalState.peakPlayersToday or #players
    
    -- Calculate average ping
    for _, playerId in ipairs(players) do
        local ping = GetPlayerPing(playerId)
        totalPing = totalPing + ping
    end
    
    local avgPing = #players > 0 and math.floor(totalPing / #players) or 0
    
    -- Update peak
    if #players > peakPlayers then
        GlobalState.peakPlayersToday = #players
        peakPlayers = #players
    end
    
    return {
        success = true,
        metrics = {
            playersOnline = #players,
            peakToday = peakPlayers,
            avgPing = avgPing,
            bandwidth = {
                ['in'] = 0, -- FiveM server does not expose bandwidth reliably; return 0 (no mock)
                out = 0
            },
            connections = #players
        }
    }
end)

-- ============================================================================
-- CALLBACK: GET DATABASE METRICS
-- ============================================================================

lib.callback.register('ec_admin:getDatabaseMetrics', function(source, data)
    -- These are framework-specific and would need to be implemented
    -- For now, return reasonable defaults
    
    local queries = GlobalState.dbQueriesPerSecond or 0
    local avgQueryTime = GlobalState.dbAvgQueryTime or 0
    local slowQueries = GlobalState.dbSlowQueries or 0
    local connections = GlobalState.dbConnections or 0
    local size = GlobalState.dbSizeMB or 0 -- MB
    
    return {
        success = true,
        metrics = {
            queries = queries,
            avgQueryTime = avgQueryTime,
            slowQueries = slowQueries,
            connections = connections,
            size = size,
            sizeFormatted = size .. ' MB'
        }
    }
end)

-- ============================================================================
-- CALLBACK: GET PLAYER POSITIONS (for live map)
-- ============================================================================

lib.callback.register('ec_admin:getPlayerPositions', function(source, data)
    local players = GetPlayers()
    local positions = {}
    
    for _, playerId in ipairs(players) do
        local ped = GetPlayerPed(playerId)
        if ped and DoesEntityExist(ped) then
            local coords = GetEntityCoords(ped)
            local vehicle = GetVehiclePedIsIn(ped, false)
            local vehicleName = nil
            
            if vehicle and vehicle ~= 0 then
                vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            end
            
            table.insert(positions, {
                id = tostring(playerId),
                name = GetPlayerName(playerId),
                coords = {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z
                },
                vehicle = vehicleName,
                job = nil -- Framework-specific, would need to fetch from QBCore/ESX
            })
        end
    end
    
    return {
        success = true,
        positions = positions
    }
end)

-- ============================================================================
-- RESET PEAK PLAYERS DAILY
-- ============================================================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3600000) -- Check every hour
        
        local currentHour = tonumber(os.date('%H'))
        if currentHour == 0 then -- Reset at midnight
            GlobalState.peakPlayersToday = #GetPlayers()
            Logger.Info('📊 Reset daily peak players')
        end
    end
end)

-- ============================================================================
-- RESOURCE MANAGEMENT EVENTS
-- ============================================================================

RegisterNetEvent('ec_admin:restartResource', function(data)
    local source = source
    local resourceName = data.resourceName or data.resource
    
    if not resourceName then return end
    
    -- Check admin permission
    if not IsPlayerAceAllowed(source, 'admin.access') then
        Logger.Info('⚠️ Unauthorized resource restart attempt from: ' .. GetPlayerName(source))
        return
    end
    
    Logger.Info('🔄 Restarting resource: ' .. resourceName .. ' (by ' .. GetPlayerName(source) .. ')')
    
    ExecuteCommand('restart ' .. resourceName)
    
    -- Log action
    TriggerEvent('ec_admin:log', {
        action = 'resource_restart',
        admin = GetPlayerName(source),
        adminIdentifier = GetPlayerIdentifiers(source)[1],
        target = resourceName,
        timestamp = os.time()
    })
end)

RegisterNetEvent('ec_admin:stopResource', function(data)
    local source = source
    local resourceName = data.resourceName or data.resource
    
    if not resourceName then return end
    
    if not IsPlayerAceAllowed(source, 'admin.access') then
        Logger.Info('⚠️ Unauthorized resource stop attempt from: ' .. GetPlayerName(source))
        return
    end
    
    Logger.Info('🛑 Stopping resource: ' .. resourceName .. ' (by ' .. GetPlayerName(source) .. ')')
    
    ExecuteCommand('stop ' .. resourceName)
    
    TriggerEvent('ec_admin:log', {
        action = 'resource_stop',
        admin = GetPlayerName(source),
        adminIdentifier = GetPlayerIdentifiers(source)[1],
        target = resourceName,
        timestamp = os.time()
    })
end)

RegisterNetEvent('ec_admin:startResource', function(data)
    local source = source
    local resourceName = data.resourceName or data.resource
    
    if not resourceName then return end
    
    if not IsPlayerAceAllowed(source, 'admin.access') then
        Logger.Info('⚠️ Unauthorized resource start attempt from: ' .. GetPlayerName(source))
        return
    end
    
    Logger.Info('▶️ Starting resource: ' .. resourceName .. ' (by ' .. GetPlayerName(source) .. ')')
    
    ExecuteCommand('start ' .. resourceName)
    
    TriggerEvent('ec_admin:log', {
        action = 'resource_start',
        admin = GetPlayerName(source),
        adminIdentifier = GetPlayerIdentifiers(source)[1],
        target = resourceName,
        timestamp = os.time()
    })
end)

Logger.Info('✅ Server monitoring callbacks loaded')
Logger.Info('📊 Tracking ' .. GetNumResources() .. ' resources')