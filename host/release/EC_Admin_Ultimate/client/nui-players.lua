--[[
    EC Admin Ultimate - Players NUI Callbacks (CLIENT)
    Handles all player management requests
]]

Logger.Info('✅ Players NUI callbacks registered (CLIENT)')

-- ============================================================================
-- GET ALL PLAYERS
-- ============================================================================

RegisterNUICallback('getPlayers', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getPlayers', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        -- Fallback: return local player list
        local players = GetActivePlayers()
        local playerList = {}
        
        for _, playerId in ipairs(players) do
            local serverId = GetPlayerServerId(playerId)
            if serverId > 0 then
                table.insert(playerList, {
                    id = serverId,
                    source = serverId,
                    name = GetPlayerName(serverId) or 'Unknown',
                    ping = 0,
                    online = true,
                    status = 'playing',
                    admin = false,
                    identifier = 'unknown'
                })
            end
        end
        
        cb({
            success = true,
            players = playerList,
            count = #playerList
        })
    end
end)

-- ============================================================================
-- GET PLAYER DETAILS
-- ============================================================================

RegisterNUICallback('getPlayerDetails', function(data, cb)
    if not data.playerId then
        cb({ success = false, error = 'No player ID provided' })
        return
    end
    
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getPlayerDetails', false, data.playerId)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, error = 'Failed to fetch player details' })
    end
end)

Logger.Info('✅ Players callbacks initialized - Player management ready')