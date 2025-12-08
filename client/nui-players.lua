--[[
    EC Admin Ultimate - Players NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callbacks and forward to server
RegisterNUICallback('getPlayers', function(data, cb)
    lib.callback('ec_admin:getPlayers', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('getBans', function(data, cb)
    lib.callback('ec_admin:getBans', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('spectatePlayer', function(data, cb)
    lib.callback('ec_admin:spectatePlayer', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('freezePlayer', function(data, cb)
    lib.callback('ec_admin:freezePlayer', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('revivePlayer', function(data, cb)
    lib.callback('ec_admin:revivePlayer', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('healPlayer', function(data, cb)
    lib.callback('ec_admin:healPlayer', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('kickPlayers', function(data, cb)
    lib.callback('ec_admin:kickPlayers', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('teleportPlayers', function(data, cb)
    lib.callback('ec_admin:teleportPlayers', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

