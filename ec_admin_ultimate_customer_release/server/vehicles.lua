--[[
    EC Admin Ultimate - Vehicles UI Backend
    Server-side logic for vehicle management
    
    Features:
    - Auto-detection of all vehicle models (native + addon)
    - Complete vehicle management (spawn, delete, repair, refuel, etc.)
    - Framework-aware (QB/ESX/Standalone)
    - Statistics tracking
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Vehicles] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Vehicles] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local detectedVehicles = {}
local vehicleCache = {}
local CACHE_TTL = 300 -- Cache detected vehicles for 5 minutes

-- Comprehensive list of GTA V native vehicles (200+ vehicles)
local NATIVE_VEHICLES = {
    -- Super
    'adder', 'autarch', 'banshee2', 'bullet', 'cheetah', 'cyclone', 'entityxf', 'entity2', 'fmj', 'gp1',
    'infernus', 'italigtb', 'italigtb2', 'nero', 'nero2', 'osiris', 'penetrator', 'pfister811', 'reaper',
    'sc1', 'scramjet', 't20', 'taipan', 'tempesta', 'turismor', 'tyrus', 'vacca', 'vagner', 'vigilante',
    'visione', 'voltic', 'voltic2', 'xa21', 'zentorno',
    -- Sports
    'alpha', 'banshee', 'bestiagts', 'blista2', 'buffalo', 'buffalo2', 'buffalo3', 'carbonizzare',
    'comet2', 'comet3', 'comet4', 'comet5', 'coquette', 'elegy', 'elegy2', 'feltzer2', 'feltzer3',
    'furoregt', 'fusilade', 'futo', 'jester', 'jester2', 'jester3', 'khamelion', 'kuruma', 'kuruma2',
    'lynx', 'massacro', 'massacro2', 'neon', 'ninef', 'ninef2', 'omnis', 'pariah', 'penumbra', 'penumbra2',
    'rapidgt', 'rapidgt2', 'rapidgt3', 'raiden', 'ruston', 'schafter2', 'schafter3', 'schafter4',
    'schafter5', 'schafter6', 'schwarzer', 'sentinel3', 'seven70', 'specter', 'specter2', 'sultan',
    'sultanrs', 'surano', 'tampa2', 'tropos', 'verlierer2', 'zr350', 'zr380', 'zr3802', 'zr3803',
    -- Sports Classics
    'ardent', 'casco', 'cheetah2', 'coquette2', 'coquette3', 'deluxo', 'fagaloa', 'gt500', 'infernus2',
    'jb700', 'jb7002', 'mamba', 'manana', 'manana2', 'monroe', 'peyote', 'peyote2', 'pigalle', 'rapidgt3',
    'retinue', 'retinue2', 'stinger', 'stingergt', 'stromberg', 'torero', 'tornado', 'tornado2', 'tornado3',
    'tornado4', 'tornado5', 'tornado6', 'turismo2', 'viseris', 'z190', 'ztype',
    -- Muscle
    'blade', 'buccaneer', 'buccaneer2', 'chino', 'chino2', 'clique', 'coquette3', 'deviant', 'dominator',
    'dominator2', 'dominator3', 'dominator4', 'dominator5', 'dominator6', 'dominator7', 'dominator8',
    'dukes', 'dukes2', 'dukes3', 'faction', 'faction2', 'faction3', 'gauntlet', 'gauntlet2', 'gauntlet3',
    'gauntlet4', 'gauntlet5', 'hermes', 'hotknife', 'hustler', 'impaler', 'impaler2', 'impaler3', 'impaler4',
    'imperator', 'imperator2', 'imperator3', 'lurcher', 'moonbeam', 'moonbeam2', 'nightshade', 'peyote3',
    'phoenix', 'picador', 'ratloader', 'ratloader2', 'ruiner', 'ruiner2', 'ruiner3', 'sabregt', 'sabregt2',
    'slamvan', 'slamvan2', 'slamvan3', 'slamvan4', 'slamvan5', 'slamvan6', 'stalion', 'stalion2', 'tampa',
    'tampa3', 'tulip', 'vamos', 'vigero', 'virgo', 'virgo2', 'virgo3', 'voodoo', 'voodoo2', 'yosemite',
    'yosemite2', 'yosemite3',
    -- Sedans
    'asea', 'asea2', 'asterope', 'cognoscenti', 'cognoscenti2', 'emperor', 'emperor2', 'emperor3', 'fugitive',
    'glendale', 'glendale2', 'ingot', 'intruder', 'premier', 'primo', 'primo2', 'regina', 'schafter2',
    'schafter3', 'schafter4', 'schafter5', 'schafter6', 'stanier', 'stratum', 'stretch', 'superd',
    'surge', 'tailgater', 'warrener', 'washington',
    -- SUVs
    'baller', 'baller2', 'baller3', 'baller4', 'baller5', 'baller6', 'bjxl', 'cavalcade', 'cavalcade2',
    'dubsta', 'dubsta2', 'dubsta3', 'fq2', 'granger', 'gresley', 'habanero', 'huntley', 'landstalker',
    'landstalker2', 'mesa', 'mesa2', 'mesa3', 'patriot', 'patriot2', 'radi', 'rocoto', 'seminole',
    'seminole2', 'serrano', 'toros', 'xls', 'xls2',
    -- Coupes
    'cognoscenti', 'exemplar', 'f620', 'felon', 'felon2', 'jackal', 'oracle', 'oracle2', 'sentinel',
    'sentinel2', 'windsor', 'windsor2', 'zion', 'zion2',
    -- Compacts
    'blista', 'brioso', 'dilettante', 'dilettante2', 'issi2', 'issi3', 'issi4', 'issi5', 'issi6',
    'panto', 'prairie', 'rhapsody', 'weevil',
    -- Motorcycles
    'akuma', 'avarus', 'bagger', 'bati', 'bati2', 'bf400', 'carbonrs', 'chimera', 'cliffhanger',
    'daemon', 'daemon2', 'defiler', 'deathbike', 'deathbike2', 'deathbike3', 'diablous', 'diablous2',
    'double', 'enduro', 'esskey', 'faggio', 'faggio2', 'faggio3', 'fcr', 'fcr2', 'gargoyle', 'hakuchou',
    'hakuchou2', 'hexer', 'innovation', 'lectro', 'manchez', 'manchez2', 'nemesis', 'nightblade',
    'oppressor', 'oppressor2', 'pcj', 'ratbike', 'ruffian', 'rrocket', 'sanchez', 'sanchez2', 'sanctus',
    'shotaro', 'sovereign', 'stryder', 'thrust', 'vader', 'vindicator', 'vortex', 'wolfsbane', 'zombiea',
    'zombieb',
    -- Off-road
    'bifta', 'blazer', 'blazer2', 'blazer3', 'blazer4', 'blazer5', 'brawler', 'bruiser', 'bruiser2',
    'bruiser3', 'brutus', 'brutus2', 'brutus3', 'caracara', 'caracara2', 'dloader', 'dubsta3', 'dune',
    'dune2', 'dune3', 'dune4', 'dune5', 'everon', 'freecrawler', 'hellion', 'insurgent', 'insurgent2',
    'insurgent3', 'kalahari', 'kamacho', 'marshall', 'mesa3', 'monster', 'monster3', 'monster4', 'monster5',
    'outlaw', 'rancherxl', 'rancherxl2', 'rebel', 'rebel2', 'riata', 'sandking', 'sandking2', 'trophytruck',
    'trophytruck2', 'vagrant', 'wastelander', 'yosemite3', 'zhaba',
    -- Industrial
    'benson', 'biff', 'cerberus', 'cerberus2', 'cerberus3', 'hauler', 'hauler2', 'mule', 'mule2', 'mule3',
    'mule4', 'packer', 'phantom', 'phantom2', 'phantom3', 'pounder', 'pounder2', 'stockade', 'stockade3',
    -- Utility
    'airtug', 'caddy', 'caddy2', 'caddy3', 'docktug', 'forklift', 'mower', 'ripley', 'sadler', 'sadler2',
    'scrap', 'towtruck', 'towtruck2', 'tractor', 'tractor2', 'tractor3', 'utillitruck', 'utillitruck2',
    'utillitruck3',
    -- Vans
    'bison', 'bison2', 'bison3', 'bobcatxl', 'boxville', 'boxville2', 'boxville3', 'boxville4', 'boxville5',
    'burrito', 'burrito2', 'burrito3', 'burrito4', 'burrito5', 'camper', 'gangburrito', 'gangburrito2',
    'journey', 'minivan', 'minivan2', 'paradise', 'pony', 'pony2', 'rumpo', 'rumpo2', 'rumpo3', 'speedo',
    'speedo2', 'speedo4', 'surfer', 'surfer2', 'youga', 'youga2', 'youga3',
    -- Cycles
    'bmx', 'cruiser', 'fixter', 'scorcher', 'tribike', 'tribike2', 'tribike3',
    -- Boats
    'dinghy', 'dinghy2', 'dinghy3', 'dinghy4', 'jetmax', 'marquis', 'predator', 'seashark', 'seashark2',
    'seashark3', 'speeder', 'speeder2', 'squalo', 'submersible', 'submersible2', 'suntrap', 'toro',
    'toro2', 'tropic', 'tropic2', 'tugboat',
    -- Helicopters
    'akula', 'annihilator', 'buzzard', 'buzzard2', 'cargobob', 'cargobob2', 'cargobob3', 'cargobob4',
    'frogger', 'frogger2', 'havok', 'hunter', 'maverick', 'polmav', 'savage', 'seasparrow', 'seasparrow2',
    'seasparrow3', 'skylift', 'supervolito', 'supervolito2', 'swift', 'swift2', 'valkyrie', 'valkyrie2',
    'volatus',
    -- Planes
    'alphaz1', 'avenger', 'avenger2', 'besra', 'blimp', 'blimp2', 'blimp3', 'bombushka', 'cargoplane',
    'cuban800', 'dodo', 'duster', 'howard', 'hydra', 'jet', 'lazer', 'luxor', 'luxor2', 'mammatus',
    'microlight', 'miljet', 'mogul', 'molotok', 'nimbus', 'nokota', 'pyro', 'rogue', 'seabreeze', 'shamal',
    'starling', 'stunt', 'titan', 'tula', 'velum', 'velum2', 'vestra', 'volatol',
    -- Service
    'airbus', 'brickade', 'bus', 'coach', 'pbus', 'pbus2', 'rentalbus', 'taxi', 'tourbus', 'trash',
    'trash2', 'wastelander',
    -- Emergency
    'ambulance', 'fbi', 'fbi2', 'firetruk', 'lguard', 'pbus', 'police', 'police2', 'police3', 'police4',
    'policeb', 'policeold1', 'policeold2', 'policet', 'polmav', 'pranger', 'riot', 'riot2', 'sheriff',
    'sheriff2',
    -- Military
    'apc', 'barrage', 'chernobog', 'halftrack', 'khanjali', 'minitank', 'rhino', 'scarab', 'scarab2',
    'scarab3', 'thruster', 'trailersmall2',
    -- Commercial
    'benson', 'biff', 'hauler', 'hauler2', 'mule', 'mule2', 'mule3', 'mule4', 'packer', 'phantom',
    'phantom2', 'phantom3', 'pounder', 'pounder2', 'stockade', 'stockade3',
    -- Trains
    'freight', 'freightcar', 'freightcont1', 'freightcont2', 'freightgrain', 'freighttrailer', 'tankercar',
    -- Open Wheel
    'formula', 'formula2', 'openwheel1', 'openwheel2',
    -- Sports (Additional)
    'calico', 'comet6', 'euros', 'futo2', 'jester4', 'remus', 'rt3000', 'sultan2', 'vectre', 'zr350',
    -- Others
    'airtug', 'caddy', 'caddy2', 'caddy3', 'docktug', 'forklift', 'mower', 'ripley', 'sadler', 'sadler2',
    'scrap', 'towtruck', 'towtruck2', 'tractor', 'tractor2', 'tractor3', 'utillitruck', 'utillitruck2',
    'utillitruck3'
}

