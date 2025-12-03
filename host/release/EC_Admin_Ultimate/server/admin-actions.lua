-- EC Admin Ultimate - Server Event Handlers
-- Handles all admin actions from client events
-- NO RegisterNUICallback on server side

-- Config is loaded via shared_script in fxmanifest.lua
local Config = Config or {}
local FrameworkBridge = ECFramework or {}
local SendWebhook = _G.SendHostWebhook

local function EnsureWebhookHelper()
    if SendWebhook then return SendWebhook end

    local exporter = exports and exports['ec_admin_ultimate']
    if exporter and exporter.SendWebhook then
        SendWebhook = exporter.SendWebhook
        return SendWebhook
    end

    return nil
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function GetPlayerFromId(playerId)
    return FrameworkBridge.GetPlayerObject(playerId)
end

local function GetIdentifiers(source)
    return FrameworkBridge.GetIdentifiers(source)
end

local function LogAction(admin, action, target, details)
    MySQL.insert('INSERT INTO ec_admin_logs (admin_identifier, admin_name, action, target_identifier, target_name, details, timestamp) VALUES (?, ?, ?, ?, ?, ?, NOW())', {
        GetIdentifiers(admin).license,
        GetPlayerName(admin),
        action,
        target and GetIdentifiers(target).license or 'N/A',
        target and GetPlayerName(target) or 'N/A',
        json.encode(details or {})
    })
end

-- ============================================================================
-- REQUEST DATA EVENTS
-- ============================================================================

RegisterNetEvent('ec_admin:server:requestPlayers')
AddEventHandler('ec_admin:server:requestPlayers', function()
    local source = source
    if not HasAdminAccess(source, 'menu') then return end
    
    local players = {}
    local allPlayers = GetPlayers()
    
    for _, playerId in ipairs(allPlayers) do
        local targetId = tonumber(playerId)
        if targetId then
            local info = FrameworkBridge.GetPlayerInfo(targetId)
            if info then
                table.insert(players, info)
            end
        end
    end
    
    TriggerClientEvent('ec_admin:client:updatePlayers', source, players)
end)

RegisterNetEvent('ec_admin:server:requestBans')
AddEventHandler('ec_admin:server:requestBans', function()
    local source = source
    if not HasAdminAccess(source, 'menu') then return end
    
    local result = MySQL.query.await('SELECT * FROM ec_admin_bans WHERE (expires IS NULL OR expires > 0) ORDER BY banned_at DESC', {})
    TriggerClientEvent('ec_admin:client:updateBans', source, result or {})
end)

RegisterNetEvent('ec_admin:server:requestReports')
AddEventHandler('ec_admin:server:requestReports', function()
    local source = source
    if not HasAdminAccess(source, 'menu') then return end
    
    local result = MySQL.query.await('SELECT * FROM ec_admin_reports ORDER BY created_at DESC LIMIT 50', {})
    TriggerClientEvent('ec_admin:client:updateReports', source, result or {})
end)

-- ============================================================================
-- PLAYER ACTIONS
-- ============================================================================

RegisterNetEvent('ec_admin:server:teleportToPlayer')
AddEventHandler('ec_admin:server:teleportToPlayer', function(targetId)
    local source = source
    if not HasAdminAccess(source, 'teleport', targetId) then return end
    
    targetId = tonumber(targetId)
    if not targetId then return end
    
    local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
    TriggerClientEvent('ec_admin:client:teleportToCoords', source, targetCoords)
    
    LogAction(source, 'teleport_to', targetId, { coords = targetCoords })

    local webhook = EnsureWebhookHelper()
    if webhook then
        webhook('teleports', {
            action = 'teleport_to',
            admin = GetPlayerName(source),
            target = GetPlayerName(targetId),
            coords = targetCoords
        })
    end
end)

RegisterNetEvent('ec_admin:server:bringPlayer')
AddEventHandler('ec_admin:server:bringPlayer', function(targetId)
    local source = source
    if not HasAdminAccess(source, 'bring', targetId) then return end
    
    targetId = tonumber(targetId)
    if not targetId then return end
    
    local adminCoords = GetEntityCoords(GetPlayerPed(source))
    TriggerClientEvent('ec_admin:client:teleportToCoords', targetId, adminCoords)
    
    LogAction(source, 'bring_player', targetId, { coords = adminCoords })

    local webhook = EnsureWebhookHelper()
    if webhook then
        webhook('teleports', {
            action = 'bring_player',
            admin = GetPlayerName(source),
            target = GetPlayerName(targetId),
            coords = adminCoords
        })
    end
end)

RegisterNetEvent('ec_admin:server:kickPlayer')
AddEventHandler('ec_admin:server:kickPlayer', function(targetId, reason)
    local source = source
    if not HasAdminAccess(source, 'kick', targetId) then return end
    
    targetId = tonumber(targetId)
    if not targetId then return end
    
    local targetName = GetPlayerName(targetId)
    
    DropPlayer(targetId, '🚫 Kicked by Admin\nReason: ' .. reason .. '\nAdmin: ' .. GetPlayerName(source))
    
    LogAction(source, 'kick', targetId, { reason = reason })

    local webhook = EnsureWebhookHelper()
    if webhook then
        webhook('kicks', {
            title = 'Player Kicked',
            admin = GetPlayerName(source),
            target = targetName,
            reason = reason
        })
    end
end)

