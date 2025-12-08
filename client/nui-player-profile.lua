--[[
    EC Admin Ultimate - Player Profile NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callbacks and forward to server
RegisterNUICallback('getPlayerProfile', function(data, cb)
    lib.callback('ec_admin:getPlayerProfile', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPlayerInventory', function(data, cb)
    lib.callback('ec_admin:getPlayerInventory', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPlayerVehicles', function(data, cb)
    lib.callback('ec_admin:getPlayerVehicles', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPlayerProperties', function(data, cb)
    lib.callback('ec_admin:getPlayerProperties', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPlayerTransactions', function(data, cb)
    lib.callback('ec_admin:getPlayerTransactions', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPlayerActivity', function(data, cb)
    lib.callback('ec_admin:getPlayerActivity', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPlayerWarnings', function(data, cb)
    lib.callback('ec_admin:getPlayerWarnings', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPlayerBans', function(data, cb)
    lib.callback('ec_admin:getPlayerBans', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPlayerNotes', function(data, cb)
    lib.callback('ec_admin:getPlayerNotes', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPlayerPerformance', function(data, cb)
    lib.callback('ec_admin:getPlayerPerformance', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getPlayerMoneyChart', function(data, cb)
    lib.callback('ec_admin:getPlayerMoneyChart', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('warnPlayer', function(data, cb)
    lib.callback('ec_admin:warnPlayer', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('banPlayer', function(data, cb)
    lib.callback('ec_admin:banPlayer', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('kickPlayer', function(data, cb)
    lib.callback('ec_admin:kickPlayer', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

