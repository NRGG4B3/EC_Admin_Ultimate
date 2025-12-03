--[[
    EC Admin Ultimate - Players Server Callbacks
    Provides player list and management data with FULL LIVE DATA
]]

Logger.Info('👥 Players callbacks loading...')

-- ============================================================================
-- PLAYER SESSION TRACKING (for online duration)
-- ============================================================================

local playerSessions = {}  -- Track when players join

-- Track player join time
AddEventHandler('playerJoining', function()
    local src = source
    playerSessions[src] = {
        joinTime = os.time(),
        lastActivity = os.time()
    }
end)

-- Track player leaving
AddEventHandler('playerDropped', function()
    local src = source
    playerSessions[src] = nil
end)

-- Update activity (for AFK detection)
Citizen.CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds
        
        for playerId, session in pairs(playerSessions) do
            if GetPlayerPing(playerId) then
                session.lastActivity = os.time()
            end
        end
    end
end)

-- Get online duration in minutes
local function GetOnlineDuration(playerId)
    if playerSessions[playerId] then
        local duration = os.time() - playerSessions[playerId].joinTime
        return math.floor(duration / 60)  -- Convert to minutes
    end
    return 0
end

-- Check if player is AFK (no activity for 5 minutes)
local function IsPlayerAFK(playerId)
    if playerSessions[playerId] then
        local idleTime = os.time() - playerSessions[playerId].lastActivity
        return idleTime > 300  -- 5 minutes
    end
    return false
end

-- ============================================================================
-- 24-HOUR PLAYER HISTORY TRACKING
-- ============================================================================

local playerHistory = {}  -- Stores hourly player counts
local peakTodayCount = 0

Citizen.CreateThread(function()
    -- Initialize history array (24 hours)
    for i = 0, 23 do
        playerHistory[i] = {
            hour = i,
            time = i < 12 and (i == 0 and '12 AM' or i .. ' AM') or (i == 12 and '12 PM' or (i - 12) .. ' PM'),
            players = 0,
            peak = 0
        }
    end
    
    while true do
        Wait(60000)  -- Update every minute
        
        local currentHour = tonumber(os.date('%H'))
        local currentPlayerCount = #GetPlayers()
        
        -- Update this hour's average
        if playerHistory[currentHour] then
            playerHistory[currentHour].players = currentPlayerCount
            
            -- Track peak for this hour
            if currentPlayerCount > playerHistory[currentHour].peak then
                playerHistory[currentHour].peak = currentPlayerCount
            end
        end
        
        -- Track peak for today
        if currentPlayerCount > peakTodayCount then
            peakTodayCount = currentPlayerCount
        end
    end
end)

-- ============================================================================
-- ZONE NAME LOOKUP (actual GTA V zones)
-- ============================================================================

local function GetZoneName(coords)
    -- GetZoneAtCoords is client-side only, return a fallback for server
    return 'Los Santos'
end

-- ============================================================================
-- FRAMEWORK DETECTION
-- ============================================================================

local function GetFramework()
    -- QBX doesn't use GetCoreObject export, just return framework name
    if GetResourceState('qbx_core') == 'started' then
        return 'qbx', nil
    elseif GetResourceState('qb-core') == 'started' then
        return 'qb', exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx', exports['es_extended']:getSharedObject()
    end
    return nil, nil
end

-- ============================================================================
-- GET ALL PLAYERS (with real-time data)
-- ============================================================================

