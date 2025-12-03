--[[
    EC Admin Ultimate - Host Management NUI Callbacks (Client)
    All RegisterNUICallback for host management features
    Author: NRG Development
    Version: 1.0.0
]]

Logger.Info('Loading Host Management NUI callbacks...')

local function respond(cb, payload)
    if type(payload) == 'table' then
        if payload.success == nil and payload[1] == nil then
            payload.success = true
        end
        cb(payload)
    else
        cb({ success = true, data = payload })
    end
end

-- ==========================================
-- DASHBOARD STATS
-- ==========================================

RegisterNUICallback('getHostDashboardStats', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getDashboardStats', false)
    respond(cb, result or {
        totalBans = 0,
        totalBansPermanent = 0,
        pendingAppeals = 0,
        totalAppeals = 0,
        totalWarnings = 0,
        totalWebhooks = 0,
        webhookExecutions24h = 0,
        actionsToday = 0,
        totalCities = 0,
        onlineCities = 0,
        recentActions = {},
        activeAlerts = {}
    })
end)

-- Host System Stats (normalized for HostDashboard UI)
-- Maps to server-side aggregate stats and converts to UI's HostStats shape
RegisterNUICallback('getHostSystemStats', function(data, cb)
    local stats = lib.callback.await('ec_admin:host:getDashboardStats', false) or {}

    local payload = {
        total_apis = stats.totalAPIs or (stats.onlineAPIs or 0) + (stats.offlineAPIs or 0) + (stats.degradedAPIs or 0),
        online_apis = stats.onlineAPIs or 0,
        degraded_apis = stats.degradedAPIs or 0,
        offline_apis = stats.offlineAPIs or 0,
        system_health = stats.systemHealth or 0,

        total_cities = stats.totalCities or 0,
        online_cities = stats.onlineCities or 0,
        ec_admin_cities = stats.ecAdminCities or 0,
        customer_cities = stats.customerCities or 0,
        total_players_online = stats.totalPlayers or 0,

        total_requests_today = stats.totalRequestsToday or stats.actionsToday or 0,
        total_requests_all_time = stats.totalRequestsAllTime or 0,
        avg_response_time = stats.avgResponseTime or 0,
        total_errors_today = stats.totalErrorsToday or 0,
        avg_uptime = stats.avgUptime or 0,

        total_bans = stats.totalBans or 0,
        bans_today = stats.bansToday or 0,
        pending_appeals = stats.pendingAppeals or 0,
        total_warnings = stats.totalWarnings or 0,
        warnings_today = stats.warningsToday or 0,

        total_memory_usage = stats.totalMemoryUsage or 0,
        total_cpu_usage = stats.totalCPUUsage or 0,
        database_size = stats.databaseSize or 0,

        total_webhooks = stats.totalWebhooks or 0,
        active_webhooks = stats.activeWebhooks or stats.totalWebhooks or 0,
        webhook_executions_today = stats.webhookExecutions24h or 0,

        critical_alerts = stats.criticalAlerts or (stats.activeAlerts and #stats.activeAlerts or 0),
        warnings_system = stats.warningsSystem or 0,
        recent_alerts = stats.activeAlerts or {}
    }

    respond(cb, payload)
end)

-- ==========================================
-- GLOBAL BANS
-- ==========================================

RegisterNUICallback('getGlobalBans', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getGlobalBans', false, data.filters or {})
    respond(cb, result or {})
end)

RegisterNUICallback('applyGlobalBan', function(data, cb)
    TriggerServerEvent('ec_admin:host:applyGlobalBan', data)
    cb({ success = true })
end)

RegisterNUICallback('removeGlobalBan', function(data, cb)
    TriggerServerEvent('ec_admin:host:removeGlobalBan', data)
    cb({ success = true })
end)

RegisterNUICallback('getCityBanStatus', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getCityBanStatus', false, data.identifier)
    respond(cb, result or { isBanned = false, citiesBanned = {} })
end)

-- ==========================================
-- BAN APPEALS
-- ==========================================

RegisterNUICallback('getBanAppeals', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getBanAppeals', false, data.filters or {})
    respond(cb, result or {})
end)

RegisterNUICallback('getBanAppealDetails', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getBanAppealDetails', false, data.appealId)
    respond(cb, result or {})
end)

RegisterNUICallback('processBanAppeal', function(data, cb)
    TriggerServerEvent('ec_admin:host:processBanAppeal', data)
    cb({ success = true })
end)

-- ==========================================
-- GLOBAL WARNINGS
-- ==========================================

RegisterNUICallback('getGlobalWarnings', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getGlobalWarnings', false, data.filters or {})
    respond(cb, result or {})
end)

RegisterNUICallback('issueGlobalWarning', function(data, cb)
    TriggerServerEvent('ec_admin:host:issueGlobalWarning', data)
    cb({ success = true })
end)

RegisterNUICallback('removeGlobalWarning', function(data, cb)
    TriggerServerEvent('ec_admin:host:removeGlobalWarning', data)
    cb({ success = true })
end)

-- ==========================================
-- WEBHOOKS
-- ==========================================

RegisterNUICallback('getHostWebhooks', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getWebhooks', false)
    respond(cb, result or {})
end)

RegisterNUICallback('getWebhookEventTypes', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getWebhookEventTypes', false)
    respond(cb, result or {})
end)

RegisterNUICallback('addHostWebhook', function(data, cb)
    TriggerServerEvent('ec_admin:host:addWebhook', data)
    cb({ success = true })
end)

RegisterNUICallback('createHostWebhook', function(data, cb)
    TriggerServerEvent('ec_admin:host:addWebhook', data)
    cb({ success = true })
end)

RegisterNUICallback('updateHostWebhook', function(data, cb)
    TriggerServerEvent('ec_admin:host:updateWebhook', data)
    cb({ success = true })
end)

RegisterNUICallback('deleteHostWebhook', function(data, cb)
    TriggerServerEvent('ec_admin:host:deleteWebhook', data)
    cb({ success = true })
end)

RegisterNUICallback('testHostWebhook', function(data, cb)
    TriggerServerEvent('ec_admin:host:testWebhook', data)
    cb({ success = true })
end)

RegisterNUICallback('toggleHostWebhook', function(data, cb)
    TriggerServerEvent('ec_admin:host:toggleWebhook', data)
    cb({ success = true })
end)

RegisterNUICallback('getWebhookLogs', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getWebhookLogs', false, data.filters or {})
    respond(cb, result or {})
end)

RegisterNUICallback('getWebhookStats', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getWebhookStats', false, data.webhookId, data.timeRange or '24h')
    respond(cb, result or {})
end)

-- ==========================================
-- ACTION LOGS
-- ==========================================

RegisterNUICallback('getHostActionLogs', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getActionLogs', false, data.filters or {})
    respond(cb, result or {})
end)

-- System Logs for Host Dashboard (maps to host action logs for now)
RegisterNUICallback('getSystemLogs', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getActionLogs', false, data.filters or {})
    -- Normalize to SystemLog shape expected by UI
    local logs = {}
    for _, entry in ipairs(result or {}) do
        table.insert(logs, {
            id = entry.id or 0,
            log_type = 'info',
            source = entry.city_name or 'host',
            message = entry.action_type or 'action',
            details = entry.details or '',
            timestamp = entry.timestamp or os.time(),
            resolved = false
        })
    end
    respond(cb, logs)
end)

-- ==========================================
-- NRG STAFF MANAGEMENT
-- ==========================================

RegisterNUICallback('getNRGStaffList', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getNRGStaffList', false)
    respond(cb, result or {})
end)

RegisterNUICallback('addNRGStaff', function(data, cb)
    TriggerServerEvent('ec_admin:host:addNRGStaff', data)
    cb({ success = true })
end)

RegisterNUICallback('removeNRGStaff', function(data, cb)
    TriggerServerEvent('ec_admin:host:removeNRGStaff', data)
    cb({ success = true })
end)

RegisterNUICallback('updateNRGStaffPermissions', function(data, cb)
    TriggerServerEvent('ec_admin:host:updateNRGStaffPermissions', data)
    cb({ success = true })
end)

RegisterNUICallback('getNRGStaffActivity', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getStaffActivity', false, data.filters or {})
    respond(cb, result or {})
end)

-- ==========================================
-- PLAYER TRACKING
-- ==========================================

RegisterNUICallback('searchGlobalPlayers', function(data, cb)
    local result = lib.callback.await('ec_admin:host:searchGlobalPlayers', false, data.searchTerm or '')
    respond(cb, result or {})
end)

RegisterNUICallback('getPlayerGlobalHistory', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getPlayerGlobalHistory', false, data.identifier)
    respond(cb, result or { bans = {}, warnings = {}, appeals = {} })
end)

RegisterNUICallback('getPlayerCrossCityData', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getPlayerCrossCityData', false, data.identifier)
    respond(cb, result or {})
end)

-- ==========================================
-- PLAYER NOTES
-- ==========================================

RegisterNUICallback('getPlayerNotes', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getPlayerNotes', false, data.identifier)
    respond(cb, result or {})
end)

RegisterNUICallback('addPlayerNote', function(data, cb)
    TriggerServerEvent('ec_admin:host:addPlayerNote', data)
    cb({ success = true })
end)

RegisterNUICallback('deletePlayerNote', function(data, cb)
    TriggerServerEvent('ec_admin:host:deletePlayerNote', data)
    cb({ success = true })
end)

-- ==========================================
-- GLOBAL BLACKLIST
-- ==========================================

RegisterNUICallback('getGlobalBlacklist', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getGlobalBlacklist', false, data.filters or {})
    respond(cb, result or {})
end)

RegisterNUICallback('addBlacklistEntry', function(data, cb)
    TriggerServerEvent('ec_admin:host:addBlacklistEntry', data)
    cb({ success = true })
end)

RegisterNUICallback('removeBlacklistEntry', function(data, cb)
    TriggerServerEvent('ec_admin:host:removeBlacklistEntry', data)
    cb({ success = true })
end)

-- ==========================================
-- NOTIFICATIONS
-- ==========================================

RegisterNUICallback('getHostNotifications', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getNotifications', false)
    respond(cb, result or {})
end)

RegisterNUICallback('markNotificationRead', function(data, cb)
    TriggerServerEvent('ec_admin:host:markNotificationRead', data)
    cb({ success = true })
end)

RegisterNUICallback('dismissNotification', function(data, cb)
    TriggerServerEvent('ec_admin:host:dismissNotification', data)
    cb({ success = true })
end)

-- ==========================================
-- CITIES MANAGEMENT
-- ==========================================

RegisterNUICallback('getConnectedCities', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getConnectedCities', false)
    respond(cb, result or {})
end)

RegisterNUICallback('getCityDetails', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getCityDetails', false, data.cityId)
    respond(cb, result or {})
end)

RegisterNUICallback('disconnectCity', function(data, cb)
    TriggerServerEvent('ec_admin:host:executeCityCommand', { cityId = data.cityId, command = 'disconnect' })
    cb({ success = true })
end)

-- ==========================================
-- ANALYTICS & REPORTS
-- ==========================================

RegisterNUICallback('getHostAnalytics', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getAnalytics', false, data.timeRange or '24h')
    respond(cb, result or {})
end)

-- Sales Projections for Host Dashboard (derive from analytics)
RegisterNUICallback('getSalesProjections', function(data, cb)
    local analytics = lib.callback.await('ec_admin:host:getAnalytics', false, '6mo') or {}
    local projections = {}
    -- Expect analytics.monthly if available
    local monthly = analytics.monthly or analytics
    if type(monthly) == 'table' then
        for _, m in ipairs(monthly) do
            table.insert(projections, {
                month = m.month or 'N/A',
                projected_revenue = m.revenue or 0,
                projected_customers = m.customers or 0,
                projected_mrr = m.mrr or 0,
                confidence = m.confidence or 75
            })
        end
    end
    respond(cb, projections)
end)

RegisterNUICallback('exportHostReport', function(data, cb)
    TriggerServerEvent('ec_admin:host:exportReport', data)
    cb({ success = true })
end)

-- ==========================================
-- EVENT LISTENERS
-- ==========================================

-- Receive action result
RegisterNetEvent('ec_admin:host:actionResult', function(result)
    SendNUIMessage({
        action = 'hostActionResult',
        data = result
    })
end)

-- Receive webhook test result
RegisterNetEvent('ec_admin:host:webhookTestResult', function(result)
    SendNUIMessage({
        action = 'webhookTestResult',
        data = result
    })
end)

-- Receive real-time updates
RegisterNetEvent('ec_admin:host:realtimeUpdate', function(updateType, data)
    SendNUIMessage({
        action = 'hostRealtimeUpdate',
        updateType = updateType,
        data = data
    })
end)

-- Receive notification
RegisterNetEvent('ec_admin:host:newNotification', function(notification)
    SendNUIMessage({
        action = 'hostNewNotification',
        data = notification
    })
end)

Logger.Info('✅ Host Management NUI callbacks registered')
