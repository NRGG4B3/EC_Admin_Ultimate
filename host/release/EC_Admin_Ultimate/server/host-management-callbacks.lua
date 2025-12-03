-- EC Admin Ultimate - Host Management Callbacks
-- All lib.callback.register for host management features
-- Author: NRG Development
-- Version: 1.0.0

-- Check if user is NRG staff
lib.callback.register('ec_admin:host:checkNRGStaff', function(source)
    local isStaff, method = exports['ec_admin_ultimate']:IsNRGStaff(source)
    
    return {
        isStaff = isStaff,
        method = method
    }
end)

-- Get global bans
lib.callback.register('ec_admin:host:getGlobalBans', function(source, filters)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetGlobalBans(filters)
end)

-- Get ban appeals
lib.callback.register('ec_admin:host:getBanAppeals', function(source, filters)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetBanAppeals(filters)
end)

-- Get ban appeal details
lib.callback.register('ec_admin:host:getBanAppealDetails', function(source, appealId)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    local appeal = MySQL.single.await([[
        SELECT ba.*, gb.identifier, gb.player_name, gb.reason as ban_reason, 
               gb.banned_by, gb.banned_at, gb.expires_at, gb.is_permanent
        FROM ec_host_ban_appeals ba
        LEFT JOIN ec_host_global_bans gb ON ba.ban_id = gb.id
        WHERE ba.id = ?
    ]], {appealId})
    
    return appeal
end)

-- Get webhooks
lib.callback.register('ec_admin:host:getWebhooks', function(source)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.webhooks') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetHostWebhooks()
end)

-- Get webhook logs
lib.callback.register('ec_admin:host:getWebhookLogs', function(source, filters)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.webhooks') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetWebhookLogs(filters)
end)

-- Get webhook statistics
lib.callback.register('ec_admin:host:getWebhookStats', function(source, webhookId, timeRange)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.webhooks') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetWebhookStats(webhookId, timeRange)
end)

-- Get webhook event types
lib.callback.register('ec_admin:host:getWebhookEventTypes', function(source)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.webhooks') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetWebhookEventTypes()
end)

-- Get global warnings
lib.callback.register('ec_admin:host:getGlobalWarnings', function(source, filters)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    local query = 'SELECT * FROM ec_host_global_warnings WHERE 1=1'
    local params = {}
    
    if filters then
        if filters.identifier then
            query = query .. ' AND identifier LIKE ?'
            table.insert(params, '%' .. filters.identifier .. '%')
        end
        
        if filters.active ~= nil then
            query = query .. ' AND active = ?'
            table.insert(params, filters.active and 1 or 0)
        end
    end
    
    query = query .. ' ORDER BY issued_at DESC LIMIT 100'
    
    return MySQL.query.await(query, params) or {}
end)

-- Get host action logs
lib.callback.register('ec_admin:host:getActionLogs', function(source, filters)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    local query = 'SELECT * FROM ec_host_actions WHERE 1=1'
    local params = {}
    
    if filters then
        if filters.actionType then
            query = query .. ' AND action_type = ?'
            table.insert(params, filters.actionType)
        end
        
        if filters.adminId then
            query = query .. ' AND admin_id = ?'
            table.insert(params, filters.adminId)
        end
        
        if filters.startTime then
            query = query .. ' AND timestamp >= ?'
            table.insert(params, filters.startTime)
        end
    end
    
    query = query .. ' ORDER BY timestamp DESC LIMIT 500'
    
    return MySQL.query.await(query, params) or {}
end)

