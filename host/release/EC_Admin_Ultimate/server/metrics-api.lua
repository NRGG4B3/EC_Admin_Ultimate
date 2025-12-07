--[[
    NUI CALLBACKS - Now handled via HTTP endpoints
    RegisterNUICallback is client-only
]]

-- These are now HTTP endpoints, registered in unified-router.lua
-- The NUI callbacks are in client/nui-bridge.lua which trigger server events

-- Server event handlers for metrics requests
RegisterNetEvent('ec_admin:getMetrics', function(cb)
    local src = source
    if not EC_Perms.Has(src, 'ec_admin.menu') then return end
    
    TriggerClientEvent('ec_admin:metricsResponse', src, {
        success = true,
        metrics = MetricsAPI.metrics,
        history = MetricsAPI.history
    })
end)

RegisterNetEvent('ec_admin:getMetricsHistory', function(data, cb)
    local src = source
    if not EC_Perms.Has(src, 'ec_admin.menu') then return end
    
    local historyData = {}
    local now = os.time()
    
    for i = 1, #MetricsAPI.history.players do
        table.insert(historyData, {
            time = os.date('%H:%M:%S', now - ((#MetricsAPI.history.players - i) * 5)),
            players = MetricsAPI.history.players[i],
            tps = MetricsAPI.history.performance[i],
            memory = MetricsAPI.history.memory[i],
            cpu = 0, -- TODO
            avgPing = MetricsAPI.history.network[i]
        })
    end
    
    TriggerClientEvent('ec_admin:metricsHistoryResponse', src, {
        success = true,
        history = historyData
    })
end)

RegisterNetEvent('ec_admin:getPlayerMetrics', function(cb)
    local src = source
    if not EC_Perms.Has(src, 'ec_admin.menu') then return end
    
    TriggerClientEvent('ec_admin:playerMetricsResponse', src, {
        success = true,
        players = GetOnlinePlayers(),
        count = GetPlayerCount()
    })
end)

RegisterNetEvent('ec_admin:getResourceMetrics', function(cb)
    local src = source
    if not EC_Perms.Has(src, 'ec_admin.menu') then return end
    
    TriggerClientEvent('ec_admin:resourceMetricsResponse', src, {
        success = true,
        resources = GetResourceMetrics()
    })
end)

RegisterNetEvent('ec_admin:getNetworkMetrics', function(cb)
    local src = source
    if not EC_Perms.Has(src, 'ec_admin.menu') then return end
    
    TriggerClientEvent('ec_admin:networkMetricsResponse', src, {
        success = true,
        network = GetNetworkStats()
    })
end)

RegisterNetEvent('ec_admin:getPerformanceMetrics', function(cb)
    local src = source
    if not EC_Perms.Has(src, 'ec_admin.menu') then return end
    
    TriggerClientEvent('ec_admin:performanceMetricsResponse', src, {
        success = true,
        performance = GetPerformanceMetrics()
    })
end)

--[[
    HTTP ENDPOINTS (for web-only access)
]]

-- Main metrics endpoint
SetHttpHandler(function(req, res)
    local path = req.path
    
    if path == '/api/metrics' then
        res.writeHead(200, {['Content-Type'] = 'application/json'})
        res.send(json.encode({
            success = true,
            metrics = MetricsAPI.metrics
        }))
        return
    end
    
    if path == '/api/players' then
        res.writeHead(200, {['Content-Type'] = 'application/json'})
        res.send(json.encode({
            success = true,
            players = GetOnlinePlayers(),
            count = GetPlayerCount()
        }))
        return
    end
    
    if path == '/api/resources' then
        res.writeHead(200, {['Content-Type'] = 'application/json'})
        res.send(json.encode({
            success = true,
            resources = GetResourceMetrics()
        }))
        return
    end
    
    if path == '/api/network' then
        res.writeHead(200, {['Content-Type'] = 'application/json'})
        res.send(json.encode({
            success = true,
            network = GetNetworkStats()
        }))
        return
    end
    
    if path == '/api/performance' then
        res.writeHead(200, {['Content-Type'] = 'application/json'})
        res.send(json.encode({
            success = true,
            performance = GetPerformanceMetrics()
        }))
        return
    end
    
    -- Health check endpoint
    if path == '/api/health' then
        res.writeHead(200, {['Content-Type'] = 'application/json'})
        res.send(json.encode({
            success = true,
            status = 'healthy',
            uptime = GetUptime()
        }))
        return
    end
end)

Logger.Success("[Metrics API] Initialized - HTTP endpoints available", '🌐')
Logger.Info("  - /api/metrics (all metrics)")
Logger.Info("  - /api/players (player data)")
Logger.Info("  - /api/resources (resource stats)")
Logger.Info("  - /api/network (network stats)")
Logger.Info("  - /api/performance (performance stats)")
Logger.Info("  - /api/health (health check)")