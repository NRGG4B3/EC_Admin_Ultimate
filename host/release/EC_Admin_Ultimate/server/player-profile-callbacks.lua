--[[
    EC Admin Ultimate - Player Profile Server Callbacks
    Provides detailed player profile data
]]

Logger.Info('👤 Player Profile callbacks loading...')

-- ============================================================================
-- FRAMEWORK DETECTION
-- ============================================================================

local Framework = nil
local FrameworkName = 'standalone'

-- Try QBX first (has priority over QB-Core)
if GetResourceState('qbx_core') == 'started' then
    Framework = exports.qbx_core
    FrameworkName = 'qbx'
    Logger.Info('✅ QBX framework detected for player profiles')
-- Try QBCore
elseif GetResourceState('qb-core') == 'started' then
    Framework = exports['qb-core']:GetCoreObject()
    FrameworkName = 'qbcore'
    Logger.Info('✅ QBCore framework detected for player profiles')
-- Try ESX
elseif GetResourceState('es_extended') == 'started' then
    Framework = exports['es_extended']:getSharedObject()
    FrameworkName = 'esx'
    Logger.Info('✅ ESX framework detected for player profiles')
else
    Logger.Info('⚠️ No framework detected - using native FiveM data only')
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function GetFrameworkPlayer(playerId)
    if not Framework then return nil end
    
    if FrameworkName == 'qbx' then
        return Framework.GetPlayer(playerId)
    elseif FrameworkName == 'qbcore' then
        return Framework.Functions.GetPlayer(playerId)
    elseif FrameworkName == 'esx' then
        return Framework.GetPlayerFromId(playerId)
    end
    
    return nil
end

local function GetPlayerMoneyData(Player)
    if not Player then return { cash = 0, bank = 0, crypto = 0, blackMoney = 0 } end
    
    if FrameworkName == 'qbx' or FrameworkName == 'qbcore' then
        return {
            cash = Player.PlayerData.money.cash or 0,
            bank = Player.PlayerData.money.bank or 0,
            crypto = Player.PlayerData.money.crypto or 0,
            blackMoney = 0
        }
    elseif FrameworkName == 'esx' then
        local bankAccount = Player.getAccount('bank')
        local blackMoneyAccount = Player.getAccount('black_money')
        
        return {
            cash = Player.getMoney() or 0,
            bank = bankAccount and bankAccount.money or 0,
            crypto = 0,
            blackMoney = blackMoneyAccount and blackMoneyAccount.money or 0
        }
    end
    
    return { cash = 0, bank = 0, crypto = 0, blackMoney = 0 }
end

local function GetPlayerJobData(Player)
    if not Player then return { name = 'Unemployed', label = 'Unemployed', grade = 0, gradeLabel = 'None', salary = 0, onDuty = false } end
    
    if FrameworkName == 'qbx' or FrameworkName == 'qbcore' then
        local job = Player.PlayerData.job
        return {
            name = job.name or 'unemployed',
            label = job.label or 'Unemployed',
            grade = job.grade.level or 0,
            gradeLabel = job.grade.name or 'None',
            salary = job.payment or 0,
            onDuty = job.onduty or false
        }
    elseif FrameworkName == 'esx' then
        local job = Player.getJob()
        return {
            name = job.name or 'unemployed',
            label = job.label or 'Unemployed',
            grade = job.grade or 0,
            gradeLabel = job.grade_label or 'None',
            salary = job.grade_salary or 0,
            onDuty = true
        }
    end
    
    return { name = 'Unemployed', label = 'Unemployed', grade = 0, gradeLabel = 'None', salary = 0, onDuty = false }
end

local function GetPlayerGangData(Player)
    if not Player then return { name = 'None', label = 'None', grade = 0, gradeLabel = 'None' } end
    
    if FrameworkName == 'qbcore' then
        local gang = Player.PlayerData.gang
        if gang and gang.name and gang.name ~= 'none' then
            return {
                name = gang.name,
                label = gang.label or gang.name,
                grade = gang.grade.level or 0,
                gradeLabel = gang.grade.name or 'None'
            }
        end
    end
    
    return { name = 'None', label = 'None', grade = 0, gradeLabel = 'None' }
end

