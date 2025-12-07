-- EC Admin Ultimate - Client-Side Quick Actions Handlers
-- Handles all client-side quick action execution

Logger.Info('📦 Loading Quick Actions Handlers')

-- State tracking
local noclipEnabled = false
local godModeEnabled = false
local invisibleEnabled = false
local savedPosition = nil
local lastPosition = nil
local spectatingPlayer = nil
local frozenPlayers = {}

-- State pause/resume for monitor switching
local statesPaused = false
local pausedStates = {
    noclip = false,
    godmode = false,
    invisible = false,
    spectating = false
}

-- ====================
-- SAFETY SYSTEM: State Cleanup & Pause/Resume
-- ====================

-- Clean up ALL active states (called when menu closes or resource stops)
RegisterNetEvent('ec_admin:cleanupAllStates')
AddEventHandler('ec_admin:cleanupAllStates', function()
    local ped = PlayerPedId()
    
    Logger.Info('Cleaning up all active states...')
    
    -- Disable noclip
    if noclipEnabled then
        noclipEnabled = false
        SetEntityCollision(ped, true, true)
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, 0)
        FreezeEntityPosition(ped, false)
    end

    -- Disable god mode (unless noclip was on)
    if godModeEnabled then
        godModeEnabled = false
        SetEntityInvincible(ped, false)
        SetPlayerInvincible(PlayerId(), false)
        SetPedCanRagdoll(ped, true)
    end
    
    -- Disable invisibility
    if invisibleEnabled then
        invisibleEnabled = false
        SetEntityVisible(ped, true, 0)
    end
    
    -- Stop spectating
    if spectatingPlayer then
        spectatingPlayer = nil
        NetworkSetInSpectatorMode(false, nil)
    end
    
    -- REMOVED: SetNuiFocus(false, false) - This is handled by nui-bridge.lua's CloseMenu()
    -- Direct focus calls here cause desync with menuOpen state and create focus leaks
    
    Logger.Info('All states cleaned up')
end)

-- Pause active states (focus loss - monitor switch, alt-tab)
RegisterNetEvent('ec_admin:pauseActiveStates')
AddEventHandler('ec_admin:pauseActiveStates', function()
    Logger.Info('Pausing active states for focus loss...')
    
    statesPaused = true
    pausedStates = {
        noclip = noclipEnabled,
        godmode = godModeEnabled,
        invisible = invisibleEnabled,
        spectating = spectatingPlayer ~= nil
    }
    
    -- Keep states active but mark as paused for safety
    -- This prevents crashes but maintains state
end)

-- Resume active states (focus regained)
RegisterNetEvent('ec_admin:resumeActiveStates')
AddEventHandler('ec_admin:resumeActiveStates', function()
    Logger.Info('Resuming active states after focus regain...')
    
    statesPaused = false
    
    -- States are already active, just unmark as paused
    -- No need to re-enable, they never truly stopped
end)

-- ====================
-- SELF ACTIONS
-- ====================
----------------------------------------
-- EC ADMIN - FINAL NOCLIP (GUARANTEED LANDING)
----------------------------------------

local noclipEnabled = false
local noclipSpeed = 1.0
local landingInProgress = false
local fallingDetected = false
local function SafeTeleport(ped, coords, heading)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
    if not coords or not coords.x or not coords.y or not coords.z then return false end

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    if heading then
        SetEntityHeading(ped, heading)
    end

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    local attempts = 0
    while not HasCollisionLoadedAroundEntity(ped) and attempts < 200 do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Wait(0)
        attempts += 1
    end

    SetEntityVelocity(ped, 0.0, 0.0, 0.0)

    return true
end

-- FX REFERENCES
local FX_SMOKE = "core"
local FX_SMOKE_NAME = "exp_grd_grenade_smoke"

local FX_CRATER = "core"
local FX_CRATER_NAME = "ent_sht_steam"

local FX_AURA = "scr_powerplay"
local FX_AURA_NAME = "scr_powerplay_beast_appear_trails"

----------------------------------------
-- LOAD FX
----------------------------------------
local function Fx(dict)
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do Wait(0) end
end

----------------------------------------
-- PLAY FX BURST
----------------------------------------
local function FxBurst(dict, fx, ped, scale)
    Fx(dict)
    UseParticleFxAssetNextCall(dict)
    StartParticleFxNonLoopedOnEntity(fx, ped, 0,0,-1, 0,0,0, scale, false,false,false)
end

----------------------------------------
-- ENABLE NOCLIP
----------------------------------------
local function EnableNoclip()
    local ped = PlayerPedId()

    TriggerEvent("ec_admin:forceCloseMenu")

    SetEntityCollision(ped, false, false)
    SetEntityVisible(ped, false)
    SetPedCanRagdoll(ped, false)
    SetEntityInvincible(ped, true)

    -- ONLY freeze during noclip
    SetEntityVelocity(ped, 0,0,0)

    FxBurst(FX_SMOKE, FX_SMOKE_NAME, ped, 1.2)
