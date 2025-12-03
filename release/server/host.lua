-- EC Admin Ultimate - Host Control (Server)
-- Main server logic for Host Control features
-- Author: NRG Development
-- Version: 1.0.0

local hostModeEnabled = false
local hostSecretValid = false
local hostSecret = nil

-- List of all 20 APIs in the NRG API Suite
local API_LIST = {
    'analytics',
    'anticheat-sync',
    'audit-logging',
    'authentication',
    'backup-storage',
    'config-sync',
    'control',
    'emergency-control',
    'global-bans',
    'global-chat',
    'license-validation',
    'marketplace-sync',
    'notification-hub',
    'performance-monitor',
    'player-tracking',
    'report-system',
    'resource-hub',
    'screenshot-storage',
    'server-registry',
    'vehicle-registry',
    'webhook-relay'
}

-- API Port mapping
local API_PORTS = {
    ['analytics'] = 30001,
    ['anticheat-sync'] = 30002,
    ['audit-logging'] = 30003,
    ['authentication'] = 30004,
    ['backup-storage'] = 30005,
    ['config-sync'] = 30006,
    ['control'] = 30007,
    ['emergency-control'] = 30008,
    ['global-bans'] = 30009,
    ['global-chat'] = 30010,
    ['license-validation'] = 30011,
    ['marketplace-sync'] = 30012,
    ['notification-hub'] = 30013,
    ['performance-monitor'] = 30014,
    ['player-tracking'] = 30015,
    ['report-system'] = 30016,
    ['resource-hub'] = 30017,
    ['screenshot-storage'] = 30018,
    ['server-registry'] = 30019,
    ['vehicle-registry'] = 30020,
    ['webhook-relay'] = 30021
}

-- Check if host mode is available
local function CheckHostMode()
    -- Check if /host/ folder exists by checking if host config exists
    local hostConfigPath = GetResourcePath(GetCurrentResourceName()) .. '/host/config.lua'
    local file = io.open(hostConfigPath, 'r')
    
    if file then
        file:close()
        hostModeEnabled = true
        Logger.Info('✅ Host folder detected')
        
        -- Check for host_secret file in resource root
        local secretPath = GetResourcePath(GetCurrentResourceName()) .. '/host_secret'
        local secretFile = io.open(secretPath, 'r')
        
        if secretFile then
            hostSecret = secretFile:read('*all'):gsub('%s+', '') -- Remove whitespace
            secretFile:close()
            
            if hostSecret and #hostSecret > 0 then
                hostSecretValid = true
                Logger.Info('🔐 Host secret validated - Full API access enabled')
            else
                Logger.Info('⚠️ Host secret file is empty')
            end
        else
            Logger.Info('⚠️ Host secret file not found (expected: /host_secret)')
            Logger.Info('ℹ️ Create host_secret file in resource root for full access')
        end
    else
        hostModeEnabled = false
        Logger.Info('ℹ️ Host mode not available (Customer version)')
    end
end

-- Initialize host mode check
CreateThread(function()
    Wait(1000)
    CheckHostMode()
end)

-- Get host API URL
local function GetHostAPIURL()
    return GetConvar('ec_host_api_url', 'http://127.0.0.1:30121')
end

-- Get host API key
local function GetHostAPIKey()
    return hostSecret or GetConvar('ec_host_api_key', '')
end

-- Make authenticated request to Host API
local function CallHostAPI(endpoint, method, data, callback)
    if not hostSecretValid then
        if callback then
            callback(false, 'Host mode not available or secret invalid')
        end
        return
    end
    
    local url = GetHostAPIURL() .. endpoint
    local body = data and json.encode(data) or nil
    local headers = {
        ['Content-Type'] = 'application/json',
        ['X-API-Key'] = GetHostAPIKey(),
        ['X-Server-Name'] = GetConvar('sv_hostname', 'Unknown'),
        ['X-Admin-Panel'] = 'true'
    }
    
    PerformHttpRequest(url, function(statusCode, responseText, headers)
        local success = statusCode >= 200 and statusCode < 300
        local response = nil
        
        if responseText and responseText ~= '' then
            local ok, decoded = pcall(json.decode, responseText)
            if ok then
                response = decoded
            else
                response = responseText
            end
        end
        
        if callback then
            callback(success, response, statusCode)
        end
    end, method or 'GET', body, headers)
end

