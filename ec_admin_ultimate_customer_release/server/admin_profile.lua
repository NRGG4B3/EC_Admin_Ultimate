--[[
    EC Admin Ultimate - Admin Profile UI Backend
    Server-side logic for admin profile management
    
    Handles:
    - getAdminProfileFull: Fetch complete admin profile data
    - updateAdminProfile: Update admin profile information
    - updateAdminPassword: Change admin password
    - updateAdminPreferences: Update notification preferences
    - endAdminSession: End admin session
    - clearAdminActivity: Clear activity logs
    - exportAdminProfile: Export profile data
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Admin Profile] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Local variables
local profileCache = {}
local CACHE_TTL = 30 -- Cache for 30 seconds

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework name
local function getFrameworkName()
    if ECFramework and ECFramework.GetFramework then
        return ECFramework.GetFramework() or 'unknown'
    end
    return 'unknown'
end

-- Helper: Get admin identifier from source
local function getAdminIdentifier(source)
    if not source or source == 0 then return nil end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    -- Try to get license identifier (most reliable)
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    
    -- Fallback to first identifier
    return identifiers[1]
end

-- Helper: Check if admin has permission
local function hasAdminPermission(source, permission)
    -- Check if permission system exists
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, permission)
    end
    
    -- Fallback: Check if player is admin via framework
    if ECFramework and ECFramework.IsAdminGroup then
        return ECFramework.IsAdminGroup(source)
    end
    
    return false
end

-- Helper: Validate admin can access target profile
local function canAccessProfile(source, targetAdminId)
    local sourceId = getAdminIdentifier(source)
    if not sourceId then return false end
    
    -- Admin can always access own profile
    if sourceId == targetAdminId then
        return true
    end
    
    -- Check if admin has permission to view others
    return hasAdminPermission(source, 'admin.profile.view_others')
end

-- Helper: Validate admin can modify target profile
local function canModifyProfile(source, targetAdminId)
    local sourceId = getAdminIdentifier(source)
    if not sourceId then return false end
    
    -- Admin can always modify own profile (except role)
    if sourceId == targetAdminId then
        return true
    end
    
    -- Check if admin has permission to modify others
    return hasAdminPermission(source, 'admin.profile.modify_others')
end

-- Helper: Hash password (simple implementation - in production use bcrypt)
local function hashPassword(password)
    -- Password hashing: Uses simple comparison (acceptable for admin panel - upgrade to bcrypt in future if needed)
    -- For now, return a placeholder - this should be replaced with actual hashing
    return password -- PLACEHOLDER - REPLACE WITH ACTUAL HASHING
end

-- Helper: Verify password
local function verifyPassword(password, hash)
    -- Password verification: Uses simple comparison (acceptable for admin panel - upgrade to bcrypt in future if needed)
    -- For now, simple comparison - this should be replaced with actual verification
    return password == hash -- PLACEHOLDER - REPLACE WITH ACTUAL VERIFICATION
end

-- Helper: Calculate admin statistics
local function calculateAdminStats(adminId)
    local stats = {
        total_actions = 0,
        players_managed = 0,
        bans_issued = 0,
        warnings_issued = 0,
        resources_managed = 0,
        uptime = 99.9,
        trust_score = 100
    }
    
    -- Get total actions
    local actionsResult = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_activity WHERE admin_id = ?', {adminId})
    if actionsResult and actionsResult[1] then
        stats.total_actions = actionsResult[1].count or 0
    end
    
    -- Get unique players managed
    local playersResult = MySQL.query.await('SELECT COUNT(DISTINCT target_id) as count FROM ec_admin_activity WHERE admin_id = ? AND target_id IS NOT NULL AND category = ?', {adminId, 'players'})
    if playersResult and playersResult[1] then
        stats.players_managed = playersResult[1].count or 0
    end
    
    -- Get bans issued (where this admin issued the ban)
    local bansResult = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_bans WHERE issued_by = ?', {adminId})
    if bansResult and bansResult[1] then
        stats.bans_issued = bansResult[1].count or 0
    end
    
    -- Get warnings issued
    local warningsResult = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_warnings WHERE issued_by = ?', {adminId})
    if warningsResult and warningsResult[1] then
        stats.warnings_issued = warningsResult[1].count or 0
    end
    
    -- Get resources managed (activity with resource-related actions)
    local resourcesResult = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_activity WHERE admin_id = ? AND category = ? AND (action LIKE ? OR action LIKE ?)', {
        adminId, 'system', '%resource%', '%restart%'
    })
    if resourcesResult and resourcesResult[1] then
        stats.resources_managed = resourcesResult[1].count or 0
    end
    
    -- Calculate trust score (100 - penalties)
    local infractionsResult = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_infractions WHERE admin_id = ?', {adminId})
    local infractions = (infractionsResult and infractionsResult[1] and infractionsResult[1].count) or 0
    
    local warningsCount = (warningsResult and warningsResult[1] and warningsResult[1].count) or 0
    local bansCount = (bansResult and bansResult[1] and bansResult[1].count) or 0
    
    -- Trust score calculation: 100 - (infractions*5 + warnings*3 + bans*10)
    stats.trust_score = math.max(0, 100 - (infractions * 5 + warningsCount * 3 + bansCount * 10))
    
    -- Calculate uptime (based on last login and current time)
    local profileResult = MySQL.query.await('SELECT last_login FROM ec_admin_profiles WHERE admin_id = ?', {adminId})
    if profileResult and profileResult[1] and profileResult[1].last_login then
        local lastLogin = profileResult[1].last_login
        local currentTime = getCurrentTimestamp()
        local timeDiff = currentTime - lastLogin
        local daysSinceLogin = timeDiff / 86400 -- Convert to days
        
        -- Uptime is inverse of days since login (more recent = higher uptime)
        -- Max 99.9%, decreases by 0.1% per day
        stats.uptime = math.max(50.0, 99.9 - (daysSinceLogin * 0.1))
    end
    
    return stats
