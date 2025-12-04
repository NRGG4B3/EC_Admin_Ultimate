--[[
    EC Admin Ultimate - Dashboard Actions
    Event handlers for dashboard-related actions
]]

-- ==========================================
-- DASHBOARD REFRESH
-- ==========================================

RegisterNetEvent('ec_admin:refreshDashboard', function()
    local src = source
    
    -- Trigger data refresh on client
    TriggerClientEvent('ec_admin:dashboardRefreshed', src)
end)

-- ==========================================
-- QUICK ACTIONS FROM DASHBOARD
-- ==========================================

RegisterNetEvent('ec_admin:dashboard:restartResource', function(data)
    local src = source
    local resourceName = data.resource
    
    if not resourceName then return end
    
    -- Verify admin permission
    if not IsPlayerAceAllowed(src, 'admin.access') then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'No permission'
        })
        return
    end
    
    -- Restart resource
    if GetResourceState(resourceName) == 'started' then
        StopResource(resourceName)
        Wait(1000)
    end
    
    StartResource(resourceName)
    
    -- Log activity
    TriggerEvent('ec_admin:logActivity', {
        type = 'resource_restart',
        admin = GetPlayerName(src),
        target = resourceName,
        description = 'Restarted resource: ' .. resourceName
    })
    
    TriggerClientEvent('ec_admin:notify', src, {
        type = 'success',
        message = 'Resource restarted: ' .. resourceName
    })
end)

RegisterNetEvent('ec_admin:dashboard:stopResource', function(data)
    local src = source
    local resourceName = data.resource
    
    if not resourceName then return end
    
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    StopResource(resourceName)
    
    TriggerEvent('ec_admin:logActivity', {
        type = 'resource_stop',
        admin = GetPlayerName(src),
        target = resourceName,
        description = 'Stopped resource: ' .. resourceName
    })
end)

RegisterNetEvent('ec_admin:dashboard:startResource', function(data)
    local src = source
    local resourceName = data.resource
    
    if not resourceName then return end
    
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    StartResource(resourceName)
    
    TriggerEvent('ec_admin:logActivity', {
        type = 'resource_start',
        admin = GetPlayerName(src),
        target = resourceName,
        description = 'Started resource: ' .. resourceName
    })
end)

Logger.Info("^7 Dashboard actions loaded")
