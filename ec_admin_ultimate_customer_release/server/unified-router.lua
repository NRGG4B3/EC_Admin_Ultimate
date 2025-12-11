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
    
    -- Note: FiveM doesn't have CreateHttpHandler
    -- HTTP routing should be handled via resource HTTP exports or external API
    -- This file is kept for future HTTP API implementation
    Logger.Info('[Unified Router] HTTP API disabled (requires external HTTP handler)')
end)

-- Placeholder for future HTTP handler implementation
-- When FiveM adds HTTP routing support, uncomment below:
--[[
    -- Health check
    CreateHttpHandler('/api/health', function(req, res, args)
        sendJSONResponse(res, 200, {
            status = 'ok',
            timestamp = os.time(),
            resource = GetCurrentResourceName()
        })
    end)
    
--]]

