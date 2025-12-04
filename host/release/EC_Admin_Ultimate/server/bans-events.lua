--[[
    EC Admin Ultimate - Bans & Warnings Server Events
    Server-side implementation for moderation actions
]]

Logger.Info('')

local function HasPermission(src, permission)
    return IsPlayerAceAllowed(src, 'ec_admin.' .. permission) or 
           IsPlayerAceAllowed(src, 'ec_admin.all')
end

RegisterNetEvent('ec:bans:getAll', function(data)
    local src = source
    
    if not HasPermission(src, 'moderation.view') then
        return
    end
    
    local bans = MySQL.Sync.fetchAll('SELECT * FROM ec_admin_bans ORDER BY banned_at DESC LIMIT 100', {})
    TriggerClientEvent('ec:bans:getAllResponse', src, bans)
end)

RegisterNetEvent('ec:bans:create', function(data)
    local src = source
    
    if not HasPermission(src, 'moderation.ban') then
        return
    end
    
    local targetId = data.playerId
    local reason = data.reason
    local duration = data.duration -- in hours, 0 = permanent
    local adminIdentifier = GetPlayerIdentifiers(src)[1]
    
    -- Get target identifier
    local targetIdentifiers = GetPlayerIdentifiers(targetId)
    local targetLicense = nil
    
    for _, id in pairs(targetIdentifiers) do
        if string.match(id, 'license:') then
            targetLicense = id
            break
        end
    end
    
    if not targetLicense then
        TriggerClientEvent('ec:notify', src, {
            title = 'Error',
            description = 'Could not find player license',
            type = 'error'
        })
        return
    end
    
    local expiresAt = nil
    if duration > 0 then
        expiresAt = os.time() + (duration * 3600)
    end
    
    MySQL.Async.insert(
        'INSERT INTO bans (license, reason, admin, expires_at, created_at) VALUES (?, ?, ?, ?, ?)',
        {targetLicense, reason, adminIdentifier, expiresAt, os.time()}
    )
    
    -- Kick the player
    DropPlayer(targetId, string.format('Banned: %s\nBanned by: Admin\nExpires: %s', 
        reason, 
        duration == 0 and 'Permanent' or os.date('%Y-%m-%d %H:%M', expiresAt)))
    
    Logger.Info(string.format('', src, targetId, reason))
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Player Banned',
        description = 'Player has been banned from the server',
        type = 'success'
    })
end)

RegisterNetEvent('ec:bans:revoke', function(data)
    local src = source
    
    if not HasPermission(src, 'moderation.unban') then
        return
    end
    
    local banId = data.banId
    
    MySQL.Async.execute('DELETE FROM ec_admin_bans WHERE id = ?', {banId})
    
    Logger.Info(string.format('', src, banId))
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Ban Revoked',
        description = 'Ban has been removed',
        type = 'success'
    })
end)

RegisterNetEvent('ec:warnings:getAll', function(data)
    local src = source
    
    if not HasPermission(src, 'moderation.view') then
        return
    end
    
    local warnings = MySQL.Sync.fetchAll('SELECT * FROM warnings ORDER BY created_at DESC LIMIT 100', {})
    TriggerClientEvent('ec:warnings:getAllResponse', src, warnings)
end)

RegisterNetEvent('ec:warnings:create', function(data)
    local src = source
    
    if not HasPermission(src, 'moderation.warn') then
        return
    end
    
    local targetId = data.playerId
    local reason = data.reason
    local adminIdentifier = GetPlayerIdentifiers(src)[1]
    
    local targetIdentifiers = GetPlayerIdentifiers(targetId)
    local targetLicense = nil
    
    for _, id in pairs(targetIdentifiers) do
        if string.match(id, 'license:') then
            targetLicense = id
            break
        end
    end
    
    MySQL.Async.insert(
        'INSERT INTO warnings (license, reason, admin, created_at) VALUES (?, ?, ?, ?)',
        {targetLicense, reason, adminIdentifier, os.time()}
    )
    
    -- Notify target player
    TriggerClientEvent('chat:addMessage', targetId, {
        color = {255, 0, 0},
        args = {'[WARNING]', reason}
    })
    
    Logger.Info(string.format('', src, targetId, reason))
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Warning Issued',
        description = 'Player has been warned',
        type = 'success'
    })
end)

RegisterNetEvent('ec:kicks:execute', function(data)
    local src = source
    
    if not HasPermission(src, 'moderation.kick') then
        return
    end
    
    local targetId = data.playerId
    local reason = data.reason
    
    DropPlayer(targetId, 'Kicked: ' .. reason)
    
    Logger.Info(string.format('', src, targetId, reason))
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Player Kicked',
        description = 'Player has been kicked from the server',
        type = 'success'
    })
end)

Logger.Info('')