--[[
    EC Admin Ultimate - Vehicle Management Client
    Client-side handlers for vehicle actions
]]

--[[
    MANUAL SERVER EVENT (ec_admin:spawnVehicle) - no client registration needed
    Old system used client-side spawning, new system uses server-side
]]
-- REMOVED: ec_admin:spawnVehicle client handler - conflicts with quick-actions-handlers.lua
-- Server now triggers quick-actions version directly

--[[
    Event: ec_admin:repairVehicle
    Repair the vehicle the player is in or nearest vehicle
]]
RegisterNetEvent('ec_admin:repairVehicle', function(plate)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    -- If not in vehicle, find nearest vehicle with matching plate
    if vehicle == 0 then
        vehicle = FindVehicleByPlate(plate)
    end
    
    if vehicle and DoesEntityExist(vehicle) then
        -- Repair vehicle
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        
        -- Set health
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        
        Logger.Info('' .. plate)
    else
        Logger.Info('' .. plate)
    end
end)

--[[
    Event: ec_admin:refuelVehicle
    Refuel the vehicle to 100%
]]
RegisterNetEvent('ec_admin:refuelVehicle', function(plate)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    -- If not in vehicle, find nearest vehicle with matching plate
    if vehicle == 0 then
        vehicle = FindVehicleByPlate(plate)
    end
    
    if vehicle and DoesEntityExist(vehicle) then
        -- Set fuel to 100%
        SetVehicleFuelLevel(vehicle, 100.0)
        
        -- If using QB fuel system
        if GetResourceState('qb-fuel') == 'started' then
            exports['qb-fuel']:SetFuel(vehicle, 100.0)
        end
        
        -- If using LegacyFuel
        if GetResourceState('LegacyFuel') == 'started' then
            exports['LegacyFuel']:SetFuel(vehicle, 100.0)
        end
        
        Logger.Info('' .. plate)
    else
        Logger.Info('' .. plate)
    end
end)

-- REMOVED: ec_admin:deleteVehicle - conflicts with quick-actions-handlers.lua

--[[
    Event: ec_admin:teleportToVehicle
    Teleport player to vehicle
]]
RegisterNetEvent('ec_admin:teleportToVehicle', function(plate)
    local vehicle = FindVehicleByPlate(plate)
    
    if vehicle and DoesEntityExist(vehicle) then
        local coords = GetEntityCoords(vehicle)
        local playerPed = PlayerPedId()
        
        -- Teleport player
        SetEntityCoords(playerPed, coords.x, coords.y, coords.z + 1.0, false, false, false, true)
        
        Logger.Info('' .. plate)
    else
        Logger.Info('' .. plate)
    end
end)

--[[
    Event: ec_admin:lockVehicle
    Lock/unlock vehicle
]]
RegisterNetEvent('ec_admin:lockVehicle', function(plate, locked)
    local vehicle = FindVehicleByPlate(plate)
    
    if vehicle and DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, locked and 2 or 1)
        Logger.Info('' .. (locked and 'locked' or 'unlocked') .. ': ' .. plate)
    else
        Logger.Info('' .. plate)
    end
end)

--[[
    Event: ec_admin:changeVehicleColor
    Change vehicle colors
]]
RegisterNetEvent('ec_admin:changeVehicleColor', function(plate, primaryColor, secondaryColor)
    local vehicle = FindVehicleByPlate(plate)
    
    if vehicle and DoesEntityExist(vehicle) then
        -- Convert color names to IDs (simplified - would need full color mapping)
        SetVehicleCustomPrimaryColour(vehicle, 255, 255, 255) -- White as default
        SetVehicleCustomSecondaryColour(vehicle, 0, 0, 0) -- Black as default
        
        Logger.Info('' .. plate)
    else
        Logger.Info('' .. plate)
    end
end)

--[[
    Event: ec_admin:upgradeVehicle
    Apply mods to vehicle
]]
RegisterNetEvent('ec_admin:upgradeVehicle', function(plate, mods)
    local vehicle = FindVehicleByPlate(plate)
    
    if vehicle and DoesEntityExist(vehicle) then
        -- Apply mods
        if mods.engine then
            SetVehicleMod(vehicle, 11, mods.engine, false)
        end
        if mods.transmission then
            SetVehicleMod(vehicle, 13, mods.transmission, false)
        end
        if mods.turbo then
            ToggleVehicleMod(vehicle, 18, mods.turbo)
        end
        if mods.brakes then
            SetVehicleMod(vehicle, 12, mods.brakes, false)
        end
        if mods.suspension then
            SetVehicleMod(vehicle, 15, mods.suspension, false)
        end
        
        Logger.Info('' .. plate)
    else
        Logger.Info('' .. plate)
    end
end)

--[[
    Helper: Find vehicle by plate
]]
function FindVehicleByPlate(plate)
    local vehicles = GetGamePool('CVehicle')
    
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehiclePlate = GetVehicleNumberPlateText(vehicle)
            if vehiclePlate and string.gsub(vehiclePlate, '^%s*(.-)%s*$', '%1') == plate then
                return vehicle
            end
        end
    end
    
    return nil
end

Logger.Success('✅ Vehicle management client handlers loaded')
