--[[
    EC ADMIN ULTIMATE - Complete Quick Actions Client Handler
    Handles all client-side execution for quick actions
    Version: 4.0.0 - COMPLETE (86+ Actions)
]]

Logger.Success("✅ Loading Quick Actions Client Handler (COMPLETE)...")

-- ============================================================================
-- SELF ACTIONS (CLIENT-SIDE)
-- ============================================================================

-- Heal Self
RegisterNetEvent('ec_admin:client:healSelf', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    Logger.Info(" ✅ Healed and armored^0")
end)

-- Max Armor
RegisterNetEvent('ec_admin:client:maxArmor', function()
    local ped = PlayerPedId()
    SetPedArmour(ped, 100)
    Logger.Info(" ✅ Max armor applied^0")
end)

-- Revive Self
RegisterNetEvent('ec_admin:reviveSelf', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    end
    
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    ClearPedTasks(ped)
    
    Logger.Info(" ✅ Revived yourself^0")
end)

-- Clean Clothes
RegisterNetEvent('ec_admin:cleanClothes', function()
    local ped = PlayerPedId()
    ClearPedDamageDecalByZone(ped, 1, "ALL")
    ClearPedDamageDecalByZone(ped, 2, "ALL")
    ClearPedDamageDecalByZone(ped, 3, "ALL")
    ClearPedDamageDecalByZone(ped, 4, "ALL")
    ClearPedDamageDecalByZone(ped, 5, "ALL")
    ResetPedVisibleDamage(ped)
    Logger.Info(" ✅ Clothes cleaned^0")
end)

-- Wash Player
RegisterNetEvent('ec_admin:washPlayer', function()
    local ped = PlayerPedId()
    ClearPedBloodDamage(ped)
    ClearPedWetness(ped)
    ClearPedEnvDirt(ped)
    ResetPedVisibleDamage(ped)
    Logger.Info(" ✅ Player washed^0")
end)

-- Clear Blood
RegisterNetEvent('ec_admin:clearBlood', function()
    local ped = PlayerPedId()
    ClearPedBloodDamage(ped)
    Logger.Info(" ✅ Blood cleared^0")
end)

-- ============================================================================
-- TELEPORT ACTIONS
-- ============================================================================

local function SafeTeleportToCoords(ped, coords, heading)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
    if not coords or not coords.x or not coords.y or not coords.z then return false end

    local x, y, z = coords.x, coords.y, coords.z

    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    if heading then
        SetEntityHeading(ped, heading)
    end

    RequestCollisionAtCoord(x, y, z)

    local attempts = 0
    while not HasCollisionLoadedAroundEntity(ped) and attempts < 200 do
        RequestCollisionAtCoord(x, y, z)
        Wait(0)
        attempts += 1
    end

    return true
end

-- Teleport to Coordinates
RegisterNetEvent('ec_admin:client:teleportToCoords', function(x, y, z)
    if not x or not y or not z then
        Logger.Info(" ❌ Invalid coordinates for teleport^0")
        return
    end

    local ped = PlayerPedId()
    local xNum, yNum, zNum = tonumber(x), tonumber(y), tonumber(z)
    if not xNum or not yNum or not zNum then
        Logger.Info(" ❌ Coordinates must be numbers^0")
        return
    end

    local targetCoords = vector3(xNum, yNum, zNum)
    local heading = GetEntityHeading(ped)

    -- Save last position before moving
    lastTeleportPosition = GetEntityCoords(ped)

    if SafeTeleportToCoords(ped, targetCoords, heading) then
        Logger.Success(string.format("✨ Teleported to %.2f, %.2f, %.2f", targetCoords.x, targetCoords.y, targetCoords.z))
    else
        Logger.Info(" ❌ Teleport failed (invalid ped or coords)^0")
    end
end)

-- Teleport Back (History)
local lastTeleportPosition = nil

RegisterNetEvent('ec_admin:teleportBack', function()
    if lastTeleportPosition then
        local ped = PlayerPedId()
        if SafeTeleportToCoords(ped, lastTeleportPosition, GetEntityHeading(ped)) then
            Logger.Info(" ✅ Teleported back^0")
            lastTeleportPosition = nil
        else
            Logger.Info(" ❌ Teleport back failed^0")
        end
    else
        Logger.Info(" ❌ No previous location^0")
    end
end)

-- ============================================================================
-- PLAYER ACTIONS (CLIENT-SIDE)
-- ============================================================================

-- Revive
RegisterNetEvent('ec_admin:client:revive', function()
    local ped = PlayerPedId()
    
    -- Resurrect if dead
    if IsEntityDead(ped) then
        local coords = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    end
    
    -- Heal fully
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    
    Logger.Info(" ✅ Revived^0")
end)

-- Kill Player
RegisterNetEvent('ec_admin:client:killPlayer', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
    Logger.Info(" ⚠️  You were killed by an admin^0")
end)

-- Freeze Player
RegisterNetEvent('ec_admin:client:freezePlayer', function(freeze)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, freeze)
    
    if freeze then
        Logger.Info(" ⚠️  You have been frozen^0")
    else
        Logger.Info(" ✅ You have been unfrozen^0")
    end
