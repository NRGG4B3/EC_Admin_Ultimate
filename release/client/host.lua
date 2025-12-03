-- EC Admin Ultimate - Host Control (Client)
-- Main client logic for Host Control features
-- Author: NRG Development
-- Version: 1.0.0

local hostModeEnabled = false
local hostSecretValid = false
local hostDataCache = {
    apis = {},
    connectedCities = {},
    globalStats = {},
    lastUpdate = 0
}

-- Check if host mode is available
local function CheckHostMode()
    lib.callback('ec_admin:host:checkMode', false, function(data)
        if data and data.enabled then
            hostModeEnabled = true
            hostSecretValid = data.secretValid
            
            if hostSecretValid then
                Logger.Info('🔐 Host Mode Enabled - Full API Access')
            else
                Logger.Info('⚠️ Host folder found but secret invalid')
            end
        else
            hostModeEnabled = false
            hostSecretValid = false
        end
    end)
end

-- Initialize host mode check on resource start
CreateThread(function()
    Wait(2000) -- Wait for server to initialize
    CheckHostMode()
end)

-- Refresh host data periodically
CreateThread(function()
    while true do
        Wait(30000) -- Every 30 seconds
        
        if hostSecretValid then
            -- Refresh APIs status
            lib.callback('ec_admin:host:getAPIsStatus', false, function(data)
                if data then
                    hostDataCache.apis = data
                    hostDataCache.lastUpdate = GetGameTimer()
                end
            end)
            
            -- Refresh connected cities
            lib.callback('ec_admin:host:getConnectedCities', false, function(data)
                if data then
                    hostDataCache.connectedCities = data
                end
            end)
            
            -- Refresh global stats
            lib.callback('ec_admin:host:getGlobalStats', false, function(data)
                if data then
                    hostDataCache.globalStats = data
                end
            end)
        end
    end
end)

-- Get host mode status
function GetHostModeStatus()
    return {
        enabled = hostModeEnabled,
        secretValid = hostSecretValid,
        hasAccess = hostSecretValid
    }
end

-- Get cached host data
function GetHostData()
    return hostDataCache
end

-- Force refresh host data
function RefreshHostData()
    if not hostSecretValid then
        return false
    end
    
    lib.callback('ec_admin:host:getAPIsStatus', false, function(data)
        if data then
            hostDataCache.apis = data
            hostDataCache.lastUpdate = GetGameTimer()
            SendNUIMessage({
                action = 'updateHostAPIs',
                data = data
            })
        end
    end)
    
    lib.callback('ec_admin:host:getConnectedCities', false, function(data)
        if data then
            hostDataCache.connectedCities = data
            SendNUIMessage({
                action = 'updateHostCities',
                data = data
            })
        end
    end)
    
    lib.callback('ec_admin:host:getGlobalStats', false, function(data)
        if data then
            hostDataCache.globalStats = data
            SendNUIMessage({
                action = 'updateHostStats',
                data = data
            })
        end
    end)
    
    return true
end

-- Control specific API
function ControlAPI(apiName, action, params)
    if not hostSecretValid then
        return false
    end
    
    TriggerServerEvent('ec_admin:host:controlAPI', apiName, action, params)
end

-- View city details
function ViewCityDetails(cityId)
    if not hostSecretValid then
        return false
    end
    
    lib.callback('ec_admin:host:getCityDetails', false, function(data)
        if data then
            SendNUIMessage({
                action = 'showCityDetails',
                data = data
            })
        end
    end, cityId)
end

-- Execute command on specific city
function ExecuteCityCommand(cityId, command, params)
    if not hostSecretValid then
        return false
    end
    
    TriggerServerEvent('ec_admin:host:executeCityCommand', cityId, command, params)
end

-- Get API logs
function GetAPILogs(apiName, filters)
    if not hostSecretValid then
        return false
    end
    
    lib.callback('ec_admin:host:getAPILogs', false, function(data)
        if data then
            SendNUIMessage({
                action = 'showAPILogs',
                data = data
            })
        end
    end, apiName, filters)
end

-- Get API metrics
function GetAPIMetrics(apiName, timeRange)
    if not hostSecretValid then
        return false
    end
    
    lib.callback('ec_admin:host:getAPIMetrics', false, function(data)
        if data then
            SendNUIMessage({
                action = 'showAPIMetrics',
                data = data
            })
        end
    end, apiName, timeRange)
end

-- Emergency stop API
function EmergencyStopAPI(apiName, reason)
    if not hostSecretValid then
        return false
    end
    
    TriggerServerEvent('ec_admin:host:emergencyStopAPI', apiName, reason)
end

-- Restart API
function RestartAPI(apiName)
    if not hostSecretValid then
        return false
    end
    
    TriggerServerEvent('ec_admin:host:restartAPI', apiName)
end

-- Update API config
function UpdateAPIConfig(apiName, config)
    if not hostSecretValid then
        return false
    end
    
    TriggerServerEvent('ec_admin:host:updateAPIConfig', apiName, config)
end

-- Export functions for UI
exports('GetHostModeStatus', GetHostModeStatus)
exports('GetHostData', GetHostData)
exports('RefreshHostData', RefreshHostData)
exports('ControlAPI', ControlAPI)
exports('ViewCityDetails', ViewCityDetails)
exports('ExecuteCityCommand', ExecuteCityCommand)
exports('GetAPILogs', GetAPILogs)
exports('GetAPIMetrics', GetAPIMetrics)
exports('EmergencyStopAPI', EmergencyStopAPI)
exports('RestartAPI', RestartAPI)
exports('UpdateAPIConfig', UpdateAPIConfig)

Logger.Info('🏢 Host Control client loaded')
