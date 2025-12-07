--[[
    EC Admin Ultimate - Moderation Callbacks
    Complete moderation system with warnings, kicks, bans, mutes, and reports
    Supports: QB-Core, QBX, ESX, Standalone
]]

local QBCore = nil
local ESX = nil
local Framework = 'unknown'

-- Initialize framework
CreateThread(function()
    Wait(1000)
    
    if GetResourceState('qbx_core') == 'started' then
        QBCore = exports.qbx_core -- QBX uses direct export
        Framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
    else
        Framework = 'standalone'
    end
    
    Logger.Debug('Moderation System Initialized: ' .. Framework)
end)

-- Tables are now automatically created by auto-migrate-sql.lua from sql/ec_admin_ultimate.sql
-- No need to create them here - this ensures consistent schema for both customers and host

-- Helper: Get player identifier
local function GetPlayerIdentifier(src)
    if Framework == 'qbx' then
        -- QBX uses direct export
        local Player = exports.qbx_core:GetPlayer(src)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'qb-core' then
        -- QB-Core uses GetCoreObject
        local Player = QBCore.Functions.GetPlayer(src)
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier or nil
    else
        return GetPlayerIdentifier(src, 0)
    end
end

-- Helper: Get player name
local function GetPlayerNameById(identifier)
    if not identifier then return 'Unknown' end
    
    if Framework == 'qb-core' or Framework == 'qbx' then
        local result = MySQL.Sync.fetchAll('SELECT charinfo FROM players WHERE citizenid = ? LIMIT 1', {identifier})
        if result and result[1] then
            local charinfo = json.decode(result[1].charinfo)
            if charinfo then
                return (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
            end
        end
    elseif Framework == 'esx' then
        local result = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = ? LIMIT 1', {identifier})
        if result and result[1] then
            return (result[1].firstname or '') .. ' ' .. (result[1].lastname or '')
        end
    end
    
    return 'Unknown'
end

-- Helper: Log moderation action
local function LogAction(adminSrc, actionType, targetId, targetName, reason, details)
    local adminId = GetPlayerIdentifier(adminSrc)
    local adminName = GetPlayerName(adminSrc)
    
    MySQL.Async.execute([[
        INSERT INTO ec_mod_actions (admin_id, admin_name, action_type, target_id, target_name, reason, details)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {adminId, adminName, actionType, targetId, targetName, reason, details})
end

-- ============================================================================
-- LIB.CALLBACK: MODERATION ACTIONS (for NUI with return values)
-- ============================================================================

lib.callback.register('ec_admin:issueWarning', function(source, data)
    local targetId = tonumber(data.targetId)
    local reason = data.reason
    local severity = data.severity or 'medium'
    local points = tonumber(data.points) or 1
    local duration = tonumber(data.duration) or 0
    
    if not targetId or not reason then
        return { success = false, message = 'Invalid data' }
    end
    
    local targetName = GetPlayerName(targetId)
    if not targetName then
        return { success = false, message = 'Player not found' }
    end
    
    local targetIdentifier = GetPlayerIdentifier(targetId)
    local adminId = GetPlayerIdentifier(source)
    local adminName = GetPlayerName(source)
    
    local expiresAt = nil
    if duration > 0 then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (duration * 24 * 60 * 60))
    end
    
    MySQL.Async.execute([[
        INSERT INTO ec_warnings (player_id, player_name, admin_id, admin_name, reason, severity, points, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {targetIdentifier, targetName, adminId, adminName, reason, severity, points, expiresAt})
    
    LogAction(source, 'warning', targetIdentifier, targetName, reason, json.encode({severity = severity, points = points}))
    
    return { success = true, message = 'Warning issued successfully' }
end)

lib.callback.register('ec_admin:kickPlayer', function(source, data)
    local targetId = tonumber(data.targetId)
    local reason = data.reason or 'No reason provided'
    
    if not targetId then
        return { success = false, message = 'Invalid player ID' }
    end
    
    local targetName = GetPlayerName(targetId)
    if not targetName then
        return { success = false, message = 'Player not found' }
    end
    
    local targetIdentifier = GetPlayerIdentifier(targetId)
    local adminId = GetPlayerIdentifier(source)
    local adminName = GetPlayerName(source)
    
    MySQL.Async.execute([[
        INSERT INTO ec_kicks (player_id, player_name, admin_id, admin_name, reason)
        VALUES (?, ?, ?, ?, ?)
    ]], {targetIdentifier, targetName, adminId, adminName, reason})
    
    LogAction(source, 'kick', targetIdentifier, targetName, reason, nil)
    
    DropPlayer(targetId, '🚫 Kicked by ' .. adminName .. '\\nReason: ' .. reason)
    
    return { success = true, message = 'Player kicked successfully' }
end)

lib.callback.register('ec_admin:mutePlayer', function(source, data)
    local targetId = tonumber(data.targetId)
    local reason = data.reason or 'No reason provided'
    local duration = tonumber(data.duration) or 60
    
    if not targetId then
        return { success = false, message = 'Invalid player ID' }
    end
    
    local targetName = GetPlayerName(targetId)
    if not targetName then
        return { success = false, message = 'Player not found' }
    end
    
    local targetIdentifier = GetPlayerIdentifier(targetId)
    local adminId = GetPlayerIdentifier(source)
    local adminName = GetPlayerName(source)
    
    local expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (duration * 60))
    
    MySQL.Async.execute([[
        INSERT INTO ec_mutes (player_id, player_name, admin_id, admin_name, reason, duration, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {targetIdentifier, targetName, adminId, adminName, reason, duration, expiresAt})
    
    LogAction(source, 'mute', targetIdentifier, targetName, reason, json.encode({duration = duration}))
    
    return { success = true, message = 'Player muted successfully' }
end)

lib.callback.register('ec_admin:unmutePlayer', function(source, data)
    local muteId = tonumber(data.muteId)
    
    if not muteId then
        return { success = false, message = 'Invalid mute ID' }
    end
    
    MySQL.Async.execute('UPDATE ec_mutes SET active = 0 WHERE id = ?', {muteId})
    
    return { success = true, message = 'Player unmuted successfully' }
end)

lib.callback.register('ec_admin:removeWarning', function(source, data)
    local warningId = tonumber(data.warningId)
    
    if not warningId then
        return { success = false, message = 'Invalid warning ID' }
    end
    
    MySQL.Async.execute('UPDATE ec_warnings SET active = 0 WHERE id = ?', {warningId})
    
    return { success = true, message = 'Warning removed successfully' }
end)

-- ❌ DUPLICATE CALLBACK - Disabled to avoid conflict
-- This callback has a better implementation in reports-callbacks.lua
-- NOTE: Commented out to avoid [[]] syntax conflict with multi-line comments
--[===[
lib.callback.register('ec_admin:updateReportStatus', function(source, data)
    local reportId = tonumber(data.reportId)
    local status = data.status
    local resolution = data.resolution
    
    if not reportId or not status then
        return { success = false, message = 'Invalid data' }
    end
    
    local adminId = GetPlayerIdentifier(source)
    local adminName = GetPlayerName(source)
    
    if status == 'investigating' then
        MySQL.Async.execute([[
            UPDATE ec_reports 
            SET status = ?, assigned_to = ?, assigned_name = ?
            WHERE id = ?
        ]], {status, adminId, adminName, reportId})
    else
        MySQL.Async.execute([[
            UPDATE ec_reports 
            SET status = ?, resolution = ?
            WHERE id = ?
        ]], {status, resolution, reportId})
    end
    
    return { success = true, message = 'Report updated successfully' }
end)
]===]

-- ❌ DUPLICATE CALLBACK - Disabled to avoid conflict
-- This callback has a better implementation in reports-callbacks.lua (with filtering & counts)
-- lib.callback.register('ec_admin:getReports', function(source, data)
--     local reports = MySQL.Sync.fetchAll([[
--         SELECT * FROM ec_reports 
--         ORDER BY created_at DESC 
--         LIMIT 100
--     ]], {})
--     
--     return { success = true, reports = reports or {} }
-- end)

-- ============================================================================
-- NET EVENTS (for backwards compatibility)
-- ============================================================================

-- Issue warning
RegisterNetEvent('ec_admin_ultimate:server:issueWarning', function(data)
    local src = source
    local targetId = tonumber(data.targetId)
    local reason = data.reason
    local severity = data.severity or 'medium'
    local points = tonumber(data.points) or 1
    local duration = tonumber(data.duration) or 0
    
    if not targetId or not reason then
        TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
            success = false,
            message = 'Invalid data'
        })
        return
    end
    
    local targetName = GetPlayerName(targetId)
    if not targetName then
        TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
            success = false,
            message = 'Player not found'
        })
        return
    end
    
    local targetIdentifier = GetPlayerIdentifier(targetId)
    local adminId = GetPlayerIdentifier(src)
    local adminName = GetPlayerName(src)
    
    local expiresAt = nil
    if duration > 0 then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (duration * 24 * 60 * 60))
    end
    
    MySQL.Async.execute([[
        INSERT INTO ec_warnings (player_id, player_name, admin_id, admin_name, reason, severity, points, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {targetIdentifier, targetName, adminId, adminName, reason, severity, points, expiresAt})
    
    LogAction(src, 'warning', targetIdentifier, targetName, reason, json.encode({severity = severity, points = points}))
    
    -- Notify target player
    TriggerClientEvent('ec_admin_ultimate:client:receiveWarning', targetId, {
        admin = adminName,
        reason = reason,
        severity = severity,
        points = points
    })
    
    TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
        success = true,
        message = 'Warning issued successfully'
    })
    
    Logger.Debug(string.format('%s issued warning to %s (ID: %d) - Reason: %s', adminName, targetName, targetId, reason), '⚠️')
end)

-- Kick player
RegisterNetEvent('ec_admin_ultimate:server:kickPlayer', function(data)
    local src = source
    local targetId = tonumber(data.targetId)
    local reason = data.reason or 'No reason provided'
    
    if not targetId then
        TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
            success = false,
            message = 'Invalid player ID'
        })
        return
    end
    
    local targetName = GetPlayerName(targetId)
    if not targetName then
        TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
            success = false,
            message = 'Player not found'
        })
        return
    end
    
    local targetIdentifier = GetPlayerIdentifier(targetId)
    local adminId = GetPlayerIdentifier(src)
    local adminName = GetPlayerName(src)
    
    MySQL.Async.execute([[
        INSERT INTO ec_kicks (player_id, player_name, admin_id, admin_name, reason)
        VALUES (?, ?, ?, ?, ?)
    ]], {targetIdentifier, targetName, adminId, adminName, reason})
    
    LogAction(src, 'kick', targetIdentifier, targetName, reason, nil)
    
    DropPlayer(targetId, '🚫 Kicked by ' .. adminName .. '\nReason: ' .. reason)
    
    TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
        success = true,
        message = 'Player kicked successfully'
    })
    
    Logger.Debug(string.format('%s kicked %s (ID: %d) - Reason: %s', adminName, targetName, targetId, reason), '🚪')
