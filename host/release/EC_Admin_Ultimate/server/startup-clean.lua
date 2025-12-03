-- EC Admin Ultimate - SILENT Startup
-- NO SPAM - Zero framework detection logs
-- ONLY show critical errors

-- Global suppression flags
_G.EC_SUPPRESS_STARTUP_LOGS = true
_G.EC_FRAMEWORK_DETECTED = false
_G.EC_SQL_DETECTED = false

-- Single clean startup message
local function PrintCleanStartup()
    local isHostMode = Config and Config.Host and Config.Host.enabled or false
    local mode = isHostMode and "HOST" or "CUSTOMER"
    
    print("^0========================================^0")
    Logger.Info(" Started^0")
    print(string.format("^7Mode: %s | APIs: %s^0", mode, isHostMode and "20 Local" or "Remote"))
    print("^0========================================^0")
end

-- Completely disable startup spam
CreateThread(function()
    Wait(3000) -- Wait for systems
    PrintCleanStartup()
    Wait(1000)
    _G.EC_SUPPRESS_STARTUP_LOGS = false
end)

-- Export for other scripts
_G.ECStartup = {
    PrintStart = function() end, -- No-op
    PrintSuccess = PrintCleanStartup,
    RestorePrint = function() end -- No-op
}
