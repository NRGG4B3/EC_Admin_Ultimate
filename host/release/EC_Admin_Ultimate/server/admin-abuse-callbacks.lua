--[[
    EC Admin Ultimate - Admin Abuse Tracking Callbacks
    Logs all admin actions for abuse detection
]]

Logger.Info('👁️ Loading admin abuse tracking callbacks...')

-- Global action log storage
_G.AdminActionLog = _G.AdminActionLog or {}

-- ============================================================================
-- CALLBACK: GET ADMIN ABUSE DATA
-- ============================================================================

lib.callback.register('ec_admin:getAdminAbuse', function(source, data)
    local logs = {}
    local stats = {
        totalActions = 0,
        todayActions = 0,
        adminStats = {},
        actionTypes = {},
        suspiciousActivity = 0
    }
    
    -- Get from database
    if MySQL then
        local result = MySQL.query.await('SELECT * FROM ec_admin_action_logs ORDER BY timestamp DESC LIMIT 500', {})
        if result then
            local todayStart = os.time() - (24 * 60 * 60)
            
            for _, log in ipairs(result) do
                table.insert(logs, {
                    id = log.id,
                    adminName = log.admin_name or 'Unknown',
                    adminIdentifier = log.admin_identifier,
                    action = log.action_type or 'unknown',
                    target = log.target_name or 'N/A',
                    targetIdentifier = log.target_identifier,
                    details = log.details or '',
                    timestamp = log.timestamp or os.time(),
                    date = os.date('%Y-%m-%d %H:%M:%S', log.timestamp or os.time()),
                    suspicious = log.suspicious == 1
                })
                
                stats.totalActions = stats.totalActions + 1
                
                if log.timestamp >= todayStart then
                    stats.todayActions = stats.todayActions + 1
                end
                
                -- Admin stats
                local adminName = log.admin_name or 'Unknown'
                stats.adminStats[adminName] = (stats.adminStats[adminName] or 0) + 1
                
                -- Action type stats
                local actionType = log.action_type or 'unknown'
                stats.actionTypes[actionType] = (stats.actionTypes[actionType] or 0) + 1
                
                if log.suspicious == 1 then
                    stats.suspiciousActivity = stats.suspiciousActivity + 1
                end
            end
        end
    else
        -- Use in-memory logs
        logs = _G.AdminActionLog
        stats.totalActions = #logs
    end
    
    return {
        success = true,
        logs = logs,
        stats = stats,
        total = #logs
    }
end)

-- ============================================================================
-- LOG ADMIN ACTION
-- ============================================================================

function LogAdminAction(adminSource, actionType, targetIdentifier, targetName, details)
    local adminName = GetPlayerName(adminSource) or 'System'
    local adminIdentifiers = GetPlayerIdentifiers(adminSource)
    local adminIdentifier = adminIdentifiers and adminIdentifiers[1] or 'unknown'
    
    -- Detect suspicious patterns
    local suspicious = false
    
    -- Flag if admin is targeting themselves
    if adminIdentifier == targetIdentifier then
        suspicious = true
    end
    
    -- Flag if excessive money actions
    if string.find(string.lower(actionType), 'money') and string.find(string.lower(details or ''), '1000000') then
        suspicious = true
    end
    
    local log = {
        id = #_G.AdminActionLog + 1,
        adminName = adminName,
        adminIdentifier = adminIdentifier,
        action = actionType,
        target = targetName or 'N/A',
        targetIdentifier = targetIdentifier or 'N/A',
        details = details or '',
        timestamp = os.time(),
        date = os.date('%Y-%m-%d %H:%M:%S'),
        suspicious = suspicious
    }
    
    table.insert(_G.AdminActionLog, log)
    
    -- Store in database
    if MySQL then
        MySQL.insert('INSERT INTO ec_admin_action_logs (admin_name, admin_identifier, action_type, target_name, target_identifier, details, timestamp, suspicious) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            adminName,
            adminIdentifier,
            actionType,
            targetName,
            targetIdentifier,
            details,
            os.time(),
            suspicious and 1 or 0
        })
    end
    
    if suspicious then
        Logger.Info(string.format('', actionType, adminName, details))
    else
        Logger.Info(string.format('', actionType, adminName))
    end
    
    return log
end

exports('LogAdminAction', LogAdminAction)

-- ============================================================================
-- HOOK INTO ADMIN ACTIONS (Auto-logging)
-- ============================================================================

-- Hook into money actions
RegisterNetEvent('ec_admin:giveMoney', function(data)
    local source = source
    LogAdminAction(source, 'give_money', data.playerId, GetPlayerName(data.playerId), 
        string.format('Gave $%d (%s) to %s', data.amount or 0, data.moneyType or 'cash', GetPlayerName(data.playerId) or 'Unknown'))
end)

RegisterNetEvent('ec_admin:removeMoney', function(data)
    local source = source
    LogAdminAction(source, 'remove_money', data.playerId, GetPlayerName(data.playerId), 
        string.format('Removed $%d (%s) from %s', data.amount or 0, data.moneyType or 'cash', GetPlayerName(data.playerId) or 'Unknown'))
end)

-- Hook into ban actions
RegisterNetEvent('ec_admin:createBan', function(data)
    local source = source
    LogAdminAction(source, 'ban_player', data.identifier, data.playerName, 
        string.format('Banned %s - Reason: %s', data.playerName or 'Unknown', data.reason or 'No reason'))
end)

-- Hook into vehicle spawns
RegisterNetEvent('ec_admin:spawnVehicle', function(data)
    local source = source
    LogAdminAction(source, 'spawn_vehicle', source, GetPlayerName(source), 
        string.format('Spawned vehicle: %s', data.model or 'Unknown'))
end)

Logger.Info('✅ Admin abuse tracking callbacks loaded')
Logger.Info('👁️ All admin actions will be logged and monitored')