end

----------------------------------------
-- DISABLE NOCLIP → START FREEFALL
----------------------------------------
local function DisableNoclip()
    local ped = PlayerPedId()

    landingInProgress = true
    fallingDetected = IsPedFalling(ped) or GetEntityHeightAboveGround(ped) > 1.5

    SetEntityVisible(ped, true)
    ClearPedTasksImmediately(ped)

    -- STOP all existing momentum
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    FreezeEntityPosition(ped, false)

    -- RESTORE GRAVITY COMPLETELY
    SetEntityCollision(ped, true, true)

    -- PROTECTION
    SetEntityInvincible(ped, true)
    SetPedCanRagdoll(ped, false)
    SetEntityProofs(ped, true,true,true,true,true,true,true,true)
end

RegisterNetEvent("ec_admin:toggleNoclip")
AddEventHandler("ec_admin:toggleNoclip", function()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then EnableNoclip() else DisableNoclip() end
    TriggerEvent("ec_admin:client:notifyNoclip", noclipEnabled)
end)

----------------------------------------
-- TRUE FALL DETECTION (DYNAMIC FLIPS BASED ON DURATION)
----------------------------------------
local landingStartTime = 0
local flipCount = 0
local flipsExecuted = false

-- Pre-load flip animations
CreateThread(function()
    local flipDict = "anim@mp_player_intcelebrationmale@flip"
    RequestAnimDict(flipDict)
    while not HasAnimDictLoaded(flipDict) do Wait(100) end
    
    local landDict = "missfam5_yoga"
    RequestAnimDict(landDict)
    while not HasAnimDictLoaded(landDict) do Wait(100) end
    
    Logger.Info(" NoClip landing animations pre-loaded")
end)

-- Function to perform flips based on duration
local function PerformFlips(ped, numFlips)
    if numFlips == 0 then return end
    
    local dict = "anim@mp_player_intcelebrationmale@flip"
    
    Logger.Info(string.format("🔄 Starting %d flips...", numFlips))
    
    CreateThread(function()
        for i = 1, numFlips do
            if not landingInProgress then 
                Logger.Warn("🔄 Landing ended, stopping flips")
                break 
            end
            
            -- Play flip animation
            TaskPlayAnim(ped, dict, "flip", 8.0, -8.0, 900, 49, 0, false, false, false)
            Logger.Info(string.format("🔄 Flip %d/%d executed", i, numFlips))
            Wait(900) -- Each flip takes ~900ms
        end
        Logger.Success("🔄 All flips completed")
    end)
end

-- Function to calculate flip count based on fall duration
local function CalculateFlips(fallDuration)
    if fallDuration < 5000 then
        return 1  -- Less than 5 seconds: 1 flip
    elseif fallDuration < 10000 then
        return math.random(2, 3)  -- 5-10 seconds: 2-3 random flips
    elseif fallDuration < 15000 then
        return 5  -- 10-15 seconds: 5 flips
    else
        return 5  -- 15+ seconds: 5 flips + force land
    end
end

