--[[
    EC Admin Ultimate - Dev Tools NUI Bridge
    Client-side bridge connecting NUI callbacks to server-side handlers
]]

-- Register NUI callbacks and forward to server
RegisterNUICallback('devTools:getData', function(data, cb)
    lib.callback('ec_admin:devTools:getData', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('devTools:executeScript', function(data, cb)
    lib.callback('ec_admin:devTools:executeScript', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

RegisterNUICallback('devTools:runCommand', function(data, cb)
    lib.callback('ec_admin:devTools:runCommand', false, function(response)
        cb(response or { success = false, error = 'No response from server' })
    end, data)
end)

