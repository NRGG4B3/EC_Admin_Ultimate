--[[
    EC Admin Ultimate - Unified HTTP & NUI Router
    SINGLE SetHttpHandler for ALL endpoints
    All endpoints return valid JSON, never HTML/text
    
    Ground Rules:
    - Keep all existing fetch paths identical
    - Always return valid JSON (even on errors)
    - Never throw/crash - graceful fallbacks
    - Host endpoints protected by secret
    - Rate limiting on sensitive endpoints
]]

-- Use global Config from shared_scripts (config/runtime-config.lua)
local Config = _G.ECAdminConfig or Config or {}

-- Rate limiting state
local RateLimiter = {
    requests = {},
    windowSize = 60000, -- 60 seconds
    maxRequests = {
        default = 60,     -- 60 req/min for most endpoints
        sensitive = 10,   -- 10 req/min for sensitive endpoints
        host = 120        -- 120 req/min for host endpoints
    }
}

-- Sensitive endpoints that need stricter rate limiting
local sensitiveEndpoints = {
    ['/api/host/toggle-web'] = true,
    ['/api/host/restart'] = true,
    ['/api/host/stop'] = true,
    ['/api/webhook/test'] = true,
    ['/api/auth/host'] = true
}

-- Check rate limit for IP and endpoint
local function CheckRateLimit(ip, endpoint)
    local now = GetGameTimer()
    local key = ip .. ':' .. endpoint
    
    -- Initialize tracking for this key
    if not RateLimiter.requests[key] then
        RateLimiter.requests[key] = {}
    end
    
    -- Remove old requests outside window
    local requests = RateLimiter.requests[key]
    for i = #requests, 1, -1 do
        if now - requests[i] > RateLimiter.windowSize then
            table.remove(requests, i)
        end
    end
    
    -- Determine limit based on endpoint type
    local limit = RateLimiter.maxRequests.default
    if sensitiveEndpoints[endpoint] then
        limit = RateLimiter.maxRequests.sensitive
    elseif endpoint:match('^/api/host/') then
        limit = RateLimiter.maxRequests.host
    end
    
    -- Check if over limit
    if #requests >= limit then
        return false, string.format('Rate limit exceeded: %d requests per minute allowed', limit)
    end
    
    -- Record this request
    table.insert(requests, now)
    return true, nil
end

