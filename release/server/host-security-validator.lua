--[[
    EC Admin Ultimate - Host Security Validator
    CRITICAL SECURITY: Prevents unauthorized access to host features
    
    Multi-layer protection:
    1. License key validation (must be NRG-issued host license)
    2. IP allowlist (only NRG IP addresses)
    3. NRG API verification (backend validates every request)
    4. Automatic lockout on tampering attempts
]]--

Logger.Info('Loading Host Security Validator...', '🔒')

-- NRG Central API Configuration
local NRG_CENTRAL_API = {
    url = 'https://api.nrg-network.com/v1',  -- Replace with actual NRG central API
    validateEndpoint = '/license/validate',
    verifyHostEndpoint = '/host/verify',
    timeout = 5000
}

-- Security state
local HostSecurityState = {
    licenseValid = false,
    lastValidation = 0,
    validationInterval = 300000, -- Revalidate every 5 minutes
    failedAttempts = 0,
    maxFailedAttempts = 3,
    locked = false,
    lockExpiry = 0
}

-- NRG IP Allowlist (automatically updated from central server)
local NRG_IP_ALLOWLIST = {
    -- Production NRG IPs (these should be fetched from NRG central API)
    -- Example IPs - replace with real NRG infrastructure IPs
    '45.144.225.227',      -- NRG Main Server
    '127.0.0.1',           -- Localhost for development
    '::1'                  -- IPv6 localhost
}

--[[ ==================== LICENSE VALIDATION ==================== ]]--

-- Validate license key with NRG central server
local function ValidateLicenseWithNRG(licenseKey, callback)
    local url = NRG_CENTRAL_API.url .. NRG_CENTRAL_API.validateEndpoint
    
    PerformHttpRequest(url, function(statusCode, responseText, headers)
        if statusCode == 200 then
            local success, response = pcall(json.decode, responseText)
            if success and response then
                callback(response.valid == true, response)
            else
                callback(false, { error = 'Invalid response from NRG API' })
            end
        else
            callback(false, { error = 'NRG API unreachable', statusCode = statusCode })
        end
    end, 'POST', json.encode({
        licenseKey = licenseKey,
        serverIp = GetConvar('ec_server_ip', ''),
        resourceVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    }), {
        ['Content-Type'] = 'application/json',
        ['User-Agent'] = 'ECAdmin/4.0'
    })
end

-- Check if license is host-tier
local function IsHostLicense(licenseKey)
    -- Host licenses have specific prefix
    return licenseKey:sub(1, 5) == 'HOST-'
end

-- Validate host authorization
local function ValidateHostAuthorization(callback)
    local licenseKey = GetConvar('ec_license_key', '')
    
    -- Check if license exists
    if licenseKey == '' then
        Logger.Error('No license key configured', '❌')
        callback(false, 'No license key configured')
        return
    end
    
    -- Check if host-tier license
    if not IsHostLicense(licenseKey) then
        Logger.Error('License is not host-tier', '❌')
        callback(false, 'This license does not have host privileges')
        return
    end
    
    -- Validate with NRG central server
    ValidateLicenseWithNRG(licenseKey, function(valid, response)
        if valid then
            -- Additional check: verify host features are enabled for this license
            if response.tier == 'host' and response.hostFeaturesEnabled then
                HostSecurityState.licenseValid = true
                HostSecurityState.lastValidation = GetGameTimer()
                HostSecurityState.failedAttempts = 0
                Logger.Success('Host license validated successfully', '✅')
                callback(true, 'Host access granted')
            else
                Logger.Error('License does not have host features enabled', '❌')
                callback(false, 'Host features not enabled for this license')
            end
        else
            HostSecurityState.failedAttempts = HostSecurityState.failedAttempts + 1
            Logger.Error('License validation failed: ' .. (response.error or 'Unknown error'), '❌')
            callback(false, response.error or 'License validation failed')
            
            -- Lock after too many failed attempts
            if HostSecurityState.failedAttempts >= HostSecurityState.maxFailedAttempts then
                HostSecurityState.locked = true
                HostSecurityState.lockExpiry = GetGameTimer() + 3600000 -- 1 hour lockout
                Logger.Error('HOST FEATURES LOCKED due to repeated validation failures', '🚨')
            end
        end
    end)
end

--[[ ==================== IP VALIDATION ==================== ]]--

-- Check if IP is in NRG allowlist
local function IsNRGIP(ip)
    -- Remove port if present
    local cleanIp = ip:match('([^:]+)')
    
    for _, allowedIp in ipairs(NRG_IP_ALLOWLIST) do
        if cleanIp == allowedIp then
            return true
        end
    end
    
    return false
end

-- Validate request IP against allowlist
local function ValidateRequestIP(req)
    local ip = req.headers['x-forwarded-for'] or req.address or 'unknown'
    
    if not IsNRGIP(ip) then
        Logger.Warn(string.format('[EC Admin] Host access denied from unauthorized IP: %s', ip), '⚠️')
        return false, 'Access denied: IP not authorized for host features'
    end
    
    return true, 'IP authorized'
end