end)

-- Mute player
RegisterNetEvent('ec_admin_ultimate:server:mutePlayer', function(data)
    local src = source
    local targetId = tonumber(data.targetId)
    local reason = data.reason or 'No reason provided'
    local duration = tonumber(data.duration) or 60
    
    if not targetId then
        TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
            success = false,
            message = 'Invalid player ID'
        })
        return
    end
    
    local targetName = GetPlayerName(targetId)
    if not targetName then
        TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
            success = false,
            message = 'Player not found'
        })
        return
    end
    
    local targetIdentifier = GetPlayerIdentifier(targetId)
    local adminId = GetPlayerIdentifier(src)
    local adminName = GetPlayerName(src)
    
    local expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (duration * 60))
    
    MySQL.Async.execute([[
        INSERT INTO ec_mutes (player_id, player_name, admin_id, admin_name, reason, duration, expires_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {targetIdentifier, targetName, adminId, adminName, reason, duration, expiresAt})
    
    LogAction(src, 'mute', targetIdentifier, targetName, reason, json.encode({duration = duration}))
    
    TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
        success = true,
        message = 'Player muted successfully'
    })
    
    Logger.Debug(string.format('%s muted %s (ID: %d) for %d minutes - Reason: %s', adminName, targetName, targetId, duration, reason), '🔇')
end)