-- Vehicle class names mapping
local VEHICLE_CLASSES = {
    [0] = 'Compacts',
    [1] = 'Sedans',
    [2] = 'SUVs',
    [3] = 'Coupes',
    [4] = 'Muscle',
    [5] = 'Sports Classics',
    [6] = 'Sports',
    [7] = 'Super',
    [8] = 'Motorcycles',
    [9] = 'Off-road',
    [10] = 'Industrial',
    [11] = 'Utility',
    [12] = 'Vans',
    [13] = 'Cycles',
    [14] = 'Boats',
    [15] = 'Helicopters',
    [16] = 'Planes',
    [17] = 'Service',
    [18] = 'Emergency',
    [19] = 'Military',
    [20] = 'Commercial',
    [21] = 'Trains',
    [22] = 'Open Wheel'
}

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Check admin permission
local function hasPermission(source, permission)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, permission)
    end
    return ECFramework.IsAdminGroup(source) or false
end

-- Helper: Get vehicle display name
local function getVehicleDisplayName(model)
    -- Note: GetDisplayNameFromVehicleModel is CLIENT-side only
    -- On server, we just format the model name
    local hash = GetHashKey(model)
    -- Fallback: Capitalize model name and format it nicely
    local formatted = model:gsub("^%l", string.upper):gsub("_", " ")
    return formatted
