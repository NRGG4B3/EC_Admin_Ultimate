--[[
    EC Admin Ultimate - Global Ban API Auto-Registration
    Automatically registers host with NRG Global Ban API on first install
]]--

-- HOST MODE: Use local multi-port server (Port 3001 = Global Ban API)
-- CUSTOMER MODE: Use production API
local function GetGlobalBanURL()
    -- Check if host folder exists
    local hostFolderExists = LoadResourceFile(GetCurrentResourceName(), 'host/README.md') ~= nil
    
    if hostFolderExists then
        -- HOST MODE: Use local server
        return 'http://127.0.0.1:3001/api/global-bans/register'
    else
        -- CUSTOMER MODE: Use production API (customers SHOULD connect)
        return 'https://api.ecbetasolutions.com:3001/api/global-bans/register'
    end
end

local GLOBAL_BAN_API_URL = GetGlobalBanURL()
local REGISTRATION_FILE = 'server/global_ban_registration.json'  -- Store in server folder
local registered = false
local registrationData = nil

-- Check if already registered
function IsGlobalBanRegistered()
    if registered then
        return true, registrationData
    end
    
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local filePath = resourcePath .. '/' .. REGISTRATION_FILE
    
    local file = io.open(filePath, 'r')
    if file then
        local content = file:read('*all')
        file:close()
        
        local success, data = pcall(json.decode, content)
        if success and data and data.registered then
            registered = true
            registrationData = data
            return true, data
        end
    end
    
    return false, nil
end

-- Register with Global Ban API
function RegisterWithGlobalBanAPI()
    local isRegistered, existingData = IsGlobalBanRegistered()
    if isRegistered then
        Logger.Info('')
        Logger.Info('' .. (existingData.apiKey or 'N/A') .. '^7')
        return true, existingData
    end
    
    -- Get server details
    local serverName = GetConvar('sv_hostname', 'Unknown Server')
    local serverEndpoint = GetConvar('web_baseUrl', 'http://localhost:30120')
    
    -- Create registration payload
    local payload = {
        serverName = serverName,
        serverEndpoint = serverEndpoint,
        resourceVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '1.0.0',
        timestamp = os.time(),
        ownerIdentifier = Config and Config.Owner or 'unknown'
    }
    
    Logger.Info('')
    
    -- Make registration request
    PerformHttpRequest(GLOBAL_BAN_API_URL, function(statusCode, response, headers)
        if statusCode == 200 or statusCode == 201 then
            local success, data = pcall(json.decode, response)
            if success and data and data.apiKey then
                -- Save registration data
                local registrationInfo = {
                    registered = true,
                    apiKey = data.apiKey,
                    serverId = data.serverId or nil,
                    registeredAt = os.date('%Y-%m-%d %H:%M:%S'),
                    timestamp = os.time()
                }
                
                -- Write to file
                local resourcePath = GetResourcePath(GetCurrentResourceName())
                local filePath = resourcePath .. '/' .. REGISTRATION_FILE
                
                local file = io.open(filePath, 'w')
                if file then
                    file:write(json.encode(registrationInfo, { indent = true }))
                    file:close()
                    
                    registered = true
                    registrationData = registrationInfo
                    
                    Logger.Info('')
                    Logger.Info('' .. (data.serverId or 'N/A') .. '^7')
                    Logger.Info('' .. data.apiKey .. '^7')
                    
                    -- Store in Config for easy access
                    if Config then
                        Config.GlobalBan = Config.GlobalBan or {}
                        Config.GlobalBan.ApiKey = data.apiKey
                        Config.GlobalBan.ServerId = data.serverId
                    end
                    
                    return true, registrationInfo
                else
                    Logger.Info('')
                    return false, nil
                end
            else
                Logger.Info('')
                return false, nil
            end
        elseif statusCode == 409 then
            Logger.Info('')
            -- Server already registered, response should contain existing key
            local success, data = pcall(json.decode, response)
            if success and data and data.apiKey then
                local registrationInfo = {
                    registered = true,
                    apiKey = data.apiKey,
                    serverId = data.serverId or nil,
                    registeredAt = os.date('%Y-%m-%d %H:%M:%S'),
                    timestamp = os.time()
                }
                
                -- Save it locally
                local resourcePath = GetResourcePath(GetCurrentResourceName())
                local filePath = resourcePath .. '/' .. REGISTRATION_FILE
                
                local file = io.open(filePath, 'w')
                if file then
                    file:write(json.encode(registrationInfo, { indent = true }))
                    file:close()
                    
                    registered = true
                    registrationData = registrationInfo
                    
                    Logger.Info('')
                    Logger.Info('' .. data.apiKey .. '^7')
                    
                    return true, registrationInfo
                end
            end
            return false, nil
        else
            Logger.Info('')
            Logger.Info('' .. statusCode .. '^7')
            Logger.Info('' .. (response or 'No response') .. '^7')
            return false, nil
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- Server event for manual registration
RegisterNetEvent('ec:registerGlobalBan', function()
    local src = source
    local success, regData = RegisterWithGlobalBanAPI()
    TriggerClientEvent('ec:registerGlobalBanResponse', src, { success = success, data = regData })
end)

-- Server event to check registration status
RegisterNetEvent('ec:checkGlobalBanRegistration', function()
    local src = source
    local isRegistered, regData = IsGlobalBanRegistered()
    TriggerClientEvent('ec:checkGlobalBanRegistrationResponse', src, { registered = isRegistered, data = regData })
end)

-- Auto-register on resource start (if enabled in config)
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Wait for config to load
    Wait(2000)
    
    -- Check if auto-registration is enabled
    if Config and Config.APIs and Config.APIs.GlobalBans and Config.APIs.GlobalBans.enabled then
        CreateThread(function()
            -- Wait for API Connection Manager to initialize
            Wait(10000) -- Wait 10 seconds after startup for Host API
            Logger.Info('')
            Logger.Info('')
            
            -- Check if Host API is ready
            local hostApiReady = false
            for i = 1, 5 do
                PerformHttpRequest('http://127.0.0.1:3000/api/health', function(statusCode, response, headers)
                    if statusCode == 200 then
                        hostApiReady = true
                    end
                end, 'GET', '', {})
                
                Wait(2000)
                
                if hostApiReady then
                    break
                end
            end
            
            if hostApiReady then
                Logger.Info('')
            else
                Logger.Info('')
            end
            
            RegisterWithGlobalBanAPI()
        end)
    else
        Logger.Info('')
    end
end)

-- Export functions for use in other scripts
exports('IsGlobalBanRegistered', IsGlobalBanRegistered)
exports('RegisterWithGlobalBanAPI', RegisterWithGlobalBanAPI)