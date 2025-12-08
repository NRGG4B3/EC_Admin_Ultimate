--[[
    EC Admin Ultimate - Player Database UI Backend
    Server-side logic for player management and database operations
    
    Handles:
    - getPlayers: Get online/offline players with history and statistics
    - getBans: Get banned players list
    - spectatePlayer: Start spectating a player
    - freezePlayer: Freeze/unfreeze a player
    - revivePlayer: Revive a player
    - healPlayer: Heal a player
    - kickPlayers: Bulk kick players
    - teleportPlayers: Bulk teleport players
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Player Database] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Player Database] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local playerCache = {}
local CACHE_TTL = 5 -- Cache for 5 seconds

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

-- Helper: Get player identifiers
local function getPlayerIdentifiers(source)
    local identifiers = {
        steam = '',
        license = '',
        discord = '',
        fivem = '',
        ip = ''
    }
    
    local ids = GetPlayerIdentifiers(source)
    if not ids then return identifiers end
    
    for _, id in ipairs(ids) do
        if string.find(id, 'steam:') then
            identifiers.steam = id
        elseif string.find(id, 'license:') then
            identifiers.license = id
        elseif string.find(id, 'discord:') then
            identifiers.discord = id
        elseif string.find(id, 'fivem:') then
            identifiers.fivem = id
        elseif string.find(id, 'ip:') then
            identifiers.ip = id
        end
    end
    
    return identifiers
end

-- Helper: Get primary identifier (license preferred, fallback to first)
local function getPrimaryIdentifier(source)
    local ids = GetPlayerIdentifiers(source)
    if not ids then return nil end
    
    -- Try license first
    for _, id in ipairs(ids) do
        if string.find(id, 'license:') then
            return id
        end
    end
    
    -- Fallback to first identifier
    return ids[1]
end

-- Helper: Get player ping
local function getPlayerPing(source)
    return GetPlayerPing(source) or 0
end

-- Helper: Get player location/zone (simplified)
local function getPlayerLocation(source)
    -- In production, integrate with zone detection system
    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 then
        local coords = GetEntityCoords(ped)
        -- Simple zone detection based on coordinates
        if coords.z < 0 then
            return "Ocean"
        elseif coords.x > 0 and coords.y > 0 then
            return "Los Santos"
        elseif coords.x < 0 and coords.y > 0 then
            return "Blaine County"
        else
            return "Unknown"
        end
    end
    return "Unknown"
end

-- Helper: Is player admin
local function isPlayerAdmin(source)
    return hasPermission(source, 'admin.access') or ECFramework.IsAdminGroup(source)
end

-- Helper: Get player playtime from database
local function getPlayerPlaytime(identifier)
    if not identifier then return 0 end
    
    local result = MySQL.query.await('SELECT total_playtime FROM ec_player_stats WHERE identifier = ?', {identifier})
    if result and result[1] then
        return result[1].total_playtime or 0
    end
    
    -- Fallback: query sessions
    local sessionResult = MySQL.query.await('SELECT SUM(playtime_minutes) as total FROM ec_player_sessions WHERE identifier = ?', {identifier})
    if sessionResult and sessionResult[1] and sessionResult[1].total then
        return sessionResult[1].total or 0
    end
    
    return 0
end

-- Helper: Get player warnings count
local function getPlayerWarningsCount(identifier)
    if not identifier then return 0 end
    
    local result = MySQL.query.await('SELECT COUNT(*) as count FROM ec_player_warnings WHERE identifier = ?', {identifier})
    if result and result[1] then
        return result[1].count or 0
    end
    
    return 0
end

-- Helper: Ensure player exists in database
local function ensurePlayerExists(identifier, name)
    if not identifier then return nil end
    
    -- Check if exists
    local existing = MySQL.query.await('SELECT id FROM ec_players WHERE identifier = ?', {identifier})
    
    if existing and existing[1] then
        -- Update last_seen and name
        MySQL.update.await('UPDATE ec_players SET name = ?, last_seen = ? WHERE identifier = ?', {
            name, getCurrentTimestamp(), identifier
        })
        return existing[1].id
    else
        -- Insert new player
        local result = MySQL.insert.await('INSERT INTO ec_players (identifier, name, join_date, last_seen) VALUES (?, ?, ?, ?)', {
            identifier, name, getCurrentTimestamp(), getCurrentTimestamp()
        })
        
        -- Create stats entry
        if result then
            MySQL.insert.await('INSERT INTO ec_player_stats (identifier) VALUES (?)', {identifier})
        end
        
        return result
    end
