--[[
    EC Admin Ultimate - Server Event Handlers
    
    Complete server-side handlers for all NUI callbacks
    Handles ALL admin actions with:
    - Permission checks
    - Database logging
    - Live data updates
    - Framework integration
    - Error handling
]]--

Logger.Info('🔧 Loading Server Event Handlers...')

--[[ ==================== PLAYER ACTIONS ==================== ]]--

-- Kick Player
RegisterServerEvent('ec-admin:kickPlayer')
AddEventHandler('ec-admin:kickPlayer', function(targetId, reason)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'kick') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to kick players')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Log action
    LogAction(source, 'kick', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId),
        reason = reason
    })
    
    -- Kick player
    DropPlayer(targetId, '🔨 Kicked by Admin\nReason: ' .. reason)
    
    -- Notify admin
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Player kicked: ' .. GetPlayerName(targetId))
    
    -- Refresh player list
    RefreshPlayerList()
end)

-- Ban Player
RegisterServerEvent('ec-admin:banPlayer')
AddEventHandler('ec-admin:banPlayer', function(targetId, reason, duration)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'ban') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to ban players')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Get identifiers
    local identifiers = GetPlayerIdentifiers(targetId)
    local license = nil
    for _, id in pairs(identifiers) do
        if string.match(id, 'license:') then
            license = id
            break
        end
    end
    
    if not license then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Could not find player license')
        return
    end
    
    -- Calculate ban expiry
    local expiresAt = duration > 0 and (os.time() + (duration * 3600)) or nil
    
    -- Insert ban into database
    if InsertRecord then
        InsertRecord('ec_bans', {
            license = license,
            player_name = GetPlayerName(targetId),
            banned_by = GetPlayerIdentifiers(source)[1],
            admin_name = GetPlayerName(source),
            reason = reason,
            expires_at = expiresAt,
            created_at = os.time()
        })
    end
    
    -- Log action
    LogAction(source, 'ban', {
        target = license,
        targetName = GetPlayerName(targetId),
        reason = reason,
        duration = duration
    })
    
    -- Kick player
    DropPlayer(targetId, '🔨 Banned from Server\nReason: ' .. reason .. '\nDuration: ' .. (duration > 0 and duration .. ' hours' or 'Permanent'))
    
    -- Notify admin
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Player banned: ' .. GetPlayerName(targetId))
    
    -- Refresh lists
    RefreshPlayerList()
    RefreshBanList()
end)

-- Warn Player
RegisterServerEvent('ec-admin:warnPlayer')
AddEventHandler('ec-admin:warnPlayer', function(targetId, reason)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'warn') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to warn players')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Get identifiers
    local license = GetPlayerIdentifiers(targetId)[1]
    
    -- Insert warning into database
    if InsertRecord then
        InsertRecord('ec_warnings', {
            license = license,
            player_name = GetPlayerName(targetId),
            warned_by = GetPlayerIdentifiers(source)[1],
            admin_name = GetPlayerName(source),
            reason = reason,
            created_at = os.time()
        })
    end
    
    -- Log action
    LogAction(source, 'warn', {
        target = license,
        targetName = GetPlayerName(targetId),
        reason = reason
    })
    
    -- Notify target
    TriggerClientEvent('ec-admin:notify', targetId, 'warning', '⚠️ Warning from Admin\n' .. reason)
    
    -- Notify admin
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Warning issued to: ' .. GetPlayerName(targetId))
    
    -- Refresh warning list
    RefreshWarningList()
end)

-- Teleport Player
RegisterServerEvent('ec-admin:teleportPlayer')
AddEventHandler('ec-admin:teleportPlayer', function(targetId, coords)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'teleport') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to teleport players')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Teleport
    local ped = GetPlayerPed(targetId)
    SetEntityCoords(ped, coords.x, coords.y, coords.z)
    
    -- Log action
    LogAction(source, 'teleport', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId),
        coords = coords
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Teleported player: ' .. GetPlayerName(targetId))
    TriggerClientEvent('ec-admin:notify', targetId, 'info', 'You were teleported by an admin')
end)

-- Teleport To Player
RegisterServerEvent('ec-admin:teleportToPlayer')
AddEventHandler('ec-admin:teleportToPlayer', function(targetId)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'teleport') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to teleport')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Get target coords
    local targetPed = GetPlayerPed(targetId)
    local targetCoords = GetEntityCoords(targetPed)
    
    -- Teleport admin
    local adminPed = GetPlayerPed(source)
    SetEntityCoords(adminPed, targetCoords.x, targetCoords.y, targetCoords.z)
    
    -- Log action
    LogAction(source, 'teleport_to', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId)
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Teleported to: ' .. GetPlayerName(targetId))
end)

