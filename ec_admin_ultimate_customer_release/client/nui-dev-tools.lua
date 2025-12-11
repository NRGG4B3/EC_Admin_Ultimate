--[[
    EC Admin Ultimate - Dev Tools NUI Bridge
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
        print(string.format("^1[NUI Dev Tools]^7 Error in %s: %s^0", callbackName, tostring(response)))
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end

-- Register NUI callbacks and forward to server with error handling
RegisterNUICallback('devTools:getData', function(data, cb)
    safeCallback('devTools:getData', 'ec_admin:devTools:getData', data, cb)
end)

RegisterNUICallback('devTools:executeScript', function(data, cb)
    safeCallback('devTools:executeScript', 'ec_admin:devTools:executeScript', data, cb)
end)

RegisterNUICallback('devTools:runCommand', function(data, cb)
    safeCallback('devTools:runCommand', 'ec_admin:devTools:runCommand', data, cb)
end)

