--[[
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                       ⚠️ LEGACY FILE - DEPRECATED ⚠️                  ║
    ║                                                                       ║
    ║  THIS FILE IS NO LONGER LOADED BY FXMANIFEST.LUA                    ║
    ║  REPLACED BY: unified-router.lua (production-ready HTTP router)      ║
    ║                                                                       ║
    ║  Reason: JWT implementation incomplete, security concerns            ║
    ║  Migration: All endpoints moved to unified-router.lua                ║
    ║                                                                       ║
    ║  ⚠️ DO NOT ENABLE THIS FILE WITHOUT COMPLETING JWT VALIDATION       ║
    ╚═══════════════════════════════════════════════════════════════════════╝
]]

Logger.Info('')
Logger.Info('')

-- Use global Config from shared_scripts (config/runtime-config.lua)
local Config = _G.ECAdminConfig or Config or {}

-- Security: JWT validation (INCOMPLETE - THIS IS WHY FILE IS DEPRECATED)
local function ValidateJWT(token)
    if not Config.Security.RequireAuth then
        return true, nil
    end
    
    if not token then
        return false, "No token provided"
    end
    
    --[[
        ⚠️ SECURITY ISSUE: JWT validation incomplete
        
        Current implementation is just a shared secret comparison.
        Proper JWT validation requires:
        1. Decoding the JWT header and payload
        2. Verifying the signature with the secret
        3. Checking expiration (exp claim)
        4. Validating issuer (iss claim)
        5. Checking audience (aud claim)
        
        Use unified-router.lua instead which uses host-secret validation
        for trusted host-mode access and proper rate limiting.
    ]]
    if token == Config.Security.JWTSecret then
        return true, nil
    end
    
    return false, "Invalid token"
end

-- Security: Check if player is owner
local function IsOwner(identifiers)
    if not identifiers then return false end
    
    for _, id in ipairs(identifiers) do
        if id == Config.Owner.Steam or 
           id == Config.Owner.License or 
           id == Config.Owner.Fivem or
           id == Config.Owner.Discord then
            return true
        end
    end
    
    return false
end

-- Get framework bridge
local Framework = nil
Citizen.CreateThread(function()
    Wait(1000)

    if GetResourceState('qbx_core') == 'started' then
        Framework = exports.qbx_core
        Logger.Info("API Router: Detected QBX framework")
    elseif GetResourceState('qb-core') == 'started' then
        Framework = exports['qb-core']:GetCoreObject()
        Logger.Info("API Router: Detected QBCore framework")
    elseif GetResourceState('es_extended') == 'started' then
        Framework = exports['es_extended']:getSharedObject()
        Logger.Info("API Router: Detected ESX framework")
    else
        Logger.Info("API Router: No framework detected, using standalone mode")
    end
end)

--[[
    /api/status - System health check
]]
local function GetStatus()
    local dbStatus = MySQL and MySQL.ready and "connected" or "disconnected"
    local frameworkStatus = Framework and "detected" or "standalone"
    
    return {
        success = true,
        status = "healthy",
        version = Config.Version,
        uptime = os.time() - (_G.ECAdminStartTime or os.time()),
        database = {
            status = dbStatus,
            type = Config.Database.UseOxMySQL and "oxmysql" or "mysql-async"
        },
        framework = {
            status = frameworkStatus,
            type = Config.Server.Framework
        },
        services = {
            staffAPI = Config.APIs.Staff.Enabled,
            globalBan = Config.APIs.GlobalBan.Enabled,
            remoteAdmin = Config.RemoteAdmin.Enabled,
            analytics = Config.APIs.Analytics.Enabled,
            ai = Config.APIs.AI.Enabled
        },
        setup = {
            complete = Config.SetupComplete,
            version = Config.SetupVersion
        }
    }
end

