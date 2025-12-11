--[[
    EC Admin Ultimate - Player Profile UI Backend
    Server-side logic for player profile management
    
    Handles:
    - getPlayerProfile: Get complete player profile data
    - getPlayerInventory: Get player inventory items
    - getPlayerVehicles: Get player vehicles
    - getPlayerProperties: Get player properties
    - getPlayerTransactions: Get transaction history
    - getPlayerActivity: Get activity history
    - getPlayerWarnings: Get warnings list
    - getPlayerBans: Get bans list
    - getPlayerNotes: Get moderation notes
    - getPlayerPerformance: Get performance chart data
    - getPlayerMoneyChart: Get money chart data
    - warnPlayer: Issue warning to player
    - banPlayer: Ban player
    - kickPlayer: Kick player
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Player Profile] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Player Profile] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local profileCache = {}
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
    
    -- Fallback to first identifier
    return identifiers[1]
end

-- Helper: Get player source from identifier (if online)
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

-- Helper: Get player identifier from player ID
local function getPlayerIdentifierFromId(playerId)
    local source = tonumber(playerId)
    if not source or not GetPlayerPing(source) then
        return nil
    end
    return getPlayerIdentifierFromSource(source)
end

-- Helper: Get player identifiers object
local function getPlayerIdentifiers(source)
    local identifiers = {
        steam = '',
        license = '',
        discord = '',
        fivem = '',
        ip = '',
        hwid = ''
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
            identifiers.ip = string.gsub(id, 'ip:', '')
        end
    end
    
    return identifiers
end

-- Helper: Get player framework data
local function getPlayerFrameworkData(source)
    local data = {
        job = 'unemployed',
        jobGrade = '0',
        gang = 'none',
        money = { cash = 0, bank = 0, crypto = 0, blackMoney = 0 },
        health = 100,
        armor = 0,
        location = 'Unknown',
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        hunger = 100,
        thirst = 100,
        stress = 0,
        isDead = false
    }
    
    local framework = getFramework()
    local player = getPlayerObject(source)
    
    if (framework == 'qb' or framework == 'qbx') and player and player.PlayerData then
        local jobData = player.PlayerData.job or {}
        data.job = jobData.name or data.job
        data.jobGrade = tostring(jobData.grade?.level or jobData.grade or 0)
        
        local gangData = player.PlayerData.gang or {}
        data.gang = gangData.name or data.gang
        
        local money = player.PlayerData.money or {}
        data.money.cash = money.cash or 0
        data.money.bank = money.bank or 0
        data.money.crypto = money.crypto or 0
        data.money.blackMoney = money.black_money or 0
        
        local metadata = player.PlayerData.metadata or {}
        data.hunger = metadata.hunger or 100
        data.thirst = metadata.thirst or 100
        data.stress = metadata.stress or 0
        data.isDead = metadata.isdead or false
        
        -- Get health/armor from ped
        local ped = GetPlayerPed(source)
        if ped and ped ~= 0 then
            data.health = GetEntityHealth(ped)
            data.armor = GetPedArmour(ped)
            local coords = GetEntityCoords(ped)
            data.coords = { x = coords.x, y = coords.y, z = coords.z }
        end
    elseif framework == 'esx' and player then
        local jobData = player.job or {}
        data.job = jobData.name or data.job
        data.jobGrade = tostring(jobData.grade or 0)
        
        data.gang = 'none' -- ESX doesn't have gangs by default
        
        -- Get money from accounts
        local accounts = player.getAccounts and player:getAccounts() or player.accounts
        if accounts then
            for _, account in pairs(accounts) do
                if account.name == 'money' then
                    data.money.cash = account.money or 0
                elseif account.name == 'bank' then
                    data.money.bank = account.money or 0
                end
            end
        end
        
        -- Get health/armor from ped
        local ped = GetPlayerPed(source)
        if ped and ped ~= 0 then
            data.health = GetEntityHealth(ped)
            data.armor = GetPedArmour(ped)
            local coords = GetEntityCoords(ped)
            data.coords = { x = coords.x, y = coords.y, z = coords.z }
        end
    end
    
    return data
end

-- Helper: Get player database data
local function getPlayerDatabaseData(identifier)
    local result = MySQL.query.await('SELECT * FROM ec_player_profiles WHERE identifier = ?', {identifier})
    
    if result and result[1] then
        local row = result[1]
        local metadata = {}
        if row.metadata then
            metadata = json.decode(row.metadata) or {}
        end
        
        return {
            citizenId = row.citizen_id or '',
            phoneNumber = row.phone_number or '',
            nationality = row.nationality or '',
            birthDate = row.birth_date or '',
            gender = row.gender or '',
            metadata = metadata
        }
    end
    
    return {
        citizenId = '',
        phoneNumber = '',
        nationality = '',
        birthDate = '',
        gender = '',
        metadata = {}
    }
end

-- Helper: Get player location name
local function getPlayerLocationName(coords)
    -- Simplified location detection
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

-- Helper: Log player activity
local function logPlayerActivity(identifier, action, actionType, details, adminId)
    MySQL.insert.await([[
        INSERT INTO ec_player_activity (identifier, action, type, details, admin_id, timestamp)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {identifier, action, actionType, details, adminId, getCurrentTimestamp()})
end

-- Helper: Calculate duration from string
local function calculateDuration(durationString)
    if not durationString or durationString == 'permanent' then
        return nil -- Permanent ban
    end
    
    local days = 0
    if string.find(durationString, 'd') then
        days = tonumber(string.match(durationString, '(%d+)d')) or 0
    elseif string.find(durationString, 'w') then
        days = (tonumber(string.match(durationString, '(%d+)w')) or 0) * 7
    elseif string.find(durationString, 'm') then
        days = (tonumber(string.match(durationString, '(%d+)m')) or 0) * 30
    end
    
    if days > 0 then
        return getCurrentTimestamp() + (days * 86400)
    end
    
    return nil
end

-- Callback: Get player profile
lib.callback.register('ec_admin:getPlayerProfile', function(source, data)
    local playerId = tonumber(data.playerId)
    local identifier = data.identifier
    
    -- Get identifier if we have playerId
    if playerId and not identifier then
        identifier = getPlayerIdentifierFromId(playerId)
    end
    
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    -- Check cache
    if profileCache[identifier] and (getCurrentTimestamp() - profileCache[identifier].timestamp) < CACHE_TTL then
        return { success = true, profile = profileCache[identifier].data }
    end
    
    -- Get player source if online
    local playerSource = getPlayerSourceByIdentifier(identifier)
    local isOnline = playerSource ~= nil
    
    -- Get identifiers
    local identifiers = {}
    if isOnline then
        identifiers = getPlayerIdentifiers(playerSource)
    else
        -- Get from database
        local playerData = MySQL.query.await('SELECT * FROM ec_players WHERE identifier = ?', {identifier})
        if playerData and playerData[1] then
            identifiers.steam = playerData[1].steamid or ''
            identifiers.license = identifier
        end
    end
    
    -- Get framework data (if online)
    local frameworkData = {}
    if isOnline then
        frameworkData = getPlayerFrameworkData(playerSource)
    else
        -- Get from database stats
        local stats = MySQL.query.await('SELECT * FROM ec_player_stats WHERE identifier = ?', {identifier})
        if stats and stats[1] then
            frameworkData = {
                job = stats[1].job_name or 'unemployed',
                jobGrade = tostring(stats[1].job_grade or 0),
                gang = stats[1].gang_name or 'none',
                money = {
                    cash = tonumber(stats[1].money_cash or 0),
                    bank = tonumber(stats[1].money_bank or 0),
                    crypto = 0,
                    blackMoney = 0
                },
                health = 100,
                armor = 0,
                location = 'Offline',
                coords = { x = 0.0, y = 0.0, z = 0.0 },
                hunger = 100,
                thirst = 100,
                stress = 0,
                isDead = false
            }
        end
    end
    
    -- Get database data
    local dbData = getPlayerDatabaseData(identifier)
    
    -- Get player name
    local playerName = 'Unknown'
    if isOnline then
        playerName = GetPlayerName(playerSource) or 'Unknown'
    else
        local playerData = MySQL.query.await('SELECT name FROM ec_players WHERE identifier = ?', {identifier})
        if playerData and playerData[1] then
            playerName = playerData[1].name
        end
    end
    
    -- Build profile
    local profile = {
        id = playerSource or 0,
        name = playerName,
        status = isOnline and 'online' or 'offline',
        location = frameworkData.location or getPlayerLocationName(frameworkData.coords),
        coords = frameworkData.coords,
        health = frameworkData.health,
        armor = frameworkData.armor,
        job = frameworkData.job,
        jobGrade = frameworkData.jobGrade,
        gang = frameworkData.gang,
        money = frameworkData.money,
        steamId = identifiers.steam,
        license = identifiers.license,
        discord = identifiers.discord,
        discordId = string.gsub(identifiers.discord, 'discord:', ''),
        ip = identifiers.ip,
        hwid = identifiers.hwid,
        phoneNumber = dbData.phoneNumber,
        nationality = dbData.nationality,
        birthDate = dbData.birthDate,
        gender = dbData.gender,
        hunger = frameworkData.hunger,
        thirst = frameworkData.thirst,
        stress = frameworkData.stress,
        isDead = frameworkData.isDead,
        citizenId = dbData.citizenId,
        metadata = dbData.metadata
    }
    
    -- Cache profile
    profileCache[identifier] = {
        data = profile,
        timestamp = getCurrentTimestamp()
    }
    
    return { success = true, profile = profile }
end)

-- Callback: Get player inventory
lib.callback.register('ec_admin:getPlayerInventory', function(source, data)
    local playerId = tonumber(data.playerId)
    local identifier = data.identifier
    
    if playerId and not identifier then
        identifier = getPlayerIdentifierFromId(playerId)
    end
    
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    local playerSource = getPlayerSourceByIdentifier(identifier)
    local framework = getFramework()
    local inventory = {}
    
    if playerSource then
        -- Get from framework (online player)
        if (framework == 'qb' or framework == 'qbx') then
            local player = getPlayerObject(playerSource)
            if player and player.PlayerData and player.PlayerData.items then
                local items = player.PlayerData.items
                for slot, item in pairs(items) do
                    if item and item.name then
                        table.insert(inventory, {
                            id = slot,
                            name = item.name,
                            quantity = item.amount or item.count or 1,
                            type = item.type or 'item',
                            weight = item.weight or 0.1,
                            useable = item.useable or false,
                            description = item.description or '',
                            slot = slot,
                            metadata = item.info or item.metadata or {}
                        })
                    end
                end
            end
        elseif framework == 'esx' then
            local player = getPlayerObject(playerSource)
            if player and player.getInventory then
                local items = player:getInventory()
                if items then
                    for _, item in pairs(items) do
                        table.insert(inventory, {
                            id = item.slot or #inventory + 1,
                            name = item.name,
                            quantity = item.count or 1,
                            type = item.type or 'item',
                            weight = item.weight or 0.1,
                            useable = item.useable or false,
                            description = item.label or '',
                            slot = item.slot or #inventory + 1,
                            metadata = item.metadata or {}
                        })
                    end
                end
            end
        end
    else
        -- Get from database (offline player) - would need framework-specific inventory table
        -- This is a placeholder - adjust based on your inventory system
    end
    
    return { success = true, inventory = inventory }
end)

-- Callback: Get player vehicles
lib.callback.register('ec_admin:getPlayerVehicles', function(source, data)
    local playerId = tonumber(data.playerId)
    local identifier = data.identifier
    
    if playerId and not identifier then
        identifier = getPlayerIdentifierFromId(playerId)
    end
    
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    local framework = getFramework()
    local vehicles = {}
    
    -- Query vehicles table (framework-specific)
    local query = ''
    if framework == 'qb' or framework == 'qbx' then
        query = 'SELECT * FROM player_vehicles WHERE citizenid = ? OR owner = ?'
    elseif framework == 'esx' then
        query = 'SELECT * FROM owned_vehicles WHERE owner = ?'
    else
        return { success = true, vehicles = {} }
    end
    
    local result = MySQL.query.await(query, {identifier, identifier})
    
    if result then
        for _, row in ipairs(result) do
            local mods = {}
            if row.mods then
                mods = json.decode(row.mods) or {}
            end
            
            local color = { primary = 'Black', secondary = 'Black' }
            if row.color1 and row.color2 then
                color = { primary = tostring(row.color1), secondary = tostring(row.color2) }
            end
            
            table.insert(vehicles, {
                id = row.id or row.vehicle,
                model = row.vehicle or row.model or 'unknown',
                plate = row.plate or '',
                location = row.garage or 'Unknown',
                stored = (row.state == 'out' or row.stored == 0) and false or true,
                mileage = tonumber(row.mileage or row.km) or 0,
                fuel = tonumber(row.fuel) or 100,
                engine = tonumber(row.engine) or 1000,
                body = tonumber(row.body) or 1000,
                value = tonumber(row.price) or 0,
                impounded = (row.state == 'impounded' or row.impounded == 1),
                impoundReason = row.impound_reason or nil,
                mods = mods,
                color = color,
                owner = row.owner or row.citizenid or identifier
            })
        end
    end
    
    return { success = true, vehicles = vehicles }
end)

-- Callback: Get player properties
lib.callback.register('ec_admin:getPlayerProperties', function(source, data)
    local playerId = tonumber(data.playerId)
    local identifier = data.identifier
    
    if playerId and not identifier then
        identifier = getPlayerIdentifierFromId(playerId)
    end
    
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    -- Query properties table (adjust table name based on your property system)
    local result = MySQL.query.await([[
        SELECT * FROM properties WHERE owner = ? OR identifier = ?
    ]], {identifier, identifier})
    
    local properties = {}
    
    if result then
        for _, row in ipairs(result) do
            local keys = {}
            if row.keys then
                keys = json.decode(row.keys) or {}
            end
            
            table.insert(properties, {
                id = row.id,
                type = row.type or 'house',
                address = row.address or row.label or 'Unknown',
                owned = (row.owner == identifier),
                garage = tonumber(row.garage) or 0,
                price = tonumber(row.price) or 0,
                keys = keys,
                locked = (row.locked == 1 or row.locked == true),
                hasStash = (row.stash == 1 or row.stash == true),
                hasWardrobe = (row.wardrobe == 1 or row.wardrobe == true),
                tier = row.tier or 'standard',
                coords = {
                    x = tonumber(row.coords_x or row.x) or 0.0,
                    y = tonumber(row.coords_y or row.y) or 0.0,
                    z = tonumber(row.coords_z or row.z) or 0.0
                }
            })
        end
    end
    
    return { success = true, properties = properties }
end)

-- Callback: Get player transactions
lib.callback.register('ec_admin:getPlayerTransactions', function(source, data)
    local playerId = tonumber(data.playerId)
    local identifier = data.identifier
    
    if playerId and not identifier then
        identifier = getPlayerIdentifierFromId(playerId)
    end
    
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    local result = MySQL.query.await([[
        SELECT * FROM ec_player_transactions
        WHERE identifier = ?
        ORDER BY timestamp DESC
        LIMIT 100
    ]], {identifier})
    
    local transactions = {}
    
    if result then
        for _, row in ipairs(result) do
            table.insert(transactions, {
                id = row.id,
                type = row.type,
                amount = tonumber(row.amount),
                balance = tonumber(row.balance_after),
                from = row.from_account or '',
                to = row.to_account or '',
                timestamp = os.date('%Y-%m-%dT%H:%M:%SZ', row.timestamp),
                details = row.details or ''
            })
        end
    end
    
    return { success = true, transactions = transactions }
end)

-- Callback: Get player activity
lib.callback.register('ec_admin:getPlayerActivity', function(source, data)
    local playerId = tonumber(data.playerId)
    local identifier = data.identifier
    
    if playerId and not identifier then
        identifier = getPlayerIdentifierFromId(playerId)
    end
    
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    local result = MySQL.query.await([[
        SELECT * FROM ec_player_activity
        WHERE identifier = ?
        ORDER BY timestamp DESC
        LIMIT 100
    ]], {identifier})
    
    local activities = {}
    
    if result then
        for _, row in ipairs(result) do
            table.insert(activities, {
                id = row.id,
                action = row.action,
                timestamp = os.date('%Y-%m-%dT%H:%M:%SZ', row.timestamp),
                type = row.type or '',
                details = row.details or '',
                admin = row.admin_id or nil
            })
        end
    end
    
    return { success = true, activity = activities }
end)

-- Callback: Get player warnings
lib.callback.register('ec_admin:getPlayerWarnings', function(source, data)
    local playerId = tonumber(data.playerId)
    local identifier = data.identifier
    
    if playerId and not identifier then
        identifier = getPlayerIdentifierFromId(playerId)
    end
    
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    -- Query warnings table (adjust table name based on your moderation system)
    local result = MySQL.query.await([[
        SELECT * FROM ec_player_warnings
        WHERE identifier = ?
        ORDER BY created_at DESC
    ]], {identifier})
    
    local warnings = {}
    
    if result then
        for _, row in ipairs(result) do
            local expires = nil
            if row.expires_at then
                expires = os.date('%Y-%m-%dT%H:%M:%SZ', row.expires_at)
            end
            
            table.insert(warnings, {
                id = row.id,
                reason = row.reason or '',
                issuedBy = row.issued_by or row.admin or 'System',
                date = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at),
                active = (row.active == 1 or row.active == true),
                expires = expires
            })
        end
    end
    
    return { success = true, warnings = warnings }
end)

-- Callback: Get player bans
lib.callback.register('ec_admin:getPlayerBans', function(source, data)
    local playerId = tonumber(data.playerId)
    local identifier = data.identifier
    
    if playerId and not identifier then
        identifier = getPlayerIdentifierFromId(playerId)
    end
    
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    -- Query bans table (adjust table name based on your moderation system)
    local result = MySQL.query.await([[
        SELECT * FROM ec_bans
        WHERE identifier = ? AND active = 1
        ORDER BY created_at DESC
    ]], {identifier})
    
    local bans = {}
    
    if result then
        for _, row in ipairs(result) do
            local expires = nil
            if row.expires_at and not row.permanent then
                expires = os.date('%Y-%m-%dT%H:%M:%SZ', row.expires_at)
            end
            
            table.insert(bans, {
                id = row.id,
                reason = row.reason or '',
                issuedBy = row.banned_by or row.admin or 'System',
                date = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at),
                active = (row.active == 1 or row.active == true),
                expires = expires
            })
        end
    end
    
    return { success = true, bans = bans }
end)

-- Callback: Get player notes
lib.callback.register('ec_admin:getPlayerNotes', function(source, data)
    local playerId = tonumber(data.playerId)
    local identifier = data.identifier
    
    if playerId and not identifier then
        identifier = getPlayerIdentifierFromId(playerId)
    end
    
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    local result = MySQL.query.await([[
        SELECT * FROM ec_player_moderation_notes
        WHERE identifier = ?
        ORDER BY created_at DESC
    ]], {identifier})
    
    local notes = {}
    
    if result then
        for _, row in ipairs(result) do
            table.insert(notes, {
                id = row.id,
                note = row.note,
                createdBy = row.created_by,
                date = os.date('%Y-%m-%dT%H:%M:%SZ', row.created_at)
            })
        end
    end
    
    return { success = true, notes = notes }
end)

-- Callback: Get player performance
lib.callback.register('ec_admin:getPlayerPerformance', function(source, data)
    local playerId = tonumber(data.playerId)
    local identifier = data.identifier
    
    if playerId and not identifier then
        identifier = getPlayerIdentifierFromId(playerId)
    end
    
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    -- Get last 30 days
    local cutoffDate = os.date('%Y-%m-%d', getCurrentTimestamp() - (30 * 86400))
    local result = MySQL.query.await([[
        SELECT * FROM ec_player_performance
        WHERE identifier = ? AND date >= ?
        ORDER BY date ASC
    ]], {identifier, cutoffDate})
    
    local performance = {}
    
    if result then
        for _, row in ipairs(result) do
            table.insert(performance, {
                day = os.date('%Y-%m-%d', row.date),
                playtime = row.playtime_minutes or 0,
                arrests = row.arrests or 0,
                deaths = row.deaths or 0
            })
        end
    end
    
    return { success = true, performance = performance }
end)

-- Callback: Get player money chart
lib.callback.register('ec_admin:getPlayerMoneyChart', function(source, data)
    local playerId = tonumber(data.playerId)
    local identifier = data.identifier
    
    if playerId and not identifier then
        identifier = getPlayerIdentifierFromId(playerId)
    end
    
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    -- Get last 30 days of transactions
    local cutoffTime = getCurrentTimestamp() - (30 * 86400)
    local result = MySQL.query.await([[
        SELECT DATE(FROM_UNIXTIME(timestamp)) as day, 
               SUM(CASE WHEN type = 'cash' THEN amount ELSE 0 END) as cash,
               SUM(CASE WHEN type = 'bank' THEN amount ELSE 0 END) as bank
        FROM ec_player_transactions
        WHERE identifier = ? AND timestamp >= ?
        GROUP BY day
        ORDER BY day ASC
    ]], {identifier, cutoffTime})
    
    local moneyChart = {}
    
    if result then
        for _, row in ipairs(result) do
            table.insert(moneyChart, {
                day = row.day,
                cash = tonumber(row.cash) or 0,
                bank = tonumber(row.bank) or 0
            })
        end
    end
    
    return { success = true, moneyChart = moneyChart }
end)

-- Callback: Warn player
lib.callback.register('ec_admin:warnPlayer', function(source, data)
    local playerId = tonumber(data.playerId)
    local reason = data.reason or 'No reason provided'
    
    if not playerId then
        return { success = false, error = 'Player ID required' }
    end
    
    local identifier = getPlayerIdentifierFromId(playerId)
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    local adminId = getPlayerIdentifierFromSource(source) or 'system'
    
    -- Insert warning
    MySQL.insert.await([[
        INSERT INTO ec_player_warnings (identifier, reason, issued_by, created_at, active, expires_at)
        VALUES (?, ?, ?, ?, 1, ?)
    ]], {identifier, reason, adminName, getCurrentTimestamp(), getCurrentTimestamp() + (7 * 86400)})
    
    -- Log activity
    logPlayerActivity(identifier, 'Warning issued', 'moderation', reason, adminId)
    
    -- Notify player if online
    if GetPlayerPing(playerId) then
        TriggerClientEvent('ec_admin:notify', playerId, 'warning', 'You have been warned: ' .. reason)
    end
    
    return { success = true, message = 'Warning issued successfully' }
end)

-- Callback: Ban player
lib.callback.register('ec_admin:banPlayer', function(source, data)
    local playerId = tonumber(data.playerId)
    local reason = data.reason or 'No reason provided'
    local duration = data.duration or '7d'
    
    if not playerId then
        return { success = false, error = 'Player ID required' }
    end
    
    local identifier = getPlayerIdentifierFromId(playerId)
    if not identifier then
        return { success = false, error = 'Player not found' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    local adminId = getPlayerIdentifierFromSource(source) or 'system'
    local expiresAt = calculateDuration(duration)
    local isPermanent = expiresAt == nil
    
    -- Insert ban
    MySQL.insert.await([[
        INSERT INTO ec_bans (identifier, reason, banned_by, created_at, expires_at, permanent, active)
        VALUES (?, ?, ?, ?, ?, ?, 1)
    ]], {identifier, reason, adminName, getCurrentTimestamp(), expiresAt, isPermanent and 1 or 0})
    
    -- Log activity
    logPlayerActivity(identifier, 'Ban issued', 'moderation', reason .. ' (Duration: ' .. duration .. ')', adminId)
    
    -- Kick player if online
    if GetPlayerPing(playerId) then
        DropPlayer(playerId, string.format('Banned: %s (Duration: %s)', reason, duration))
    end
    
    return { success = true, message = 'Player banned successfully' }
end)

-- Callback: Kick player
lib.callback.register('ec_admin:kickPlayer', function(source, data)
    local playerId = tonumber(data.playerId)
    local reason = data.reason or 'No reason provided'
    
    if not playerId then
        return { success = false, error = 'Player ID required' }
    end
    
    if not GetPlayerPing(playerId) then
        return { success = false, error = 'Player not found or offline' }
    end
    
    local identifier = getPlayerIdentifierFromId(playerId)
    local adminName = GetPlayerName(source) or 'System'
    local adminId = getPlayerIdentifierFromSource(source) or 'system'
    
    -- Log activity
    if identifier then
        logPlayerActivity(identifier, 'Kicked', 'moderation', reason, adminId)
    end
    
    -- Kick player
    DropPlayer(playerId, string.format('Kicked: %s', reason))
    
    return { success = true, message = 'Player kicked successfully' }
end)

-- Cleanup cache periodically
CreateThread(function()
    while true do
        Wait(10000) -- Check every 10 seconds
        
        local currentTime = getCurrentTimestamp()
        for key, cached in pairs(profileCache) do
            if (currentTime - cached.timestamp) >= CACHE_TTL then
                profileCache[key] = nil
            end
        end
    end
end)

print("^2[Player Profile]^7 UI Backend loaded successfully^0")

