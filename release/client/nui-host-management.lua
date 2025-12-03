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

-- ==========================================
-- ANALYTICS & REPORTS
-- ==========================================

RegisterNUICallback('getHostAnalytics', function(data, cb)
    local result = lib.callback.await('ec_admin:host:getAnalytics', false, data.timeRange or '24h')
    respond(cb, result or {})
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
