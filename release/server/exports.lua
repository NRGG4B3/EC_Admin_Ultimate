-- EC Admin Ultimate - Exports System
-- Allows other resources to interact with EC Admin Ultimate
-- Version: 1.0.0

Logger.Info('Loading exports system...')

-- ============================================================================
-- PERMISSION EXPORTS
-- ============================================================================

---Check if a player has admin permission
---@param source number Player server ID
---@return boolean
exports('HasAdminPermission', function(source)
    return IsPlayerAceAllowed(source, 'admin.access')
end)

---Check if a player has a specific permission level
---@param source number Player server ID
---@param level string Permission level (user, moderator, admin, superadmin)
---@return boolean
exports('HasPermissionLevel', function(source, level)
    if IsPlayerAceAllowed(source, 'admin.superadmin') then return true end
    if level == 'admin' and IsPlayerAceAllowed(source, 'admin.access') then return true end
    if level == 'moderator' and IsPlayerAceAllowed(source, 'moderator.access') then return true end
    return false
end)

---Get a player's permission level
---@param source number Player server ID
---@return string Permission level
exports('GetPlayerPermissionLevel', function(source)
    if IsPlayerAceAllowed(source, 'admin.superadmin') then
        return 'superadmin'
    elseif IsPlayerAceAllowed(source, 'admin.access') then
        return 'admin'
    elseif IsPlayerAceAllowed(source, 'moderator.access') then
        return 'moderator'
    else
        return 'user'
    end
end)

-- ============================================================================
-- PLAYER MANAGEMENT EXPORTS
-- ============================================================================

---Get online players data
---@return table Array of player data
exports('GetOnlinePlayers', function()
    local players = {}
    for _, playerId in pairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        local coords = ped and GetEntityCoords(ped) or vector3(0, 0, 0)
        
        table.insert(players, {
            id = tonumber(playerId),
            name = GetPlayerName(playerId) or 'Unknown',
            ping = GetPlayerPing(playerId),
            coords = { x = coords.x, y = coords.y, z = coords.z },
            identifiers = GetPlayerIdentifiers(playerId)
        })
    end
    return players
end)

---Get player count
---@return number Player count
exports('GetPlayerCount', function()
    return #GetPlayers()
end)

---Get max players
---@return number Max players
exports('GetMaxPlayers', function()
    return GetConvarInt('sv_maxclients', 32)
end)

-- ============================================================================
-- BAN SYSTEM EXPORTS
-- ============================================================================

---Ban a player
---@param identifier string Player identifier (license:xxx)
---@param reason string Ban reason
---@param duration number Ban duration in seconds (0 = permanent)
---@param adminSource number Admin source who issued the ban
---@return boolean success
exports('BanPlayer', function(identifier, reason, duration, adminSource)
    if not identifier or not reason then return false end
    
    local expiresAt = duration > 0 and (os.time() + duration) or 0
    local adminName = adminSource and GetPlayerName(adminSource) or 'System'
    
    if _G.ECDatabase then
        local data = {
            identifier = identifier,
            player_name = 'Unknown',
            reason = reason,
            banned_by = adminSource and GetPlayerIdentifiers(adminSource)[1] or 'system',
            banned_by_name = adminName,
            ban_date = os.date('%Y-%m-%d %H:%M:%S'),
            expires = expiresAt,
            active = 1,
            server_id = 1
        }
        
        _G.ECDatabase.Insert('ec_admin_bans', data, function(success)
            if success then
                Logger.Info(string.format('', identifier))
                
                -- Kick player if online
                for _, playerId in ipairs(GetPlayers()) do
                    local playerIdentifiers = GetPlayerIdentifiers(playerId)
                    for _, id in pairs(playerIdentifiers) do
                        if id == identifier then
                            DropPlayer(playerId, 'Banned: ' .. reason)
                            break
                        end
                    end
                end
            end
        end)
        
        return true
    end
    
    return false
end)

---Unban a player
---@param identifier string Player identifier
---@return boolean success
exports('UnbanPlayer', function(identifier)
    if not identifier then return false end
    
    if _G.ECDatabase then
        _G.ECDatabase.Update('ec_admin_bans', { active = 0 }, 'identifier = \"' .. identifier .. '\"', function(success)
            if success then
                Logger.Info(string.format('', identifier))
            end
        end)
        return true
    end
    
    return false
end)

---Check if a player is banned
---@param identifier string Player identifier
---@param callback function Callback with result
exports('IsPlayerBanned', function(identifier, callback)
    if not identifier or not callback then return end
    
    if _G.ECDatabase then
        -- Use pcall to handle missing columns gracefully
        local success, result = pcall(function()
            return _G.ECDatabase.Query(
                'SELECT * FROM ec_admin_bans WHERE identifier = ? AND is_active = 1 AND (expires IS NULL OR expires = 0 OR expires > UNIX_TIMESTAMP()) LIMIT 1',
                {identifier}
            )
        end)
        
        if success and result and result[1] then
            callback(true, result[1])
        else
            callback(false, nil)
        end
    else
        callback(false, nil)
    end
end)

-- ============================================================================
-- LOGGING EXPORTS
-- ============================================================================

