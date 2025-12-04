--[[
    EC Admin Ultimate - Vehicle Pack Detector
    Detects all vehicles (default + custom car packs) on the server
    IMPROVED: Now uses client-side scanning for ALL loaded vehicle models
]]

Logger.Info('')

VehiclePackDetector = {}
VehiclePackDetector.CustomVehicles = {}
VehiclePackDetector.AllVehicles = {} -- ALL vehicles (default + custom)
VehiclePackDetector.LastScan = 0
VehiclePackDetector.ScanInterval = 300000 -- 5 minutes
VehiclePackDetector.VehicleModels = {} -- Hash map for faster lookups
VehiclePackDetector.ScannedModels = {} -- Models scanned from client

--[[
    Receive scanned vehicles from client
    Clients scan ALL vehicle models and send them to server
]]
RegisterNetEvent('ec_admin:updateVehicleModels', function(vehicles)
    local source = source
    
    if not vehicles or type(vehicles) ~= 'table' then
        Logger.Info(string.format('', source))
        return
    end
    
    Logger.Info(string.format('', #vehicles, source))
    
    -- Merge with existing scanned models
    for _, vehicle in ipairs(vehicles) do
        local modelLower = string.lower(vehicle.model)
        if not VehiclePackDetector.ScannedModels[modelLower] then
            VehiclePackDetector.ScannedModels[modelLower] = {
                model = vehicle.model,
                hash = vehicle.hash,
                resource = vehicle.resource
            }
        end
    end
    
    -- Trigger a re-scan to categorize vehicles
    VehiclePackDetector.ProcessScannedVehicles()
end)

--[[
    Process scanned vehicles from clients
    Categorize them as default or custom
]]
function VehiclePackDetector.ProcessScannedVehicles()
    local startTime = GetGameTimer()
    local customVehicles = {}
    local allVehicles = {}
    
    -- Get default vehicle list
    local defaultVehicles = {}
    local defaultList = VehicleDatabase.GetAllVehicles()
    for _, vehicle in ipairs(defaultList) do
        defaultVehicles[string.lower(vehicle.model)] = true
    end
    
    -- ALWAYS add default vehicles to allVehicles first
    for _, vehicle in ipairs(defaultList) do
        table.insert(allVehicles, {
            model = vehicle.model,
            name = vehicle.name,
            hash = GetHashKey(vehicle.model),
            resource = 'default',
            isCustom = false,
            class = vehicle.class
        })
    end
    
    -- Add custom scanned vehicles
    for modelLower, vehicleData in pairs(VehiclePackDetector.ScannedModels) do
        -- Only add if not already in default list
        if not defaultVehicles[modelLower] then
            local vehicleInfo = {
                model = vehicleData.model,
                name = VehiclePackDetector.FormatVehicleName(vehicleData.model),
                hash = vehicleData.hash,
                resource = vehicleData.resource,
                isCustom = true,
                class = 'custom'
            }
            
            table.insert(allVehicles, vehicleInfo)
            table.insert(customVehicles, vehicleInfo)
        end
    end
    
    VehiclePackDetector.CustomVehicles = customVehicles
    VehiclePackDetector.AllVehicles = allVehicles
    VehiclePackDetector.LastScan = GetGameTimer()
    
    local scanTime = GetGameTimer() - startTime
    Logger.Info(string.format('', 
        #allVehicles, #defaultList, #customVehicles, scanTime))
    
    return {
        totalCount = #allVehicles,
        defaultCount = #defaultList,
        customCount = #customVehicles,
        scanTime = scanTime
    }
end

--[[
    Format vehicle name from model
    Example: "adder" -> "Adder", "police2" -> "Police 2"
]]
function VehiclePackDetector.FormatVehicleName(model)
    if not model then return 'Unknown' end
    
    -- Capitalize first letter
    local name = string.upper(string.sub(model, 1, 1)) .. string.sub(model, 2)
    
    -- Add spaces before numbers
    name = string.gsub(name, '(%d+)', ' %1')
    
    return name
end

--[[
    Get all vehicles (default + custom)
]]
function VehiclePackDetector.GetAllAvailableVehicles()
    -- Check if we need to rescan
    if GetGameTimer() - VehiclePackDetector.LastScan > VehiclePackDetector.ScanInterval then
        VehiclePackDetector.ProcessScannedVehicles()
    end
    
    return VehiclePackDetector.AllVehicles
end

--[[
    Search vehicles (default + custom)
]]
function VehiclePackDetector.SearchVehicles(query)
    local allVehicles = VehiclePackDetector.GetAllAvailableVehicles()
    
    if not query or query == '' then
        return allVehicles
    end
    
    local results = {}
    local lowerQuery = string.lower(query)
    
    for _, vehicle in ipairs(allVehicles) do
        if string.find(string.lower(vehicle.model), lowerQuery) or
           string.find(string.lower(vehicle.name), lowerQuery) then
            table.insert(results, vehicle)
        end
    end
    
    return results
end

--[[
    Get vehicles by class (including custom)
]]
function VehiclePackDetector.GetVehiclesByClass(className)
    local allVehicles = VehiclePackDetector.GetAllAvailableVehicles()
    local results = {}
    
    for _, vehicle in ipairs(allVehicles) do
        if vehicle.class == className then
            table.insert(results, vehicle)
        end
    end
    
    return results
end

-- Initial scan on resource start
CreateThread(function()
    Wait(5000) -- Wait 5 seconds for other resources to load
    VehiclePackDetector.ProcessScannedVehicles()
end)

-- Periodic rescan every 5 minutes
CreateThread(function()
    while true do
        Wait(VehiclePackDetector.ScanInterval)
        VehiclePackDetector.ProcessScannedVehicles()
    end
end)

-- Callback to get all available vehicles
lib.callback.register('ec_admin:getAllVehicles', function(source, data)
    local query = data.query or ''
    local className = data.class or nil
    
    local vehicles
    
    if className and className ~= 'all' then
        vehicles = VehiclePackDetector.GetVehiclesByClass(className)
    elseif query and query ~= '' then
        vehicles = VehiclePackDetector.SearchVehicles(query)
    else
        vehicles = VehiclePackDetector.GetAllAvailableVehicles()
    end
    
    return {
        success = true,
        vehicles = vehicles,
        totalCount = #vehicles,
        customCount = #VehiclePackDetector.CustomVehicles,
        lastScan = VehiclePackDetector.LastScan
    }
end)

-- Command to manually trigger vehicle scan
RegisterCommand('scanvehicles', function(source, args, rawCommand)
    if source > 0 then
        -- Check if player has admin permission
        if not EC_Perms or not EC_Perms.Has(source, 'admin') then
            return
        end
    end
    
    local result = VehiclePackDetector.ProcessScannedVehicles()
    
    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = true,
            args = {'EC Admin', string.format('Vehicle scan complete! Found %d custom vehicles in %dms', result.customCount, result.scanTime)}
        })
    else
        Logger.Info(string.format('', result.customCount, result.scanTime))
    end
end, false)

Logger.Info('')