-- Bring Player
RegisterServerEvent('ec-admin:bringPlayer')
AddEventHandler('ec-admin:bringPlayer', function(targetId)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'teleport') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to bring players')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Get admin coords
    local adminPed = GetPlayerPed(source)
    local adminCoords = GetEntityCoords(adminPed)
    
    -- Teleport target to admin
    local targetPed = GetPlayerPed(targetId)
    SetEntityCoords(targetPed, adminCoords.x + 2.0, adminCoords.y, adminCoords.z)
    
    -- Log action
    LogAction(source, 'bring', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId)
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Brought player: ' .. GetPlayerName(targetId))
    TriggerClientEvent('ec-admin:notify', targetId, 'info', 'You were brought to an admin')
end)

-- Freeze Player
RegisterServerEvent('ec-admin:freezePlayer')
AddEventHandler('ec-admin:freezePlayer', function(targetId, frozen)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'freeze') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to freeze players')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Freeze/unfreeze
    local targetPed = GetPlayerPed(targetId)
    FreezeEntityPosition(targetPed, frozen)
    
    -- Log action
    LogAction(source, frozen and 'freeze' or 'unfreeze', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId)
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', (frozen and 'Frozen' or 'Unfrozen') .. ' player: ' .. GetPlayerName(targetId))
    TriggerClientEvent('ec-admin:notify', targetId, 'info', 'You were ' .. (frozen and 'frozen' or 'unfrozen') .. ' by an admin')
end)

-- Set Player Health
RegisterServerEvent('ec-admin:setPlayerHealth')
AddEventHandler('ec-admin:setPlayerHealth', function(targetId, health)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'heal') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to set health')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Set health
    local targetPed = GetPlayerPed(targetId)
    SetEntityHealth(targetPed, health)
    
    -- Log action
    LogAction(source, 'set_health', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId),
        health = health
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Set health for: ' .. GetPlayerName(targetId))
end)

-- Set Player Armor
RegisterServerEvent('ec-admin:setPlayerArmor')
AddEventHandler('ec-admin:setPlayerArmor', function(targetId, armor)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'heal') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to set armor')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Set armor
    local targetPed = GetPlayerPed(targetId)
    SetPedArmour(targetPed, armor)
    
    -- Log action
    LogAction(source, 'set_armor', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId),
        armor = armor
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Set armor for: ' .. GetPlayerName(targetId))
end)

-- Revive Player
RegisterServerEvent('ec-admin:revivePlayer')
AddEventHandler('ec-admin:revivePlayer', function(targetId)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'revive') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to revive players')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Framework-specific revive
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        TriggerClientEvent('hospital:client:Revive', targetId)
    elseif Config.Framework == 'esx' then
        TriggerClientEvent('esx_ambulancejob:revive', targetId)
    else
        -- Generic revive
        local targetPed = GetPlayerPed(targetId)
        SetEntityHealth(targetPed, 200)
    end
    
    -- Log action
    LogAction(source, 'revive', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId)
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Revived player: ' .. GetPlayerName(targetId))
    TriggerClientEvent('ec-admin:notify', targetId, 'success', 'You were revived by an admin')
end)

-- Spectate Player
RegisterServerEvent('ec-admin:spectatePlayer')
AddEventHandler('ec-admin:spectatePlayer', function(targetId)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'spectate') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to spectate players')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Trigger client spectate
    TriggerClientEvent('ec-admin:startSpectate', source, targetId)
    
    -- Log action
    LogAction(source, 'spectate', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId)
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'info', 'Spectating: ' .. GetPlayerName(targetId))
end)

--[[ ==================== ECONOMY ACTIONS ==================== ]]--

-- Give Money
RegisterServerEvent('ec-admin:giveMoney')
AddEventHandler('ec-admin:giveMoney', function(targetId, amount, moneyType)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'manage_money') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to manage money')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Framework-specific money handling
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        local Player = GetFrameworkObject().Functions.GetPlayer(targetId)
        if Player then
            Player.Functions.AddMoney(moneyType or 'cash', amount)
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = GetFrameworkObject().GetPlayerFromId(targetId)
        if xPlayer then
            if moneyType == 'bank' then
                xPlayer.addAccountMoney('bank', amount)
            else
                xPlayer.addMoney(amount)
            end
        end
    end
    
    -- Log action
    LogAction(source, 'give_money', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId),
        amount = amount,
        type = moneyType
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Gave $' .. amount .. ' to ' .. GetPlayerName(targetId))
    TriggerClientEvent('ec-admin:notify', targetId, 'success', 'You received $' .. amount .. ' from an admin')
end)