end

-- Helper: Get player info from framework
local function getPlayerFrameworkInfo(source)
    local info = {
        job = 'unemployed',
        gang = 'none',
        money = 0,
        bank = 0,
        level = 0
    }
    
    local framework = getFramework()
    local player = getPlayerObject(source)
    
    if (framework == 'qb' or framework == 'qbx') and player and player.PlayerData then
        local jobData = player.PlayerData.job or {}
        info.job = jobData.name or info.job
        
        local gangData = player.PlayerData.gang or {}
        info.gang = gangData.name or info.gang
        
        local money = player.PlayerData.money or {}
        info.money = money.cash or info.money
        info.bank = money.bank or info.bank
        
        -- Level might be in metadata or calculated
        info.level = player.PlayerData.metadata and player.PlayerData.metadata.level or 0
    elseif framework == 'esx' and player then
        local jobData = player.job or {}
        info.job = jobData.name or info.job
        
        -- ESX doesn't have gangs by default, but might have groups
        info.gang = 'none'
        
        -- Get money from accounts
        local accounts = player.getAccounts and player:getAccounts() or player.accounts
        if accounts then
            for _, account in pairs(accounts) do
                if account.name == 'money' then
                    info.money = account.money or info.money
                elseif account.name == 'bank' then
                    info.bank = account.money or info.bank
                end
            end
        end
        
        info.level = player.getLevel and player:getLevel() or 0
    end
    
    return info
end

-- Helper: Get online players data
local function getOnlinePlayersData()
    local players = {}
    local playerList = GetPlayers()
    
    for _, playerId in ipairs(playerList) do
        local source = tonumber(playerId)
        if source then
            local name = GetPlayerName(source) or 'Unknown'
            local identifiers = getPlayerIdentifiers(source)
            local primaryId = getPrimaryIdentifier(source)
            
            -- Ensure player exists in database
            if primaryId then
                ensurePlayerExists(primaryId, name)
            end
            
            local frameworkInfo = getPlayerFrameworkInfo(source)
            local playtime = primaryId and getPlayerPlaytime(primaryId) or 0
            local warnings = primaryId and getPlayerWarningsCount(primaryId) or 0
            
            table.insert(players, {
                source = source,
                id = source,
                name = name,
                identifier = primaryId or '',
                steamid = identifiers.steam,
                ping = getPlayerPing(source),
                playtime = playtime,
                status = 'playing', -- Could detect AFK
                admin = isPlayerAdmin(source),
                location = getPlayerLocation(source),
                online = true,
                money = frameworkInfo.money,
                bank = frameworkInfo.bank,
                job = frameworkInfo.job,
                gang = frameworkInfo.gang,
                level = frameworkInfo.level,
                warnings = warnings
            })
        end
    end
    
    return players
end

-- Helper: Get offline players data
local function getOfflinePlayersData(limit, offset)
    limit = limit or 100
    offset = offset or 0
    
    local result = MySQL.query.await([[
        SELECT 
            p.identifier,
            p.name,
            p.steamid,
            p.playtime,
            p.last_seen,
            p.join_date,
            ps.warnings_count,
            ps.money_cash,
            ps.job_name,
            ps.level
        FROM ec_players p
        LEFT JOIN ec_player_stats ps ON p.identifier = ps.identifier
        WHERE p.last_seen IS NOT NULL
        ORDER BY p.last_seen DESC
        LIMIT ? OFFSET ?
    ]], {limit, offset})
    
    if not result then return {} end
    
    local players = {}
    for _, row in ipairs(result) do
        table.insert(players, {
            id = row.identifier, -- Use identifier as ID for offline players
            name = row.name,
            identifier = row.identifier,
            steamid = row.steamid,
            playtime = row.playtime or 0,
            status = 'offline',
            admin = false, -- Would need to check admin table
            lastSeen = row.last_seen and os.date('%Y-%m-%d %H:%M:%S', row.last_seen) or nil,
            joinDate = row.join_date and os.date('%Y-%m-%d', row.join_date) or nil,
            online = false,
            money = row.money_cash or 0,
            job = row.job_name or 'unemployed',
            level = row.level or 0,
            warnings = row.warnings_count or 0
        })
    end
    
    return players
