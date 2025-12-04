--[[
    EC Admin Ultimate - Host Dashboard NUI Callbacks (Client)
]]

-- Get host dashboard data
RegisterNUICallback('hostDashboard:getData', function(data, cb)
    -- Use modern callback with fallback
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getHostDashboard', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        -- Fallback to legacy event
        TriggerServerEvent('ec_admin_ultimate:server:getHostDashboard')
        cb({ success = true })
    end
end)

-- Restart API
RegisterNUICallback('hostDashboard:restartAPI', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:restartAPI', data)
    cb({ success = true })
end)

-- Toggle admin menu visibility
RegisterNUICallback('hostDashboard:toggleAdminMenu', function(data, cb)
    -- This would be handled by the main admin menu system
    -- For now, just acknowledge
    cb({ success = true })
end)

-- Connect to customer server
RegisterNUICallback('hostDashboard:connectServer', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:connectCustomerServer', data)
    cb({ success = true })
end)

-- Disconnect customer server
RegisterNUICallback('hostDashboard:disconnectServer', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:disconnectCustomerServer', data)
    cb({ success = true })
end)

-- Add global ban
RegisterNUICallback('hostDashboard:addGlobalBan', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:addGlobalBan', data)
    cb({ success = true })
end)

-- Remove global ban
RegisterNUICallback('hostDashboard:removeGlobalBan', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:removeGlobalBan', data)
    cb({ success = true })
end)

-- Receive host dashboard data
RegisterNetEvent('ec_admin_ultimate:client:receiveHostDashboard', function(result)
    SendNUIMessage({
        action = 'hostDashboardData',
        data = result
    })
end)

-- Receive host dashboard response
RegisterNetEvent('ec_admin_ultimate:client:hostDashboardResponse', function(result)
    SendNUIMessage({
        action = 'hostDashboardResponse',
        data = result
    })
end)

Logger.Info('Host Dashboard NUI callbacks loaded')