-- EC Admin Ultimate - Topbar Client Actions
-- Handles client-side quick actions triggered from topbar

local noclipEnabled = false
local invisibilityEnabled = false

-- ============================================================================
-- SELF ACTIONS
-- ============================================================================

-- NoClip Toggle
-- DISABLED: Using quick-actions-handlers.lua NoClip instead (better camera-based movement)
-- RegisterNetEvent('ec_admin:client:toggleNoclip', function()
--     noclipEnabled = not noclipEnabled
--     local ped = PlayerPedId()
--     
--     if noclipEnabled then
--         SetEntityInvincible(ped, true)
--         SetEntityVisible(ped, false, false)
--         FreezeEntityPosition(ped, true)
--         
--         -- Show notification
--         TriggerEvent('ec_admin:client:notify', {
--             title = 'NoClip',
--             message = 'NoClip enabled',
--             type = 'success',
--             duration = 3000
--         })
--         
--         -- Start noclip thread
--         CreateThread(function()
--             local speed = 1.0
--             while noclipEnabled do
--                 local coords = GetEntityCoords(ped)
--                 local heading = GetEntityHeading(ped)
--                 
--                 -- Camera controls
--                 if IsControlPressed(0, 32) then -- W
--                     coords = coords + GetEntityForwardVector(ped) * speed
--                 end
--                 if IsControlPressed(0, 33) then -- S
--                     coords = coords - GetEntityForwardVector(ped) * speed
--                 end
--                 if IsControlPressed(0, 34) then -- A
--                     heading = heading + 2.0
--                 end
--                 if IsControlPressed(0, 35) then -- D
--                     heading = heading - 2.0
--                 end
--                 if IsControlPressed(0, 44) then -- Q (down)
--                     coords = vector3(coords.x, coords.y, coords.z - speed)
--                 end
--                 if IsControlPressed(0, 38) then -- E (up)
--                     coords = vector3(coords.x, coords.y, coords.z + speed)
--                 end
--                 
--                 -- Speed control
--                 if IsControlPressed(0, 21) then -- Shift (faster)
--                     speed = 5.0
--                 else
--                     speed = 1.0
--                 end
--                 
--                 SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
--                 SetEntityHeading(ped, heading)
--                 
--                 Wait(0)
--             end
--             
--             -- Disable noclip
--             SetEntityInvincible(ped, false)
--             SetEntityVisible(ped, true, false)
--             FreezeEntityPosition(ped, false)
--         end)
--     else
--         SetEntityInvincible(ped, false)
--         SetEntityVisible(ped, true, false)
--         FreezeEntityPosition(ped, false)
--         
--         TriggerEvent('ec_admin:client:notify', {
--             title = 'NoClip',
--             message = 'NoClip disabled',
--             type = 'info',
--             duration = 3000
--         })
--     end
-- end)

-- God Mode Toggle
RegisterNetEvent('ec_admin:client:toggleGodmode', function()
    TriggerEvent('ec_admin:toggleGodMode')
end)

-- Invisibility Toggle
RegisterNetEvent('ec_admin:client:toggleInvisibility', function()
    invisibilityEnabled = not invisibilityEnabled
    local ped = PlayerPedId()
    
    if invisibilityEnabled then
        SetEntityVisible(ped, false, false)
        SetLocalPlayerVisibleLocally(true)
        
        TriggerEvent('ec_admin:client:notify', {
            title = 'Invisibility',
            message = 'Invisibility enabled',
            type = 'success',
            duration = 3000
        })
    else
        SetEntityVisible(ped, true, false)
        
        TriggerEvent('ec_admin:client:notify', {
            title = 'Invisibility',
            message = 'Invisibility disabled',
            type = 'info',
            duration = 3000
        })
    end
end)

-- Heal Player
RegisterNetEvent('ec_admin:client:healPlayer', function()
    local ped = PlayerPedId()
    
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    
    -- Clear all damage
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    
    TriggerEvent('ec_admin:client:notify', {
        title = 'Heal',
        message = 'Health and armor restored',
        type = 'success',
        duration = 3000
    })
end)

-- ============================================================================
-- TELEPORT ACTIONS
-- ============================================================================

