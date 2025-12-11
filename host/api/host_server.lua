-- EC Admin Ultimate - Host Server API
-- 🔵 NRG Internal Only - This file only loads if host/ folder exists

-- Check if host folder exists (don't rely on Config.Host which might not be set yet)
local function hostFolderExists()
    local hostFiles = {
        'host/api/host_server.lua',
        'host/api/server.js'
    }
    
    for _, file in ipairs(hostFiles) do
        local content = LoadResourceFile(GetCurrentResourceName(), file)
        if content then
            return true
        end
    end
    
    return false
end

-- Only load if host folder exists
if not hostFolderExists() then
    return -- Not in host mode
end

-- Initialize Config.Host if not set
if not Config then Config = {} end
if not Config.Host then Config.Host = {} end
Config.Host.enabled = true

local HOST_API_URL = 'http://localhost:' .. (Config.Host.apiPort or 30121)
local API_KEY = Config.Host.masterLicense or ''

print('^2[EC Admin Host]^7 Host API server integration loaded')
print('^3[Host API]^7 URL: ' .. HOST_API_URL)

-- ==================== UTILITY FUNCTIONS ====================

local function MakeHostAPIRequest(endpoint, method, data, callback)
    method = method or 'GET'
    
    PerformHttpRequest(HOST_API_URL .. endpoint, function(statusCode, response, headers)
        local success = statusCode >= 200 and statusCode < 300
        local responseData = nil
        
        if response then
            local ok, decoded = pcall(json.decode, response)
            if ok then
                responseData = decoded
            end
        end
        
        if callback then
            callback(success, responseData, statusCode)
        end
    end, method, data and json.encode(data) or nil, {
        ['Content-Type'] = 'application/json',
        ['X-API-Key'] = API_KEY
    })
end

-- ==================== PLAYER SYNC ====================

-- Sync player data to host API every 30 seconds
CreateThread(function()
    while true do
        Wait(30000) -- 30 seconds
        
        local players = {}
        for _, playerId in ipairs(GetPlayers()) do
            local name = GetPlayerName(playerId)
            local identifiers = Utils.GetAllIdentifiers(playerId)
            local ping = GetPlayerPing(playerId)
            
            table.insert(players, {
                serverId = tonumber(playerId),
                name = name,
                identifiers = identifiers,
                ping = ping,
                endpoint = GetPlayerEndpoint(playerId)
            })
        end
        
        -- Update player cache in host API
        MakeHostAPIRequest('/api/v1/players/update-cache', 'POST', {
            players = players,
            cityIdentifier = Config.Host.cityIdentifier,
            timestamp = os.time()
        }, function(success, data)
            if success then
                print('^2[Host API]^7 Player cache updated (' .. #players .. ' players)')
            end
        end)
    end
end)

-- ==================== METRICS SYNC ====================

-- Sync metrics to host API every 60 seconds
CreateThread(function()
    while true do
        Wait(60000) -- 60 seconds
        
        local metrics = {
            players = {
                online = #GetPlayers(),
                max = GetConvarInt('sv_maxclients', 32)
            },
            server = {
                uptime = os.time() - GetConvarInt('sv_startTime', 0),
                version = GetConvar('version', 'unknown')
            }
        }
        
        -- Record metrics
        for metricType, value in pairs({
            player_count = metrics.players.online,
            server_uptime = metrics.server.uptime
        }) do
            MakeHostAPIRequest('/api/metrics/record', 'POST', {
                cityIdentifier = Config.Host.cityIdentifier,
                metricType = metricType,
                value = value
            })
        end
    end
end)

-- ==================== GLOBAL BAN CHECK ====================

-- Check player against global ban system on connect
-- NOTE: This is NON-BLOCKING - only blocks if player is actually banned
-- If API is down or slow, players can still connect (fail-open for availability)
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local src = source
    
    -- Check if player is NRG staff first (bypass ban check)
    local success, isNRGStaff = pcall(function()
        if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].IsNRGStaff then
            return exports['ec_admin_ultimate']:IsNRGStaff(src)
        end
        return false
    end)
    
    if success and isNRGStaff then
        -- NRG staff bypass all checks
        return
    end
    
    -- Get player identifiers
    local identifiers = GetPlayerIdentifiers(src)
    if not identifiers or #identifiers == 0 then
        return -- Can't check, allow connection
    end
    
    deferrals.defer()
    Wait(0)
    deferrals.update('Checking global ban status...')
    
    local banFound = false
    local banReason = nil
    local checksCompleted = 0
    local totalChecks = 0
    
    -- Count total identifiers to check
    for _, identifier in ipairs(identifiers) do
        if identifier and (string.find(identifier, 'license:') or string.find(identifier, 'steam:') or string.find(identifier, 'discord:')) then
            totalChecks = totalChecks + 1
        end
    end
    
    -- If no valid identifiers, allow connection
    if totalChecks == 0 then
        deferrals.done()
        return
    end
    
    -- Check each identifier
    for _, identifier in ipairs(identifiers) do
        if identifier and (string.find(identifier, 'license:') or string.find(identifier, 'steam:') or string.find(identifier, 'discord:')) then
            MakeHostAPIRequest('/api/v1/bans/check/' .. identifier, 'GET', nil, function(success, data)
                checksCompleted = checksCompleted + 1
                
                if success and data and data.banned then
                    banFound = true
                    banReason = data.ban and data.ban.reason or 'No reason provided'
                    deferrals.done('You are globally banned: ' .. banReason)
                    return
                end
                
                -- If all checks completed and no ban found, allow connection
                if checksCompleted >= totalChecks and not banFound then
                    deferrals.done()
                end
            end)
        end
    end
    
    -- Timeout: If API doesn't respond within 3 seconds, allow connection (fail-open)
    CreateThread(function()
        Wait(3000)
        if checksCompleted < totalChecks and not banFound then
            checksCompleted = totalChecks
            if not banFound then
                deferrals.done() -- Allow connection if API is slow/down
            end
        end
    end)
end)

