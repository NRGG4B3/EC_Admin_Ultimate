--[[
    EC Admin Ultimate - System Management NUI Callbacks (Client)
]]

-- Get system data
RegisterNUICallback('system:getData', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getSystemData', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:getSystemData')
        cb({ success = true })
    end
end)

-- Start resource
RegisterNUICallback('system:startResource', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:startResource', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:startResource', data)
        cb({ success = true })
    end
end)

-- Stop resource
RegisterNUICallback('system:stopResource', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:stopResource', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:stopResource', data)
        cb({ success = true })
    end
end)

-- Restart resource
RegisterNUICallback('system:restartResource', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:restartResource', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:restartResource', data)
        cb({ success = true })
    end
end)

-- Server announcement
RegisterNUICallback('system:serverAnnouncement', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:serverAnnouncement', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:serverAnnouncement', data)
        cb({ success = true })
    end
end)

-- Kick all players
RegisterNUICallback('system:kickAllPlayers', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:kickAllPlayers', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:kickAllPlayers', data)
        cb({ success = true })
    end
end)

-- Clear cache
RegisterNUICallback('system:clearCache', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:clearCache', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:clearCache', data)
        cb({ success = true })
    end
end)

-- Database cleanup
RegisterNUICallback('system:databaseCleanup', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:databaseCleanup', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:databaseCleanup', data)
        cb({ success = true })
    end
end)

-- Get database stats
RegisterNUICallback('system:getDatabaseStats', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:getDatabaseStats')
    cb({ success = true })
end)

-- Receive system data
RegisterNetEvent('ec_admin_ultimate:client:receiveSystemData', function(result)
    SendNUIMessage({
        action = 'systemData',
        data = result
    })
end)

-- Receive system response
RegisterNetEvent('ec_admin_ultimate:client:systemResponse', function(result)
    SendNUIMessage({
        action = 'systemResponse',
        data = result
    })
end)

-- Receive database stats
RegisterNetEvent('ec_admin_ultimate:client:receiveDatabaseStats', function(result)
    SendNUIMessage({
        action = 'databaseStats',
        data = result
    })
end)

-- Receive performance update
RegisterNetEvent('ec_admin_ultimate:client:performanceUpdate', function(data)
    SendNUIMessage({
        action = 'performanceUpdate',
        data = data
    })
end)

-- Receive console log
RegisterNetEvent('ec_admin_ultimate:client:consoleLog', function(data)
    SendNUIMessage({
        action = 'consoleLog',
        data = data
    })
end)

-- Receive server announcement
RegisterNetEvent('ec_admin_ultimate:client:serverAnnouncement', function(data)
    -- Display announcement
    SendNUIMessage({
        action = 'serverAnnouncement',
        data = data
    })
    
    -- Also show as notification
    if exports['ec_admin_ultimate'] then
        exports['ec_admin_ultimate']:ShowNotification({
            title = '📢 Server Announcement',
            message = data.message,
            type = 'info',
            duration = data.duration or 10000
        })
    end
end)

Logger.Info('System Management NUI callbacks loaded')
