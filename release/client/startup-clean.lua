-- EC Admin Ultimate - Client Clean Startup
-- Suppress verbose client-side logs

-- Global flag to suppress verbose startup messages
_G.EC_SUPPRESS_CLIENT_LOGS = true

-- Override print function to suppress client startup logs
local originalPrint = print
_G.print = function(...)
    local args = {...}
    local msg = table.concat(args, " ")
    
    -- Allow through if suppression is disabled
    if not _G.EC_SUPPRESS_CLIENT_LOGS then
        originalPrint(...)
        return
    end
    
    -- ALWAYS allow these through (critical messages)
    local alwaysAllowPatterns = {
        "ERROR", "Error", "error",
        "WARNING", "Warning", "warning",
        "CRITICAL", "Critical", "critical",
        "FAILED", "Failed", "failed",
        "API", "api",  -- API connection messages
        "NRG API", "NRG api",  -- NRG API messages
        "Connected to", "connected to",  -- Connection status
        "Disconnected from", "disconnected from",
        "offline", "Offline", "OFFLINE",
        "online", "Online", "ONLINE"
    }
    
    -- Check if message should always be allowed
    for _, pattern in ipairs(alwaysAllowPatterns) do
        if string.find(msg, pattern) then
            originalPrint(...)
            return
        end
    end
    
    -- Suppress these patterns (client-side)
    local suppressPatterns = {
        "Loading",
        "Initializing",
        "loading",
        "initializing",
        "callbacks",
        "NUI",
        "handlers",
        "system"
    }
    
    -- Check if message should be suppressed
    for _, pattern in ipairs(suppressPatterns) do
        if string.find(msg, pattern) then
            -- Only suppress EC Admin messages
            if string.find(msg, "EC Admin") then
                return -- Suppress this message
            end
        end
    end
    
    -- Print everything else
    originalPrint(...)
end

-- Re-enable normal printing after startup
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Wait for client to fully load
    _G.EC_SUPPRESS_CLIENT_LOGS = false
    _G.print = originalPrint -- Restore original print
end)