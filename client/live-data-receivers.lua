--[[
    EC Admin Ultimate - Live Data Receivers
    
    Client-side handlers for real-time data updates from server
    Ensures complete front-to-back connectivity with live data
]]--

Logger.Info('📡 Loading Live Data Receivers...')

-- Helper function to send data to NUI
local function SendNUIData(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

--[[ ==================== DATA RECEIVERS ==================== ]]--

-- Receive Player List from Server
RegisterNetEvent('ec-admin:receivePlayerList')
AddEventHandler('ec-admin:receivePlayerList', function(players)
    Logger.Info('Received player list: ' .. #players .. ' players')
    SendNUIData('updatePlayerList', players)
end)

-- Receive Player Details from Server
RegisterNetEvent('ec-admin:receivePlayerDetails')
AddEventHandler('ec-admin:receivePlayerDetails', function(details)
    Logger.Info('Received player details')
    SendNUIData('updatePlayerDetails', details)
end)

-- Receive Vehicle List from Server
RegisterNetEvent('ec-admin:receiveVehicleList')
AddEventHandler('ec-admin:receiveVehicleList', function(vehicles)
    Logger.Info('Received vehicle list: ' .. #vehicles .. ' vehicles')
    SendNUIData('updateVehicleList', vehicles)
end)

-- Receive Ban List from Server
RegisterNetEvent('ec-admin:receiveBanList')
AddEventHandler('ec-admin:receiveBanList', function(bans)
    Logger.Info('Received ban list: ' .. #bans .. ' bans')
    SendNUIData('updateBanList', bans)
end)

-- Receive Warning List from Server
RegisterNetEvent('ec-admin:receiveWarningList')
AddEventHandler('ec-admin:receiveWarningList', function(warnings)
    Logger.Info('Received warning list: ' .. #warnings .. ' warnings')
    SendNUIData('updateWarningList', warnings)
end)

-- Receive Resource List from Server
RegisterNetEvent('ec-admin:receiveResourceList')
AddEventHandler('ec-admin:receiveResourceList', function(resources)
    Logger.Info('Received resource list: ' .. #resources .. ' resources')
    SendNUIData('updateResourceList', resources)
end)

-- Receive Log List from Server
RegisterNetEvent('ec-admin:receiveLogList')
AddEventHandler('ec-admin:receiveLogList', function(logs)
    Logger.Info('Received log list: ' .. #logs .. ' logs')
    SendNUIData('updateLogList', logs)
end)

-- Receive Backup List from Server
RegisterNetEvent('ec-admin:receiveBackupList')
AddEventHandler('ec-admin:receiveBackupList', function(backups)
    Logger.Info('Received backup list: ' .. #backups .. ' backups')
    SendNUIData('updateBackupList', backups)
end)

-- Receive Server Metrics from Server
RegisterNetEvent('ec-admin:receiveServerMetrics')
AddEventHandler('ec-admin:receiveServerMetrics', function(metrics)
    SendNUIData('updateServerMetrics', metrics)
end)

--[[ ==================== NOTIFICATIONS ==================== ]]--

-- Receive Notifications from Server
RegisterNetEvent('ec-admin:notify')
AddEventHandler('ec-admin:notify', function(type, message)
    SendNUIData('showNotification', {
        type = type,
        message = message
    })
    
    -- Also show in chat/console for visibility
    if type == 'error' then
        Logger.Info('' .. message)
    elseif type == 'success' then
        Logger.Info('' .. message)
    elseif type == 'warning' then
        Logger.Info('' .. message)
    else
        Logger.Info('' .. message)
    end
end)

--[[ ==================== AUTO-REFRESH ==================== ]]--

-- Auto-refresh request from server
RegisterNetEvent('ec-admin:requestRefresh')
AddEventHandler('ec-admin:requestRefresh', function()
    -- Only refresh if menu is open
    if GetResourceState('EC_admin_ultimate') == 'started' then
        -- Check if NUI is focused
        local isMenuOpen = exports['EC_admin_ultimate']:isMenuOpen()
        
        if isMenuOpen then
            -- Refresh all data
            TriggerServerEvent('ec-admin:getPlayers')
            TriggerServerEvent('ec-admin:getServerMetrics')
        end
    end
end)

--[[ ==================== WORLD SYNC ==================== ]]--

-- Weather sync from server
RegisterNetEvent('ec-admin:syncWeather')
AddEventHandler('ec-admin:syncWeather', function(weather)
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypePersist(weather)
    Logger.Info('Weather synced: ' .. weather)
end)

-- Time sync from server
RegisterNetEvent('ec-admin:syncTime')
AddEventHandler('ec-admin:syncTime', function(hour, minute)
    -- Set time for all clients
    NetworkOverrideClockTime(hour, minute, 0)
    
    SendNUIData('timeSync', {
        hour = hour,
        minute = minute
    })
end)

-- ============================================================================
-- LIVE METRICS UPDATE (Critical for Dashboard)
-- ============================================================================

-- Receive live metrics update from server
RegisterNetEvent('ec-admin:updateLiveData')
AddEventHandler('ec-admin:updateLiveData', function(data)
    SendNUIMessage({
        action = 'updateLiveMetrics',
        data = data
    })
end)

-- Legacy compatibility (old event name)
RegisterNetEvent('ec-admin:updateMetrics')
AddEventHandler('ec-admin:updateMetrics', function(metrics)
    SendNUIMessage({
        action = 'updateLiveMetrics',
        data = metrics
    })
end)

-- ============================================================================
-- SPECTATE SYSTEM
-- ============================================================================

local isSpectating = false
local spectateTarget = nil

-- Start spectate
RegisterNetEvent('ec-admin:startSpectate')
AddEventHandler('ec-admin:startSpectate', function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    
    if DoesEntityExist(targetPed) then
        isSpectating = true
        spectateTarget = targetPed
        
        NetworkSetInSpectatorMode(true, targetPed)
        
        SendNUIData('showNotification', {
            type = 'info',
            message = 'Spectating player. Press ESC to stop.'
        })
        
        Logger.Info('Started spectating player')
    else
        SendNUIData('showNotification', {
            type = 'error',
            message = 'Could not find target player'
        })
    end
end)

-- Stop spectate (ESC key)
CreateThread(function()
    while true do
        if isSpectating then
            Wait(0) -- Check frequently when spectating
            
            if IsControlJustPressed(0, 322) then -- ESC key
                NetworkSetInSpectatorMode(false, spectateTarget)
                isSpectating = false
                spectateTarget = nil
                
                SendNUIData('showNotification', {
                    type = 'info',
                    message = 'Stopped spectating'
                })
                
                Logger.Info('Stopped spectating')
            end
        else
            Wait(1000) -- Sleep when not spectating
        end
    end
end)

--[[ ==================== LIVE DATA PUSH ==================== ]]--

-- Push live player position updates to NUI
CreateThread(function()
    while true do
        Wait(5000) -- Every 5 seconds
        
        -- Only if menu is open (get from nui-bridge export)
        local success, isMenuOpen = pcall(function()
            return exports['EC_admin_ultimate']:isMenuOpen()
        end)
        
        if success and isMenuOpen then
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            
            SendNUIData('updatePlayerPosition', {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                heading = heading
            })
        end
    end
end)

--[[ ==================== EXPORTS ==================== ]]--

-- Export menu state (returns false if export doesn't exist yet)
function IsMenuOpen()
    return false -- This file doesn't track menu state, nui-bridge.lua does
end

exports('isMenuOpen', IsMenuOpen)

--[[ ==================== CLEANUP HANDLERS ==================== ]]--

-- Stop spectating a specific target (when they disconnect)
RegisterNetEvent('ec_admin:stopSpectatingTarget', function(targetId)
    if isSpectating and spectateTarget == GetPlayerPed(GetPlayerFromServerId(targetId)) then
        NetworkSetInSpectatorMode(false, spectateTarget)
        isSpectating = false
        spectateTarget = nil
        
        SendNUIData('showNotification', {
            type = 'info',
            message = 'Player you were spectating has disconnected'
        })
        
        Logger.Info('Stopped spectating - target disconnected')
    end
end)

-- Force close everything (resource stop)
RegisterNetEvent('ec_admin:forceCloseAll', function()
    -- Close NUI
    SendNUIMessage({ action = 'forceClose' })
    SetNuiFocus(false, false)
    
    -- Stop spectating
    if isSpectating then
        NetworkSetInSpectatorMode(false, spectateTarget)
        isSpectating = false
        spectateTarget = nil
    end
    
    Logger.Info('Force closed all UI and spectating')
end)

-- General cleanup event
RegisterNetEvent('ec_admin:cleanup', function()
    -- Stop spectating
    if isSpectating then
        NetworkSetInSpectatorMode(false, spectateTarget)
        isSpectating = false
        spectateTarget = nil
    end
    
    -- Unfreeze local player
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    
    -- Clear invincibility
    SetEntityInvincible(ped, false)
    
    Logger.Info('Cleanup complete')
end)

Logger.Info('✅ Live Data Receivers loaded with cleanup handlers')