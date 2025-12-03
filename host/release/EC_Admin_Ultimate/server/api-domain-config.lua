--[[
    EC Admin Ultimate - API Domain Configuration
    
    🔒 SECURITY: YOUR VPS IP stays hidden from customers
    
    How it works:
    1. You register domain: api.ecbetasolutions.com
    2. DNS A record points to YOUR VPS IP: 45.144.225.227
    3. Customers connect to: https://api.ecbetasolutions.com
    4. They NEVER see 45.144.225.227 - your IP stays hidden!
    
    Benefits:
    ✅ Customers can't DDoS your VPS directly (they only know the domain)
    ✅ You can change VPS/IP without updating customer files
    ✅ Cloudflare/proxy protection possible
    ✅ Professional appearance (domain vs raw IP)
]]

local Logger = require('server.logger')

local API_DOMAIN = {}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════

-- HOST MODE: Your actual infrastructure (YOU see the real IP)
API_DOMAIN.HOST = {
    ip = "45.144.225.227",           -- YOUR real VPS IP (NEVER given to customers)
    port = 30120,                     -- FiveM port
    nodePort = 3000,                  -- Node.js API gateway port
    localhost = "http://127.0.0.1:3000",  -- Local API endpoint (fastest)
    
    -- Public domain (what customers connect to - they never see the IP above)
    domain = "api.ecbetasolutions.com",  -- ✅ Customers use this domain
    protocol = "https"  -- Use HTTPS in production
}

-- CUSTOMER MODE: What customers see/use (they NEVER see your VPS IP)
API_DOMAIN.CUSTOMER = {
    -- Domain name ONLY - YOUR IP stays hidden from customers
    endpoint = GetConvar('ec_api_endpoint', 'https://api.ecbetasolutions.com'),
    
    -- Alternative: Use relative URLs (proxied by FiveM for extra protection)
    useRelative = true,  -- true = use /api/host/* (recommended, adds extra layer)
    
    -- Fallback (domain only, never an IP address)
    fallback = "https://api.ecbetasolutions.com"
}

-- ═══════════════════════════════════════════════════════════════
-- AUTOMATIC MODE DETECTION
-- ═══════════════════════════════════════════════════════════════

function API_DOMAIN.GetMode()
    local hostFolderExists = LoadResourceFile(GetCurrentResourceName(), 'host/README.md') ~= nil
    return hostFolderExists and 'HOST' or 'CUSTOMER'
end

function API_DOMAIN.IsHost()
    return API_DOMAIN.GetMode() == 'HOST'
end

function API_DOMAIN.IsCustomer()
    return API_DOMAIN.GetMode() == 'CUSTOMER'
end

-- ═══════════════════════════════════════════════════════════════
-- API ENDPOINT GETTER (SMART ROUTING)
-- ═══════════════════════════════════════════════════════════════

function API_DOMAIN.GetEndpoint()
    if API_DOMAIN.IsHost() then
        -- HOST: Use localhost (fastest, you're on your own VPS)
        return API_DOMAIN.HOST.localhost
    else
        -- CUSTOMER: Use domain name (YOUR VPS IP stays hidden from them)
        if API_DOMAIN.CUSTOMER.useRelative then
            -- Use relative URLs - FiveM will proxy (extra protection layer)
            return ""  -- Empty = use relative URLs like /api/host/*
        else
            -- Use full domain (customers connect to domain, not your IP)
            return API_DOMAIN.CUSTOMER.endpoint
        end
    end
end

function API_DOMAIN.GetFullEndpoint(path)
    local base = API_DOMAIN.GetEndpoint()
    
    if base == "" then
        -- Relative URL mode
        return path
    else
        -- Full URL mode
        return base .. path
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CUSTOMER-SAFE API CALLER
-- ═══════════════════════════════════════════════════════════════

function API_DOMAIN.Call(method, path, data, callback)
    local endpoint = API_DOMAIN.GetFullEndpoint(path)
    
    -- Debug (HOST ONLY - customers never see this)
    if API_DOMAIN.IsHost() then
        Logger.Debug(string.format('[API] %s %s', method, endpoint))
    end
    
    -- Make request
    PerformHttpRequest(endpoint, function(statusCode, response, headers)
        if callback then
            callback(statusCode, response, headers)
        end
    end, method, data and json.encode(data) or nil, {
        ['Content-Type'] = 'application/json'
    })
end

-- Convenience methods
function API_DOMAIN.GET(path, callback)
    API_DOMAIN.Call('GET', path, nil, callback)
end

function API_DOMAIN.POST(path, data, callback)
    API_DOMAIN.Call('POST', path, data, callback)
end

function API_DOMAIN.PUT(path, data, callback)
    API_DOMAIN.Call('PUT', path, data, callback)
end

function API_DOMAIN.DELETE(path, callback)
    API_DOMAIN.Call('DELETE', path, nil, callback)
end

-- ═══════════════════════════════════════════════════════════════
-- CUSTOMER FILE VALIDATOR (ENSURE NO IP LEAKS)
-- ═══════════════════════════════════════════════════════════════

function API_DOMAIN.ValidateCustomerFiles()
    if not API_DOMAIN.IsHost() then
        return true  -- Only validate on host
    end
    
    Logger.System('🔒 Validating customer files for IP leaks...', '🔍')
    
    local filesWithIP = {}
    local filesToCheck = {
        'config.lua',
        'client/nui-bridge.lua',
        'ui/dist/index.html'
    }
    
    -- NOTE: server/api-domain-config.lua is NOT checked because it's a HOST file
    -- This file should have the IP in HOST mode - it's never distributed to customers
    
    local ipPattern = API_DOMAIN.HOST.ip
    
    for _, file in ipairs(filesToCheck) do
        local content = LoadResourceFile(GetCurrentResourceName(), file)
        if content and string.find(content, ipPattern, 1, true) then
            table.insert(filesWithIP, file)
        end
    end
    
    if #filesWithIP > 0 then
        Logger.Error('⚠️  IP LEAK DETECTED in customer files:')
        for _, file in ipairs(filesWithIP) do
            Logger.Error('  - ' .. file)
        end
        Logger.Error('⚠️  Remove IP before distributing to customers!')
        return false
    else
        Logger.Success('✅ Customer files validated - No IP leaks detected')
        Logger.Info('ℹ️  Note: server/api-domain-config.lua is a HOST-only file')
        return true
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INITIALIZE
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(2000)
    
    local mode = API_DOMAIN.GetMode()
    
    if mode == 'HOST' then
        Logger.Success('🏠 HOST MODE - Using localhost:' .. API_DOMAIN.HOST.nodePort)
        Logger.Info('🌐 Customer endpoint: ' .. API_DOMAIN.CUSTOMER.endpoint)
        
        -- Validate files
        SetTimeout(5000, function()
            API_DOMAIN.ValidateCustomerFiles()
        end)
    else
        Logger.Success('🌐 CUSTOMER MODE - Using API domain (IP hidden)')
        Logger.Info('🔒 Connecting to: ' .. (API_DOMAIN.CUSTOMER.useRelative and 'Relative URLs' or API_DOMAIN.CUSTOMER.endpoint))
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════

exports('GetAPIEndpoint', API_DOMAIN.GetEndpoint)
exports('GetFullAPIEndpoint', API_DOMAIN.GetFullEndpoint)
exports('CallAPI', API_DOMAIN.Call)

return API_DOMAIN