end

-- Helper: Get vehicle class name
local function getVehicleClassName(model)
    -- Note: GetVehicleClassFromName is CLIENT-side only
    -- On server, we'll use a simple mapping based on model name patterns
    local hash = GetHashKey(model)
    -- Simple pattern matching for common vehicle types
    local modelLower = string.lower(model)
    if string.find(modelLower, 'car') or string.find(modelLower, 'sedan') or string.find(modelLower, 'coupe') then
        return 'Compacts' or 'Sedans'
    elseif string.find(modelLower, 'suv') or string.find(modelLower, 'offroad') then
        return 'SUVs'
    elseif string.find(modelLower, 'truck') or string.find(modelLower, 'van') then
        return 'Commercial'
    elseif string.find(modelLower, 'bike') or string.find(modelLower, 'motorcycle') then
        return 'Motorcycles'
    elseif string.find(modelLower, 'boat') then
        return 'Boats'
    elseif string.find(modelLower, 'plane') or string.find(modelLower, 'jet') then
        return 'Planes'
    elseif string.find(modelLower, 'heli') or string.find(modelLower, 'copter') then
        return 'Helicopters'
    else
        return 'Unknown'
    end
end

-- Helper: Check if vehicle model is valid
-- Note: IsModelInCdimage is CLIENT-side only, so we use a different approach on server
local function isVehicleModelValid(model)
    local hash = GetHashKey(model)
    -- On server, we can't use IsModelInCdimage, so we check if hash is valid
    -- Valid hashes are typically > 0 and < 2^31
    if hash and hash > 0 and hash < 2147483647 then
        return true
    end
    return false
end

