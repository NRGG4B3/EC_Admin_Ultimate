--[[
    EC Admin Ultimate - Players NUI Bridge
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
        print(string.format("^1[NUI Players]^7 Error in %s: %s^0", callbackName, tostring(response)))
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end

-- Register NUI callbacks and forward to server with error handling
RegisterNUICallback('getPlayers', function(data, cb)
    safeCallback('getPlayers', 'ec_admin:getPlayers', data, cb)
end)

RegisterNUICallback('getBans', function(data, cb)
    safeCallback('getBans', 'ec_admin:getBans', data, cb)
end)

RegisterNUICallback('spectatePlayer', function(data, cb)
    safeCallback('spectatePlayer', 'ec_admin:spectatePlayer', data, cb)
end)

RegisterNUICallback('freezePlayer', function(data, cb)
    safeCallback('freezePlayer', 'ec_admin:freezePlayer', data, cb)
end)

RegisterNUICallback('revivePlayer', function(data, cb)
    safeCallback('revivePlayer', 'ec_admin:revivePlayer', data, cb)
end)

RegisterNUICallback('healPlayer', function(data, cb)
    safeCallback('healPlayer', 'ec_admin:healPlayer', data, cb)
end)

RegisterNUICallback('kickPlayers', function(data, cb)
    safeCallback('kickPlayers', 'ec_admin:kickPlayers', data, cb)
end)

RegisterNUICallback('teleportPlayers', function(data, cb)
    safeCallback('teleportPlayers', 'ec_admin:teleportPlayers', data, cb)
end)

