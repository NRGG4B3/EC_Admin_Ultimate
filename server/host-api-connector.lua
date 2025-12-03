-- EC Admin Ultimate - Host API Connector (FiveM → Node.js)
-- Connects FiveM server to Node.js Host API
-- Author: NRG Development
-- Version: 1.0.0

local HOST_API_URL = GetConvar('ec_host_api_url', 'http://127.0.0.1:30121')
local API_KEY = GetConvar('ec_host_api_key', '')
local SERVER_NAME = GetConvar('sv_hostname', 'Unknown Server')
local SERVER_IP = GetConvar('ec_server_ip', '127.0.0.1')
local SERVER_PORT = GetConvar('sv_port', '30120')

local isConnected = false
local lastHeartbeat = 0

-- Register with Host API on startup
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Wait for server to be ready
    
    if API_KEY == '' then
        Logger.Info('⚠️ No Host API key configured (ec_host_api_key)')
        Logger.Info('Host API features disabled')
        return
    end
    
    -- Register server with Host API
    PerformHttpRequest(HOST_API_URL .. '/api/v1/server/register', function(statusCode, responseText, headers)
        if statusCode == 200 then
            Logger.Info('✅ Connected to Host API')
            isConnected = true
        elseif statusCode == 0 then
            -- Silently fail on connection errors (Host API might not be running)
            isConnected = false
        elseif statusCode == 404 then
            -- API endpoint doesn't exist yet - silently fail
            isConnected = false
        else
            Logger.Info('⚠️ Failed to connect to Host API: ' .. statusCode)
            Logger.Info('Response: ' .. (responseText or 'No response'))
            isConnected = false
        end
    end, 'POST', json.encode({
        serverName = SERVER_NAME,
        ip = SERVER_IP,
        port = SERVER_PORT,
        apiKey = API_KEY,
        version = '1.0.0'
    }), {
        ['Content-Type'] = 'application/json',
        ['X-API-Key'] = API_KEY
    })
end)

-- Heartbeat to keep connection alive
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Every minute
        
        if isConnected then
            local now = os.time()
            if now - lastHeartbeat >= 60 then
                lastHeartbeat = now
                
                -- Send heartbeat (optional)
                -- This lets the Host API know the server is still alive
            end
        end
    end
end)

-- Handle Host API commands sent to this server
RegisterNetEvent('ec:host:executeCommand')
AddEventHandler('ec:host:executeCommand', function(command, params, callbackId)
    -- Verify this came from Host API (would include auth check)
    
    local result = {
        success = false,
        error = 'Unknown command'
    }
    
    if command == 'getPlayers' then
        local players = {}
        for _, playerId in ipairs(GetPlayers()) do
            table.insert(players, {
                serverId = playerId,
                name = GetPlayerName(playerId),
                identifier = GetPlayerIdentifiers(playerId)[1] or 'unknown',
                ping = GetPlayerPing(playerId)
            })
        end
        result = { success = true, players = players }
        
    elseif command == 'kickPlayer' then
        local playerId = params.playerId
        local reason = params.reason or 'Kicked by Host API'
        
        if playerId and GetPlayerName(playerId) then
            DropPlayer(playerId, reason)
            result = { success = true, message = 'Player kicked' }
        else
            result = { success = false, error = 'Player not found' }
        end
        
    elseif command == 'getMetrics' then
        result = {
            success = true,
            metrics = {
                players = #GetPlayers(),
                maxPlayers = GetConvarInt('sv_maxclients', 32),
                uptime = os.time() - (startTime or os.time()),
                tps = 50.0 -- Would calculate actual TPS
            }
        }
    end
    
    -- Send result back to Host API
    if callbackId then
        PerformHttpRequest(HOST_API_URL .. '/api/v1/callback/' .. callbackId, function() end, 'POST', 
            json.encode(result), {
                ['Content-Type'] = 'application/json',
                ['X-API-Key'] = API_KEY
            })
    end
end)

-- Export helper function for other scripts
function CallHostAPI(endpoint, method, data, callback)
    if not isConnected then
        if callback then
            callback(false, 'Not connected to Host API')
        end
        return
    end
    
    local url = HOST_API_URL .. endpoint
    local body = data and json.encode(data) or nil
    
    PerformHttpRequest(url, function(statusCode, responseText, headers)
        local success = statusCode >= 200 and statusCode < 300
        local response = nil
        
        if responseText then
            local ok, decoded = pcall(json.decode, responseText)
            if ok then
                response = decoded
            end
        end
        
        if callback then
            callback(success, response or responseText, statusCode)
        end
    end, method or 'GET', body, {
        ['Content-Type'] = 'application/json',
        ['X-API-Key'] = API_KEY
    })
end

exports('CallHostAPI', CallHostAPI)
_G.CallHostAPI = CallHostAPI

-- Check connection status
RegisterCommand('ec_host_status', function(source)
    if source ~= 0 then return end
    
    Logger.Info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    Logger.Info('Host API Connection Status')
    Logger.Info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    Logger.Info('URL: ' .. HOST_API_URL)
    Logger.Info('Connected: ' .. (isConnected and 'YES' or 'NO'))
    Logger.Info('API Key: ' .. (API_KEY ~= '' and 'Configured' or 'Not set'))
    Logger.Info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
end, true)

Logger.Info('📡 Host API connector loaded')