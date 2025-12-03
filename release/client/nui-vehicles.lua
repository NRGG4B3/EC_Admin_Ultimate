-- EC Admin Ultimate - Client NUI Callbacks for Vehicles
-- All RegisterNUICallback calls MUST be client-side

Logger.Info('🚗 Loading Vehicles NUI callbacks...')

-- Get all vehicles (uses lib.callback for server query)
RegisterNUICallback('getVehicles', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getVehicles', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ vehicles = {}, stats = {} })
    end
end)

-- Get all available vehicles for spawning (default + custom packs)
RegisterNUICallback('getAllVehicles', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getAllVehicles', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, vehicles = {}, customCount = 0 })  -- FIX: Lua uses {} not []
    end
end)

-- Vehicle actions (server events)
RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:spawnVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('quickSpawnVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:quickSpawnVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('deleteVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:deleteVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('repairVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:repairVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('refuelVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:refuelVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('impoundVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:impoundVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('unimpoundVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:unimpoundVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('teleportToVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:teleportToVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('renameVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:renameVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('changeVehicleColor', function(data, cb)
    TriggerServerEvent('ec_admin:changeVehicleColor', data)
    cb({ success = true })
end)

RegisterNUICallback('upgradeVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:upgradeVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('transferVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:transferVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('storeVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:storeVehicle', data)
    cb({ success = true })
end)

RegisterNUICallback('addVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:addVehicle', data)
    cb({ success = true })
end)

Logger.Info('✅ Vehicles NUI callbacks loaded')