--[[
    EC Admin Ultimate - Permissions System
    Centralized permission checking for all admin actions
    
    Exports:
    - HasPermission(source, permission): Check if player has permission
    - EC_Perms(source, permission): Alias for HasPermission
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Permissions] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Local variables
local permissionCache = {}
local CACHE_TTL = 60 -- Cache for 60 seconds

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get player identifier from source
local function getPlayerIdentifier(source)
    if not source or source == 0 then return nil end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    -- Try license first
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    
    return identifiers[1]
end

-- Helper: Check if player is admin via framework
local function isFrameworkAdmin(source)
    if not ECFramework then return false end
    
    if ECFramework.IsAdminGroup then
        return ECFramework.IsAdminGroup(source)
    end
    
    return false
end

-- Main permission check function
local function hasPermission(source, permission)
    if not source or source == 0 then return false end
    if not permission or permission == '' then return true end
    
    local identifier = getPlayerIdentifier(source)
    if not identifier then return false end
    
    -- Check cache
    local cacheKey = identifier .. '_' .. permission
    if permissionCache[cacheKey] and (getCurrentTimestamp() - permissionCache[cacheKey].timestamp) < CACHE_TTL then
        return permissionCache[cacheKey].hasPermission
    end
    
    local hasPerm = false
    
    -- Check database for admin profile
    local result = MySQL.query.await([[
        SELECT ap.granted 
        FROM ec_admin_profiles ap
        LEFT JOIN ec_admin_permissions perm ON ap.admin_id = perm.admin_id AND perm.permission_name = ?
        WHERE ap.admin_id = ? AND ap.active = 1
        LIMIT 1
    ]], {permission, identifier})
    
    if result and result[1] then
        hasPerm = (result[1].granted == 1 or result[1].granted == true)
    else
        -- Fallback to framework admin check
        hasPerm = isFrameworkAdmin(source)
    end
    
    -- Cache result
    permissionCache[cacheKey] = {
        hasPermission = hasPerm,
        timestamp = getCurrentTimestamp()
    }
    
    return hasPerm
end

-- Export functions
exports('HasPermission', hasPermission)
exports('EC_Perms', hasPermission)

-- Also set as global for backward compatibility
_G.HasPermission = hasPermission

print("^2[Permissions]^7 Permission system loaded^0")

