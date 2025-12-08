--[[
    EC Admin Ultimate - Vehicles NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callbacks and forward to server
RegisterNUICallback('getVehicles', function(data, cb)
    lib.callback('ec_admin:getVehicles', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getAllVehicles', function(data, cb)
    lib.callback('ec_admin:getAllVehicles', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    lib.callback('ec_admin:spawnVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('quickSpawnVehicle', function(data, cb)
    lib.callback('ec_admin:quickSpawnVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('deleteVehicle', function(data, cb)
    lib.callback('ec_admin:deleteVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('repairVehicle', function(data, cb)
    lib.callback('ec_admin:repairVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('refuelVehicle', function(data, cb)
    lib.callback('ec_admin:refuelVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('impoundVehicle', function(data, cb)
    lib.callback('ec_admin:impoundVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('unimpoundVehicle', function(data, cb)
    lib.callback('ec_admin:unimpoundVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('teleportToVehicle', function(data, cb)
    lib.callback('ec_admin:teleportToVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('renameVehicle', function(data, cb)
    lib.callback('ec_admin:renameVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('changeVehicleColor', function(data, cb)
    lib.callback('ec_admin:changeVehicleColor', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('upgradeVehicle', function(data, cb)
    lib.callback('ec_admin:upgradeVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('transferVehicle', function(data, cb)
    lib.callback('ec_admin:transferVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('storeVehicle', function(data, cb)
    lib.callback('ec_admin:storeVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('addVehicle', function(data, cb)
    lib.callback('ec_admin:addVehicle', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