--[[
    /api/players - Get all online players
]]
local function GetPlayers(filters)
    local players = {}
    local playerList = GetPlayers()
    
    for _, playerId in ipairs(playerList) do
        local identifiers = GetPlayerIdentifiers(playerId)
        local player = {
            id = tonumber(playerId),
            name = GetPlayerName(playerId),
            ping = GetPlayerPing(playerId),
            identifiers = identifiers,
            isOwner = IsOwner(identifiers)
        }
        
        -- Add framework data if available
        if Framework then
            if Config.Server.Framework == 'qbx' or Config.Server.Framework == 'qbcore' then
                local QBPlayer = Framework.Functions and Framework.Functions.GetPlayer(tonumber(playerId))
                if QBPlayer then
                    player.job = QBPlayer.PlayerData.job
                    player.gang = QBPlayer.PlayerData.gang
                    player.money = QBPlayer.PlayerData.money
                    player.citizenid = QBPlayer.PlayerData.citizenid
                end
            elseif Config.Server.Framework == 'esx' then
                local ESXPlayer = Framework.GetPlayerFromId(tonumber(playerId))
                if ESXPlayer then
                    player.job = ESXPlayer.job
                    player.money = {
                        cash = ESXPlayer.getMoney(),
                        bank = ESXPlayer.getAccount('bank').money
                    }
                    player.identifier = ESXPlayer.identifier
                end
            end
        end
        
        table.insert(players, player)
    end
    
    return {
        success = true,
        players = players,
        count = #players,
        max = GetConvarInt('sv_maxclients', 64)
    }
end

--[[
    /api/player/:id - Get specific player details
]]
local function GetPlayer(playerId)
    playerId = tonumber(playerId)
    
    if not playerId or GetPlayerName(playerId) == nil then
        return { success = false, error = "Player not found" }
    end
    
    local identifiers = GetPlayerIdentifiers(playerId)
    local player = {
        id = playerId,
        name = GetPlayerName(playerId),
        ping = GetPlayerPing(playerId),
        endpoint = GetPlayerEndpoint(playerId),
        identifiers = identifiers,
        isOwner = IsOwner(identifiers),
        tokens = GetNumPlayerTokens(playerId)
    }
    
    -- Add framework-specific data
    if Framework then
        if Config.Server.Framework == 'qbx' or Config.Server.Framework == 'qbcore' then
            local QBPlayer = Framework.Functions and Framework.Functions.GetPlayer(playerId)
            if QBPlayer then
                player.job = QBPlayer.PlayerData.job
                player.gang = QBPlayer.PlayerData.gang
                player.money = QBPlayer.PlayerData.money
                player.citizenid = QBPlayer.PlayerData.citizenid
                player.position = GetEntityCoords(GetPlayerPed(playerId))
                
                -- Get inventory (if ox_inventory)
                if GetResourceState('ox_inventory') == 'started' then
                    player.inventory = exports.ox_inventory:GetPlayerItems(playerId)
                end
            end
        elseif Config.Server.Framework == 'esx' then
            local ESXPlayer = Framework.GetPlayerFromId(playerId)
            if ESXPlayer then
                player.job = ESXPlayer.job
                player.money = {
                    cash = ESXPlayer.getMoney(),
                    bank = ESXPlayer.getAccount('bank').money
                }
                player.inventory = ESXPlayer.inventory
                player.position = GetEntityCoords(GetPlayerPed(playerId))
            end
        end
    end
    
    return {
        success = true,
        player = player
    }
end

--[[
    /api/vehicles - Get all vehicles
]]
local function GetVehicles()
    local vehicles = {}
    
    -- This would typically query database for owned vehicles
    -- For now, get active vehicles
    local allVehicles = GetAllVehicles()
    
    for _, vehicle in ipairs(allVehicles) do
        local driver = GetPedInVehicleSeat(vehicle, -1)
        local playerId = driver ~= 0 and NetworkGetPlayerIndexFromPed(driver) or nil
        
        table.insert(vehicles, {
            entity = vehicle,
            model = GetEntityModel(vehicle),
            plate = GetVehicleNumberPlateText(vehicle),
            driver = playerId and GetPlayerName(playerId) or nil,
            driverId = playerId,
            position = GetEntityCoords(vehicle),
            health = GetVehicleEngineHealth(vehicle),
            bodyHealth = GetVehicleBodyHealth(vehicle)
        })
    end
    
    return {
        success = true,
        vehicles = vehicles,
        count = #vehicles
    }
