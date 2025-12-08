--[[
    EC Admin Ultimate - Player Profile NUI Bridge
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
        print(string.format("^1[NUI Player Profile]^7 Error in %s: %s^0", callbackName, tostring(response)))
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end

-- Register NUI callbacks and forward to server with error handling
RegisterNUICallback('getPlayerProfile', function(data, cb)
    safeCallback('getPlayerProfile', 'ec_admin:getPlayerProfile', data, cb)
end)

RegisterNUICallback('getPlayerInventory', function(data, cb)
    safeCallback('getPlayerInventory', 'ec_admin:getPlayerInventory', data, cb)
end)

RegisterNUICallback('getPlayerVehicles', function(data, cb)
    safeCallback('getPlayerVehicles', 'ec_admin:getPlayerVehicles', data, cb)
end)

RegisterNUICallback('getPlayerProperties', function(data, cb)
    safeCallback('getPlayerProperties', 'ec_admin:getPlayerProperties', data, cb)
end)

RegisterNUICallback('getPlayerTransactions', function(data, cb)
    safeCallback('getPlayerTransactions', 'ec_admin:getPlayerTransactions', data, cb)
end)

RegisterNUICallback('getPlayerActivity', function(data, cb)
    safeCallback('getPlayerActivity', 'ec_admin:getPlayerActivity', data, cb)
end)

RegisterNUICallback('getPlayerWarnings', function(data, cb)
    safeCallback('getPlayerWarnings', 'ec_admin:getPlayerWarnings', data, cb)
end)

RegisterNUICallback('getPlayerBans', function(data, cb)
    safeCallback('getPlayerBans', 'ec_admin:getPlayerBans', data, cb)
end)

RegisterNUICallback('getPlayerNotes', function(data, cb)
    safeCallback('getPlayerNotes', 'ec_admin:getPlayerNotes', data, cb)
end)

RegisterNUICallback('getPlayerPerformance', function(data, cb)
    safeCallback('getPlayerPerformance', 'ec_admin:getPlayerPerformance', data, cb)
end)

RegisterNUICallback('getPlayerMoneyChart', function(data, cb)
    safeCallback('getPlayerMoneyChart', 'ec_admin:getPlayerMoneyChart', data, cb)
end)

RegisterNUICallback('warnPlayer', function(data, cb)
    safeCallback('warnPlayer', 'ec_admin:warnPlayer', data, cb)
end)

RegisterNUICallback('banPlayer', function(data, cb)
    safeCallback('banPlayer', 'ec_admin:banPlayer', data, cb)
end)

RegisterNUICallback('kickPlayer', function(data, cb)
    safeCallback('kickPlayer', 'ec_admin:kickPlayer', data, cb)
end)