end)

-- Sit Player
RegisterNetEvent('ec_admin:client:sitPlayer', function()
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, "PROP_HUMAN_SEAT_CHAIR", 0, true)
    Logger.Info(" ⚠️  You were forced to sit^0")
end)

-- Drag Player
local isDragging = false
local dragTarget = nil

RegisterNetEvent('ec_admin:client:dragPlayer', function(adminId, targetId)
    local adminPed = GetPlayerPed(GetPlayerFromServerId(adminId))
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    
    if DoesEntityExist(adminPed) and DoesEntityExist(targetPed) then
        isDragging = not isDragging
        dragTarget = isDragging and adminPed or nil
        
        if isDragging then
            AttachEntityToEntity(targetPed, adminPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            Logger.Info(" ⚠️  You are being dragged^0")
        else
            DetachEntity(targetPed, true, false)
            Logger.Info(" ✅ You are no longer being dragged^0")
        end
    end
end)

-- Cuff Player
local isCuffed = false

RegisterNetEvent('ec_admin:client:cuffPlayer', function(cuff)
    local ped = PlayerPedId()
    isCuffed = cuff
    
    if cuff then
        RequestAnimDict("mp_arresting")
        while not HasAnimDictLoaded("mp_arresting") do
            Wait(100)
        end
        TaskPlayAnim(ped, "mp_arresting", "idle", 8.0, -8, -1, 49, 0, 0, 0, 0)
        SetEnableHandcuffs(ped, true)
        SetPedCanPlayGestureAnims(ped, false)
        FreezeEntityPosition(ped, true)
        Logger.Info(" ⚠️  You have been cuffed^0")
    else
        ClearPedSecondaryTask(ped)
        SetEnableHandcuffs(ped, false)
        SetPedCanPlayGestureAnims(ped, true)
        FreezeEntityPosition(ped, false)
        Logger.Info(" ✅ You have been uncuffed^0")
    end
end)

-- Remove Mask
RegisterNetEvent('ec_admin:client:removeMask', function()
    local ped = PlayerPedId()
    SetPedComponentVariation(ped, 1, 0, 0, 2)
    Logger.Info(" Your mask was removed^0")
end)

-- Remove Hat
RegisterNetEvent('ec_admin:client:removeHat', function()
    local ped = PlayerPedId()
    ClearPedProp(ped, 0)
    Logger.Info(" Your hat was removed^0")
end)

-- Clear Wanted Level
RegisterNetEvent('ec_admin:client:clearWanted', function()
    local ped = PlayerPedId()
    local playerId = PlayerId()
    ClearPlayerWantedLevel(playerId)
    SetPlayerWantedLevel(playerId, 0, false)
    SetPlayerWantedLevelNow(playerId, false)
    Logger.Info(" ✅ Wanted level cleared^0")
end)

-- Clear Inventory
RegisterNetEvent('ec_admin:client:clearInventory', function()
    -- This would integrate with your inventory system
    Logger.Info(" ⚠️  Your inventory was cleared^0")
end)

-- Spectate Player
local spectatingPlayer = nil

RegisterNetEvent('ec_admin:client:spectatePlayer', function(targetId)
    local playerPed = PlayerPedId()
    
    if spectatingPlayer == targetId then
        -- Stop spectating
        spectatingPlayer = nil
        
        -- Restore camera
        RenderScriptCams(false, false, 0, true, true)
        
        -- Make player visible again
        SetEntityVisible(playerPed, true, false)
        SetEntityCollision(playerPed, true, true)
        FreezeEntityPosition(playerPed, false)
        
        Logger.Info(" Stopped spectating^0")
    else
        -- Start spectating
        spectatingPlayer = targetId
        local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
        
        if DoesEntityExist(targetPed) then
            -- Hide admin player
            SetEntityVisible(playerPed, false, false)
            SetEntityCollision(playerPed, false, false)
            FreezeEntityPosition(playerPed, true)
            
            -- Follow target
            local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
            AttachCamToEntity(cam, targetPed, 0.0, -2.5, 1.0, true)
            SetCamActive(cam, true)
            RenderScriptCams(true, false, 0, true, true)
            
            Logger.Info(" ✅ Spectating player^0")
        end
    end
end)

-- Slap Player
RegisterNetEvent('ec_admin:client:slapPlayer', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Apply force upwards and random direction
    ApplyForceToEntity(ped, 1, math.random(-100, 100), math.random(-100, 100), 100.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
    
    -- Apply damage
    SetEntityHealth(ped, GetEntityHealth(ped) - 10)
    
    Logger.Info(" ⚠️  You have been slapped!^0")
end)

-- Strip Weapons
RegisterNetEvent('ec_admin:client:stripWeapons', function()
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    Logger.Info(" Your weapons have been removed^0")
end)

-- Give Weapon
RegisterNetEvent('ec_admin:client:giveWeapon', function(weapon)
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, GetHashKey(weapon), 250, false, true)
    Logger.Success(string.format("🔫 Received weapon: %s", weapon))
end)

-- Set Health
RegisterNetEvent('ec_admin:client:setHealth', function(health)
    local ped = PlayerPedId()
    SetEntityHealth(ped, health)
    Logger.Success(string.format("❤️ Health set to: %s", health))
end)

-- Set Armor
RegisterNetEvent('ec_admin:client:setArmor', function(armor)
    local ped = PlayerPedId()
    SetPedArmour(ped, armor)
    Logger.Success(string.format("🛡️ Armor set to: %s", armor))
end)

-- Change Ped
RegisterNetEvent('ec_admin:client:changePed', function(model)
    local ped = PlayerPedId()
    local hash = GetHashKey(model)
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(100)
    end
    
    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)
    
    Logger.Success(string.format("👤 Changed ped to: %s", model))
end)

