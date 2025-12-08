--[[
    EC Admin Ultimate - API Domain Configuration
    Handles API endpoint routing and domain configuration
    - Customers: Auto-connect to api.ecbetasolutions.com (NO IPs exposed)
    - Host: Connect to localhost node.js backend (internal only)
]]

-- Check if host mode is enabled
local function isHostMode()
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].IsHostMode then
        return exports['ec_admin_ultimate']:IsHostMode()
    end
    return false
end

-- Get API base URL based on mode
local function getApiBaseUrl()
    local isHost = isHostMode()
    
    if isHost then
        -- Host mode: Use localhost node.js backend
        local hostPort = GetConvar('ec_admin_host_api_port', '3019')
        return 'http://127.0.0.1:' .. hostPort
    else
        -- Customer mode: Use public API domain (NO IPs exposed)
        return 'https://api.ecbetasolutions.com'
    end
end

-- Configuration
local API_DOMAIN = GetConvar('ec_admin_api_domain', '')
local API_ENABLED = GetConvar('ec_admin_api_enabled', 'true') == 'true'

-- Export: Get API endpoint
exports('GetAPIEndpoint', function(endpoint)
    if not API_ENABLED then return nil end
    
    local baseUrl = getApiBaseUrl()
    if baseUrl then
        -- Remove trailing slash from baseUrl and leading slash from endpoint
        baseUrl = baseUrl:gsub('/+$', '')
        endpoint = endpoint:gsub('^/+', '')
        return baseUrl .. '/' .. endpoint
    end
    
    if API_DOMAIN and API_DOMAIN ~= '' then
        return API_DOMAIN .. endpoint
    end
    return endpoint
end)

-- Export: Get full API endpoint
exports('GetFullAPIEndpoint', function(endpoint)
    if not API_ENABLED then return nil end
    
    local baseUrl = getApiBaseUrl()
    if baseUrl then
        -- Remove trailing slash from baseUrl and leading slash from endpoint
        baseUrl = baseUrl:gsub('/+$', '')
        endpoint = endpoint:gsub('^/+', '')
        return baseUrl .. '/' .. endpoint
    end
    
    if API_DOMAIN and API_DOMAIN ~= '' then
        return 'https://' .. API_DOMAIN .. endpoint
    end
    return endpoint
end)

-- Export: Call API
exports('CallAPI', function(endpoint, method, data, headers)
    if not API_ENABLED then
        return { success = false, error = 'API disabled' }
    end
    
    local url = exports('ec_admin_ultimate', 'GetFullAPIEndpoint', endpoint)
    if not url then
        return { success = false, error = 'Invalid endpoint' }
    end
    
    -- Use PerformHttpRequest if available
    if PerformHttpRequest then
        local requestId = math.random(1000000, 9999999)
        local success = false
        local responseCode = 0
        local responseBody = ''
        
        local body = data and json.encode(data) or ''
        local reqHeaders = headers or {}
        reqHeaders['Content-Type'] = 'application/json'
        
        PerformHttpRequest(url, function(code, body, resHeaders)
            success = (code >= 200 and code < 300)
            responseCode = code
            responseBody = body or ''
        end, method or 'GET', body, reqHeaders)
        
        -- Wait for response (with timeout)
        local timeout = 0
        while timeout < 30 and not success and responseCode == 0 do
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
        
        return { success = false, error = 'Request failed', code = responseCode }
    end
    
    return { success = false, error = 'HTTP requests not available' }
end)

print("^2[API Domain Config]^7 API routing configured^0")

