--[[
    EC Admin Ultimate - Owner Protection System
    PRD Section 10: Anti-Cheat, Roles & Owner Protection
    
    Features:
    - Prevents admins from banning/kicking owners
    - Owner identifier verification
    - Anti-cheat whitelist for owners/staff
    - Audit logging for all admin actions
    - Owner bypass for all restrictions
]]

local OwnerProtection = {
    owners = {},
    nrgStaff = {},  -- NRG staff identifiers (bypass everything)
    initialized = false
}

-- Known NRG staff identifiers (these bypass ALL restrictions)
local NRG_STAFF_IDENTIFIERS = {
    -- Add NRG staff Steam/License IDs here
    -- Example: "steam:110000123456789",
    -- Example: "license:abc123def456",
    -- These are loaded from convars in production
}

--[[
    Initialize owner identifiers from convars
]]
local function InitializeOwners()
    if OwnerProtection.initialized then
        return true
    end
    
    Logger.Info("[Owner Protection] Initializing owner identifiers...", '🛡️')
    
    -- Load owner identifiers from convars
    local identifiers = {
        steam = GetConvar('ec_owner_steam', ''),
        license = GetConvar('ec_owner_license', ''),
        fivem = GetConvar('ec_owner_fivem', ''),
        discord = GetConvar('ec_owner_discord', '')
    }
    
    local count = 0
    for idType, idValue in pairs(identifiers) do
        if idValue ~= '' then
            table.insert(OwnerProtection.owners, idValue)
            Logger.Success(string.format("  ✓ Owner %s: %s", idType, idValue))
            count = count + 1
        end
    end
    
    -- Load NRG staff identifiers from convars
    local nrgStaffCount = 0
    for i = 1, 10 do  -- Support up to 10 NRG staff
        local nrgIdentifier = GetConvar('ec_nrg_staff_' .. i, '')
        if nrgIdentifier ~= '' then
            table.insert(OwnerProtection.nrgStaff, nrgIdentifier)
            Logger.Success(string.format("  ✓ NRG Staff #%d: %s", i, nrgIdentifier))
            nrgStaffCount = nrgStaffCount + 1
        end
    end
    
    -- Add hardcoded NRG staff (for NRG internal use only)
    for _, identifier in ipairs(NRG_STAFF_IDENTIFIERS) do
        table.insert(OwnerProtection.nrgStaff, identifier)
        nrgStaffCount = nrgStaffCount + 1
    end
    
    if count == 0 then
        Logger.Warn("[Owner Protection] WARNING: No owner identifiers configured!", '⚠️')
        Logger.Warn("[Owner Protection] Set at least one: setr ec_owner_steam/license/fivem/discord")
        Logger.Warn("[Owner Protection] Example: setr ec_owner_steam \"steam:110000123456789\"")
        return false
    end
    
    Logger.Success(string.format("[Owner Protection] Loaded %d owner identifier(s)", count), '✅')
    if nrgStaffCount > 0 then
        Logger.Success(string.format("[Owner Protection] Loaded %d NRG staff identifier(s)", nrgStaffCount), '✅')
        Logger.Info("[Owner Protection] 🛡️  NRG staff bypass all restrictions")
    end
    OwnerProtection.initialized = true
    return true
end

--[[
    Check if player is an owner
    @param source - Player server ID
    @return boolean
]]
function IsPlayerOwner(source)
    if not OwnerProtection.initialized then
        InitializeOwners()
    end
    
    if source == 0 then
        -- Console is always owner
        return true
    end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then
        return false
    end
    
    for _, playerIdentifier in ipairs(identifiers) do
        for _, ownerIdentifier in ipairs(OwnerProtection.owners) do
            if playerIdentifier == ownerIdentifier then
                return true
            end
        end
    end
    
    return false
end

--[[
    Check if target player is an owner (by identifier)
    @param identifier - Player identifier (steam:xxx, license:xxx, etc.)
    @return boolean
]]
local function IsIdentifierOwner(identifier)
    if not OwnerProtection.initialized then
        InitializeOwners()
    end
    
    for _, ownerIdentifier in ipairs(OwnerProtection.owners) do
        if identifier == ownerIdentifier then
            return true
        end
    end
    
    return false
end

--[[
    Check if player is NRG staff
    @param source - Player server ID
    @return boolean
]]
function IsPlayerNRGStaff(source)
    if not OwnerProtection.initialized then
        InitializeOwners()
    end
    
    if source == 0 then
        -- Console is not NRG staff (but is owner)
        return false
    end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then
        return false
    end
    
    for _, playerIdentifier in ipairs(identifiers) do
        for _, staffIdentifier in ipairs(OwnerProtection.nrgStaff) do
            if playerIdentifier == staffIdentifier then
                return true
            end
        end
    end
    
    return false
end

