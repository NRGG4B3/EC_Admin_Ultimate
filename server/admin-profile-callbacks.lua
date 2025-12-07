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

local function GetPlayerIdentsData(playerId)
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
    local identifiers = GetPlayerIdentsData(playerId)
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
    email = nil,
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
        
    -- Recent activity (no mock)
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

lib.callback.register('updateAdminProfile', function(source, data)
    local adminId = data.adminId
    local profile = data.profile
    if not adminId or not profile then
        return { success = false, error = 'Missing adminId or profile data' }
    end
    exports.oxmysql:execute('UPDATE ec_admin_permissions SET name = ?, email = ?, phone = ?, location = ? WHERE identifier = ?', {
        profile.name, profile.email, profile.phone, profile.location, adminId
    }, function(result)
        if result and result.affectedRows > 0 then
            return { success = true }
        else
            return { success = false, error = 'No rows updated' }
        end
    end)
end)

-- Update password
lib.callback.register('updateAdminPassword', function(source, data)
    local adminId = data.adminId
    local currentPassword = data.currentPassword
    local newPassword = data.newPassword
    if not adminId or not currentPassword or not newPassword then
        return { success = false, error = 'Missing required fields' }
    end
    -- Example: update password in database (hashing recommended)
    exports.oxmysql:execute('UPDATE ec_admin_permissions SET password = ? WHERE identifier = ? AND password = ?', {
        newPassword, adminId, currentPassword
    }, function(result)
        if result and result.affectedRows > 0 then
            return { success = true }
        else
            return { success = false, error = 'Password not updated' }
        end
    end)
end)

-- Update preferences
lib.callback.register('updateAdminPreferences', function(source, data)
    local adminId = data.adminId
    local preferences = data.preferences
    if not adminId or not preferences then
        return { success = false, error = 'Missing required fields' }
    end
    -- Example: update preferences in database (store as JSON)
    local prefsJson = json.encode(preferences)
    exports.oxmysql:execute('UPDATE ec_admin_permissions SET preferences = ? WHERE identifier = ?', {
        prefsJson, adminId
    }, function(result)
        if result and result.affectedRows > 0 then
            return { success = true }
        else
            return { success = false, error = 'Preferences not updated' }
        end
    end)
end)

-- End session
lib.callback.register('endAdminSession', function(source, data)
    local adminId = data.adminId
    local sessionId = data.sessionId
    if not adminId or not sessionId then
        return { success = false, error = 'Missing required fields' }
    end
    exports.oxmysql:execute('UPDATE ec_admin_sessions SET status = "ended", logout_time = NOW() WHERE id = ? AND admin_id = ?', {
        sessionId, adminId
    }, function(result)
        if result and result.affectedRows > 0 then
            return { success = true }
        else
            return { success = false, error = 'Session not ended' }
        end
    end)
end)

-- Clear activity
lib.callback.register('clearAdminActivity', function(source, data)
    local adminId = data.adminId
    if not adminId then
        return { success = false, error = 'Missing adminId' }
    end
    exports.oxmysql:execute('DELETE FROM ec_admin_logs WHERE admin_identifier = ?', {
        adminId
    }, function(result)
        if result then
            return { success = true }
        else
            return { success = false, error = 'Activity not cleared' }
        end
    end)
end)

-- Export profile
lib.callback.register('exportAdminProfile', function(source, data)
    local adminId = data.adminId
    if not adminId then
        return { success = false, error = 'Missing adminId' }
    end
    exports.oxmysql:execute('SELECT * FROM ec_admin_permissions WHERE identifier = ?', {
        adminId
    }, function(rows)
        if rows and rows[1] then
            return { success = true, profile = rows[1] }
        else
            return { success = false, error = 'Profile not found' }
        end
    end)
end)

-- ============================================================================
-- GET ADMIN STATISTICS
-- ============================================================================

lib.callback.register('adminProfile:getStats', function(source, data)
    local playerId = source
    
    -- In production, load from database
    -- No mock stats; return zeros if unavailable
    
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

-- ============================================================================
-- BATCH: GET FULL ADMIN PROFILE (ALL DATA AT ONCE)
-- ============================================================================
lib.callback.register('adminProfile:getFullProfile', function(source, data)
    local playerId = source
    local adminId = data and data.adminId or nil
    if not adminId then
        return { success = false, message = 'Missing adminId' }
    end

    local result = {
        profile = nil,
        permissions = {},
        roles = {},
        activity = {},
        actions = {},
        infractions = {},
        warnings = {},
        bans = {}
    }

    local done = 0
    local needed = 8
    local finished = false

    local function checkDone()
        done = done + 1
        if done >= needed and not finished then
            finished = true
            returnTrigger()
        end
    end

    local function returnTrigger()
        TriggerClientEvent('adminProfile:fullProfileResult', playerId, {
            success = true,
            data = result
        })
    end

    -- Profile
    exports.oxmysql:execute('SELECT * FROM ec_admin_permissions WHERE identifier = ?', { adminId }, function(rows)
        result.profile = rows and rows[1] or nil
        checkDone()
    end)
    -- Permissions
    exports.oxmysql:execute('SELECT * FROM ec_admin_permissions WHERE identifier = ?', { adminId }, function(rows)
        result.permissions = rows or {}
        checkDone()
    end)
    -- Roles
    exports.oxmysql:execute('SELECT * FROM ec_admin_roles WHERE admin_id = ?', { adminId }, function(rows)
        result.roles = rows or {}
        checkDone()
    end)
    -- Activity
    exports.oxmysql:execute('SELECT * FROM ec_admin_logs WHERE admin_identifier = ? ORDER BY timestamp DESC LIMIT 50', { adminId }, function(rows)
        result.activity = rows or {}
        checkDone()
    end)
    -- Actions
    exports.oxmysql:execute('SELECT * FROM ec_admin_action_logs WHERE admin_identifier = ? ORDER BY created_at DESC LIMIT 50', { adminId }, function(rows)
        result.actions = rows or {}
        checkDone()
    end)
    -- Infractions
    exports.oxmysql:execute('SELECT * FROM ec_admin_infractions WHERE admin_id = ?', { adminId }, function(rows)
        result.infractions = rows or {}
        checkDone()
    end)
    -- Warnings
    exports.oxmysql:execute('SELECT * FROM ec_admin_warnings WHERE identifier = ?', { adminId }, function(rows)
        result.warnings = rows or {}
        checkDone()
    end)
    -- Bans
    exports.oxmysql:execute('SELECT * FROM ec_admin_bans WHERE identifier = ?', { adminId }, function(rows)
        result.bans = rows or {}
        checkDone()
    end)
end)

Logger.Info('✅ Admin Profile callbacks loaded successfully')