-- Get host dashboard stats
lib.callback.register('ec_admin:host:getDashboardStats', function(source)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    local stats = {}
    
    -- Global bans
    stats.totalBans = MySQL.scalar.await('SELECT COUNT(*) FROM ec_host_global_bans WHERE active = 1') or 0
    stats.totalBansPermanent = MySQL.scalar.await('SELECT COUNT(*) FROM ec_host_global_bans WHERE active = 1 AND is_permanent = 1') or 0
    
    -- Ban appeals
    stats.pendingAppeals = MySQL.scalar.await('SELECT COUNT(*) FROM ec_host_ban_appeals WHERE status = "pending"') or 0
    stats.totalAppeals = MySQL.scalar.await('SELECT COUNT(*) FROM ec_host_ban_appeals') or 0
    
    -- Warnings
    stats.totalWarnings = MySQL.scalar.await('SELECT COUNT(*) FROM ec_host_global_warnings WHERE active = 1') or 0
    
    -- Webhooks
    stats.totalWebhooks = MySQL.scalar.await('SELECT COUNT(*) FROM ec_host_webhooks WHERE enabled = 1') or 0
    stats.webhookExecutions24h = MySQL.scalar.await([[
        SELECT COUNT(*) FROM ec_host_webhook_logs 
        WHERE timestamp >= ?
    ]], {os.time() - 86400}) or 0
    
    -- Actions
    stats.actionsToday = MySQL.scalar.await([[
        SELECT COUNT(*) FROM ec_host_actions 
        WHERE timestamp >= ?
    ]], {os.time() - 86400}) or 0
    
    -- Cities
    stats.totalCities = MySQL.scalar.await('SELECT COUNT(*) FROM ec_host_cities') or 0
    stats.onlineCities = MySQL.scalar.await('SELECT COUNT(*) FROM ec_host_cities WHERE status = "online"') or 0
    
    -- Recent actions
    stats.recentActions = MySQL.query.await([[
        SELECT * FROM ec_host_actions 
        ORDER BY timestamp DESC 
        LIMIT 10
    ]]) or {}
    
    -- Active alerts
    stats.activeAlerts = MySQL.query.await([[
        SELECT * FROM ec_host_alerts 
        WHERE acknowledged = 0 
        ORDER BY timestamp DESC 
        LIMIT 10
    ]]) or {}
    
    return stats
end)

-- Get NRG staff list
lib.callback.register('ec_admin:host:getNRGStaffList', function(source)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.manage_staff') then
        return nil
    end
    
    return exports['ec_admin_ultimate']:GetNRGStaffList()
end)

-- Get city ban status
lib.callback.register('ec_admin:host:getCityBanStatus', function(source, identifier)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    -- Get global ban
    local globalBan = MySQL.single.await([[
        SELECT * FROM ec_host_global_bans 
        WHERE identifier = ? AND active = 1
    ]], {identifier})
    
    -- Get cities where ban is applied
    local citiesBanned = {}
    if globalBan and globalBan.applied_cities then
        local ok, cities = pcall(json.decode, globalBan.applied_cities)
        if ok then
            citiesBanned = cities
        end
    end
    
    return {
        isBanned = globalBan ~= nil,
        ban = globalBan,
        citiesBanned = citiesBanned,
        canAppeal = globalBan and not globalBan.is_permanent
    }
end)

-- Get player global history
lib.callback.register('ec_admin:host:getPlayerGlobalHistory', function(source, identifier)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    local history = {}
    
    -- Bans
    history.bans = MySQL.query.await([[
        SELECT * FROM ec_host_global_bans 
        WHERE identifier = ? 
        ORDER BY banned_at DESC
    ]], {identifier}) or {}
    
    -- Warnings
    history.warnings = MySQL.query.await([[
        SELECT * FROM ec_host_global_warnings 
        WHERE identifier = ? 
        ORDER BY issued_at DESC
    ]], {identifier}) or {}
    
    -- Appeals
    history.appeals = MySQL.query.await([[
        SELECT ba.* FROM ec_host_ban_appeals ba
        JOIN ec_host_global_bans gb ON ba.ban_id = gb.id
        WHERE gb.identifier = ?
        ORDER BY ba.submitted_at DESC
    ]], {identifier}) or {}
    
    return history
end)

-- Search global players
lib.callback.register('ec_admin:host:searchGlobalPlayers', function(source, searchTerm)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return nil
    end
    
    -- This would search across all connected cities
    -- For now, return from global bans and warnings
    local players = {}
    
    local bans = MySQL.query.await([[
        SELECT DISTINCT identifier, player_name 
        FROM ec_host_global_bans 
        WHERE identifier LIKE ? OR player_name LIKE ?
        LIMIT 50
    ]], {'%' .. searchTerm .. '%', '%' .. searchTerm .. '%'}) or {}
    
    for _, ban in ipairs(bans) do
        table.insert(players, {
            identifier = ban.identifier,
            playerName = ban.player_name,
            source = 'global_bans'
        })
    end
    
    return players
end)

Logger.Info('🏢 Host Management callbacks registered')