-- Validate host secret for /api/host/* endpoints
local function ValidateHostSecret(headers)
    local hostSecret = GetConvar('ec_host_secret', '')
    
    if hostSecret == '' then
        -- No secret configured - auto-generate one
        hostSecret = string.format('%x%x%x', 
            math.random(0, 0xFFFFFFFF),
            math.random(0, 0xFFFFFFFF),
            os.time()
        )
        SetConvar('ec_host_secret', hostSecret)
        if Logger and Logger.Warn then
            Logger.Warn('[Router] Generated new host secret (persist in server.cfg): ' .. hostSecret)
            Logger.Warn('Set in server.cfg: setr ec_host_secret "' .. hostSecret .. '"')
        else
            print('^3[Router] WARNING: Generated new host secret: ' .. hostSecret .. '^7')
            print('^3[Router] Set in server.cfg: setr ec_host_secret "' .. hostSecret .. '"^7')
        end
    end
    
    -- Check header
    local providedSecret = headers['x-host-secret'] or headers['X-Host-Secret']
    
    if providedSecret == hostSecret then
        return true, nil
    else
        return false, 'Invalid or missing host secret'
    end
end

-- Get client IP from request
local function GetClientIP(req)
    return req.address or 'unknown'
end

-- Log API request
local function LogRequest(method, path, status, duration, ip)
    local msg = string.format('[API] %s %s %d %dms [%s]', method, path, status, duration or 0, ip or 'unknown')
    if Logger and Logger.Info then
        if status >= 500 then
            Logger.Error(msg)
        elseif status >= 400 then
            Logger.Warn(msg)
        else
            Logger.Info(msg)
        end
    else
        local statusColor = status < 300 and '^2' or (status < 500 and '^3' or '^1')
        print(string.format('[API] %s %s %s%d^7 %dms [%s]', method, path, statusColor, status, duration or 0, ip or 'unknown'))
    end
end

--[[ ==================== ENDPOINT HANDLERS ==================== ]]--

-- /api/health - Health check
local function HandleHealth()
    return {
        ok = true,
        ts = os.time(),
        uptime = os.time() - (_G.ECAdminStartTime or os.time()),
        version = Config.Version or '3.5.0',
        mode = _G.ECEnvironment and _G.ECEnvironment.GetMode() or 'UNKNOWN'
    }
end

-- /api/status - System status (extended health check)
local function HandleStatus()
    local dbStatus = MySQL and MySQL.ready and 'connected' or 'disconnected'
    local mode = _G.ECEnvironment and _G.ECEnvironment.GetMode() or 'CUSTOMER'
    
    return {
        success = true,
        status = 'healthy',
        version = Config.Version or '3.5.0',
        uptime = os.time() - (_G.ECAdminStartTime or os.time()),
        mode = mode,
        database = {
            status = dbStatus,
            type = Config.Database and Config.Database.UseOxMySQL and 'oxmysql' or 'mysql-async'
        },
        framework = {
            status = _G.ECFramework and 'detected' or 'standalone',
            type = Config.Server and Config.Server.Framework or 'standalone'
        },
        features = {
            remoteAdmin = Config.RemoteAdmin and Config.RemoteAdmin.Enabled or false,
            webhooks = Config.Webhook and Config.Webhook.Enabled or false,
            analytics = Config.APIs and Config.APIs.Analytics and Config.APIs.Analytics.Enabled or false
        }
    }
end

-- /api/setup/status - Setup wizard status
local function HandleSetupStatus()
    return {
        success = true,
        setupComplete = _G.ECSetupComplete or false,
        frameworkDetected = _G.ECFramework and true or false,
        databaseConnected = MySQL and MySQL.ready and true or false
    }
end

-- /api/setup/detectFramework - Detect framework
local function HandleSetupDetectFramework()
    local framework = _G.ECFramework and _G.ECFramework.Type or 'standalone'
    
    return {
        success = true,
        framework = framework
    }
end

-- /api/setup/testDatabase - Test database connection
local function HandleSetupTestDatabase(data)
    local dbConfig = data.dbConfig
    
    if not dbConfig then
        return { success = false, error = 'Missing dbConfig parameter' }
    end
    
    -- Attempt to connect to database
    local success, err = pcall(function()
        MySQL.ready = false
        MySQL.connect(dbConfig)
    end)
    
    if success then
        return {
            success = true,
            message = 'Database connection successful'
        }
    else
        return {
            success = false,
            error = 'Database connection failed: ' .. err
        }
    end
end

-- /api/setup/validateSchema - Validate database schema
local function HandleSetupValidateSchema(data)
    local dbConfig = data.dbConfig
    
    if not dbConfig then
        return { success = false, error = 'Missing dbConfig parameter' }
    end
    
    -- Attempt to validate schema
    local success, err = pcall(function()
        MySQL.ready = false
        MySQL.connect(dbConfig)
        MySQL.query('SELECT 1 FROM users LIMIT 1') -- Example query to check schema
    end)
    
    if success then
        return {
            success = true,
            message = 'Database schema is valid'
        }
    else
        return {
            success = false,
            error = 'Database schema validation failed: ' .. err
        }
    end
end

-- /api/setup/writeConfig - Write configuration file
local function HandleSetupWriteConfig(data)
    local configData = data.configData
    
    if not configData then
        return { success = false, error = 'Missing configData parameter' }
    end
    
    -- Write config file
    local configFile = io.open('config/runtime-config.lua', 'w')
    if not configFile then
        return { success = false, error = 'Failed to open config file for writing' }
    end
    
    configFile:write('Config = ' .. json.encode(configData, { indent = true }))
    configFile:close()
    
    return {
        success = true,
        message = 'Configuration file written successfully'
    }
end

-- /api/setup/buildUI - Build UI
local function HandleSetupBuildUI(data)
    local uiData = data.uiData
    
    if not uiData then
        return { success = false, error = 'Missing uiData parameter' }
    end
    
    -- Runtime UI build is not supported. Keep build in CI/setup.
    local message = 'Runtime UI build is not supported. Use setup.bat/build pipeline.'
    if Logger and Logger.Warn then Logger.Warn('[Router] ' .. message) end
    return { success = false, error = message }
end

-- /api/setup/complete - Complete setup
local function HandleSetupComplete(data)
    local setupData = data.setupData
    
    if not setupData then
        return { success = false, error = 'Missing setupData parameter' }
    end
    
    -- Mark setup as complete
    _G.ECSetupComplete = true
    
    return {
        success = true,
        message = 'Setup completed successfully'
    }
end

-- /api/metrics - Current metrics snapshot
local function HandleMetrics()
    if _G.GetCurrentMetrics then
        return _G.GetCurrentMetrics()
    else
        -- Fallback if metrics-sampler not loaded yet
        return {
            success = true,
            metrics = {
                time = os.time(),
                timeFormatted = os.date('%H:%M:%S'),
                players = #GetPlayers(),
                maxPlayers = GetConvarInt('sv_maxclients', 64),
                tps = 60,
                memory = collectgarbage('count') / 1024,
                cpu = 0,
                avgPing = 0,
                maxPing = 0
            }
        }
    end
end

-- /api/metrics/history - Historical metrics data
local function HandleMetricsHistory()
    if _G.GetMetricsHistory then
        return _G.GetMetricsHistory()
    else
        -- Fallback - return empty but valid structure
        return {
            success = true,
            history = {},
            count = 0,
            message = 'Metrics sampler initializing...'
        }
    end
end

-- /api/players - Get all online players
local function HandleGetPlayers()
    local players = {}
    local playerList = GetPlayers()
    
    for _, playerId in ipairs(playerList) do
        local id = tonumber(playerId)
        if id then
            table.insert(players, {
                id = id,
                name = GetPlayerName(id) or 'Unknown',
                ping = GetPlayerPing(id) or 0,
                identifiers = GetPlayerIdentifiers(id) or {}
            })
        end
    end
    
    return {
        success = true,
        players = players,
        count = #players,
        max = GetConvarInt('sv_maxclients', 64)
    }
end

-- /api/resources - Get all resources
local function HandleGetResources()
    local resources = {}
    local totalResources = GetNumResources()
    
    for i = 0, totalResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local state = GetResourceState(resourceName)
            table.insert(resources, {
                name = resourceName,
                state = state,
                isStarted = state == 'started'
            })
        end
    end
    
    return {
        success = true,
        resources = resources,
        count = #resources
    }
end

-- /api/host/status - Get host service status (HOST ONLY)
local function HandleHostStatus()
    local mode = _G.ECEnvironment and _G.ECEnvironment.GetMode() or 'CUSTOMER'
    
    return {
        success = true,
        mode = mode,
        isHost = mode == 'HOST',
        services = {
            webAdmin = {
                enabled = GetConvar('ec_web_admin_enabled', 'true') == 'true',
                status = 'running'
            }
        },
        timestamp = os.time()
    }
end

-- /api/host/toggle-web - Toggle web admin (HOST ONLY)
local function HandleHostToggleWeb(data)
    local enabled = data.enabled
    
    if enabled == nil then
        return { success = false, error = 'Missing enabled parameter' }
    end
    
    -- Set convar
    SetConvar('ec_web_admin_enabled', tostring(enabled))
    
    -- Log action
    if Logger and Logger.Info then
        Logger.Info(string.format('[Router] Web admin %s', enabled and 'ENABLED' or 'DISABLED'))
    else
        print(string.format('[Router] Web admin %s', enabled and 'ENABLED' or 'DISABLED'))
    end
    
    return {
        success = true,
        enabled = enabled,
        message = string.format('Web admin %s', enabled and 'enabled' or 'disabled')
    }
end

-- /api/host/start - Start a FiveM resource (HOST ONLY)
local function HandleHostStart(data)
    local service = data.service or 'unknown'
    local state = GetResourceState(service)
    if not state or state == 'missing' then
        return { success = false, error = 'Unknown resource: ' .. tostring(service) }
    end
    if state == 'started' then
        return { success = true, service = service, action = 'start', message = 'Resource already started' }
    end
    local ok = StartResource(service)
    if ok then
        if Logger and Logger.Info then Logger.Info('[Router] Started resource: ' .. service) end
        return { success = true, service = service, action = 'start', message = 'Resource start initiated' }
    else
        if Logger and Logger.Error then Logger.Error('[Router] Failed to start resource: ' .. service) end
        return { success = false, error = 'Failed to start resource ' .. service }
    end
end

-- /api/host/stop - Stop a FiveM resource (HOST ONLY)
local function HandleHostStop(data)
    local service = data.service or 'unknown'
    local state = GetResourceState(service)
    if not state or state == 'missing' then
        return { success = false, error = 'Unknown resource: ' .. tostring(service) }
    end
    if state ~= 'started' then
        return { success = true, service = service, action = 'stop', message = 'Resource already stopped' }
    end
    local ok = StopResource(service)
    if ok then
        if Logger and Logger.Info then Logger.Info('[Router] Stopped resource: ' .. service) end
        return { success = true, service = service, action = 'stop', message = 'Resource stop initiated' }
    else
        if Logger and Logger.Error then Logger.Error('[Router] Failed to stop resource: ' .. service) end
        return { success = false, error = 'Failed to stop resource ' .. service }
    end
end

-- /api/host/restart - Restart a FiveM resource (HOST ONLY)
local function HandleHostRestart(data)
    local service = data.service or 'unknown'
    local state = GetResourceState(service)
    if not state or state == 'missing' then
        return { success = false, error = 'Unknown resource: ' .. tostring(service) }
    end
    local ok = ExecuteCommand('restart ' .. service)
    if Logger and Logger.Info then Logger.Info('[Router] Restart command issued for resource: ' .. service) end
    return { success = true, service = service, action = 'restart', message = 'Resource restart issued' }
end

-- /host/toggle - Host-only admin menu toggle
local function HandleHostToggle(req, res)
    if _G.ECHostToggleHandler then
        _G.ECHostToggleHandler(req, res)
    else
        res.writeHead(503, { ['Content-Type'] = 'application/json' })
        res.send(json.encode({ 
            success = false, 
            error = 'Host toggle handler not initialized' 
        }))
    end
end

-- /host/rotate-token - Host-only token rotation
local function HandleHostRotateToken(req, res)
    if _G.ECTokenRotateHandler then
        _G.ECTokenRotateHandler(req, res)
    else
        res.writeHead(503, { ['Content-Type'] = 'application/json' })
        res.send(json.encode({ success = false, error = 'Token rotation not initialized' }))
    end
end

--[[ ==================== MAIN HTTP HANDLER ==================== ]]--

SetHttpHandler(function(req, res)
    local startTime = GetGameTimer()
    local path = req.path
    local method = req.method
    local ip = GetClientIP(req)
    
    -- DEBUG: Log every request (respect logger if available)
    if Logger and Logger.Debug then
        Logger.Debug(string.format('[Router DEBUG] %s %s from %s', method, path, ip))
    else
        print(string.format('^3[Router DEBUG] %s %s from %s^7', method, path, ip))
    end
    
    -- Check if admin menu is disabled
    if not _G.ECAdminMenuEnabled and path:match('^/api/') and not path:match('^/api/health') then
        res.writeHead(403, { ['Content-Type'] = 'application/json' })
        res.send(json.encode({
            success = false,
            error = 'Admin menu disabled by host',
            message = 'The admin panel has been temporarily disabled. Contact server owner.'
        }))
        LogRequest(method, path, 403, GetGameTimer() - startTime, ip)
        return
    end
    
    -- Set CORS headers
    local allowedOrigins = Config.Security and Config.Security.CORS and Config.Security.CORS.AllowedOrigins or '*'
    res.setHeader('Access-Control-Allow-Origin', allowedOrigins)
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Host-Secret')
    
    -- Handle OPTIONS preflight
    if method == 'OPTIONS' then
        res.writeHead(200)
        res.send('')
        return
    end
    
    -- Rate limiting check
    local rateLimitOk, rateLimitErr = CheckRateLimit(ip, path)
    if not rateLimitOk then
        res.writeHead(429, { ['Content-Type'] = 'application/json' })
        res.send(json.encode({
            success = false,
            error = rateLimitErr
        }))
        LogRequest(method, path, 429, GetGameTimer() - startTime, ip)
        return
    end
    
    -- Host endpoint protection
    if path:match('^/api/host/') or path:match('^/host/') then
        -- CRITICAL SECURITY: Validate host access with multi-layer protection
        -- This checks: License key, IP allowlist, and NRG API validation
        local accessGranted = false
        
        if _G.ValidateHostAccess then
            -- Use new security validator (blocks even if someone has the UI password)
            _G.ValidateHostAccess(req, function(valid, message)
                if not valid then
                    res.writeHead(403, { ['Content-Type'] = 'application/json' })
                    res.send(json.encode({
                        success = false,
                        error = 'Host access denied',
                        message = message,
                        hint = 'Contact NRG Network to obtain a host-tier license'
                    }))
                    LogRequest(method, path, 403, GetGameTimer() - startTime, ip)
                    if Logger and Logger.Warn then Logger.Warn(string.format('[Router] Host access denied for %s: %s', ip, message)) end
                    return
                end
                accessGranted = true
            end)
            
            -- Wait for validation (synchronous check)
            if not accessGranted then
                return
            end
        else
            -- Fallback: Old validation (should never happen)
            local isValid, err = ValidateHostSecret(req.headers)
            if not isValid then
                res.writeHead(401, { ['Content-Type'] = 'application/json' })
                res.send(json.encode({
                    success = false,
                    error = err
                }))
                LogRequest(method, path, 401, GetGameTimer() - startTime, ip)
                return
            end
        end
    end
    
    -- Parse request body if present
    local data = {}
    if req.body and req.body ~= '' then
        local success, parsed = pcall(json.decode, req.body)
        if success then
            data = parsed
        end
    end
    
    -- Route request to handler
    local result, status
    
    -- Serve UI files for /admin and root paths
    if path == '/admin' or path == '/admin/' or path == '/' then
        -- Serve index.html using LoadResourceFile
        local htmlContent = LoadResourceFile(GetCurrentResourceName(), 'ui/dist/index.html')
        
        if htmlContent then
            res.writeHead(200, { ['Content-Type'] = 'text/html; charset=utf-8' })
            res.send(htmlContent)
            LogRequest(method, path, 200, GetGameTimer() - startTime, ip)
        else
            res.writeHead(404, { ['Content-Type'] = 'text/plain' })
            res.send('UI not built. Run setup.bat first.')
            LogRequest(method, path, 404, GetGameTimer() - startTime, ip)
        end
        return
    elseif path:match('^/assets/') then
        -- Serve static assets from ui/dist/assets/
        local filePath = 'ui/dist' .. path
        local fileContent = LoadResourceFile(GetCurrentResourceName(), filePath)
        
        if fileContent then
            -- Determine content type from extension
            local contentType = 'application/octet-stream'
            if path:match('%.js$') then
                contentType = 'application/javascript; charset=utf-8'
            elseif path:match('%.css$') then
                contentType = 'text/css; charset=utf-8'
            elseif path:match('%.png$') then
                contentType = 'image/png'
            elseif path:match('%.jpg$') or path:match('%.jpeg$') then
                contentType = 'image/jpeg'
            elseif path:match('%.svg$') then
                contentType = 'image/svg+xml'
            elseif path:match('%.woff2$') then
                contentType = 'font/woff2'
            elseif path:match('%.woff$') then
                contentType = 'font/woff'
            elseif path:match('%.ttf$') then
                contentType = 'font/ttf'
            end
            
            res.writeHead(200, { ['Content-Type'] = contentType })
            res.send(fileContent)
            LogRequest(method, path, 200, GetGameTimer() - startTime, ip)
        else
            res.writeHead(404, { ['Content-Type'] = 'text/plain' })
            res.send('Asset not found: ' .. path)
            LogRequest(method, path, 404, GetGameTimer() - startTime, ip)
        end
        return
    end
    
    -- Public endpoints
    if path == '/api/health' then
        result = HandleHealth()
        status = 200
    elseif path == '/api/status' then
        result = HandleStatus()
        status = 200
        
    -- Setup wizard endpoints (before auth check)
    elseif path == '/api/setup/status' then
        result = HandleSetupStatus()
        status = 200
    elseif path == '/api/setup/detectFramework' then
        result = HandleSetupDetectFramework()
        status = 200
    elseif path == '/api/setup/testDatabase' and method == 'POST' then
        result = HandleSetupTestDatabase(data)
        status = 200
    elseif path == '/api/setup/validateSchema' and method == 'POST' then
        result = HandleSetupValidateSchema(data)
        status = 200
    elseif path == '/api/setup/writeConfig' and method == 'POST' then
        result = HandleSetupWriteConfig(data)
        status = 200
    elseif path == '/api/setup/buildUI' and method == 'POST' then
        result = HandleSetupBuildUI(data)
        status = 200
    elseif path == '/api/setup/complete' and method == 'POST' then
        result = HandleSetupComplete(data)
        status = 200
        
    -- Regular endpoints
    elseif path == '/api/metrics' then
        result = HandleMetrics()
        status = 200
    elseif path == '/api/metrics/history' then
        result = HandleMetricsHistory()
        status = 200
    elseif path == '/api/players' then
        result = HandleGetPlayers()
        status = 200
    elseif path == '/api/resources' then
        result = HandleGetResources()
        status = 200
        
    -- Host-only endpoints
    elseif path == '/api/host/status' then
        result = HandleHostStatus()
        status = 200
    elseif path == '/api/host/toggle-web' then
        result = HandleHostToggleWeb(data)
        status = 200
    elseif path == '/api/host/start' then
        result = HandleHostStart(data)
        status = 200
    elseif path == '/api/host/stop' then
        result = HandleHostStop(data)
        status = 200
    elseif path == '/api/host/restart' then
        result = HandleHostRestart(data)
        status = 200
    elseif path == '/host/toggle' then
        -- Special handling - uses req/res directly
        HandleHostToggle(req, res)
        LogRequest(method, path, 200, GetGameTimer() - startTime, ip)
        return
        
    elseif path == '/host/rotate-token' then
        -- Special handling - uses req/res directly
        HandleHostRotateToken(req, res)
        LogRequest(method, path, 200, GetGameTimer() - startTime, ip)
        return
        
    -- Unknown endpoint
    else
        result = {
            success = false,
            error = 'Endpoint not found',
            path = path
        }
        status = 404
    end
    
    -- Send response
    res.writeHead(status, { ['Content-Type'] = 'application/json' })
    res.send(json.encode(result))
    
    -- Log request
    LogRequest(method, path, status, GetGameTimer() - startTime, ip)
end)

-- Initialize
CreateThread(function()
    Wait(100)
    
    -- Register host toggle/token-rotate handlers as local events and initialize defaults
    AddEventHandler('ec:host:registerToggleEndpoint', function()
        -- Default to enabled unless explicitly disabled by convar
        if _G.ECAdminMenuEnabled == nil then
            _G.ECAdminMenuEnabled = GetConvar('ec_web_admin_enabled', 'true') == 'true'
        end

        _G.ECHostToggleHandler = function(req, res)
            local success, payload = pcall(function()
                local body = {}
                if req.body and req.body ~= '' then
                    local ok, parsed = pcall(json.decode, req.body)
                    if ok and type(parsed) == 'table' then body = parsed end
                end
                local enabled = body.enabled
                if enabled == nil then enabled = not _G.ECAdminMenuEnabled end
                _G.ECAdminMenuEnabled = enabled and true or false
                SetConvar('ec_web_admin_enabled', tostring(_G.ECAdminMenuEnabled))
                if Logger and Logger.Info then Logger.Info(string.format('[Host] Admin menu %s by host toggle', _G.ECAdminMenuEnabled and 'ENABLED' or 'DISABLED')) end
                return { success = true, enabled = _G.ECAdminMenuEnabled }
            end)
            if not success then
                res.writeHead(500, { ['Content-Type'] = 'application/json' })
                res.send(json.encode({ success = false, error = 'Failed to toggle admin menu' }))
                return
            end
            res.writeHead(200, { ['Content-Type'] = 'application/json' })
            res.send(json.encode(payload))
        end

        _G.ECTokenRotateHandler = function(req, res)
            local newSecret = string.format('%x%x%x', math.random(0, 0xFFFFFFFF), math.random(0, 0xFFFFFFFF), os.time())
            SetConvar('ec_host_secret', newSecret)
            if Logger and Logger.Info then Logger.Info('[Host] Rotated host secret token') end
            res.writeHead(200, { ['Content-Type'] = 'application/json' })
            res.send(json.encode({ success = true, message = 'Host secret rotated', secretHint = string.sub(newSecret, 1, 6) .. '...' }))
        end
    end)

    -- Fire the local registration event immediately
    TriggerEvent('ec:host:registerToggleEndpoint')
    
    _G.ECAdminStartTime = os.time()
    
    -- Only show HTTP Router info if verbose logging enabled
    if not Config.Logging or Config.Logging.verboseStartup then
        local lines = {
            '========================================',
            '[EC Admin Ultimate] HTTP Router Active',
            '  Resource: ' .. GetCurrentResourceName(),
            '  Web UI:',
            '    GET  /           (redirect to admin)',
            '    GET  /admin      (setup wizard & admin panel)',
            '    GET  /assets/*   (static files)',
            '  Public Endpoints:',
            '    GET  /api/health',
            '    GET  /api/status',
            '    GET  /api/metrics',
            '    GET  /api/metrics/history',
            '    GET  /api/players',
            '    GET  /api/resources',
            '  Setup Endpoints:',
            '    GET  /api/setup/status',
            '    POST /api/setup/detectFramework',
            '    POST /api/setup/complete',
            '  Host Endpoints:',
            '    GET  /api/host/status',
            '    POST /api/host/toggle-web',
            '    POST /api/host/start',
            '    POST /api/host/stop',
            '    POST /api/host/restart',
            '    POST /host/toggle',
            '    POST /host/rotate-token',
            '  Security:',
            '    Rate Limiting: Enabled',
            '    CORS: ' .. (Config.Security and Config.Security.CORS and 'Enabled' or 'Disabled'),
            '    Host Secret: ' .. (GetConvar('ec_host_secret', '') ~= '' and 'Configured' or 'Auto-generated'),
            '========================================',
            'Access web UI at: http://YOUR_IP:30120/admin',
            'Test health check: http://YOUR_IP:30120/api/health',
            '========================================'
        }
        if Logger and Logger.System then
            for _, l in ipairs(lines) do Logger.System(l) end
        else
            print('^2========================================^0')
            print('^2[EC Admin Ultimate] HTTP Router Active^0')
            print('^3  Resource: ' .. GetCurrentResourceName() .. '^0')
            print('^3  Web UI:^0')
            print('    GET  /           (redirect to admin)')
            print('    GET  /admin      (setup wizard & admin panel)')
            print('    GET  /assets/*   (static files)')
            print('^3  Public Endpoints:^0')
            print('    GET  /api/health')
            print('    GET  /api/status')
            print('    GET  /api/metrics')
            print('    GET  /api/metrics/history')
            print('    GET  /api/players')
            print('    GET  /api/resources')
            print('^3  Setup Endpoints:^0')
            print('    GET  /api/setup/status')
            print('    POST /api/setup/detectFramework')
            print('    POST /api/setup/complete')
            print('^3  Host Endpoints:^0')
            print('    GET  /api/host/status')
            print('    POST /api/host/toggle-web')
            print('    POST /api/host/start')
            print('    POST /api/host/stop')
            print('    POST /api/host/restart')
            print('    POST /host/toggle')
            print('    POST /host/rotate-token')
            print('^3  Security:^0')
            print('    Rate Limiting: Enabled')
            print('    CORS: ' .. (Config.Security and Config.Security.CORS and 'Enabled' or 'Disabled'))
            print('    Host Secret: ' .. (GetConvar('ec_host_secret', '') ~= '' and 'Configured' or 'Auto-generated'))
            print('^2========================================^0')
            print('^3[INFO] Access web UI at: http://YOUR_IP:30120/admin^0')
            print('^3[INFO] Test health check: http://YOUR_IP:30120/api/health^0')
            print('^2========================================^0')
        end
    end
end)