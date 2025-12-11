--[[
    EC Admin Ultimate - Vehicles NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Helper: Safe callback wrapper
local function safeCallback(callbackName, serverCallback, data, cb)
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await(serverCallback, false, data)
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print(string.format("^1[NUI Vehicles]^7 Error in %s: %s^0", callbackName, tostring(response)))
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end

-- Register NUI callbacks and forward to server with error handling
RegisterNUICallback('getVehicles', function(data, cb)
    safeCallback('getVehicles', 'ec_admin:getVehicles', data, cb)
end)

RegisterNUICallback('getAllVehicles', function(data, cb)
    safeCallback('getAllVehicles', 'ec_admin:getAllVehicles', data, cb)
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    safeCallback('spawnVehicle', 'ec_admin:spawnVehicle', data, cb)
end)

RegisterNUICallback('quickSpawnVehicle', function(data, cb)
    safeCallback('quickSpawnVehicle', 'ec_admin:quickSpawnVehicle', data, cb)
end)

RegisterNUICallback('deleteVehicle', function(data, cb)
    safeCallback('deleteVehicle', 'ec_admin:deleteVehicle', data, cb)
end)

RegisterNUICallback('repairVehicle', function(data, cb)
    safeCallback('repairVehicle', 'ec_admin:repairVehicle', data, cb)
end)

RegisterNUICallback('refuelVehicle', function(data, cb)
    safeCallback('refuelVehicle', 'ec_admin:refuelVehicle', data, cb)
end)

RegisterNUICallback('impoundVehicle', function(data, cb)
    safeCallback('impoundVehicle', 'ec_admin:impoundVehicle', data, cb)
end)

RegisterNUICallback('unimpoundVehicle', function(data, cb)
    safeCallback('unimpoundVehicle', 'ec_admin:unimpoundVehicle', data, cb)
end)

RegisterNUICallback('teleportToVehicle', function(data, cb)
    safeCallback('teleportToVehicle', 'ec_admin:teleportToVehicle', data, cb)
end)

RegisterNUICallback('renameVehicle', function(data, cb)
    safeCallback('renameVehicle', 'ec_admin:renameVehicle', data, cb)
end)

RegisterNUICallback('changeVehicleColor', function(data, cb)
    safeCallback('changeVehicleColor', 'ec_admin:changeVehicleColor', data, cb)
end)

RegisterNUICallback('upgradeVehicle', function(data, cb)
    safeCallback('upgradeVehicle', 'ec_admin:upgradeVehicle', data, cb)
end)

RegisterNUICallback('transferVehicle', function(data, cb)
    safeCallback('transferVehicle', 'ec_admin:transferVehicle', data, cb)
end)

RegisterNUICallback('storeVehicle', function(data, cb)
    safeCallback('storeVehicle', 'ec_admin:storeVehicle', data, cb)
end)

RegisterNUICallback('addVehicle', function(data, cb)
    safeCallback('addVehicle', 'ec_admin:addVehicle', data, cb)
end)

