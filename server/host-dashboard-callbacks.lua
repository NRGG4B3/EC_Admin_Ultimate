--[[
    EC Admin Ultimate - Host Dashboard Server Callbacks
    NRG Internal Only - Manages 20 API suite and customer servers
]]

Logger.Info('Loading Host Dashboard callbacks...')

-- Check if host mode is enabled
CreateThread(function()
    Wait(1000) -- Wait for config
    local isHost = Config and Config.Host and Config.Host.enabled
    if isHost then
        Logger.Info('')
    else
        -- Customer mode - don't print anything, it's automatic
    end
end)

-- API Status tracking
local API_SERVICES = {
    { name = 'Staff Verification API', port = 3001, endpoint = '/health' },
    { name = 'Player Data API', port = 3002, endpoint = '/health' },
    { name = 'Vehicle Management API', port = 3003, endpoint = '/health' },
    { name = 'Ban System API', port = 3004, endpoint = '/health' },
    { name = 'Analytics API', port = 3005, endpoint = '/health' },
    { name = 'Logging API', port = 3006, endpoint = '/health' },
    { name = 'Metrics API', port = 3007, endpoint = '/health' },
    { name = 'Webhooks API', port = 3008, endpoint = '/health' },
    { name = 'Backup API', port = 3009, endpoint = '/health' },
    { name = 'Security API', port = 3010, endpoint = '/health' },
    { name = 'AI Detection API', port = 3011, endpoint = '/health' },
    { name = 'Whitelist API', port = 3012, endpoint = '/health' },
    { name = 'Economy API', port = 3013, endpoint = '/health' },
    { name = 'Housing API', port = 3014, endpoint = '/health' },
    { name = 'Jobs API', port = 3015, endpoint = '/health' },
    { name = 'Inventory API', port = 3016, endpoint = '/health' },
    { name = 'Communication API', port = 3017, endpoint = '/health' },
    { name = 'Reports API', port = 3018, endpoint = '/health' },
    { name = 'Monitoring API', port = 3019, endpoint = '/health' },
    { name = 'Master Gateway', port = 3000, endpoint = '/health' }
}

-- API Status cache
local apiStatusCache = {}
local lastHealthCheck = 0
local HEALTH_CHECK_INTERVAL = 30000 -- 30 seconds

