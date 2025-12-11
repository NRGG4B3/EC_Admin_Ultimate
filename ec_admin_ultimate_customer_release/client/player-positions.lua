--[[
    EC Admin Ultimate - Player Positions Client
    Sends player position data to server for live map
    OPTIMIZED: Throttled updates to prevent spam
]]

local lastPositionUpdate = 0
local POSITION_UPDATE_INTERVAL = 3000 -- Update every 3 seconds (throttled)

-- Send position update to server
local function sendPositionUpdate()
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end
    
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local health = GetEntityHealth(ped)
    local armor = GetPedArmour(ped)
    
    -- Convert health to percentage
    if health > 100 then
        health = math.floor((health - 100) / 10)
    end
    
    local vehicle = nil
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and veh ~= 0 then
            local model = GetEntityModel(veh)
            vehicle = GetDisplayNameFromVehicleModel(model)
        end
    end
    
    -- Get job from framework (if available)
    local job = 'Civilian'
    if ECFramework then
        local player = ECFramework.GetPlayerObject()
        if player then
            if player.PlayerData and player.PlayerData.job then
                job = player.PlayerData.job.name or 'Civilian'
            elseif player.job then
                job = player.job.name or 'Civilian'
            end
        end
    end
    
    -- Get identifier (server will get it, we don't have access to GetPlayerIdentifiers on client)
    local identifier = nil
    -- Server will populate this from the source
    
    -- Normalize coordinates (GTA V map bounds: -4000 to 4000)
    local normalizedX = (coords.x + 4000) / 8000
    local normalizedY = (coords.y + 4000) / 8000
    normalizedX = math.max(0, math.min(1, normalizedX))
    normalizedY = math.max(0, math.min(1, normalizedY))
    
    -- Send to server (server will get identifier from source)
    TriggerServerEvent('ec_admin:playerPositionUpdate', {
        id = tostring(PlayerId()),
        name = GetPlayerName(PlayerId()) or 'Unknown',
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        normalizedX = normalizedX,
        normalizedY = normalizedY,
        heading = heading,
        vehicle = vehicle,
        job = job,
        health = health,
        armor = armor
        -- identifier will be added by server
    })
end

-- Listen for server request
RegisterNetEvent('ec_admin:requestPlayerPositions', function()
    local now = GetGameTimer()
    if (now - lastPositionUpdate) >= POSITION_UPDATE_INTERVAL then
        sendPositionUpdate()
        lastPositionUpdate = now
    end
end)

-- Auto-send position updates (throttled)
CreateThread(function()
    Wait(5000) -- Wait 5 seconds on startup
    while true do
        sendPositionUpdate()
        Wait(POSITION_UPDATE_INTERVAL) -- Update every 3 seconds
    end
end)

print("^2[Player Positions]^7 Client-side position tracking loaded^0")
