-- EC Admin Ultimate - ULTRA QUIET MODE
-- ONLY show critical errors and final startup message
-- ZERO framework spam, ZERO API spam, ZERO initialization spam

_G.EC_ADMIN_QUIET_MODE = true
_G.EC_SHOWN_ONCE = {}

local originalPrint = print

-- Override print to suppress ALL EC Admin logs during startup
_G.print = function(...)
    if not _G.EC_ADMIN_QUIET_MODE then
        originalPrint(...)
        return
    end
    
    local args = {...}
    local msg = tostring(args[1] or "")
    
    -- ONLY ALLOW CRITICAL ERRORS
    local criticalOnly = {
        "ERROR",
        "FAILED",
        "CRITICAL",
        "OFFLINE"
    }
    
    for _, pattern in ipairs(criticalOnly) do
        if string.find(msg, pattern) and string.find(msg, "EC Admin") then
            originalPrint(...)
            return
        end
    end
    
    -- ALLOW non-EC Admin messages (other resources, FiveM, etc)
    if not string.find(msg, "EC Admin") and
       not string.find(msg, "EC Perms") and
       not string.find(msg, "API Manager") and
       not string.find(msg, "Auto%-Setup") and
       not string.find(msg, "Host Control") and
       not string.find(msg, "Environment") and
       not string.find(msg, "Discord ACE") and
       not string.find(msg, "API Router") and
       not string.find(msg, "Metrics") and
       not string.find(msg, "Owner Protection") and
       not string.find(msg, "EC Web") and
       not string.find(msg, "EC Security") and
       not string.find(msg, "Permission") and
       not string.find(msg, "NRG Staff") and
       not string.find(msg, "API Connection") and
       not string.find(msg, "API Status") and
       not string.find(msg, "Framework detected") and
       not string.find(msg, "QBCore") and
       not string.find(msg, "ESX") and
       not string.find(msg, "framework") then
        originalPrint(...)
    end
end

-- Disable quiet mode after 20 seconds
CreateThread(function()
    Wait(20000)
    _G.EC_ADMIN_QUIET_MODE = false
end)

originalPrint("^3[EC Admin] Silent startup mode enabled^0")