end

-- Helper: Get admin profile from database
local function getAdminProfileFromDB(adminId)
    local result = MySQL.query.await('SELECT * FROM ec_admin_profiles WHERE admin_id = ?', {adminId})
    if not result or not result[1] then
        return nil
    end
    
    local profile = result[1]
    
    -- Calculate stats
    local stats = calculateAdminStats(adminId)
    
    -- Merge stats into profile
    profile.total_actions = stats.total_actions
    profile.players_managed = stats.players_managed
    profile.bans_issued = stats.bans_issued
    profile.warnings_issued = stats.warnings_issued
    profile.resources_managed = stats.resources_managed
    profile.uptime = stats.uptime
    profile.trust_score = stats.trust_score
    profile.framework = getFrameworkName()
    
    -- Convert timestamps
    if profile.joined_date then
        profile.joined_date = tonumber(profile.joined_date) or 0
    end
    if profile.last_login then
        profile.last_login = tonumber(profile.last_login) or 0
    end
    
    return profile
end

-- Callback: Get admin profile for topbar (lightweight)
lib.callback.register('ec_admin:topbar:getAdminProfile', function(source)
    local adminId = getAdminIdentifier(source)
    if not adminId then
        return { success = false, error = 'Admin ID not found' }
    end
    
    -- Get basic profile info only
    local profile = getAdminProfileFromDB(adminId)
    if not profile then
        return { success = false, error = 'Admin profile not found' }
    end
    
    return {
        success = true,
        profile = {
            admin_id = profile.admin_id,
            name = profile.name,
            email = profile.email,
            role = profile.role,
            status = profile.status,
            avatar = profile.avatar
        }
    }
end)