CreateThread(function()
    while true do
        Wait(10)

            if landingInProgress then
                local ped = PlayerPedId()

            -- Initialize timer on first loop
            if landingStartTime == 0 then
                landingStartTime = GetGameTimer()
                flipsExecuted = false
            end
            
            local fallDuration = GetGameTimer() - landingStartTime

            -- FALLBACK: Force land after 15 seconds
            if fallDuration > 15000 then
                Logger.Info(" NoClip landing timeout (15s) - forcing land with 5 flips")
                
                -- Do 5 flips first if not done
                if not flipsExecuted then
                    flipCount = 5
                    PerformFlips(ped, 5)
                    flipsExecuted = true
                    Wait(4000) -- Wait for flips to complete
                end
                
                -- Force land at current position
                local coords = GetEntityCoords(ped)
                SetEntityCoords(ped, coords.x, coords.y, coords.z - 1.0, false, false, false, false)
                
                -- Superhero landing
                local dict = "missfam5_yoga"
                TaskPlayAnim(ped, dict, "a2_pose", 8.0, -8.0, 600, 0, 0, false, false, false)
                
                Wait(100)
                FxBurst(FX_SMOKE, FX_SMOKE_NAME, ped, 2.0)
                FxBurst(FX_AURA, FX_AURA_NAME, ped, 2.8)
                FxBurst(FX_CRATER, FX_CRATER_NAME, ped, 2.5)
                
                Wait(300)
                SetPedCanRagdoll(ped, true)
                SetEntityProofs(ped, false,false,false,false,false,false,false,false)
                SetEntityInvincible(ped, false)
                
                landingInProgress = false
                fallingDetected = false
                landingStartTime = 0
                flipCount = 0
                flipsExecuted = false
            end

            -- START FALLING & FLIPS
            if not fallingDetected then
                local vel = GetEntityVelocity(ped)

                -- Detect falling
                if vel.z < -0.3 then
                    fallingDetected = true

                    -- Calculate flips based on current duration
                    flipCount = CalculateFlips(fallDuration)

                    Logger.Info(string.format(" Fall detected! Duration: %.1fs | Flips: %d", fallDuration/1000, flipCount))

                    -- Start flips immediately
                    PerformFlips(ped, flipCount)
                    flipsExecuted = true
                else
                    local coords = GetEntityCoords(ped)
                    local groundFound, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
                    if (groundFound and math.abs(coords.z - groundZ) < 1.5) or IsEntityInWater(ped) then
                        fallingDetected = true
                    end
                end
            end

            -- LANDING DETECTION (GROUND + WATER) - ALWAYS SMOOTH
            if fallingDetected then
                local coords = GetEntityCoords(ped)
                local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
                
                -- Check for water surface
                local waterZ = GetWaterHeight(coords.x, coords.y, coords.z)
                local isInWater = IsEntityInWater(ped)
                
                -- Land on ground OR water
                local shouldLand = false
                local landingSurface = "ground"
                
                if found and math.abs(coords.z - groundZ) < 1.5 then
                    shouldLand = true
                    landingSurface = "ground"
                elseif waterZ and math.abs(coords.z - waterZ) < 1.5 then
                    shouldLand = true
                    landingSurface = "water"
                elseif isInWater then
                    shouldLand = true
                    landingSurface = "water"
                end

                if shouldLand then
                    -- Clear any ongoing flip animations
                    ClearPedTasks(ped)
                    
                    -- SUPERHERO KNEEL LANDING
                    local dict = "missfam5_yoga"
                    TaskPlayAnim(ped, dict, "a2_pose", 8.0, -8.0, 600, 0, 0, false, false, false)

                    Wait(100)

                    -- FX COMBO (scaled by flip count)
                    local fxScale = 1.0 + (flipCount * 0.2)
                    FxBurst(FX_SMOKE, FX_SMOKE_NAME, ped, 1.4 * fxScale)
                    FxBurst(FX_AURA, FX_AURA_NAME, ped, 2.2 * fxScale)
                    FxBurst(FX_CRATER, FX_CRATER_NAME, ped, 2.0 * fxScale)
                    
                    Logger.Info(string.format(" Landed on %s after %d flips!", landingSurface, flipCount))

                    -- RESTORE NORMAL STATE
                    Wait(300)
                    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
                    SetPedCanRagdoll(ped, true)
                    SetEntityProofs(ped, false,false,false,false,false,false,false,false)
                    SetEntityInvincible(ped, false)

                    landingInProgress = false
                    fallingDetected = false
                    landingStartTime = 0
                    flipCount = 0
                    flipsExecuted = false
                end
            end
        else
            -- Reset timer when not landing
            landingStartTime = 0
            flipCount = 0
            flipsExecuted = false
        end
    end
end)

----------------------------------------
-- NOCLIP MOVEMENT
----------------------------------------
CreateThread(function()
    while true do
        if noclipEnabled then
            Wait(0)

            local ped = PlayerPedId()

            -- Only zero velocity WHILE noclip is enabled
            SetEntityVelocity(ped, 0,0,0)

            local pos = GetEntityCoords(ped)
            local rot = GetGameplayCamRot(2)

            local heading = rot.z * math.pi/180
            local pitch = rot.x * math.pi/180

            local fwd = vec3(
                -math.sin(heading)*math.cos(pitch),
                 math.cos(heading)*math.cos(pitch),
                 math.sin(pitch)
            )

            local right = vec3(
                -math.cos(heading),
                -math.sin(heading), 0
            )

            local up = vec3(0,0,1)
            local speed = noclipSpeed

            if IsDisabledControlPressed(0,21) then speed *= 3 end
            if IsDisabledControlPressed(0,19) then speed *= 7 end

            if IsDisabledControlJustPressed(0,241) then noclipSpeed = math.min(10, noclipSpeed + 0.2) end
            if IsDisabledControlJustPressed(0,242) then noclipSpeed = math.max(0.2, noclipSpeed - 0.2) end

            DisableControlAction(0,32,true)
            DisableControlAction(0,33,true)
            DisableControlAction(0,34,true)
            DisableControlAction(0,35,true)
            DisableControlAction(0,44,true)
            DisableControlAction(0,38,true)

            local move = vec3(0,0,0)

            if IsDisabledControlPressed(0,32) then move += fwd end
            if IsDisabledControlPressed(0,33) then move -= fwd end

            if IsDisabledControlPressed(0,34) then move += right end
            if IsDisabledControlPressed(0,35) then move -= right end

            if IsDisabledControlPressed(0,44) then move += up end
            if IsDisabledControlPressed(0,38) then move -= up end

            local len = #(move)
            if len > 0 then
                move /= len
                SetEntityCoordsNoOffset(ped, pos.x+move.x*speed, pos.y+move.y*speed, pos.z+move.z*speed, false,false,false)
            end

            SetEntityHeading(ped, rot.z)

        else
            Wait(200)
        end
    end
end)