--[[
    Validate admin action against owner protection
    @param adminSource - Admin player ID
    @param targetSource - Target player ID
    @param action - Action type (ban, kick, warn, etc.)
    @return boolean, string - success, error message
]]
function ValidateAdminAction(adminSource, targetSource, action)
    -- Console can do anything
    if adminSource == 0 then
        return true, nil
    end
    
    -- Check if admin is owner or NRG staff
    local adminIsOwner = IsPlayerOwner(adminSource)
    local adminIsNRGStaff = IsPlayerNRGStaff(adminSource)
    
    -- Check if target is owner or NRG staff
    local targetIsOwner = IsPlayerOwner(targetSource)
    local targetIsNRGStaff = IsPlayerNRGStaff(targetSource)
    
    -- NRG staff cannot be targeted by anyone (except console)
    if targetIsNRGStaff then
        local adminName = GetPlayerName(adminSource) or "Unknown"
        print(string.format("[Owner Protection] BLOCKED: %s (%d) attempted to %s NRG STAFF (ID: %d)", 
            adminName, adminSource, action, targetSource))
        
        -- Log this attempt to database
        if MySQL and MySQL.ready then
            MySQL.insert.await('INSERT INTO ec_admin_logs (admin_identifier, admin_name, action, target_identifier, target_name, details, timestamp) VALUES (?, ?, ?, ?, ?, ?, UNIX_TIMESTAMP())', {
                GetPlayerIdentifier(adminSource, 0),
                adminName,
                'BLOCKED_' .. string.upper(action),
                GetPlayerIdentifier(targetSource, 0),
                GetPlayerName(targetSource) or "Unknown",
                json.encode({ blocked = true, reason = "nrg_staff_protection" })
            })
        end
        
        return false, "⛔ NRG staff members cannot be targeted by admin actions."
    end
    
    -- Owners cannot be targeted by non-owners (unless admin is NRG staff)
    if targetIsOwner and not (adminIsOwner or adminIsNRGStaff) then
        local adminName = GetPlayerName(adminSource) or "Unknown"
        print(string.format("[Owner Protection] BLOCKED: %s (%d) attempted to %s owner (ID: %d)", 
            adminName, adminSource, action, targetSource))
        
        -- Log this attempt to database
        if MySQL and MySQL.ready then
            MySQL.insert.await('INSERT INTO ec_admin_logs (admin_identifier, admin_name, action, target_identifier, target_name, details, timestamp) VALUES (?, ?, ?, ?, ?, ?, UNIX_TIMESTAMP())', {
                GetPlayerIdentifier(adminSource, 0),
                adminName,
                'BLOCKED_' .. string.upper(action),
                GetPlayerIdentifier(targetSource, 0),
                GetPlayerName(targetSource) or "Unknown",
                json.encode({ blocked = true, reason = "owner_protection" })
            })
        end
        
        return false, "You cannot perform this action on the server owner."
    end
    
    return true, nil
end

--[[
    Audit log for admin actions
    @param adminSource - Admin player ID
    @param action - Action type
    @param targetSource - Target player ID (optional)
    @param details - Action details (optional)
    @param reason - Action reason (optional)
]]
function LogAdminAction(adminSource, action, targetSource, details, reason)
    local adminIdentifier = adminSource == 0 and "console" or GetPlayerIdentifier(adminSource, 0)
    local adminName = adminSource == 0 and "Console" or GetPlayerName(adminSource) or "Unknown"
    
    local targetIdentifier = nil
    local targetName = nil
    
    if targetSource then
        targetIdentifier = GetPlayerIdentifier(targetSource, 0)
        targetName = GetPlayerName(targetSource) or "Unknown"
    end
    
    local logData = {
        actor_identifier = adminIdentifier,
        actor_name = adminName,
        action_type = action,
        target_identifier = targetIdentifier,
        target_name = targetName,
        details = json.encode(details or {}),
        reason = reason or "",
        created_at = os.time()
    }
    
    -- Console log
    if targetSource then
        print(string.format("[Admin Action] %s (%s) performed %s on %s (%s) - Reason: %s", 
            adminName, adminIdentifier, action, targetName, targetIdentifier, reason or "None"))
    else
        print(string.format("[Admin Action] %s (%s) performed %s - Reason: %s", 
            adminName, adminIdentifier, action, reason or "None"))
    end
    
    -- Database log
    if MySQL and MySQL.ready then
        MySQL.insert('INSERT INTO ec_admin_logs (admin_identifier, admin_name, action, target_identifier, target_name, details, timestamp) VALUES (?, ?, ?, ?, ?, ?, FROM_UNIXTIME(?))', {
            logData.actor_identifier,
            logData.actor_name,
            logData.action_type,
            logData.target_identifier,
            logData.target_name,
            logData.details,
            logData.created_at
        })
    end
end

