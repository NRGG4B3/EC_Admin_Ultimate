local MySQL = exports['mysql-async'] or exports['oxmysql']
-- EC Admin Ultimate - Admin Profile UI Backend
local MySQL = exports['oxmysql'] or exports['mysql-async']
local function getAdminId(source, data)
    return data.adminId or (GetPlayerIdentifiers and GetPlayerIdentifiers(source)[1]) or nil
end

local function isAdmin(source)
    -- Use shared framework permission check
    local ECFramework = exports['ec_admin_ultimate'] and exports['ec_admin_ultimate']:getFramework()
    if ECFramework and ECFramework.IsAdminGroup then
        return ECFramework.IsAdminGroup(source)
    end
    return false
end

-- Main fetch callback
lib.callback.register('adminProfile:getFullProfile', function(source, data)
    if not isAdmin(source) then return { success = false, error = 'permission_denied' } end
    local adminId = getAdminId(source, data)
    if not adminId then return { success = false, error = 'invalid_admin_id' } end

    local profile = MySQL.query.await('SELECT * FROM ec_admin_profiles WHERE admin_id = ?', {adminId})[1] or {}
    local stats = {
        totalActions = profile.total_actions or 0,
        playersManaged = profile.players_managed or 0,
        bansIssued = profile.bans_issued or 0,
        warningsIssued = profile.warnings_issued or 0,
        resourcesManaged = profile.resources_managed or 0,
        uptime = profile.uptime or 0,
        trustScore = profile.trust_score or 100,
        status = profile.status or 'inactive'
    }
    local activity = MySQL.query.await('SELECT * FROM ec_admin_activity WHERE admin_id = ? ORDER BY timestamp DESC LIMIT 100', {adminId}) or {}
    local permissions = MySQL.query.await('SELECT * FROM ec_admin_permissions WHERE admin_id = ?', {adminId}) or {}
    local roles = MySQL.query.await('SELECT * FROM ec_admin_roles WHERE admin_id = ?', {adminId}) or {}
    local infractions = MySQL.query.await('SELECT reason, timestamp FROM ec_admin_infractions WHERE admin_id = ? ORDER BY timestamp DESC', {adminId}) or {}
    local warnings = MySQL.query.await('SELECT reason, timestamp FROM ec_admin_warnings WHERE admin_id = ? ORDER BY timestamp DESC', {adminId}) or {}
    local bans = MySQL.query.await('SELECT reason, timestamp FROM ec_admin_bans WHERE admin_id = ? ORDER BY timestamp DESC', {adminId}) or {}
    local sessions = MySQL.query.await('SELECT * FROM ec_admin_sessions WHERE admin_id = ? ORDER BY login_time DESC LIMIT 10', {adminId}) or {}
    local logs = MySQL.query.await('SELECT * FROM ec_admin_logs WHERE admin_id = ? ORDER BY timestamp DESC LIMIT 100', {adminId}) or {}
    local security = {
        twoFactorEnabled = false,
        apiKeys = {},
        notificationPreferences = profile.notification_preferences or {}
    }
    local statsExtra = {}
    return {
        success = true,
        profile = profile,
        stats = stats,
        activity = activity,
        permissions = permissions,
        roles = roles,
        infractions = infractions,
        warnings = warnings,
        bans = bans,
        sessions = sessions,
        security = security,
        statsExtra = statsExtra,
        logs = logs
    }
end)

lib.callback.register('updateAdminProfile', function(source, data)
    if not isAdmin(source) then return { success = false, error = 'permission_denied' } end
    local adminId = getAdminId(source, data)
    if not adminId then return { success = false, error = 'invalid_admin_id' } end
    local update = MySQL.update.await('UPDATE ec_admin_profiles SET name = ?, email = ?, phone = ?, location = ? WHERE admin_id = ?', {
        data.profile.name, data.profile.email, data.profile.phone, data.profile.location, adminId
    })
    return { success = update > 0 }
end)

lib.callback.register('updateAdminPassword', function(source, data)
    if not isAdmin(source) then return { success = false, error = 'permission_denied' } end
    -- Stub: Do not implement password logic unless secure system exists
    return { success = false, error = 'not_configured' }
end)

lib.callback.register('updateAdminPreferences', function(source, data)
    if not isAdmin(source) then return { success = false, error = 'permission_denied' } end
    local adminId = getAdminId(source, data)
    if not adminId then return { success = false, error = 'invalid_admin_id' } end
    local prefs = data.preferences and json.encode(data.preferences) or '{}'
    local update = MySQL.update.await('UPDATE ec_admin_profiles SET notification_preferences = ? WHERE admin_id = ?', {prefs, adminId})
    return { success = update > 0 }
end)

