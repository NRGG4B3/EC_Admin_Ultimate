--[[
    EC Admin Ultimate - Config Loader
    Automatically loads the correct config file based on host mode detection
    
    This script runs BEFORE config.lua and determines which config to load
]]

-- Check if host folder exists
local function hostFolderExists()
    local hostFiles = {
        'host/config.lua',
        'host/api/host_server.lua'
    }
    
    for _, file in ipairs(hostFiles) do
        local content = LoadResourceFile(GetCurrentResourceName(), file)
        if content then
            return true
        end
    end
    
    return false
end

-- Set global config source (used by config.lua)
local isHost = hostFolderExists()
_EC_CONFIG_SOURCE = isHost and 'host.config.lua' or 'customer.config.lua'
_EC_CONFIG_MODE = isHost and 'HOST' or 'CUSTOMER'

print("^2[Config Loader]^7 Detected mode: " .. _EC_CONFIG_MODE .. "^0")
print("^2[Config Loader]^7 Will load config from: " .. _EC_CONFIG_SOURCE .. "^0")
