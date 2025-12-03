--[[
    EC Admin Ultimate - Live Map Server Callbacks
    Real-time player position tracking
]]

Logger.Info('🗺️ Loading live map callbacks...')

-- ============================================================================
-- CALLBACK: GET LIVE MAP DATA
-- ============================================================================

lib.callback.register('ec_admin:getLiveMap', function(source, data)
    local players = GetPlayers()
    local playerBlips = {}
    local zones = {}
    
    for _, playerId in ipairs(players) do
        local id = tonumber(playerId)
        if id then
            local name = GetPlayerName(id)
            local ped = GetPlayerPed(id)
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            
            -- Check if in vehicle
            local vehicle = GetVehiclePedIsIn(ped, false)
            local inVehicle = vehicle ~= 0
            local vehicleModel = inVehicle and GetEntityModel(vehicle) or nil
            
            table.insert(playerBlips, {
                id = id,
                name = name,
                x = coords.x,
                y = coords.y,
                z = coords.z,
                heading = heading,
                vehicle = inVehicle,
                vehicleModel = vehicleModel,
                online = true
            })
        end
    end
    
    return {
        success = true,
        players = playerBlips,
        blips = playerBlips,
        zones = zones,
        total = #playerBlips
    }
end)

-- ============================================================================
-- REAL-TIME POSITION PUSH (Server -> All Admins)
-- ============================================================================

CreateThread(function()
    while true do
        Wait(5000) -- Push every 5 seconds
        
        local players = GetPlayers()
        local positions = {}
        
        for _, playerId in ipairs(players) do
            local id = tonumber(playerId)
            if id then
                local ped = GetPlayerPed(id)
                local coords = GetEntityCoords(ped)
                
                positions[id] = {
                    id = id,
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    heading = GetEntityHeading(ped)
                }
            end
        end
        
        -- Send to all admins who have the panel open
        TriggerClientEvent('ec_admin:updateLiveMapPositions', -1, positions)
    end
end)

Logger.Info('✅ Live Map callbacks loaded - Real-time position push active')
