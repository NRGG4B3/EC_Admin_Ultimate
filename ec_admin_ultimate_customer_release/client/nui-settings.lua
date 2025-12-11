--[[
    EC Admin Ultimate - Settings NUI Bridge
    Client-side bridge for settings callbacks
]]

-- Register NUI callback: settings:getData
RegisterNUICallback('settings:getData', function(data, cb)
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await('ec_admin:settings:getData', false, data)
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print("^1[NUI Settings]^7 Error in settings:getData: " .. tostring(response) .. "^0")
        cb({ success = false, error = 'Callback failed: ' .. tostring(response) })
    else
        cb(response or { success = false, error = 'No response from server' })
    end
end)

print("^2[NUI Settings]^7 Settings bridge loaded^0")
