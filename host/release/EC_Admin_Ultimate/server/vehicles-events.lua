--[[
    EC Admin Ultimate - Vehicles Server Events
    Server-side implementation for vehicle actions
    Framework Support: QB-Core, QBX, ESX
]]

Logger.Info('')

-- Cache for performance
local vehicleCache = {
    lastUpdate = 0,
    data = nil,
    updateInterval = 5000
}

--[[ Helper: Get framework ]]
local function GetFramework()
    if GetResourceState('qbx_core') == 'started' then
        return 'qbx', exports['qbx_core']:GetCoreObject()
    elseif GetResourceState('qb-core') == 'started' then
        return 'qb', exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx', exports['es_extended']:getSharedObject()
    end
    return nil, nil
end

--[[ Helper: Check admin permission ]]
local function HasPermission(src, permission)
    -- Prefer the centralized permissions module if it has been initialized
    if _G.ECPermissions and _G.ECPermissions.HasPermission then
        return _G.ECPermissions.HasPermission(src, permission) or
               _G.ECPermissions.HasPermission(src, 'admin')
    end

    -- Fall back to the resource export (defined in server/main.lua)
    local exportsResource = exports[GetCurrentResourceName()]
    if exportsResource and type(exportsResource.HasPermission) == 'function' then
        local ok, result = pcall(exportsResource.HasPermission, src, permission)
        if ok and result then
            return true
        end
    end

    -- Final fallback to ACE permissions
    return IsPlayerAceAllowed(src, 'ec_admin.' .. permission) or IsPlayerAceAllowed(src, 'ec_admin.all')
end

--[[ Helper: Get location name ]]
local function GetLocationName(coords)
    if not coords then return 'Unknown' end
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    return streetName or 'Unknown'
end

--[[ Helper: Get spawned vehicles data ]]
local function GetSpawnedVehiclesData()
    local spawnedData = {}
    local vehicles = GetAllVehicles()
    
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local plate = GetVehicleNumberPlateText(vehicle)
            if plate then
                plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
                local coords = GetEntityCoords(vehicle)
                spawnedData[plate] = {
                    entity = vehicle,
                    coords = coords,
                    location = GetLocationName(coords),
                    health = math.floor((GetVehicleBodyHealth(vehicle) / 1000) * 100),
                    engineHealth = GetVehicleEngineHealth(vehicle),
                    bodyHealth = GetVehicleBodyHealth(vehicle),
                    fuel = GetVehicleFuelLevel(vehicle) or 0
                }
            end
        end
    end
    
    return spawnedData
end

--[[ Event: Spawn Vehicle ]]
RegisterNetEvent('ec:vehicles:spawn', function(data)
    local src = source

    if type(data) ~= 'table' then
        return
    end
    
    if not HasPermission(src, 'vehicles.spawn') then
        Logger.Info('Unauthorized vehicle spawn attempt from player ' .. src)
        TriggerClientEvent('ec:notify', src, {
            title = 'Access Denied',
            description = 'You do not have permission to spawn vehicles',
            type = 'error'
        })
        return
    end
    
    local model = data.model
    local targetPlayerId = data.targetPlayerId or src

    if not model or model == '' then
        TriggerClientEvent('ec:notify', src, {
            title = 'Invalid Vehicle',
            description = 'Vehicle model is missing or invalid',
            type = 'error'
        })
        return
    end
    
    Logger.Info(string.format('', 
        src, model, targetPlayerId))
    
    -- Trigger client-side spawn for the target player
    TriggerClientEvent('ec:vehicles:doSpawn', targetPlayerId, {
        model = model,
        coords = data.coords,
        heading = data.heading
    })
    
    -- Log the action
    TriggerEvent('ec:log', {
        action = 'vehicle_spawn',
        admin = src,
        target = targetPlayerId,
        data = { model = model }
    })
end)

--[[ Event: Delete Vehicle ]]
RegisterNetEvent('ec:vehicles:delete', function(data)
    local src = source

    if type(data) ~= 'table' then
        return
    end
    
    if not HasPermission(src, 'vehicles.delete') then
        Logger.Info('Unauthorized vehicle delete attempt from player ' .. src)
        return
    end
    
    local plate = data.plate
    local spawnedVehicles = GetSpawnedVehiclesData()
    
    if spawnedVehicles[plate] then
        local vehicle = spawnedVehicles[plate].entity
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
            Logger.Info(string.format('', src, plate))
            
            TriggerClientEvent('ec:notify', src, {
                title = 'Vehicle Deleted',
                description = 'Vehicle ' .. plate .. ' has been deleted',
                type = 'success'
            })
        end
    else
        TriggerClientEvent('ec:notify', src, {
            title = 'Vehicle Not Found',
            description = 'Could not find vehicle with plate ' .. plate,
            type = 'error'
        })
    end
end)

