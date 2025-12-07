-- EC Admin Ultimate - Server
-- NO RegisterNUICallback here - all NUI callbacks are in client/

-- Safety check: Ensure Config exists
if not Config then
    Logger.Error('Main ERROR: Config not loaded! Using defaults.')
    Config = { Framework = 'qbcore' }
end

local FrameworkBridge = ECFramework or {}
local FrameworkName = nil
local Framework = 'qbx'  -- Default framework (will be detected)
local SendWebhook = _G.SendHostWebhook

-- Initialize framework synchronously (framework detection happens early in startup)
local function InitializeFramework()
    if FrameworkBridge.GetFramework then
        Framework = FrameworkBridge.GetFramework() or 'qbx'
        FrameworkName = Framework
        Logger.Info('Framework initialized: ' .. Framework)
    else
        Logger.Warn('Framework bridge not available, using default: qbx')
        Framework = 'qbx'
    end
end

-- Call immediately (after FrameworkBridge is available)
InitializeFramework()

local function EnsureWebhookHelper()
    if SendWebhook then return SendWebhook end

    local exporter = exports and exports['ec_admin_ultimate']
    if exporter and exporter.SendWebhook then
        SendWebhook = exporter.SendWebhook
        return SendWebhook
    end

    return nil
end

-- Check Permission Event (re-enabled for proper permission checking)
RegisterNetEvent('ec_admin:checkPermission', function()
    local src = source
    local hasAccess = HasAdminAccess(src, 'menu')
    Logger.Debug(string.format('Permission check for player %d: %s', src, tostring(hasAccess)))
    
    -- If no access, show them helpful message
    if not hasAccess then
        Logger.Error('Player ' .. GetPlayerName(src) .. ' denied access')
        Logger.Warn('To grant access, add to server.cfg:')
        local identifiers = GetPlayerIdentifiers(src)
        for _, id in pairs(identifiers) do
            Logger.Info('  add_ace ' .. id .. ' ec_admin.all allow')
        end
        Logger.Warn('Or fill in Config.Owners in config.lua')
    end
    
    TriggerClientEvent('ec_admin:permissionResult', src, hasAccess)
end)

-- Get Players
RegisterNetEvent('ec_admin:requestPlayers', function()
    local src = source
    if not HasAdminAccess(src, 'menu') then return end
    
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local name = GetPlayerName(playerId)
        local identifiers = GetPlayerIdentifiers(playerId)
        
        table.insert(players, {
            id = playerId,
            name = name,
            identifiers = identifiers,
            ping = GetPlayerPing(playerId)
        })
    end
    
    TriggerClientEvent('ec_admin:updatePlayers', src, players)
end)

-- Kick Player
RegisterNetEvent('ec_admin:kickPlayer', function(targetId, reason)
    local src = source
    if not HasAdminAccess(src, 'kick', targetId) then return end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:kickPlayer') then
        return
    end

    DropPlayer(targetId, reason or 'Kicked by admin')
    
    local webhook = EnsureWebhookHelper()
    if webhook then
        webhook('kicks', {
            title = 'Player Kicked',
            admin = GetPlayerName(src),
            target = GetPlayerName(targetId),
            reason = reason
        })
    end
    
    TriggerClientEvent('ec_admin:notification', src, 'Player kicked successfully', 'success')
end)

