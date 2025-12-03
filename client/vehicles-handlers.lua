--[[
    EC Admin Ultimate - Client-Side Vehicle Handlers
    Handles all client-side vehicle actions
]]

print("[EC Admin Client] Loading vehicles handlers...")

-- Remove duplicate spawnVehicle - already in quick-actions-client-complete.lua

-- Repair Vehicle (UNIQUE - keep this)
RegisterNetEvent('ec_admin:client:repairVehicle')
AddEventHandler('ec_admin:client:repairVehicle', function(vehicleId)
    if vehicleId then
        local vehicle = vehicleId
        
        -- Repair vehicle
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        
        -- Clean vehicle
        SetVehicleDirtLevel(vehicle, 0.0)
        
        lib.notify({
            title = 'EC Admin',
            description = 'Vehicle repaired',
            type = 'success'
        })
    else
        -- Repair player's current vehicle
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle and vehicle ~= 0 then
            SetVehicleFixed(vehicle)
            SetVehicleDeformationFixed(vehicle)
            SetVehicleUndriveable(vehicle, false)
            SetVehicleEngineOn(vehicle, true, true, false)
            SetVehicleDirtLevel(vehicle, 0.0)
            
            lib.notify({
                title = 'EC Admin',
                description = 'Vehicle repaired',
                type = 'success'
            })
        else
            lib.notify({
                title = 'EC Admin',
                description = 'You are not in a vehicle',
                type = 'error'
            })
        end
    end
end)

-- ============================================================================
-- REFUEL VEHICLE
-- ============================================================================

RegisterNetEvent('ec_admin:client:refuelVehicle')
AddEventHandler('ec_admin:client:refuelVehicle', function(vehicleId)
    if vehicleId then
        SetVehicleFuelLevel(vehicleId, 100.0)
    else
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle and vehicle ~= 0 then
            SetVehicleFuelLevel(vehicle, 100.0)
            
            lib.notify({
                title = 'EC Admin',
                description = 'Vehicle refueled',
                type = 'success'
            })
        else
            lib.notify({
                title = 'EC Admin',
                description = 'You are not in a vehicle',
                type = 'error'
            })
        end
    end
end)

-- ============================================================================
-- TOGGLE VEHICLE LOCK
-- ============================================================================

RegisterNetEvent('ec_admin:client:toggleLock')
AddEventHandler('ec_admin:client:toggleLock', function(vehicleId)
    if vehicleId then
        local lockStatus = GetVehicleDoorLockStatus(vehicleId)
        
        if lockStatus == 1 then
            SetVehicleDoorsLocked(vehicleId, 2)
            lib.notify({
                title = 'EC Admin',
                description = 'Vehicle locked',
                type = 'success'
            })
        else
            SetVehicleDoorsLocked(vehicleId, 1)
            lib.notify({
                title = 'EC Admin',
                description = 'Vehicle unlocked',
                type = 'success'
            })
        end
    else
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle and vehicle ~= 0 then
            local lockStatus = GetVehicleDoorLockStatus(vehicle)
            
            if lockStatus == 1 then
                SetVehicleDoorsLocked(vehicle, 2)
                lib.notify({
                    title = 'EC Admin',
                    description = 'Vehicle locked',
                    type = 'success'
                })
            else
                SetVehicleDoorsLocked(vehicle, 1)
                lib.notify({
                    title = 'EC Admin',
                    description = 'Vehicle unlocked',
                    type = 'success'
                })
            end
        end
    end
end)

-- Remove duplicate teleportToCoords - already in quick-actions-client-complete.lua

-- ============================================================================
-- DELETE CLOSEST VEHICLE (Quick Action)
-- ============================================================================

RegisterNetEvent('ec_admin:client:deleteClosestVehicle')
AddEventHandler('ec_admin:client:deleteClosestVehicle', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    
    if vehicle and vehicle ~= 0 then
        DeleteEntity(vehicle)
        
        lib.notify({
            title = 'EC Admin',
            description = 'Vehicle deleted',
            type = 'success'
        })
    else
        lib.notify({
            title = 'EC Admin',
            description = 'No vehicle nearby',
            type = 'error'
        })
    end
end)

-- ============================================================================
-- FLIP VEHICLE (Quick Action)
-- ============================================================================

RegisterNetEvent('ec_admin:client:flipVehicle')
AddEventHandler('ec_admin:client:flipVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle and vehicle ~= 0 then
        local rot = GetEntityRotation(vehicle, 2)
        SetEntityRotation(vehicle, rot.x, 0.0, rot.z, 2, true)
        
        lib.notify({
            title = 'EC Admin',
            description = 'Vehicle flipped',
            type = 'success'
        })
    else
        lib.notify({
            title = 'EC Admin',
            description = 'You are not in a vehicle',
            type = 'error'
        })
    end
end)

-- ============================================================================
-- MAX UPGRADE VEHICLE (Quick Action)
-- ============================================================================

RegisterNetEvent('ec_admin:client:maxUpgradeVehicle')
AddEventHandler('ec_admin:client:maxUpgradeVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle and vehicle ~= 0 then
        SetVehicleModKit(vehicle, 0)
        
        -- Engine
        SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false)
        -- Brakes
        SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false)
        -- Transmission
        SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false)
        -- Suspension
        SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false)
        -- Armor
        SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false)
        -- Turbo
        ToggleVehicleMod(vehicle, 18, true)
        
        lib.notify({
            title = 'EC Admin',
            description = 'Vehicle fully upgraded',
            type = 'success'
        })
    else
        lib.notify({
            title = 'EC Admin',
            description = 'You are not in a vehicle',
            type = 'error'
        })
    end
end)

-- ============================================================================
-- CLEAN VEHICLE (Quick Action)
-- ============================================================================

RegisterNetEvent('ec_admin:client:cleanVehicle')
AddEventHandler('ec_admin:client:cleanVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle and vehicle ~= 0 then
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
        
        lib.notify({
            title = 'EC Admin',
            description = 'Vehicle cleaned',
            type = 'success'
        })
    else
        lib.notify({
            title = 'EC Admin',
            description = 'You are not in a vehicle',
            type = 'error'
        })
    end
end)

print('[EC Admin Client] ✅ Vehicle handlers loaded successfully')