end

--[[
    /api/bans - Get all bans
]]
local function GetBans()
    if not MySQL then
        return { success = false, error = "Database not available" }
    end
    
    local bans = MySQL.query.await('SELECT * FROM ec_admin_bans ORDER BY created_at DESC LIMIT 100', {})
    
    return {
        success = true,
        bans = bans or {},
        count = #(bans or {})
    }
end

--[[
    /api/warnings - Get all warnings
]]
local function GetWarnings()
    if not MySQL then
        return { success = false, error = "Database not available" }
    end
    
    local warnings = MySQL.query.await('SELECT * FROM ec_admin_warnings ORDER BY created_at DESC LIMIT 100', {})
    
    return {
        success = true,
        warnings = warnings or {},
        count = #(warnings or {})
    }
end

--[[
    /api/jobs - Get all jobs
]]
local function GetJobs()
    local jobs = {}
    
    if Framework then
        if Config.Server.Framework == 'qbx' or Config.Server.Framework == 'qbcore' then
            jobs = Framework.Shared and Framework.Shared.Jobs or {}
        elseif Config.Server.Framework == 'esx' then
            -- ESX jobs from database
            if MySQL then
                local result = MySQL.query.await('SELECT * FROM jobs', {})
                for _, job in ipairs(result or {}) do
                    jobs[job.name] = job
                end
            end
        end
    end
    
    return {
        success = true,
        jobs = jobs
    }
end

--[[
    /api/gangs - Get all gangs
]]
local function GetGangs()
    local gangs = {}
    
    if Framework and (Config.Server.Framework == 'qbx' or Config.Server.Framework == 'qbcore') then
        gangs = Framework.Shared and Framework.Shared.Gangs or {}
    end
    
    return {
        success = true,
        gangs = gangs
    }
end

--[[
    /api/settings - Get/Update settings
]]
local function GetSettings()
    return {
        success = true,
        settings = {
            server = Config.Server,
            features = Config.Features,
            security = {
                requireAuth = Config.Security.RequireAuth,
                rateLimit = Config.Security.RateLimit.Enabled,
                cors = Config.Security.CORS.Enabled
            },
            webhook = {
                enabled = Config.Webhook.Enabled
            },
            remoteAdmin = {
                enabled = Config.RemoteAdmin.Enabled
            }
        }
    }
end

--[[
    /api/remote-admin/url - Generate secure remote admin URL
]]
local function GenerateRemoteAdminURL(data)
    if not Config.RemoteAdmin.Enabled then
        return { success = false, error = "Remote admin not enabled" }
    end
    
    -- Generate session token
    local token = string.format("%x%x%x%x", 
        math.random(0, 0xFFFFFFFF),
        math.random(0, 0xFFFFFFFF),
        math.random(0, 0xFFFFFFFF),
        os.time()
    )
    
    -- Store token with expiration (in-memory for now, should be DB)
    _G.ECAdminRemoteSessions = _G.ECAdminRemoteSessions or {}
    _G.ECAdminRemoteSessions[token] = {
        created = os.time(),
        expires = os.time() + Config.RemoteAdmin.SessionTTL,
        playerId = data.playerId,
        playerName = data.playerName
    }
    
    local url = string.format("https://%s:%s/admin?token=%s", 
        Config.Server.IP,
        Config.Server.Port,
        token
    )
    
    return {
        success = true,
        url = url,
        expires = Config.RemoteAdmin.SessionTTL
    }
