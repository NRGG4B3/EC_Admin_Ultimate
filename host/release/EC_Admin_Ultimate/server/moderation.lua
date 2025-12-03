-- EC Admin Ultimate - Moderation System (PRODUCTION STABLE)
-- Version: 1.0.0 - Complete bans, warnings, kicks, and appeals system

Logger.Info('🔨 Loading moderation system...')

local Moderation = {}

-- Framework detection
local Framework = nil
local FrameworkObject = nil

-- Configuration
local config = {
    maxWarningsBeforeBan = 5,
    warningExpireDays = 30,
    kickHistoryDays = 7,
    appealCooldownHours = 24
}

-- Safe framework detection
local function DetectFramework()
    -- Detect QBCore (QBX variant)
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('🔨 QBCore (qbx_core) detected')
        
        local success, coreObj = pcall(function()
            return exports['qbx_core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('🔨 QBCore framework successfully connected')
        else
            Logger.Info('⚠️ QBX Core detected but GetCoreObject() not available yet')
            Logger.Info('⚠️ Moderation will use basic mode until core loads')
        end
        return true  -- Return true even if core object isn't ready yet
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('🔨 QBCore (qb-core) detected')
        
        local success, coreObj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('🔨 QBCore framework successfully connected')
        else
            Logger.Info('⚠️ QB Core detected but GetCoreObject() not available yet')
        end
        return true  -- Return true even if core object isn't ready yet
    end
    
    -- Detect ESX
    if GetResourceState('es_extended') == 'started' then
        Framework = 'ESX'
        local success, esxObj = pcall(function()
            return exports["es_extended"]:getSharedObject()
        end)
        if success and esxObj then
            FrameworkObject = esxObj
            Logger.Info('🔨 ESX framework detected')
        end
        return true  -- Return true even if ESX object isn't ready yet
    end
    
    Logger.Info('⚠️ No supported framework detected for moderation')
    return false
end

-- Get player name from identifier
local function GetPlayerName(identifier)
    if not Framework or not FrameworkObject then
        return 'Unknown'
    end
    
    if Framework == 'QBCore' then
        -- Try online first
        for _, playerId in pairs(GetPlayers()) do
            local Player = FrameworkObject.Functions.GetPlayer(tonumber(playerId))
            if Player and (Player.PlayerData.citizenid == identifier or Player.PlayerData.license == identifier) then
                return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            end
        end
        
        -- Try database
        if MySQL and MySQL.query then
            local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ? OR license = ?', {identifier, identifier})
            if result and result[1] then
                local charinfo = json.decode(result[1].charinfo or '{}')
                return (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or 'Player')
            end
        end
    elseif Framework == 'ESX' then
        -- ESX implementation
        for _, playerId in pairs(GetPlayers()) do
            local xPlayer = FrameworkObject.GetPlayerFromId(tonumber(playerId))
            if xPlayer and xPlayer.identifier == identifier then
                return xPlayer.getName()
            end
        end
    end
    
    return 'Unknown'
end

-- Get player identifiers
local function GetPlayerIdentifiers(source)
    local identifiers = {
        steam = nil,
        license = nil,
        discord = nil,
        ip = nil
    }
    
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.find(id, 'steam:') then
            identifiers.steam = id
        elseif string.find(id, 'license:') then
            identifiers.license = id
        elseif string.find(id, 'discord:') then
            identifiers.discord = id
        elseif string.find(id, 'ip:') then
            identifiers.ip = id
        end
    end
    
    return identifiers
end

-- Get all bans
function Moderation.GetBans()
    local bans = {}
    
    if not MySQL or not MySQL.query then
        return bans
    end
    
    local result = MySQL.query.await('SELECT * FROM ec_admin_bans ORDER BY banned_at DESC')
    if result then
        for _, row in ipairs(result) do
            local expireTimestamp = row.expires or 0
            local status = 'active'
            
            if expireTimestamp > 0 and expireTimestamp < os.time() then
                status = 'expired'
            end
            
            if row.unbanned == 1 then
                status = 'unbanned'
            end
            
            if row.appealed == 1 then
                status = 'appealed'
            end
            
            table.insert(bans, {
                id = 'ban_' .. row.id,
                player = row.citizenid or row.identifier,
                playerName = GetPlayerName(row.citizenid or row.identifier),
                identifier = row.identifier,
                license = row.license,
                reason = row.reason,
                bannedBy = row.banned_by,
                bannedByName = GetPlayerName(row.banned_by),
                date = os.date('%Y-%m-%d', row.banned_at),
                timestamp = row.banned_at,
                expires = expireTimestamp == 0 and 'Permanent' or os.date('%Y-%m-%d', expireTimestamp),
                expireTimestamp = expireTimestamp,
                status = status,
                permanent = expireTimestamp == 0,
                ipBan = row.ip_ban == 1,
                hwid = row.hwid
            })
        end
    end
    
    return bans
end

-- Get all warnings
function Moderation.GetWarnings()
    local warnings = {}
    
    if not MySQL or not MySQL.query then
        return warnings
    end
    
    local result = MySQL.query.await('SELECT * FROM warnings ORDER BY warn_date DESC')
    if result then
        for _, row in ipairs(result) do
            table.insert(warnings, {
                id = 'warn_' .. row.id,
                player = row.citizenid or row.identifier,
                playerName = GetPlayerName(row.citizenid or row.identifier),
                identifier = row.identifier,
                license = row.license,
                reason = row.reason,
                warnedBy = row.warned_by,
                warnedByName = GetPlayerName(row.warned_by),
                date = os.date('%Y-%m-%d', row.warn_date),
                timestamp = row.warn_date,
                count = row.warning_count or 1,
                severity = row.severity or 'low',
                acknowledged = row.acknowledged == 1
            })
        end
    end
    
    return warnings
end

-- Get recent kicks
function Moderation.GetKicks()
    local kicks = {}
    
    if not MySQL or not MySQL.query then
        return kicks
    end
    
    local cutoffTime = os.time() - (config.kickHistoryDays * 86400)
    local result = MySQL.query.await('SELECT * FROM kicks WHERE kick_time > ? ORDER BY kick_time DESC LIMIT 100', {cutoffTime})
    if result then
        for _, row in ipairs(result) do
            local timeDiff = os.time() - row.kick_time
            local timeStr = ''
            
            if timeDiff < 60 then
                timeStr = 'Just now'
            elseif timeDiff < 3600 then
                timeStr = math.floor(timeDiff / 60) .. ' min ago'
            elseif timeDiff < 86400 then
                timeStr = math.floor(timeDiff / 3600) .. ' hour' .. (math.floor(timeDiff / 3600) > 1 and 's' or '') .. ' ago'
            else
                timeStr = math.floor(timeDiff / 86400) .. ' day' .. (math.floor(timeDiff / 86400) > 1 and 's' or '') .. ' ago'
            end
            
            table.insert(kicks, {
                id = 'kick_' .. row.id,
                player = row.citizenid or row.identifier,
                playerName = GetPlayerName(row.citizenid or row.identifier),
                identifier = row.identifier,
                reason = row.reason,
                kickedBy = row.kicked_by,
                kickedByName = GetPlayerName(row.kicked_by),
                time = timeStr,
                timestamp = row.kick_time
            })
        end
    end
    
    return kicks
end

-- Get all appeals
function Moderation.GetAppeals()
    local appeals = {}
    
    if not MySQL or not MySQL.query then
        return appeals
    end
    
    local result = MySQL.query.await('SELECT * FROM ban_appeals ORDER BY appeal_date DESC')
    if result then
        for _, row in ipairs(result) do
            table.insert(appeals, {
                id = 'appeal_' .. row.id,
                player = row.citizenid or row.identifier,
                playerName = GetPlayerName(row.citizenid or row.identifier),
                banId = 'ban_' .. row.ban_id,
                reason = row.ban_reason,
                appealReason = row.appeal_reason,
                date = os.date('%Y-%m-%d', row.appeal_date),
                timestamp = row.appeal_date,
                status = row.status,
                reviewedBy = row.reviewed_by,
                reviewedByName = row.reviewed_by and GetPlayerName(row.reviewed_by) or nil,
                reviewDate = row.review_date and os.date('%Y-%m-%d', row.review_date) or nil
            })
        end
    end
    
    return appeals
end

-- Get comprehensive moderation data
function Moderation.GetAllData()
    local bans = Moderation.GetBans()
    local warnings = Moderation.GetWarnings()
    local kicks = Moderation.GetKicks()
    local appeals = Moderation.GetAppeals()
    
    local stats = {
        totalBans = #bans,
        activeBans = 0,
        permanentBans = 0,
        totalWarnings = #warnings,
        activeWarnings = 0,
        totalKicks = #kicks,
        pendingAppeals = 0
    }
    
    -- Calculate stats
    for _, ban in ipairs(bans) do
        if ban.status == 'active' then
            stats.activeBans = stats.activeBans + 1
        end
        if ban.permanent then
            stats.permanentBans = stats.permanentBans + 1
        end
    end
    
    for _, warning in ipairs(warnings) do
        if not warning.acknowledged then
            stats.activeWarnings = stats.activeWarnings + 1
        end
    end
    
    for _, appeal in ipairs(appeals) do
        if appeal.status == 'pending' then
            stats.pendingAppeals = stats.pendingAppeals + 1
        end
    end
    
    return {
        bans = bans,
        warnings = warnings,
        kicks = kicks,
        appeals = appeals,
        framework = Framework,
        stats = stats
    }
end

-- Add ban
function Moderation.AddBan(adminSource, playerId, reason, duration, ipBan, hwidBan)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'banPlayers') then
        return false, 'Insufficient permissions'
    end
    
    if not MySQL or not MySQL.query then
        return false, 'Database not available'
    end
    
    -- Get player info
    local targetSource = tonumber(playerId)
    local targetPlayer = nil
    local identifier = nil
    local license = nil
    local citizenid = nil
    local ip = nil
    local hwid = nil
    
    if Framework == 'QBCore' and FrameworkObject then
        if targetSource then
            targetPlayer = FrameworkObject.Functions.GetPlayer(targetSource)
        else
            -- Try to find by citizenid
            for _, pid in pairs(GetPlayers()) do
                local p = FrameworkObject.Functions.GetPlayer(tonumber(pid))
                if p and p.PlayerData.citizenid == playerId then
                    targetPlayer = p
                    targetSource = tonumber(pid)
                    break
                end
            end
        end
        
        if targetPlayer then
            citizenid = targetPlayer.PlayerData.citizenid
            license = targetPlayer.PlayerData.license
            identifier = GetPlayerIdentifiers(targetSource).steam or license
            ip = ipBan and GetPlayerIdentifiers(targetSource).ip or nil
            hwid = hwidBan and GetPlayerIdentifiers(targetSource).hwid or nil
        end
    end
    
    if not identifier then
        return false, 'Player not found'
    end
    
    -- Calculate expire timestamp
    local expireTimestamp = 0
    if duration ~= 'permanent' then
        local hours = tonumber(duration)
        if hours then
            expireTimestamp = os.time() + (hours * 3600)
        end
    end
    
    -- Get admin info
    local adminPlayer = nil
    local adminCitizenid = 'system'
    
    if Framework == 'QBCore' and FrameworkObject then
        adminPlayer = FrameworkObject.Functions.GetPlayer(adminSource)
        if adminPlayer then
            adminCitizenid = adminPlayer.PlayerData.citizenid
        end
    end
    
    -- Insert ban
    MySQL.insert('INSERT INTO bans (citizenid, identifier, license, reason, banned_by, ban_date, expire_timestamp, ip_ban, ip, hwid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {citizenid, identifier, license, reason, adminCitizenid, os.time(), expireTimestamp, ipBan and 1 or 0, ip, hwid})
    
    -- Kick the player if online
    if targetSource then
        DropPlayer(targetSource, 'You have been banned: ' .. reason)
    end
    
    Logger.Info(string.format('', citizenid or identifier, identifier, reason))
    return true, 'Player banned successfully'
end

-- Unban player
function Moderation.Unban(adminSource, banId, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'unbanPlayers') then
        return false, 'Insufficient permissions'
    end
    
    if not MySQL or not MySQL.query then
        return false, 'Database not available'
    end
    
    local id = tonumber(string.match(banId, '%d+'))
    if not id then
        return false, 'Invalid ban ID'
    end
    
    -- Get admin info
    local adminPlayer = nil
    local adminCitizenid = 'system'
    
    if Framework == 'QBCore' and FrameworkObject then
        adminPlayer = FrameworkObject.Functions.GetPlayer(adminSource)
        if adminPlayer then
            adminCitizenid = adminPlayer.PlayerData.citizenid
        end
    end
    
    -- Update ban
    MySQL.query('UPDATE bans SET unbanned = 1, unban_reason = ?, unbanned_by = ?, unban_date = ? WHERE id = ?',
        {reason, adminCitizenid, os.time(), id})
    
    Logger.Info(string.format('', banId, reason))
    return true, 'Player unbanned successfully'
end

-- Add warning
function Moderation.AddWarning(adminSource, playerId, reason, severity)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'warnPlayers') then
        return false, 'Insufficient permissions'
    end
    
    if not MySQL or not MySQL.query then
        return false, 'Database not available'
    end
    
    -- Get player info
    local targetSource = tonumber(playerId)
    local targetPlayer = nil
    local identifier = nil
    local license = nil
    local citizenid = nil
    
    if Framework == 'QBCore' and FrameworkObject then
        if targetSource then
            targetPlayer = FrameworkObject.Functions.GetPlayer(targetSource)
        else
            -- Try to find by citizenid
            for _, pid in pairs(GetPlayers()) do
                local p = FrameworkObject.Functions.GetPlayer(tonumber(pid))
                if p and p.PlayerData.citizenid == playerId then
                    targetPlayer = p
                    targetSource = tonumber(pid)
                    break
                end
            end
        end
        
        if targetPlayer then
            citizenid = targetPlayer.PlayerData.citizenid
            license = targetPlayer.PlayerData.license
            identifier = GetPlayerIdentifiers(targetSource).steam or license
        end
    end
    
    if not identifier then
        return false, 'Player not found'
    end
    
    -- Get admin info
    local adminPlayer = nil
    local adminCitizenid = 'system'
    
    if Framework == 'QBCore' and FrameworkObject then
        adminPlayer = FrameworkObject.Functions.GetPlayer(adminSource)
        if adminPlayer then
            adminCitizenid = adminPlayer.PlayerData.citizenid
        end
    end
    
    -- Get current warning count
    local result = MySQL.query.await('SELECT COUNT(*) as count FROM warnings WHERE citizenid = ? OR identifier = ?', {citizenid, identifier})
    local warningCount = result and result[1] and result[1].count or 0
    warningCount = warningCount + 1
    
    -- Insert warning
    MySQL.insert('INSERT INTO warnings (citizenid, identifier, license, reason, warned_by, warn_date, warning_count, severity) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {citizenid, identifier, license, reason, adminCitizenid, os.time(), warningCount, severity})
    
    -- Notify player if online
    if targetSource then
        TriggerClientEvent('chat:addMessage', targetSource, {
            color = {255, 165, 0},
            multiline = true,
            args = {'⚠️ Warning', 'You have been warned: ' .. reason .. ' (Warning #' .. warningCount .. ')'}
        })
    end
    
    -- Auto-ban if too many warnings
    if warningCount >= config.maxWarningsBeforeBan then
        Moderation.AddBan(adminSource, playerId, 'Too many warnings (' .. warningCount .. ')', '168', false, false)
        return true, 'Player warned and auto-banned for excessive warnings'
    end
    
    Logger.Info(string.format('', citizenid or identifier, identifier, reason))
    return true, 'Warning issued successfully'
end

-- Review appeal
function Moderation.ReviewAppeal(adminSource, appealId, approved)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'reviewAppeals') then
        return false, 'Insufficient permissions'
    end
    
    if not MySQL or not MySQL.query then
        return false, 'Database not available'
    end
    
    local id = tonumber(string.match(appealId, '%d+'))
    if not id then
        return false, 'Invalid appeal ID'
    end
    
    -- Get admin info
    local adminPlayer = nil
    local adminCitizenid = 'system'
    
    if Framework == 'QBCore' and FrameworkObject then
        adminPlayer = FrameworkObject.Functions.GetPlayer(adminSource)
        if adminPlayer then
            adminCitizenid = adminPlayer.PlayerData.citizenid
        end
    end
    
    -- Update appeal
    local status = approved and 'approved' or 'denied'
    MySQL.query('UPDATE ban_appeals SET status = ?, reviewed_by = ?, review_date = ? WHERE id = ?',
        {status, adminCitizenid, os.time(), id})
    
    -- If approved, unban the player
    if approved then
        local appeal = MySQL.query.await('SELECT ban_id FROM ban_appeals WHERE id = ?', {id})
        if appeal and appeal[1] then
            MySQL.query('UPDATE bans SET unbanned = 1, unban_reason = ?, unbanned_by = ?, unban_date = ? WHERE id = ?',
                {'Appeal approved', adminCitizenid, os.time(), appeal[1].ban_id})
        end
    end
    
    Logger.Info(string.format('', approved and 'approved' or 'denied', appealId))
    return true, 'Appeal ' .. (approved and 'approved' or 'denied')
end

-- Initialize
function Moderation.Initialize()
    Logger.Info('🔨 Initializing moderation system...')
    
    local frameworkDetected = DetectFramework()
    if not frameworkDetected then
        Logger.Info('⚠️ Moderation system disabled - no supported framework')
        return false
    end
    
    -- Create tables if they don't exist
    if MySQL and MySQL.query then
        -- Bans table
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `bans` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `citizenid` varchar(50) DEFAULT NULL,
                `identifier` varchar(50) NOT NULL,
                `license` varchar(50) DEFAULT NULL,
                `reason` text NOT NULL,
                `banned_by` varchar(50) NOT NULL,
                `ban_date` bigint(20) NOT NULL,
                `expire_timestamp` bigint(20) DEFAULT 0,
                `ip_ban` tinyint(1) DEFAULT 0,
                `ip` varchar(50) DEFAULT NULL,
                `hwid` varchar(255) DEFAULT NULL,
                `unbanned` tinyint(1) DEFAULT 0,
                `unban_reason` text DEFAULT NULL,
                `unbanned_by` varchar(50) DEFAULT NULL,
                `unban_date` bigint(20) DEFAULT NULL,
                `appealed` tinyint(1) DEFAULT 0,
                PRIMARY KEY (`id`),
                KEY `citizenid` (`citizenid`),
                KEY `identifier` (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
        
        -- Warnings table
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `warnings` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `citizenid` varchar(50) DEFAULT NULL,
                `identifier` varchar(50) NOT NULL,
                `license` varchar(50) DEFAULT NULL,
                `reason` text NOT NULL,
                `warned_by` varchar(50) NOT NULL,
                `warn_date` bigint(20) NOT NULL,
                `warning_count` int(11) DEFAULT 1,
                `severity` varchar(20) DEFAULT 'low',
                `acknowledged` tinyint(1) DEFAULT 0,
                PRIMARY KEY (`id`),
                KEY `citizenid` (`citizenid`),
                KEY `identifier` (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
        
        -- Kicks table
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `kicks` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `citizenid` varchar(50) DEFAULT NULL,
                `identifier` varchar(50) NOT NULL,
                `reason` text NOT NULL,
                `kicked_by` varchar(50) NOT NULL,
                `kick_time` bigint(20) NOT NULL,
                PRIMARY KEY (`id`),
                KEY `citizenid` (`citizenid`),
                KEY `kick_time` (`kick_time`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
        
        -- Ban appeals table
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `ban_appeals` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `ban_id` int(11) NOT NULL,
                `citizenid` varchar(50) DEFAULT NULL,
                `identifier` varchar(50) NOT NULL,
                `ban_reason` text NOT NULL,
                `appeal_reason` text NOT NULL,
                `appeal_date` bigint(20) NOT NULL,
                `status` varchar(20) DEFAULT 'pending',
                `reviewed_by` varchar(50) DEFAULT NULL,
                `review_date` bigint(20) DEFAULT NULL,
                PRIMARY KEY (`id`),
                KEY `ban_id` (`ban_id`),
                KEY `citizenid` (`citizenid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
        
        Logger.Info('🔨 Moderation database tables initialized')
    end
    
    Logger.Info('✅ Moderation system initialized with ' .. Framework .. ' framework')
    return true
end

-- Server events
RegisterNetEvent('ec-admin:getModerationData')
AddEventHandler('ec-admin:getModerationData', function()
    local source = source
    local data = Moderation.GetAllData()
    TriggerClientEvent('ec-admin:receiveModerationData', source, data)
end)

-- Admin action events
RegisterNetEvent('ec-admin:moderation:addBan')
AddEventHandler('ec-admin:moderation:addBan', function(data, cb)
    local source = source
    local success, message = Moderation.AddBan(source, data.playerId, data.reason, data.duration, data.ipBan, data.hwidBan)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:moderation:unban')
AddEventHandler('ec-admin:moderation:unban', function(data, cb)
    local source = source
    local success, message = Moderation.Unban(source, data.banId, data.reason)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:moderation:addWarning')
AddEventHandler('ec-admin:moderation:addWarning', function(data, cb)
    local source = source
    local success, message = Moderation.AddWarning(source, data.playerId, data.reason, data.severity)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:moderation:reviewAppeal')
AddEventHandler('ec-admin:moderation:reviewAppeal', function(data, cb)
    local source = source
    local success, message = Moderation.ReviewAppeal(source, data.appealId, data.approved)
    
    if cb then
        cb({ success = success, message = message })
    end
end)

-- Exports
exports('GetBans', function()
    return Moderation.GetBans()
end)

exports('GetWarnings', function()
    return Moderation.GetWarnings()
end)

exports('GetKicks', function()
    return Moderation.GetKicks()
end)

exports('GetAppeals', function()
    return Moderation.GetAppeals()
end)

exports('GetAllModerationData', function()
    return Moderation.GetAllData()
end)

-- Initialize
Moderation.Initialize()

-- Make available globally
_G.ECModeration = Moderation

Logger.Info('✅ Moderation system loaded successfully')