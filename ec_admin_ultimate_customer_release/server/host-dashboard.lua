--[[
    EC Admin Ultimate - Host Dashboard UI Backend
    Server-side logic for host dashboard management
    
    Handles:
    - getHostSystemStats: Get host system statistics
    - getHostAPIStatuses: Get API statuses
    - getConnectedCities: Get connected cities
    - getGlobalBans: Get global bans
    - getBanAppeals: Get ban appeals
    - getGlobalWarnings: Get global warnings
    - getHostWebhooks: Get host webhooks
    - getSystemLogs: Get system logs
    - getHostActionLogs: Get action logs
    - getPerformanceMetrics: Get performance metrics
    - getSalesProjections: Get sales projections
    - startHostAPI: Start a host API
    - stopHostAPI: Stop a host API
    - restartHostAPI: Restart a host API
    - startAllHostAPIs: Start all host APIs
    - stopAllHostAPIs: Stop all host APIs
    - removeGlobalBan: Remove a global ban
    - processBanAppeal: Process a ban appeal
    - issueGlobalWarning: Issue a global warning
    - removeGlobalWarning: Remove a global warning
    - testHostWebhook: Test a host webhook
    - toggleHostWebhook: Toggle a host webhook
    - updateHostWebhook: Update a host webhook
    - createHostWebhook: Create a host webhook
    - deleteHostWebhook: Delete a host webhook
    - resolveSystemAlert: Resolve a system alert
    - disconnectCity: Disconnect a city
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Host Dashboard] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Check if host mode is enabled
local function isHostMode()
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].IsHostMode then
        return exports['ec_admin_ultimate']:IsHostMode()
    end
    return false
end

-- Check if player can access host dashboard
local function canAccessHostDashboard(source)
    if not source or source == 0 then return false end
    
    -- Check if host mode is enabled
    if isHostMode() then
        -- In host mode, check if player has permission
        if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
            return exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.dashboard')
        end
        return true -- Default allow in host mode
    end
    
    -- Check if player is NRG staff (can access from customer servers)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].IsNRGStaff then
        return exports['ec_admin_ultimate']:IsNRGStaff(source)
    end
    
    return false
end

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get admin info
local function getAdminInfo(source)
    return {
        id = GetPlayerIdentifier(source, 0) or 'system',
        name = GetPlayerName(source) or 'System'
    }
end

-- ============================================================================
-- LIB.CALLBACK REGISTERS (fetchNui calls from UI)
-- ============================================================================

-- Callback: Get host system stats
lib.callback.register('ec_admin:getHostSystemStats', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Try to get real data from host API (Node.js backend)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/stats', 'GET')
        if apiResponse and apiResponse.success and apiResponse.data then
            return { success = true, data = apiResponse.data }
        end
    end
    
    -- Fallback: Return empty structure (will be populated by API when available)
    return {
        success = true,
        data = {
            total_apis = 0,
            online_apis = 0,
            degraded_apis = 0,
            offline_apis = 0,
            system_health = 0,
            total_cities = 0,
            online_cities = 0,
            ec_admin_cities = 0,
            customer_cities = 0,
            total_players_online = 0,
            total_requests_today = 0,
            total_requests_all_time = 0,
            avg_response_time = 0,
            total_errors_today = 0,
            avg_uptime = 0,
            total_bans = 0,
            bans_today = 0,
            pending_appeals = 0,
            total_warnings = 0,
            warnings_today = 0,
            total_memory_usage = 0,
            total_cpu_usage = 0,
            database_size = 0,
            total_webhooks = 0,
            active_webhooks = 0,
            webhook_executions_today = 0,
            critical_alerts = 0,
            warnings_system = 0
        }
    }
end)

-- Callback: Get host API statuses
lib.callback.register('ec_admin:getHostAPIStatuses', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Try to get real data from host API
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/apis', 'GET')
        if apiResponse and apiResponse.success and apiResponse.data then
            return { success = true, data = apiResponse.data }
        end
    end
    
    -- Fallback: Return empty array
    return { success = true, data = {} }
end)

-- Callback: Get connected cities
lib.callback.register('ec_admin:getConnectedCities', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Try to get real data from host API
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/cities', 'GET')
        if apiResponse and apiResponse.success and apiResponse.data then
            return { success = true, data = apiResponse.data }
        end
    end
    
    -- Fallback: Return empty array
    return { success = true, data = {} }
end)

-- Callback: Get global bans
lib.callback.register('ec_admin:getGlobalBans', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Try to get real data from host API
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/bans', 'GET')
        if apiResponse and apiResponse.success and apiResponse.data then
            return { success = true, data = apiResponse.data }
        end
    end
    
    -- Fallback: Return empty array
    return { success = true, data = {} }
end)