-- Remove Money
RegisterServerEvent('ec-admin:removeMoney')
AddEventHandler('ec-admin:removeMoney', function(targetId, amount, moneyType)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'manage_money') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to manage money')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Framework-specific money handling
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        local Player = GetFrameworkObject().Functions.GetPlayer(targetId)
        if Player then
            Player.Functions.RemoveMoney(moneyType or 'cash', amount)
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = GetFrameworkObject().GetPlayerFromId(targetId)
        if xPlayer then
            if moneyType == 'bank' then
                xPlayer.removeAccountMoney('bank', amount)
            else
                xPlayer.removeMoney(amount)
            end
        end
    end
    
    -- Log action
    LogAction(source, 'remove_money', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId),
        amount = amount,
        type = moneyType
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Removed $' .. amount .. ' from ' .. GetPlayerName(targetId))
end)

--[[ ==================== INVENTORY ACTIONS ==================== ]]--

-- Give Item
RegisterServerEvent('ec-admin:giveItem')
AddEventHandler('ec-admin:giveItem', function(targetId, item, amount)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'manage_inventory') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to manage inventory')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Framework-specific inventory handling
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        local Player = GetFrameworkObject().Functions.GetPlayer(targetId)
        if Player then
            Player.Functions.AddItem(item, amount)
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = GetFrameworkObject().GetPlayerFromId(targetId)
        if xPlayer then
            xPlayer.addInventoryItem(item, amount)
        end
    end
    
    -- Log action
    LogAction(source, 'give_item', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId),
        item = item,
        amount = amount
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Gave ' .. amount .. 'x ' .. item .. ' to ' .. GetPlayerName(targetId))
    TriggerClientEvent('ec-admin:notify', targetId, 'success', 'You received ' .. amount .. 'x ' .. item .. ' from an admin')
end)

-- Remove Item
RegisterServerEvent('ec-admin:removeItem')
AddEventHandler('ec-admin:removeItem', function(targetId, item, amount)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'manage_inventory') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to manage inventory')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Framework-specific inventory handling
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        local Player = GetFrameworkObject().Functions.GetPlayer(targetId)
        if Player then
            Player.Functions.RemoveItem(item, amount)
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = GetFrameworkObject().GetPlayerFromId(targetId)
        if xPlayer then
            xPlayer.removeInventoryItem(item, amount)
        end
    end
    
    -- Log action
    LogAction(source, 'remove_item', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId),
        item = item,
        amount = amount
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Removed ' .. amount .. 'x ' .. item .. ' from ' .. GetPlayerName(targetId))
end)

--[[ ==================== JOB/GANG ACTIONS ==================== ]]--

-- Set Job
RegisterServerEvent('ec-admin:setJob')
AddEventHandler('ec-admin:setJob', function(targetId, job, grade)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'manage_jobs') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to manage jobs')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Framework-specific job setting
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        local Player = GetFrameworkObject().Functions.GetPlayer(targetId)
        if Player then
            Player.Functions.SetJob(job, grade or 0)
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = GetFrameworkObject().GetPlayerFromId(targetId)
        if xPlayer then
            xPlayer.setJob(job, grade or 0)
        end
    end
    
    -- Log action
    LogAction(source, 'set_job', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId),
        job = job,
        grade = grade
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Set job for ' .. GetPlayerName(targetId) .. ': ' .. job)
    TriggerClientEvent('ec-admin:notify', targetId, 'info', 'Your job was changed to: ' .. job)
end)

-- Set Gang
RegisterServerEvent('ec-admin:setGang')
AddEventHandler('ec-admin:setGang', function(targetId, gang, grade)
    local source = source
    
    -- Permission check
    if not HasAdminPermission(source, 'manage_gangs') then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'No permission to manage gangs')
        return
    end
    
    -- Validate target
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('ec-admin:notify', source, 'error', 'Invalid player')
        return
    end
    
    -- Framework-specific gang setting (QB/QBX only)
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        local Player = GetFrameworkObject().Functions.GetPlayer(targetId)
        if Player then
            Player.Functions.SetGang(gang, grade or 0)
        end
    end
    
    -- Log action
    LogAction(source, 'set_gang', {
        target = GetPlayerIdentifiers(targetId)[1],
        targetName = GetPlayerName(targetId),
        gang = gang,
        grade = grade
    })
    
    -- Notify
    TriggerClientEvent('ec-admin:notify', source, 'success', 'Set gang for ' .. GetPlayerName(targetId) .. ': ' .. gang)
    TriggerClientEvent('ec-admin:notify', targetId, 'info', 'Your gang was changed to: ' .. gang)
end)

Logger.Info('✅ Server Event Handlers loaded (Part 1/3)')