lib.callback.register('endAdminSession', function(source, data)
    if not isAdmin(source) then return { success = false, error = 'permission_denied' } end
    local sessionId = data.sessionId
    if not sessionId then return { success = false, error = 'invalid_session_id' } end
    local update = MySQL.update.await('UPDATE ec_admin_sessions SET status = "ended", logout_time = ? WHERE id = ?', {os.time(), sessionId})
    return { success = update > 0 }
end)

lib.callback.register('clearAdminActivity', function(source, data)
    if not isAdmin(source) then return { success = false, error = 'permission_denied' } end
    local adminId = getAdminId(source, data)
    if not adminId then return { success = false, error = 'invalid_admin_id' } end
    local delete = MySQL.execute.await('DELETE FROM ec_admin_activity WHERE admin_id = ?', {adminId})
    return { success = delete > 0 }
end)

lib.callback.register('exportAdminProfile', function(source, data)
    if not isAdmin(source) then return { success = false, error = 'permission_denied' } end
    local adminId = getAdminId(source, data)
    if not adminId then return { success = false, error = 'invalid_admin_id' } end
    local profile = MySQL.query.await('SELECT * FROM ec_admin_profiles WHERE admin_id = ?', {adminId})[1] or {}
    return { success = true, data = profile }
end)
-- Register NUI callback for fetching admin profile
type = type or {}
lib.callback.register('getAdminProfile', function(source, data)
    local adminId = data.adminId or GetPlayerIdentifier(source, 0)
    local profile = MySQL.query.await('SELECT * FROM admin_profiles WHERE admin_id = ?', {adminId})[1] or {}
    local stats = {
        totalActions = profile.total_actions or 0,
        playersManaged = profile.players_managed or 0,
        bansIssued = profile.bans_issued or 0,
        warningsIssued = profile.warnings_issued or 0,
        resourcesManaged = profile.resources_managed or 0,
        uptime = profile.uptime or 0,
        trustScore = profile.trust_score or 0,
        status = profile.status or 'inactive'
    }
    local activity = MySQL.query.await('SELECT * FROM admin_activity WHERE admin_id = ? ORDER BY timestamp DESC LIMIT 100', {adminId}) or {}
    local permissions = MySQL.query.await('SELECT * FROM admin_permissions WHERE admin_id = ?', {adminId}) or {}
    local sessions = MySQL.query.await('SELECT * FROM admin_sessions WHERE admin_id = ? ORDER BY login_time DESC LIMIT 10', {adminId}) or {}
    local framework = 'Unknown' -- Set from server config if needed

    return {
        success = true,
        data = {
            profile = profile,
            stats = stats,
            activity = activity,
            permissions = permissions,
            sessions = sessions,
            framework = framework
        }
    }
end)

-- Register NUI callback for updating profile info
lib.callback.register('updateAdminProfile', function(source, data)
    local adminId = data.adminId or GetPlayerIdentifier(source, 0)
    local update = MySQL.update.await('UPDATE admin_profiles SET name = ?, email = ?, phone = ?, location = ? WHERE admin_id = ?', {
        data.name, data.email, data.phone, data.location, adminId
    })
    return { success = update > 0 }
end)

-- Register NUI callback for changing password
lib.callback.register('updateAdminPassword', function(source, data)
    -- Implement password change logic here (hash, validate, update)
    return { success = false, error = 'Not implemented' }
end)

-- Register NUI callback for updating preferences
lib.callback.register('updateAdminPreferences', function(source, data)
    -- Implement preferences update logic here
    return { success = false, error = 'Not implemented' }
end)

-- Register NUI callback for ending session
lib.callback.register('endAdminSession', function(source, data)
    local sessionId = data.session_id
    local update = MySQL.update.await('UPDATE admin_sessions SET status = "ended", logout_time = ? WHERE id = ?', {os.time(), sessionId})
    return { success = update > 0 }
end)

-- Register NUI callback for clearing activity logs
lib.callback.register('clearAdminActivity', function(source, data)
    local adminId = data.adminId or GetPlayerIdentifier(source, 0)
    local delete = MySQL.execute.await('DELETE FROM admin_activity WHERE admin_id = ?', {adminId})
    return { success = delete > 0 }
end)

-- Register NUI callback for exporting profile data
lib.callback.register('exportAdminProfile', function(source, data)
    local adminId = data.adminId or GetPlayerIdentifier(source, 0)
    local profile = MySQL.query.await('SELECT * FROM admin_profiles WHERE admin_id = ?', {adminId})[1] or {}
    return { success = true, data = profile }
end)

-- Comments: Future updates (e.g., security, API keys, 2FA) should be added as new callbacks here.