-- EC Admin Ultimate - Client Admin Menu Gating
-- Gates F2 menu when host disables admin panel

local adminMenuEnabled = true

-- Listen for admin menu toggle from server
RegisterNetEvent('ec_admin:adminMenuToggled')
AddEventHandler('ec_admin:adminMenuToggled', function(data)
    adminMenuEnabled = data.enabled
    
    if adminMenuEnabled then
        print('^2[Admin Menu] Admin panel has been enabled by host^0')
        -- Show notification
        SendNUIMessage({
            type = 'notification',
            data = {
                type = 'success',
                message = 'Admin panel enabled'
            }
        })
    else
        print('^3[Admin Menu] Admin panel has been disabled by host^0')
        -- Show notification
        SendNUIMessage({
            type = 'notification',
            data = {
                type = 'warning',
                message = 'Admin panel disabled by host'
            }
        })
        
        -- Close NUI if open
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = 'closeAdminPanel'
        })
    end
end)

-- Get current state on join
RegisterNetEvent('playerSpawned')
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('ec_admin:host:getAdminMenuState')
end)

-- Receive admin menu state
RegisterNetEvent('ec_admin:client:adminMenuState')
AddEventHandler('ec_admin:client:adminMenuState', function(data)
    adminMenuEnabled = data.enabled
    print(string.format('^3[Admin Menu] State: %s^0', adminMenuEnabled and 'ENABLED' or 'DISABLED'))
end)

-- Gate the F2 menu opening
function CanOpenAdminMenu()
    if not adminMenuEnabled then
        -- Show toast notification
        SendNUIMessage({
            type = 'notification',
            data = {
                type = 'error',
                message = 'Admin panel has been disabled by the server host. Contact server owner for more information.'
            }
        })
        
        -- Play error sound
        PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        
        return false
    end
    
    return true
end

-- Export for use in main.lua
exports('CanOpenAdminMenu', CanOpenAdminMenu)

print('^2[Admin Menu Gating] Client handler loaded^0')
