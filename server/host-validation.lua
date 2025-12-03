--[[
    EC ADMIN ULTIMATE - HOST VALIDATION
    Internal NRG use only - verifies host folder and secret
    🔒 PROTECTED: Not included in customer escrow
]]

-- 🔒 INTERNAL SECRET - DO NOT SHARE WITH CUSTOMERS
local NRG_HOST_SECRET = "nrg_host_tnD8W1nm1shTIZ3KO4DxGPzCydYfRFKUjyJvskFQBMAdNyj7EPuqosf8ZCfEAJyq"

-- Host validation state
local hostModeEnabled = false
local hostSecretValid = false

-- NRG Staff identifiers (hardcoded for security)
local NRG_STAFF_IDENTIFIERS = {
    -- Add NRG staff Steam/License/Discord IDs here
    -- These are the ONLY people who can access the Host Dashboard
    -- Example: "steam:110000103fd1bb1",
    -- Example: "license:a1b2c3d4e5f6g7h8",
    -- Example: "discord:123456789012345678"
}

-- Check if /host/ folder exists
local function CheckHostFolderExists()
    -- Try to load a known host file to verify folder exists
    local success = LoadResourceFile(GetCurrentResourceName(), "host/.hostmarker")
    return success ~= nil
end

-- Validate host secret from config
local function ValidateHostSecret()
    if not Config or not Config.Host then
        return false
    end
    
    -- Check if secret matches
    return Config.Host.secret == NRG_HOST_SECRET
end

-- Check if player is NRG staff
local function IsNRGStaff(source)
    local identifiers = GetPlayerIdentifiers(source)
    
    for _, identifier in ipairs(identifiers) do
        for _, staffIdentifier in ipairs(NRG_STAFF_IDENTIFIERS) do
            if identifier == staffIdentifier then
                return true
            end
        end
    end
    
    return false
end

-- Initialize host validation on server start
CreateThread(function()
    Wait(2000) -- Wait for Config to load
    
    -- Check host folder
    hostModeEnabled = CheckHostFolderExists()
    
    -- Validate secret if host folder exists
    if hostModeEnabled then
        hostSecretValid = ValidateHostSecret()
        
        if hostSecretValid then
            Logger.Success("[EC Admin] ✓ Host Mode ENABLED - NRG Internal Dashboard Active", '🏢')
            Logger.Info("[EC Admin] 🔒 Host Dashboard restricted to NRG staff only")
        else
            Logger.Error("[EC Admin] ✗ Host folder detected but secret validation FAILED", '❌')
            Logger.Error("[EC Admin] ✗ Host Dashboard DISABLED - Invalid credentials", '❌')
            hostModeEnabled = false
        end
    else
        Logger.Info("[EC Admin] Customer Mode - Host Dashboard hidden", 'ℹ️')
    end
end)

-- NUI Callback: Check if player has host access
lib.callback.register('ec_admin:checkHostAccess', function(source)
    -- Must have host folder + valid secret + be NRG staff
    local hasAccess = hostModeEnabled and hostSecretValid and IsNRGStaff(source)
    
    return {
        hostMode = hostModeEnabled and hostSecretValid,
        isNRGStaff = IsNRGStaff(source),
        hasAccess = hasAccess
    }
end)

-- Export for other scripts
exports('IsHostModeEnabled', function()
    return hostModeEnabled and hostSecretValid
end)

exports('IsNRGStaff', function(source)
    return IsNRGStaff(source)
end)

-- Prevent non-NRG staff from accessing host endpoints
RegisterNetEvent('ec_admin:host:requestData', function(dataType)
    local source = source
    
    -- Validate access
    if not hostModeEnabled or not hostSecretValid then
        Logger.Error(("Player %s attempted to access host data - Host mode not enabled"):format(source), '🚫')
        return
    end
    
    if not IsNRGStaff(source) then
        Logger.Error(("Player %s attempted to access host data - Not NRG staff"):format(source), '🚫')
        -- Log potential stolen code attempt
        TriggerEvent('ec_admin:security:logUnauthorizedAccess', source, 'host_dashboard_attempt')
        return
    end
    
    -- Process host data request
    TriggerEvent('ec_admin:host:processDataRequest', source, dataType)
end)

Logger.Success("Host validation system loaded", '🛡️')

-- ==========================================
-- System Info (Framework/Database) for Sidebar
-- ==========================================
-- Provides accurate, non-mock environment details to the UI
lib.callback.register('ec_admin:getSystemInfo', function(source)
    -- Framework detection
    local frameworkType = 'standalone'
    if _G.ECFramework and (_G.ECFramework.Type or _G.ECFramework.Framework or _G.ECFramework.Name) then
        frameworkType = (_G.ECFramework.Type or _G.ECFramework.Framework or _G.ECFramework.Name)
    else
        if GetResourceState('qbx_core') == 'started' then
            frameworkType = 'qbx'
        elseif GetResourceState('qb-core') == 'started' then
            frameworkType = 'qb-core'
        elseif GetResourceState('es_extended') == 'started' then
            frameworkType = 'esx'
        else
            frameworkType = 'standalone'
        end
    end

    -- Database detection
    local dbType = 'none'
    if GetResourceState('oxmysql') == 'started' then
        dbType = 'oxmysql'
    elseif GetResourceState('mysql-async') == 'started' then
        dbType = 'mysql-async'
    end

    local dbConnected = false
    if MySQL then
        if type(MySQL.ready) == 'boolean' then
            dbConnected = MySQL.ready
        elseif MySQL.Sync or MySQL.query then
            -- Assume connected if the adapter is present
            dbConnected = true
        end
    end

    return {
        framework = {
            detected = frameworkType ~= 'standalone',
            type = frameworkType
        },
        database = {
            connected = dbConnected == true,
            type = dbType
        }
    }
end)
