--[[
    EC Admin Ultimate - Moderation UI Backend
    Server-side logic for moderation management
    
    Handles:
    - moderation:getData: Get all moderation data (warnings, kicks, mutes, reports, action logs, stats)
    - moderation:issueWarning: Issue a warning to a player
    - moderation:kickPlayer: Kick a player
    - moderation:mutePlayer: Mute a player
    - moderation:removeWarning: Remove a warning
    - moderation:unmutePlayer: Unmute a player
    - moderation:updateReportStatus: Update report status
    
    Framework Support: QB-Core, QBX, ESX
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Moderation] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Moderation] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local dataCache = {}
local CACHE_TTL = 10 -- Cache for 10 seconds

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Get player object
local function getPlayerObject(source)
    return ECFramework.GetPlayerObject(source)
end

-- Helper: Check admin permission
local function hasPermission(source, permission)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, permission)
    end
    return ECFramework.IsAdminGroup(source) or false
end

-- Helper: Get admin info
local function getAdminInfo(source)
    return {
        id = GetPlayerIdentifier(source, 0) or 'system',
        name = GetPlayerName(source) or 'System'
    }
end

-- Helper: Get player identifier from source
local function getPlayerIdentifierFromSource(source)
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

-- Helper: Get player source from identifier
local function getPlayerSourceByIdentifier(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            local ids = GetPlayerIdentifiers(source)
            if ids then
                for _, id in ipairs(ids) do
                    if id == identifier then
                        return source
                    end
                end
            end
        end
    end
    return nil
end

-- Helper: Get player name from identifier
local function getPlayerNameByIdentifier(identifier)
    -- Try online first
    local source = getPlayerSourceByIdentifier(identifier)
    if source then
        return GetPlayerName(source) or 'Unknown'
    end
    
    -- Try database
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ? LIMIT 1', {identifier})
        if result and result[1] then
            local charinfo = json.decode(result[1].charinfo or '{}')
            if charinfo then
                return (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
            end
        end
    elseif framework == 'esx' then
        local result = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = ? LIMIT 1', {identifier})
        if result and result[1] then
            return (result[1].firstname or '') .. ' ' .. (result[1].lastname or '')
        end
    end
    
    return 'Unknown'
end

-- Helper: Get player identifier from player ID
local function getPlayerIdentifierFromId(playerId)
    local source = tonumber(playerId)
    if not source then return nil end
    
    return getPlayerIdentifierFromSource(source)
end

-- Helper: Log moderation action
local function logModerationAction(adminId, adminName, actionType, targetId, targetName, reason, details)
    MySQL.insert.await([[
        INSERT INTO ec_moderation_action_logs 
        (admin_id, admin_name, action_type, target_id, target_name, reason, details, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        adminId, adminName, actionType, targetId, targetName, reason,
        details and json.encode(details) or nil, getCurrentTimestamp()
    })
end

-- Helper: Get all warnings
local function getAllWarnings()
    local warnings = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_moderation_warnings
        ORDER BY created_at DESC
        LIMIT 500
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            local expiresAt = nil
            if row.expires_at then
                expiresAt = os.date('%Y-%m-%dT%H:%M:%SZ', row.expires_at)
            end
            
            table.insert(warnings, {
                id = row.id,
                player_id = row.player_id,
                player_name = row.player_name,
                admin_id = row.admin_id,
                admin_name = row.admin_name,
                reason = row.reason,
                severity = row.severity or 'medium',
                points = tonumber(row.points) or 1,
                active = (row.active == 1 or row.active == true),
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at),
                expires_at = expiresAt
            })
        end
    end
    
    return warnings
end

-- Helper: Get all kicks
local function getAllKicks()
    local kicks = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_moderation_kicks
        ORDER BY created_at DESC
        LIMIT 500
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(kicks, {
                id = row.id,
                player_id = row.player_id,
                player_name = row.player_name,
                admin_id = row.admin_id,
                admin_name = row.admin_name,
                reason = row.reason,
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at)
            })
        end
    end
    
    return kicks
end

-- Helper: Get all mutes
local function getAllMutes()
    local mutes = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_moderation_mutes
        ORDER BY created_at DESC
        LIMIT 500
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            local expiresAt = nil
            if row.expires_at then
                expiresAt = os.date('%Y-%m-%dT%H:%M:%SZ', row.expires_at)
            end
            
            table.insert(mutes, {
                id = row.id,
                player_id = row.player_id,
                player_name = row.player_name,
                admin_id = row.admin_id,
                admin_name = row.admin_name,
                reason = row.reason,
                duration = tonumber(row.duration) or 0,
                active = (row.active == 1 or row.active == true),
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at),
                expires_at = expiresAt
            })
        end
    end
    
    return mutes
end

-- Helper: Get all reports
local function getAllReports()
    local reports = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_moderation_reports
        ORDER BY created_at DESC
        LIMIT 500
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(reports, {
                id = row.id,
                reporter_id = row.reporter_id,
                reporter_name = row.reporter_name,
                reported_id = row.reported_id,
                reported_name = row.reported_name,
                reason = row.reason,
                category = row.category or 'other',
                status = row.status or 'pending',
                assigned_to = row.assigned_to,
                assigned_name = row.assigned_name,
                resolution = row.resolution,
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at),
                updated_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.updated_at)
            })
        end
    end
    
    return reports
