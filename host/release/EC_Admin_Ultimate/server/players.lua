--[[
    EC Admin Ultimate - Players Main Logic
    Core player management functions and data structures
]]

local Players = {}

-- ==========================================
-- CORE PLAYER FUNCTIONS
-- ==========================================

function Players.GetOnlinePlayers()
    local players = GetPlayers()
    local playerList = {}

    for _, playerId in pairs(players) do
        local serverID = tonumber(playerId)
        if serverID then
            local playerData = Players.GetPlayerData(serverID)
            if playerData then
                table.insert(playerList, playerData)
            end
        end
    end

    return playerList
end

function Players.GetPlayerData(playerId)
    if not playerId then return nil end
    
    local player = GetPlayerName(playerId)
    if not player then return nil end
    
    local identifiers = GetPlayerIdentifiers(playerId)
    local license = nil
    local discord = nil
    local steam = nil
    
    for _, id in pairs(identifiers) do
        if string.match(id, "license:") then
            license = id
        elseif string.match(id, "discord:") then
            discord = id
        elseif string.match(id, "steam:") then
            steam = id
        end
    end
    
    return {
        id = playerId,
        source = playerId,
        name = player,
        identifiers = {
            license = license,
            discord = discord,
            steam = steam
        },
        ping = GetPlayerPing(playerId) or 0,
        online = true,
        status = 'playing',
        coords = GetEntityCoords(GetPlayerPed(playerId))
    }
end

function Players.GetPlayerByIdentifier(identifier)
    local players = GetPlayers()
    
    for _, playerId in pairs(players) do
        local identifiers = GetPlayerIdentifiers(tonumber(playerId))
        for _, id in pairs(identifiers) do
            if id == identifier then
                return Players.GetPlayerData(tonumber(playerId))
            end
        end
    end
    
    return nil
end

function Players.GetPlayerCount()
    return #GetPlayers()
end

function Players.IsPlayerOnline(playerId)
    return GetPlayerName(playerId) ~= nil
end

-- ==========================================
-- EXPORT
-- ==========================================

_G.Players = Players

Logger.Info("^7 Players main logic loaded")