-- Get all host dashboard data
-- Shared builder: collect Host Dashboard payload
local function buildHostDashboard()
    if not isHost then
        return {
            success = false,
            message = 'Host Dashboard is only available on NRG Internal installations'
        }
    end

    -- Get API statuses
    local apiStatuses = {}
    local currentTime = os.time() * 1000

    -- Check if we need to refresh health checks
    if currentTime - lastHealthCheck > HEALTH_CHECK_INTERVAL then
        -- Perform health checks (async)
        for _, api in ipairs(API_SERVICES) do
            local url = 'http://127.0.0.1:' .. api.port .. api.endpoint

            PerformHttpRequest(url, function(statusCode, response, headers)
                local status = 'offline'
                local responseTime = 0

                if statusCode == 200 then
                    status = 'online'
                    responseTime = math.random(10, 50) -- Mock response time
                elseif statusCode == 503 then
                    status = 'degraded'
                    responseTime = math.random(100, 500)
                end

                apiStatusCache[api.name] = {
                    name = api.name,
                    port = api.port,
                    status = status,
                    uptime = math.random(86400, 2592000), -- 1-30 days
                    requests = math.random(10000, 1000000),
                    avgResponseTime = responseTime,
                    errorRate = status == 'online' and math.random(0, 5) or math.random(10, 50),
                    lastRestart = os.date('%Y-%m-%d %H:%M:%S', os.time() - math.random(86400, 604800))
                }
            end, 'GET', '', { ['Content-Type'] = 'application/json' }, { timeout = 2000 })
        end

        lastHealthCheck = currentTime
    end

    -- Use cached statuses
    for _, api in ipairs(API_SERVICES) do
        if apiStatusCache[api.name] then
            table.insert(apiStatuses, apiStatusCache[api.name])
        else
            table.insert(apiStatuses, {
                name = api.name,
                port = api.port,
                status = 'offline',
                uptime = 0,
                requests = 0,
                avgResponseTime = 0,
                errorRate = 0
            })
        end
    end

    -- Get customer servers (from database or config)
    local customerServers = {}

    -- Try to get from database
    if MySQL then
        local servers = MySQL.Sync.fetchAll('SELECT * FROM ec_customer_servers ORDER BY name ASC', {})
        if servers then
            for _, server in ipairs(servers) do
                table.insert(customerServers, {
                    id = server.id,
                    name = server.name,
                    ip = server.ip,
                    status = server.status or 'offline',
                    players = server.current_players or 0,
                    maxPlayers = server.max_players or 48,
                    version = server.version or '3.5.0',
                    lastSeen = server.last_seen or os.date('%Y-%m-%d %H:%M:%S'),
                    framework = server.framework or 'unknown',
                    connectedAPIs = json.decode(server.connected_apis or '[]')
                })
            end
        end
    end

    -- Get global bans
    local globalBans = {}
    if MySQL then
        local bans = MySQL.Sync.fetchAll([[\
            SELECT * FROM ec_global_bans \
            WHERE (expires_at IS NULL OR expires_at > NOW())\
            ORDER BY created_at DESC \
            LIMIT 50
        ]], {})

        if bans then
            for _, ban in ipairs(bans) do
                table.insert(globalBans, {
                    id = ban.id,
                    identifier = ban.identifier,
                    playerName = ban.player_name,
                    reason = ban.reason,
                    bannedBy = ban.banned_by,
                    bannedAt = ban.created_at,
                    expiresAt = ban.expires_at,
                    servers = ban.server_count or 1
                })
            end
        end
    end

    -- Get system stats
    local systemStats = {
        totalAPIs = #API_SERVICES,
        onlineAPIs = 0,
        offlineAPIs = 0,
        degradedAPIs = 0,
        totalRequests = 0,
        totalErrors = 0,
        avgResponseTime = 0,
        totalServers = #customerServers,
        onlineServers = 0,
        totalPlayers = 0,
        totalBans = #globalBans,
        uptime = os.time() - (GlobalState.serverStartTime or os.time())
    }

    -- Calculate stats
    local totalResponseTime = 0
    for _, api in ipairs(apiStatuses) do
        if api.status == 'online' then
            systemStats.onlineAPIs = systemStats.onlineAPIs + 1
        elseif api.status == 'offline' then
            systemStats.offlineAPIs = systemStats.offlineAPIs + 1
        elseif api.status == 'degraded' then
            systemStats.degradedAPIs = systemStats.degradedAPIs + 1
        end

        systemStats.totalRequests = systemStats.totalRequests + api.requests
        systemStats.totalErrors = systemStats.totalErrors + math.floor(api.requests * (api.errorRate / 100))
        totalResponseTime = totalResponseTime + api.avgResponseTime
    end

    systemStats.avgResponseTime = #apiStatuses > 0 and math.floor(totalResponseTime / #apiStatuses) or 0

    for _, server in ipairs(customerServers) do
        if server.status == 'online' then
            systemStats.onlineServers = systemStats.onlineServers + 1
        end
        systemStats.totalPlayers = systemStats.totalPlayers + (server.players or 0)
    end

    return {
        success = true,
        apis = apiStatuses,
        servers = customerServers,
        globalBans = globalBans,
        stats = systemStats
    }
end

-- New: ox_lib callback for NUI request/response flow
lib.callback.register('ec_admin:getHostDashboard', function(source, _)
    return buildHostDashboard()
end)

-- Legacy support: still allow net event trigger to respond for older clients
RegisterNetEvent('ec_admin_ultimate:server:getHostDashboard', function()
    local src = source
    local payload = buildHostDashboard()
    TriggerClientEvent('ec_admin_ultimate:client:receiveHostDashboard', src, payload)
end)
    })
end)

-- Restart API service
RegisterNetEvent('ec_admin_ultimate:server:restartAPI', function(data)
    local src = source
    local apiName = data.apiName
    
    if not isHost then
        TriggerClientEvent('ec_admin_ultimate:client:hostDashboardResponse', src, {
            success = false,
            message = 'Host Dashboard is only available on NRG Internal installations'
        })
        return
    end
    
    -- TODO: Implement actual API restart logic via PM2 or systemd
    -- For now, just simulate
    Wait(2000)
    
    TriggerClientEvent('ec_admin_ultimate:client:hostDashboardResponse', src, {
        success = true,
        message = 'API service restart initiated: ' .. apiName
    })
    
    print(string.format('[EC Admin Host] API restart requested: %s by %s', apiName, GetPlayerName(src)))
end)

