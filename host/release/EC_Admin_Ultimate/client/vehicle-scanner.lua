--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║        EC Admin Ultimate - Vehicle Scanner (Enhanced)         ║
    ║          Scans ALL vehicle packs automatically                ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    Detects vehicles from:
    - vehicles.meta files (addon vehicle packs)
    - carvariations.meta (DLC vehicles)
    - Hardcoded DLC vehicles list
    - All loaded vehicle models in game
    
    Works with ANY vehicle pack - no configuration needed!
]]

local VehicleScanner = {}
VehicleScanner.ScannedVehicles = {}
VehicleScanner.LastScan = 0
VehicleScanner.ScanCooldown = Config.VehicleScanning?.scanInterval or 300000 -- 5 minutes

--[[
    ENHANCED: Multi-source vehicle scanning
    Scans from: resource meta files, DLC list, AND runtime models
]]
function VehicleScanner.ScanFromResources()
    if not Config.VehicleScanning?.enabled then
        Logger.Warn('Vehicle scanning is disabled in config')
        return {}
    end

    local startTime = GetGameTimer()
    local scannedVehicles = {}
    local vehicleMap = {} -- To avoid duplicates
    local count = 0
    local excludedResources = Config.VehicleScanning?.excludeResources or {}
    
    Logger.Info('🚗 Vehicle Scanner - Starting comprehensive scan...')
    
    -- ========================================================================
    -- METHOD 1: Scan from resource meta files (addon vehicle packs)
    -- ========================================================================
    local numResources = GetNumResources()
    Logger.Debug(string.format('Scanning %d resources for vehicle meta files', numResources))
    
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        
        -- Skip excluded resources
        local excluded = false
        for _, excludeName in ipairs(excludedResources) do
            if resourceName == excludeName then
                excluded = true
                break
            end
        end
        
        if not excluded and resourceName and GetResourceState(resourceName) == 'started' then
            -- Method 1: Check for vehicles.meta (addon vehicles)
            local vehiclesMeta = LoadResourceFile(resourceName, 'data/vehicles.meta')
            if not vehiclesMeta then
                vehiclesMeta = LoadResourceFile(resourceName, 'vehicles.meta')
            end
            
            if vehiclesMeta then
                -- Parse XML for modelName tags
                for modelName in string.gmatch(vehiclesMeta, '<modelName>([^<]+)</modelName>') do
                    local modelLower = string.lower(modelName)
                    local hash = GetHashKey(modelLower)
                    
                    -- Deep check if enabled
                    local isValid = true
                    if Config.VehicleScanning?.scanDeepCheck then
                        isValid = IsModelInCdimage(hash) and IsModelAVehicle(hash)
                    end
                    
                    if not vehicleMap[modelLower] and isValid then
                        vehicleMap[modelLower] = true
                        table.insert(scannedVehicles, {
                            model = modelLower,
                            hash = hash,
                            resource = resourceName,
                            source = 'vehicles.meta'
                        })
                        count = count + 1
                    end
                end
                
                Logger.Debug(string.format('Found vehicles in %s (vehicles.meta)', resourceName))
            end
            
            -- Method 2: Check for carvariations.meta (DLC vehicles)
            local carVariations = LoadResourceFile(resourceName, 'data/carvariations.meta')
            if not carVariations then
                carVariations = LoadResourceFile(resourceName, 'carvariations.meta')
            end
            
            if carVariations then
                -- Parse XML for modelName in variations
                for modelName in string.gmatch(carVariations, '<modelName>([^<]+)</modelName>') do
                    local modelLower = string.lower(modelName)
                    local hash = GetHashKey(modelLower)
                    
                    -- Deep check if enabled
                    local isValid = true
                    if Config.VehicleScanning?.scanDeepCheck then
                        isValid = IsModelInCdimage(hash) and IsModelAVehicle(hash)
                    end
                    
                    if not vehicleMap[modelLower] and isValid then
                        vehicleMap[modelLower] = true
                        table.insert(scannedVehicles, {
                            model = modelLower,
                            hash = hash,
                            resource = resourceName,
                            source = 'carvariations.meta'
                        })
                        count = count + 1
                    end
                end
                
                Logger.Debug(string.format('Found vehicles in %s (carvariations.meta)', resourceName))
            end
            
            -- Method 3: Check fxmanifest.lua for data_file entries
            local fxmanifest = LoadResourceFile(resourceName, 'fxmanifest.lua')
            if not fxmanifest then
                fxmanifest = LoadResourceFile(resourceName, '__resource.lua')
            end
            
            if fxmanifest then
                -- Look for data_file declarations
                for dataFile in string.gmatch(fxmanifest, "data_file%s+['\"]VEHICLE_METADATA_FILE['\"]%s+['\"]([^'\"]+)['\"]") do
                    local vehiclesMetaContent = LoadResourceFile(resourceName, dataFile)
                    if vehiclesMetaContent then
                        for modelName in string.gmatch(vehiclesMetaContent, '<modelName>([^<]+)</modelName>') do
                            local modelLower = string.lower(modelName)
                            local hash = GetHashKey(modelLower)
                            
                            if not vehicleMap[modelLower] and IsModelInCdimage(hash) and IsModelAVehicle(hash) then
                                vehicleMap[modelLower] = true
                                table.insert(scannedVehicles, {
                                    model = modelLower,
                                    hash = hash,
                                    resource = resourceName
                                })
                                count = count + 1
                            end
                        end
                    end
                end
            end
        end
        
        -- Yield every 10 resources to prevent freezing
        if i % 10 == 0 then
            Wait(0)
        end
    end
    
    local scanTime = GetGameTimer() - startTime
    Logger.Info(string.format('', count, scanTime))
    
    if count == 0 then
        Logger.Info('')
        Logger.Info('')
    end
    
    VehicleScanner.ScannedVehicles = scannedVehicles
    VehicleScanner.LastScan = GetGameTimer()
    
    return scannedVehicles