-- Teleport to Waypoint
RegisterNetEvent('ec_admin:client:teleportToWaypoint', function()
    local waypoint = GetFirstBlipInfoId(8)
    
    if not DoesBlipExist(waypoint) then
        TriggerEvent('ec_admin:client:notify', {
            title = 'Teleport',
            message = 'No waypoint set',
            type = 'error',
            duration = 3000
        })
        return
    end
    
    local coords = GetBlipCoords(waypoint)
    local ped = PlayerPedId()
    
    -- Get ground Z coordinate
    local groundZ = 0.0
    local foundGround, z = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
    
    if foundGround then
        groundZ = z
    else
        groundZ = coords.z
    end
    
    -- Teleport
    SetEntityCoords(ped, coords.x, coords.y, groundZ + 1.0, false, false, false, false)
    
    TriggerEvent('ec_admin:client:notify', {
        title = 'Teleport',
        message = 'Teleported to waypoint',
        type = 'success',
        duration = 3000
    })
end)

-- Remove duplicate teleportToCoords - already in quick-actions-client-complete.lua
-- Remove duplicate spawnVehicle - already in quick-actions-client-complete.lua

-- ============================================================================
-- VEHICLE ACTIONS
-- ============================================================================

-- Fix Vehicle
RegisterNetEvent('ec_admin:client:fixVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        TriggerEvent('ec_admin:client:notify', {
            title = 'Vehicle Repair',
            message = 'You are not in a vehicle',
            type = 'error',
            duration = 3000
        })
        return
    end
    
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleFuelLevel(vehicle, 100.0)
    
    TriggerEvent('ec_admin:client:notify', {
        title = 'Vehicle Repair',
        message = 'Vehicle repaired',
        type = 'success',
        duration = 3000
    })
end)

-- Delete Vehicle
RegisterNetEvent('ec_admin:client:deleteVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        -- Try to get closest vehicle
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end
    
    if vehicle == 0 then
        TriggerEvent('ec_admin:client:notify', {
            title = 'Delete Vehicle',
            message = 'No vehicle nearby',
            type = 'error',
            duration = 3000
        })
        return
    end
    
    DeleteVehicle(vehicle)
    
    TriggerEvent('ec_admin:client:notify', {
        title = 'Delete Vehicle',
        message = 'Vehicle deleted',
        type = 'success',
        duration = 3000
    })
end)

-- ============================================================================
-- SERVER ACTIONS
-- ============================================================================

-- Revive Player
RegisterNetEvent('ec_admin:client:revivePlayer', function()
    local ped = PlayerPedId()
    
    -- Revive logic (depends on framework)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    
    -- Try framework-specific revive
    if GetResourceState('qb-core') == 'started' then
        TriggerEvent('hospital:client:Revive')
    elseif GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx_ambulancejob:revive')
    end
    
    TriggerEvent('ec_admin:client:notify', {
        title = 'Revive',
        message = 'You have been revived',
        type = 'success',
        duration = 3000
    })
end)

-- Clear Area
RegisterNetEvent('ec_admin:client:clearArea', function(radius)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Clear vehicles
    local vehicles = GetGamePool('CVehicle')
    local count = 0
    
    for _, vehicle in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehCoords)
        
        if distance <= radius and not IsPedInVehicle(ped, vehicle, false) then
            DeleteVehicle(vehicle)
            count = count + 1
        end
    end
    
    -- Clear peds
    local peds = GetGamePool('CPed')
    for _, pedEntity in ipairs(peds) do
        if pedEntity ~= ped and not IsPedAPlayer(pedEntity) then
            local pedCoords = GetEntityCoords(pedEntity)
            local distance = #(coords - pedCoords)
            
            if distance <= radius then
                DeletePed(pedEntity)
                count = count + 1
            end
        end
    end
    
    -- Clear objects
    local objects = GetGamePool('CObject')
    for _, object in ipairs(objects) do
        local objCoords = GetEntityCoords(object)
        local distance = #(coords - objCoords)
        
        if distance <= radius then
            DeleteObject(object)
            count = count + 1
        end
    end
    
    TriggerEvent('ec_admin:client:notify', {
        title = 'Clear Area',
        message = string.format('Cleared %d entities (%.1fm radius)', count, radius),
        type = 'success',
        duration = 3000
    })
end)

-- Close Panel
RegisterNetEvent('ec_admin:client:closePanel', function()
    Logger.Info('')
    
    -- Use the centralized CloseMenu from nui-bridge
    -- This event should trigger the proper close via ec_admin:forceCloseMenu
    TriggerEvent('ec_admin:forceCloseMenu')
end)

-- Notification
RegisterNetEvent('ec_admin:client:notify', function(data)
    -- Show notification
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(data.message)
    EndTextCommandThefeedPostTicker(false, true)
end)

Logger.Success('✅ Topbar client actions loaded successfully')