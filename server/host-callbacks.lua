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
    
    -- NOTE: host-api-management-callbacks.lua has a duplicate but is not loaded
    
    -- Mock data for now (would call actual API)
    return {
        apiName = apiName,
        logs = {
            {
                id = 1,
                timestamp = os.time() - 300,
                level = 'info',
                message = 'API started successfully',
                details = {}
            },
            {
                id = 2,
                timestamp = os.time() - 240,
                level = 'info',
                message = 'Connection established from city-001',
                details = {cityId = 'city-001'}
            },
            {
                id = 3,
                timestamp = os.time() - 180,
                level = 'warn',
                message = 'High response time detected',
                details = {responseTime = 523}
            },
            {
                id = 4,
                timestamp = os.time() - 120,
                level = 'error',
                message = 'Connection timeout to database',
                details = {error = 'ETIMEDOUT'}
            },
            {
                id = 5,
                timestamp = os.time() - 60,
                level = 'info',
                message = 'Database connection restored',
                details = {}
            }
        },
        totalLogs = 1234,
        filters = filters
    }
end)

-- Get API metrics
-- ✅ CANONICAL VERSION - This is the primary implementation
lib.callback.register('ec_admin:host:getAPIMetrics', function(source, apiName, timeRange)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    -- NOTE: host-api-management-callbacks.lua has a duplicate but is not loaded
    
    -- Mock data for now (would call actual API)
    local metrics = {
        apiName = apiName,
        timeRange = timeRange or '1h',
        data = {
            requests = {},
            responseTime = {},
            errors = {},
            cpu = {},
            memory = {}
        }
    }
    
    -- Generate sample data points
    for i = 1, 60 do
        table.insert(metrics.data.requests, {
            timestamp = os.time() - (60 - i) * 60,
            value = math.random(50, 200)
        })
        table.insert(metrics.data.responseTime, {
            timestamp = os.time() - (60 - i) * 60,
            value = math.random(20, 150)
        })
        table.insert(metrics.data.errors, {
            timestamp = os.time() - (60 - i) * 60,
            value = math.random(0, 5)
        })
        table.insert(metrics.data.cpu, {
            timestamp = os.time() - (60 - i) * 60,
            value = math.random(20, 80)
        })
        table.insert(metrics.data.memory, {
            timestamp = os.time() - (60 - i) * 60,
            value = math.random(512, 2048)
        })
    end
    
    return metrics
end)

-- Get API configuration
lib.callback.register('ec_admin:host:getAPIConfig', function(source, apiName)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    -- Mock data for now (would read actual config)
    return {
        apiName = apiName,
        config = {
            enabled = true,
            port = 30000,
            maxConnections = 100,
            timeout = 30000,
            rateLimiting = {
                enabled = true,
                maxRequests = 1000,
                timeWindow = 60
            },
            authentication = {
                required = true,
                methods = {'api-key', 'jwt'}
            },
            logging = {
                level = 'info',
                maxSize = '100MB',
                retention = 7
            }
        }
    }
end)

-- Get city analytics
lib.callback.register('ec_admin:host:getCityAnalytics', function(source, cityId, timeRange)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    -- Mock data for now (would aggregate from analytics API)
    return {
        cityId = cityId,
        timeRange = timeRange or '24h',
        analytics = {
            playerCount = {
                current = 48,
                peak = 64,
                average = 42,
                trend = '+12%'
            },
            performance = {
                avgTps = 49.8,
                avgCpu = 45.5,
                avgMemory = 2048,
                uptime = 99.8
            },
            events = {
                total = 12456,
                playerJoin = 234,
                playerLeave = 198,
                adminActions = 45,
                reports = 12
            },
            apiUsage = {
                ['global-bans'] = 245,
                ['player-tracking'] = 1234,
                ['anticheat-sync'] = 567,
                ['analytics'] = 890
            }
        }
    }
end)

-- Get all cities analytics (aggregate)
lib.callback.register('ec_admin:host:getAllCitiesAnalytics', function(source, timeRange)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    -- Mock data for now (would aggregate from all cities)
    return {
        timeRange = timeRange or '24h',
        totalCities = 12,
        onlineCities = 11,
        totalPlayers = 384,
        totalRequests = 145678,
        totalBans = 156,
        totalReports = 89,
        avgUptime = 99.8,
        topAPIs = {
            {name = 'player-tracking', requests = 45678},
            {name = 'global-bans', requests = 23456},
            {name = 'analytics', requests = 19876},
            {name = 'anticheat-sync', requests = 15432},
            {name = 'config-sync', requests = 12345}
        }
    }
end)

-- Get API health checks
lib.callback.register('ec_admin:host:getAPIHealthChecks', function(source)
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    -- Mock data for now (would run actual health checks)
    local apis = exports['ec_admin_ultimate']:GetAPIsStatus()
    local healthChecks = {}
    
    for _, api in ipairs(apis) do
        table.insert(healthChecks, {
            apiName = api.name,
            status = api.status,
            lastCheck = os.time(),
            checks = {
                {name = 'HTTP', status = 'pass', responseTime = math.random(10, 50)},
                {name = 'Database', status = 'pass', responseTime = math.random(5, 30)},
                {name = 'Cache', status = 'pass', responseTime = math.random(1, 10)},
                {name = 'Storage', status = 'pass', responseTime = math.random(5, 20)}
            }
        })
    end
    
    return healthChecks
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
