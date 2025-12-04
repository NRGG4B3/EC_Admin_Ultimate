--[[
    EC Admin Ultimate - Live Map NUI Callbacks (CLIENT)
    Real-time player position tracking
]]

Logger.Info('🗺️ Live Map NUI callbacks loading...')

-- ============================================================================
-- GET LIVE MAP DATA
-- ============================================================================

RegisterNUICallback('getLiveMap', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getLiveMap', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, players = {}, blips = {} })
    end
end)

-- ============================================================================
-- TELEPORT TO PLAYER
-- ============================================================================

RegisterNUICallback('teleportToPlayer', function(data, cb)
    if data.playerId then
        local targetPlayer = GetPlayerFromServerId(data.playerId)
        if targetPlayer == -1 or targetPlayer == 0 then
            print("[EC Admin Livemap] ERROR: Invalid player ID: " .. tostring(data.playerId))
            cb({ success = false, error = 'Player not found' })
            return
        end
        
        local targetPed = GetPlayerPed(targetPlayer)
        if targetPed and targetPed ~= 0 and DoesEntityExist(targetPed) then
            local coords = GetEntityCoords(targetPed)
            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
            print("[EC Admin Livemap] Teleported to player " .. data.playerId)
            cb({ success = true })
        else
            print("[EC Admin Livemap] ERROR: Player ped not found for ID: " .. tostring(data.playerId))
            cb({ success = false, error = 'Player ped not found' })
        end
    else
        cb({ success = false, error = 'No player ID provided' })
    end
end)

-- ============================================================================
-- TELEPORT TO COORDS
-- ============================================================================

RegisterNUICallback('teleportToCoords', function(data, cb)
    if data.x and data.y and data.z then
        SetEntityCoords(PlayerPedId(), data.x, data.y, data.z, false, false, false, false)
        cb({ success = true, message = 'Teleported to coordinates' })
    else
        cb({ success = false, message = 'Invalid coordinates' })
    end
end)

-- ============================================================================
-- REAL-TIME POSITION UPDATE LOOP (runs client-side, sends to NUI)
-- ============================================================================

CreateThread(function()
    while true do
        Wait(5000) -- Update every 5 seconds
        
        -- Get all player positions
        local players = GetActivePlayers()
        local positions = {}
        
        for _, player in ipairs(players) do
            local serverId = GetPlayerServerId(player)
            if serverId > 0 then
                local ped = GetPlayerPed(player)
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                
                table.insert(positions, {
                    id = serverId,
                    name = GetPlayerName(serverId),
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    heading = heading,
                    vehicle = IsPedInAnyVehicle(ped, false)
                })
            end
        end
        
        -- Send to NUI
        SendNUIMessage({
            action = 'updateLiveMapPositions',
            players = positions
        })
    end
end)

Logger.Info('✅ Live Map NUI callbacks loaded - Real-time tracking active')