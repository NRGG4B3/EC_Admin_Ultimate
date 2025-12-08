--[[
    EC Admin Ultimate - Unified HTTP Router
    Handles all HTTP requests for the admin panel API
    
    Routes:
    - GET /api/health - Health check
    - GET /api/status - Server status
    - POST /api/* - Various API endpoints
]]

-- Configuration
local API_ENABLED = GetConvar('ec_admin_api_enabled', 'true') == 'true'
local API_PORT = GetConvarInt('ec_admin_api_port', 30120)

-- Helper: Send JSON response
local function sendJSONResponse(res, statusCode, data)
    SendHttpResponse(res, statusCode, json.encode(data), {
        ['Content-Type'] = 'application/json',
        ['Access-Control-Allow-Origin'] = '*',
        ['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS',
        ['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    })
end

-- Helper: Parse request body
local function parseBody(body)
    if not body or body == '' then return {} end
    local success, data = pcall(json.decode, body)
    if success then return data end
    return {}
end

-- Health check endpoint
CreateThread(function()
    if not API_ENABLED then return end
    
    -- Health check
    CreateHttpHandler('/api/health', function(req, res, args)
        sendJSONResponse(res, 200, {
            status = 'ok',
            timestamp = os.time(),
            resource = GetCurrentResourceName()
        })
    end)
    
    -- Server status
    CreateHttpHandler('/api/status', function(req, res, args)
        sendJSONResponse(res, 200, {
            status = 'ok',
            players = GetNumPlayerIndices() or 0,
            maxPlayers = GetConvarInt('sv_maxclients', 32),
            uptime = os.time(),
            framework = ECFramework and ECFramework.GetFramework() or 'unknown'
        })
    end)
    
    -- API info
    CreateHttpHandler('/api/info', function(req, res, args)
        sendJSONResponse(res, 200, {
            name = 'EC Admin Ultimate API',
            version = '1.0.0',
            endpoints = {
                '/api/health',
                '/api/status',
                '/api/info'
            }
        })
    end)
    
    print("^2[Unified Router]^7 HTTP API router loaded on port " .. API_PORT .. "^0")
end)