end

-- Helper: Calculate player history (24 hours)
local function calculatePlayerHistory()
    local history = {}
    local currentTime = getCurrentTimestamp()
    
    -- Get history from database for last 24 hours
    local cutoffTime = currentTime - (24 * 60 * 60)
    local result = MySQL.query.await([[
        SELECT 
            hour,
            player_count,
            peak_count,
            timestamp
        FROM ec_player_history
        WHERE timestamp >= ?
        ORDER BY timestamp ASC
    ]], {cutoffTime})
    
    if result and #result > 0 then
        for _, row in ipairs(result) do
            local time = os.date("*t", row.timestamp)
            local hour = time.hour
            local ampm = hour >= 12 and "PM" or "AM"
            hour = hour > 12 and (hour - 12) or (hour == 0 and 12 or hour)
            local timeLabel = string.format("%d %s", hour, ampm)
            
            table.insert(history, {
                hour = row.hour,
                time = timeLabel,
                players = row.player_count or 0,
                peak = row.peak_count or row.player_count or 0
            })
        end
    else
        -- Generate empty history if no data
        local now = os.date("*t", currentTime)
        for i = 23, 0, -1 do
            local hour = (now.hour - i) % 24
            local ampm = hour >= 12 and "PM" or "AM"
            local displayHour = hour > 12 and (hour - 12) or (hour == 0 and 12 or hour)
            local timeLabel = string.format("%d %s", displayHour, ampm)
            
            table.insert(history, {
                hour = hour,
                time = timeLabel,
                players = 0,
                peak = 0
            })
        end
    end
    
    return history
end

-- Helper: Get peak today
local function getPeakToday()
    local today = os.date("%Y-%m-%d")
    local result = MySQL.query.await([[
        SELECT MAX(peak_count) as peak
        FROM ec_player_history
        WHERE DATE(FROM_UNIXTIME(timestamp)) = ?
    ]], {today})
    
    if result and result[1] and result[1].peak then
        return result[1].peak
    end
    
    -- Fallback: current player count
    return #GetPlayers()
end

-- Helper: Get new players today
local function getNewPlayersToday()
    local todayStart = os.time(os.date("*t"))
    local result = MySQL.query.await('SELECT COUNT(*) as count FROM ec_players WHERE join_date >= ?', {todayStart})
    
    if result and result[1] then
        return result[1].count or 0
    end
    
    return 0
end

-- Helper: Update player history (hourly)
local function updatePlayerHistory()
    local currentTime = getCurrentTimestamp()
    local timeInfo = os.date("*t", currentTime)
    local hour = timeInfo.hour
    local today = os.date("%Y-%m-%d")
    local playerCount = #GetPlayers()
    
    -- Get or create history entry for this hour
    local existing = MySQL.query.await([[
        SELECT id, peak_count FROM ec_player_history
        WHERE hour = ? AND date = ?
    ]], {hour, today})
    
    if existing and existing[1] then
        -- Update existing entry
        local peak = math.max(existing[1].peak_count or 0, playerCount)
        MySQL.update.await([[
            UPDATE ec_player_history
            SET player_count = ?, peak_count = ?, timestamp = ?
            WHERE id = ?
        ]], {playerCount, peak, currentTime, existing[1].id})
    else
        -- Insert new entry
        MySQL.insert.await([[
            INSERT INTO ec_player_history (hour, date, player_count, peak_count, timestamp)
            VALUES (?, ?, ?, ?, ?)
        ]], {hour, today, playerCount, playerCount, currentTime})
    end