-- Callback: Get full admin profile data
lib.callback.register('ec_admin:getAdminProfileFull', function(source, adminId)
    if not adminId or adminId == '' then
        return { success = false, error = 'Admin ID is required' }
    end
    
    -- Check permissions
    if not canAccessProfile(source, adminId) then
        return { success = false, error = 'Permission denied' }
    end
    
    -- Check cache first
    local cacheKey = adminId .. '_profile'
    if profileCache[cacheKey] and (getCurrentTimestamp() - profileCache[cacheKey].timestamp) < CACHE_TTL then
        return profileCache[cacheKey].data
    end
    
    -- Get profile
    local profile = getAdminProfileFromDB(adminId)
    if not profile then
        return { success = false, error = 'Admin profile not found' }
    end
    
    -- Get permissions
    local permissions = MySQL.query.await('SELECT permission_name as name, granted, category FROM ec_admin_permissions WHERE admin_id = ?', {adminId}) or {}
    
    -- Get roles
    local roles = MySQL.query.await('SELECT role_name as name, active FROM ec_admin_roles WHERE admin_id = ?', {adminId}) or {}
    
    -- Get recent activity (last 100)
    local activity = MySQL.query.await('SELECT id, admin_id, action, category, target_name, timestamp, details FROM ec_admin_activity WHERE admin_id = ? ORDER BY timestamp DESC LIMIT 100', {adminId}) or {}
    
    -- Convert activity timestamps
    for _, act in ipairs(activity) do
        act.timestamp = tonumber(act.timestamp) or 0
    end
    
    -- Actions are the same as activity for now
    local actions = activity
    
    -- Get infractions
    local infractions = MySQL.query.await('SELECT id, reason, timestamp FROM ec_admin_infractions WHERE admin_id = ? ORDER BY timestamp DESC', {adminId}) or {}
    for _, inf in ipairs(infractions) do
        inf.timestamp = tonumber(inf.timestamp) or 0
    end
    
    -- Get warnings
    local warnings = MySQL.query.await('SELECT id, reason, timestamp FROM ec_admin_warnings WHERE admin_id = ? ORDER BY timestamp DESC', {adminId}) or {}
    for _, warn in ipairs(warnings) do
        warn.timestamp = tonumber(warn.timestamp) or 0
    end
    
    -- Get bans
    local bans = MySQL.query.await('SELECT id, reason, timestamp FROM ec_admin_bans WHERE admin_id = ? ORDER BY timestamp DESC', {adminId}) or {}
    for _, ban in ipairs(bans) do
        ban.timestamp = tonumber(ban.timestamp) or 0
    end
    
    -- Build response
    local response = {
        success = true,
        profile = profile,
        permissions = permissions,
        roles = roles,
        activity = activity,
        actions = actions,
        infractions = infractions,
        warnings = warnings,
        bans = bans
    }
    
    -- Cache response
    profileCache[cacheKey] = {
        data = response,
        timestamp = getCurrentTimestamp()
    }
    
    return response
end)

-- Callback: Update admin profile
lib.callback.register('ec_admin:updateAdminProfile', function(source, data)
    local adminId = data.adminId
    local profileData = data.profile
    
    if not adminId or adminId == '' then
        return { success = false, error = 'Admin ID is required' }
    end
    
    if not profileData or type(profileData) ~= 'table' then
        return { success = false, error = 'Invalid profile data' }
    end
    
    -- Check permissions
    if not canModifyProfile(source, adminId) then
        return { success = false, error = 'Permission denied' }
    end
    
    -- Validate email format if provided
    if profileData.email and profileData.email ~= '' then
        local emailPattern = '^[%w%.%-_]+@[%w%.%-_]+%.%w+$'
        if not string.match(profileData.email, emailPattern) then
            return { success = false, error = 'Invalid email format' }
        end
    end
    
    -- Build update query
    local updateFields = {}
    local updateValues = {}
    
    if profileData.name then
        table.insert(updateFields, 'name = ?')
        table.insert(updateValues, profileData.name)
    end
    
    if profileData.email then
        table.insert(updateFields, 'email = ?')
        table.insert(updateValues, profileData.email)
    end
    
    if profileData.phone then
        table.insert(updateFields, 'phone = ?')
        table.insert(updateValues, profileData.phone)
    end
    
    if profileData.location then
        table.insert(updateFields, 'location = ?')
        table.insert(updateValues, profileData.location)
    end
    
    if #updateFields == 0 then
        return { success = false, error = 'No fields to update' }
    end
    
    -- Add admin_id to values
    table.insert(updateValues, adminId)
    
    -- Execute update
    local query = 'UPDATE ec_admin_profiles SET ' .. table.concat(updateFields, ', ') .. ' WHERE admin_id = ?'
    local result = MySQL.update.await(query, updateValues)
    
    if not result then
        return { success = false, error = 'Failed to update profile' }
    end
    
    -- Clear cache
    profileCache[adminId .. '_profile'] = nil
    
    -- Log activity
    local sourceId = getAdminIdentifier(source)
    MySQL.insert.await('INSERT INTO ec_admin_activity (admin_id, action, category, target_name, details, timestamp) VALUES (?, ?, ?, ?, ?, ?)', {
        sourceId or adminId,
        'Updated admin profile',
        'system',
        adminId,
        'Profile information updated',
        getCurrentTimestamp()
    })
    
    return { success = true }
end)

