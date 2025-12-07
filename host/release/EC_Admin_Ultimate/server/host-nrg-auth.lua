-- EC Admin Ultimate - NRG Staff Authentication
-- Cross-city NRG staff verification
-- Author: NRG Development
-- Version: 1.0.0

-- NRG Staff identifiers (add your staff here)
local NRG_STAFF = {
    -- Steam IDs
    steam = {
        -- Add NRG staff Steam IDs here
        -- Example: 'steam:110000103fd1bb1',
    },
    
    -- License IDs
    license = {
        -- Add NRG staff License IDs here
        -- Example: 'license:a1b2c3d4e5f6g7h8',
    },
    
    -- Discord IDs
    discord = {
        -- Add NRG staff Discord IDs here
        -- Example: 'discord:123456789012345678',
    },
    
    -- FiveM IDs
    fivem = {
        -- Add NRG staff FiveM IDs here
        -- Example: 'fivem:123456',
    }
}

-- Check if player is NRG staff
function IsNRGStaff(source)
    local identifiers = GetPlayerIdentifiers(source)
    
    for _, identifier in ipairs(identifiers) do
        -- Check Steam
        for _, steamId in ipairs(NRG_STAFF.steam) do
            if identifier == steamId then
                return true, 'steam'
            end
        end
        
        -- Check License
        for _, licenseId in ipairs(NRG_STAFF.license) do
            if identifier == licenseId then
                return true, 'license'
            end
        end
        
        -- Check Discord
        for _, discordId in ipairs(NRG_STAFF.discord) do
            if identifier == discordId then
                return true, 'discord'
            end
        end
        
        -- Check FiveM
        for _, fivemId in ipairs(NRG_STAFF.fivem) do
            if identifier == fivemId then
                return true, 'fivem'
            end
        end
    end
    
    -- Check against NRG Staff API
    local isStaff = CheckNRGStaffAPI(source)
    if isStaff then
        return true, 'api'
    end
    
    return false, nil
end

-- Check NRG Staff API (cross-city verification)
function CheckNRGStaffAPI(source)
    local identifiers = GetPlayerIdentifiers(source)
    
    if not identifiers or #identifiers == 0 then
        return false
    end
    
    -- Check if host mode is available
    local hostSecret = GetConvar('ec_host_api_key', '')
    if hostSecret == '' then
        return false
    end
    
    -- Call authentication API
    local endpoint = '/api/v1/auth/verify-staff'
    local data = {
        identifiers = identifiers,
        playerName = GetPlayerName(source)
    }
    
    local isVerified = false
    
    exports['ec_admin_ultimate']:CallHostAPI(endpoint, 'POST', data, function(success, response)
        if success and response and response.verified then
            isVerified = true
            
            -- Cache the verification
            CacheNRGStaffVerification(source, response.staffData)
        end
    end)
    
    -- Wait for response (synchronous for now)
    Wait(500)
    
    return isVerified
end

-- Cache staff verification
local staffVerificationCache = {}

function CacheNRGStaffVerification(source, staffData)
    local identifier = GetPlayerIdentifiers(source)[1]
    
    staffVerificationCache[identifier] = {
        verified = true,
        staffData = staffData,
        cachedAt = os.time(),
        expiresAt = os.time() + 3600 -- Cache for 1 hour
    }
end

-- Get cached verification
function GetCachedNRGStaffVerification(source)
    local identifier = GetPlayerIdentifiers(source)[1]
    local cached = staffVerificationCache[identifier]
    
    if cached and cached.expiresAt > os.time() then
        return cached.verified, cached.staffData
    end
    
    return false, nil
end