end

-- Helper: Get players data (shared logic)
local function getPlayersData(includeOffline)
    -- Check cache
    local cacheKey = includeOffline and 'all' or 'online'
    if playerCache[cacheKey] and (getCurrentTimestamp() - playerCache[cacheKey].timestamp) < CACHE_TTL then
        return playerCache[cacheKey].data
    end
    
    local onlinePlayers = getOnlinePlayersData()
    local allPlayers = onlinePlayers
    
    -- Add offline players if requested
    if includeOffline then
        local offlinePlayers = getOfflinePlayersData(100, 0)
        for _, player in ipairs(offlinePlayers) do
            table.insert(allPlayers, player)
        end
    end
    
    -- Calculate history
    local history = calculatePlayerHistory()
    
    -- Get statistics
    local peakToday = getPeakToday()
    local newToday = getNewPlayersToday()
    
    -- Build response
    local response = {
        success = true,
        players = allPlayers,
        history = history,
        peakToday = peakToday,
        newToday = newToday
    }
    
    -- Cache response
    playerCache[cacheKey] = {
        data = response,
        timestamp = getCurrentTimestamp()
    }
    
    return response
end

-- RegisterNUICallback: Get players (direct fetch from UI)
RegisterNUICallback('getPlayers', function(data, cb)
    local includeOffline = data.includeOffline or false
    local response = getPlayersData(includeOffline)
    cb(response)
end)

-- Callback: Get players (via fetchNui/client bridge)
lib.callback.register('ec_admin:getPlayers', function(source, data)
    local includeOffline = data.includeOffline or false
    return getPlayersData(includeOffline)
end)

-- Helper: Get bans data (shared logic)
local function getBansData()
    -- Query bans table (adjust table name to match your ban system)
    local result = MySQL.query.await([[
        SELECT 
            id,
            identifier,
            player_name,
            reason,
            banned_by,
            created_at,
            expires_at,
            permanent
        FROM ec_bans
        WHERE active = 1
        ORDER BY created_at DESC
        LIMIT 100
    ]], {})
    
    if not result then
        return { success = true, bans = {} }
    end
    
    local bans = {}
    for _, row in ipairs(result) do
        local duration = nil
        local expiresAt = nil
        
        if not row.permanent and row.expires_at then
            expiresAt = os.date('%Y-%m-%dT%H:%M:%SZ', row.expires_at)
            local days = math.ceil((row.expires_at - getCurrentTimestamp()) / 86400)
            duration = days > 0 and (days .. ' days') or 'Expired'
        end
        
        table.insert(bans, {
            id = row.id,
            playerName = row.player_name or 'Unknown',
            identifier = row.identifier,
            reason = row.reason or 'No reason provided',
            bannedBy = row.banned_by or 'System',
            createdAt = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at),
            permanent = row.permanent == 1 or row.permanent == true,
            duration = duration,
            expiresAt = expiresAt
        })
    end
    
    return { success = true, bans = bans }
end

-- RegisterNUICallback: Get bans (direct fetch from UI)
RegisterNUICallback('getBans', function(data, cb)
    local response = getBansData()
    cb(response)
end)

-- Callback: Get bans (via fetchNui/client bridge)
lib.callback.register('ec_admin:getBans', function(source, data)
    return getBansData()
end)

-- Callback: Spectate player
lib.callback.register('ec_admin:spectatePlayer', function(source, data)
    local playerId = tonumber(data.playerId)
    if not playerId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(playerId) then
        return { success = false, error = 'Player not found or offline' }
    end
    
    -- Trigger client event for source to spectate target
    TriggerClientEvent('ec_admin:spectatePlayer', source, playerId)
    
    return { success = true, message = 'Spectating player ' .. playerId }
end)

-- Callback: Freeze player
lib.callback.register('ec_admin:freezePlayer', function(source, data)
    local playerId = tonumber(data.playerId)
    local freeze = data.freeze ~= false -- Default to true
    
    if not playerId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(playerId) then
        return { success = false, error = 'Player not found or offline' }
    end
    
    TriggerClientEvent('ec_admin:freezePlayer', playerId, freeze)
    
    return { success = true, message = string.format('Player %d %s', playerId, freeze and 'frozen' or 'unfrozen') }
end)