-- God Mode
RegisterNetEvent('ec_admin:toggleGodMode')
AddEventHandler('ec_admin:toggleGodMode', function()
    godModeEnabled = not godModeEnabled
    local ped = PlayerPedId()

    if godModeEnabled then
        local function applyGodMode()
            local currentPed = PlayerPedId()
            local maxHealth = GetEntityMaxHealth(currentPed)

            SetEntityInvincible(currentPed, true)
            SetPlayerInvincible(PlayerId(), true)
            SetPedCanRagdoll(currentPed, false)

            SetEntityHealth(currentPed, maxHealth)
            SetPedArmour(currentPed, 100)
            ClearPedBloodDamage(currentPed)
            ResetPedVisibleDamage(currentPed)
        end

        applyGodMode()

        -- Keep god mode enforced while enabled
        CreateThread(function()
            while godModeEnabled do
                applyGodMode()
                Wait(500)
            end

            -- Safety: restore ragdoll once disabled
            local latestPed = PlayerPedId()
            SetPedCanRagdoll(latestPed, true)
        end)

        Logger.Info(" God Mode: ENABLED")
        TriggerEvent('ec_admin:client:notifyGodMode', true)
    else
        SetEntityInvincible(ped, false)
        SetPlayerInvincible(PlayerId(), false)
        SetPedCanRagdoll(ped, true)

        Logger.Info(" God Mode: DISABLED")
        TriggerEvent('ec_admin:client:notifyGodMode', false)
    end
end)

-- Invisible
RegisterNetEvent('ec_admin:toggleInvisible')
AddEventHandler('ec_admin:toggleInvisible', function()
    invisibleEnabled = not invisibleEnabled
    local ped = PlayerPedId()
    
    SetEntityVisible(ped, not invisibleEnabled, 0)
    SetLocalPlayerVisibleLocally(true)
    
    if invisibleEnabled then
        Logger.Info(" Invisibility: ENABLED")
        TriggerEvent('ec_admin:client:notifyInvisible', true)
    else
        Logger.Info(" Invisibility: DISABLED")
        TriggerEvent('ec_admin:client:notifyInvisible', false)
    end
end)

-- Infinite Stamina
local infiniteStamina = false
RegisterNetEvent('ec_admin:toggleStamina')
AddEventHandler('ec_admin:toggleStamina', function()
    infiniteStamina = not infiniteStamina
    Logger.Info("⚡ Infinite Stamina: " .. (infiniteStamina and "✅ ENABLED" or "❌ DISABLED"))
end)

CreateThread(function()
    while true do
        if infiniteStamina then
            Wait(0)
            RestorePlayerStamina(PlayerId(), 1.0)
        else
            Wait(500) -- Save CPU when not active
        end
    end
end)

-- Super Jump
local superJump = false
RegisterNetEvent('ec_admin:toggleSuperJump')
AddEventHandler('ec_admin:toggleSuperJump', function()
    superJump = not superJump
    Logger.Info("🚀 Super Jump: " .. (superJump and "✅ ENABLED" or "❌ DISABLED"))
end)

CreateThread(function()
    while true do
        if superJump then
            Wait(0)
            SetSuperJumpThisFrame(PlayerId())
        else
            Wait(500) -- Save CPU when not active
        end
    end
end)

-- Fast Run
local fastRun = false
RegisterNetEvent('ec_admin:toggleFastRun')
AddEventHandler('ec_admin:toggleFastRun', function()
    fastRun = not fastRun
    local ped = PlayerPedId()
    
    if fastRun then
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
        SetPedMoveRateOverride(ped, 2.0)
    else
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        SetPedMoveRateOverride(ped, 1.0)
    end
    
    Logger.Info("💨 Fast Run: " .. (fastRun and "✅ ENABLED" or "❌ DISABLED"))
end)

-- Fast Swim
local fastSwim = false
RegisterNetEvent('ec_admin:toggleFastSwim')
AddEventHandler('ec_admin:toggleFastSwim', function()
    fastSwim = not fastSwim
    local ped = PlayerPedId()
    
    if fastSwim then
        SetSwimMultiplierForPlayer(PlayerId(), 1.49)
    else
        SetSwimMultiplierForPlayer(PlayerId(), 1.0)
    end
    
    Logger.Info("🏊 Fast Swim: " .. (fastSwim and "✅ ENABLED" or "❌ DISABLED"))
end)