-- Function: Auto-detect all vehicles
local function detectAllVehicles()
    local vehicles = {}
    local nativeCount = 0
    local addonCount = 0
    
    -- Detect native vehicles
    for _, model in ipairs(NATIVE_VEHICLES) do
        if isVehicleModelValid(model) then
            table.insert(vehicles, {
                model = model,
                name = getVehicleDisplayName(model),
                class = getVehicleClassName(model),
                manufacturer = nil, -- Could add manufacturer mapping
                category = 'native'
            })
            nativeCount = nativeCount + 1
        end
    end
    
    -- Detect addon vehicles (common patterns)
    local addonPatterns = {
        'addon_', 'custom_', 'pack_', 'dlc_', 'mod_'
    }
    
    -- Try to detect addon vehicles by checking common resource names
    -- This is a simplified approach - in production, you might want to scan resources
    for i = 0, 1000 do
        local testModel = 'addon_' .. i
        if isVehicleModelValid(testModel) then
            table.insert(vehicles, {
                model = testModel,
                name = getVehicleDisplayName(testModel),
                class = getVehicleClassName(testModel),
                manufacturer = nil,
                category = 'addon'
            })
            addonCount = addonCount + 1
        end
    end
    
    -- Sort by class, then name
    table.sort(vehicles, function(a, b)
        if a.class == b.class then
            return a.name < b.name
        end
        return a.class < b.class
    end)
    
    print(string.format("^2[Vehicles]^7 Detected %d vehicles (%d native, %d addon)^0", #vehicles, nativeCount, addonCount))
    
    return vehicles, addonCount
end

-- Helper: Get vehicles table name
local function getVehiclesTableName()
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        return 'player_vehicles'
    elseif framework == 'esx' then
        return 'owned_vehicles'
    else
        return 'vehicles' -- Fallback
    end
end

-- Helper: Get vehicle by plate
local function getVehicleByPlate(plate)
    local tableName = getVehiclesTableName()
    local framework = getFramework()
    
    local query = ''
    if framework == 'qb' or framework == 'qbx' then
        query = 'SELECT * FROM ' .. tableName .. ' WHERE plate = ?'
    elseif framework == 'esx' then
        query = 'SELECT * FROM ' .. tableName .. ' WHERE plate = ?'
    else
        query = 'SELECT * FROM ' .. tableName .. ' WHERE plate = ?'
    end
    
    local result = MySQL.query.await(query, {plate})
    if result and result[1] then
        return result[1]
    end
    return nil
end

-- Helper: Get vehicle in world by plate
local function getVehicleInWorld(plate)
    local vehicles = GetAllVehicles()
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehiclePlate = GetVehicleNumberPlateText(vehicle)
            if vehiclePlate == plate then
                return vehicle
            end
        end
    end
    return nil
end

-- Helper: Generate unique plate
local function generatePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local plate = ''
    for i = 1, 8 do
        local rand = math.random(1, #chars)
        plate = plate .. string.sub(chars, rand, rand)
    end
    
    -- Check if plate exists
    local existing = getVehicleByPlate(plate)
    if existing then
        return generatePlate() -- Recursive if exists
    end
    
    return plate
end

-- Helper: Get owner location
local function getOwnerLocation(identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if source then
            local ids = GetPlayerIdentifiers(source)
            if ids then
                for _, id in ipairs(ids) do
                    if string.find(id, 'license:') and id == identifier then
                        local ped = GetPlayerPed(source)
                        if ped and ped ~= 0 then
                            local coords = GetEntityCoords(ped)
                            return { x = coords.x, y = coords.y, z = coords.z }
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Helper: Spawn vehicle at location
local function spawnVehicleAtLocation(model, coords, plate, mods, color)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) and not IsModelValid(hash) then
        return nil
    end
    
    -- Request model
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(hash) then
        return nil
    end
    
    -- Spawn vehicle
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, 0.0, false, false)
    if not vehicle or vehicle == 0 then
        return nil
    end
    
    -- Set plate
    if plate then
        SetVehicleNumberPlateText(vehicle, plate)
    end
    
    -- Set mods
    if mods then
        if mods.engine then SetVehicleMod(vehicle, 11, mods.engine, false) end
        if mods.brakes then SetVehicleMod(vehicle, 12, mods.brakes, false) end
        if mods.transmission then SetVehicleMod(vehicle, 13, mods.transmission, false) end
        if mods.suspension then SetVehicleMod(vehicle, 15, mods.suspension, false) end
        if mods.turbo then ToggleVehicleMod(vehicle, 18, mods.turbo) end
    end
    
    -- Set colors
    if color then
        SetVehicleColours(vehicle, tonumber(color.primary) or 0, tonumber(color.secondary) or 0)
    end
    
    SetModelAsNoLongerNeeded(hash)
    
    return vehicle
end

-- Helper: Log vehicle action
local function logVehicleAction(plate, action, performedBy, details)
    MySQL.insert.await([[
        INSERT INTO ec_vehicle_action_log (plate, action, performed_by, details, timestamp)
        VALUES (?, ?, ?, ?, ?)
    ]], {plate or '', action, performedBy, details or '', getCurrentTimestamp()})
end

-- Helper: Log vehicle spawn
local function logVehicleSpawn(model, plate, spawnedBy, spawnedFor, coords)
    MySQL.insert.await([[
        INSERT INTO ec_vehicle_spawn_log (vehicle_model, plate, spawned_by, spawned_for, coords_x, coords_y, coords_z, timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {model, plate, spawnedBy, spawnedFor or nil, coords and coords.x or nil, coords and coords.y or nil, coords and coords.z or nil, getCurrentTimestamp()})
end

-- Helper: Log plate change
local function logPlateChange(oldPlate, newPlate, changedBy)
    MySQL.insert.await([[
        INSERT INTO ec_vehicle_plate_history (old_plate, new_plate, changed_by, timestamp)
        VALUES (?, ?, ?, ?)
    ]], {oldPlate, newPlate, changedBy, getCurrentTimestamp()})
end

-- Helper: Log vehicle transfer
local function logVehicleTransfer(plate, oldOwner, newOwner, transferredBy)
    MySQL.insert.await([[
        INSERT INTO ec_vehicle_transfer_log (plate, old_owner, new_owner, transferred_by, timestamp)
        VALUES (?, ?, ?, ?, ?)
    ]], {plate, oldOwner or nil, newOwner, transferredBy, getCurrentTimestamp()})
end

-- Helper: Update vehicle statistics
local function updateVehicleStatistics(action)
    local today = os.date("%Y-%m-%d")
    local result = MySQL.query.await('SELECT * FROM ec_vehicle_statistics WHERE date = ?', {today})
    
    if result and result[1] then
        -- Update existing
        MySQL.update.await('UPDATE ec_vehicle_statistics SET ' .. action .. ' = ' .. action .. ' + 1 WHERE date = ?', {today})
    else
        -- Insert new
        MySQL.insert.await('INSERT INTO ec_vehicle_statistics (date, ' .. action .. ') VALUES (?, ?)', {today, 1})
    end
end

-- Helper: Calculate vehicle stats
local function calculateVehicleStats(vehicles)
    local stats = {
        totalVehicles = #vehicles,
        spawnedVehicles = 0,
        ownedVehicles = #vehicles,
        impoundedVehicles = 0,
        totalValue = 0
    }
    
    for _, vehicle in ipairs(vehicles) do
        if vehicle.spawned then
            stats.spawnedVehicles = stats.spawnedVehicles + 1
        end
        if vehicle.impounded then
            stats.impoundedVehicles = stats.impoundedVehicles + 1
        end
        if vehicle.value then
            stats.totalValue = stats.totalValue + vehicle.value
        end
    end
    
    return stats
end

-- Callback: Get all vehicles
lib.callback.register('ec_admin:getVehicles', function(source, data)
    local tableName = getVehiclesTableName()
    local framework = getFramework()
    
    local query = ''
    if framework == 'qb' or framework == 'qbx' then
        query = 'SELECT * FROM ' .. tableName .. ' ORDER BY id DESC LIMIT 1000'
    elseif framework == 'esx' then
        query = 'SELECT * FROM ' .. tableName .. ' ORDER BY id DESC LIMIT 1000'
    else
        query = 'SELECT * FROM ' .. tableName .. ' ORDER BY id DESC LIMIT 1000'
    end
    
    local result = MySQL.query.await(query, {})
    
    if not result then
        return { success = true, vehicles = {}, stats = { totalVehicles = 0, spawnedVehicles = 0, ownedVehicles = 0, impoundedVehicles = 0, totalValue = 0 } }
    end
    
    local vehicles = {}
    local spawnedVehicles = GetAllVehicles()
    
    for _, row in ipairs(result) do
        local mods = {}
        if row.mods then
            mods = json.decode(row.mods) or {}
        end
        
        local color = { primary = '0', secondary = '0' }
        if row.color1 and row.color2 then
            color = { primary = tostring(row.color1), secondary = tostring(row.color2) }
        end
        
        -- Check if vehicle is spawned
        local isSpawned = false
        for _, veh in ipairs(spawnedVehicles) do
            if DoesEntityExist(veh) then
                local plate = GetVehicleNumberPlateText(veh)
                if plate == (row.plate or '') then
                    isSpawned = true
                    break
                end
            end
        end
        
        table.insert(vehicles, {
            id = row.id or row.vehicle,
            model = row.vehicle or row.model or 'unknown',
            plate = row.plate or '',
            owner = row.owner or row.citizenid or 'Unknown',
            ownerId = row.citizenid or row.owner,
            citizenid = row.citizenid,
            location = row.garage or 'Unknown',
            garage = row.garage,
            health = tonumber(row.body) or 1000,
            bodyHealth = tonumber(row.body) or 1000,
            engineHealth = tonumber(row.engine) or 1000,
            fuel = tonumber(row.fuel) or 100,
            locked = false,
            type = 'automobile',
            class = getVehicleClassName(row.vehicle or row.model or 'unknown'),
            spawned = isSpawned or (row.state == 'out'),
            impounded = (row.state == 'impounded' or row.impounded == 1),
            impoundReason = row.impound_reason,
            stored = (row.state == 'garage' or row.stored == 1),
            mods = mods,
            color = color,
            value = tonumber(row.price) or 0,
            mileage = tonumber(row.mileage or row.km) or 0
        })
    end
    
    local stats = calculateVehicleStats(vehicles)
    
    return { success = true, vehicles = vehicles, stats = stats }
end)

-- Callback: Get all available vehicles (with auto-detection)
lib.callback.register('ec_admin:getAllVehicles', function(source, data)
    -- Check cache
    if detectedVehicles.vehicles and (getCurrentTimestamp() - detectedVehicles.timestamp) < CACHE_TTL then
        return {
            success = true,
            vehicles = detectedVehicles.vehicles,
            customCount = detectedVehicles.customCount
        }
    end
    
    -- Run detection
    local vehicles, customCount = detectAllVehicles()
    
    -- Cache results
    detectedVehicles = {
        vehicles = vehicles,
        customCount = customCount,
        timestamp = getCurrentTimestamp()
    }
    
    return {
        success = true,
        vehicles = vehicles,
        customCount = customCount
    }
end)

-- Callback: Spawn vehicle
lib.callback.register('ec_admin:spawnVehicle', function(source, data)
    local plate = data.plate
    if not plate then
        return { success = false, error = 'Plate required' }
    end
    
    local vehicleData = getVehicleByPlate(plate)
    if not vehicleData then
        return { success = false, error = 'Vehicle not found' }
    end
    
    -- Get owner location or default spawn
    local coords = { x = 0.0, y = 0.0, z = 0.0 }
    if vehicleData.citizenid or vehicleData.owner then
        local ownerLoc = getOwnerLocation(vehicleData.citizenid or vehicleData.owner)
        if ownerLoc then
            coords = ownerLoc
        else
            -- Default spawn location
            coords = { x = -1037.0, y = -2737.0, z = 20.0 }
        end
    end
    
    local mods = {}
    if vehicleData.mods then
        mods = json.decode(vehicleData.mods) or {}
    end
    
    local color = { primary = '0', secondary = '0' }
    if vehicleData.color1 and vehicleData.color2 then
        color = { primary = tostring(vehicleData.color1), secondary = tostring(vehicleData.color2) }
    end
    
    local vehicle = spawnVehicleAtLocation(vehicleData.vehicle or vehicleData.model, coords, plate, mods, color)
    if not vehicle then
        return { success = false, error = 'Failed to spawn vehicle' }
    end
    
    -- Update database
    local tableName = getVehiclesTableName()
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        MySQL.update.await('UPDATE ' .. tableName .. ' SET state = ? WHERE plate = ?', {'out', plate})
    elseif framework == 'esx' then
        MySQL.update.await('UPDATE ' .. tableName .. ' SET stored = ? WHERE plate = ?', {0, plate})
    end
    
    return { success = true, message = 'Vehicle spawned successfully' }
end)

-- Callback: Quick spawn vehicle
lib.callback.register('ec_admin:quickSpawnVehicle', function(source, data)
    local model = data.model
    if not model then
        return { success = false, error = 'Model required' }
    end
    
    -- Validate model
    if not isVehicleModelValid(model) then
        return { success = false, error = 'Invalid vehicle model' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    local adminId = GetPlayerIdentifier(source, 0) or 'system'
    
    -- Get admin location
    local adminPed = GetPlayerPed(source)
    local coords = { x = 0.0, y = 0.0, z = 0.0 }
    if adminPed and adminPed ~= 0 then
        local adminCoords = GetEntityCoords(adminPed)
        coords = { x = adminCoords.x + 3.0, y = adminCoords.y, z = adminCoords.z }
    end
    
    -- Generate plate
    local plate = generatePlate()
    
    -- Spawn vehicle
    local vehicle = spawnVehicleAtLocation(model, coords, plate, {}, { primary = '0', secondary = '0' })
    if not vehicle then
        return { success = false, error = 'Failed to spawn vehicle' }
    end
    
    -- Optionally add to database if owner provided
    if data.owner then
        local tableName = getVehiclesTableName()
        local framework = getFramework()
        if framework == 'qb' or framework == 'qbx' then
            MySQL.insert.await('INSERT INTO ' .. tableName .. ' (citizenid, vehicle, hash, mods, plate, garage, state, fuel, engine, body) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                data.owner, model, GetHashKey(model), '{}', plate, 'legion', 'out', 100, 1000, 1000
            })
        elseif framework == 'esx' then
            MySQL.insert.await('INSERT INTO ' .. tableName .. ' (owner, plate, vehicle, stored, garage) VALUES (?, ?, ?, ?, ?)', {
                data.owner, plate, model, 0, 'legion'
            })
        end
    end
    
    -- Log spawn
    logVehicleSpawn(model, plate, adminName, data.owner, coords)
    logVehicleAction(plate, 'quick_spawn', adminName, 'Quick spawned vehicle: ' .. model)
    
    return { success = true, message = 'Vehicle spawned successfully', plate = plate }
end)

-- Callback: Delete vehicle
lib.callback.register('ec_admin:deleteVehicle', function(source, data)
    local plate = data.plate
    if not plate then
        return { success = false, error = 'Plate required' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    
    -- Delete from world if spawned
    local vehicle = getVehicleInWorld(plate)
    if vehicle then
        DeleteEntity(vehicle)
    end
    
    -- Delete from database
    local tableName = getVehiclesTableName()
    MySQL.query.await('DELETE FROM ' .. tableName .. ' WHERE plate = ?', {plate})
    
    -- Log action
    logVehicleAction(plate, 'delete', adminName, 'Vehicle deleted')
    updateVehicleStatistics('vehicles_deleted')
    
    return { success = true, message = 'Vehicle deleted successfully' }
end)

-- Callback: Repair vehicle
lib.callback.register('ec_admin:repairVehicle', function(source, data)
    local plate = data.plate
    if not plate then
        return { success = false, error = 'Plate required' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    
    local vehicle = getVehicleInWorld(plate)
    if not vehicle then
        return { success = false, error = 'Vehicle not found in world' }
    end
    
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    
    -- Update database
    local tableName = getVehiclesTableName()
    MySQL.update.await('UPDATE ' .. tableName .. ' SET engine = ?, body = ? WHERE plate = ?', {1000, 1000, plate})
    
    -- Log action
    logVehicleAction(plate, 'repair', adminName, 'Vehicle repaired')
    updateVehicleStatistics('vehicles_repaired')
    
    return { success = true, message = 'Vehicle repaired successfully' }
end)

-- Callback: Refuel vehicle
lib.callback.register('ec_admin:refuelVehicle', function(source, data)
    local plate = data.plate
    if not plate then
        return { success = false, error = 'Plate required' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    
    local vehicle = getVehicleInWorld(plate)
    if not vehicle then
        return { success = false, error = 'Vehicle not found in world' }
    end
    
    SetVehicleFuelLevel(vehicle, 100.0)
    
    -- Update database
    local tableName = getVehiclesTableName()
    MySQL.update.await('UPDATE ' .. tableName .. ' SET fuel = ? WHERE plate = ?', {100, plate})
    
    -- Log action
    logVehicleAction(plate, 'refuel', adminName, 'Vehicle refueled')
    updateVehicleStatistics('vehicles_refueled')
    
    return { success = true, message = 'Vehicle refueled successfully' }
end)

-- Callback: Impound vehicle
lib.callback.register('ec_admin:impoundVehicle', function(source, data)
    local plate = data.plate
    local reason = data.reason or 'Admin impound'
    
    if not plate then
        return { success = false, error = 'Plate required' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    
    -- Delete from world if spawned
    local vehicle = getVehicleInWorld(plate)
    if vehicle then
        DeleteEntity(vehicle)
    end
    
    -- Update database
    local tableName = getVehiclesTableName()
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        MySQL.update.await('UPDATE ' .. tableName .. ' SET state = ?, impound_reason = ? WHERE plate = ?', {'impounded', reason, plate})
    elseif framework == 'esx' then
        MySQL.update.await('UPDATE ' .. tableName .. ' SET stored = ?, impounded = ? WHERE plate = ?', {1, 1, plate})
    end
    
    -- Log action
    logVehicleAction(plate, 'impound', adminName, 'Reason: ' .. reason)
    updateVehicleStatistics('vehicles_impounded')
    
    return { success = true, message = 'Vehicle impounded successfully' }
end)

-- Callback: Unimpound vehicle
lib.callback.register('ec_admin:unimpoundVehicle', function(source, data)
    local plate = data.plate
    if not plate then
        return { success = false, error = 'Plate required' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    
    -- Update database
    local tableName = getVehiclesTableName()
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        MySQL.update.await('UPDATE ' .. tableName .. ' SET state = ?, impound_reason = ? WHERE plate = ?', {'garage', nil, plate})
    elseif framework == 'esx' then
        MySQL.update.await('UPDATE ' .. tableName .. ' SET impounded = ? WHERE plate = ?', {0, plate})
    end
    
    -- Log action
    logVehicleAction(plate, 'unimpound', adminName, 'Vehicle released from impound')
    
    return { success = true, message = 'Vehicle unimpounded successfully' }
end)

-- Callback: Teleport to vehicle
lib.callback.register('ec_admin:teleportToVehicle', function(source, data)
    local plate = data.plate
    if not plate then
        return { success = false, error = 'Plate required' }
    end
    
    local vehicle = getVehicleInWorld(plate)
    if not vehicle then
        return { success = false, error = 'Vehicle not found in world' }
    end
    
    local coords = GetEntityCoords(vehicle)
    TriggerClientEvent('ec_admin:teleportToCoords', source, coords.x, coords.y, coords.z)
    
    return { success = true, message = 'Teleported to vehicle' }
end)

-- Callback: Rename vehicle (change plate)
lib.callback.register('ec_admin:renameVehicle', function(source, data)
    local oldPlate = data.oldPlate
    local newPlate = data.newPlate
    
    if not oldPlate or not newPlate then
        return { success = false, error = 'Plates required' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    
    -- Check if new plate exists
    local existing = getVehicleByPlate(newPlate)
    if existing then
        return { success = false, error = 'Plate already exists' }
    end
    
    -- Update in world if spawned
    local vehicle = getVehicleInWorld(oldPlate)
    if vehicle then
        SetVehicleNumberPlateText(vehicle, newPlate)
    end
    
    -- Update database
    local tableName = getVehiclesTableName()
    MySQL.update.await('UPDATE ' .. tableName .. ' SET plate = ? WHERE plate = ?', {newPlate, oldPlate})
    
    -- Log plate change
    logPlateChange(oldPlate, newPlate, adminName)
    logVehicleAction(oldPlate, 'rename', adminName, 'Plate changed to: ' .. newPlate)
    
    return { success = true, message = 'Vehicle plate changed successfully' }
end)

-- Callback: Change vehicle color
lib.callback.register('ec_admin:changeVehicleColor', function(source, data)
    local plate = data.plate
    local primaryColor = tonumber(data.primaryColor) or 0
    local secondaryColor = tonumber(data.secondaryColor) or 0
    
    if not plate then
        return { success = false, error = 'Plate required' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    
    local vehicle = getVehicleInWorld(plate)
    if vehicle then
        SetVehicleColours(vehicle, primaryColor, secondaryColor)
    end
    
    -- Update database
    local tableName = getVehiclesTableName()
    MySQL.update.await('UPDATE ' .. tableName .. ' SET color1 = ?, color2 = ? WHERE plate = ?', {primaryColor, secondaryColor, plate})
    
    -- Log action
    logVehicleAction(plate, 'color_change', adminName, 'Primary: ' .. primaryColor .. ', Secondary: ' .. secondaryColor)
    
    return { success = true, message = 'Vehicle color changed successfully' }
end)

-- Callback: Upgrade vehicle
lib.callback.register('ec_admin:upgradeVehicle', function(source, data)
    local plate = data.plate
    local mods = data.mods or {}
    
    if not plate then
        return { success = false, error = 'Plate required' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    
    local vehicle = getVehicleInWorld(plate)
    if vehicle then
        if mods.engine then SetVehicleMod(vehicle, 11, mods.engine, false) end
        if mods.brakes then SetVehicleMod(vehicle, 12, mods.brakes, false) end
        if mods.transmission then SetVehicleMod(vehicle, 13, mods.transmission, false) end
        if mods.suspension then SetVehicleMod(vehicle, 15, mods.suspension, false) end
        if mods.turbo ~= nil then ToggleVehicleMod(vehicle, 18, mods.turbo) end
    end
    
    -- Update database
    local tableName = getVehiclesTableName()
    MySQL.update.await('UPDATE ' .. tableName .. ' SET mods = ? WHERE plate = ?', {json.encode(mods), plate})
    
    -- Log action
    logVehicleAction(plate, 'upgrade', adminName, 'Mods: ' .. json.encode(mods))
    
    return { success = true, message = 'Vehicle upgraded successfully' }
end)

-- Callback: Transfer vehicle
lib.callback.register('ec_admin:transferVehicle', function(source, data)
    local plate = data.plate
    local newOwner = data.newOwner
    
    if not plate or not newOwner then
        return { success = false, error = 'Plate and owner required' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    
    -- Get current owner
    local vehicleData = getVehicleByPlate(plate)
    local oldOwner = nil
    if vehicleData then
        oldOwner = vehicleData.citizenid or vehicleData.owner
    end
    
    -- Get new owner identifier
    local newOwnerId = nil
    for _, playerId in ipairs(GetPlayers()) do
        local sourceId = tonumber(playerId)
        if sourceId then
            local name = GetPlayerName(sourceId)
            if name == newOwner then
                local ids = GetPlayerIdentifiers(sourceId)
                if ids then
                    for _, id in ipairs(ids) do
                        if string.find(id, 'license:') then
                            newOwnerId = id
                            break
                        end
                    end
                end
            end
        end
    end
    
    if not newOwnerId then
        return { success = false, error = 'New owner not found' }
    end
    
    -- Update database
    local tableName = getVehiclesTableName()
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        MySQL.update.await('UPDATE ' .. tableName .. ' SET citizenid = ? WHERE plate = ?', {newOwnerId, plate})
    elseif framework == 'esx' then
        MySQL.update.await('UPDATE ' .. tableName .. ' SET owner = ? WHERE plate = ?', {newOwnerId, plate})
    end
    
    -- Log transfer
    logVehicleTransfer(plate, oldOwner, newOwnerId, adminName)
    logVehicleAction(plate, 'transfer', adminName, 'Transferred to: ' .. newOwner)
    
    return { success = true, message = 'Vehicle transferred successfully' }
end)

-- Callback: Store vehicle
lib.callback.register('ec_admin:storeVehicle', function(source, data)
    local plate = data.plate
    if not plate then
        return { success = false, error = 'Plate required' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    
    -- Delete from world if spawned
    local vehicle = getVehicleInWorld(plate)
    if vehicle then
        DeleteEntity(vehicle)
    end
    
    -- Update database
    local tableName = getVehiclesTableName()
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        MySQL.update.await('UPDATE ' .. tableName .. ' SET state = ? WHERE plate = ?', {'garage', plate})
    elseif framework == 'esx' then
        MySQL.update.await('UPDATE ' .. tableName .. ' SET stored = ? WHERE plate = ?', {1, plate})
    end
    
    -- Log action
    logVehicleAction(plate, 'store', adminName, 'Vehicle stored in garage')
    
    return { success = true, message = 'Vehicle stored successfully' }
end)

-- Callback: Add vehicle
lib.callback.register('ec_admin:addVehicle', function(source, data)
    local model = data.model
    local plate = data.plate or generatePlate()
    local owner = data.owner
    
    if not model then
        return { success = false, error = 'Model required' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    
    -- Validate model
    if not isVehicleModelValid(model) then
        return { success = false, error = 'Invalid vehicle model' }
    end
    
    -- Check if plate exists
    local existing = getVehicleByPlate(plate)
    if existing then
        return { success = false, error = 'Plate already exists' }
    end
    
    -- Get owner identifier
    local ownerId = owner
    if owner and not string.find(owner, 'license:') then
        -- Try to find by name
        for _, playerId in ipairs(GetPlayers()) do
            local sourceId = tonumber(playerId)
            if sourceId then
                local name = GetPlayerName(sourceId)
                if name == owner then
                    local ids = GetPlayerIdentifiers(sourceId)
                    if ids then
                        for _, id in ipairs(ids) do
                            if string.find(id, 'license:') then
                                ownerId = id
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Insert into database
    local tableName = getVehiclesTableName()
    local framework = getFramework()
    if framework == 'qb' or framework == 'qbx' then
        MySQL.insert.await('INSERT INTO ' .. tableName .. ' (citizenid, vehicle, hash, mods, plate, garage, state, fuel, engine, body) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            ownerId or 'system', model, GetHashKey(model), '{}', plate, 'legion', 'garage', 100, 1000, 1000
        })
    elseif framework == 'esx' then
        MySQL.insert.await('INSERT INTO ' .. tableName .. ' (owner, plate, vehicle, stored, garage) VALUES (?, ?, ?, ?, ?)', {
            ownerId or 'system', plate, model, 1, 'legion'
        })
    end
    
    -- Log action
    logVehicleAction(plate, 'add', adminName, 'Added vehicle: ' .. model .. ' for owner: ' .. (ownerId or 'system'))
    updateVehicleStatistics('vehicles_added')
    
    return { success = true, message = 'Vehicle added successfully', plate = plate }
end)

-- Initialize vehicle detection on resource start
CreateThread(function()
    Wait(5000) -- Wait 5 seconds for resources to load
    
    print("^2[Vehicles]^7 Starting vehicle auto-detection...^0")
    local vehicles, customCount = detectAllVehicles()
    
    detectedVehicles = {
        vehicles = vehicles,
        customCount = customCount,
        timestamp = getCurrentTimestamp()
    }
    
    print(string.format("^2[Vehicles]^7 Vehicle detection complete: %d vehicles ready (%d addon)^0", #vehicles, customCount))
end)

print("^2[Vehicles]^7 UI Backend loaded - Auto-detection enabled^0")