-- Callback: Get ban appeals
lib.callback.register('ec_admin:getBanAppeals', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Try to get real data from host API
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/appeals', 'GET')
        if apiResponse and apiResponse.success and apiResponse.data then
            return { success = true, data = apiResponse.data }
        end
    end
    
    -- Fallback: Return empty array
    return { success = true, data = {} }
end)

-- Callback: Get global warnings
lib.callback.register('ec_admin:getGlobalWarnings', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Try to get real data from host API
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/warnings', 'GET')
        if apiResponse and apiResponse.success and apiResponse.data then
            return { success = true, data = apiResponse.data }
        end
    end
    
    -- Fallback: Return empty array
    return { success = true, data = {} }
end)

-- Callback: Get host webhooks
lib.callback.register('ec_admin:getHostWebhooks', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Try to get real data from host API
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/webhooks', 'GET')
        if apiResponse and apiResponse.success and apiResponse.data then
            return { success = true, data = apiResponse.data }
        end
    end
    
    -- Fallback: Return empty array
    return { success = true, data = {} }
end)

-- Callback: Get system logs
lib.callback.register('ec_admin:getSystemLogs', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Try to get real data from host API
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/logs', 'GET')
        if apiResponse and apiResponse.success and apiResponse.data then
            return { success = true, data = apiResponse.data }
        end
    end
    
    -- Fallback: Return empty array
    return { success = true, data = {} }
end)

-- Callback: Get host action logs
lib.callback.register('ec_admin:getHostActionLogs', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Try to get real data from host API
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/actions', 'GET')
        if apiResponse and apiResponse.success and apiResponse.data then
            return { success = true, data = apiResponse.data }
        end
    end
    
    -- Fallback: Return empty array
    return { success = true, data = {} }
end)

-- Callback: Get performance metrics
lib.callback.register('ec_admin:getPerformanceMetrics', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Try to get real data from host API
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/metrics', 'GET')
        if apiResponse and apiResponse.success and apiResponse.data then
            return { success = true, data = apiResponse.data }
        end
    end
    
    -- Fallback: Return empty array
    return { success = true, data = {} }
end)

-- Callback: Get sales projections
lib.callback.register('ec_admin:getSalesProjections', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Try to get real data from host API
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/sales', 'GET')
        if apiResponse and apiResponse.success and apiResponse.data then
            return { success = true, data = apiResponse.data }
        end
    end
    
    -- Fallback: Return empty array
    return { success = true, data = {} }
end)

