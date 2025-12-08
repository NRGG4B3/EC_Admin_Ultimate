--[[
    EC Admin Ultimate - NUI Callback Helper
    Provides safe wrapper for NUI callbacks with error handling
    Use this to ensure all NUI callbacks handle errors gracefully
]]

-- Safe NUI callback wrapper
function SafeNUICallback(callbackName, serverCallback, data)
    -- Wrap in pcall to catch any errors
    local success, result = pcall(function()
        if lib and lib.callback then
            -- Use await for synchronous response
            return lib.callback.await(serverCallback, false, data)
        else
            -- Fallback if lib.callback not available
            return { success = false, error = 'Callback system not available' }
        end
    end)
    
    if not success then
        -- Log error and return safe response
        print(string.format("^1[NUI Callback]^7 Error in %s: %s^0", callbackName, tostring(result)))
        return { success = false, error = 'Callback failed: ' .. tostring(result) }
    end
    
    return result or { success = false, error = 'No response from server' }
end

-- Register NUI callback with error handling
function RegisterSafeNUICallback(callbackName, serverCallback)
    RegisterNUICallback(callbackName, function(data, cb)
        local response = SafeNUICallback(callbackName, serverCallback, data)
        cb(response)
    end)
end
