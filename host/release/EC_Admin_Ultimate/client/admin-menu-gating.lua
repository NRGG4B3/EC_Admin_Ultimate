-- EC Admin Ultimate - Client Admin Menu Gating
-- Gates F2 menu when host disables admin panel

local adminMenuEnabled = true

-- Listen for admin menu toggle from server
RegisterNetEvent('ec_admin:adminMenuToggled')
AddEventHandler('ec_admin:adminMenuToggled', function(data)
    adminMenuEnabled = data.enabled
    
    if adminMenuEnabled then
        Logger.Success('✅ Admin panel enabled by host')
        -- Show notification
        SendNUIMessage({
            type = 'notification',
            data = {
                type = 'success',
                message = 'Admin panel enabled'
            }
        })
    else
        Logger.Warn('⚠ Admin panel disabled by host')
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
    Logger.Info(string.format('📋 Admin Menu State: %s', adminMenuEnabled and 'ENABLED' or 'DISABLED'))
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

Logger.Info('✅ Admin Menu Gating loaded')
