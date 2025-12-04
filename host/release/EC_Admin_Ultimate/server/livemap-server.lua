--[[
    EC Admin Ultimate - Livemap Real-Time Tracking System
    Real-time player location tracking, heatmaps, and activity zones
    Features: Player tracking, heatmap generation, zone detection, activity analysis
    Generated: December 4, 2025
]]

Logger.Success('📍 Initializing Livemap Real-Time Tracking System')

-- =============================================================================
-- LIVEMAP TRACKING ENGINE
-- =============================================================================

local LivemapSystem = {
    activeTracking = {},
    playerLocations = {},
    heatmapData = {},
    activityZones = {},
    config = {
        updateInterval = 1000,      -- Update every 1 second
        locationHistory = 100,      -- Keep 100 location samples
        heatmapCellSize = 50,       -- 50x50 meter cells
        activityThreshold = 10      -- Min 10 events for activity zone
    }
}

-- =============================================================================
-- PLAYER TRACKING
-- =============================================================================

-- Track player location
local function TrackPlayerLocation(playerId, coords)
    if not LivemapSystem.playerLocations[playerId] then
        LivemapSystem.playerLocations[playerId] = {
            history = {},
            current = coords,
            lastUpdate = os.time(),
            totalDistance = 0.0
        }
    end
    
    local player = LivemapSystem.playerLocations[playerId]
    
    -- Calculate distance traveled
    if player.current then
        local dx = coords.x - player.current.x
        local dy = coords.y - player.current.y
        local dz = coords.z - player.current.z
        local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
        player.totalDistance = player.totalDistance + distance
    end
    
    -- Update current location
    player.current = coords
    player.lastUpdate = os.time()
    
    -- Keep location history
    table.insert(player.history, coords)
    if #player.history > LivemapSystem.config.locationHistory then
        table.remove(player.history, 1)
    end
    
    return player
end

-- Get player trail (movement history)
local function GetPlayerTrail(playerId)
    local player = LivemapSystem.playerLocations[playerId]
    if not player then return nil end
    
    return {
        playerId = playerId,
        currentLocation = player.current,
        history = player.history,
        totalDistance = player.totalDistance,
        lastUpdate = player.lastUpdate
    }
end

-- =============================================================================
-- HEATMAP GENERATION
-- =============================================================================

-- Convert coordinates to heatmap cell
local function GetHeatmapCell(coords)
    local cellSize = LivemapSystem.config.heatmapCellSize
    local cellX = math.floor(coords.x / cellSize)
    local cellY = math.floor(coords.y / cellSize)
    return cellX .. '_' .. cellY
end

-- Update heatmap data
local function UpdateHeatmapData(playerId, coords)
    local cell = GetHeatmapCell(coords)
    
    if not LivemapSystem.heatmapData[cell] then
        LivemapSystem.heatmapData[cell] = {
            cell = cell,
            x = math.floor(coords.x / LivemapSystem.config.heatmapCellSize) * LivemapSystem.config.heatmapCellSize,
            y = math.floor(coords.y / LivemapSystem.config.heatmapCellSize) * LivemapSystem.config.heatmapCellSize,
            intensity = 0,
            players = {},
            lastUpdate = os.time()
        }
    end
    
    local cellData = LivemapSystem.heatmapData[cell]
    cellData.intensity = cellData.intensity + 1
    cellData.players[playerId] = true
    cellData.lastUpdate = os.time()
end

-- Generate heatmap image data
local function GenerateHeatmapData()
    local heatmap = {}
    
    for cell, data in pairs(LivemapSystem.heatmapData) do
        local intensity = math.min(255, data.intensity * 25)  -- Scale intensity to 0-255
        table.insert(heatmap, {
            x = data.x,
            y = data.y,
            intensity = intensity,
            playerCount = table.getn(data.players),
            color = {
                r = math.floor(intensity),
                g = math.floor(255 - intensity),
                b = 0,
                a = math.floor(intensity * 0.6)
            }
        })
    end
    
    return heatmap
end

-- =============================================================================
-- ACTIVITY ZONES
-- =============================================================================

