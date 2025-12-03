--[[
    EC Admin Ultimate - Admin Profile Server Callbacks
    Provides admin user profile data and statistics
]]

Logger.Info('👤 Admin Profile callbacks loading...')

-- ============================================================================
-- FRAMEWORK DETECTION
-- ============================================================================

local Framework = nil
local FrameworkName = 'standalone'

-- Try QBX first
if GetResourceState('qbx_core') == 'started' then
    Framework = exports.qbx_core
    FrameworkName = 'qbx'
elseif GetResourceState('qb-core') == 'started' then
    Framework = exports['qb-core']:GetCoreObject()
    FrameworkName = 'qbcore'
elseif GetResourceState('es_extended') == 'started' then
    Framework = exports['es_extended']:getSharedObject()
    FrameworkName = 'esx'
end

-- ============================================================================
-- HELPER: GET PLAYER IDENTIFIERS
-- ============================================================================

local function GetPlayerIdentifiers(playerId)
    local identifiers = {
        steam = nil,
        license = nil,
        discord = nil,
        ip = nil
    }
    
    local playerIdents = GetPlayerIdentifiers(playerId)
    
    for _, v in pairs(playerIdents) do
        if string.find(v, 'steam:') then
            identifiers.steam = v
        elseif string.find(v, 'license:') then
            identifiers.license = v
        elseif string.find(v, 'discord:') then
            identifiers.discord = v
        elseif string.find(v, 'ip:') then
            identifiers.ip = v
        end
    end
    
    return identifiers
end

-- ============================================================================
-- HELPER: CHECK ADMIN PERMISSIONS
-- ============================================================================

local function GetAdminPermissions(playerId)
    -- Check various admin systems
    local permissions = {
        isSuperAdmin = false,
        isAdmin = false,
        isModerator = false,
        level = 0
    }
    
    -- Check if player is server owner (first connection, usually has all perms)
    if IsPlayerAceAllowed(playerId, 'command') then
        permissions.isSuperAdmin = true
        permissions.level = 3
        return permissions
    end
    
    -- Check basic admin ACE
    if IsPlayerAceAllowed(playerId, 'ec_admin.admin') then
        permissions.isAdmin = true
        permissions.level = 2
    end
    
    -- Check moderator ACE
    if IsPlayerAceAllowed(playerId, 'ec_admin.moderator') then
        permissions.isModerator = true
        if permissions.level < 1 then
            permissions.level = 1
        end
    end
    
    return permissions
end

-- ============================================================================
-- GET ADMIN PROFILE
-- ============================================================================

lib.callback.register('adminProfile:getData', function(source, data)
    local playerId = source
    
    -- Get basic player info
    local playerName = GetPlayerName(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local permissions = GetAdminPermissions(playerId)
    
    -- Determine role based on permissions
    local role = 'user'
    local roleLabel = 'User'
    
    if permissions.isSuperAdmin then
        role = 'superadmin'
        roleLabel = 'Super Admin'
    elseif permissions.isAdmin then
        role = 'admin'
        roleLabel = 'Admin'
    elseif permissions.isModerator then
        role = 'moderator'
        roleLabel = 'Moderator'
    end
    
    -- Build profile
    local profile = {
        name = playerName,
        username = identifiers.license or identifiers.steam or 'Unknown',
        email = 'admin@server.com', -- Placeholder
        role = role,
        roleLabel = roleLabel,
        avatar = nil, -- No avatar by default
        isSuperUser = permissions.isSuperAdmin,
        
        -- Identifiers
        identifiers = identifiers,
        
        -- Statistics (would be loaded from database in production)
        stats = {
            totalActions = 0,
            totalBans = 0,
            totalKicks = 0,
            totalWarnings = 0,
            playersHelped = 0,
            reportsHandled = 0,
            sessionsStarted = 0,
            lastLogin = os.date('%Y-%m-%d %H:%M:%S'),
            accountCreated = os.date('%Y-%m-%d')
        },
        
        -- Recent activity (placeholder)
        recentActivity = {},
        
        -- Permissions
        permissions = {
            canBan = permissions.isAdmin or permissions.isSuperAdmin,
            canKick = permissions.isModerator or permissions.isAdmin or permissions.isSuperAdmin,
            canWarn = permissions.isModerator or permissions.isAdmin or permissions.isSuperAdmin,
            canManageServer = permissions.isSuperAdmin,
            canViewReports = true,
            canManageWhitelist = permissions.isAdmin or permissions.isSuperAdmin,
            canAccessDevTools = permissions.isSuperAdmin
        }
    }
    
    return {
        success = true,
        data = profile
    }
end)

-- ============================================================================
-- UPDATE ADMIN PROFILE
-- ============================================================================

lib.callback.register('adminProfile:update', function(source, data)
    local playerId = source
    
    if not data then
        return { success = false, message = 'No data provided' }
    end
    
    -- In a real implementation, you would save to database here
    -- For now, just return success
    
    Logger.Info(string.format('', GetPlayerName(playerId)))
    
    return {
        success = true,
        message = 'Profile updated successfully'
    }
end)

-- ============================================================================
-- GET ADMIN STATISTICS
-- ============================================================================

lib.callback.register('adminProfile:getStats', function(source, data)
    local playerId = source
    
    -- In production, load from database
    -- For now, return placeholder stats
    
    local stats = {
        totalActions = 0,
        totalBans = 0,
        totalKicks = 0,
        totalWarnings = 0,
        playersHelped = 0,
        reportsHandled = 0,
        sessionsToday = 1,
        averageResponseTime = '5m 30s',
        
        -- Activity breakdown
        actionsByDay = {},
        actionsByType = {
            bans = 0,
            kicks = 0,
            warnings = 0,
            teleports = 0,
            spawns = 0,
            other = 0
        },
        
        -- Recent sessions
        recentSessions = {}
    }
    
    return {
        success = true,
        data = stats
    }
end)

Logger.Info('✅ Admin Profile callbacks loaded successfully')