end

-- Helper: Get all action logs
local function getAllActionLogs()
    local actionLogs = {}
    local result = MySQL.query.await([[
        SELECT * FROM ec_moderation_action_logs
        ORDER BY created_at DESC
        LIMIT 500
    ]], {})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(actionLogs, {
                id = row.id,
                admin_id = row.admin_id,
                admin_name = row.admin_name,
                action_type = row.action_type,
                target_id = row.target_id,
                target_name = row.target_name,
                reason = row.reason,
                details = row.details,
                created_at = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at)
            })
        end
    end
    
    return actionLogs
end

-- Helper: Get moderation data (shared logic)
local function getModerationData()
    -- Check cache
    if dataCache.data and (getCurrentTimestamp() - dataCache.timestamp) < CACHE_TTL then
        return dataCache.data
    end
    
    local warnings = getAllWarnings()
    local kicks = getAllKicks()
    local mutes = getAllMutes()
    local reports = getAllReports()
    local actionLogs = getAllActionLogs()
    
    -- Calculate statistics
    local stats = {
        totalWarnings = #warnings,
        totalKicks = #kicks,
        activeMutes = 0,
        pendingReports = 0,
        totalActions = #actionLogs,
        warningsToday = 0,
        kicksToday = 0,
        reportsToday = 0
    }
    
    local today = os.time() - (os.time() % 86400) -- Start of today
    
    for _, mute in ipairs(mutes) do
        if mute.active then
            stats.activeMutes = stats.activeMutes + 1
        end
    end
    
    for _, report in ipairs(reports) do
        if report.status == 'pending' then
            stats.pendingReports = stats.pendingReports + 1
        end
    end
    
    for _, warning in ipairs(warnings) do
        local warningTime = os.time({year = tonumber(string.sub(warning.created_at, 1, 4)), month = tonumber(string.sub(warning.created_at, 6, 7)), day = tonumber(string.sub(warning.created_at, 9, 10))})
        if warningTime >= today then
            stats.warningsToday = stats.warningsToday + 1
        end
    end
    
    for _, kick in ipairs(kicks) do
        local kickTime = os.time({year = tonumber(string.sub(kick.created_at, 1, 4)), month = tonumber(string.sub(kick.created_at, 6, 7)), day = tonumber(string.sub(kick.created_at, 9, 10))})
        if kickTime >= today then
            stats.kicksToday = stats.kicksToday + 1
        end
    end
    
    for _, report in ipairs(reports) do
        local reportTime = os.time({year = tonumber(string.sub(report.created_at, 1, 4)), month = tonumber(string.sub(report.created_at, 6, 7)), day = tonumber(string.sub(report.created_at, 9, 10))})
        if reportTime >= today then
            stats.reportsToday = stats.reportsToday + 1
        end
    end
    
    local data = {
        warnings = warnings,
        kicks = kicks,
        mutes = mutes,
        reports = reports,
        actionLogs = actionLogs,
        stats = stats,
        framework = getFramework()
    }
    
    -- Cache data
    dataCache = {
        data = data,
        timestamp = getCurrentTimestamp()
    }
    
    return data
end

-- ============================================================================
-- REGISTERNUICALLBACK HANDLERS (Direct fetch from UI)
-- ============================================================================

