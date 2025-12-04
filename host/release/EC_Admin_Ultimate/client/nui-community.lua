--[[
    EC Admin Ultimate - Community NUI Callbacks (Client)
]]

-- Get community data
RegisterNUICallback('community:getData', function(data, cb)
    -- Use modern callback with fallback
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getCommunityData', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        -- Fallback to legacy event
        TriggerServerEvent('ec_admin_ultimate:server:getCommunityData')
        cb({ success = true })
    end
end)

-- Create group
RegisterNUICallback('community:createGroup', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:createGroup', data)
    cb({ success = true })
end)

-- Delete group
RegisterNUICallback('community:deleteGroup', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:deleteGroup', data)
    cb({ success = true })
end)

-- Create event
RegisterNUICallback('community:createEvent', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:createEvent', data)
    cb({ success = true })
end)

-- Delete event
RegisterNUICallback('community:deleteEvent', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:deleteEvent', data)
    cb({ success = true })
end)

-- Update event status
RegisterNUICallback('community:updateEventStatus', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:updateEventStatus', data)
    cb({ success = true })
end)

-- Create achievement
RegisterNUICallback('community:createAchievement', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:createAchievement', data)
    cb({ success = true })
end)

-- Delete achievement
RegisterNUICallback('community:deleteAchievement', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:deleteAchievement', data)
    cb({ success = true })
end)

-- Grant achievement
RegisterNUICallback('community:grantAchievement', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:grantAchievement', data)
    cb({ success = true })
end)

-- Create announcement
RegisterNUICallback('community:createAnnouncement', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:createAnnouncement', data)
    cb({ success = true })
end)

-- Delete announcement
RegisterNUICallback('community:deleteAnnouncement', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:deleteAnnouncement', data)
    cb({ success = true })
end)

-- Receive community data
RegisterNetEvent('ec_admin_ultimate:client:receiveCommunityData', function(result)
    SendNUIMessage({
        action = 'communityData',
        data = result
    })
end)

-- Receive community response
RegisterNetEvent('ec_admin_ultimate:client:communityResponse', function(result)
    SendNUIMessage({
        action = 'communityResponse',
        data = result
    })
end)

-- Receive new announcement
RegisterNetEvent('ec_admin_ultimate:client:newAnnouncement', function(data)
    SendNUIMessage({
        action = 'newAnnouncement',
        data = data
    })
    
    -- Show notification
    if exports['ec_admin_ultimate'] then
        exports['ec_admin_ultimate']:ShowNotification({
            title = '📢 ' .. data.title,
            message = data.message,
            type = data.type or 'info',
            duration = 10000
        })
    end
end)

Logger.Info('Community NUI callbacks loaded')
