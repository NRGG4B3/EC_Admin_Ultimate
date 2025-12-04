-- EC Admin Ultimate - Host Control Actions (Server)
-- All RegisterNetEvent for host actions
-- Author: NRG Development
-- Version: 1.0.0

-- Control API (start, stop, restart, configure)
RegisterNetEvent('ec_admin:host:controlAPI', function(apiName, action, params)
    local source = source
    exports['ec_admin_ultimate']:ControlAPI(source, apiName, action, params)
end)

-- Execute command on specific city
RegisterNetEvent('ec_admin:host:executeCityCommand', function(cityId, command, params)
    local source = source
    exports['ec_admin_ultimate']:ExecuteCityCommand(source, cityId, command, params)
end)

-- Emergency stop API
RegisterNetEvent('ec_admin:host:emergencyStopAPI', function(apiName, reason)
    local source = source
    exports['ec_admin_ultimate']:EmergencyStopAPI(source, apiName, reason)
end)

-- Restart API
RegisterNetEvent('ec_admin:host:restartAPI', function(apiName)
    local source = source
    exports['ec_admin_ultimate']:RestartAPI(source, apiName)
end)

-- Update API configuration
RegisterNetEvent('ec_admin:host:updateAPIConfig', function(apiName, config)
    local source = source
    exports['ec_admin_ultimate']:UpdateAPIConfig(source, apiName, config)
end)