-- Ban Player (supports offline identifiers)
RegisterNetEvent('ec_admin:banPlayer', function(data)
    local src = source
    if not HasAdminAccess(src, 'ban') then return end

    -- Rate limit protection
    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:banPlayer') then
        return
    end

    -- Normalize incoming payload
    if type(data) ~= 'table' then
        data = {
            identifier = data,
            reason = 'Banned by admin',
            duration = 0
        }
    end

    -- Ban reason
    local reason = (data.reason and tostring(data.reason) ~= '' and tostring(data.reason)) or 'Banned by admin'

    -- Duration → Convert hours → UNIX timestamp
    local durationHours = tonumber(data.duration) or 0
    local expires = durationHours > 0 and (os.time() + (durationHours * 3600)) or 0

    -- Extract identifiers safely
    local identifiers = {
        license  = data.license or data.identifier or nil,
        fivem    = data.fivem or nil,
        discord  = data.discord or nil,
        ip       = data.ip or nil
    }

    -- Validate primary identifier
    if not identifiers.license then
        TriggerClientEvent('ec_admin:notification', src, 'Ban failed: No valid license identifier found.', 'error')
        return
    end

    -- Prevent MySQL inserts with "license:" missing prefix
    if not identifiers.license:find("license:") then
        identifiers.license = "license:" .. identifiers.license
    end

    -- Insert ban entry
    local insertResult = MySQL.insert.await(
        [[INSERT INTO ec_admin_bans 
        (identifier, license, fivem, discord, ip, reason, admin_name, banned_at, expires)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)]],
        {
            identifiers.license,           -- identifier
            identifiers.license,           -- license
            identifiers.fivem,             -- fivem
            identifiers.discord,           -- discord
            identifiers.ip,                -- ip
            reason,                        -- reason
            GetPlayerName(src),            -- admin_name
            os.time(),                     -- banned_at
            expires                        -- expires
        }
    )

    if not insertResult then
        TriggerClientEvent('ec_admin:notification', src, 'Database error while banning player.', 'error')
        return
    end

    -- Disconnect online players matching this ban
    for _, playerId in ipairs(GetPlayers()) do
        local playerIdentifiers = GetPlayerIdentifiers(playerId)
        if playerIdentifiers then
            for _, id in pairs(playerIdentifiers) do
                if id == identifiers.license then
                    -- Safe DropPlayer (prevent crash if already disconnected)
                    if GetPlayerName(playerId) then
                        DropPlayer(playerId, 'You have been banned: ' .. reason)
                    end
                    break
                end
            end
        end
    end

    -- Webhook logging
    local webhook = EnsureWebhookHelper and EnsureWebhookHelper()
    if webhook then
        webhook('bans', {
            title = 'Player Banned',
            admin = GetPlayerName(src),
            target = identifiers.license or 'Unknown',
            reason = reason,
            duration = durationHours > 0 and (durationHours .. ' hours') or 'Permanent'
        })
    end

    -- Confirmation to admin
    TriggerClientEvent('ec_admin:notification', src, 'Player banned successfully', 'success')
end)


-- Bring Player
RegisterNetEvent('ec_admin:bringPlayer', function(targetId)
    local src = source
    if not HasAdminAccess(src, 'bring', targetId) then return end
    
    -- Validate target exists
    local valid, validId, err = ValidatePlayerExists(targetId)
    if not valid then
        TriggerClientEvent('ec_admin:notify', src, { type = 'error', message = err })
        return
    end
    targetId = validId
    
    -- Rate limit
    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:bringPlayer') then
        return
    end
    
    local adminPed = GetPlayerPed(src)
    local coords = GetEntityCoords(adminPed)

    TriggerClientEvent('ec_admin:teleportToCoords', targetId, coords)

    local webhook = EnsureWebhookHelper()
    if webhook then
        webhook('teleports', {
            action = 'bring_player',
            admin = GetPlayerName(src),
            target = GetPlayerName(targetId),
            coords = coords
        })
    end
end)

-- Give Item
RegisterNetEvent('ec_admin:giveItem', function(targetId, item, amount)
    local src = source
    if not HasAdminAccess(src, 'giveitem', targetId) then return end
    
    if Framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(tonumber(targetId))
        if Player then
            Player.Functions.AddItem(item, amount)
            TriggerClientEvent('ec_admin:notification', src, 'Item given successfully', 'success')
        end
    elseif Framework == 'qb-core' then
        local Player = QBCore.Functions.GetPlayer(tonumber(targetId))
        if Player then
            Player.Functions.AddItem(item, amount)
            TriggerClientEvent('ec_admin:notification', src, 'Item given successfully', 'success')
        end
    elseif Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(tonumber(targetId))
        if xPlayer then
            xPlayer.addInventoryItem(item, amount)
            TriggerClientEvent('ec_admin:notification', src, 'Item given successfully', 'success')
        end
    end
end)

-- Set Job
RegisterNetEvent('ec_admin:setJob', function(targetId, job, grade)
    local src = source
    if not HasAdminAccess(src, 'economy', targetId) then return end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:setJob') then
        return
    end

    if Framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(tonumber(targetId))
        if Player then
            Player.Functions.SetJob(job, grade or 0)
            TriggerClientEvent('ec_admin:notification', src, 'Job set successfully', 'success')
        end
    elseif Framework == 'qb-core' then
        local Player = QBCore.Functions.GetPlayer(tonumber(targetId))
        if Player then
            Player.Functions.SetJob(job, grade or 0)
            TriggerClientEvent('ec_admin:notification', src, 'Job set successfully', 'success')
        end
    elseif Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(tonumber(targetId))
        if xPlayer then
            xPlayer.setJob(job, grade or 0)
            TriggerClientEvent('ec_admin:notification', src, 'Job set successfully', 'success')
        end
    end
end)

