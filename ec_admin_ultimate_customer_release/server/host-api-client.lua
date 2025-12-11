--[[
    EC Admin Ultimate - Host API Client
    Handles communication with Node.js backend for host dashboard
    This file is ONLY loaded in host mode (when host/ folder exists)
]]

-- Check if host mode is enabled
local function isHostMode()
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].IsHostMode then
        return exports['ec_admin_ultimate']:IsHostMode()
    end
    return false
end

-- Get host API base URL
local function getHostAPIBaseUrl()
    if not isHostMode() then
        return nil
    end
    
    local port = GetConvar('ec_admin_host_api_port', '3019')
    return 'http://127.0.0.1:' .. port
end

-- Get host API secret
local function getHostAPISecret()
    if Config and Config.HostApi and Config.HostApi.secret then
        return Config.HostApi.secret
    end
    return ''
end

-- Call host API (Node.js backend)
local function callHostAPI(endpoint, method, data)
    if not isHostMode() then
        return { success = false, error = 'Not in host mode' }
    end
    
    local baseUrl = getHostAPIBaseUrl()
    if not baseUrl then
        return { success = false, error = 'Host API not configured' }
    end
    
    local url = baseUrl .. endpoint
    local secret = getHostAPISecret()
    
    -- Prepare headers
    local headers = {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = 'Bearer ' .. secret
    }
    
    -- Use PerformHttpRequest
    if PerformHttpRequest then
        local requestId = math.random(1000000, 9999999)
        local success = false
        local responseCode = 0
        local responseBody = ''
        
        local body = data and json.encode(data) or ''
        
        PerformHttpRequest(url, function(code, body, resHeaders)
            success = (code >= 200 and code < 300)
            responseCode = code
            responseBody = body or ''
        end, method or 'GET', body, headers)
        
        -- Wait for response (with timeout)
        local timeout = 0
        while timeout < 10 and not success and responseCode == 0 do
            Wait(100)
            timeout = timeout + 0.1
        end
        
        if success then
            local success2, parsed = pcall(json.decode, responseBody)
            if success2 then
                return { success = true, data = parsed, code = responseCode }
            end
            return { success = true, data = responseBody, code = responseCode }
        end
        
        return { success = false, error = 'Request failed', code = responseCode, body = responseBody }
    end
    
    return { success = false, error = 'HTTP requests not available' }
end

-- Export function for other files
exports('CallHostAPI', callHostAPI)

print("^2[Host API Client]^7 Host API client loaded (host mode only)^0")