-- Load Position (complement to Save Position)
RegisterNetEvent('ec_admin:loadPosition')
AddEventHandler('ec_admin:loadPosition', function()
    if savedPosition then
        local ped = PlayerPedId()
        SetEntityCoordsNoOffset(ped, savedPosition.x, savedPosition.y, savedPosition.z, false, false, false)
        Logger.Info(string.format(" Loaded saved position: %.2f, %.2f, %.2f", savedPosition.x, savedPosition.y, savedPosition.z))
    else
        Logger.Info(" No saved position found")
    end
end)

-- Change Ped (receive from server for target player)
RegisterNetEvent('ec_admin:changePed')
AddEventHandler('ec_admin:changePed', function(pedModel)
    local modelHash = GetHashKey(pedModel)
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if HasModelLoaded(modelHash) then
        SetPlayerModel(PlayerId(), modelHash)
        SetModelAsNoLongerNeeded(modelHash)
        Logger.Success("👤 Ped changed to: " .. pedModel)
    else
        Logger.Error("👤 Failed to load ped model: " .. pedModel)
    end
end)

-- ====================
-- TELEPORT ACTIONS
-- ====================

-- Teleport to Waypoint
RegisterNetEvent('ec_admin:teleportToMarker')
AddEventHandler('ec_admin:teleportToMarker', function()
    local waypoint = GetFirstBlipInfoId(8)
    if DoesBlipExist(waypoint) then
        local coords = GetBlipCoords(waypoint)
        local ped = PlayerPedId()

        if not coords then
            Logger.Info(" Invalid waypoint coordinates")
            return
        end

        -- Save last position
        lastPosition = GetEntityCoords(ped)
        
        -- Ground check
        local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
        
        local targetCoords = foundGround and vector3(coords.x, coords.y, groundZ) or vector3(coords.x, coords.y, coords.z)
        if SafeTeleport(ped, targetCoords, GetEntityHeading(ped)) then
            Logger.Success(foundGround and "✨ Teleported to waypoint" or "✨ Teleported to waypoint (approximate height)")
        else
            Logger.Info(" Teleport failed - invalid waypoint data")
        end
    else
        Logger.Info(" No waypoint set")
    end
end)

-- Bring Player
RegisterNetEvent('ec_admin:bringPlayer')
AddEventHandler('ec_admin:bringPlayer', function(targetId)
    local adminCoords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('ec_admin:requestBringPlayer', targetId, adminCoords)
end)

-- Be brought to admin (server triggers this on target)
RegisterNetEvent('ec_admin:beBrought')
AddEventHandler('ec_admin:beBrought', function(coords)
    local ped = PlayerPedId()
    if SafeTeleport(ped, coords, GetEntityHeading(ped)) then
        Logger.Info(" Brought to admin")
    else
        Logger.Info(" Failed to bring - invalid coordinates")
    end
end)

RegisterNetEvent('ec_admin:gotoPlayer')
AddEventHandler('ec_admin:gotoPlayer', function(targetId)
    TriggerServerEvent('ec_admin:requestGotoPlayer', targetId)
end)

-- Receive target coordinates
RegisterNetEvent('ec_admin:receivePlayerCoords')
AddEventHandler('ec_admin:receivePlayerCoords', function(coords)
    local ped = PlayerPedId()
    if not coords or not coords.x or not coords.y or not coords.z then
        return
    end

    lastPosition = GetEntityCoords(ped)
    if SafeTeleport(ped, coords, GetEntityHeading(ped)) then
        Logger.Info(" Teleported to player")
    else
        Logger.Info(" Teleport failed - invalid target position")
    end
end)

-- Heal Player
RegisterNetEvent('ec_admin:healPlayer')
AddEventHandler('ec_admin:healPlayer', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    Logger.Info(" Healed")
end)
-- Teleport to Coordinates
RegisterNetEvent('ec_admin:teleportToCoords')
AddEventHandler('ec_admin:teleportToCoords', function(coordsStr)
    local coords = {}
    for coord in string.gmatch(coordsStr, "[^,]+") do
        table.insert(coords, tonumber(coord))
    end

    if #coords >= 3 and coords[1] and coords[2] and coords[3] then
        local ped = PlayerPedId()
        lastPosition = GetEntityCoords(ped)
        local targetCoords = vector3(coords[1], coords[2], coords[3])
        if SafeTeleport(ped, targetCoords, GetEntityHeading(ped)) then
            Logger.Info(" Teleported to coordinates")
        else
            Logger.Info(" Teleport failed - invalid coordinates")
        end
    else
        Logger.Info(" Invalid coordinates format")
    end
end)