-- Give Money
RegisterNetEvent('ec_admin:giveMoney', function(targetId, moneyType, amount)
    local src = source
    if not HasAdminAccess(src, 'economy', targetId) then return end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:giveMoney') then
        return
    end

    if Framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(tonumber(targetId))
        if Player then
            Player.Functions.AddMoney(moneyType, amount)
            TriggerClientEvent('ec_admin:notification', src, 'Money given successfully', 'success')
        end
    elseif Framework == 'qb-core' then
        local Player = QBCore.Functions.GetPlayer(tonumber(targetId))
        if Player then
            Player.Functions.AddMoney(moneyType, amount)
            TriggerClientEvent('ec_admin:notification', src, 'Money given successfully', 'success')
        end
    elseif Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(tonumber(targetId))
        if xPlayer then
            xPlayer.addAccountMoney(moneyType, amount)
            TriggerClientEvent('ec_admin:notification', src, 'Money given successfully', 'success')
        end
    end
end)

-- Delete Vehicle
RegisterNetEvent('ec_admin:deleteVehicle', function(netId)
    local src = source
    if not HasAdminAccess(src, 'deletevehicle') then return end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:deleteVehicle') then
        return
    end

    if not netId or type(netId) ~= "number" then
        TriggerClientEvent('ec_admin:notification', src, 'Invalid vehicle network ID', 'error')
        return
    end
    
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
        TriggerClientEvent('ec_admin:notification', src, 'Vehicle deleted', 'success')
    else
        TriggerClientEvent('ec_admin:notification', src, 'Vehicle not found', 'error')
    end
end)

-- Revive Player
RegisterNetEvent('ec_admin:revivePlayer', function(targetId)
    local src = source
    if not HasAdminAccess(src, 'revive', targetId) then return end
    
    if Framework == 'qbx' or Framework == 'qb-core' then
        TriggerClientEvent('hospital:client:Revive', targetId)
    elseif Framework == 'esx' then
        TriggerClientEvent('esx_ambulancejob:revive', targetId)
    end
    
    TriggerClientEvent('ec_admin:notification', src, 'Player revived', 'success')
end)

-- Freeze Player
RegisterNetEvent('ec_admin:freezePlayer', function(targetId, freeze)
    local src = source
    if not HasAdminAccess(src, 'freeze', targetId) then return end
    
    -- Validate target exists
    local valid, validId, err = ValidatePlayerExists(targetId)
    if not valid then
        TriggerClientEvent('ec_admin:notify', src, { type = 'error', message = err })
        return
    end
    targetId = validId
    
    -- Prevent freezing yourself
    if targetId == src then
        TriggerClientEvent('ec_admin:notify', src, { type = 'error', message = 'You cannot freeze yourself!' })
        Logger.Warn(string.format('Player %s tried to freeze themselves', GetPlayerName(src)))
        return
    end
    
    -- Prevent freezing other admins
    if HasAdminAccess(targetId, 'menu') then
        TriggerClientEvent('ec_admin:notify', src, { type = 'error', message = 'You cannot freeze other administrators!' })
        Logger.Warn(string.format('Player %s tried to freeze admin %s', GetPlayerName(src), GetPlayerName(targetId)))
        return
    end
    
    -- Rate limit
    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:freezePlayer') then
        return
    end
    
    TriggerClientEvent('ec_admin:freezeLocal', targetId, freeze)
    TriggerClientEvent('ec_admin:notification', src, string.format('Player %s %s', GetPlayerName(targetId), freeze and 'frozen' or 'unfrozen'), 'success')
end)

-- Spectate Player
RegisterNetEvent('ec_admin:spectatePlayer', function(targetId)
    local src = source
    if not HasAdminAccess(src, 'spectate', targetId) then return end
    
    -- Prevent spectating yourself
    if tonumber(targetId) == src then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'You cannot spectate yourself!'
        })
        Logger.Warn(string.format('Player %s tried to spectate themselves', GetPlayerName(src)))
        return
    end
    
    -- Rate limit
    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:spectatePlayer') then
        return
    end
    
    TriggerClientEvent('ec_admin:startSpectating', src, targetId)
end)

-- Server Announcement
RegisterNetEvent('ec_admin:announceServer', function(message, announcementType)
    local src = source
    if not HasAdminAccess(src, 'announce') then return end
    
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div class="chat-message advert"><b>ADMIN ANNOUNCEMENT</b>: {0}</div>',
        args = { message }
    })
