-- EC Admin Ultimate - Host API Proxy
-- Forwards /api/host/* requests from FiveM (30120) to localhost:3000
-- Part of Option B architecture: UI on 30120, Host API on localhost:3000

local json = json or require('json')

-- Safety check: Ensure Config exists
if not Config then
    Logger.Error("Host API proxy ERROR: Config not loaded!")
    return
end

-- Only load this proxy if host mode is enabled
if not Config.HostApi or not Config.HostApi.enabled then
    Logger.Warn("Host API proxy disabled (Config.HostApi.enabled = false)")
    return
end

Logger.Info("Loading Host API Proxy...")
Logger.Info("Target: " .. Config.HostApi.baseUrl)

-- Forward request to localhost:3000 with security header
local function forwardToHost(method, path, body, callback)
    local url = Config.HostApi.baseUrl .. path
    local headers = {
        ["Content-Type"] = "application/json",
        ["X-Host-Secret"] = Config.HostApi.secret
    }
    
    local data = ""
    if body and type(body) == "table" then
        local success, encoded = pcall(json.encode, body)
        if success then
            data = encoded
        else
            Logger.Error("Proxy: Failed to encode request body: " .. tostring(encoded))
            callback(500, json.encode({ error = "Request encoding failed" }), {})
            return
        end
    elseif body and type(body) == "string" then
        data = body
    end
    
    -- Timeout handling
    local timedOut = false
    local timeoutTimer = SetTimeout(Config.HostApi.timeoutMs or 10000, function()
        if not timedOut then
            timedOut = true
            Logger.Error("Proxy: Request timed out: " .. method .. " " .. path)
            callback(504, json.encode({ error = "Gateway timeout" }), {})
        end
    end)
    
    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        if timedOut then
            return -- Already handled by timeout
        end
        
        ClearTimeout(timeoutTimer)
        
        if not statusCode then
            Logger.Error("Proxy: Request failed: " .. method .. " " .. path)
            callback(502, json.encode({ error = "Bad gateway - host server unreachable" }), {})
            return
        end
        
        callback(statusCode, responseText or "{}", responseHeaders or {})
    end, method, data, headers)
end

-- Register proxy routes for all /api/host/* endpoints
-- These routes intercept browser requests and forward them to localhost:3000

Logger.Info("Registering Host API Proxy Routes...")

-- GET /api/host/*
SetHttpHandler(function(req, res)
    local path = req.path
    
    -- Only handle /api/host/* routes
    if not path:match("^/api/host/") then
        return false -- Let other handlers process this
    end
    
    if req.method ~= "GET" then
        return false -- Let other handlers process this
    end
    
    Logger.Debug("Proxy: GET " .. path)
    
    forwardToHost("GET", path, nil, function(statusCode, responseText, responseHeaders)
        res.writeHead(statusCode, {
            ["Content-Type"] = responseHeaders["Content-Type"] or "application/json",
            ["Access-Control-Allow-Origin"] = "*"
        })
        res.send(responseText)
    end)
    
    return true -- We handled this request
end)

-- POST /api/host/*
SetHttpHandler(function(req, res)
    local path = req.path
    
    -- Only handle /api/host/* routes
    if not path:match("^/api/host/") then
        return false -- Let other handlers process this
    end
    
    if req.method ~= "POST" then
        return false -- Let other handlers process this
    end
    
    Logger.Debug("Proxy: POST " .. path)
    
    local body = {}
    if req.body and #req.body > 0 then
        local success, parsed = pcall(json.decode, req.body)
        if success and type(parsed) == "table" then
            body = parsed
        else
            Logger.Error("Proxy: Failed to parse POST body")
        end
    end
    
    forwardToHost("POST", path, body, function(statusCode, responseText, responseHeaders)
        res.writeHead(statusCode, {
            ["Content-Type"] = responseHeaders["Content-Type"] or "application/json",
            ["Access-Control-Allow-Origin"] = "*"
        })
        res.send(responseText)
    end)
    
    return true -- We handled this request
end)

-- PUT /api/host/*
SetHttpHandler(function(req, res)
    local path = req.path
    
    -- Only handle /api/host/* routes
    if not path:match("^/api/host/") then
        return false -- Let other handlers process this
    end
    
    if req.method ~= "PUT" then
        return false -- Let other handlers process this
    end
    
    Logger.Debug("Proxy: PUT " .. path)
    
    local body = {}
    if req.body and #req.body > 0 then
        local success, parsed = pcall(json.decode, req.body)
        if success and type(parsed) == "table" then
            body = parsed
        end
    end
    
    forwardToHost("PUT", path, body, function(statusCode, responseText, responseHeaders)
        res.writeHead(statusCode, {
            ["Content-Type"] = responseHeaders["Content-Type"] or "application/json",
            ["Access-Control-Allow-Origin"] = "*"
        })
        res.send(responseText)
    end)
    
    return true -- We handled this request
end)

-- DELETE /api/host/*
SetHttpHandler(function(req, res)
    local path = req.path
    
    -- Only handle /api/host/* routes
    if not path:match("^/api/host/") then
        return false -- Let other handlers process this
    end
    
    if req.method ~= "DELETE" then
        return false -- Let other handlers process this
    end
    
    Logger.Debug("Proxy: DELETE " .. path)
    
    forwardToHost("DELETE", path, nil, function(statusCode, responseText, responseHeaders)
        res.writeHead(statusCode, {
            ["Content-Type"] = responseHeaders["Content-Type"] or "application/json",
            ["Access-Control-Allow-Origin"] = "*"
        })
        res.send(responseText)
    end)
    
    return true -- We handled this request
end)

Logger.Success("Host API Proxy loaded successfully!")
Logger.Info("Routes: /api/host/* → " .. Config.HostApi.baseUrl .. "/api/host/*")