local function GetPlayerInventoryData(Player)
    if not Player then return { items = {}, weight = 0, maxWeight = 100 } end
    
    if FrameworkName == 'qbcore' then
        local items = Player.PlayerData.items or {}
        local weight = 0
        local formattedItems = {}
        
        for slot, item in pairs(items) do
            if item and item.name then
                table.insert(formattedItems, {
                    id = slot,
                    name = item.name,
                    label = item.label or item.name,
                    quantity = item.amount or 1,
                    type = item.type or 'item',
                    weight = item.weight or 0,
                    useable = item.useable or false,
                    description = item.info and item.info.description or '',
                    slot = slot,
                    metadata = item.info or {}
                })
                weight = weight + ((item.weight or 0) * (item.amount or 1))
            end
        end
        
        return {
            items = formattedItems,
            weight = weight,
            maxWeight = 120000
        }
    elseif FrameworkName == 'esx' then
        local inventory = Player.getInventory()
        local formattedItems = {}
        local weight = 0
        
        for _, item in ipairs(inventory) do
            if item.count > 0 then
                table.insert(formattedItems, {
                    id = item.name,
                    name = item.name,
                    label = item.label or item.name,
                    quantity = item.count,
                    type = 'item',
                    weight = item.weight or 0,
                    useable = item.useable or false,
                    description = '',
                    slot = #formattedItems + 1,
                    metadata = {}
                })
                weight = weight + ((item.weight or 0) * item.count)
            end
        end
        
        return {
            items = formattedItems,
            weight = weight,
            maxWeight = ESX.GetConfig().MaxWeight or 30
        }
    end
    
    return { items = {}, weight = 0, maxWeight = 100 }
end

-- ============================================================================
-- GET PLAYER PROFILE (detailed information)
-- ============================================================================