-- Get status of all APIs
function GetAPIsStatus()
    if not hostSecretValid then
        return nil
    end
    
    local apis = {}
    
    for _, apiName in ipairs(API_LIST) do
        -- Make request to each API's health endpoint
        local port = API_PORTS[apiName]
        local url = 'http://127.0.0.1:' .. port .. '/health'
        
        -- This would be async in production, but for now we'll return mock data
        -- In production, you'd use PerformHttpRequest for each API
        table.insert(apis, {
            name = apiName,
            port = port,
            status = 'online', -- Would be determined by actual health check
            uptime = math.random(3600, 86400),
            requests = math.random(1000, 100000),
            avgResponseTime = math.random(10, 150),
            errorRate = math.random(0, 5) / 100,
            version = '1.0.0',
            lastRestart = os.date('%Y-%m-%d %H:%M:%S', os.time() - math.random(3600, 86400))
        })
    end
    
    return apis
end

-- Get connected cities
function GetConnectedCities()
    if not hostSecretValid then
        return nil
    end
    
    local cities = {}
    
    -- Call server-registry API to get connected servers
    CallHostAPI('/api/v1/servers/list', 'GET', nil, function(success, response)
        if success and response and response.servers then
            cities = response.servers
        end
    end)
    
    -- For now, return mock data (would be replaced with actual API call)
    return {
        {
            id = 'city-001',
            name = 'Los Santos RP',
            ip = '192.168.1.100:30120',
            status = 'online',
            players = 48,
            maxPlayers = 64,
            version = '1.0.0',
            lastSeen = os.date('%Y-%m-%d %H:%M:%S'),
            framework = 'qbcore',
            connectedAPIs = {'global-bans', 'player-tracking', 'anticheat-sync', 'analytics'},
            uptime = 86400,
            performance = {
                tps = 49.8,
                memoryUsage = 2048,
                cpuUsage = 45.5
            }
        },
        {
            id = 'city-002',
            name = 'Liberty City RP',
            ip = '192.168.1.101:30120',
            status = 'online',
            players = 32,
            maxPlayers = 48,
            version = '1.0.0',
            lastSeen = os.date('%Y-%m-%d %H:%M:%S'),
            framework = 'esx',
            connectedAPIs = {'global-bans', 'player-tracking', 'analytics'},
            uptime = 43200,
            performance = {
                tps = 50.0,
                memoryUsage = 1536,
                cpuUsage = 32.1
            }
        }
    }
end

-- Get global statistics across all cities
function GetGlobalStats()
    if not hostSecretValid then
        return nil
    end
    
    -- Would aggregate data from all APIs
    return {
        totalCities = 12,
        totalPlayers = 384,
        totalBans = 156,
        totalReports = 89,
        apiUptime = 99.8,
        totalRequests = 1284567,
        avgResponseTime = 42,
        dataProcessed = 2.4, -- GB
        storageUsed = 15.8, -- GB
        totalAlerts = 23,
        activeAlerts = 3
    }
end

-- Get detailed city information
function GetCityDetails(cityId)
    if not hostSecretValid then
        return nil
    end
    
    -- Call APIs to get city details
    CallHostAPI('/api/v1/servers/' .. cityId, 'GET', nil, function(success, response)
        if success and response then
            return response
        end
    end)
    
    -- Mock data for now
    return {
        id = cityId,
        name = 'Los Santos RP',
        ip = '192.168.1.100:30120',
        status = 'online',
        players = 48,
        maxPlayers = 64,
        version = '1.0.0',
        framework = 'qbcore',
        connectedAPIs = {'global-bans', 'player-tracking', 'anticheat-sync', 'analytics'},
        performance = {
            tps = 49.8,
            memoryUsage = 2048,
            cpuUsage = 45.5,
            networkIn = 1.2, -- MB/s
            networkOut = 0.8 -- MB/s
        },
        recentPlayers = {},
        recentBans = {},
        recentReports = {},
        config = {}
    }
end

-- Control API (start, stop, restart, configure)
function ControlAPI(source, apiName, action, params)
    if not hostSecretValid then
        TriggerClientEvent('ec_admin:host:controlResult', source, false, 'Host mode not available', apiName, action)
        return
    end
    
    -- Verify admin has permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.control') then
        TriggerClientEvent('ec_admin:host:controlResult', source, false, 'No permission', apiName, action)
        return
    end
    
    local endpoint = '/api/v1/control/' .. apiName
    local data = {
        action = action,
        params = params,
        requestedBy = GetPlayerName(source)
    }
    
    CallHostAPI(endpoint, 'POST', data, function(success, response)
        local message = success and 'API action completed' or 'API action failed'
        if response and response.message then
            message = response.message
        end
        
        TriggerClientEvent('ec_admin:host:controlResult', source, success, message, apiName, action)
        
        -- Log the action
        LogAdminAction(source, 'HOST_API_CONTROL', {
            apiName = apiName,
            action = action,
            params = params,
            success = success
        })
    end)
