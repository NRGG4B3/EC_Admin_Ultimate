--[[
    EC Admin Ultimate - Main Server File
    Handles basic events and initialization
]]

-- Wait for resources to be ready
CreateThread(function()
    Wait(1000) -- Wait 1 second for other resources to initialize
    
    -- Check dependencies
    if GetResourceState('oxmysql') ~= 'started' then
        print("^1[EC Admin] WARNING: oxmysql not found! Database operations will fail.^0")
    end
    
    if GetResourceState('ox_lib') ~= 'started' then
        print("^1[EC Admin] WARNING: ox_lib not found! Callbacks may not work.^0")
    end
    
    -- Initialize framework detection
    if ECFramework then
        local framework = ECFramework.GetFramework()
        print(string.format("^2[EC Admin]^7 Framework detected: %s^0", framework or 'standalone'))
    end
    
    print("^2[EC Admin Ultimate]^7 Server-side initialized^0")
end)

-- Player connecting event (basic)
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    -- Additional checks can be added here
    -- Main whitelist check is in whitelist.lua
end)

-- Resource start event
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print("^2[EC Admin Ultimate]^7 Resource started^0")
    end
end)

-- Resource stop event
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print("^2[EC Admin Ultimate]^7 Resource stopped^0")
    end
end)

-- ============================================================================
--  NUI ERROR LOGGING (Catches ALL NUI errors and logs to server)
-- ============================================================================

-- Callback: Log NUI errors from client
lib.callback.register('ec_admin:logNUIError', function(source, errorData)
    if not errorData then return false end
    
    local errorType = errorData.type or 'UNKNOWN'
    local errorMessage = errorData.message or 'No error message'
    local errorDetails = errorData.details or {}
    
    -- Log to server logger
    if Logger and Logger.NUIError then
        Logger.NUIError(errorType, errorMessage, errorDetails)
    else
        -- Fallback if Logger not available
        print(string.format("^1[EC Admin] [NUI ERROR] [%s] %s^0", errorType, errorMessage))
        if errorDetails and next(errorDetails) then
            print("^1[EC Admin] [NUI ERROR] Details: " .. json.encode(errorDetails) .. "^0")
        end
    end
    
    return true
end)

-- Server Event: Log NUI errors (fallback if callback fails)
RegisterNetEvent('ec_admin:logNUIError', function(errorData)
    if not errorData then return end
    
    local errorType = errorData.type or 'UNKNOWN'
    local errorMessage = errorData.message or 'No error message'
    local errorDetails = errorData.details or {}
    
    -- Log to server logger
    if Logger and Logger.NUIError then
        Logger.NUIError(errorType, errorMessage, errorDetails)
    else
        -- Fallback if Logger not available
        print(string.format("^1[EC Admin] [NUI ERROR] [%s] %s^0", errorType, errorMessage))
        if errorDetails and next(errorDetails) then
            print("^1[EC Admin] [NUI ERROR] Details: " .. json.encode(errorDetails) .. "^0")
        end
    end
end)

