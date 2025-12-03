-- EC Admin Ultimate - Host Server API
-- 🔵 NRG Internal Only - This file only loads if host/ folder exists

if not Config.Host or not Config.Host.enabled then
    return -- Host mode not enabled
end

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
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local src = source
    local identifiers = Utils.GetAllIdentifiers(src)
    
    deferrals.defer()
    Wait(0)
    deferrals.update('Checking global ban status...')
    
    -- Check each identifier
    for idType, identifier in pairs(identifiers) do
        if identifier then
            MakeHostAPIRequest('/api/v1/bans/check/' .. identifier, 'GET', nil, function(success, data)
                if success and data and data.banned then
                    deferrals.done('You are globally banned: ' .. (data.ban.reason or 'No reason provided'))
                end
            end)
        end
    end
    
    Wait(1000) -- Give time for ban check
    deferrals.done()
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
