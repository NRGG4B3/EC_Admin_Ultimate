--[[
    EC Admin Ultimate - Unified Permission System
    Loads FIRST - provides EC_Perms.Has() for all other scripts
]]

EC_Perms = {}

local resourceName = GetCurrentResourceName()

local ActionPermissionNodes = {
    ban = 'ec_admin.ban',
    kick = 'ec_admin.kick',
    teleport = 'ec_admin.teleport',
    bring = 'ec_admin.teleport',
    menu = 'ec_admin.menu',
    reports = 'ec_admin.reports.manage',
    vehicles = 'ec_admin.vehicle.spawn',
    deletevehicle = 'ec_admin.vehicle.delete',
    spectate = 'ec_admin.spectate',
    noclip = 'ec_admin.noclip',
    freeze = 'ec_admin.freeze',
    revive = 'ec_admin.revive',
    giveitem = 'ec_admin.giveitem',
    economy = 'ec_admin.givemoney',
    announce = 'ec_admin.announce'
}

local RankPriority = {
    owner = 5,
    super_admin = 4,
    admin = 3,
    moderator = 2,
    staff = 1,
    user = 0
}

-- Database fallback cache
local dbPermissions = {}

-- Initialize permission system
function EC_Perms.Init()
    Logger.Info('🔐 Permission system initializing...')
    
    -- Determine permission mode
    local permMode = Config and Config.Permissions and Config.Permissions.system or 'both'
    
    if permMode == 'both' then
        Logger.Info('🔐 Mode: ACE + Database permissions')
        if Config and Config.Database and Config.Database.enabled then
            EC_Perms.LoadFromDB()
        else
            Logger.Warn('⚠️ Database disabled, using ACE only')
        end
    elseif permMode == 'ace' then
        Logger.Info('🔐 Mode: ACE permissions only')
    elseif permMode == 'database' then
        Logger.Info('🔐 Mode: Database permissions only')
        if Config and Config.Database and Config.Database.enabled then
            EC_Perms.LoadFromDB()
        end
    end
    
    Logger.Success('✅ Permission system ready')
end

-- Load permissions from database
function EC_Perms.LoadFromDB()
    if not MySQL then
        Logger.Warn('⚠️ MySQL not available, skipping database permissions')
        return
    end
    
    -- Try to load permissions from database
    MySQL.query('SELECT * FROM ec_admin_permissions LIMIT 1', {}, function(result)
        if result then
            Logger.Info('📋 Database permissions available')
            -- Load all permissions
            MySQL.query('SELECT * FROM ec_admin_permissions', {}, function(perms)
                if perms then
                    for _, perm in ipairs(perms) do
                        dbPermissions[perm.identifier] = dbPermissions[perm.identifier] or {}
                        table.insert(dbPermissions[perm.identifier], perm.permission)
                    end
                    Logger.Success('✅ Loaded ' .. #perms .. ' database permissions')
                end
            end)
        else
            Logger.Warn('⚠️ Database permissions table not found, using ACE only')
        end
    end)
end

-- Check if player has permission (ACE first, then DB fallback)
function EC_Perms.Has(source, permission)
    if not source then return false end
    
    -- Check NRG Staff in-memory permissions FIRST (highest priority)
    if EC_PERMISSIONS and EC_PERMISSIONS[source] and EC_PERMISSIONS[source].allPermissions then
        return true
    end
    
    -- Check ACE permission (second priority)
    if IsPlayerAceAllowed(source, permission) then
        return true
    end
    
    -- Fallback to database check
    local identifier = GetPlayerIdentifier(source, 0)
    if identifier and dbPermissions[identifier] then
        for _, perm in ipairs(dbPermissions[identifier]) do
            if perm == permission or perm == permission:match("^([^.]+)%.?") then
                return true
            end
        end
    end
    
    return false
end

-- Grant permission (adds to DB and cache)
function EC_Perms.Grant(identifier, permission)
    if not identifier or not permission then return false end
    
    dbPermissions[identifier] = dbPermissions[identifier] or {}
    table.insert(dbPermissions[identifier], permission)
    
    if MySQL and Config.Database and Config.Database.enabled then
        MySQL.insert('INSERT INTO ec_admin_permissions (identifier, permission) VALUES (?, ?)', {
            identifier, permission
        })
    end
    
    return true
end

-- Revoke permission
function EC_Perms.Revoke(identifier, permission)
    if not identifier or not permission then return false end
    
    if dbPermissions[identifier] then
        for i, perm in ipairs(dbPermissions[identifier]) do
            if perm == permission then
                table.remove(dbPermissions[identifier], i)
                break
            end
        end
    end
    
    if MySQL and Config.Database and Config.Database.enabled then
        MySQL.execute('DELETE FROM ec_admin_permissions WHERE identifier = ? AND permission = ?', {
            identifier, permission
        })
    end
    
    return true
end

-- Get all permissions for an identifier
function EC_Perms.GetAll(identifier)
    return dbPermissions[identifier] or {}
end

-- Check if source is admin (has base permission)
function EC_Perms.IsAdmin(source)
    return EC_Perms.Has(source, 'ec_admin.menu')
end

-- Check if source is super admin
function EC_Perms.IsSuperAdmin(source)
    return EC_Perms.Has(source, 'ec_admin.super')
end

-- Export for compatibility with old code
_G.HasAdminPermission = function(source, permission)
    return EC_Perms.Has(source, permission or 'ec_admin.menu')
end

local function logDenied(action, source, target, reason)
    local sourceName = GetPlayerName(source) or ('Unknown (' .. tostring(source) .. ')')
    local targetName = target and (GetPlayerName(target) or ('Unknown (' .. tostring(target) .. ')')) or 'N/A'
    Logger.Warn(string.format('[Permission Denied] Action: %s | Admin: %s | Target: %s | Reason: %s', action or 'unknown', sourceName, targetName, reason or 'No permission'))
end

local function isOwnerIdentifier(identifier)
    if not identifier or not Config or not Config.Owners then
        return false
    end

    return (Config.Owners.steam ~= '' and identifier == Config.Owners.steam)
        or (Config.Owners.license ~= '' and identifier == Config.Owners.license)
        or (Config.Owners.discord ~= '' and identifier == Config.Owners.discord)
        or (Config.Owners.fivem ~= '' and identifier == Config.Owners.fivem)
end

local function getPrimaryIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source) or {}
    for _, id in ipairs(identifiers) do
        if id:find('license:') then return id end
    end
    for _, id in ipairs(identifiers) do
        if id:find('steam:') then return id end
    end
    for _, id in ipairs(identifiers) do
        if id:find('discord:') then return id end
    end
    for _, id in ipairs(identifiers) do
        if id:find('fivem:') then return id end
    end
    return identifiers[1]