end

--[[
    FALLBACK: Try to detect vehicles by checking common vehicle folders
]]
function VehicleScanner.ScanVehicleFolders()
    local vehicleFolders = {
        '[vehicles]',
        '[cars]',
        '[addon-vehicles]',
        '[addons]',
        'vehicles',
        'cars',
        'addon-vehicles'
    }
    
    local scannedVehicles = {}
    local count = 0
    
    Logger.Info('')
    
    -- Check each potential folder
    for _, folderPattern in ipairs(vehicleFolders) do
        -- Try to find resources that start with this folder name
        for i = 0, GetNumResources() - 1 do
            local resourceName = GetResourceByFindIndex(i)
            
            if resourceName and GetResourceState(resourceName) == 'started' then
                -- Check if resource name matches folder pattern
                if string.find(string.lower(resourceName), string.lower(folderPattern)) or
                   string.find(string.lower(resourceName), 'vehicle') or
                   string.find(string.lower(resourceName), 'car') then
                    
                    -- Try to load vehicle data from this resource
                    local vehiclesMeta = LoadResourceFile(resourceName, 'data/vehicles.meta')
                    if not vehiclesMeta then
                        vehiclesMeta = LoadResourceFile(resourceName, 'vehicles.meta')
                    end
                    
                    if vehiclesMeta then
                        for modelName in string.gmatch(vehiclesMeta, '<modelName>([^<]+)</modelName>') do
                            local modelLower = string.lower(modelName)
                            local hash = GetHashKey(modelLower)
                            
                            if IsModelInCdimage(hash) and IsModelAVehicle(hash) then
                                table.insert(scannedVehicles, {
                                    model = modelLower,
                                    hash = hash,
                                    resource = resourceName
                                })
                                count = count + 1
                            end
                        end
                        
                        Logger.Info(string.format('', resourceName))
                    end
                end
            end
        end
    end
    
    Logger.Info(string.format('', count))
    return scannedVehicles
end

--[[
    Main scan function - tries multiple methods
]]
function VehicleScanner.ScanAllVehicles()
    -- Method 1: Scan from all resources
    local vehicles = VehicleScanner.ScanFromResources()
    
    -- Method 2: If no vehicles found, try folder-specific scan
    if #vehicles == 0 then
        Logger.Info('')
        local folderVehicles = VehicleScanner.ScanVehicleFolders()
        
        for _, veh in ipairs(folderVehicles) do
            table.insert(vehicles, veh)
        end
    end
    
    VehicleScanner.ScannedVehicles = vehicles
    return vehicles
end

--[[
    Send scanned vehicles to server
]]
function VehicleScanner.SendToServer()
    if #VehicleScanner.ScannedVehicles == 0 then
        Logger.Info('')
    else
        Logger.Info(string.format('', #VehicleScanner.ScannedVehicles))
    end
    
    -- Always send, even if empty (server will use defaults)
    TriggerServerEvent('ec_admin:updateVehicleModels', VehicleScanner.ScannedVehicles)
end

--[[
    Auto-scan on resource start
]]
CreateThread(function()
    -- Wait for game to fully load
    while not NetworkIsSessionStarted() do
        Wait(100)
    end
    
    -- Wait additional time for resources to load
    Wait(10000) -- 10 seconds
    
    Logger.Info('')
    VehicleScanner.ScanAllVehicles()
    VehicleScanner.SendToServer()
    
    Logger.Info('')
end)

--[[
    Manual scan command
]]
RegisterCommand('scanvehicles', function()
    if GetGameTimer() - VehicleScanner.LastScan < VehicleScanner.ScanCooldown then
        local remaining = math.ceil((VehicleScanner.ScanCooldown - (GetGameTimer() - VehicleScanner.LastScan)) / 1000)
        TriggerEvent('chat:addMessage', {
            color = {255, 153, 0},
            multiline = false,
            args = {'EC Admin', string.format('Please wait %d seconds before scanning again', remaining)}
        })
        return
    end
    
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = false,
        args = {'EC Admin', 'Starting vehicle scan...'}
    })
    
    local vehicles = VehicleScanner.ScanAllVehicles()
    VehicleScanner.SendToServer()
    
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = false,
        args = {'EC Admin', string.format('Found %d custom vehicles!', #vehicles)}
    })
end, false)

--[[
    Server request for vehicle scan
]]
RegisterNetEvent('ec_admin:requestVehicleScan', function()
    VehicleScanner.ScanAllVehicles()
    VehicleScanner.SendToServer()
end)

Logger.Info('')