-- Grant NRG staff permissions
function GrantNRGStaffPermissions(source)
    local isStaff, method = IsNRGStaff(source)
    
    if not isStaff then
        return false
    end
    
    -- Grant all host permissions
    local permissions = {
        'ec_admin.all',
        'ec_admin.host.view',
        'ec_admin.host.control',
        'ec_admin.host.configure',
        'ec_admin.host.emergency',
        'ec_admin.host.ban',
        'ec_admin.host.unban',
        'ec_admin.host.appeals',
        'ec_admin.host.broadcast',
        'ec_admin.host.backup',
        'ec_admin.host.restore',
        'ec_admin.host.export',
        'ec_admin.host.webhooks'
    }
    
    -- Grant permissions (this would integrate with your permission system)
    for _, permission in ipairs(permissions) do
        ExecuteCommand(string.format('add_principal identifier.%s %s', 
            GetPlayerIdentifiers(source)[1], permission))
    end
    
    Logger.Info(string.format('', 
        GetPlayerName(source), method))
    
    return true
end

-- Remove NRG staff permissions on disconnect
function RevokeNRGStaffPermissions(source)
    local identifier = GetPlayerIdentifiers(source)[1]
    
    -- Remove from cache
    staffVerificationCache[identifier] = nil
    
    -- Revoke permissions (optional, depends on your ACE setup)
    -- This is handled automatically if using principal-based permissions
end

-- Get NRG staff list
function GetNRGStaffList()
    local staffList = {}
    
    -- From local config
    for _, steamId in ipairs(NRG_STAFF.steam) do
        table.insert(staffList, {
            identifier = steamId,
            type = 'steam',
            source = 'local'
        })
    end
    
    for _, licenseId in ipairs(NRG_STAFF.license) do
        table.insert(staffList, {
            identifier = licenseId,
            type = 'license',
            source = 'local'
        })
    end
    
    -- From API
    exports['ec_admin_ultimate']:CallHostAPI('/api/v1/auth/staff-list', 'GET', nil, function(success, response)
        if success and response and response.staff then
            for _, staff in ipairs(response.staff) do
                table.insert(staffList, {
                    identifier = staff.identifier,
                    name = staff.name,
                    role = staff.role,
                    type = 'api',
                    source = 'api'
                })
            end
        end
    end)
    
    return staffList
end

-- Add NRG staff member
function AddNRGStaff(source, staffData)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.manage_staff') then
        return false, 'No permission'
    end
    
    -- Add to API
    exports['ec_admin_ultimate']:CallHostAPI('/api/v1/auth/staff/add', 'POST', {
        identifier = staffData.identifier,
        name = staffData.name,
        role = staffData.role,
        addedBy = GetPlayerName(source)
    }, function(success, response)
        if success then
            Logger.Info(string.format('', staffData.name))
        end
    end)
    
    return true, 'Staff member added'
end

-- Remove NRG staff member
function RemoveNRGStaff(source, identifier)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.manage_staff') then
        return false, 'No permission'
    end
    
    -- Remove from API
    exports['ec_admin_ultimate']:CallHostAPI('/api/v1/auth/staff/remove', 'POST', {
        identifier = identifier,
        removedBy = GetPlayerName(source)
    }, function(success, response)
        if success then
            Logger.Info(string.format('', identifier))
        end
    end)
    
    return true, 'Staff member removed'
end

-- Event handlers
AddEventHandler('playerConnecting', function()
    local source = source
    
    -- Check if NRG staff
    local isStaff = IsNRGStaff(source)
    
    if isStaff then
        Logger.Info(string.format('', GetPlayerName(source)))
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    RevokeNRGStaffPermissions(source)
end)

-- Exports
exports('IsNRGStaff', IsNRGStaff)
exports('CheckNRGStaffAPI', CheckNRGStaffAPI)
exports('GrantNRGStaffPermissions', GrantNRGStaffPermissions)
exports('GetNRGStaffList', GetNRGStaffList)
exports('AddNRGStaff', AddNRGStaff)
exports('RemoveNRGStaff', RemoveNRGStaff)

Logger.Info('👥 NRG Staff Authentication system loaded')
