--[[
    EC Admin Ultimate - Client Logger
    Lightweight logging system for client-side scripts
    Provides safe logging functions that won't crash if server Logger isn't available
]]

-- Client-side Logger (safe fallback)
Logger = Logger or {}

-- Helper: Get current time (client-safe)
local function getClientTime()
    -- Use GetGameTimer for client-side time (milliseconds since game start)
    -- Convert to seconds for compatibility
    return math.floor(GetGameTimer() / 1000)
end

-- Info logging
function Logger.Info(message)
    if type(message) ~= 'string' then
        message = tostring(message)
    end
    print(string.format("^2[EC Admin Client]^7 %s^0", message))
end

-- Error logging
function Logger.Error(message)
    if type(message) ~= 'string' then
        message = tostring(message)
    end
    print(string.format("^1[EC Admin Client ERROR]^7 %s^0", message))
end

-- Warning logging
function Logger.Warn(message)
    if type(message) ~= 'string' then
        message = tostring(message)
    end
    print(string.format("^3[EC Admin Client WARN]^7 %s^0", message))
end

-- Success logging
function Logger.Success(message)
    if type(message) ~= 'string' then
        message = tostring(message)
    end
    print(string.format("^2[EC Admin Client]^7 ✓ %s^0", message))
end

-- Debug logging (only if debug mode)
function Logger.Debug(message)
    if Config and Config.Debug then
        if type(message) ~= 'string' then
            message = tostring(message)
        end
        print(string.format("^5[EC Admin Client DEBUG]^7 %s^0", message))
    end
end

-- Export for compatibility
exports('Logger', function()
    return Logger
end)

print("^2[Client Logger]^7 Client-side logger initialized^0")