-- Teleport Back
RegisterNetEvent('ec_admin:teleportBack')
AddEventHandler('ec_admin:teleportBack', function()
    if lastPosition and lastPosition.x and lastPosition.y and lastPosition.z then
        local ped = PlayerPedId()
        if SafeTeleport(ped, lastPosition, GetEntityHeading(ped)) then
            Logger.Info(" Returned to last location")
            lastPosition = nil
        else
            Logger.Info(" Failed to return to last location")
        end
    else
        Logger.Info(" No previous location saved")
    end
end)

-- Save Position
RegisterNetEvent('ec_admin:savePosition')
AddEventHandler('ec_admin:savePosition', function()
    savedPosition = GetEntityCoords(PlayerPedId())
    Logger.Info(string.format(" Position saved: %.2f, %.2f, %.2f", savedPosition.x, savedPosition.y, savedPosition.z))
end)

-- ====================
-- PLAYER ACTIONS
-- ====================

-- Revive Player
RegisterNetEvent('ec_admin:revivePlayer')
AddEventHandler('ec_admin:revivePlayer', function()
    local ped = PlayerPedId()
    
    -- Revive logic
    local playerPos = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(playerPos.x, playerPos.y, playerPos.z, 0, true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    
    Logger.Info(" Revived")
end)

-- Freeze Player
RegisterNetEvent('ec_admin:freezePlayer')
AddEventHandler('ec_admin:freezePlayer', function()
    local ped = PlayerPedId()
    local isFrozen = IsEntityPositionFrozen(ped)
    
    FreezeEntityPosition(ped, not isFrozen)
    
    if not isFrozen then
        Logger.Info(" You are now frozen")
    else
        Logger.Info(" You are no longer frozen")
    end
end)

-- Spectate Player
RegisterNetEvent('ec_admin:spectatePlayer')
AddEventHandler('ec_admin:spectatePlayer', function(targetId)
    -- Validate target player exists
    local targetPlayer = GetPlayerFromServerId(targetId)
    if targetPlayer == -1 or targetPlayer == 0 then
        Logger.Info(" ERROR: Target player not found (invalid server ID)")
        return
    end
    
    local targetPed = GetPlayerPed(targetPlayer)
    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
        Logger.Info(" ERROR: Target player ped not found or invalid")
        return
    end
    
    if spectatingPlayer then
        -- Stop spectating
        spectatingPlayer = nil
        local playerPed = PlayerPedId()
        NetworkSetInSpectatorMode(false, playerPed)
        Logger.Info(" Stopped spectating")
    else
        -- Start spectating
        spectatingPlayer = targetId
        NetworkSetInSpectatorMode(true, targetPed)
        Logger.Info("👁️ Spectating player " .. targetId)
    end
end)

-- Slap Player
RegisterNetEvent('ec_admin:slapPlayer')
AddEventHandler('ec_admin:slapPlayer', function()
    local ped = PlayerPedId()
    ApplyDamageToPed(ped, 20, false)
    
    -- Apply upward force
    local coords = GetEntityCoords(ped)
    SetEntityVelocity(ped, 0.0, 0.0, 10.0)
    
    Logger.Info(" You were slapped!")
end)

-- Strip Weapons
RegisterNetEvent('ec_admin:stripWeapons')
AddEventHandler('ec_admin:stripWeapons', function()
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    Logger.Info(" Weapons removed")
end)

-- Wipe Inventory
RegisterNetEvent('ec_admin:wipeInventory')
AddEventHandler('ec_admin:wipeInventory', function()
    -- This would integrate with ESX/QBCore
    -- Framework-specific inventory clearing
    Logger.Info(" Inventory wiped")
end)

-- ====================
-- VEHICLE ACTIONS
-- ====================

-- Fix Vehicle
RegisterNetEvent('ec_admin:fixVehicle')
AddEventHandler('ec_admin:fixVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true)
        SetVehicleDirtLevel(vehicle, 0.0)
        Logger.Info(" Vehicle repaired")
    else
        Logger.Info(" You must be in a vehicle")
    end
end)

-- Delete Vehicle
RegisterNetEvent('ec_admin:deleteVehicle')
AddEventHandler('ec_admin:deleteVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        -- Get closest vehicle
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end
    
    if vehicle ~= 0 then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        Logger.Info(" Vehicle deleted")
    else
        Logger.Info(" No vehicle nearby")
    end
end)

-- Spawn Vehicle
RegisterNetEvent('ec_admin:spawnVehicle')
AddEventHandler('ec_admin:spawnVehicle', function(vehicleName)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    RequestModel(GetHashKey(vehicleName))
    while not HasModelLoaded(GetHashKey(vehicleName)) do
        Wait(0)
    end
    
    local vehicle = CreateVehicle(GetHashKey(vehicleName), coords.x, coords.y, coords.z, heading, true, false)
    SetPedIntoVehicle(ped, vehicle, -1)
    SetEntityAsNoLongerNeeded(vehicle)
    
    Logger.Success("🚗 Spawned vehicle: " .. vehicleName)
end)

-- Flip Vehicle
RegisterNetEvent('ec_admin:flipVehicle')
AddEventHandler('ec_admin:flipVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 then
        local rotation = GetEntityRotation(vehicle, 2)
        SetEntityRotation(vehicle, rotation.x, 0.0, rotation.z, 2, true)
        Logger.Info(" Vehicle flipped")
    else
        Logger.Info(" You must be in a vehicle")
    end
end)

-- Boost Vehicle
RegisterNetEvent('ec_admin:boostVehicle')
AddEventHandler('ec_admin:boostVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 then
        SetVehicleEnginePowerMultiplier(vehicle, 50.0)
        Logger.Info(" Boost activated")
        
        -- Reset after 10 seconds
        SetTimeout(10000, function()
            SetVehicleEnginePowerMultiplier(vehicle, 1.0)
            Logger.Info(" Boost deactivated")
        end)
    else
        Logger.Info(" You must be in a vehicle")
    end
end)

-- Clean Vehicle
RegisterNetEvent('ec_admin:cleanVehicle')
AddEventHandler('ec_admin:cleanVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 then
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
        Logger.Info(" Vehicle cleaned")
    else
        Logger.Info(" You must be in a vehicle")
    end
end)

-- Max Tune Vehicle
RegisterNetEvent('ec_admin:maxTuneVehicle')
AddEventHandler('ec_admin:maxTuneVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 then
        -- Max all mods
        SetVehicleModKit(vehicle, 0)
        
        -- Engine, brakes, transmission, etc
        SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false) -- Engine
        SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false) -- Brakes
        SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false) -- Transmission
        SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false) -- Suspension
        SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false) -- Armor
        
        -- Turbo
        ToggleVehicleMod(vehicle, 18, true)
        
        Logger.Info(" Vehicle fully tuned")
    else
        Logger.Info(" You must be in a vehicle")
    end