-- Unmute player
RegisterNetEvent('ec_admin_ultimate:server:unmutePlayer', function(data)
    local src = source
    local muteId = tonumber(data.muteId)
    
    if not muteId then
        TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
            success = false,
            message = 'Invalid mute ID'
        })
        return
    end
    
    MySQL.Async.execute('UPDATE ec_mutes SET active = 0 WHERE id = ?', {muteId})
    
    TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
        success = true,
        message = 'Player unmuted successfully'
    })
end)

-- Remove warning
RegisterNetEvent('ec_admin_ultimate:server:removeWarning', function(data)
    local src = source
    local warningId = tonumber(data.warningId)
    
    if not warningId then
        TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
            success = false,
            message = 'Invalid warning ID'
        })
        return
    end
    
    MySQL.Async.execute('UPDATE ec_warnings SET active = 0 WHERE id = ?', {warningId})
    
    TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
        success = true,
        message = 'Warning removed successfully'
    })
end)

-- Update report status
RegisterNetEvent('ec_admin_ultimate:server:updateReportStatus', function(data)
    local src = source
    local reportId = tonumber(data.reportId)
    local status = data.status
    local resolution = data.resolution
    
    if not reportId or not status then
        TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
            success = false,
            message = 'Invalid data'
        })
        return
    end
    
    local adminId = GetPlayerIdentifier(src)
    local adminName = GetPlayerName(src)
    
    if status == 'investigating' then
        MySQL.Async.execute([[
            UPDATE ec_reports 
            SET status = ?, assigned_to = ?, assigned_name = ?
            WHERE id = ?
        ]], {status, adminId, adminName, reportId})
    else
        MySQL.Async.execute([[
            UPDATE ec_reports 
            SET status = ?, resolution = ?
            WHERE id = ?
        ]], {status, resolution, reportId})
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
        success = true,
        message = 'Report updated successfully'
    })
end)

-- Submit report (player-facing)
RegisterNetEvent('ec_admin_ultimate:server:submitReport', function(data)
    local src = source
    local reportedId = tonumber(data.reportedId)
    local reason = data.reason
    local category = data.category or 'other'
    
    if not reportedId or not reason then
        return
    end
    
    local reportedName = GetPlayerName(reportedId)
    if not reportedName then
        return
    end
    
    local reporterId = GetPlayerIdentifier(src)
    local reporterName = GetPlayerName(src)
    local reportedIdentifier = GetPlayerIdentifier(reportedId)
    
    MySQL.Async.execute([[
        INSERT INTO ec_reports (reporter_id, reporter_name, reported_id, reported_name, reason, category)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {reporterId, reporterName, reportedIdentifier, reportedName, reason, category})
    
    TriggerClientEvent('ec_admin_ultimate:client:moderationResponse', src, {
        success = true,
        message = 'Report submitted successfully'
    })
    
    Logger.Info(string.format('', reporterName, reportedName, reason))
end)

Logger.Info('Moderation callbacks loaded')