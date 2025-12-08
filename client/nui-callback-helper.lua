--[[
    EC Admin Ultimate - NUI Callback Helper
    Shared helper function for safe NUI callbacks with error handling
    Use this in all NUI bridge files to ensure consistent error handling
]]

-- Safe callback wrapper function
function SafeNUICallback(callbackName, serverCallback, data)
    local success, response = pcall(function()
        if lib and lib.callback then
            return lib.callback.await(serverCallback, false, data)
        else
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        print(string.format("^1[NUI Callback]^7 Error in %s: %s^0", callbackName, tostring(response)))
        return { success = false, error = 'Callback failed: ' .. tostring(response) }
    end
    
    return response or { success = false, error = 'No response from server' }
end
