--[[
    EC Admin Ultimate - Whitelist NUI Callbacks (Client)
]]

-- Get whitelist data
RegisterNUICallback('whitelist:getData', function(data, cb)
    -- Use modern callback with fallback
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getWhitelistData', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        -- Fallback to legacy event
        TriggerServerEvent('ec_admin_ultimate:server:getWhitelistData')
        cb({ success = true })
    end
end)

-- Add whitelist entry
RegisterNUICallback('whitelist:add', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:addWhitelist', data)
    cb({ success = true })
end)

-- Update whitelist entry
RegisterNUICallback('whitelist:update', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:updateWhitelist', data)
    cb({ success = true })
end)

-- Remove whitelist entry
RegisterNUICallback('whitelist:remove', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:removeWhitelist', data)
    cb({ success = true })
end)

-- Approve application
RegisterNUICallback('whitelist:approveApplication', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:approveApplication', data)
    cb({ success = true })
end)

-- Deny application
RegisterNUICallback('whitelist:denyApplication', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:denyApplication', data)
    cb({ success = true })
end)

-- Create role
RegisterNUICallback('whitelist:createRole', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:createRole', data)
    cb({ success = true })
end)

-- Update role
RegisterNUICallback('whitelist:updateRole', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:updateRole', data)
    cb({ success = true })
end)

-- Delete role
RegisterNUICallback('whitelist:deleteRole', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:deleteRole', data)
    cb({ success = true })
end)

-- Receive whitelist data
RegisterNetEvent('ec_admin_ultimate:client:receiveWhitelistData', function(result)
    SendNUIMessage({
        action = 'whitelistData',
        data = result
    })
end)

-- Receive whitelist response
RegisterNetEvent('ec_admin_ultimate:client:whitelistResponse', function(result)
    SendNUIMessage({
        action = 'whitelistResponse',
        data = result
    })
end)

Logger.Info('Whitelist NUI callbacks loaded')