-- Detect activity zones (clusters of player activity)
local function DetectActivityZones()
    local zones = {}
    local cellClusters = {}
    
    -- Group cells by proximity
    for cell, data in pairs(LivemapSystem.heatmapData) do
        local zoneFound = false
        
        for _, zone in ipairs(cellClusters) do
            -- Check if cell is adjacent to any cell in zone
            for _, existingCell in ipairs(zone.cells) do
                local parts = string.split(cell, '_')
                local existingParts = string.split(existingCell, '_')
                local distance = math.abs(tonumber(parts[1]) - tonumber(existingParts[1])) +
                                 math.abs(tonumber(parts[2]) - tonumber(existingParts[2]))
                
                if distance <= 2 then  -- Adjacent cells
                    table.insert(zone.cells, cell)
                    zone.intensity = zone.intensity + data.intensity
                    zone.playerCount = zone.playerCount + table.getn(data.players)
                    zoneFound = true
                    break
                end
            end
            
            if zoneFound then break end
        end
        
        if not zoneFound then
            table.insert(cellClusters, {
                cells = { cell },
                intensity = data.intensity,
                playerCount = table.getn(data.players),
                data = data
            })
        end
    end
    
    -- Convert clusters to zones
    for i, cluster in ipairs(cellClusters) do
        if cluster.intensity >= LivemapSystem.config.activityThreshold then
            table.insert(zones, {
                id = i,
                x = cluster.data.x,
                y = cluster.data.y,
                intensity = cluster.intensity,
                playerCount = cluster.playerCount,
                cellCount = #cluster.cells,
                radius = math.sqrt(#cluster.cells) * LivemapSystem.config.heatmapCellSize
            })
        end
    end
    
    LivemapSystem.activityZones = zones
    return zones
end

-- =============================================================================
-- CLIENT EVENTS
-- =============================================================================

-- Start tracking player
RegisterNetEvent('ec_admin_ultimate:server:startPlayerTracking', function(targetPlayerId)
    local src = source
    local target = tonumber(targetPlayerId)
    
    if not target or GetPlayerName(target) == nil then
        TriggerClientEvent('ec_admin_ultimate:client:trackingResponse', src, {
            success = false,
            message = 'Player not found'
        })
        return
    end
    
    LivemapSystem.activeTracking[src] = target
    
    TriggerClientEvent('ec_admin_ultimate:client:trackingResponse', src, {
        success = true,
        message = 'Tracking started for ' .. GetPlayerName(target),
        targetId = target
    })
end)

-- Stop tracking
RegisterNetEvent('ec_admin_ultimate:server:stopPlayerTracking', function()
    local src = source
    LivemapSystem.activeTracking[src] = nil
    
    TriggerClientEvent('ec_admin_ultimate:client:trackingResponse', src, {
        success = true,
        message = 'Tracking stopped'
    })
end)

-- Get heatmap data
RegisterNetEvent('ec_admin_ultimate:server:getHeatmapData', function()
    local src = source
    local heatmap = GenerateHeatmapData()
    
    TriggerClientEvent('ec_admin_ultimate:client:heatmapUpdate', src, heatmap)
end)

-- Get activity zones
RegisterNetEvent('ec_admin_ultimate:server:getActivityZones', function()
    local src = source
    local zones = DetectActivityZones()
    
    TriggerClientEvent('ec_admin_ultimate:client:activityZonesUpdate', src, zones)
end)

-- Get player trail
RegisterNetEvent('ec_admin_ultimate:server:getPlayerTrail', function(playerId)
    local src = source
    local trail = GetPlayerTrail(tonumber(playerId))
    
    if trail then
        TriggerClientEvent('ec_admin_ultimate:client:playerTrailUpdate', src, trail)
    else
        TriggerClientEvent('ec_admin_ultimate:client:playerTrailUpdate', src, nil)
    end
end)

-- Get all player locations
RegisterNetEvent('ec_admin_ultimate:server:getAllPlayerLocations', function()
    local src = source
    local locations = {}
    
    for playerId, data in pairs(LivemapSystem.playerLocations) do
        table.insert(locations, {
            playerId = playerId,
            playerName = GetPlayerName(tonumber(playerId)),
            x = data.current.x,
            y = data.current.y,
            z = data.current.z,
            heading = data.current.w,
            distance = data.totalDistance
        })
    end
    
    TriggerClientEvent('ec_admin_ultimate:client:allPlayerLocationsUpdate', src, locations)
end)

-- =============================================================================
-- CLIENT-SIDE LOCATION UPDATES
-- =============================================================================

-- Receive location update from client
RegisterNetEvent('ec_admin_ultimate:server:updatePlayerLocation', function(playerId, coords)
    local playerCoords = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = coords.heading or 0
    }
    
    TrackPlayerLocation(tonumber(playerId), playerCoords)
    UpdateHeatmapData(tonumber(playerId), playerCoords)
end)

-- =============================================================================
-- BACKGROUND SYSTEMS
-- =============================================================================

-- Broadcast location updates to tracking admins
CreateThread(function()
    while true do
        Wait(LivemapSystem.config.updateInterval)
        
        for adminSrc, targetId in pairs(LivemapSystem.activeTracking) do
            if GetPlayerName(targetId) then
                local trail = GetPlayerTrail(targetId)
                if trail then
                    TriggerClientEvent('ec_admin_ultimate:client:trackedPlayerUpdate', adminSrc, trail)
                end
            end
        end
    end
end)

-- Update heatmap every minute
CreateThread(function()
    while true do
        Wait(60 * 1000)
        
        -- Clear old heatmap data
        for cell, data in pairs(LivemapSystem.heatmapData) do
            if os.time() - data.lastUpdate > 300 then  -- 5 minutes
                LivemapSystem.heatmapData[cell] = nil
            end
        end
    end
end)

-- Store location data to database every 10 minutes
CreateThread(function()
    while true do
        Wait(10 * 60 * 1000)
        
        for playerId, data in pairs(LivemapSystem.playerLocations) do
            if GetPlayerName(tonumber(playerId)) then
                MySQL.Async.execute([[
                    INSERT INTO ec_livemap_history 
                    (player_id, x, y, z, distance, recorded_at)
                    VALUES (?, ?, ?, ?, ?, NOW())
                ]], {
                    tonumber(playerId),
                    data.current.x,
                    data.current.y,
                    data.current.z,
                    data.totalDistance
                })
            end
        end
    end
end)

Logger.Success('✅ Livemap Real-Time Tracking System initialized')
Logger.Info('Features: Player tracking | Heatmap generation | Activity zones | Location history')
Logger.Info('📍 Livemap system ready for deployment')