end

--[[
    /api/host/credentials - Get host API credentials (HOST ONLY)
]]
local function GetHostCredentials()
    if Config.InstallType ~= 'host' then
        return { success = false, error = "Not a host installation" }
    end
    
    return {
        success = true,
        credentials = {
            password = "*** HIDDEN ***", -- Never send actual password
            apis = Config.Host.APIs
        }
    }
end

--[[
    /api/host/services - Get host service status (HOST ONLY)
]]
local function GetHostServices()
    if Config.InstallType ~= 'host' then
        return { success = false, error = "Not a host installation" }
    end
    
    local services = {}
    
    for apiName, apiConfig in pairs(Config.Host.APIs) do
        services[apiName] = {
            name = apiName,
            enabled = apiConfig.Enabled,
            port = apiConfig.Port,
            status = apiConfig.Enabled and "running" or "stopped"
        }
    end
    
    return {
        success = true,
        services = services
    }
end

--[[
    /api/host/menu-toggle - Toggle web menu availability (HOST ONLY)
]]
local function ToggleMenu(enabled)
    if Config.InstallType ~= 'host' then
        return { success = false, error = "Not a host installation" }
    end
    
    Config.Host.MenuToggle = enabled
    SetConvar('ec_host_menu_toggle', tostring(enabled))
    
    return {
        success = true,
        enabled = enabled
    }
end

--[[
    /api/webhook/test - Test Discord webhook
]]
local function TestWebhook(data)
    if not Config.Webhook.Enabled or not Config.Webhook.URL then
        return { success = false, error = "Webhook not configured" }
    end
    
    PerformHttpRequest(Config.Webhook.URL, function(err, text, headers)
        if err == 200 or err == 204 then
            Logger.Info("API Router: Webhook test successful")
        else
            Logger.Info("API Router: Webhook test failed: " .. tostring(err))
        end
    end, 'POST', json.encode({
        username = Config.Webhook.Name,
        avatar_url = Config.Webhook.Avatar,
        embeds = {{
            title = "🔔 EC Admin - Test Notification",
            description = "This is a test notification from EC Admin Ultimate",
            color = 3447003,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S"),
            footer = {
                text = "EC Admin Ultimate v" .. Config.Version
            }
        }}
    }), { ['Content-Type'] = 'application/json' })
    
    return {
        success = true,
        message = "Webhook test sent"
    }
end

--[[
    /api/auth/host - Validate host password (SERVER-SIDE ONLY)
    PRD Section 3: Host Password Gate
]]
local function ValidateHostPassword(password)
    if not password or password == "" then
        return { success = false, error = "Password required" }
    end
    
    -- Get password from convar (NEVER from file/code)
    local validPassword = GetConvar('ec_host_password', nil)
    
    if not validPassword or validPassword == "" then
        -- No host password set - generate one on first access
        print("^3[API Router] WARNING: No host password set in convars^7")
        print("^3[API Router] Please set: setr ec_host_password \"your-secure-password\"^7")
        return { success = false, error = "Host password not configured on server" }
    end
    
    -- Validate password
    if password == validPassword then
        print("^2[API Router] Host authentication successful^7")
        return { success = true, message = "Authentication successful" }
    else
        print("^1[API Router] Host authentication failed - invalid password^7")
        return { success = false, error = "Invalid password" }
    end
end

