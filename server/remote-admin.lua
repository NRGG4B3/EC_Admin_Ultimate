-- EC Admin Ultimate - Remote Admin Access System
-- Allows VPS administrators to access the admin panel remotely (like TXAdmin)
Logger.Info('🌐 Loading Remote Admin Access System...')

local RemoteAdmin = {}
local activeSessions = {}

-- Utility Functions
local function GenerateAuthKey()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    local key = ''
    for i = 1, 32 do
        local rand = math.random(1, #chars)
        key = key .. chars:sub(rand, rand)
    end
    return key
end

local function GenerateSessionId()
    return os.date('%Y%m%d%H%M%S') .. '_' .. math.random(100000, 999999)
end

local function GenerateSessionToken()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    local token = ''
    for i = 1, 64 do
        local rand = math.random(1, #chars)
        token = token .. chars:sub(rand, rand)
    end
    return token
end

local function GetServerIP()
    local convars = {
        GetConvar('ec_admin_public_ip', ''),
        GetConvar('sv_hostname', ''):match('(%d+%.%d+%.%d+%.%d+)') or '',
        '127.0.0.1'  -- Fallback
    }
    
    for _, ip in ipairs(convars) do
        if ip and ip ~= '' and ip ~= '127.0.0.1' then
            return ip
        end
    end
    
    return '127.0.0.1'
end

local function GenerateConnectionURL(sessionId, sessionToken, port)
    local serverIP = GetServerIP()
    local adminPort = port or Config.RemoteAdmin.port or 30121
    
    -- Generate secure connection URL
    return string.format('http://%s:%d/admin?session=%s&token=%s', 
        serverIP, adminPort, sessionId, sessionToken)
end

local function ValidateIP(ip)
    local settings = Config.RemoteAdmin
    if not settings or not settings.enabled then
        return false
    end
    
    -- If no IP whitelist, allow all
    if not settings.allowedIPs or #settings.allowedIPs == 0 then
        return true
    end
    
    -- Check if IP is in whitelist
    for _, allowedIP in ipairs(settings.allowedIPs) do
        if ip == allowedIP then
            return true
        end
    end
    
    return false
end

local function ValidateAuth(authKey)
    local settings = Config.RemoteAdmin
    if not settings or not settings.enabled then
        return false
    end
    
    if not settings.requireAuth then
        return true
    end
    
    local configKey = settings.authKey
    if not configKey or configKey == '' then
        -- Auto-generate and save
        configKey = GenerateAuthKey()
        Logger.Info('🔐 Auto-generated auth key: ' .. configKey)
        Logger.Info('🔐 Add this to your config.lua: Config.RemoteAdmin.authKey = "' .. configKey .. '"')
    end
    
    return authKey == configKey
end

local function GetEnabledFeatures(features)
    if not features then return {} end
    local enabled = {}
    for feature, isEnabled in pairs(features) do
        if isEnabled then
            table.insert(enabled, feature)
        end
    end
    if #enabled == 0 then
        return {'All Features'}
    end
    return enabled
end

-- Session Management
function RemoteAdmin.CreateSession(ip, authKey, userAgent)
    local settings = Config.RemoteAdmin
    if not settings or not settings.enabled then
        return { success = false, message = 'Remote admin is not enabled' }
    end
    
    -- Validate IP
    if not ValidateIP(ip) then
        Logger.Info(string.format('', ip))
        return { success = false, message = 'IP not authorized' }
    end
    
    -- Validate auth
    if not ValidateAuth(authKey) then
        Logger.Info(string.format('', ip))
        return { success = false, message = 'Invalid authentication key' }
    end
    
    -- Check max sessions (sessions never expire unless manually ended)
    local activeCount = 0
    local now = os.time() * 1000
    for sessionId, session in pairs(activeSessions) do
        activeCount = activeCount + 1
    end
    
    if activeCount >= (settings.maxSessions or 5) then
        return { success = false, message = 'Maximum concurrent sessions reached' }
    end
    
    -- Create session
    local sessionId = GenerateSessionId()
    local sessionToken = GenerateSessionToken()
    local connectionURL = GenerateConnectionURL(sessionId, sessionToken, settings.port)
    
    local session = {
        id = sessionId,
        token = sessionToken,
        ip = ip,
        userAgent = userAgent or 'Unknown',
        createdAt = now,
        lastActivity = now,
        features = settings.features or {},
        connectionURL = connectionURL
    }
    
    activeSessions[sessionId] = session
    
    Logger.Info(string.format('', sessionId, ip))
    Logger.Info(string.format('', connectionURL))
    Logger.Info('📋 Copy and paste this URL in your browser to access the admin panel')
    Logger.Info('⏱️  Session NEVER EXPIRES (valid until server restart or manually ended)')
    
    if settings.enableLogging and _G.ECWebhooks then
        _G.ECWebhooks.SendLog('security', {
            title = '🌐 Remote Admin Session Created',
            description = string.format('**New remote admin session created**\n\n🔗 **[Click here to access the admin panel](%s)**\n\nOr copy and paste this URL:\n```\n%s\n```\n\n⏱️ Session expires in %d minutes', 
                connectionURL, connectionURL, math.floor((settings.sessionTimeout or 3600000) / 60000)),
            color = 3447003,
            fields = {
                { name = 'Session ID', value = '`' .. sessionId .. '`', inline = true },
                { name = 'IP Address', value = ip, inline = true },
                { name = 'User Agent', value = userAgent or 'Unknown', inline = false },
                { name = 'Connection URL', value = '`' .. connectionURL .. '`', inline = false },
                { name = 'Features Enabled', value = table.concat(GetEnabledFeatures(session.features), ', '), inline = false }
            },
            footer = {
                text = 'EC Admin Ultimate - Remote Access',
                icon_url = 'https://i.imgur.com/4M34hi2.png'
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
        })
    end
    
    return {
        success = true,
        sessionId = sessionId,
        sessionToken = sessionToken,
        connectionURL = connectionURL,
        features = session.features,
        timeout = 999999999999 -- Never expires (effectively infinite)
    }
end

function RemoteAdmin.ValidateSession(sessionId, token)
    local session = activeSessions[sessionId]
    if not session then
        return false, 'Session not found'
    end
    
    -- Validate token if provided
    if token and session.token ~= token then
        return false, 'Invalid session token'
    end
    
    local now = os.time() * 1000
    
    -- Sessions never expire, no timeout check
    -- They remain valid until server restart or manually ended
    
    -- Update activity
    session.lastActivity = now
    return true, 'Session valid', session
end

function RemoteAdmin.EndSession(sessionId)
    if activeSessions[sessionId] then
        local session = activeSessions[sessionId]
        activeSessions[sessionId] = nil
        
        Logger.Info(string.format('', sessionId))
        
        if Config.RemoteAdmin and Config.RemoteAdmin.enableLogging and _G.ECWebhooks then
            _G.ECWebhooks.SendLog('security', {
                title = '🌐 Remote Admin Session Ended',
                description = string.format('Session ended: %s', sessionId),
                color = 10181046,
                fields = {
                    { name = 'Session ID', value = sessionId, inline = true },
                    { name = 'IP Address', value = session.ip, inline = true }
                }
            })
        end
        
        return { success = true, message = 'Session ended' }
    end
    
    return { success = false, message = 'Session not found' }
end

function RemoteAdmin.GetActiveSessions()
    local sessions = {}
    local now = os.time() * 1000
    
    for sessionId, session in pairs(activeSessions) do
        table.insert(sessions, {
            id = sessionId,
            ip = session.ip,
            userAgent = session.userAgent,
            createdAt = session.createdAt,
            lastActivity = session.lastActivity,
            connectionURL = session.connectionURL,
            active = true -- Sessions never expire
        })
    end
    
    return sessions
end

-- HTTP Endpoints (for remote access)
if Config.RemoteAdmin and Config.RemoteAdmin.enabled then
    -- Serve the admin panel HTML page
    SetHttpHandler(function(req, res)
        local path = req.path
        
        -- Handle /admin endpoint for remote admin access
        if path == '/admin' or string.match(path, '^/admin%?') then
            local query = {}
            if req.path:find('?') then
                local queryString = req.path:match('%?(.+)')
                if queryString then
                    for key, value in queryString:gmatch('([^&=]+)=([^&=]+)') do
                        query[key] = value
                    end
                end
            end
            
            local sessionId = query.session
            local token = query.token
            
            if not sessionId or not token then
                res.writeHead(400, {['Content-Type'] = 'text/html'})
                res.write('<html><body><h1>Invalid Request</h1><p>Missing session or token parameter.</p></body></html>')
                res.send()
                return
            end
            
            local isValid, message, session = RemoteAdmin.ValidateSession(sessionId, token)
            if not isValid then
                res.writeHead(403, {['Content-Type'] = 'text/html'})
                res.write('<html><body><h1>Access Denied</h1><p>' .. message .. '</p></body></html>')
                res.send()
                return
            end
            
            -- Serve the remote admin HTML
            -- Read the HTML file from the resource
            local htmlPath = GetResourcePath(GetCurrentResourceName()) .. '/ui/remote-admin.html'
            local file = io.open(htmlPath, 'r')
            
            if not file then
                res.writeHead(500, {['Content-Type'] = 'text/html'})
                res.write('<html><body><h1>Server Error</h1><p>Could not load admin panel.</p></body></html>')
                res.send()
                return
            end
            
            local html = file:read('*all')
            file:close()
            
            res.writeHead(200, {
                ['Content-Type'] = 'text/html',
                ['Cache-Control'] = 'no-cache, no-store, must-revalidate'
            })
            res.write(html)
            res.send()
            return
        end
        
        -- Default 404 for other paths
        res.writeHead(404, {['Content-Type'] = 'text/html'})
        res.write('<html><body><h1>Not Found</h1></body></html>')
        res.send()
    end)
    
    -- Session creation endpoint
    RegisterCommand('ec:remote:auth', function(source, args, rawCommand)
        if source ~= 0 then return end -- Console only
        
        local ip = args[1] or '127.0.0.1'
        local authKey = args[2] or Config.RemoteAdmin.authKey or ''
        
        local result = RemoteAdmin.CreateSession(ip, authKey, 'Console')
        
        if result.success then
            Logger.Info('🌐 ═══════════════════════════════════════════════════════════════')
            Logger.Info('✅ Remote Admin Session Created Successfully!')
            Logger.Info('═══════════════════════════════════════════════════════════════')
            Logger.Info('🔐 Session ID: ' .. result.sessionId)
            Logger.Info('🔗 Connection URL (Click or Copy):')
            Logger.Info('   ' .. result.connectionURL)
            Logger.Info('⏱️  Session NEVER EXPIRES (valid until server restart or manually ended)')
            Logger.Info('📋 Instructions:')
            Logger.Info('   1. Copy the URL above')
            Logger.Info('   2. Open it in your browser')
            Logger.Info('   3. You will see the full admin panel exactly as in-game')
            Logger.Info('═══════════════════════════════════════════════════════════════')
        else
            Logger.Info('❌ Failed to create remote admin session: ' .. result.message)
        end
    end, true)
    
    -- Session status endpoint
    RegisterCommand('ec:remote:status', function(source, args, rawCommand)
        if source ~= 0 then return end -- Console only
        
        local sessions = RemoteAdmin.GetActiveSessions()
        
        Logger.Info('🌐 ═══════════════════════════════════════════════════════════════')
        Logger.Info('🌐 Active Remote Admin Sessions: ' .. #sessions)
        Logger.Info('═══════════════════════════════════════════════════════════════')
        
        if #sessions == 0 then
            Logger.Info('📭 No active sessions')
            Logger.Info('💡 Create a new session with: ec:remote:auth <ip> <authKey>')
        else
            for _, session in ipairs(sessions) do
                Logger.Info(string.format('', session.id))
                Logger.Info(string.format('', 
                    session.ip, session.active and '✅ Yes' or '❌ No'))
                if session.connectionURL then
                    Logger.Info(string.format('', session.connectionURL))
                end
                Logger.Info('───────────────────────────────────────────────────────────────')
            end
        end
        Logger.Info('═══════════════════════════════════════════════════════════════')
    end, true)
    
    -- End session endpoint
    RegisterCommand('ec:remote:end', function(source, args, rawCommand)
        if source ~= 0 then return end -- Console only
        
        local sessionId = args[1]
        if not sessionId then
            Logger.Info('❌ Usage: ec:remote:end <sessionId>')
            return
        end
        
        local result = RemoteAdmin.EndSession(sessionId)
        Logger.Info('' .. result.message)
    end, true)
end

-- Event Handlers
RegisterNetEvent('ec-admin:remote:createSession')
AddEventHandler('ec-admin:remote:createSession', function(data, cb)
    local source = source
    
    -- Only allow from console (source 0) or specific permission
    if source ~= 0 then
        if cb then cb({ success = false, message = 'Unauthorized' }) end
        return
    end
    
    local result = RemoteAdmin.CreateSession(data.ip, data.authKey, data.userAgent)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:remote:validateSession')
AddEventHandler('ec-admin:remote:validateSession', function(data, cb)
    local isValid, message, session = RemoteAdmin.ValidateSession(data.sessionId, data.token)
    if cb then 
        cb({ 
            success = isValid, 
            message = message,
            session = session and {
                id = session.id,
                features = session.features,
                connectionURL = session.connectionURL
            } or nil
        }) 
    end
end)

RegisterNetEvent('ec-admin:remote:endSession')
AddEventHandler('ec-admin:remote:endSession', function(data, cb)
    local result = RemoteAdmin.EndSession(data.sessionId)
    if cb then cb(result) end
end)

RegisterNetEvent('ec-admin:remote:getActiveSessions')
AddEventHandler('ec-admin:remote:getActiveSessions', function(data, cb)
    local sessions = RemoteAdmin.GetActiveSessions()
    if cb then cb({ success = true, sessions = sessions }) end
end)

-- Cleanup thread
CreateThread(function()
    while true do
        Wait(60000) -- Every minute
        
        local now = os.time() * 1000
        local timeout = Config.RemoteAdmin and Config.RemoteAdmin.sessionTimeout or 3600000
        
        for sessionId, session in pairs(activeSessions) do
            if now - session.lastActivity > timeout then
                Logger.Info(string.format('', sessionId))
                activeSessions[sessionId] = nil
            end
        end
    end
end)

-- Exports
exports('CreateRemoteSession', RemoteAdmin.CreateSession)
exports('ValidateRemoteSession', RemoteAdmin.ValidateSession)
exports('EndRemoteSession', RemoteAdmin.EndSession)

_G.RemoteAdmin = RemoteAdmin

Logger.Info('✅ Remote Admin Access System loaded successfully')
if Config.RemoteAdmin and Config.RemoteAdmin.enabled then
    Logger.Info('🌐 ═══════════════════════════════════════════════════════════════')
    Logger.Info('🌐 Remote Admin Access is ENABLED')
    Logger.Info('═══════════════════════════════════════════════════════════════')
    Logger.Info('📋 Available Commands:')
    Logger.Info('   • ec:remote:auth <ip> <authKey>   - Create a new remote session')
    Logger.Info('   • ec:remote:status                - View active sessions & URLs')
    Logger.Info('   • ec:remote:end <sessionId>       - End a remote session')
    Logger.Info('═══════════════════════════════════════════════════════════════')
    Logger.Info('💡 Usage Example:')
    Logger.Info('   1. Run: ec:remote:auth 127.0.0.1 YOUR_AUTH_KEY')
    Logger.Info('   2. Copy the connection URL from the output')
    Logger.Info('   3. Open the URL in your browser')
    Logger.Info('   4. Access the full admin panel remotely!')
    Logger.Info('═══════════════════════════════════════════════════════════════')
else
    Logger.Info('🌐 Remote admin access is DISABLED')
    Logger.Info('💡 Enable it in config.lua: Config.RemoteAdmin.enabled = true')
end