---Log an admin action
---@param adminSource number Admin source
---@param action string Action name
---@param targetIdentifier string|nil Target identifier
---@param details string|nil Action details
exports('LogAdminAction', function(adminSource, action, targetIdentifier, details)
    if not adminSource or not action then return end
    
    local adminIdentifier = GetPlayerIdentifiers(adminSource)[1] or 'system'
    local adminName = GetPlayerName(adminSource) or 'System'
    
    if _G.ECDatabase then
        _G.ECDatabase.LogAdminAction(
            adminIdentifier,
            adminName,
            action,
            targetIdentifier,
            '',
            details,
            function(success)
                if success then
                    Logger.Info(string.format('', action, adminName))
                end
            end
        )
    end
end)

-- ============================================================================
-- SERVER METRICS EXPORTS
-- ============================================================================

---Get current server metrics
---@return table Server metrics
exports('GetServerMetrics', function()
    local players = GetPlayers()
    return {
        playersOnline = #players,
        maxPlayers = GetConvarInt('sv_maxclients', 32),
        serverTPS = GetServerTPS and GetServerTPS() or 60,
        memoryUsage = collectgarbage('count') / 1024,
        uptime = os.time() - (ServerStartTime or os.time())
    }
end)

---Get server uptime
---@return number Uptime in seconds
exports('GetServerUptime', function()
    return os.time() - (ServerStartTime or os.time())
end)

---Get server TPS
---@return number Current TPS
exports('GetServerTPS', function()
    if GetServerTPS then
        return GetServerTPS()
    end
    return 60
end)

-- ============================================================================
-- VEHICLE EXPORTS
-- ============================================================================

---Get all cached vehicles
---@return table Array of vehicle data
exports('GetCachedVehicles', function()
    if _G.CachedVehicles then
        return _G.CachedVehicles
    end
    return {}
end)

---Get cached vehicle count
---@return number Vehicle count
exports('GetCachedVehicleCount', function()
    if _G.CachedVehicles then
        return #_G.CachedVehicles
    end
    return 0
end)

-- ============================================================================
-- FRAMEWORK DETECTION EXPORTS
-- ============================================================================

---Get the detected framework
---@return string|nil Framework name (qbx, qb, esx) or nil
exports('GetFramework', function()
    if GetResourceState('qbx_core') == 'started' then
        return 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        return 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx'
    end
    return nil
end)

---Check if a framework is detected
---@return boolean Has framework
exports('HasFramework', function()
    local frameworks = {'qbx_core', 'qb-core', 'es_extended'}
    for _, framework in ipairs(frameworks) do
        if GetResourceState(framework) == 'started' then
            return true
        end
    end
    return false
end)

-- ============================================================================
-- NOTIFICATION EXPORTS
-- ============================================================================

---Send a notification to a player
---@param source number Player source
---@param message string Notification message
---@param type string Notification type (success, error, info, warning)
exports('NotifyPlayer', function(source, message, type)
    if not source or not message then return end
    TriggerClientEvent('ec_admin:notify', source, message, type or 'info')
end)

---Send a notification to all players
---@param message string Notification message
---@param type string Notification type
exports('NotifyAll', function(message, type)
    if not message then return end
    TriggerClientEvent('ec_admin:notify', -1, message, type or 'info')
end)

---Send a notification to all admins
---@param message string Notification message
---@param type string Notification type
exports('NotifyAdmins', function(message, type)
    if not message then return end
    
    for _, playerId in pairs(GetPlayers()) do
        if IsPlayerAceAllowed(tonumber(playerId), 'admin.access') then
            TriggerClientEvent('ec_admin:notify', tonumber(playerId), message, type or 'info')
        end
    end
end)

-- ============================================================================
-- DATABASE EXPORTS
-- ============================================================================

---Execute a database query
---@param query string SQL query
---@param parameters table Query parameters
---@param callback function Callback function
exports('DatabaseQuery', function(query, parameters, callback)
    if _G.ECDatabase then
        return _G.ECDatabase.Query(query, parameters, callback)
    end
    if callback then callback(false, 'Database not ready') end
    return false
end)

---Get database query statistics
---@return table Query stats
exports('GetQueryStats', function()
    if _G.ECDatabase then
        return exports['ec_admin_ultimate']:GetQueryStats()
    end
    return {
        total = 0,
        avgTime = 0,
        failed = 0,
        samples = 0
    }
end)

-- ============================================================================
-- UTILITY EXPORTS
-- ============================================================================

---Get player identifier
---@param source number Player source
---@param idType string|nil Identifier type (license, steam, discord, etc)
---@return string|nil Identifier
exports('GetPlayerIdentifier', function(source, idType)
    if not source then return nil end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    if idType then
        for _, id in pairs(identifiers) do
            if string.match(id, idType .. ':') then
                return id
            end
        end
        return nil
    else
        -- Return first identifier (usually license)
        return identifiers[1]
    end
end)

---Get all player identifiers
---@param source number Player source
---@return table Identifiers
exports('GetPlayerIdentifiers', function(source)
    if not source then return {} end
    return GetPlayerIdentifiers(source) or {}
end)

---Format duration to human readable
---@param seconds number Duration in seconds
---@return string Formatted duration
exports('FormatDuration', function(seconds)
    if not seconds or seconds <= 0 then return 'Permanent' end
    
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    if days > 0 then
        return string.format('%d day%s', days, days > 1 and 's' or '')
    elseif hours > 0 then
        return string.format('%d hour%s', hours, hours > 1 and 's' or '')
    elseif minutes > 0 then
        return string.format('%d minute%s', minutes, minutes > 1 and 's' or '')
    else
        return string.format('%d second%s', seconds, seconds > 1 and 's' or '')
    end
end)

Logger.Info('Exports system loaded successfully')
Logger.Info('Available exports: 30+ functions')