--[[
    Safe ban with owner protection
    @param adminSource - Admin player ID
    @param targetSource - Target player ID
    @param reason - Ban reason
    @param duration - Ban duration in seconds (0 = permanent)
    @return boolean, string - success, message
]]
function SafeBanPlayer(adminSource, targetSource, reason, duration)
    -- Validate action
    local valid, error = ValidateAdminAction(adminSource, targetSource, "ban")
    if not valid then
        return false, error
    end
    
    -- Log the action
    LogAdminAction(adminSource, "BAN", targetSource, {
        duration = duration,
        permanent = duration == 0
    }, reason)
    
    -- Execute ban (your existing ban logic here)
    local targetIdentifier = GetPlayerIdentifier(targetSource, 0)
    local targetName = GetPlayerName(targetSource) or "Unknown"
    
    if MySQL and MySQL.ready then
        local expiresAt = duration > 0 and (os.time() + duration) or 0
        local banType = duration > 0 and "temporary" or "permanent"

        local _ = MySQL.query.await('INSERT INTO ec_admin_bans (identifier, player_name, banned_by, reason, ban_type, expires, active) VALUES (?, ?, ?, ?, ?, ?, TRUE)', {
            targetIdentifier,
            targetName,
            GetPlayerIdentifier(adminSource, 0),
            reason,
            banType,
            expiresAt
        })
        
        -- Kick player
        DropPlayer(targetSource, string.format("🚫 Banned: %s\nDuration: %s", reason, banType))
        
        return true, string.format("%s has been banned (%s)", targetName, banType)
    end
    
    return false, "Database error"
end

--[[
    Safe kick with owner protection
    @param adminSource - Admin player ID
    @param targetSource - Target player ID
    @param reason - Kick reason
    @return boolean, string - success, message
]]
function SafeKickPlayer(adminSource, targetSource, reason)
    -- Validate action
    local valid, error = ValidateAdminAction(adminSource, targetSource, "kick")
    if not valid then
        return false, error
    end
    
    -- Log the action
    LogAdminAction(adminSource, "KICK", targetSource, {}, reason)
    
    -- Execute kick
    local targetName = GetPlayerName(targetSource) or "Unknown"
    DropPlayer(targetSource, string.format("⚠️ Kicked: %s", reason))
    
    return true, string.format("%s has been kicked", targetName)
end

--[[
    Safe warn with owner protection
    @param adminSource - Admin player ID
    @param targetSource - Target player ID
    @param reason - Warning reason
    @return boolean, string - success, message
]]
function SafeWarnPlayer(adminSource, targetSource, reason)
    -- Validate action
    local valid, error = ValidateAdminAction(adminSource, targetSource, "warn")
    if not valid then
        return false, error
    end
    
    -- Log the action
    LogAdminAction(adminSource, "WARN", targetSource, {}, reason)
    
    -- Execute warning
    local targetIdentifier = GetPlayerIdentifier(targetSource, 0)
    local targetName = GetPlayerName(targetSource) or "Unknown"
    
    if MySQL and MySQL.ready then
        MySQL.insert.await('INSERT INTO ec_admin_warnings (identifier, player_name, warned_by, reason) VALUES (?, ?, ?, ?)', {
            targetIdentifier,
            targetName,
            GetPlayerIdentifier(adminSource, 0),
            reason
        })
        
        -- Notify player
        TriggerClientEvent('chat:addMessage', targetSource, {
            color = {255, 165, 0},
            multiline = true,
            args = {"⚠️ Admin Warning", reason}
        })
        
        return true, string.format("%s has been warned", targetName)
    end
    
    return false, "Database error"
end

--[[
    Anti-cheat whitelist check
    @param source - Player server ID
    @return boolean - true if player should be whitelisted from AC
]]
function ShouldWhitelistFromAC(source)
    -- Owners and staff always whitelisted from anti-cheat
    return IsPlayerOwner(source) or IsPlayerAdmin(source)
end

-- Initialize on startup
CreateThread(function()
    Wait(2000)
    InitializeOwners()
end)

-- Exports
exports('IsPlayerOwner', IsPlayerOwner)
exports('IsPlayerNRGStaff', IsPlayerNRGStaff)  -- NEW: Export NRG staff check
exports('ValidateAdminAction', ValidateAdminAction)
exports('LogAdminAction', LogAdminAction)
exports('SafeBanPlayer', SafeBanPlayer)
exports('SafeKickPlayer', SafeKickPlayer)
exports('SafeWarnPlayer', SafeWarnPlayer)
exports('ShouldWhitelistFromAC', ShouldWhitelistFromAC)

Logger.Success("[Owner Protection] System loaded", '🛡️')
Logger.Info("[Owner Protection] 🛡️  Protections active:")
Logger.Info("[Owner Protection]   ✅ Server owners cannot be banned/kicked/warned")
Logger.Info("[Owner Protection]   ✅ NRG staff bypass all restrictions")
Logger.Info("[Owner Protection]   ✅ Anti-cheat whitelist for owners/staff")