end)

-- Get Server Metrics
RegisterNetEvent('ec_admin:requestMetrics', function()
    local src = source
    if not HasAdminAccess(src, 'menu') then return end
    
    local metrics = {
        players = {
            online = #GetPlayers(),
            max = GetConvarInt('sv_maxclients', 32)
        },
        server = {
            uptime = os.time() - GetConvarInt('sv_startTime', 0),
            version = GetConvar('version', 'unknown')
        }
    }
    
    TriggerClientEvent('ec_admin:updateMetrics', src, metrics)
end)

-- Get Bans
RegisterNetEvent('ec_admin:requestBans', function()
    local src = source
    if not HasAdminAccess(src, 'ban') then return end

    local bans = MySQL.query.await('SELECT * FROM ec_admin_bans WHERE expires = 0 OR expires > ? ORDER BY banned_at DESC', {
        os.time()
    })

    TriggerClientEvent('ec_admin:updateBans', src, bans or {})
end)

-- Unban Player
RegisterNetEvent('ec_admin:unbanPlayer', function(banId)
    local src = source
    if not HasAdminAccess(src, 'ban') then return end

    local result = MySQL.query.await('DELETE FROM ec_admin_bans WHERE id = ?', { banId })
    if result and result.affectedRows and result.affectedRows > 0 then
        TriggerClientEvent('ec_admin:notification', src, 'Player unbanned successfully', 'success')
    end
end)

-- Get Reports
RegisterNetEvent('ec_admin:requestReports', function()
    local src = source
    if not HasAdminAccess(src, 'reports') then return end
    
    local reports = MySQL.query.await('SELECT * FROM ec_admin_reports WHERE status = ? ORDER BY created_at DESC', {
        'pending'
    })

    TriggerClientEvent('ec_admin:updateReports', src, reports or {})
end)

-- ==========================================
-- STARTUP BANNER
-- ==========================================
CreateThread(function()
    Wait(3000) -- Wait for all initialization
    Logger.System('')
    Logger.System('===============================================')
    Logger.System('  EC ADMIN ULTIMATE v1.0.0')
    Logger.System('===============================================')
    Logger.Info('  Framework: ' .. (Framework or 'Unknown'))
    Logger.Info('  Mode: ' .. (IsHostMode() and 'HOST' or 'CUSTOMER'))
    Logger.Info('  Permissions: Unified (Owners / ACE / EC Perms / Discord)')
    Logger.System('===============================================')
    Logger.Success('  Server initialized successfully!')
    Logger.System('===============================================')
    Logger.Info('  Commands:')
    Logger.Info('    /hud or F2 - Open Admin Menu')
    Logger.Info('    /quickactions or F3 - Quick Actions')
    Logger.Info('    /forceclose - Force close if stuck')
    Logger.System('===============================================')
    Logger.System('')
end)

-- Check if we're in host mode
function IsHostMode()
    -- Explicit config override (used internally)
    if Config and type(Config) == 'table' and Config.HostMode then
        return true
    end

    local resourceName = GetCurrentResourceName()

    -- Host builds ship with a marker file
    if LoadResourceFile(resourceName, 'host/.hostmarker') then
        return true
    end

    -- Safe fallback: check for host assets
    if LoadResourceFile(resourceName, 'host/config.lua') or LoadResourceFile(resourceName, 'host/api/host_server.lua') then
        return true
    end

    return false
end

-- ==========================================
-- CLEANUP ON PLAYER DISCONNECT
-- ==========================================
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    -- Stop anyone spectating this player
    TriggerClientEvent('ec_admin:stopSpectatingTarget', -1, source)
    
    -- Clean up any state tracking for this player
    -- (frozen state, godmode, noclip handled client-side)
    
    Logger.Debug(string.format('Player %d disconnected, cleaned up state (%s)', source, reason))
end)

-- ==========================================
-- CLEANUP ON RESOURCE STOP
-- ==========================================
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    Logger.Info('Resource stopping - cleaning up all states...', '🧹')
    
    -- Close all open menus
    TriggerClientEvent('ec_admin:forceCloseAll', -1)
    
    -- Stop all spectating
    TriggerClientEvent('ec_admin:cleanup', -1)
    
    -- Unfreeze all players
    -- (handled client-side via cleanup event)
    
    Logger.Success('Cleanup complete')
end)

-- ==========================================
-- EXPORTS
-- ==========================================
exports('GetFramework', function()
    return Framework
end)
exports('IsHostMode', IsHostMode)
