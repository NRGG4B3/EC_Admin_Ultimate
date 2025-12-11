--[[
    EC Admin Ultimate - AI Behavior Tracker (Client)
    Tracks player behavior for AI detection analysis
]]--

local AI_ENABLED = true -- Will be synced from server
local trackingEnabled = false
local lastPosition = nil
local lastUpdateTime = 0
local combatData = {
    shots = 0,
    hits = 0,
    headshots = 0,
    lastShot = 0
}

-- ============================================================================
-- MOVEMENT TRACKING
-- ============================================================================

CreateThread(function()
    while true do
        Wait(1000) -- Update every second
        
        if trackingEnabled and AI_ENABLED then
            local ped = PlayerPedId()
            
            if DoesEntityExist(ped) then
                local currentPos = GetEntityCoords(ped)
                local currentTime = GetGameTimer()
                
                if lastPosition then
                    -- Calculate distance and speed
                    local distance = #(currentPos - lastPosition)
                    local timeDiff = (currentTime - lastUpdateTime) / 1000 -- seconds
                    local speed = distance / timeDiff -- m/s
                    
                    -- Check if in vehicle
                    local vehicle = nil
                    if IsPedInAnyVehicle(ped, false) then
                        vehicle = GetVehiclePedIsIn(ped, false)
                    end
                    
                    -- Send to server for analysis
                    TriggerServerEvent('ec_ai:trackMovement', {
                        coords = currentPos,
                        speed = speed,
                        vehicle = vehicle ~= nil,
                        onFoot = not IsPedInAnyVehicle(ped, false),
                        timestamp = GetGameTimer()
                    })
                end
                
                lastPosition = currentPos
                lastUpdateTime = currentTime
            end
        end
    end
end)

-- ============================================================================
-- COMBAT TRACKING
-- ============================================================================

-- Track shooting
CreateThread(function()
    while true do
        Wait(0)
        
        if trackingEnabled and AI_ENABLED then
            local ped = PlayerPedId()
            
            if IsPedShooting(ped) then
                local weapon = GetSelectedPedWeapon(ped)
                local currentTime = GetGameTimer()
                
                -- Track shot
                combatData.shots = combatData.shots + 1
                
                -- Calculate fire rate
                local fireRate = 0
                if combatData.lastShot > 0 then
                    local timeDiff = (currentTime - combatData.lastShot) / 1000
                    fireRate = 1 / timeDiff -- shots per second
                end
                combatData.lastShot = currentTime
                
                -- Check if hit target
                local target, hit = GetEntityPlayerIsFreeAimingAt(PlayerId())
                if hit and DoesEntityExist(target) then
                    combatData.hits = combatData.hits + 1
                    
                    -- Check if headshot (simplified)
                    local targetPed = target
                    if IsPedAPlayer(targetPed) then
                        local boneIndex = GetPedLastDamageBone(targetPed)
                        if boneIndex == 31086 then -- Head bone
                            combatData.headshots = combatData.headshots + 1
                        end
                    end
                end
                
                -- Send data periodically (every 10 shots)
                if combatData.shots % 10 == 0 then
                    local accuracy = combatData.hits / combatData.shots
                    local headshotRatio = combatData.headshots / math.max(1, combatData.hits)
                    
                    TriggerServerEvent('ec_ai:trackCombat', {
                        weapon = weapon,
                        fireRate = fireRate,
                        accuracy = accuracy,
                        headshotRatio = headshotRatio,
                        shots = combatData.shots,
                        hits = combatData.hits,
                        headshots = combatData.headshots,
                        timestamp = GetGameTimer()
                    })
                end
            end
        end
    end
end)

-- ============================================================================
-- DAMAGE TRACKING (for god mode detection)
-- ============================================================================

local damageTaken = 0
local shotsTaken = 0
local lastDamageTime = 0

