-- EC Admin Ultimate - Client Error Handler
-- Catches and logs errors gracefully
-- Version: 1.0.0

Logger.Info('🛡️ Loading client error handler...')

-- Global error tracking
local ErrorStats = {
    totalErrors = 0,
    errors = {},
    maxErrors = 20
}

-- Error handler function
local function HandleError(errorMessage)
    ErrorStats.totalErrors = ErrorStats.totalErrors + 1
    
    -- Store error
    table.insert(ErrorStats.errors, {
        message = errorMessage,
        timestamp = os.time(),
        count = 1
    })
    
    -- Keep only last 20 errors
    if #ErrorStats.errors > ErrorStats.maxErrors then
        table.remove(ErrorStats.errors, 1)
    end
    
    -- Log to console
    Logger.Error(errorMessage)
end

-- Wrap functions with error handling
function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        HandleError(result)
        return nil
    end
    return result
end

-- Export functions
exports('GetErrorStats', function()
    return ErrorStats
end)

exports('SafeCall', function(func, ...)
    return SafeCall(func, ...)
end)

-- Catch unhandled errors
CreateThread(function()
    SetTimeout(5000, function()
        Logger.Info('✅ Client error handler active')
    end)
end)

Logger.Info('✅ Client error handler loaded')
