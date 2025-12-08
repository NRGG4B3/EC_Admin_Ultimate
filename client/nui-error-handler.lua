--[[
    EC Admin Ultimate - NUI Error Handler
    Catches ALL NUI errors and logs them to the server logger
    This ensures all UI issues are visible in the server console
]]

-- Check if NUI error logging is enabled
local function isNUIErrorLoggingEnabled()
    if Config and Config.LogNUIErrors ~= nil then
        return Config.LogNUIErrors
    end
    return true  -- Default to enabled
end

-- Send error to server logger
local function logNUIError(errorType, errorMessage, errorDetails)
    if not isNUIErrorLoggingEnabled() then
        return
    end
    
    -- Format error message
    local fullMessage = string.format("[NUI ERROR] [%s] %s", errorType, errorMessage)
    
    if errorDetails then
        if type(errorDetails) == "table" then
            fullMessage = fullMessage .. " | Details: " .. json.encode(errorDetails)
        else
            fullMessage = fullMessage .. " | Details: " .. tostring(errorDetails)
        end
    end
    
    -- Send to server via callback (async - don't wait)
    CreateThread(function()
        if lib and lib.callback then
            local success = lib.callback.await('ec_admin:logNUIError', false, {
                type = errorType,
                message = errorMessage,
                details = errorDetails,
                timestamp = os.time()
            })
            
            if not success then
                -- Fallback to client-side logging if server callback fails
                print("^1[NUI Error Handler]^7 " .. fullMessage .. "^0")
            end
        else
            -- Fallback if lib.callback not available - send via server event
            TriggerServerEvent('ec_admin:logNUIError', {
                type = errorType,
                message = errorMessage,
                details = errorDetails,
                timestamp = os.time()
            })
        end
    end)
end

-- Register NUI callback for error reporting
RegisterNUICallback('logError', function(data, cb)
    local errorType = data.type or 'UNKNOWN'
    local errorMessage = data.message or 'No error message provided'
    local errorDetails = data.details or {}
    local stackTrace = data.stack or nil
    
    -- Log to server
    logNUIError(errorType, errorMessage, {
        details = errorDetails,
        stack = stackTrace,
        source = 'NUI_CALLBACK'
    })
    
    cb({ success = true })
end)

-- Register NUI callback for React errors
RegisterNUICallback('logReactError', function(data, cb)
    local error = data.error or {}
    local errorInfo = data.errorInfo or {}
    
    logNUIError('REACT_ERROR', error.message or 'React component error', {
        componentStack = errorInfo.componentStack,
        stack = error.stack,
        name = error.name,
        source = 'REACT_ERROR_BOUNDARY'
    })
    
    cb({ success = true })
end)

-- Register NUI callback for fetch errors
RegisterNUICallback('logFetchError', function(data, cb)
    local url = data.url or 'unknown'
    local method = data.method or 'GET'
    local status = data.status or 0
    local statusText = data.statusText or 'Unknown error'
    local errorMessage = data.message or 'Fetch failed'
    
    logNUIError('FETCH_ERROR', string.format("%s %s failed: %s (%d %s)", method, url, errorMessage, status, statusText), {
        url = url,
        method = method,
        status = status,
        statusText = statusText,
        source = 'NUI_FETCH'
    })
    
    cb({ success = true })
end)

-- Register NUI callback for console errors
RegisterNUICallback('logConsoleError', function(data, cb)
    local level = data.level or 'ERROR'
    local message = data.message or 'Console error'
    local stack = data.stack or nil
    
    logNUIError('CONSOLE_' .. string.upper(level), message, {
        stack = stack,
        source = 'NUI_CONSOLE'
    })
    
    cb({ success = true })
end)

print("^2[NUI Error Handler]^7 NUI error logging system loaded^0")
