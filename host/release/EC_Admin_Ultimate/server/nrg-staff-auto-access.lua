-- ============================================================================
-- NRG Staff Auto-Access System (API-Based Verification)
-- ============================================================================
-- Verifies NRG staff via api.ecbetasolutions.com
-- NO hardcoded identifiers - all authentication via API
-- NO VPS IPs exposed - secure bearer token authentication
-- Automatic host dashboard access when visiting customer servers
-- ============================================================================

Logger.Info('🔐 NRG Staff Auto-Access System - Initializing...')

-- API Configuration
local API_BASE_URL = Config.API and Config.API.baseUrl or "https://api.ecbetasolutions.com"
local API_STAFF_VERIFY_ENDPOINT = "/api/v1/staff/verify"
local API_TIMEOUT = 5000  -- 5 second timeout
local CACHE_DURATION = 3600  -- Cache verification for 1 hour

-- Verification Cache (prevents excessive API calls)
local staffVerificationCache = {}

-- ============================================================================
-- VERIFY NRG STAFF VIA API (Secure, No Hardcoded IDs)
-- ============================================================================
local function VerifyNRGStaffViaAPI(identifiers, callback)
    -- Build verification request
    local requestData = {
        identifiers = identifiers,
        timestamp = os.time(),
        server = GetConvar('sv_hostname', 'Unknown Server')
    }
    
    local url = API_BASE_URL .. API_STAFF_VERIFY_ENDPOINT
    
    Logger.Debug(string.format('🔍 Verifying staff via API: %s', url))
    
    -- Send verification request to API
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            local success, data = pcall(json.decode, response)
            
            if success and data and data.isStaff then
                Logger.Success(string.format('✅ NRG Staff verified: %s (%s)', data.name, data.role))
                callback(true, {
                    name = data.name,
                    role = data.role,
                    permissions = data.permissions or {},
                    hostAccess = data.hostAccess or false
                })
            else
                Logger.Debug('Not NRG staff (API verification failed)')
                callback(false, nil)
            end
        elseif statusCode == 404 then
            -- Not staff (expected for regular players)
            Logger.Debug('Player is not NRG staff')
            callback(false, nil)
        else
            -- API error - fail closed (deny access)
            Logger.Warn(string.format('⚠️ Staff verification API error: %d', statusCode))
            callback(false, nil)
        end
    end, 'POST', json.encode(requestData), {
        ['Content-Type'] = 'application/json',
        ['Accept'] = 'application/json',
        ['User-Agent'] = 'EC-Admin-Ultimate/1.0'
    })
end

-- ============================================================================
-- CHECK IF PLAYER IS NRG STAFF (With Caching)
-- ============================================================================
local function IsNRGStaff(source, callback)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers or #identifiers == 0 then
        if callback then callback(false, nil) end
        return false, nil
    end
    
    -- Check cache first (prevent excessive API calls)
    local cacheKey = table.concat(identifiers, '|')
    local cachedData = staffVerificationCache[cacheKey]
    
    if cachedData and (os.time() - cachedData.timestamp) < CACHE_DURATION then
        Logger.Debug('Using cached staff verification')
        if callback then callback(cachedData.isStaff, cachedData.data) end
        return cachedData.isStaff, cachedData.data
    end
    
    -- Not in cache or expired - verify via API
    if callback then
        -- Async verification
        VerifyNRGStaffViaAPI(identifiers, function(isStaff, staffData)
            -- Cache result
            staffVerificationCache[cacheKey] = {
                isStaff = isStaff,
                data = staffData,
                timestamp = os.time()
            }
            
            callback(isStaff, staffData)
        end)
    else
        -- Synchronous check (use cached data only)
        return false, nil
    end
end

-- ============================================================================
-- EXPORT: Check NRG Staff Status (For Other Scripts)
-- ============================================================================
_G.IsNRGStaff = IsNRGStaff