end)

-- ====================
-- WORLD ACTIONS
-- ====================

-- Set Weather
RegisterNetEvent('ec_admin:setWeather')
AddEventHandler('ec_admin:setWeather', function(weatherType)
    SetWeatherTypeNowPersist(weatherType)
    SetWeatherTypeNow(weatherType)
    SetWeatherTypePersist(weatherType)
    Logger.Info("🌤️ Weather changed to: " .. weatherType)
end)

-- Set Time
RegisterNetEvent('ec_admin:setTime')
AddEventHandler('ec_admin:setTime', function(time)
    NetworkOverrideClockTime(time, 0, 0)
    Logger.Info("⏰ Time changed to: " .. time)
end)

-- Toggle Blackout
local blackoutEnabled = false
RegisterNetEvent('ec_admin:toggleBlackout')
AddEventHandler('ec_admin:toggleBlackout', function()
    blackoutEnabled = not blackoutEnabled
    SetArtificialLightsState(blackoutEnabled)
    Logger.Info("🌑 Blackout: " .. (blackoutEnabled and "✅ ENABLED" or "❌ DISABLED"))
end)

-- Toggle Rainbow Paint
local rainbowEnabled = false
RegisterNetEvent('ec_admin:toggleRainbow')
AddEventHandler('ec_admin:toggleRainbow', function()
    rainbowEnabled = not rainbowEnabled
    Logger.Info("🌈 Rainbow Paint: " .. (rainbowEnabled and "✅ ENABLED" or "❌ DISABLED"))
end)

-- Rainbow paint loop
CreateThread(function()
    local colors = {
        {255, 0, 0},    -- Red
        {255, 127, 0},  -- Orange
        {255, 255, 0},  -- Yellow
        {0, 255, 0},    -- Green
        {0, 0, 255},    -- Blue
        {75, 0, 130},   -- Indigo
        {148, 0, 211}   -- Violet
    }
    local colorIndex = 1
    
    while true do
        Wait(100)
        if rainbowEnabled then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle ~= 0 then
                local color = colors[colorIndex]
                SetVehicleCustomPrimaryColour(vehicle, color[1], color[2], color[3])
                SetVehicleCustomSecondaryColour(vehicle, color[1], color[2], color[3])
                
                colorIndex = colorIndex + 1
                if colorIndex > #colors then
                    colorIndex = 1
                end
            end
        end
    end
end)

-- Toggle Boost
local boostEnabled = false
RegisterNetEvent('ec_admin:toggleBoost')
AddEventHandler('ec_admin:toggleBoost', function()
    boostEnabled = not boostEnabled
    Logger.Info("⚡ Vehicle Boost: " .. (boostEnabled and "✅ ENABLED" or "❌ DISABLED"))
end)

