-- EC Admin Ultimate - Client Player Action Handlers
-- Handles client-side player actions triggered by server

print('[EC Admin Client] Loading Player Action Handlers...')

-- ==========================================
-- TELEPORT TO COORDINATES
-- ==========================================
RegisterNetEvent('ec_admin:teleportToCoords', function(coords)
    local ped = PlayerPedId()
    
    if not coords or type(coords) ~= 'table' then
        Logger.Info('Invalid teleport coordinates')
        return
    end
    
    -- Ensure we have x, y, z
    local x = coords.x or coords[1] or 0
    local y = coords.y or coords[2] or 0
    local z = coords.z or coords[3] or 0
    
    Logger.Info(string.format('', x, y, z))
    
    -- Teleport with DoScreenFadeOut/In for smooth transition
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(ped, x, y, z, false, false, false, true)
    
    Wait(500)
    DoScreenFadeIn(500)
    
    Logger.Info('Teleport complete')
end)

-- ==========================================
-- FREEZE/UNFREEZE PLAYER
-- ==========================================
RegisterNetEvent('ec_admin:setFreeze', function(freeze)
    local ped = PlayerPedId()
    
    FreezeEntityPosition(ped, freeze)
    
    if freeze then
        Logger.Info('You have been frozen')
        -- Show notification
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~r~You have been frozen by an admin')
        DrawNotification(false, true)
    else
        Logger.Info('You have been unfrozen')
        -- Show notification
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~g~You have been unfrozen')
        DrawNotification(false, true)
    end
end)

-- ==========================================
-- SPECTATE PLAYER
-- ==========================================
RegisterNetEvent('ec_admin:startSpectate', function(targetId)
    if not targetId then
        Logger.Info('Invalid spectate target')
        return
    end
    
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    
    if not DoesEntityExist(targetPed) then
        Logger.Info('Target player not found')
        return
    end
    
    Logger.Info(string.format('', targetId))
    
    -- Enable spectator mode
    NetworkSetInSpectatorMode(true, targetPed)
    
    -- Show notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString('~b~Spectating player. Press ESC to stop.')
    DrawNotification(false, true)
end)

RegisterNetEvent('ec_admin:stopSpectate', function()
    Logger.Info('Stopping spectate')
    
    NetworkSetInSpectatorMode(false, PlayerPedId())
    
    -- Show notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString('~g~Spectate stopped')
    DrawNotification(false, true)
end)

-- ==========================================
-- HEAL PLAYER
-- ==========================================
RegisterNetEvent('ec_admin:heal', function()
    local ped = PlayerPedId()
    
    Logger.Info('Healing player')
    
    -- Set full health
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    
    -- Remove all damage
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastWeaponDamage(ped)
    
    -- Show notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString('~g~You have been healed')
    DrawNotification(false, true)
end)

-- ==========================================
-- REVIVE PLAYER
-- ==========================================
RegisterNetEvent('ec_admin:revive', function()
    local ped = PlayerPedId()
    
    Logger.Info('Reviving player')
    
    -- Framework-specific revive (works with most frameworks)
    local coords = GetEntityCoords(ped)
    
    -- Network resurrection
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    
    -- Set full health
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    
    -- Clear damage
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    
    -- Ensure player is standing
    ClearPedTasksImmediately(ped)
    
    -- Show notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString('~g~You have been revived')
    DrawNotification(false, true)
    
    -- Try framework-specific revive events (if they exist)
    TriggerEvent('hospital:client:Revive') -- QBCore
    TriggerEvent('esx_ambulancejob:revive') -- ESX
end)

-- ==========================================
-- GIVE ARMOR
-- ==========================================
RegisterNetEvent('ec_admin:giveArmor', function(data)
    local ped = PlayerPedId()
    local amount = data and data.amount or 100
    
    Logger.Info(string.format('', amount))
    
    SetPedArmour(ped, amount)
    
    -- Show notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString(string.format('~b~Armor set to %d', amount))
    DrawNotification(false, true)
end)

-- ==========================================
-- RECEIVE WARNING
-- ==========================================
RegisterNetEvent('ec_admin:receiveWarning', function(data)
    if not data then return end
    
    local admin = data.admin or 'Admin'
    local reason = data.reason or 'No reason provided'
    
    Logger.Info(string.format('', admin, reason))
    
    -- Show big notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString(string.format('~r~WARNING FROM %s~n~~w~%s', admin, reason))
    DrawNotification(false, true)
    
    -- Play alert sound
    PlaySoundFrontend(-1, 'CHECKPOINT_UNDER_THE_BRIDGE', 'HUD_MINI_GAME_SOUNDSET', true)
end)

-- ==========================================
-- SET GOD MODE
-- ==========================================
RegisterNetEvent('ec_admin:setGodMode', function(enabled)
    local ped = PlayerPedId()
    
    SetEntityInvincible(ped, enabled)
    SetPlayerInvincible(PlayerId(), enabled)
    
    if enabled then
        Logger.Info('God mode enabled')
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~g~God Mode: ON')
        DrawNotification(false, true)
    else
        Logger.Info('God mode disabled')
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~r~God Mode: OFF')
        DrawNotification(false, true)
    end
end)

-- ==========================================
-- SET INVISIBILITY
-- ==========================================
RegisterNetEvent('ec_admin:setInvisibility', function(enabled)
    local ped = PlayerPedId()
    
    SetEntityVisible(ped, not enabled, 0)
    
    if enabled then
        Logger.Info('Invisibility enabled')
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~g~Invisibility: ON')
        DrawNotification(false, true)
    else
        Logger.Info('Invisibility disabled')
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~r~Invisibility: OFF')
        DrawNotification(false, true)
    end
end)

-- ==========================================
-- SUPER JUMP
-- ==========================================
RegisterNetEvent('ec_admin:setSuperJump', function(enabled)
    if enabled then
        Logger.Info('Super jump enabled')
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~g~Super Jump: ON')
        DrawNotification(false, true)
        
        -- Enable super jump in a thread
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(0)
                SetSuperJumpThisFrame(PlayerId())
                
                -- Break if no longer needed (implement your own break condition)
                if not enabled then break end
            end
        end)
    else
        Logger.Info('Super jump disabled')
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~r~Super Jump: OFF')
        DrawNotification(false, true)
    end
end)

-- ==========================================
-- SUPER SPEED
-- ==========================================
local superSpeedEnabled = false

RegisterNetEvent('ec_admin:setSuperSpeed', function(enabled)
    superSpeedEnabled = enabled
    
    if enabled then
        Logger.Info('Super speed enabled')
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~g~Super Speed: ON')
        DrawNotification(false, true)
    else
        Logger.Info('Super speed disabled')
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~r~Super Speed: OFF')
        DrawNotification(false, true)
    end
end)

-- Super speed thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if superSpeedEnabled then
            local ped = PlayerPedId()
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
            SetPedMoveRateOverride(ped, 2.0)
        else
            Citizen.Wait(500)
        end
    end
end)

print('[EC Admin Client] ✅ Player Action Handlers Loaded - All client events registered')
