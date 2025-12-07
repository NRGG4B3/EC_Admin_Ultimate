-- EC Admin Ultimate - Client Main
-- DISABLED: All functionality moved to nui-bridge.lua
-- This file is kept for backwards compatibility but does nothing

Logger.Info('')

-- Everything is handled in nui-bridge.lua which loads FIRST
-- DO NOT re-enable this file as it causes conflicts with RegisterNUICallback

-- Legacy events that other scripts might trigger (keeping these for compatibility)

RegisterNetEvent('ec_admin:updatePlayers', function(players)
    SendNUIMessage({
        action = 'updatePlayers',
        data = { players = players }
    })
end)

RegisterNetEvent('ec_admin:updateMetrics', function(metrics)
    SendNUIMessage({
        action = 'updateMetrics',
        data = { metrics = metrics }
    })
end)

RegisterNetEvent('ec_admin:updateBans', function(bans)
    SendNUIMessage({
        action = 'updateBans',
        data = { bans = bans }
    })
end)

RegisterNetEvent('ec_admin:updateReports', function(reports)
    SendNUIMessage({
        action = 'updateReports',
        data = { reports = reports }
    })
end)

RegisterNetEvent('ec_admin:notification', function(message, type)
    SendNUIMessage({
        action = 'notification',
        data = { message = message, type = type }
    })
end)

-- REMOVED: ec_admin:teleportToCoords - duplicate with quick-actions-handlers.lua

RegisterNetEvent('ec_admin:startSpectating', function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    NetworkSetInSpectatorMode(true, targetPed)
end)

RegisterNetEvent('ec_admin:stopSpectating', function()
    NetworkSetInSpectatorMode(false, nil)
end)

RegisterNetEvent('ec_admin:freezeLocal', function(freeze)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, freeze)
end)

Logger.Info('')