-- Update IP allowlist from NRG central server
local function UpdateIPAllowlist()
    local url = NRG_CENTRAL_API.url .. '/host/allowed-ips'
    
    PerformHttpRequest(url, function(statusCode, responseText, headers)
        if statusCode == 200 then
            local success, response = pcall(json.decode, responseText)
            if success and response and response.ips then
                NRG_IP_ALLOWLIST = response.ips
                Logger.Success('Updated NRG IP allowlist (' .. #NRG_IP_ALLOWLIST .. ' IPs)', '✅')
            end
        end
    end, 'GET', '', {
        ['Content-Type'] = 'application/json',
        ['User-Agent'] = 'ECAdmin/4.0'
    })
end

--[[ ==================== MAIN VALIDATION FUNCTION ==================== ]]--

-- Complete host access validation (call this on every host endpoint)
function ValidateHostAccess(req, callback)
    -- Check if locked due to failed attempts
    if HostSecurityState.locked then
        if GetGameTimer() < HostSecurityState.lockExpiry then
            local remaining = math.ceil((HostSecurityState.lockExpiry - GetGameTimer()) / 60000)
            callback(false, string.format('Host features locked for %d more minutes', remaining))
            return
        else
            -- Unlock after expiry
            HostSecurityState.locked = false
            HostSecurityState.failedAttempts = 0
        end
    end
    
    -- Step 1: Validate IP
    local ipValid, ipError = ValidateRequestIP(req)
    if not ipValid then
        callback(false, ipError)
        return
    end
    
    -- Step 2: Check if license needs revalidation
    local timeSinceValidation = GetGameTimer() - HostSecurityState.lastValidation
    if not HostSecurityState.licenseValid or timeSinceValidation > HostSecurityState.validationInterval then
        ValidateHostAuthorization(function(valid, message)
            callback(valid, message)
        end)
    else
        -- License still valid
        callback(true, 'Host access granted')
    end
end

--[[ ==================== HOST API PROTECTION ==================== ]]--

-- Protect host endpoint (wrapper for all host routes)
function ProtectHostEndpoint(req, res, handler)
    ValidateHostAccess(req, function(valid, message)
        if valid then
            -- Access granted - call the actual handler
            handler(req, res)
        else
            -- Access denied - log attempt and return error
            Logger.Error(string.format('[EC Admin] Unauthorized host access attempt from %s: %s', 
                req.address or 'unknown', message), '🚨')
            
            res.writeHead(403, { ['Content-Type'] = 'application/json' })
            res.send(json.encode({
                success = false,
                error = 'Host access denied',
                message = message,
                timestamp = os.time()
            }))
        end
    end)
end

--[[ ==================== AUTOMATIC VALIDATION ==================== ]]--

-- Periodic license validation
Citizen.CreateThread(function()
    -- Initial validation on startup
    Citizen.Wait(5000)
    
    local licenseKey = GetConvar('ec_license_key', '')
    if licenseKey ~= '' and IsHostLicense(licenseKey) then
        Logger.Info('Performing initial host license validation...', '🔒')
        ValidateHostAuthorization(function(valid, message)
            if valid then
                Logger.Success('Host mode enabled and validated', '✅')
            else
                Logger.Warn('Host mode disabled: ' .. message, '⚠️')
            end
        end)
        
        -- Update IP allowlist
        UpdateIPAllowlist()
    end
    
    -- Periodic revalidation
    while true do
        Citizen.Wait(300000) -- Every 5 minutes
        
        licenseKey = GetConvar('ec_license_key', '')
        if licenseKey ~= '' and IsHostLicense(licenseKey) then
            ValidateHostAuthorization(function(valid, message)
                if not valid then
                    Logger.Warn('Host validation failed: ' .. message, '⚠️')
                end
            end)
            
            -- Update IP allowlist every 5 minutes
            UpdateIPAllowlist()
        end
    end
end)

--[[ ==================== EXPORTS ==================== ]]--

-- Export for other scripts
exports('ValidateHostAccess', ValidateHostAccess)
exports('ProtectHostEndpoint', ProtectHostEndpoint)
exports('IsHostLicenseValid', function()
    return HostSecurityState.licenseValid
end)

-- Global function for unified router
_G.ValidateHostAccess = ValidateHostAccess
_G.ProtectHostEndpoint = ProtectHostEndpoint

--[[ ==================== ADMIN COMMANDS ==================== ]]--

-- Check host security status (server console only)
RegisterCommand('host:security', function(source)
    if source ~= 0 then return end -- Console only
    
    Logger.Info('=== Host Security Status ===', '🔒')
    Logger.Info('License Valid: ' .. tostring(HostSecurityState.licenseValid))
    Logger.Info('Last Validation: ' .. math.floor((GetGameTimer() - HostSecurityState.lastValidation) / 1000) .. 's ago')
    Logger.Info('Failed Attempts: ' .. HostSecurityState.failedAttempts)
    Logger.Info('Locked: ' .. tostring(HostSecurityState.locked))
    Logger.Info('Allowed IPs: ' .. #NRG_IP_ALLOWLIST)
    
    local licenseKey = GetConvar('ec_license_key', '')
    Logger.Info('License Key: ' .. (licenseKey ~= '' and (licenseKey:sub(1, 10) .. '...') or 'NOT SET'))
    Logger.Info('Is Host License: ' .. tostring(IsHostLicense(licenseKey)))
end, true)

-- Force revalidation (server console only)
RegisterCommand('host:revalidate', function(source)
    if source ~= 0 then return end
    
    Logger.Info('🔒 Forcing host license revalidation...')
    ValidateHostAuthorization(function(valid, message)
        Logger.Info('Validation result: ' .. tostring(valid))
        Logger.Info('Message: ' .. message)
    end)
end, true)

-- Unlock after lockout (server console only - emergency use)
RegisterCommand('host:unlock', function(source)
    if source ~= 0 then return end
    
    HostSecurityState.locked = false
    HostSecurityState.failedAttempts = 0
    Logger.Success('Host features unlocked (manual override)', '✅')
end, true)

Logger.Success('Host Security Validator loaded', '✅')
Logger.Info('Commands: host:security, host:revalidate, host:unlock', '🔒')