CreateThread(function()
    while true do
        Wait(100)
        
        if trackingEnabled and AI_ENABLED then
            local ped = PlayerPedId()
            
            if DoesEntityExist(ped) then
                -- Check if player is being shot at
                if IsPedBeingStunned(ped) or HasEntityBeenDamagedByAnyPed(ped) then
                    shotsTaken = shotsTaken + 1
                    
                    -- Check if actually took damage
                    local currentHealth = GetEntityHealth(ped)
                    if currentHealth < 200 then -- Less than max health
                        damageTaken = damageTaken + 1
                    end
                    
                    lastDamageTime = GetGameTimer()
                    
                    ClearEntityLastDamageEntity(ped)
                end
                
                -- Send data periodically (every 30 seconds)
                local currentTime = GetGameTimer()
                if lastDamageTime > 0 and (currentTime - lastDamageTime) > 30000 then
                    if shotsTaken > 0 then
                        TriggerServerEvent('ec_ai:trackCombat', {
                            shotsTaken = shotsTaken,
                            damageTaken = damageTaken,
                            timeWindow = currentTime - lastDamageTime,
                            timestamp = GetGameTimer()
                        })
                    end
                    
                    -- Reset
                    shotsTaken = 0
                    damageTaken = 0
                    lastDamageTime = 0
                end
            end
        end
    end
end)

-- ============================================================================
-- NOCLIP / COLLISION DETECTION
-- ============================================================================

CreateThread(function()
    while true do
        Wait(500)
        
        if trackingEnabled and AI_ENABLED then
            local ped = PlayerPedId()
            
            if DoesEntityExist(ped) then
                -- Check for collision bypass
                local coords = GetEntityCoords(ped)
                local groundZ = 0.0
                local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
                
                if foundGround then
                    local heightAboveGround = coords.z - groundZ
                    
                    -- If player is significantly above ground without flying vehicle
                    if heightAboveGround > 5.0 and not IsPedInAnyVehicle(ped, false) and not IsPedInParachuteFreeFall(ped) then
                        local verticalSpeed = GetEntitySpeed(ped)
                        
                        TriggerServerEvent('ec_ai:trackMovement', {
                            coords = coords,
                            verticalSpeed = verticalSpeed,
                            heightAboveGround = heightAboveGround,
                            collisionMisses = 1,
                            terrainIgnore = true,
                            timestamp = GetGameTimer()
                        })
                    end
                end
            end
        end
    end
end)

-- ============================================================================
-- TELEPORT DETECTION
-- ============================================================================

local lastTeleportCheck = vector3(0, 0, 0)
local lastTeleportTime = 0

CreateThread(function()
    while true do
        Wait(100)
        
        if trackingEnabled and AI_ENABLED then
            local ped = PlayerPedId()
            
            if DoesEntityExist(ped) then
                local currentPos = GetEntityCoords(ped)
                local currentTime = GetGameTimer()
                
                if lastTeleportCheck and lastTeleportCheck ~= vector3(0, 0, 0) then
                    local distance = #(currentPos - lastTeleportCheck)
                    local timeInterval = currentTime - lastTeleportTime
                    
                    -- If moved more than 100m in less than 200ms
                    if distance > 100 and timeInterval < 200 then
                        TriggerServerEvent('ec_ai:trackMovement', {
                            coords = currentPos,
                            distanceTraveled = distance,
                            timeInterval = timeInterval,
                            possibleTeleport = true,
                            timestamp = GetGameTimer()
                        })
                    end
                end
                
                lastTeleportCheck = currentPos
                lastTeleportTime = currentTime
            end
        end
    end
end)

-- ============================================================================
-- ENABLE/DISABLE TRACKING
-- ============================================================================

RegisterNetEvent('ec_ai:setTracking', function(enabled)
    trackingEnabled = enabled
    
    -- Ensure Logger is available
    if Logger and Logger.Info then
        if enabled then
            Logger.Info('✅ AI Tracking enabled')
        else
            Logger.Info('⏹️ AI Tracking disabled')
        end
    else
        print("^2[EC Admin]^7 " .. (enabled and "✓ AI Tracking enabled" or "⏹️ AI Tracking disabled") .. "^0")
    end
end)

-- ============================================================================
-- AUTO-START TRACKING
-- ============================================================================

CreateThread(function()
    Wait(5000) -- Wait for player to fully load
    
    -- Request tracking status from server
    TriggerServerEvent('ec_ai:requestTrackingStatus')
    
    -- Enable by default
    trackingEnabled = true
    
    -- Ensure Logger is available
    if Logger and Logger.Success then
        Logger.Success('✅ AI Behavior Tracker initialized')
    else
        print("^2[EC Admin]^7 ✓ AI Behavior Tracker initialized^0")
    end
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('SetTracking', function(enabled)
    trackingEnabled = enabled
end)

exports('GetCombatStats', function()
    return combatData
end)