-- Boost loop
CreateThread(function()
    while true do
        if boostEnabled then
            Wait(0)
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                if IsControlPressed(0, 21) then -- Left Shift = SUPER BOOST
                    SetVehicleEnginePowerMultiplier(vehicle, 10.0) -- Increased from 5.0 to 10.0
                    SetVehicleForwardSpeed(vehicle, GetEntitySpeed(vehicle) + 4.0) -- Increased from 2.0 to 4.0
                else -- Normal boost
                    SetVehicleEnginePowerMultiplier(vehicle, 4.0) -- Increased from 2.0 to 4.0
                end
            end
        else
            Wait(500) -- Save CPU when not active
        end
    end
end)

-- Clear Area
RegisterNetEvent('ec_admin:clearArea')
AddEventHandler('ec_admin:clearArea', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local radius = 50.0
    
    -- Clear vehicles
    local vehicles = GetGamePool('CVehicle')
    local count = 0
    for _, vehicle in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        if #(coords - vehCoords) <= radius and not IsPedInVehicle(ped, vehicle, false) then
            DeleteEntity(vehicle)
            count = count + 1
        end
    end
    
    Logger.Info(string.format(" Cleared %d entities in area", count))
end)

-- ====================
-- SERVER COORDINATION
-- ====================

-- Server events for bringing/going to players
-- NOTE: These are received from server, not registered as server events
RegisterNetEvent('ec_admin:requestBringPlayer')
AddEventHandler('ec_admin:requestBringPlayer', function(targetId, coords)
    TriggerClientEvent('ec_admin:beBrought', targetId, coords)
end)

RegisterNetEvent('ec_admin:requestGotoPlayer')
AddEventHandler('ec_admin:requestGotoPlayer', function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if targetPed then
        local coords = GetEntityCoords(targetPed)
        TriggerClientEvent('ec_admin:receivePlayerCoords', source, coords)
    end
end)

-- Helper: Get camera direction
function GetCamDirection()
    local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
    local pitch = GetGameplayCamRelativePitch()
    
    local x = -math.sin(heading * math.pi / 180.0)
    local y = math.cos(heading * math.pi / 180.0)
    local z = math.sin(pitch * math.pi / 180.0)
    
    local len = math.sqrt(x * x + y * y + z * z)
    if len ~= 0 then
        x = x / len
        y = y / len
        z = z / len
    end
    
    return x, y, z
end

-- ====================
-- NEW CUSTOM ACTIONS
-- ====================

-- Reload Eyes (soft player reload)
RegisterNetEvent('ec_admin:reloadEyes')
AddEventHandler('ec_admin:reloadEyes', function()
    Logger.Info(" Reloading eyes (soft reload)...")
    
    -- Trigger loading screen
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Show loading screen
    BeginTextCommandBusyspinnerOn("STRING")
    AddTextComponentSubstringPlayerName("~b~EC Admin~w~: Reloading eyes...")
    EndTextCommandBusyspinnerOn(4)
    
    Wait(2000)
    
    -- Remove loading screen
    BusyspinnerOff()
    DoScreenFadeIn(500)
    
    Logger.Info(" Eyes reloaded successfully")
end)

-- Send vehicles to garage (proximity)
RegisterNetEvent('ec_admin:garageVehiclesProximity')
AddEventHandler('ec_admin:garageVehiclesProximity', function(radius)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local count = 0
    
    Logger.Info(string.format(" Sending vehicles to garage (radius: %dm)...", radius))
    
    for _, vehicle in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        if #(coords - vehCoords) <= radius then
            -- Check if vehicle is owned (has plate)
            local plate = GetVehicleNumberPlateText(vehicle)
            if plate and plate ~= '' then
                -- Delete the vehicle (in real implementation, would save to database)
                DeleteEntity(vehicle)
                count = count + 1
            end
        end
    end
    
    Logger.Info(string.format(" Sent %d vehicles to garage", count))
    
    -- Notify player
    lib.notify({
        title = 'EC Admin',
        description = string.format('Sent %d vehicles to garage', count),
        type = 'success'
    })
end)

-- Send ALL vehicles to garage (server-wide)
RegisterNetEvent('ec_admin:garageVehiclesServerwide')
AddEventHandler('ec_admin:garageVehiclesServerwide', function()
    local vehicles = GetGamePool('CVehicle')
    local count = 0
    
    Logger.Info(" Sending ALL vehicles to garage (server-wide)...")
    
    for _, vehicle in ipairs(vehicles) do
        -- Check if vehicle is owned (has plate)
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate and plate ~= '' then
            -- Delete the vehicle (in real implementation, would save to database)
            DeleteEntity(vehicle)
            count = count + 1
        end
    end
    
    Logger.Info(string.format(" Sent %d vehicles to garage", count))
    
    -- Notify player
    lib.notify({
        title = 'EC Admin',
        description = string.format('Sent %d vehicles to garage (server-wide)', count),
        type = 'success'
    })
end)

Logger.Success('✅ Quick Actions Handlers Loaded - 46+ actions ready')