RegisterNetEvent('ec_admin:server:banPlayer')
AddEventHandler('ec_admin:server:banPlayer', function(targetId, reason, duration)
    local source = source
    if not HasAdminAccess(source, 'ban', targetId) then return end
    
    targetId = tonumber(targetId)
    duration = tonumber(duration) or 0
    if not targetId then return end
    
    local identifiers = GetIdentifiers(targetId)
    local targetName = GetPlayerName(targetId)
    local expires = duration > 0 and (os.time() + (duration * 3600)) or 0

    local _ = MySQL.query.await('INSERT INTO ec_admin_bans (name, identifier, reason, banned_by, banned_at, expires) VALUES (?, ?, ?, ?, NOW(), ?)', {
        targetName,
        identifiers.license,
        reason,
        GetPlayerName(source),
        expires
    })
    
    DropPlayer(targetId, '🚫 Banned\nReason: ' .. reason .. '\nDuration: ' .. (duration > 0 and duration .. ' hours' or 'Permanent'))
    
    LogAction(source, 'ban', targetId, { reason = reason, duration = duration })

    local webhook = EnsureWebhookHelper()
    if webhook then
        webhook('bans', {
            title = 'Player Banned',
            admin = GetPlayerName(source),
            target = targetName,
            reason = reason,
            duration = duration > 0 and duration .. ' hours' or 'Permanent'
        })
    end
end)

RegisterNetEvent('ec_admin:server:giveMoney')
AddEventHandler('ec_admin:server:giveMoney', function(targetId, moneyType, amount)
    local source = source
    if not HasAdminAccess(source, 'economy', targetId) then return end
    
    targetId = tonumber(targetId)
    amount = tonumber(amount)
    if not targetId or not amount then return end

    FrameworkBridge.AddMoney(targetId, moneyType, amount)

    TriggerClientEvent('ec_admin:client:notify', targetId, 'Admin gave you $' .. amount .. ' (' .. moneyType .. ')', 'success')
    
    LogAction(source, 'give_money', targetId, { type = moneyType, amount = amount })
end)

RegisterNetEvent('ec_admin:server:setJob')
AddEventHandler('ec_admin:server:setJob', function(targetId, job, grade)
    local source = source
    if not HasAdminAccess(source, 'economy', targetId) then return end

    if CheckRateLimit and not CheckRateLimit(source, 'ec_admin:setJob') then
        return
    end

    targetId = tonumber(targetId)
    grade = tonumber(grade) or 0
    if not targetId or not job then return end

    FrameworkBridge.SetJob(targetId, job, grade)
    
    TriggerClientEvent('ec_admin:client:notify', targetId, 'Admin set your job to ' .. job, 'success')
    
    LogAction(source, 'set_job', targetId, { job = job, grade = grade })
end)

RegisterNetEvent('ec_admin:server:spawnVehicle')
AddEventHandler('ec_admin:server:spawnVehicle', function(model)
    local source = source
    if not HasAdminAccess(source, 'vehicles') then return end

    if CheckRateLimit and not CheckRateLimit(source, 'ec_admin:spawnVehicle') then
        return
    end

    TriggerClientEvent('ec_admin:client:spawnVehicle', source, model)
    
    LogAction(source, 'spawn_vehicle', nil, { model = model })
end)

RegisterNetEvent('ec_admin:server:unbanPlayer')
AddEventHandler('ec_admin:server:unbanPlayer', function(banId)
    local source = source
    if not HasAdminAccess(source, 'ban') then return end
    
    banId = tonumber(banId)
    if not banId then return end
    
    MySQL.query('DELETE FROM ec_admin_bans WHERE id = ?', { banId }, function(result)
        TriggerClientEvent('ec_admin:client:notify', source, 'Player unbanned successfully', 'success')
        TriggerEvent('ec_admin:server:requestBans') -- Refresh ban list
    end)
    
    LogAction(source, 'unban', nil, { banId = banId })
end)

RegisterNetEvent('ec_admin:server:resolveReport')
AddEventHandler('ec_admin:server:resolveReport', function(reportId)
    local source = source
    if not HasAdminAccess(source, 'reports') then return end
    
    reportId = tonumber(reportId)
    if not reportId then return end
    
    MySQL.query('UPDATE ec_admin_reports SET status = ?, resolved_by = ?, resolved_at = NOW() WHERE id = ?', {
        'resolved',
        GetPlayerName(source),
        reportId
    }, function(result)
        TriggerClientEvent('ec_admin:client:notify', source, 'Report resolved', 'success')
        TriggerEvent('ec_admin:server:requestReports') -- Refresh reports
    end)
    
    LogAction(source, 'resolve_report', nil, { reportId = reportId })
end)

-- ============================================================================
-- BAN CHECK ON CONNECT
-- ============================================================================

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    
    Wait(100)
    deferrals.update('Checking ban status...')
    
    local identifiers = GetIdentifiers(source)
    
    MySQL.query('SELECT * FROM ec_admin_bans WHERE identifier = ? AND (expires IS NULL OR expires > NOW()) LIMIT 1', {
        identifiers.license
    }, function(result)
        if result and #result > 0 then
            local ban = result[1]
            local message = '🚫 You are banned from this server\n\n'
            message = message .. 'Reason: ' .. ban.reason .. '\n'
            message = message .. 'Banned by: ' .. ban.banned_by .. '\n'
            message = message .. 'Date: ' .. ban.banned_at .. '\n'
            if ban.expires then
                message = message .. 'Expires: ' .. ban.expires
            else
                message = message .. 'Duration: Permanent'
            end
            
            deferrals.done(message)
        else
            deferrals.done()
        end
    end)
end)

-- Admin actions module initialized