--[[ Event: Impound Vehicle ]]
RegisterNetEvent('ec:vehicles:impound', function(data)
    local src = source

    if type(data) ~= 'table' then
        return
    end
    
    if not HasPermission(src, 'vehicles.impound') then
        return
    end
    
    local plate = data.plate
    if not plate or plate == '' then
        return
    end

    local fwType, fw = GetFramework()
    
    if not fw then
        TriggerClientEvent('ec:notify', src, {
            title = 'Error',
            description = 'No compatible framework detected',
            type = 'error'
        })
        return
    end
    
    -- Update database to set vehicle as impounded
    if not MySQL or not MySQL.Async or type(MySQL.Async.execute) ~= 'function' then
        TriggerClientEvent('ec:notify', src, {
            title = 'Database Error',
            description = 'Database connection is not available',
            type = 'error'
        })
        return
    end

    if fwType == 'qbx' or fwType == 'qb' then
        MySQL.Async.execute('UPDATE player_vehicles SET state = ? WHERE plate = ?', {0, plate})
    elseif fwType == 'esx' then
        MySQL.Async.execute('UPDATE owned_vehicles SET stored = ? WHERE plate = ?', {0, plate})
    end
    
    -- Delete the physical vehicle
    local spawnedVehicles = GetSpawnedVehiclesData()
    if spawnedVehicles[plate] then
        local vehicle = spawnedVehicles[plate].entity
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    
    Logger.Info(string.format('', src, plate))
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Vehicle Impounded',
        description = 'Vehicle ' .. plate .. ' has been impounded',
        type = 'success'
    })
end)

--[[ Event: Repair Vehicle ]]
RegisterNetEvent('ec:vehicles:repair', function(data)
    local src = source

    if not HasPermission(src, 'vehicles.repair') then
        return
    end

    if type(data) ~= 'table' then
        return
    end
    
    local plate = data.plate
    local spawnedVehicles = GetSpawnedVehiclesData()
    
    if spawnedVehicles[plate] then
        local vehicle = spawnedVehicles[plate].entity
        if DoesEntityExist(vehicle) then
            SetVehicleFixed(vehicle)
            SetVehicleDeformationFixed(vehicle)
            SetVehicleUndriveable(vehicle, false)
            SetVehicleEngineOn(vehicle, true, true, false)
            
            Logger.Info(string.format('', src, plate))
            
            TriggerClientEvent('ec:notify', src, {
                title = 'Vehicle Repaired',
                description = 'Vehicle ' .. plate .. ' has been fully repaired',
                type = 'success'
            })
        end
    end
end)

--[[ Event: Get Vehicles List ]]
RegisterNetEvent('ec:vehicles:list', function(data)
    local src = source

    if not HasPermission(src, 'vehicles.view') then
        return
    end

    local fwType, fw = GetFramework()
    local vehicles = {}

    if not MySQL or not MySQL.Sync or type(MySQL.Sync.fetchAll) ~= 'function' then
        TriggerClientEvent('ec:notify', src, {
            title = 'Database Error',
            description = 'Database connection is not available',
            type = 'error'
        })
        return
    end
    
    if fwType == 'qbx' or fwType == 'qb' then
        local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles', {})
        
        for _, veh in ipairs(result) do
            table.insert(vehicles, {
                plate = veh.plate,
                model = veh.vehicle,
                owner = veh.citizenid,
                state = veh.state,
                garage = veh.garage,
                fuel = veh.fuel,
                engine = veh.engine,
                body = veh.body
            })
        end
    elseif fwType == 'esx' then
        local result = MySQL.Sync.fetchAll('SELECT * FROM owned_vehicles', {})
        
        for _, veh in ipairs(result) do
            table.insert(vehicles, {
                plate = veh.plate,
                model = json.decode(veh.vehicle).model,
                owner = veh.owner,
                state = veh.stored,
                garage = veh.parking
            })
        end
    end
    
    -- Send data back to client
    TriggerClientEvent('ec:vehicles:listResponse', src, vehicles)
end)

--[[ Event: Transfer Vehicle ]]
RegisterNetEvent('ec:vehicles:transfer', function(data)
    local src = source

    if not HasPermission(src, 'vehicles.transfer') then
        return
    end

    if type(data) ~= 'table' then
        return
    end

    local plate = data.plate
    local targetIdentifier = data.targetIdentifier
    local fwType, fw = GetFramework()

    if not MySQL or not MySQL.Async or type(MySQL.Async.execute) ~= 'function' then
        TriggerClientEvent('ec:notify', src, {
            title = 'Database Error',
            description = 'Database connection is not available',
            type = 'error'
        })
        return
    end
    
    if fwType == 'qbx' or fwType == 'qb' then
        MySQL.Async.execute('UPDATE player_vehicles SET citizenid = ? WHERE plate = ?', 
            {targetIdentifier, plate})
    elseif fwType == 'esx' then
        MySQL.Async.execute('UPDATE owned_vehicles SET owner = ? WHERE plate = ?', 
            {targetIdentifier, plate})
    end
    
    Logger.Info(string.format('', 
        src, plate, targetIdentifier))
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Vehicle Transferred',
        description = 'Vehicle ownership transferred successfully',
        type = 'success'
    })
end)

Logger.Info('')