-- Broadcast message to all cities
RegisterNetEvent('ec_admin:host:broadcastToAllCities', function(message, messageType)
    local source = source
    
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.broadcast') then
        return
    end
    
    -- Send to all connected cities via control API
    local cities = exports['ec_admin_ultimate']:GetConnectedCities()
    
    for _, city in ipairs(cities) do
        exports['ec_admin_ultimate']:ExecuteCityCommand(source, city.id, 'broadcast', {
            message = message,
            messageType = messageType,
            from = 'NRG Host'
        })
    end
    
    TriggerClientEvent('ec_admin:host:controlResult', source, true, 'Broadcast sent to ' .. #cities .. ' cities', 'broadcast', 'send')
end)

-- Emergency shutdown all APIs
RegisterNetEvent('ec_admin:host:emergencyShutdownAll', function(reason)
    local source = source
    
    -- Verify permission (requires superadmin)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.emergency') then
        return
    end
    
    local apis = exports['ec_admin_ultimate']:GetAPIsStatus()
    
    for _, api in ipairs(apis) do
        exports['ec_admin_ultimate']:EmergencyStopAPI(source, api.name, reason)
    end
    
    TriggerClientEvent('ec_admin:host:controlResult', source, true, 'Emergency shutdown initiated for all APIs', 'all', 'emergency_shutdown')
end)

-- Restart all APIs
RegisterNetEvent('ec_admin:host:restartAllAPIs', function()
    local source = source
    
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.control') then
        return
    end
    
    local apis = exports['ec_admin_ultimate']:GetAPIsStatus()
    
    for _, api in ipairs(apis) do
        exports['ec_admin_ultimate']:RestartAPI(source, api.name)
    end
    
    TriggerClientEvent('ec_admin:host:controlResult', source, true, 'Restart initiated for all APIs', 'all', 'restart')
end)

-- Export city data
RegisterNetEvent('ec_admin:host:exportCityData', function(cityId, dataTypes)
    local source = source
    
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.export') then
        return
    end
    
    -- Call APIs to export data
    local exportData = {
        cityId = cityId,
        exportedAt = os.time(),
        dataTypes = dataTypes,
        data = {}
    }
    
    -- Collect data from various APIs based on dataTypes
    if table.contains(dataTypes, 'players') then
        -- Get player data from player-tracking API
        exportData.data.players = {}
    end
    
    if table.contains(dataTypes, 'bans') then
        -- Get ban data from global-bans API
        exportData.data.bans = {}
    end
    
    if table.contains(dataTypes, 'reports') then
        -- Get report data from report-system API
        exportData.data.reports = {}
    end
    
    if table.contains(dataTypes, 'analytics') then
        -- Get analytics data from analytics API
        exportData.data.analytics = {}
    end
    
    -- Send data back to client
    TriggerClientEvent('ec_admin:host:exportReady', source, exportData)
end)

-- Sync config to city
RegisterNetEvent('ec_admin:host:syncConfigToCity', function(cityId, configData)
    local source = source
    
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.config') then
        return
    end
    
    -- Send config via config-sync API
    exports['ec_admin_ultimate']:ExecuteCityCommand(source, cityId, 'sync_config', {
        config = configData,
        syncedBy = GetPlayerName(source)
    })
end)

-- Sync config to all cities
RegisterNetEvent('ec_admin:host:syncConfigToAll', function(configData)
    local source = source
    
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.config') then
        return
    end
    
    local cities = exports['ec_admin_ultimate']:GetConnectedCities()
    
    for _, city in ipairs(cities) do
        exports['ec_admin_ultimate']:ExecuteCityCommand(source, city.id, 'sync_config', {
            config = configData,
            syncedBy = GetPlayerName(source)
        })
    end
    
    TriggerClientEvent('ec_admin:host:controlResult', source, true, 'Config synced to ' .. #cities .. ' cities', 'config', 'sync')
end)

-- Apply global ban
RegisterNetEvent('ec_admin:host:applyGlobalBan', function(banData)
    local source = source
    
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.ban') then
        return
    end
    
    -- Send ban to global-bans API
    local endpoint = '/api/v1/bans/global'
    local data = {
        identifier = banData.identifier,
        playerName = banData.playerName,
        reason = banData.reason,
        bannedBy = GetPlayerName(source),
        duration = banData.duration,
        applyToAllCities = true
    }
    
    exports['ec_admin_ultimate']:CallHostAPI(endpoint, 'POST', data, function(success, response)
        if success then
            -- Notify all connected cities
            local cities = exports['ec_admin_ultimate']:GetConnectedCities()
            for _, city in ipairs(cities) do
                exports['ec_admin_ultimate']:ExecuteCityCommand(source, city.id, 'apply_ban', data)
            end
            
            TriggerClientEvent('ec_admin:host:controlResult', source, true, 'Global ban applied to all cities', 'ban', 'apply')
        else
            TriggerClientEvent('ec_admin:host:controlResult', source, false, 'Failed to apply global ban', 'ban', 'apply')
        end
    end)
end)

-- Remove global ban
RegisterNetEvent('ec_admin:host:removeGlobalBan', function(banId)
    local source = source
    
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.unban') then
        return
    end
    
    -- Remove ban from global-bans API
    local endpoint = '/api/v1/bans/global/' .. banId
    
    exports['ec_admin_ultimate']:CallHostAPI(endpoint, 'DELETE', nil, function(success, response)
        if success then
            -- Notify all connected cities
            local cities = exports['ec_admin_ultimate']:GetConnectedCities()
            for _, city in ipairs(cities) do
                exports['ec_admin_ultimate']:ExecuteCityCommand(source, city.id, 'remove_ban', {banId = banId})
            end
            
            TriggerClientEvent('ec_admin:host:controlResult', source, true, 'Global ban removed from all cities', 'ban', 'remove')
        else
            TriggerClientEvent('ec_admin:host:controlResult', source, false, 'Failed to remove global ban', 'ban', 'remove')
        end
    end)
end)

-- Backup city data
RegisterNetEvent('ec_admin:host:backupCityData', function(cityId)
    local source = source
    
    -- Verify permission
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.backup') then
        return
    end
    
    -- Trigger backup via backup-storage API
    local endpoint = '/api/v1/backup/city/' .. cityId
    local data = {
        requestedBy = GetPlayerName(source),
        timestamp = os.time()
    }
    
    exports['ec_admin_ultimate']:CallHostAPI(endpoint, 'POST', data, function(success, response)
        if success then
            TriggerClientEvent('ec_admin:host:controlResult', source, true, 'Backup initiated for ' .. cityId, 'backup', 'create')
        else
            TriggerClientEvent('ec_admin:host:controlResult', source, false, 'Failed to initiate backup', 'backup', 'create')
        end
    end)
end)

-- Restore city data
RegisterNetEvent('ec_admin:host:restoreCityData', function(cityId, backupId)
    local source = source
    
    -- Verify permission (requires superadmin)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.restore') then
        return
    end
    
    -- Restore from backup via backup-storage API
    local endpoint = '/api/v1/backup/restore/' .. cityId .. '/' .. backupId
    local data = {
        requestedBy = GetPlayerName(source),
        timestamp = os.time()
    }
    
    exports['ec_admin_ultimate']:CallHostAPI(endpoint, 'POST', data, function(success, response)
        if success then
            TriggerClientEvent('ec_admin:host:controlResult', source, true, 'Restore initiated for ' .. cityId, 'backup', 'restore')
        else
            TriggerClientEvent('ec_admin:host:controlResult', source, false, 'Failed to initiate restore', 'backup', 'restore')
        end
    end)
end)

-- Helper function to check if table contains value
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

Logger.Info('🏢 Host Control actions registered')
