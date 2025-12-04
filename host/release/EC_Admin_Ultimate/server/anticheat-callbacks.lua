--[[
    EC Admin Ultimate - Advanced Anticheat System
    Complete anticheat with real-time detection and automated responses
    Detections: Aimbot, ESP, Speedhack, Noclip, Godmode, Teleport, Resource Injection, Mod Menu
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
    
    Logger.Info('Anticheat System Initialized: ' .. Framework)
end)

-- Anticheat tables are automatically created by auto-migrate-sql.lua
-- This ensures consistent schema for both customers and host mode
CreateThread(function()
    Wait(2000)
    Logger.Debug('Anticheat system ready - tables created by auto-migration system')
end)

-- ============================================================================
-- LIB.CALLBACK: GET ANTICHEAT DATA (for NUI)
-- ============================================================================

lib.callback.register('ec_admin:getAnticheatData', function(source, data)
    -- Wrap in pcall to handle database errors gracefully
    local success, result = pcall(function()
        -- Get recent detections
        local detections = MySQL.Sync.fetchAll([=[
            SELECT * FROM ec_anticheat_detections 
            ORDER BY created_at DESC 
            LIMIT 100
        ]=], {})
        
        -- Get flagged players
        local flaggedPlayers = MySQL.Sync.fetchAll([=[
            SELECT * FROM ec_anticheat_flags 
            WHERE risk_score > 50 
            ORDER BY risk_score DESC 
            LIMIT 50
        ]=], {})
        
        -- Get anticheat bans
        local bans = MySQL.Sync.fetchAll([=[
            SELECT * FROM ec_anticheat_bans 
            ORDER BY created_at DESC 
            LIMIT 50
        ]=], {})
        
        -- Get whitelisted players
        local whitelist = MySQL.Sync.fetchAll([=[
            SELECT * FROM ec_anticheat_whitelist 
            ORDER BY created_at DESC
        ]=], {})
        
        -- Calculate stats
        local stats = {
            totalDetections = #(detections or {}),
            criticalDetections = 0,
            highRiskPlayers = #(flaggedPlayers or {}),
            activeBans = #(bans or {}),
            whitelistedPlayers = #(whitelist or {})
        }
        
        for _, detection in ipairs(detections or {}) do
            if detection.severity == 'critical' then
                stats.criticalDetections = stats.criticalDetections + 1
            end
        end
        
        return {
            success = true,
            data = {
                detections = detections or {},
                flaggedPlayers = flaggedPlayers or {},
                bans = bans or {},
                whitelist = whitelist or {},
                stats = stats
            }
        }
    end)
    
    if success and result then
        return result
    else
        -- Return empty data structure on error
        Logger.Info('⚠️ Anticheat data fetch error: ' .. tostring(result))
        return {
            success = true,
            data = {
                detections = {},
                flaggedPlayers = {},
                bans = {},
                whitelist = {},
                stats = {
                    totalDetections = 0,
                    criticalDetections = 0,
                    highRiskPlayers = 0,
                    activeBans = 0,
                    whitelistedPlayers = 0
                }
            }
        }
    end
end)

-- Active player monitoring
local PlayerMonitoring = {}

-- Detection thresholds
local Config = {
    SpeedThreshold = 100.0,      -- m/s
    HeightThreshold = 500.0,     -- meters above ground
    TeleportDistance = 100.0,    -- meters
    GodmodeTime = 30,            -- seconds
    RapidFireThreshold = 10,     -- shots per second
    AimbotAccuracy = 95,         -- % headshot rate
    
    AutoActions = {
        low = 'log',             -- Just log
        medium = 'warn',         -- Warn player
        high = 'kick',           -- Kick player
        critical = 'ban'         -- Ban player
    },
    
    RiskScoreThresholds = {
        warn = 50,
        kick = 100,
        ban = 200
    }
}

-- Helper: Get player identifier
local function GetPlayerIdentifier(src)
    if Framework == 'qb-core' or Framework == 'qbx' then
        local Player = nil
        if Framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(src)
        else
            Player = QBCore.Functions.GetPlayer(src)
        end
        return Player and Player.PlayerData.citizenid or nil
    elseif Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier or nil
    else
        return GetPlayerIdentifiers(src)[1] or nil
    end
end

-- Helper: Check if whitelisted
local function IsWhitelisted(playerId)
    local result = MySQL.Sync.fetchAll('SELECT * FROM ec_anticheat_whitelist WHERE player_id = ? LIMIT 1', {playerId})
    return result and #result > 0
end

-- Helper: Log detection
local function LogDetection(src, detectionType, severity, details, evidence)
    local playerId = GetPlayerIdentifier(src)
    local playerName = GetPlayerName(src)
    
    if not playerId or IsWhitelisted(playerId) then
        return
    end
    
    -- Insert detection
    MySQL.Async.execute([[
        INSERT INTO ec_anticheat_detections (player_id, player_name, detection_type, severity, details, evidence)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {playerId, playerName, detectionType, severity, details, evidence})
    
    -- Update player risk score
    local riskIncrease = {low = 5, medium = 15, high = 30, critical = 50}
    MySQL.Async.execute([[
        INSERT INTO ec_anticheat_flags (player_id, player_name, risk_score, total_detections, last_detection)
        VALUES (?, ?, ?, 1, NOW())
        ON DUPLICATE KEY UPDATE
            risk_score = risk_score + ?,
            total_detections = total_detections + 1,
            last_detection = NOW()
    ]], {playerId, playerName, riskIncrease[severity], riskIncrease[severity]})
    
    -- Get updated risk score
    local scoreResult = MySQL.Sync.fetchAll('SELECT risk_score FROM ec_anticheat_flags WHERE player_id = ?', {playerId})
    local riskScore = scoreResult and scoreResult[1] and scoreResult[1].risk_score or 0
    
    -- Notify all admins
    TriggerClientEvent('ec_admin_ultimate:client:anticheatAlert', -1, {
        playerId = src,
        playerName = playerName,
        detectionType = detectionType,
        severity = severity,
        details = details,
        riskScore = riskScore
    })
    
    -- Auto action
    local action = Config.AutoActions[severity]
    
    if riskScore >= Config.RiskScoreThresholds.ban or action == 'ban' then
        -- Auto ban
        MySQL.Async.execute([[
            INSERT INTO ec_anticheat_bans (player_id, player_name, reason, evidence, ban_type, banned_by)
            VALUES (?, ?, ?, ?, 'permanent', 'ANTICHEAT')
        ]], {playerId, playerName, 'Anticheat: ' .. detectionType, details})
        
        MySQL.Async.execute('UPDATE ec_anticheat_flags SET banned = 1 WHERE player_id = ?', {playerId})
        
        DropPlayer(src, '🚫 BANNED: Anticheat Detection\nType: ' .. detectionType .. '\nIf you believe this is an error, contact server staff.')
        
        Logger.Error(string.format('🚫 BANNED %s (ID: %d) - %s', playerName, src, detectionType))
    elseif riskScore >= Config.RiskScoreThresholds.kick or action == 'kick' then
        -- Auto kick
        DropPlayer(src, '⚠️ KICKED: Suspicious Activity Detected\nType: ' .. detectionType .. '\nRisk Score: ' .. riskScore)
        
        Logger.Warn(string.format('⚠️ KICKED %s (ID: %d) - %s', playerName, src, detectionType))
    elseif action == 'warn' then
        -- Warn player
        TriggerClientEvent('ec_admin_ultimate:client:anticheatWarning', src, {
            type = detectionType,
            message = 'Suspicious activity detected. This has been logged.',
            riskScore = riskScore
        })
        
        Logger.Info(string.format('⚠️ WARNED %s (ID: %d) - %s', playerName, src, detectionType))
    else
        -- Just log
        Logger.Info(string.format('📝 LOGGED %s (ID: %d) - %s', playerName, src, detectionType))
    end
end

-- Client detection report
RegisterNetEvent('ec_admin_ultimate:server:reportDetection', function(data)
    local src = source
    
    if not data or not data.type then return end
    
    LogDetection(src, data.type, data.severity or 'medium', data.details or '', data.evidence or '')
end)

-- Manual ban player
RegisterNetEvent('ec_admin_ultimate:server:banPlayer', function(data)
    local src = source
    local targetId = tonumber(data.targetId)
    local reason = data.reason or 'No reason provided'
    local banType = data.banType or 'permanent'
    local duration = tonumber(data.duration) or 0
    
    if not targetId then
        TriggerClientEvent('ec_admin_ultimate:client:anticheatResponse', src, {
            success = false,
            message = 'Invalid player ID'
        })
        return
    end
    
    local targetName = GetPlayerName(targetId)
    if not targetName then
        TriggerClientEvent('ec_admin_ultimate:client:anticheatResponse', src, {
            success = false,
            message = 'Player not found'
        })
        return
    end
    
    local targetIdentifier = GetPlayerIdentifier(targetId)
    local adminName = GetPlayerName(src)
    
    local expiresAt = nil
    if banType == 'temporary' and duration > 0 then
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (duration * 24 * 60 * 60))
    end
    
    MySQL.Async.execute([[
        INSERT INTO ec_anticheat_bans (player_id, player_name, reason, ban_type, expires_at, banned_by)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {targetIdentifier, targetName, reason, banType, expiresAt, adminName})
    
    MySQL.Async.execute('UPDATE ec_anticheat_flags SET banned = 1 WHERE player_id = ?', {targetIdentifier})
    
    DropPlayer(targetId, '🚫 BANNED: ' .. reason)
    
    TriggerClientEvent('ec_admin_ultimate:client:anticheatResponse', src, {
        success = true,
        message = 'Player banned successfully'
    })
    
    Logger.Error(string.format('🚫 %s banned %s - Reason: %s', adminName, targetName, reason))
end)

-- Unban player
RegisterNetEvent('ec_admin_ultimate:server:unbanPlayer', function(data)
    local src = source
    local playerId = data.playerId
    
    if not playerId then
        TriggerClientEvent('ec_admin_ultimate:client:anticheatResponse', src, {
            success = false,
            message = 'Invalid player ID'
        })
        return
    end
    
    MySQL.Async.execute('DELETE FROM ec_anticheat_bans WHERE player_id = ?', {playerId})
    MySQL.Async.execute('UPDATE ec_anticheat_flags SET banned = 0 WHERE player_id = ?', {playerId})
    
    TriggerClientEvent('ec_admin_ultimate:client:anticheatResponse', src, {
        success = true,
        message = 'Player unbanned successfully'
    })
end)

-- Add to whitelist
RegisterNetEvent('ec_admin_ultimate:server:addWhitelist', function(data)
    local src = source
    local playerId = data.playerId
    local playerName = data.playerName or 'Unknown'
    local reason = data.reason or 'No reason provided'
    local adminName = GetPlayerName(src)
    
    if not playerId then
        TriggerClientEvent('ec_admin_ultimate:client:anticheatResponse', src, {
            success = false,
            message = 'Invalid player ID'
        })
        return
    end
    
    MySQL.Async.execute([[
        INSERT INTO ec_anticheat_whitelist (player_id, player_name, reason, added_by)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE reason = ?, added_by = ?
    ]], {playerId, playerName, reason, adminName, reason, adminName})
    
    TriggerClientEvent('ec_admin_ultimate:client:anticheatResponse', src, {
        success = true,
        message = 'Player whitelisted successfully'
    })
end)

-- Remove from whitelist
RegisterNetEvent('ec_admin_ultimate:server:removeWhitelist', function(data)
    local src = source
    local playerId = data.playerId
    
    if not playerId then
        TriggerClientEvent('ec_admin_ultimate:client:anticheatResponse', src, {
            success = false,
            message = 'Invalid player ID'
        })
        return
    end
    
    MySQL.Async.execute('DELETE FROM ec_anticheat_whitelist WHERE player_id = ?', {playerId})
    
    TriggerClientEvent('ec_admin_ultimate:client:anticheatResponse', src, {
        success = true,
        message = 'Player removed from whitelist'
    })
end)

-- Clear player risk score
RegisterNetEvent('ec_admin_ultimate:server:clearRiskScore', function(data)
    local src = source
    local playerId = data.playerId
    
    if not playerId then
        TriggerClientEvent('ec_admin_ultimate:client:anticheatResponse', src, {
            success = false,
            message = 'Invalid player ID'
        })
        return
    end
    
    MySQL.Async.execute('UPDATE ec_anticheat_flags SET risk_score = 0, total_detections = 0 WHERE player_id = ?', {playerId})
    
    TriggerClientEvent('ec_admin_ultimate:client:anticheatResponse', src, {
        success = true,
        message = 'Risk score cleared'
    })
end)

-- Check if player is banned on connect
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local src = source
    local identifier = GetPlayerIdentifier(src)
    
    if not identifier then return end
    
    -- Check for ban
    local result = MySQL.Sync.fetchAll([[
        SELECT * FROM ec_anticheat_bans 
        WHERE player_id = ? 
        AND (ban_type = 'permanent' OR (ban_type = 'temporary' AND expires_at > NOW()))
        LIMIT 1
    ]], {identifier})
    
    if result and #result > 0 then
        local ban = result[1]
        local message = '🚫 You are banned from this server\n\nReason: ' .. ban.reason
        
        if ban.ban_type == 'temporary' and ban.expires_at then
            message = message .. '\nExpires: ' .. ban.expires_at
        else
            message = message .. '\nType: Permanent'
        end
        
        message = message .. '\n\nIf you believe this is an error, contact server staff.'
        
        deferrals.done(message)
    end
end)

Logger.Info('Anticheat callbacks loaded')