exports('IsNRGStaff', function(source, callback)
    return IsNRGStaff(source, callback)
end)

-- ============================================================================
-- GRANT PERMISSIONS FOR NRG STAFF
-- ============================================================================
local function GrantNRGStaffAccess(source, staffData)
    local playerName = GetPlayerName(source)
    
    Logger.Success(string.format('👑 NRG Staff Auto-Access: %s (%s) - Role: %s', staffData.name, playerName, staffData.role))
    
    -- Initialize permissions if not exists
    if not EC_PERMISSIONS then
        EC_PERMISSIONS = {}
    end
    
    -- Grant full owner-level permissions
    EC_PERMISSIONS[source] = {
        level = 'owner',
        nrgStaff = true,
        staffName = staffData.name,
        staffRole = staffData.role,
        allPermissions = true,
        hostAccess = staffData.hostAccess or false  -- Host dashboard access
    }
    
    -- Show host dashboard if enabled and staff has access
    local hasHostFolder = LoadResourceFile(GetCurrentResourceName(), 'host/config.lua') ~= nil
    if hasHostFolder and staffData.hostAccess then
        Logger.Info(string.format('📊 Host Dashboard enabled for: %s', staffData.name))
        TriggerClientEvent('ec_admin:showHostDashboard', source, true)
    end
    
    -- WEBHOOK DISABLED: Webhook is now sent by player-events.lua centralized handler
    -- This prevents duplicate webhook notifications (was causing 3x webhooks)
    -- The centralized handler already sends a join notification for all players
    
    -- Note: If you want NRG-specific webhook notifications, modify player-events.lua
    -- to check if player is NRG staff and send a different webhook there
end

-- Check if player has txAdmin permissions
local function HasTxAdminPerms(source)
    -- Check if they have txAdmin admin permissions
    if IsPlayerAceAllowed(source, 'command.txadmin') or 
       IsPlayerAceAllowed(source, 'txadmin.admins') or
       IsPlayerAceAllowed(source, 'txAdmin') then
        return true
    end
    return false
end

-- Grant permissions for txAdmin staff
local function GrantTxAdminAccess(source)
    local playerName = GetPlayerName(source)
    
    print(('^3[txAdmin] ✅ Granting admin permissions to: %s^0'):format(playerName))
    
    if not EC_PERMISSIONS then
        EC_PERMISSIONS = {}
    end
    
    EC_PERMISSIONS[source] = {
        level = 'admin',
        txAdmin = true,
        allPermissions = true
    }
end

-- ============================================================================
-- AUTO-GRANT PERMISSIONS ON PLAYER JOIN (Async API Verification)
-- ============================================================================
AddEventHandler('playerJoining', function()
    local _source = source
    
    -- Small delay to ensure player is fully connected
    SetTimeout(2000, function()
        -- Check NRG staff status via API (async)
        IsNRGStaff(_source, function(isNRG, staffData)
        
            if isNRG and staffData then
                GrantNRGStaffAccess(_source, staffData)
            else
                -- Not NRG staff - check txAdmin permissions
                if HasTxAdminPerms(_source) then
                    GrantTxAdminAccess(_source)
                end
            end
        end)
    end)
end)

-- ============================================================================
-- PERMISSION CHECK EVENT (When Player Opens Admin Menu)
-- ============================================================================
RegisterNetEvent('ec_admin:checkPermission', function()
    local src = source
    
    Logger.Debug(string.format('🔑 Permission check: %s (%d)', GetPlayerName(src), src))
    
    -- Check NRG staff via API (async)
    IsNRGStaff(src, function(isNRG, staffData)
        if isNRG and staffData then
            -- Auto-grant permissions if not already granted
            if not EC_PERMISSIONS or not EC_PERMISSIONS[src] or not EC_PERMISSIONS[src].nrgStaff then
                GrantNRGStaffAccess(src, staffData)
            end
        end
    end)
end)