-- Callback: Get moderation data
RegisterNUICallback('moderation:getData', function(data, cb)
    local response = getModerationData()
    cb({ success = true, data = response })
end)

-- Callback: Issue warning
RegisterNUICallback('moderation:issueWarning', function(data, cb)
    local targetId = tonumber(data.targetId)
    local reason = data.reason
    local severity = data.severity or 'medium'
    local points = tonumber(data.points) or 1
    local duration = tonumber(data.duration) or 0
    
    if not targetId or not reason then
        cb({ success = false, message = 'Target ID and reason required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Warning issued successfully'
    
    local playerIdentifier = getPlayerIdentifierFromId(targetId)
    if not playerIdentifier then
        cb({ success = false, message = 'Player not found' })
        return
    end
    
    local playerName = GetPlayerName(targetId) or 'Unknown'
    local expiresAt = nil
    if duration > 0 then
        expiresAt = getCurrentTimestamp() + (duration * 60) -- Duration in minutes
    end
    
    -- Insert warning
    MySQL.insert.await([[
        INSERT INTO ec_moderation_warnings 
        (player_id, player_name, admin_id, admin_name, reason, severity, points, active, created_at, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
    ]], {
        playerIdentifier, playerName, adminInfo.id, adminInfo.name, reason, severity, points,
        getCurrentTimestamp(), expiresAt
    })
    
    success = true
    
    -- Log action
    logModerationAction(adminInfo.id, adminInfo.name, 'warn', playerIdentifier, playerName, reason, {
        severity = severity,
        points = points,
        duration = duration
    })
    
    -- Notify player if online
    if GetPlayerPing(targetId) then
        TriggerClientEvent('ec_admin:notify', targetId, 'warning', 'You have been warned: ' .. reason)
    end
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to issue warning' })
end)

-- Callback: Kick player
RegisterNUICallback('moderation:kickPlayer', function(data, cb)
    local targetId = tonumber(data.targetId)
    local reason = data.reason or 'No reason provided'
    
    if not targetId then
        cb({ success = false, message = 'Target ID required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Player kicked successfully'
    
    if not GetPlayerPing(targetId) then
        cb({ success = false, message = 'Player not found' })
        return
    end
    
    local playerIdentifier = getPlayerIdentifierFromId(targetId)
    local playerName = GetPlayerName(targetId) or 'Unknown'
    
    -- Insert kick record
    MySQL.insert.await([[
        INSERT INTO ec_moderation_kicks 
        (player_id, player_name, admin_id, admin_name, reason, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        playerIdentifier, playerName, adminInfo.id, adminInfo.name, reason, getCurrentTimestamp()
    })
    
    -- Kick player
    DropPlayer(targetId, string.format('Kicked by admin: %s', reason))
    success = true
    
    -- Log action
    logModerationAction(adminInfo.id, adminInfo.name, 'kick', playerIdentifier, playerName, reason, nil)
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to kick player' })
end)

-- Callback: Mute player
RegisterNUICallback('moderation:mutePlayer', function(data, cb)
    local targetId = tonumber(data.targetId)
    local reason = data.reason or 'No reason provided'
    local duration = tonumber(data.duration) or 60 -- Default 60 minutes
    
    if not targetId or not reason then
        cb({ success = false, message = 'Target ID and reason required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Player muted successfully'
    
    local playerIdentifier = getPlayerIdentifierFromId(targetId)
    if not playerIdentifier then
        cb({ success = false, message = 'Player not found' })
        return
    end
    
    local playerName = GetPlayerName(targetId) or 'Unknown'
    local expiresAt = getCurrentTimestamp() + (duration * 60) -- Duration in minutes
    
    -- Deactivate existing mutes
    MySQL.update.await([[
        UPDATE ec_moderation_mutes 
        SET active = 0 
        WHERE player_id = ? AND active = 1
    ]], {playerIdentifier})
    
    -- Insert mute record
    MySQL.insert.await([[
        INSERT INTO ec_moderation_mutes 
        (player_id, player_name, admin_id, admin_name, reason, duration, active, created_at, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)
    ]], {
        playerIdentifier, playerName, adminInfo.id, adminInfo.name, reason, duration,
        getCurrentTimestamp(), expiresAt
    })
    
    success = true
    
    -- Log action
    logModerationAction(adminInfo.id, adminInfo.name, 'mute', playerIdentifier, playerName, reason, {
        duration = duration
    })
    
    -- Notify player if online
    if GetPlayerPing(targetId) then
        TriggerClientEvent('ec_admin:notify', targetId, 'warning', string.format('You have been muted for %d minutes: %s', duration, reason))
        -- Trigger mute event (integrate with your chat system)
        TriggerEvent('ec_admin:mutePlayer', targetId, duration)
    end
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to mute player' })
end)

-- Callback: Remove warning
RegisterNUICallback('moderation:removeWarning', function(data, cb)
    local warningId = tonumber(data.warningId)
    
    if not warningId then
        cb({ success = false, message = 'Warning ID required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Warning removed successfully'
    
    -- Get warning info
    local result = MySQL.query.await('SELECT * FROM ec_moderation_warnings WHERE id = ? LIMIT 1', {warningId})
    if not result or not result[1] then
        cb({ success = false, message = 'Warning not found' })
        return
    end
    
    local warning = result[1]
    
    -- Deactivate warning
    MySQL.update.await([[
        UPDATE ec_moderation_warnings 
        SET active = 0 
        WHERE id = ?
    ]], {warningId})
    
    success = true
    
    -- Log action
    logModerationAction(adminInfo.id, adminInfo.name, 'remove_warning', warning.player_id, warning.player_name, nil, {
        warning_id = warningId
    })
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to remove warning' })
end)

-- Callback: Unmute player
RegisterNUICallback('moderation:unmutePlayer', function(data, cb)
    local muteId = tonumber(data.muteId)
    
    if not muteId then
        cb({ success = false, message = 'Mute ID required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Player unmuted successfully'
    
    -- Get mute info
    local result = MySQL.query.await('SELECT * FROM ec_moderation_mutes WHERE id = ? LIMIT 1', {muteId})
    if not result or not result[1] then
        cb({ success = false, message = 'Mute not found' })
        return
    end
    
    local mute = result[1]
    
    -- Deactivate mute
    MySQL.update.await([[
        UPDATE ec_moderation_mutes 
        SET active = 0 
        WHERE id = ?
    ]], {muteId})
    
    success = true
    
    -- Log action
    logModerationAction(adminInfo.id, adminInfo.name, 'unmute', mute.player_id, mute.player_name, nil, {
        mute_id = muteId
    })
    
    -- Notify player if online
    local source = getPlayerSourceByIdentifier(mute.player_id)
    if source then
        TriggerClientEvent('ec_admin:notify', source, 'success', 'You have been unmuted')
        -- Trigger unmute event (integrate with your chat system)
        TriggerEvent('ec_admin:unmutePlayer', source)
    end
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to unmute player' })
end)

-- Callback: Update report status
RegisterNUICallback('moderation:updateReportStatus', function(data, cb)
    local reportId = tonumber(data.reportId)
    local status = data.status
    local resolution = data.resolution
    
    if not reportId or not status then
        cb({ success = false, message = 'Report ID and status required' })
        return
    end
    
    local adminInfo = { id = 'system', name = 'System' }
    local success = false
    local message = 'Report status updated successfully'
    
    -- Get report info
    local result = MySQL.query.await('SELECT * FROM ec_moderation_reports WHERE id = ? LIMIT 1', {reportId})
    if not result or not result[1] then
        cb({ success = false, message = 'Report not found' })
        return
    end
    
    local report = result[1]
    
    -- Update report
    MySQL.update.await([[
        UPDATE ec_moderation_reports 
        SET status = ?, resolution = ?, assigned_to = ?, assigned_name = ?, updated_at = ?
        WHERE id = ?
    ]], {
        status, resolution, adminInfo.id, adminInfo.name, getCurrentTimestamp(), reportId
    })
    
    success = true
    
    -- Log action
    logModerationAction(adminInfo.id, adminInfo.name, 'update_report', report.reported_id, report.reported_name, nil, {
        report_id = reportId,
        old_status = report.status,
        new_status = status,
        resolution = resolution
    })
    
    -- Clear cache
    dataCache = {}
    
    cb({ success = success, message = success and message or 'Failed to update report status' })
end)

print("^2[Moderation]^7 UI Backend loaded^0")