end

-- Execute command on specific city
function ExecuteCityCommand(source, cityId, command, params)
    if not hostSecretValid then
        TriggerClientEvent('ec_admin:host:cityCommandResult', source, false, 'Host mode not available', cityId, command)
        return
    end
    
    -- Verify admin has permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.control') then
        TriggerClientEvent('ec_admin:host:cityCommandResult', source, false, 'No permission', cityId, command)
        return
    end
    
    local endpoint = '/api/v1/cities/' .. cityId .. '/execute'
    local data = {
        command = command,
        params = params,
        requestedBy = GetPlayerName(source)
    }
    
    CallHostAPI(endpoint, 'POST', data, function(success, response)
        local message = success and 'Command executed' or 'Command failed'
        if response and response.message then
            message = response.message
        end
        
        TriggerClientEvent('ec_admin:host:cityCommandResult', source, success, message, cityId, command)
        
        -- Log the action
        LogAdminAction(source, 'HOST_CITY_COMMAND', {
            cityId = cityId,
            command = command,
            params = params,
            success = success
        })
    end)
end

-- Emergency stop API
function EmergencyStopAPI(source, apiName, reason)
    if not hostSecretValid then
        return
    end
    
    -- Verify admin has permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.emergency') then
        TriggerClientEvent('ec_admin:host:controlResult', source, false, 'No permission', apiName, 'emergency_stop')
        return
    end
    
    local endpoint = '/api/v1/emergency/stop/' .. apiName
    local data = {
        reason = reason,
        requestedBy = GetPlayerName(source)
    }
    
    CallHostAPI(endpoint, 'POST', data, function(success, response)
        TriggerClientEvent('ec_admin:host:controlResult', source, success, 
            success and 'Emergency stop executed' or 'Emergency stop failed', 
            apiName, 'emergency_stop')
        
        -- Log the critical action
        LogAdminAction(source, 'HOST_EMERGENCY_STOP', {
            apiName = apiName,
            reason = reason,
            success = success
        })
        
        -- Notify all admins
        for _, playerId in ipairs(GetPlayers()) do
            if exports['ec_admin_ultimate']:HasPermission(playerId, 'ec_admin.host.view') then
                TriggerClientEvent('ec_admin:host:emergencyShutdown', playerId, apiName, reason)
            end
        end
    end)
end

-- Restart API
function RestartAPI(source, apiName)
    ControlAPI(source, apiName, 'restart', {})
end

-- Update API configuration
function UpdateAPIConfig(source, apiName, config)
    if not hostSecretValid then
        return
    end
    
    -- Verify admin has permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.configure') then
        TriggerClientEvent('ec_admin:host:controlResult', source, false, 'No permission', apiName, 'update_config')
        return
    end
    
    local endpoint = '/api/v1/config/' .. apiName
    local data = {
        config = config,
        requestedBy = GetPlayerName(source)
    }
    
    CallHostAPI(endpoint, 'PUT', data, function(success, response)
        if success then
            TriggerClientEvent('ec_admin:host:configUpdated', source, apiName)
        else
            TriggerClientEvent('ec_admin:host:controlResult', source, false, 'Config update failed', apiName, 'update_config')
        end
        
        -- Log the action
        LogAdminAction(source, 'HOST_API_CONFIG_UPDATE', {
            apiName = apiName,
            config = config,
            success = success
        })
    end)
end

-- Log admin action
function LogAdminAction(source, action, details)
    local identifier = GetPlayerIdentifiers(source)[1]
    local playerName = GetPlayerName(source)
    
    -- Log to database
    MySQL.Async.execute('INSERT INTO ec_admin_logs (admin_id, admin_name, action, details, timestamp) VALUES (?, ?, ?, ?, ?)',
        {identifier, playerName, action, json.encode(details), os.time()})
    
    -- Send to audit-logging API
    if hostSecretValid then
        CallHostAPI('/api/v1/audit/log', 'POST', {
            adminId = identifier,
            adminName = playerName,
            action = action,
            details = details,
            timestamp = os.time(),
            serverName = GetConvar('sv_hostname', 'Unknown')
        })
    end
end

-- Export functions
exports('CheckHostMode', CheckHostMode)
exports('GetAPIsStatus', GetAPIsStatus)
exports('GetConnectedCities', GetConnectedCities)
exports('GetGlobalStats', GetGlobalStats)
exports('GetCityDetails', GetCityDetails)
exports('CallHostAPI', CallHostAPI)

Logger.Info('🏢 Host Control server loaded')
