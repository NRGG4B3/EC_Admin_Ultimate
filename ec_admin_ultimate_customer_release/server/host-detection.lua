--[[
    EC Admin Ultimate - Host Mode Detection
    Detects if running in host mode (host/ folder exists)
    Also checks if player is NRG staff (via API)
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

-- Check if player is NRG staff (via API)
local function isNRGStaff(source)
    if not source or source == 0 then return false end
    
    -- In host mode, always check for NRG staff
    local isHost = hostFolderExists()
    
    -- In host mode, if NRG staff auto-access is enabled, check framework admin first
    if isHost and Config and Config.NRGStaff and Config.NRGStaff.autoAccess and Config.NRGStaff.autoAccess.enabled then
        -- Quick check: If player is framework admin in host mode, they're likely NRG staff
        if ECFramework and ECFramework.IsAdminGroup then
            local success, isAdmin = pcall(function()
                return ECFramework.IsAdminGroup(source)
            end)
            if success and isAdmin then
                return true
            end
        end
    end
    
    -- Check if NRG staff auto-access is enabled
    if Config and Config.NRGStaff and Config.NRGStaff.autoAccess and Config.NRGStaff.autoAccess.enabled then
        -- Check if player has NRG staff permission (from database)
        if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
            local success, hasNRGStaff = pcall(function()
                return exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.nrg.staff')
            end)
            if success and hasNRGStaff then
                return true
            end
        end
        
        -- Check via API (if configured)
        if Config.NRGStaff.autoAccess.checkAPI then
            -- Get player identifiers
            local identifiers = GetPlayerIdentifiers(source)
            if identifiers then
                local license = nil
                local steam = nil
                local discord = nil
                
                for _, id in ipairs(identifiers) do
                    if string.find(id, 'license:') then
                        license = id
                    elseif string.find(id, 'steam:') then
                        steam = id
                    elseif string.find(id, 'discord:') then
                        discord = id
                    end
                end
                
                -- Call NRG staff verification API
                -- Check each identifier (license, steam, discord)
                local identifiersToCheck = {}
                if license then table.insert(identifiersToCheck, license) end
                if steam then table.insert(identifiersToCheck, steam) end
                if discord then table.insert(identifiersToCheck, discord) end
                
                -- Try host API first (if in host mode)
                if isHost and exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
                    for _, identifier in ipairs(identifiersToCheck) do
                        -- URL encode identifier
                        local encodedId = string.gsub(identifier, ':', '%%3A')
                        local success, apiResponse = pcall(function()
                            return exports['ec_admin_ultimate']:CallHostAPI(
                                '/api/staff/verify/' .. encodedId,
                                'GET',
                                nil
                            )
                        end)
                        
                        if success and apiResponse then
                            if apiResponse.success and apiResponse.data then
                                -- API returns { isStaff: true, staff: {...} } or { success: true, data: { isStaff: true } }
                                if apiResponse.data.isStaff == true or apiResponse.data.isNRGStaff == true then
                                    return true
                                end
                            elseif apiResponse.isStaff == true then
                                -- Direct response format
                                return true
                            end
                        end
                    end
                end
                
                -- Fallback: Try public API (for customer servers or if host API fails)
                if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallAPI then
                    for _, identifier in ipairs(identifiersToCheck) do
                        -- URL encode identifier
                        local encodedId = string.gsub(identifier, ':', '%%3A')
                        local success, apiResponse = pcall(function()
                            return exports['ec_admin_ultimate']:CallAPI(
                                '/api/staff/verify/' .. encodedId,
                                'GET',
                                nil,
                        {
                                    ['Authorization'] = 'Bearer ' .. (Config.HostApi and Config.HostApi.secret or ''),
                                    ['X-API-Key'] = Config.HostApi and Config.HostApi.secret or ''
                        }
                    )
                        end)
                    
                        if success and apiResponse then
                            if apiResponse.success and apiResponse.data then
                                -- API returns { isStaff: true, staff: {...} } or { success: true, data: { isStaff: true } }
                                if apiResponse.data.isStaff == true or apiResponse.data.isNRGStaff == true then
                                    return true
                                end
                            elseif apiResponse.isStaff == true then
                                -- Direct response format
                                return true
                            end
                        end
                    end
                    end
                end
            end
            
        -- Fallback: Check if player is in admin group (for development/testing)
            if ECFramework and ECFramework.IsAdminGroup then
            local success, isAdmin = pcall(function()
                return ECFramework.IsAdminGroup(source)
            end)
            if success and isAdmin then
                return true
            end
        end
    end
    
    return false
end

-- Get host mode status
local function getHostModeStatus(source)
    local isHost = hostFolderExists()
    local isNRG = isNRGStaff(source)
    
    return {
        isHost = isHost,
        isNRGStaff = isNRG,
        canAccessHostDashboard = isHost or isNRG,
        mode = isHost and 'host' or 'customer'
    }
end

-- Send host status to client
RegisterNetEvent('ec_admin:requestHostStatus', function()
    local source = source
    local status = getHostModeStatus(source)
    
    TriggerClientEvent('ec_admin:hostStatus', source, status)
end)

-- Callback: Get host status (for NUI bridge)
lib.callback.register('ec_admin:getHostStatus', function(source)
    return getHostModeStatus(source)
end)

-- Export function
exports('IsHostMode', function()
    return hostFolderExists()
end)

exports('IsNRGStaff', function(source)
    return isNRGStaff(source)
end)

exports('CanAccessHostDashboard', function(source)
    local status = getHostModeStatus(source)
    return status.canAccessHostDashboard
end)

-- Initialize on resource start
CreateThread(function()
    Wait(1000)
    local isHost = hostFolderExists()
    if isHost then
        print("^2[Host Detection]^7 Host mode ENABLED (host/ folder detected)^0")
        if Config then
            Config.Host = Config.Host or {}
            Config.Host.enabled = true
            Config.Host.mode = 'host'
        end
    else
        print("^2[Host Detection]^7 Customer mode (host/ folder not found)^0")
        if Config then
            Config.Host = Config.Host or {}
            Config.Host.enabled = false
            Config.Host.mode = 'customer'
        end
    end
end)

print("^2[Host Detection]^7 Host detection system loaded^0")