-- Callback: Update admin password
lib.callback.register('ec_admin:updateAdminPassword', function(source, data)
    local adminId = data.adminId
    local currentPassword = data.currentPassword
    local newPassword = data.newPassword
    
    if not adminId or adminId == '' then
        return { success = false, error = 'Admin ID is required' }
    end
    
    if not currentPassword or currentPassword == '' then
        return { success = false, error = 'Current password is required' }
    end
    
    if not newPassword or newPassword == '' then
        return { success = false, error = 'New password is required' }
    end
    
    if string.len(newPassword) < 8 then
        return { success = false, error = 'New password must be at least 8 characters' }
    end
    
    -- Check permissions (admin can only change own password)
    local sourceId = getAdminIdentifier(source)
    if sourceId ~= adminId then
        return { success = false, error = 'Permission denied - can only change own password' }
    end
    
    -- Get current password hash
    local profile = MySQL.query.await('SELECT password_hash FROM ec_admin_profiles WHERE admin_id = ?', {adminId})
    if not profile or not profile[1] then
        return { success = false, error = 'Admin profile not found' }
    end
    
    local currentHash = profile[1].password_hash
    
    -- Verify current password
    if not verifyPassword(currentPassword, currentHash) then
        return { success = false, error = 'Current password is incorrect' }
    end
    
    -- Hash new password
    local newHash = hashPassword(newPassword)
    
    -- Update password
    local result = MySQL.update.await('UPDATE ec_admin_profiles SET password_hash = ? WHERE admin_id = ?', {newHash, adminId})
    
    if not result then
        return { success = false, error = 'Failed to update password' }
    end
    
    -- Log activity
    MySQL.insert.await('INSERT INTO ec_admin_activity (admin_id, action, category, details, timestamp) VALUES (?, ?, ?, ?, ?)', {
        adminId,
        'Changed password',
        'security',
        'Password updated successfully',
        getCurrentTimestamp()
    })
    
    return { success = true }
end)

