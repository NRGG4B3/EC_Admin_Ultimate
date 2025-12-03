--[[
    EC Admin Ultimate - Vehicles Server Callbacks
    Provides vehicle list and management with FULL LIVE DATA
]]

Logger.Info('Vehicles callbacks loading...', '🚗')

-- ============================================================================
-- FRAMEWORK DETECTION
-- ============================================================================

local function GetFramework()
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
-- VEHICLE CLASS NAMES
-- ============================================================================

local vehicleClasses = {
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

-- ============================================================================
-- HELPER: GET VEHICLE NAME FROM MODEL (works on server)
-- ============================================================================

local function GetVehicleName(model)
    -- Try to get from shared vehicle database first
    if VehicleDatabase and VehicleDatabase.DefaultVehicles then
        for category, vehicles in pairs(VehicleDatabase.DefaultVehicles) do
            for _, veh in ipairs(vehicles) do
                if GetHashKey(veh.model) == model then
                    return veh.name
                end
            end
        end
    end
    
    -- Fallback: return model hash as string
    return 'Vehicle_' .. tostring(model)
end

-- ============================================================================
-- GET ALL VEHICLES (from database + spawned entities)
-- ============================================================================

lib.callback.register('ec_admin:getVehicles', function(source, data)
    local framework, Core = GetFramework()
    local vehicleList = {}
    local spawnedVehicles = {}
    
    -- Get all spawned vehicles in the world
    local allEntities = GetAllVehicles()
    
    for _, vehicle in ipairs(allEntities) do
        if DoesEntityExist(vehicle) then
            local plate = GetVehicleNumberPlateText(vehicle)
            local model = GetEntityModel(vehicle)
            -- FIX: Use our helper function instead of client-side native
            local modelName = GetVehicleName(model)
            local coords = GetEntityCoords(vehicle)
            local heading = GetEntityHeading(vehicle)
            
            -- Get vehicle health
            local bodyHealth = GetVehicleBodyHealth(vehicle)
            local engineHealth = GetVehicleEngineHealth(vehicle)
            local health = math.floor(((bodyHealth + engineHealth) / 2000) * 100)
            
            -- Get fuel level (check if function exists, fallback to 100)
            local fuel = 100
            if GetVehicleFuelLevel then
                fuel = GetVehicleFuelLevel(vehicle)
            elseif Entity then
                -- Try to get from entity state (FiveM statebag)
                fuel = Entity(vehicle).state.fuel or 100
            end
            
            -- Check if locked
            local lockStatus = GetVehicleDoorLockStatus(vehicle)
            local locked = lockStatus >= 2
            
            -- Get vehicle class (server-side doesn't have GetVehicleClass, use model hash)
            local vehicleClass = 0  -- Default to compacts
            local className = 'Unknown'
            
            -- Try to get class from model (server-side safe)
            if DoesEntityExist(vehicle) then
                -- We'll just use 'Vehicle' as className since GetVehicleClass is client-only
                className = 'Vehicle'
            end
            
            -- Get owner (if they're online)
            local owner = 'Unknown'
            local ownerId = nil
            
            -- Try to find owner from plate in database
            if framework == 'qb' or framework == 'qbx' then
                local result = MySQL.query.await('SELECT citizenid FROM player_vehicles WHERE plate = ?', {plate})
                if result and result[1] then
                    ownerId = result[1].citizenid
                    -- Get player name
                    local ownerResult = MySQL.query.await('SELECT JSON_EXTRACT(charinfo, "$.firstname") as firstname, JSON_EXTRACT(charinfo, "$.lastname") as lastname FROM players WHERE citizenid = ?', {ownerId})
                    if ownerResult and ownerResult[1] then
                        owner = string.format('%s %s', ownerResult[1].firstname or '', ownerResult[1].lastname or '')
                        owner = owner:gsub('"', '') -- Remove JSON quotes
                    end
                end
            elseif framework == 'esx' then
                local result = MySQL.query.await('SELECT owner FROM owned_vehicles WHERE plate = ?', {plate})
                if result and result[1] then
                    ownerId = result[1].owner
                    local ownerResult = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = ?', {ownerId})
                    if ownerResult and ownerResult[1] then
                        owner = string.format('%s %s', ownerResult[1].firstname or '', ownerResult[1].lastname or '')
                    end
                end
            end
            
            spawnedVehicles[plate] = {
                id = vehicle,
                entity = vehicle,
                model = modelName,
                plate = plate,
                owner = owner,
                ownerId = ownerId,
                location = string.format('Spawned (%.0f, %.0f, %.0f)', coords.x, coords.y, coords.z),
                coords = { x = coords.x, y = coords.y, z = coords.z, heading = heading },
                health = health,
                bodyHealth = math.floor(bodyHealth / 10),
                engineHealth = math.floor(engineHealth / 10),
                fuel = math.floor(fuel),
                locked = locked,
                type = modelName,
                class = className,
                spawned = true,
                impounded = false,
                stored = false,
                state = 1 -- Out
            }
        end
    end
    
    -- Get vehicles from database
    if framework == 'qb' or framework == 'qbx' then
        local dbVehicles = MySQL.query.await('SELECT * FROM player_vehicles', {})
        
        if dbVehicles then
            for _, veh in ipairs(dbVehicles) do
                -- Check if already in spawned list
                if not spawnedVehicles[veh.plate] then
                    -- Get owner name
                    local owner = 'Unknown'
                    local ownerResult = MySQL.query.await('SELECT JSON_EXTRACT(charinfo, "$.firstname") as firstname, JSON_EXTRACT(charinfo, "$.lastname") as lastname FROM players WHERE citizenid = ?', {veh.citizenid})
                    if ownerResult and ownerResult[1] then
                        owner = string.format('%s %s', ownerResult[1].firstname or '', ownerResult[1].lastname or '')
                        owner = owner:gsub('"', '')
                    end
                    
                    -- Parse mods JSON
                    local mods = {}
                    if veh.mods and veh.mods ~= '' then
                        local success, modsData = pcall(json.decode, veh.mods)
                        if success then
                            mods = {
                                engine = modsData.engine or 0,
                                transmission = modsData.transmission or 0,
                                turbo = modsData.turbo or false,
                                brakes = modsData.brakes or 0,
                                suspension = modsData.suspension or 0
                            }
                        end
                    end
                    
                    table.insert(vehicleList, {
                        id = veh.id,
                        model = veh.vehicle,
                        plate = veh.plate,
                        owner = owner,
                        ownerId = veh.citizenid,
                        citizenid = veh.citizenid,
                        location = veh.garage or 'Unknown',
                        garage = veh.garage,
                        health = 100,
                        bodyHealth = 100,
                        engineHealth = 100,
                        fuel = veh.fuel or 100,
                        locked = false,
                        type = veh.vehicle,
                        class = 'Vehicle',
                        spawned = false,
                        impounded = veh.state == 2,
                        impoundReason = veh.depotprice and veh.depotprice > 0 and 'Impounded' or nil,
                        stored = veh.state == 1,
                        state = veh.state or 1,
                        mods = mods,
                        value = 0,
                        purchaseDate = veh.created_at,
                        lastUsed = veh.last_used,
                        mileage = veh.mileage or 0
                    })
                else
                    -- Vehicle is spawned, add database info to spawned entry
                    local spawned = spawnedVehicles[veh.plate]
                    spawned.ownerId = veh.citizenid
                    spawned.garage = veh.garage
                    spawned.mileage = veh.mileage or 0
                    table.insert(vehicleList, spawned)
                    spawnedVehicles[veh.plate] = nil -- Remove from spawned list
                end
            end
        end
    elseif framework == 'esx' then
        local dbVehicles = MySQL.query.await('SELECT * FROM owned_vehicles', {})
        
        if dbVehicles then
            for _, veh in ipairs(dbVehicles) do
                if not spawnedVehicles[veh.plate] then
                    -- Get owner name
                    local owner = 'Unknown'
                    local ownerResult = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = ?', {veh.owner})
                    if ownerResult and ownerResult[1] then
                        owner = string.format('%s %s', ownerResult[1].firstname or '', ownerResult[1].lastname or '')
                    end
                    
                    -- Parse vehicle data
                    local vehicleData = json.decode(veh.vehicle)
                    
                    table.insert(vehicleList, {
                        id = veh.id,
                        model = vehicleData.model or veh.vehicle,
                        plate = veh.plate,
                        owner = owner,
                        ownerId = veh.owner,
                        location = veh.stored == 1 and 'Garage' or 'Out',
                        health = 100,
                        bodyHealth = 100,
                        engineHealth = 100,
                        fuel = 100,
                        locked = false,
                        type = vehicleData.model or veh.vehicle,
                        class = 'Vehicle',
                        spawned = false,
                        impounded = veh.stored == 2,
                        stored = veh.stored == 1,
                        state = veh.stored or 0
                    })
                else
                    table.insert(vehicleList, spawnedVehicles[veh.plate])
                    spawnedVehicles[veh.plate] = nil
                end
            end
        end
    end
    
    -- Add remaining spawned vehicles (no owner in database)
    for _, veh in pairs(spawnedVehicles) do
        table.insert(vehicleList, veh)
    end
    
    -- Calculate statistics
    local stats = {
        totalVehicles = #vehicleList,
        spawnedVehicles = 0,
        ownedVehicles = 0,
        impoundedVehicles = 0,
        totalValue = 0
    }
    
    for _, veh in ipairs(vehicleList) do
        if veh.spawned then stats.spawnedVehicles = stats.spawnedVehicles + 1 end
        if veh.ownerId then stats.ownedVehicles = stats.ownedVehicles + 1 end
        if veh.impounded then stats.impoundedVehicles = stats.impoundedVehicles + 1 end
        stats.totalValue = stats.totalValue + (veh.value or 0)
    end
    
    return {
        success = true,
        vehicles = vehicleList,
        stats = stats,
        count = #vehicleList
    }
end)

-- ============================================================================
-- SPAWN VEHICLE
-- ============================================================================
-- ✅ CANONICAL VERSION - This is the primary implementation

lib.callback.register('ec_admin:spawnVehicle', function(source, data)
    if not data.model then
        return { success = false, error = 'No vehicle model provided' }
    end

    if CheckRateLimit and not CheckRateLimit(source, 'ec_admin:spawnVehicle') then
        return { success = false, error = 'Rate limit exceeded' }
    end

    -- Validate vehicle model (basic check)
    local model = tostring(data.model)
    if not model or model == '' then
        return { success = false, error = 'Invalid vehicle model' }
    end
    
    -- Check if player exists
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        return { success = false, error = 'Player not found' }
    end
    
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Spawn vehicle in front of player
    local forwardVector = GetEntityForwardVector(ped)
    local spawnCoords = vector3(
        coords.x + forwardVector.x * 5,
        coords.y + forwardVector.y * 5,
        coords.z
    )
    
    TriggerClientEvent('ec_admin:client:spawnVehicle', source, {
        model = model,
        coords = spawnCoords,
        heading = heading
    })
    
    return { success = true, message = 'Vehicle spawned: ' .. model }
end)

-- ============================================================================
-- DELETE VEHICLE
-- ============================================================================

RegisterNetEvent('ec_admin:deleteVehicle', function(data)
    local src = source

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:deleteVehicle') then
        return
    end

    if data.vehicleId then
        -- Delete by entity ID (spawned vehicle)
        if DoesEntityExist(data.vehicleId) then
            DeleteEntity(data.vehicleId)
            TriggerClientEvent('ec_admin:notification', src, 'Vehicle deleted', 'success')
        end
    elseif data.plate then
        -- Delete from database and world
        local vehicles = GetAllVehicles()
        for _, veh in ipairs(vehicles) do
            if GetVehicleNumberPlateText(veh) == data.plate then
                DeleteEntity(veh)
                break
            end
        end
        TriggerClientEvent('ec_admin:notification', src, 'Vehicle deleted', 'success')
    end
end)

-- ============================================================================
-- REPAIR VEHICLE
-- ============================================================================

RegisterNetEvent('ec_admin:repairVehicle', function(data)
    local src = source
    
    if data.vehicleId then
        TriggerClientEvent('ec_admin:client:repairVehicle', src, data.vehicleId)
    end
end)

-- ============================================================================
-- REFUEL VEHICLE
-- ============================================================================

RegisterNetEvent('ec_admin:refuelVehicle', function(data)
    local src = source
    
    if data.vehicleId then
        TriggerClientEvent('ec_admin:client:refuelVehicle', src, data.vehicleId)
    end
end)

-- ============================================================================
-- TOGGLE VEHICLE LOCK
-- ============================================================================

RegisterNetEvent('ec_admin:toggleVehicleLock', function(data)
    local src = source
    
    if data.vehicleId then
        TriggerClientEvent('ec_admin:client:toggleLock', src, data.vehicleId)
    end
end)

-- ============================================================================
-- IMPOUND VEHICLE
-- ============================================================================

RegisterNetEvent('ec_admin:impoundVehicle', function(data)
    local src = source
    local framework, Core = GetFramework()
    
    if not data.plate then
        return
    end
    
    -- Update database
    if framework == 'qb' or framework == 'qbx' then
        MySQL.update('UPDATE player_vehicles SET state = 2, depotprice = ? WHERE plate = ?', {
            data.price or 1000,
            data.plate
        })
    elseif framework == 'esx' then
        MySQL.update('UPDATE owned_vehicles SET stored = 2 WHERE plate = ?', {data.plate})
    end
    
    -- Delete vehicle from world
    local vehicles = GetAllVehicles()
    for _, veh in ipairs(vehicles) do
        if GetVehicleNumberPlateText(veh) == data.plate then
            DeleteEntity(veh)
            break
        end
    end
    
    TriggerClientEvent('ec_admin:notification', src, 'Vehicle impounded', 'success')
end)

-- ============================================================================
-- UNIMPOUND VEHICLE
-- ============================================================================

RegisterNetEvent('ec_admin:unimpoundVehicle', function(data)
    local src = source
    local framework, Core = GetFramework()
    
    if not data.plate then
        return
    end
    
    -- Update database
    if framework == 'qb' or framework == 'qbx' then
        MySQL.update('UPDATE player_vehicles SET state = 1, depotprice = 0 WHERE plate = ?', {data.plate})
    elseif framework == 'esx' then
        MySQL.update('UPDATE owned_vehicles SET stored = 1 WHERE plate = ?', {data.plate})
    end
    
    TriggerClientEvent('ec_admin:notification', src, 'Vehicle unimpounded', 'success')
end)

-- ============================================================================
-- TELEPORT TO VEHICLE
-- ============================================================================

RegisterNetEvent('ec_admin:teleportToVehicle', function(data)
    local src = source
    
    if data.coords then
        TriggerClientEvent('ec_admin:client:teleportToCoords', src, data.coords)
    end
end)

Logger.Info('Vehicles callbacks loaded successfully', '✅')