-- Callback: Start host API
lib.callback.register('ec_admin:startHostAPI', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local apiKey = data.apiKey
    if not apiKey then
        return { success = false, error = 'API key required' }
    end
    
    -- Call host API to start the service
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/apis/start', 'POST', { apiKey = apiKey })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'API started' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to start API' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Stop host API
lib.callback.register('ec_admin:stopHostAPI', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local apiKey = data.apiKey
    if not apiKey then
        return { success = false, error = 'API key required' }
    end
    
    -- Call host API to stop the service
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/apis/stop', 'POST', { apiKey = apiKey })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'API stopped' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to stop API' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Restart host API
lib.callback.register('ec_admin:restartHostAPI', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local apiKey = data.apiKey
    if not apiKey then
        return { success = false, error = 'API key required' }
    end
    
    -- Call host API to restart the service
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/apis/restart', 'POST', { apiKey = apiKey })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'API restarted' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to restart API' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Start all host APIs
lib.callback.register('ec_admin:startAllHostAPIs', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Call host API to start all services
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/apis/start-all', 'POST', {})
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'All APIs started' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to start all APIs' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Stop all host APIs
lib.callback.register('ec_admin:stopAllHostAPIs', function(source)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Call host API to stop all services
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/apis/stop-all', 'POST', {})
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'All APIs stopped' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to stop all APIs' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Remove global ban
lib.callback.register('ec_admin:removeGlobalBan', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local banId = data.banId
    if not banId then
        return { success = false, error = 'Ban ID required' }
    end
    
    local adminInfo = getAdminInfo(source)
    
    -- Call host API to remove ban
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/bans/remove', 'POST', {
            banId = banId,
            adminId = adminInfo.id,
            adminName = adminInfo.name
        })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'Ban removed' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to remove ban' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Process ban appeal
lib.callback.register('ec_admin:processBanAppeal', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local appealId = data.appealId
    local action = data.action
    if not appealId or not action then
        return { success = false, error = 'Appeal ID and action required' }
    end
    
    local adminInfo = getAdminInfo(source)
    
    -- Call host API to process appeal
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/appeals/process', 'POST', {
            appealId = appealId,
            action = action,
            adminId = adminInfo.id,
            adminName = adminInfo.name,
            reason = data.reason or ''
        })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'Appeal processed' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to process appeal' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Issue global warning
lib.callback.register('ec_admin:issueGlobalWarning', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local adminInfo = getAdminInfo(source)
    
    -- Call host API to issue warning
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/warnings/issue', 'POST', {
            playerIdentifier = data.playerIdentifier,
            reason = data.reason or '',
            severity = data.severity or 'medium',
            adminId = adminInfo.id,
            adminName = adminInfo.name
        })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'Warning issued' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to issue warning' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Remove global warning
lib.callback.register('ec_admin:removeGlobalWarning', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local warningId = data.warningId
    if not warningId then
        return { success = false, error = 'Warning ID required' }
    end
    
    local adminInfo = getAdminInfo(source)
    
    -- Call host API to remove warning
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/warnings/remove', 'POST', {
            warningId = warningId,
            adminId = adminInfo.id,
            adminName = adminInfo.name
        })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'Warning removed' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to remove warning' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Test host webhook
lib.callback.register('ec_admin:testHostWebhook', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local webhookId = data.webhookId
    if not webhookId then
        return { success = false, error = 'Webhook ID required' }
    end
    
    -- Call host API to test webhook
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/webhooks/test', 'POST', { webhookId = webhookId })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'Webhook tested' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to test webhook' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Toggle host webhook
lib.callback.register('ec_admin:toggleHostWebhook', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local webhookId = data.webhookId
    local enabled = data.enabled
    if not webhookId then
        return { success = false, error = 'Webhook ID required' }
    end
    
    -- Call host API to toggle webhook
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/webhooks/toggle', 'POST', {
            webhookId = webhookId,
            enabled = enabled
        })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'Webhook toggled' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to toggle webhook' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Update host webhook
lib.callback.register('ec_admin:updateHostWebhook', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local webhookId = data.webhookId
    if not webhookId then
        return { success = false, error = 'Webhook ID required' }
    end
    
    -- Call host API to update webhook
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/webhooks/update', 'POST', {
            webhookId = webhookId,
            name = data.name,
            url = data.url,
            events = data.events,
            enabled = data.enabled
        })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'Webhook updated' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to update webhook' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Create host webhook
lib.callback.register('ec_admin:createHostWebhook', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    -- Call host API to create webhook
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/webhooks/create', 'POST', {
            name = data.name,
            url = data.url,
            events = data.events,
            enabled = data.enabled ~= false
        })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'Webhook created', data = apiResponse.data }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to create webhook' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Delete host webhook
lib.callback.register('ec_admin:deleteHostWebhook', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local webhookId = data.webhookId
    if not webhookId then
        return { success = false, error = 'Webhook ID required' }
    end
    
    -- Call host API to delete webhook
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/webhooks/delete', 'POST', { webhookId = webhookId })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'Webhook deleted' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to delete webhook' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Resolve system alert
lib.callback.register('ec_admin:resolveSystemAlert', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local logId = data.logId
    if not logId then
        return { success = false, error = 'Log ID required' }
    end
    
    local adminInfo = getAdminInfo(source)
    
    -- Call host API to resolve alert
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/alerts/resolve', 'POST', {
            logId = logId,
            adminId = adminInfo.id,
            adminName = adminInfo.name,
            resolution = data.resolution or ''
        })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'Alert resolved' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to resolve alert' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

-- Callback: Disconnect city
lib.callback.register('ec_admin:disconnectCity', function(source, data)
    if not canAccessHostDashboard(source) then
        return { success = false, error = 'Access denied' }
    end
    
    local cityId = data.cityId
    if not cityId then
        return { success = false, error = 'City ID required' }
    end
    
    local adminInfo = getAdminInfo(source)
    
    -- Call host API to disconnect city
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        local apiResponse = exports['ec_admin_ultimate']:CallHostAPI('/api/host/cities/disconnect', 'POST', {
            cityId = cityId,
            adminId = adminInfo.id,
            adminName = adminInfo.name,
            reason = data.reason or ''
        })
        if apiResponse and apiResponse.success then
            return { success = true, message = apiResponse.data and apiResponse.data.message or 'City disconnected' }
        end
        return { success = false, error = apiResponse and apiResponse.error or 'Failed to disconnect city' }
    end
    
    return { success = false, error = 'Host API not available' }
end)

print("^2[Host Dashboard]^7 UI Backend loaded^0")