end

local function getAdminTeamMember(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in ipairs(identifiers) do
        local ok, member = pcall(function()
            return exports[resourceName] and exports[resourceName]:GetAdminMember(identifier) or nil
        end)

        if ok and member then
            return member
        end
    end
    return nil
end

local function determineRank(source)
    local identifier = getPrimaryIdentifier(source)
    if identifier and isOwnerIdentifier(identifier) then
        return 'owner'
    end

    local member = getAdminTeamMember(source)
    if member and member.rank then
        return member.rank
    end

    if EC_Perms and EC_Perms.Has then
        if EC_Perms.Has(source, 'ec_admin.all') or EC_Perms.Has(source, 'ec_admin.super') then
            return 'super_admin'
        end

        if EC_Perms.Has(source, 'ec_admin.menu') then
            return 'admin'
        end
    end

    if IsPlayerAceAllowed(source, 'ec_admin.all') then
        return 'super_admin'
    end

    return 'user'
end

local function rankValue(rank)
    return RankPriority[rank] or RankPriority.user
end

local function getPermissionNode(action)
    if not action or action == '' then
        return 'ec_admin.menu'
    end

    local key = string.lower(action)
    return ActionPermissionNodes[key] or ('ec_admin.' .. key)
end

local function hasNodePermission(source, node)
    if EC_Perms and EC_Perms.Has and EC_Perms.Has(source, node) then
        return true
    end

    if EC_Perms and EC_Perms.Has and EC_Perms.Has(source, 'ec_admin.all') then
        return true
    end

    if IsPlayerAceAllowed(source, 'ec_admin.all') or IsPlayerAceAllowed(source, node) then
        return true
    end

    local member = getAdminTeamMember(source)
    if member and member.permissions then
        for _, perm in ipairs(member.permissions) do
            if perm == 'ec_admin.all' or perm == node then
                return true
            end
        end
    end

    if _G.ECFramework and _G.ECFramework.IsAdminGroup and _G.ECFramework.IsAdminGroup(source) then
        return true
    end

    return false
end

local function ensureDiscordSync(source)
    if not Config or not Config.Discord or not Config.Discord.rolePermissions or not Config.Discord.rolePermissions.enabled then
        return
    end

    if exports[resourceName] and exports[resourceName].RefreshDiscordACE then
        local ok = pcall(function()
            exports[resourceName]:RefreshDiscordACE(source)
        end)

        if not ok then
            Logger.Info('⚠️ Failed to refresh Discord ACE permissions for source ' .. tostring(source))
        end
    end
end

function HasAdminAccess(source, action, target)
    if not source then return false end

    ensureDiscordSync(source)

    local node = getPermissionNode(action)
    local actorRank = determineRank(source)
    local targetRank = target and determineRank(target) or nil

    if targetRank and rankValue(targetRank) > rankValue(actorRank) then
        logDenied(action or node, source, target, 'Rank escalation blocked')
        return false
    end

    if actorRank == 'owner' then
        return true
    end

    if hasNodePermission(source, node) then
        return true
    end

    logDenied(action or node, source, target, 'Missing permission ' .. node)
    return false
end

exports('HasAdminAccess', HasAdminAccess)
exports('HasPermission', function(source, action, target)
    return HasAdminAccess(source, action, target)
end)

_G.HasAdminAccess = HasAdminAccess

-- Initialize on resource start
CreateThread(function()
    Wait(1000) -- Wait for config and database
    EC_Perms.Init()
end)

Logger.Success('[EC Perms] Permission module loaded', '🔐')