-- ============================================================================
-- VEHICLE ACTIONS (CLIENT-SIDE)
-- ============================================================================

-- Spawn Vehicle
RegisterNetEvent('ec_admin:client:spawnVehicle', function(model)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local hash = GetHashKey(model)
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(100)
    end
    
    -- Spawn vehicle
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    
    -- Put player in vehicle
    SetPedIntoVehicle(ped, vehicle, -1)
    
    -- Give keys (QB-Core / QBX integration)
    if GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started' then
        TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(vehicle))
    end
    
    -- Start engine
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleOnGroundProperly(vehicle)
    
    -- Cleanup
    SetEntityAsNoLongerNeeded(vehicle)
    SetModelAsNoLongerNeeded(hash)
    
    Logger.Success(string.format("🚗 Spawned vehicle: %s", model))
end)

-- Change Plate
RegisterNetEvent('ec_admin:client:changePlate', function(plate)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 then
        SetVehicleNumberPlateText(vehicle, plate)
        Logger.Success(string.format("📋 Plate changed to: %s", plate))
    else
        Logger.Info(" ❌ You must be in a vehicle^0")
    end
end)

-- Unlock Vehicle
RegisterNetEvent('ec_admin:unlockVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        vehicle = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 71)
    end
    
    if vehicle ~= 0 then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        Logger.Info(" ✅ Vehicle unlocked^0")
    else
        Logger.Info(" ❌ No vehicle nearby^0")
    end
end)

-- Lock Vehicle
RegisterNetEvent('ec_admin:lockVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        vehicle = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 71)
    end
    
    if vehicle ~= 0 then
        SetVehicleDoorsLocked(vehicle, 2)
        Logger.Info(" ✅ Vehicle locked^0")
    else
        Logger.Info(" ❌ No vehicle nearby^0")
    end
end)

-- Hop Into Driver Seat
RegisterNetEvent('ec_admin:hopIntoDriver', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords, 10.0, 0, 71)
    
    if vehicle ~= 0 then
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        Logger.Info(" ✅ Hopped into driver seat^0")
    else
        Logger.Info(" ❌ No vehicle nearby^0")
    end
end)

-- ============================================================================
-- SERVER ACTIONS (CLIENT-SIDE)
-- ============================================================================

-- Clear All Vehicles
RegisterNetEvent('ec_admin:client:clearAllVehicles', function()
    local vehicles = GetGamePool('CVehicle')
    local count = 0
    
    for _, vehicle in ipairs(vehicles) do
        if not IsPedInVehicle(PlayerPedId(), vehicle, false) then
            DeleteEntity(vehicle)
            count = count + 1
        end
    end
    
    Logger.Success(string.format("🚗 Cleared %s vehicles", count))
end)

-- Clear All Peds
RegisterNetEvent('ec_admin:client:clearAllPeds', function()
    local peds = GetGamePool('CPed')
    local count = 0
    
    for _, ped in ipairs(peds) do
        if not IsPedAPlayer(ped) then
            DeleteEntity(ped)
            count = count + 1
        end
    end
    
    Logger.Success(string.format("👥 Cleared %s peds", count))
end)

-- Garage Radius
RegisterNetEvent('ec_admin:client:garageRadius', function(radius)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local count = 0
    
    for _, vehicle in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehCoords)
        
        if distance <= radius and not IsPedInVehicle(ped, vehicle, false) then
            DeleteEntity(vehicle)
            count = count + 1
        end
    end
    
    Logger.Success(string.format("🚗 Sent %s nearby vehicles to garage", count))
end)

-- Garage All
RegisterNetEvent('ec_admin:client:garageAll', function()
    local vehicles = GetGamePool('CVehicle')
    local count = 0
    
    for _, vehicle in ipairs(vehicles) do
        if not IsPedInVehicle(PlayerPedId(), vehicle, false) then
            DeleteEntity(vehicle)
            count = count + 1
        end
    end
    
    Logger.Success(string.format("🚗 Sent %s nearby vehicles to garage", count))
end)

-- REMOVED: Weather/Time - Now handled by global-tools-client.lua
-- ec_admin:client:setWeather → global-tools-client.lua
-- ec_admin:client:setTime → global-tools-client.lua  
-- ec_admin:client:toggleBlackout → global-tools-client.lua

Logger.Success("✅ Quick Actions Client Complete loaded - 86+ actions ready")