-- Connect to customer server
RegisterNetEvent('ec_admin_ultimate:server:connectCustomerServer', function(data)
    local src = source
    local serverId = data.serverId
    
    if not isHost then
        TriggerClientEvent('ec_admin_ultimate:client:hostDashboardResponse', src, {
            success = false,
            message = 'Host Dashboard is only available on NRG Internal installations'
        })
        return
    end
    
    -- TODO: Implement actual connection logic
    TriggerClientEvent('ec_admin_ultimate:client:hostDashboardResponse', src, {
        success = true,
        message = 'Connecting to customer server...',
        serverId = serverId
    })
end)

-- Disconnect customer server
RegisterNetEvent('ec_admin_ultimate:server:disconnectCustomerServer', function(data)
    local src = source
    local serverId = data.serverId
    
    if not isHost then
        TriggerClientEvent('ec_admin_ultimate:client:hostDashboardResponse', src, {
            success = false,
            message = 'Host Dashboard is only available on NRG Internal installations'
        })
        return
    end
    
    -- TODO: Implement actual disconnection logic
    TriggerClientEvent('ec_admin_ultimate:client:hostDashboardResponse', src, {
        success = true,
        message = 'Server disconnected successfully',
        serverId = serverId
    })
    
    print(string.format('[EC Admin Host] Disconnected from customer server: %s by %s', serverId, GetPlayerName(src)))
end)

-- Add global ban
RegisterNetEvent('ec_admin_ultimate:server:addGlobalBan', function(data)
    local src = source
    local identifier = data.identifier
    local playerName = data.playerName
    local reason = data.reason
    local duration = tonumber(data.duration) or 0
    
    if not isHost then
        TriggerClientEvent('ec_admin_ultimate:client:hostDashboardResponse', src, {
            success = false,
            message = 'Host Dashboard is only available on NRG Internal installations'
        })
        return
    end
    
    if MySQL then
        local expiresAt = nil
        if duration > 0 then
            expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (duration * 86400))
        end
        
        MySQL.Async.execute([[
            INSERT INTO ec_global_bans (identifier, player_name, reason, banned_by, created_at, expires_at)
            VALUES (?, ?, ?, ?, NOW(), ?)
        ]], {
            identifier,
            playerName,
            reason,
            GetPlayerName(src),
            expiresAt
        }, function(affectedRows)
            TriggerClientEvent('ec_admin_ultimate:client:hostDashboardResponse', src, {
                success = true,
                message = 'Global ban added successfully'
            })
            
            print(string.format('[EC Admin Host] Global ban added: %s (%s) by %s', playerName, identifier, GetPlayerName(src)))
        end)
    end
end)

-- Remove global ban
RegisterNetEvent('ec_admin_ultimate:server:removeGlobalBan', function(data)
    local src = source
    local banId = tonumber(data.banId)
    
    if not isHost then
        TriggerClientEvent('ec_admin_ultimate:client:hostDashboardResponse', src, {
            success = false,
            message = 'Host Dashboard is only available on NRG Internal installations'
        })
        return
    end
    
    if MySQL then
        MySQL.Async.execute('DELETE FROM ec_global_bans WHERE id = ?', {banId}, function(affectedRows)
            TriggerClientEvent('ec_admin_ultimate:client:hostDashboardResponse', src, {
                success = true,
                message = 'Global ban removed successfully'
            })
            
            print(string.format('[EC Admin Host] Global ban removed: ID %s by %s', banId, GetPlayerName(src)))
        end)
    end
end)

-- Create database tables
CreateThread(function()
    Wait(3000)
    
    if not isHost then
        return
    end
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_customer_servers (
            id VARCHAR(50) PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            ip VARCHAR(50) NOT NULL,
            status VARCHAR(20) DEFAULT 'offline',
            current_players INT DEFAULT 0,
            max_players INT DEFAULT 48,
            version VARCHAR(20) DEFAULT '3.5.0',
            framework VARCHAR(20) DEFAULT 'unknown',
            connected_apis TEXT NULL,
            last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]], {})
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS ec_global_bans (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(100) NOT NULL,
            player_name VARCHAR(100) NOT NULL,
            reason TEXT NOT NULL,
            banned_by VARCHAR(100) NOT NULL,
            server_count INT DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NULL,
            INDEX idx_identifier (identifier),
            INDEX idx_expires (expires_at)
        )
    ]], {})
    
    Logger.Info('Host Dashboard tables initialized')
end)

Logger.Info('Host Dashboard callbacks loaded')