--[[
    UNIFIED ROUTER - Handles both HTTP and NUI requests
]]
local function RouteRequest(method, path, data, cb)
    local response = nil
    
    -- Route to appropriate handler
    if path == '/api/status' or path == 'getStatus' then
        response = GetStatus()
    elseif path == '/api/players' or path == 'getPlayers' then
        response = GetPlayers(data)
    elseif path:match('/api/player/(%d+)') or path == 'getPlayer' then
        local playerId = path:match('/api/player/(%d+)') or data.playerId
        response = GetPlayer(playerId)
    elseif path == '/api/vehicles' or path == 'getVehicles' then
        response = GetVehicles()
    elseif path == '/api/bans' or path == 'getBans' then
        response = GetBans()
    elseif path == '/api/warnings' or path == 'getWarnings' then
        response = GetWarnings()
    elseif path == '/api/jobs' or path == 'getJobs' then
        response = GetJobs()
    elseif path == '/api/gangs' or path == 'getGangs' then
        response = GetGangs()
    elseif path == '/api/settings' or path == 'getSettings' then
        response = GetSettings()
    elseif path == '/api/metrics' or path == 'getMetrics' then
        -- Delegate to metrics-api.lua
        response = { success = true, redirect = 'metrics-api' }
    elseif path == '/api/remote-admin/url' or path == 'generateRemoteURL' then
        response = GenerateRemoteAdminURL(data)
    elseif path == '/api/host/credentials' or path == 'getHostCredentials' then
        response = GetHostCredentials()
    elseif path == '/api/host/services' or path == 'getHostServices' then
        response = GetHostServices()
    elseif path == '/api/host/menu-toggle' or path == 'toggleMenu' then
        response = ToggleMenu(data.enabled)
    elseif path == '/api/webhook/test' or path == 'testWebhook' then
        response = TestWebhook(data)
    elseif path == '/api/auth/host' or path == 'validateHostPassword' then
        response = ValidateHostPassword(data.password)
    else
        response = { success = false, error = "Endpoint not found", path = path }
    end
    
    if cb then
        cb(response)
    end
    
    return response
end

--[[
    NUI CALLBACKS - Register all endpoints
]]
local nuiEndpoints = {
    'getStatus',
    'getPlayers',
    'getPlayer',
    'getVehicles',
    'getBans',
    'getWarnings',
    'getJobs',
    'getGangs',
    'getSettings',
    'getMetrics',
    'generateRemoteURL',
    'getHostCredentials',
    'getHostServices',
    'toggleMenu',
    'testWebhook'
}

-- REMOVED: RegisterNUICallback loop (CLIENT-SIDE ONLY)
-- These NUI callbacks have been moved to client/nui-bridge.lua
-- Server-side should use lib.callback.register instead
--[[ DISABLED
for _, endpoint in ipairs(nuiEndpoints) do
    RegisterNUICallback(endpoint, function(data, cb)
        RouteRequest('POST', endpoint, data, cb)
    end)
end
--]]

--[[
    HTTP HANDLER - Handle web requests
]]
SetHttpHandler(function(req, res)
    local path = req.path
    local method = req.method
    
    -- CORS headers (safe check)
    if Config.Security and Config.Security.CORS and Config.Security.CORS.enabled then
        local origins = type(Config.Security.CORS.origins) == 'table' and table.concat(Config.Security.CORS.origins, ', ') or '*'
        res.setHeader('Access-Control-Allow-Origin', origins)
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        
        if method == 'OPTIONS' then
            res.writeHead(200)
            res.send('')
            return
        end
    end
    
    -- Only handle /api/* paths
    if not path:match('^/api/') then
        return
    end
    
    -- Route request
    local response = RouteRequest(method, path, req.body and json.decode(req.body) or {}, nil)
    
    res.writeHead(200, { ['Content-Type'] = 'application/json' })
    res.send(json.encode(response))
end)

-- Initialize
_G.ECAdminStartTime = os.time()

Logger.Info("API Router: Initialized")
print("  HTTP endpoints: /api/*")
print("  NUI callbacks: " .. #nuiEndpoints .. " endpoints")
print("  Security: " .. (Config.Security and Config.Security.RequireAuth and "Enabled" or "Disabled"))
-- CORS check - safely handle if CORS config doesn't exist
local corsStatus = "Disabled"
if Config.Security and Config.Security.CORS and Config.Security.CORS.enabled then
    corsStatus = "Enabled"
end
print("  CORS: " .. corsStatus)