-- ==================== NRG STAFF ACCESS ====================

RegisterCommand('nrg:flyin', function(source, args)
    -- Only allow from console or authorized NRG staff
    if source ~= 0 then
        return
    end
    
    local staffEmail = args[1]
    local staffName = args[2] or 'NRG Staff'
    
    if not staffEmail then
        print('^1[Host API]^7 Usage: nrg:flyin <email> <name>')
        return
    end
    
    -- Log staff fly-in
    MakeHostAPIRequest('/api/host/nrg/flyin', 'POST', {
        staffEmail = staffEmail,
        staffName = staffName,
        cityIdentifier = Config.Host.cityIdentifier,
        action = 'fly_in'
    }, function(success, data)
        if success then
            print('^2[Host API]^7 NRG staff fly-in logged: ' .. staffEmail)
            
            -- Notify city owner via webhook
            if Config.Webhooks.staffAccess and Config.Webhooks.staffAccess ~= '' then
                local webhook = Config.Webhooks.staffAccess
                PerformHttpRequest(webhook, function() end, 'POST', json.encode({
                    embeds = {{
                        title = '🔵 NRG Staff Access',
                        description = string.format('**%s** (%s) has accessed your server for support/review.', staffName, staffEmail),
                        color = 3447003,
                        timestamp = os.date('!%Y-%m-%dT%H:%M:%S'),
                        footer = {
                            text = 'This access is logged and audited'
                        }
                    }}
                }), { ['Content-Type'] = 'application/json' })
            end
        end
    end)
end, true) -- Restricted command

-- ==================== HOST EVENTS ====================

RegisterNetEvent('ec_admin:host:syncBan', function(identifier, reason, duration, global)
    local src = source
    
    if not HasPermission(src) then return end
    
    -- Create ban via host API
    MakeHostAPIRequest('/api/v1/bans', 'POST', {
        identifier = identifier,
        reason = reason,
        duration = duration or 0,
        global = global or false,
        adminName = GetPlayerName(src)
    }, function(success, data)
        if success then
            TriggerClientEvent('ec_admin:notification', src, 
                global and 'Global ban created' or 'Ban created', 
                'success'
            )
        end
    end)
end)

print('^2[EC Admin Host]^7 Host API integration complete')
