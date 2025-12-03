--[[
    EC Admin Ultimate - Monitoring Actions
    Event handlers for server monitoring and resource management
]]

-- ==========================================
-- RESOURCE MANAGEMENT
-- ==========================================

RegisterNetEvent('ec_admin:restartResource', function(data)
    local src = source
    
    if not data or not data.resource then return end
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    local resourceName = data.resource
    
    if GetResourceState(resourceName) == 'started' then
        StopResource(resourceName)
        Wait(1000)
    end
    
    local success = StartResource(resourceName)
    
    if success then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = 'Resource restarted: ' .. resourceName
        })
    else
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'Failed to restart resource: ' .. resourceName
        })
    end
    
    -- Log activity
    TriggerEvent('ec_admin:logActivity', {
        type = 'resource_restart',
        admin = GetPlayerName(src),
        target = resourceName,
        description = 'Restarted resource'
    })
end)

RegisterNetEvent('ec_admin:stopResource', function(data)
    local src = source
    
    if not data or not data.resource then return end
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    local resourceName = data.resource
    
    StopResource(resourceName)
    
    TriggerClientEvent('ec_admin:notify', src, {
        type = 'success',
        message = 'Resource stopped: ' .. resourceName
    })
    
    -- Log activity
    TriggerEvent('ec_admin:logActivity', {
        type = 'resource_stop',
        admin = GetPlayerName(src),
        target = resourceName,
        description = 'Stopped resource'
    })
end)

RegisterNetEvent('ec_admin:startResource', function(data)
    local src = source
    
    if not data or not data.resource then return end
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    local resourceName = data.resource
    
    local success = StartResource(resourceName)
    
    if success then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = 'Resource started: ' .. resourceName
        })
    else
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'Failed to start resource: ' .. resourceName
        })
    end
    
    -- Log activity
    TriggerEvent('ec_admin:logActivity', {
        type = 'resource_start',
        admin = GetPlayerName(src),
        target = resourceName,
        description = 'Started resource'
    })
end)

-- ==========================================
-- SERVER COMMANDS
-- ==========================================

RegisterNetEvent('ec_admin:executeCommand', function(data)
    local src = source
    
    if not data or not data.command then return end
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    ExecuteCommand(data.command)
    
    TriggerClientEvent('ec_admin:notify', src, {
        type = 'success',
        message = 'Command executed'
    })
    
    -- Log activity
    TriggerEvent('ec_admin:logActivity', {
        type = 'command_execute',
        admin = GetPlayerName(src),
        description = 'Executed command: ' .. data.command
    })
end)

-- ==========================================
-- PERFORMANCE MONITORING
-- ==========================================

RegisterNetEvent('ec_admin:clearCache', function()
    local src = source
    
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    collectgarbage('collect')
    
    TriggerClientEvent('ec_admin:notify', src, {
        type = 'success',
        message = 'Server cache cleared'
    })
    
    -- Log activity
    TriggerEvent('ec_admin:logActivity', {
        type = 'cache_clear',
        admin = GetPlayerName(src),
        description = 'Cleared server cache'
    })
end)

Logger.Info("^7 Monitoring actions loaded")