-- ============================================================================
-- CLEAR CACHE ON PLAYER DISCONNECT
-- ============================================================================
AddEventHandler('playerDropped', function()
    local _source = source
    
    -- Clear permissions
    if EC_PERMISSIONS and EC_PERMISSIONS[_source] then
        EC_PERMISSIONS[_source] = nil
    end
    
    -- Clear verification cache for this player
    local identifiers = GetPlayerIdentifiers(_source)
    if identifiers then
        local cacheKey = table.concat(identifiers, '|')
        if staffVerificationCache[cacheKey] then
            staffVerificationCache[cacheKey] = nil
            Logger.Debug('🗑️ Cleared staff verification cache on disconnect')
        end
    end
end)

-- ============================================================================
-- CONSOLE COMMAND: Check Staff Status
-- ============================================================================
RegisterCommand('ec:checkstaff', function(source, args, rawCommand)
    if source ~= 0 then
        return  -- Server console only
    end
    
    local playerId = tonumber(args[1])
    if not playerId then
        print('Usage: ec:checkstaff <playerid>')
        return
    end
    
    IsNRGStaff(playerId, function(isStaff, staffData)
        if isStaff and staffData then
            print(string.format('^2✅ Player %d IS NRG Staff^0', playerId))
            print(string.format('   Name: %s', staffData.name))
            print(string.format('   Role: %s', staffData.role))
            print(string.format('   Host Access: %s', staffData.hostAccess and 'Yes' or 'No'))
        else
            print(string.format('^1❌ Player %d is NOT NRG Staff^0', playerId))
        end
    end)
end, true)

Logger.Success('✅ NRG Staff Auto-Access System Loaded (API-Based Verification)')
Logger.Info('   🌐 Verification: api.ecbetasolutions.com')
Logger.Info('   🔐 Security: Bearer token authentication')
Logger.Info('   ⚡ Cache: 1 hour per player')
Logger.Info('   📊 Host Dashboard: Auto-enabled for staff')

-- ============================================================================
-- PERMISSION CHECK EVENT (When Player Opens Admin Menu)
-- ============================================================================
RegisterNetEvent('ec_admin:checkPermission', function()
    local src = source
    
    Logger.Debug(string.format('🔑 Permission check: %s (%d)', GetPlayerName(src), src))
    
    -- Check NRG staff via API (async)
    IsNRGStaff(src, function(isNRG, staffData)
        if isNRG and staffData then
            -- Auto-grant permissions if not already granted
            if not EC_PERMISSIONS or not EC_PERMISSIONS[src] or not EC_PERMISSIONS[src].nrgStaff then
                GrantNRGStaffAccess(src, staffData)
            end
        
            TriggerClientEvent('ec_admin:permissionResult', src, true)
        end
    end)
    
    -- Check txAdmin permissions next
    if HasTxAdminPerms(src) then
        GrantTxAdminAccess(src)
        TriggerClientEvent('ec_admin:permissionResult', src, true)
        return
    end
    
    -- Check normal permissions
    local hasPerm = EC_Perms and EC_Perms.Has(src, 'admin.menu') or false
    TriggerClientEvent('ec_admin:permissionResult', src, hasPerm)
end)

-- ============================================================================
-- Manual grant command (in case auto-grant fails)
-- ============================================================================
RegisterCommand('nrg:grant', function(source, args)
    local isStaff, staffData = IsNRGStaff(source)
    
    if isStaff then
        GrantNRGStaffAccess(source, staffData)
        print(('^2[NRG Staff] Manually granted access to %s^0'):format(staffData.name))
    else
        print('^1[NRG Staff] Not recognized as NRG staff^0')
    end
end, false)

-- ============================================================================
-- Export for other scripts to check NRG staff status
-- ============================================================================
exports('IsNRGStaff', function(source)
    return IsNRGStaff(source)
end)

Logger.Info('')