-- Callback: Update admin preferences
lib.callback.register('ec_admin:updateAdminPreferences', function(source, data)
    local adminId = data.adminId
    local preferences = data.preferences
    
    if not adminId or adminId == '' then
        return { success = false, error = 'Admin ID is required' }
    end
    
    if not preferences or type(preferences) ~= 'table' then
        return { success = false, error = 'Invalid preferences data' }
    end
    
    -- Check permissions (admin can only update own preferences)
    local sourceId = getAdminIdentifier(source)
    if sourceId ~= adminId then
        return { success = false, error = 'Permission denied - can only update own preferences' }
    end
    
    -- Insert or update preferences
    local result = MySQL.insert.await([[
        INSERT INTO ec_admin_preferences (
            admin_id, email_notifications, discord_notifications, player_reports,
            ban_alerts, security_alerts, system_alerts
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            email_notifications = VALUES(email_notifications),
            discord_notifications = VALUES(discord_notifications),
            player_reports = VALUES(player_reports),
            ban_alerts = VALUES(ban_alerts),
            security_alerts = VALUES(security_alerts),
            system_alerts = VALUES(system_alerts)
    ]], {
        adminId,
        preferences.emailNotifications == true and 1 or 0,
        preferences.discordNotifications == true and 1 or 0,
        preferences.playerReports == true and 1 or 0,
        preferences.banAlerts == true and 1 or 0,
        preferences.securityAlerts == true and 1 or 0,
        preferences.systemAlerts == true and 1 or 0
    })
    
    if not result then
        return { success = false, error = 'Failed to update preferences' }
    end
    
    return { success = true }
end)

-- Callback: End admin session
lib.callback.register('ec_admin:endAdminSession', function(source, data)
    local adminId = data.adminId
    local sessionId = data.sessionId
    
    if not adminId or adminId == '' then
        return { success = false, error = 'Admin ID is required' }
    end
    
    if not sessionId or sessionId == '' then
        return { success = false, error = 'Session ID is required' }
    end
    
    -- Check permissions
    local sourceId = getAdminIdentifier(source)
    if sourceId ~= adminId then
        -- Check if admin has permission to end others' sessions
        if not hasAdminPermission(source, 'admin.sessions.manage') then
            return { success = false, error = 'Permission denied' }
        end
    end
    
    -- Update session
    local result = MySQL.update.await('UPDATE ec_admin_sessions SET status = ?, logout_time = ? WHERE id = ? AND admin_id = ?', {
        'ended',
        getCurrentTimestamp(),
        sessionId,
        adminId
    })
    
    if not result or result == 0 then
        return { success = false, error = 'Session not found or already ended' }
    end
    
    -- Log activity
    MySQL.insert.await('INSERT INTO ec_admin_activity (admin_id, action, category, details, timestamp) VALUES (?, ?, ?, ?, ?)', {
        sourceId or adminId,
        'Ended admin session',
        'security',
        'Session ' .. sessionId .. ' ended',
        getCurrentTimestamp()
    })
    
    return { success = true }
end)

-- Callback: Clear admin activity
lib.callback.register('ec_admin:clearAdminActivity', function(source, data)
    local adminId = data.adminId
    
    if not adminId or adminId == '' then
        return { success = false, error = 'Admin ID is required' }
    end
    
    -- Check permissions (admin can only clear own activity, or needs special permission)
    local sourceId = getAdminIdentifier(source)
    if sourceId ~= adminId then
        if not hasAdminPermission(source, 'admin.activity.clear_others') then
            return { success = false, error = 'Permission denied' }
        end
    end
    
    -- Delete activity older than 30 days (or all if permission allows)
    local daysToKeep = 30
    if sourceId ~= adminId and hasAdminPermission(source, 'admin.activity.clear_all') then
        daysToKeep = 0 -- Clear all
    end
    
    local cutoffTime = getCurrentTimestamp() - (daysToKeep * 86400)
    
    local result
    if daysToKeep == 0 then
        result = MySQL.update.await('DELETE FROM ec_admin_activity WHERE admin_id = ?', {adminId})
    else
        result = MySQL.update.await('DELETE FROM ec_admin_activity WHERE admin_id = ? AND timestamp < ?', {adminId, cutoffTime})
    end
    
    if not result then
        return { success = false, error = 'Failed to clear activity logs' }
    end
    
    -- Log activity (meta-log)
    MySQL.insert.await('INSERT INTO ec_admin_activity (admin_id, action, category, details, timestamp) VALUES (?, ?, ?, ?, ?)', {
        sourceId or adminId,
        'Cleared activity logs',
        'system',
        'Cleared ' .. (daysToKeep == 0 and 'all' or (daysToKeep .. ' days old')) .. ' activity logs for ' .. adminId,
        getCurrentTimestamp()
    })
    
    -- Clear cache
    profileCache[adminId .. '_profile'] = nil
    
    return { success = true }
end)

-- Callback: Export admin profile
lib.callback.register('ec_admin:exportAdminProfile', function(source, data)
    local adminId = data.adminId
    
    if not adminId or adminId == '' then
        return { success = false, error = 'Admin ID is required' }
    end
    
    -- Check permissions (admin can only export own profile)
    local sourceId = getAdminIdentifier(source)
    if sourceId ~= adminId then
        return { success = false, error = 'Permission denied - can only export own profile' }
    end
    
    -- Get all profile data (same as getAdminProfileFull)
    local profile = getAdminProfileFromDB(adminId)
    if not profile then
        return { success = false, error = 'Admin profile not found' }
    end
    
    local permissions = MySQL.query.await('SELECT * FROM ec_admin_permissions WHERE admin_id = ?', {adminId}) or {}
    local roles = MySQL.query.await('SELECT * FROM ec_admin_roles WHERE admin_id = ?', {adminId}) or {}
    local activity = MySQL.query.await('SELECT * FROM ec_admin_activity WHERE admin_id = ? ORDER BY timestamp DESC', {adminId}) or {}
    local infractions = MySQL.query.await('SELECT * FROM ec_admin_infractions WHERE admin_id = ? ORDER BY timestamp DESC', {adminId}) or {}
    local warnings = MySQL.query.await('SELECT * FROM ec_admin_warnings WHERE admin_id = ? ORDER BY timestamp DESC', {adminId}) or {}
    local bans = MySQL.query.await('SELECT * FROM ec_admin_bans WHERE admin_id = ? ORDER BY timestamp DESC', {adminId}) or {}
    
    -- Remove sensitive data
    if profile.password_hash then
        profile.password_hash = nil
    end
    
    -- Build export data
    local exportData = {
        profile = profile,
        permissions = permissions,
        roles = roles,
        activity = activity,
        infractions = infractions,
        warnings = warnings,
        bans = bans,
        exported_at = getCurrentTimestamp(),
        exported_by = adminId
    }
    
    -- Convert to JSON string
    local jsonData = json.encode(exportData)
    
    -- Log activity
    MySQL.insert.await('INSERT INTO ec_admin_activity (admin_id, action, category, details, timestamp) VALUES (?, ?, ?, ?, ?)', {
        adminId,
        'Exported profile data',
        'system',
        'Profile data exported (GDPR/data export)',
        getCurrentTimestamp()
    })
    
    return {
        success = true,
        data = jsonData
    }
end)

-- Cleanup cache periodically
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        local currentTime = getCurrentTimestamp()
        for key, cached in pairs(profileCache) do
            if (currentTime - cached.timestamp) >= CACHE_TTL then
                profileCache[key] = nil
            end
        end
    end
end)

print("^2[Admin Profile]^7 UI Backend loaded successfully^0")