-- Callback: Revive player
lib.callback.register('ec_admin:revivePlayer', function(source, data)
    local playerId = tonumber(data.playerId)
    if not playerId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(playerId) then
        return { success = false, error = 'Player not found or offline' }
    end
    
    local framework = getFramework()
    local player = getPlayerObject(playerId)
    
    if (framework == 'qb' or framework == 'qbx') and player and player.Functions then
        player.Functions.SetJob('unemployed', 0)
        TriggerClientEvent('hospital:client:Revive', playerId)
    elseif framework == 'esx' then
        TriggerClientEvent('esx_ambulancejob:revive', playerId)
    else
        TriggerClientEvent('ec_admin:revivePlayer', playerId)
    end
    
    return { success = true, message = 'Player ' .. playerId .. ' revived' }
end)

-- Callback: Heal player
lib.callback.register('ec_admin:healPlayer', function(source, data)
    local playerId = tonumber(data.playerId)
    if not playerId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(playerId) then
        return { success = false, error = 'Player not found or offline' }
    end
    
    TriggerClientEvent('ec_admin:healPlayer', playerId)
    
    return { success = true, message = 'Player ' .. playerId .. ' healed' }
end)

-- Callback: Kick players (bulk)
lib.callback.register('ec_admin:kickPlayers', function(source, data)
    local playerIds = data.playerIds or {}
    local reason = data.reason or 'No reason provided'
    
    if not playerIds or #playerIds == 0 then
        return { success = false, error = 'No players selected' }
    end
    
    local kicked = 0
    local errors = {}
    
    for _, playerId in ipairs(playerIds) do
        local id = tonumber(playerId)
        if id and GetPlayerPing(id) then
            local playerName = GetPlayerName(id) or 'Unknown'
            DropPlayer(id, string.format('Kicked: %s', reason))
            kicked = kicked + 1
        else
            table.insert(errors, 'Player ' .. tostring(playerId) .. ' not found')
        end
    end
    
    if kicked > 0 then
        return { success = true, message = string.format('Kicked %d player(s)', kicked), count = kicked }
    else
        return { success = false, error = 'No players were kicked', errors = errors }
    end
end)

-- Callback: Teleport players (bulk)
lib.callback.register('ec_admin:teleportPlayers', function(source, data)
    local playerIds = data.playerIds or {}
    local coords = data.coords or {}
    
    if not playerIds or #playerIds == 0 then
        return { success = false, error = 'No players selected' }
    end
    
    if not coords.x or not coords.y or not coords.z then
        return { success = false, error = 'Invalid coordinates' }
    end
    
    local teleported = 0
    local errors = {}
    
    for _, playerId in ipairs(playerIds) do
        local id = tonumber(playerId)
        if id and GetPlayerPing(id) then
            TriggerClientEvent('ec_admin:teleportPlayer', id, coords.x, coords.y, coords.z)
            teleported = teleported + 1
        else
            table.insert(errors, 'Player ' .. tostring(playerId) .. ' not found')
        end
    end
    
    if teleported > 0 then
        return { success = true, message = string.format('Teleported %d player(s)', teleported), count = teleported }
    else
        return { success = false, error = 'No players were teleported', errors = errors }
    end
end)

-- Auto-update player history every hour
CreateThread(function()
    Wait(60000) -- Wait 1 minute on startup
    
    while true do
        updatePlayerHistory()
        Wait(3600000) -- Wait 1 hour
    end
end)

-- Cleanup cache periodically
CreateThread(function()
    while true do
        Wait(10000) -- Check every 10 seconds
        
        local currentTime = getCurrentTimestamp()
        for key, cached in pairs(playerCache) do
            if (currentTime - cached.timestamp) >= CACHE_TTL then
                playerCache[key] = nil
            end
        end
    end
end)

print("^2[Player Database]^7 UI Backend loaded successfully^0")