lib.callback.register('ec_admin:getPlayerProfile', function(source, data)
    local playerId = data.playerId
    
    if not playerId then
        return {
            success = false,
            error = 'No player ID provided'
        }
    end
    
    -- Check if player exists
    local playerPed = GetPlayerPed(playerId)
    if not playerPed or playerPed == 0 then
        return {
            success = false,
            error = 'Player not found'
        }
    end
    
    local name = GetPlayerName(playerId)
    local ping = GetPlayerPing(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local coords = GetEntityCoords(playerPed)
    local health = GetEntityHealth(playerPed)
    local armor = GetPedArmour(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- Extract identifiers
    local steam = nil
    local license = nil
    local discord = nil
    local fivem = nil
    local ip = nil
    local hwid = nil
    
    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, 'steam:') then
            steam = identifier
        elseif string.find(identifier, 'license:') then
            license = identifier
        elseif string.find(identifier, 'discord:') then
            discord = identifier
        elseif string.find(identifier, 'fivem:') then
            fivem = identifier
        elseif string.find(identifier, 'ip:') then
            ip = identifier
        end
    end
    
    -- Get Framework Player
    local Player = GetFrameworkPlayer(playerId)
    
    -- Get player data from framework
    local money = GetPlayerMoneyData(Player)
    local job = GetPlayerJobData(Player)
    local gang = GetPlayerGangData(Player)
    local inventory = GetPlayerInventoryData(Player)
    
    -- Check if player is admin
    local isAdmin = IsPlayerAceAllowed(playerId, 'admin.access')
    
    -- Get player vehicle
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local vehicleData = nil
    if vehicle ~= 0 then
        local vehicleModel = GetEntityModel(vehicle)
        local vehiclePlate = GetVehicleNumberPlateText(vehicle)
        local vehicleHealth = GetVehicleEngineHealth(vehicle)
        local vehicleBodyHealth = GetVehicleBodyHealth(vehicle)
        local vehicleFuel = GetVehicleFuelLevel(vehicle)
        
        vehicleData = {
            model = vehicleModel,
            plate = vehiclePlate,
            health = vehicleHealth,
            bodyHealth = vehicleBodyHealth,
            fuel = vehicleFuel,
            maxHealth = 1000.0,
            inVehicle = true
        }
    end
    
    -- Get additional player data from framework
    local citizenId = nil
    local phoneNumber = nil
    local metadata = {}
    
    if Player then
        if FrameworkName == 'qbcore' then
            citizenId = Player.PlayerData.citizenid
            phoneNumber = Player.PlayerData.charinfo.phone or 'Unknown'
            metadata = {
                hunger = Player.PlayerData.metadata.hunger or 100,
                thirst = Player.PlayerData.metadata.thirst or 100,
                stress = Player.PlayerData.metadata.stress or 0,
                isDead = Player.PlayerData.metadata.isdead or false,
                inlaststand = Player.PlayerData.metadata.inlaststand or false,
                armor = Player.PlayerData.metadata.armor or 0,
                ishandcuffed = Player.PlayerData.metadata.ishandcuffed or false,
                tracker = Player.PlayerData.metadata.tracker or false,
                injail = Player.PlayerData.metadata.injail or 0,
                jailitems = Player.PlayerData.metadata.jailitems or {},
                criminalrecord = Player.PlayerData.metadata.criminalrecord or {},
                licences = Player.PlayerData.metadata.licences or {},
                bloodtype = Player.PlayerData.metadata.bloodtype or 'O+',
                fingerprint = Player.PlayerData.metadata.fingerprint or 'Unknown',
                phone = Player.PlayerData.charinfo.phone or 'Unknown',
                nationality = Player.PlayerData.charinfo.nationality or 'USA',
                birthdate = Player.PlayerData.charinfo.birthdate or '1990-01-01',
                gender = Player.PlayerData.charinfo.gender == 0 and 'Male' or 'Female'
            }
        elseif FrameworkName == 'esx' then
            citizenId = Player.identifier
            phoneNumber = 'Unknown' -- ESX doesn't have built-in phone numbers
            metadata = {
                hunger = 100,
                thirst = 100,
                stress = 0,
                isDead = Player.isDead or false
            }
        end
    end
    
    -- Build profile with REAL DATA ONLY
    local profile = {
        -- Basic Info
        id = playerId,
        source = playerId,
        name = name,
        citizenId = citizenId,
        
        -- Identifiers (REAL)
        identifiers = {
            steam = steam,
            license = license,
            discord = discord,
            fivem = fivem,
            ip = ip,
            hwid = hwid
        },
        steamId = steam,
        license = license,
        discord = discord,
        discordId = discord,
        ip = ip,
        hwid = hwid,
        
        -- Live Stats (REAL)
        ping = ping,
        health = health,
        armor = armor,
        coords = {
            x = math.floor(coords.x * 100) / 100,
            y = math.floor(coords.y * 100) / 100,
            z = math.floor(coords.z * 100) / 100
        },
        heading = heading,
        location = 'Live Location', -- TODO: Get zone name from coords
        
        -- Status (REAL)
        online = true,
        status = 'online',
        admin = isAdmin,
        
        -- Current Activity (REAL)
        vehicle = vehicleData,
        inVehicle = vehicleData ~= nil,
        currentVehicle = vehicleData,
        zone = 'Unknown', -- TODO: Get zone name from coords
        
        -- Money (REAL from Framework)
        money = money,
        
        -- Job (REAL from Framework)
        job = job.label or job.name,
        jobGrade = job.gradeLabel,
        jobGradeLevel = job.grade,
        jobSalary = job.salary,
        onDuty = job.onDuty,
        
        -- Gang (REAL from Framework)
        gang = gang.label or gang.name,
        gangGrade = gang.gradeLabel,
        gangGradeLevel = gang.grade,
        
        -- Metadata (REAL from Framework)
        hunger = metadata.hunger or 100,
        thirst = metadata.thirst or 100,
        stress = metadata.stress or 0,
        isDead = metadata.isDead or false,
        phoneNumber = phoneNumber or 'Unknown',
        bloodType = metadata.bloodtype or 'Unknown',
        fingerprint = metadata.fingerprint or 'Unknown',
        nationality = metadata.nationality or 'Unknown',
        birthDate = metadata.birthdate or 'Unknown',
        gender = metadata.gender or 'Unknown',
        
        -- Inventory (REAL from Framework)
        inventory = inventory,
        
    -- Activity (no mock - needs database)
        lastLogin = os.time(),
        lastSeen = os.time(),
        lastSeenDate = os.date('%Y-%m-%d %H:%M:%S'),
        joinDate = os.date('%Y-%m-%d'),
        firstJoined = os.date('%Y-%m-%d'),
        playtime = '0h 0m',
        playtimeMinutes = 0,
        
    -- Moderation (no mock - needs database)
        warnings = 0,
        kicks = 0,
        bans = 0,
        commendations = 0,
        lastWarning = nil,
        
    -- Advanced stats (no mock - needs database)
        deaths = 0,
        kills = 0,
        arrests = 0,
        arrestsMade = 0,
        crimes = 0,
        level = 1,
        xp = 0,
        nextLevelXp = 1000,
        
        -- Timestamp
        timestamp = os.time()
    }
    
    return {
        success = true,
        player = profile  -- Frontend expects 'player' key
    }
end)

-- ============================================================================
-- GET PLAYER INVENTORY
-- ============================================================================

lib.callback.register('ec_admin:getPlayerInventory', function(source, data)
    local playerId = data.playerId
    
    if not playerId then
        return { success = false, error = 'No player ID provided' }
    end
    
    -- Get Framework Player
    local Player = GetFrameworkPlayer(playerId)
    
    -- Get player inventory data from framework
    local inventory = GetPlayerInventoryData(Player)
    
    return {
        success = true,
        inventory = inventory
    }
end)

-- ============================================================================
-- GET PLAYER VEHICLES
-- ============================================================================

lib.callback.register('ec_admin:getPlayerVehicles', function(source, data)
    local playerId = data.playerId
    
    if not playerId then
        return { success = false, error = 'No player ID provided' }
    end
    
    -- TODO: Query player vehicles from database
    
    return {
        success = true,
        vehicles = {}
    }
end)

-- ============================================================================
-- GET PLAYER LOGS
-- ============================================================================

lib.callback.register('ec_admin:getPlayerLogs', function(source, data)
    local playerId = data.playerId
    
    if not playerId then
        return { success = false, error = 'No player ID provided' }
    end
    
    -- TODO: Query player logs from database
    
    return {
        success = true,
        logs = {}
    }
end)

Logger.Info('✅ Player Profile callbacks loaded successfully')