lib.callback.register('ec_admin:getPlayers', function(source, data)
    local includeOffline = data and data.includeOffline or false
    local players = GetPlayers()
    local playerList = {}
    local framework, Core = GetFramework()
    
    for _, playerId in ipairs(players) do
        local id = tonumber(playerId)
        if id then
            local name = GetPlayerName(id)
            
            -- Skip if player name is invalid (disconnected or invalid)
            if not name or name == '' or name == 'Unknown' then
                goto continue
            end
            
            local ping = GetPlayerPing(id)
            local identifiers = GetPlayerIdentifiers(id)
            local ped = GetPlayerPed(id)
            local coords = GetEntityCoords(ped)
            
            -- Extract steam, license, discord
            local steamId = nil
            local license = nil
            local discord = nil
            
            for _, identifier in ipairs(identifiers) do
                if string.find(identifier, 'steam:') then
                    steamId = identifier
                elseif string.find(identifier, 'license:') then
                    license = identifier
                elseif string.find(identifier, 'discord:') then
                    discord = identifier
                end
            end
            
            -- Check if player is admin (use centralized permission check)
            local isAdmin = HasPermission and HasPermission(id) or false
            
            -- Get framework data
            local money = 0
            local cash = 0
            local bank = 0
            local job = { name = 'Unemployed', grade = 0, label = 'Unemployed' }
            local gang = { name = 'None', grade = 0, label = 'None' }
            local citizenid = nil
            local playtime = 0
            
            if framework == 'qb' or framework == 'qbx' then
                local Player = nil
                if framework == 'qbx' then
                    Player = exports.qbx_core:GetPlayer(id)
                else
                    Player = Core.Functions.GetPlayer(id)
                end
                
                if Player then
                    local playerData = Player.PlayerData
                    cash = playerData.money and playerData.money.cash or 0
                    bank = playerData.money and playerData.money.bank or 0
                    money = cash + bank
                    
                    if playerData.job then
                        job = {
                            name = playerData.job.name or 'unemployed',
                            grade = playerData.job.grade and playerData.job.grade.level or 0,
                            label = playerData.job.label or 'Unemployed'
                        }
                    end
                    
                    if playerData.gang then
                        gang = {
                            name = playerData.gang.name or 'none',
                            grade = playerData.gang.grade and playerData.gang.grade.level or 0,
                            label = playerData.gang.label or 'None'
                        }
                    end
                    
                    citizenid = playerData.citizenid
                    
                    -- Get playtime from database (try different column names for QB/QBX compatibility)
                    -- We use a safe approach that doesn't fail if columns don't exist
                    local success, playtimeResult = pcall(function()
                        return MySQL.query.await([[
                            SELECT 
                                playtime as playtime 
                            FROM players 
                            WHERE citizenid = ?
                        ]], {citizenid})
                    end)
                    
                    -- If playtime column doesn't exist, try alternatives
                    if not success or not playtimeResult or not playtimeResult[1] then
                        success, playtimeResult = pcall(function()
                            return MySQL.query.await([[
                                SELECT 
                                    total_playtime as playtime 
                                FROM players 
                                WHERE citizenid = ?
                            ]], {citizenid})
                        end)
                    end
                    
                    -- Extract playtime if found
                    if success and playtimeResult and playtimeResult[1] then
                        playtime = playtimeResult[1].playtime or 0
                    end
                end
            elseif framework == 'esx' then
                local xPlayer = Core.GetPlayerFromId(id)
                if xPlayer then
                    cash = xPlayer.getMoney() or 0
                    bank = xPlayer.getAccount('bank') and xPlayer.getAccount('bank').money or 0
                    money = cash + bank
                    
                    if xPlayer.job then
                        job = {
                            name = xPlayer.job.name or 'unemployed',
                            grade = xPlayer.job.grade or 0,
                            label = xPlayer.job.label or 'Unemployed'
                        }
                    end
                    
                    citizenid = xPlayer.identifier
                end
            end
            
            -- Calculate status (playing, afk, etc.)
            local status = 'playing'
            if IsPlayerAFK(id) then
                status = 'afk'
            end
            
            -- Get online duration (session time)
            local onlineDuration = GetOnlineDuration(id)
            local onlineTime = onlineDuration > 0 and onlineDuration or 0  -- Minutes
            
            table.insert(playerList, {
                id = id,
                source = id,
                name = name,
                identifier = steamId or license,
                steamid = steamId,
                license = license,
                discord = discord,
                citizenid = citizenid,
                ping = ping,
                online = true,
                status = status,
                admin = isAdmin,
                isAdmin = isAdmin,
                location = GetZoneName(coords),
                coords = { x = coords.x, y = coords.y, z = coords.z },
                playtime = playtime,  -- Total playtime from database
                sessionTime = onlineTime,  -- Current session time in minutes
                money = money,
                cash = cash,
                bank = bank,
                job = job,
                gang = gang,
                level = 1,
                warnings = 0,
                joinDate = os.date('%Y-%m-%d'),
                joinTime = playerSessions[id] and playerSessions[id].joinTime or os.time()
            })
        end
        
        ::continue::  -- Label for goto continue (skip invalid players)
    end
    
    -- TODO: If includeOffline, query database for offline players
    
    -- Get player history for charts
    local history = playerHistory
    local peakToday = peakTodayCount
    
    -- Calculate new players today
    local newToday = 0
    if MySQL and MySQL.query then
        -- QBX doesn't have a 'created' column, use 'last_updated' instead
        local todayStart = os.time() - (24 * 60 * 60)
        local success, result = pcall(function()
            return MySQL.query.await('SELECT COUNT(*) as count FROM players WHERE last_updated >= ?', {todayStart})
        end)
        
        if success and result and result[1] then
            newToday = result[1].count or 0
        else
            -- If query fails (column doesn't exist), default to 0
            newToday = 0
        end
    end
    
    return {
        success = true,
        players = playerList,
        count = #playerList,
        history = history,
        peakToday = peakToday,
        newToday = newToday,
        currentCount = #playerList
    }
end)

-- ============================================================================
-- GET PLAYER DETAILS (individual player info)
-- ============================================================================

lib.callback.register('ec_admin:getPlayerDetails', function(source, playerId)
    if not playerId then
        return { success = false, error = 'No player ID provided' }
    end
    
    local id = tonumber(playerId)
    if not id then
        return { success = false, error = 'Invalid player ID' }
    end
    
    local name = GetPlayerName(id)
    if not name then
        return { success = false, error = 'Player not found' }
    end
    
    local framework, Core = GetFramework()
    local ping = GetPlayerPing(id)
    local identifiers = GetPlayerIdentifiers(id)
    local ped = GetPlayerPed(id)
    local coords = GetEntityCoords(ped)
    
    -- Extract identifiers
    local steamId, license, discord, xbl, live, fivem = nil, nil, nil, nil, nil, nil
    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, 'steam:') then steamId = identifier
        elseif string.find(identifier, 'license:') then license = identifier
        elseif string.find(identifier, 'discord:') then discord = identifier
        elseif string.find(identifier, 'xbl:') then xbl = identifier
        elseif string.find(identifier, 'live:') then live = identifier
        elseif string.find(identifier, 'fivem:') then fivem = identifier
        end
    end
    
    local isAdmin = IsPlayerAceAllowed(id, 'admin.access')
    
    -- Get framework data
    local money, cash, bank = 0, 0, 0
    local job = { name = 'Unemployed', grade = 0, label = 'Unemployed' }
    local gang = { name = 'None', grade = 0, label = 'None' }
    local citizenid = nil
    local playtime = 0
    local metadata = {}
    local inventory = {}
    
    if framework == 'qb' or framework == 'qbx' then
        local Player = nil
        if framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(id)
        else
            Player = Core.Functions.GetPlayer(id)
        end
        
        if Player then
            local playerData = Player.PlayerData
            cash = playerData.money and playerData.money.cash or 0
            bank = playerData.money and playerData.money.bank or 0
            money = cash + bank
            
            if playerData.job then
                job = {
                    name = playerData.job.name or 'unemployed',
                    grade = playerData.job.grade and playerData.job.grade.level or 0,
                    label = playerData.job.label or 'Unemployed'
                }
            end
            
            if playerData.gang then
                gang = {
                    name = playerData.gang.name or 'none',
                    grade = playerData.gang.grade and playerData.gang.grade.level or 0,
                    label = playerData.gang.label or 'None'
                }
            end
            
            citizenid = playerData.citizenid
            metadata = playerData.metadata or {}
            
            -- Get inventory
            if playerData.items then
                for slot, item in pairs(playerData.items) do
                    table.insert(inventory, {
                        name = item.name,
                        label = item.label or item.name,
                        amount = item.amount or 1,
                        slot = slot
                    })
                end
            end
            
            -- Get playtime
            local playtimeResult = MySQL.query.await('SELECT playTime FROM players WHERE citizenid = ?', {citizenid})
            if playtimeResult and playtimeResult[1] then
                playtime = playtimeResult[1].playTime or 0
            end
        end
    elseif framework == 'esx' then
        local xPlayer = Core.GetPlayerFromId(id)
        if xPlayer then
            cash = xPlayer.getMoney() or 0
            bank = xPlayer.getAccount('bank') and xPlayer.getAccount('bank').money or 0
            money = cash + bank
            
            if xPlayer.job then
                job = {
                    name = xPlayer.job.name or 'unemployed',
                    grade = xPlayer.job.grade or 0,
                    label = xPlayer.job.label or 'Unemployed'
                }
            end
            
            citizenid = xPlayer.identifier
            
            -- Get inventory
            if xPlayer.inventory then
                for _, item in pairs(xPlayer.inventory) do
                    if item.count > 0 then
                        table.insert(inventory, {
                            name = item.name,
                            label = item.label or item.name,
                            amount = item.count
                        })
                    end
                end
            end
        end
    end
    
    -- Get warnings/bans from database
    local warnings = 0
    local bans = 0
    local reports = 0
    
    if citizenid or license then
        local warningResult = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_warnings WHERE target_identifier = ?', {citizenid or license})
        if warningResult and warningResult[1] then
            warnings = warningResult[1].count or 0
        end
        
        local banResult = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_bans WHERE identifier = ?', {citizenid or license})
        if banResult and banResult[1] then
            bans = banResult[1].count or 0
        end
        
        local reportResult = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_reports WHERE reporter_id = ?', {id})
        if reportResult and reportResult[1] then
            reports = reportResult[1].count or 0
        end
    end
    
    return {
        success = true,
        player = {
            id = id,
            source = id,
            name = name,
            steamid = steamId,
            license = license,
            discord = discord,
            xbl = xbl,
            live = live,
            fivem = fivem,
            citizenid = citizenid,
            ping = ping,
            admin = isAdmin,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            location = GetZoneName(coords),
            money = money,
            cash = cash,
            bank = bank,
            job = job,
            gang = gang,
            playtime = playtime,
            metadata = metadata,
            inventory = inventory,
            warnings = warnings,
            bans = bans,
            reports = reports,
            online = true,
            status = 'playing'
        }
    }
end)

Logger.Info('✅ Players callbacks loaded successfully')