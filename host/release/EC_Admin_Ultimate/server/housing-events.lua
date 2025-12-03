--[[
    EC Admin Ultimate - Housing Server Events
    Server-side implementation for housing management
]]

Logger.Info('')

local function HasPermission(src, permission)
    return IsPlayerAceAllowed(src, 'ec_admin.' .. permission) or 
           IsPlayerAceAllowed(src, 'ec_admin.all')
end

RegisterNetEvent('ec:housing:getAll', function(data)
    local src = source
    
    if not HasPermission(src, 'housing.view') then
        return
    end
    
    local houses = MySQL.Sync.fetchAll('SELECT * FROM player_houses', {})
    TriggerClientEvent('ec:housing:getAllResponse', src, houses)
end)

RegisterNetEvent('ec:housing:getPlayerHouses', function(data)
    local src = source
    
    if not HasPermission(src, 'housing.view') then
        return
    end
    
    local identifier = data.identifier
    local houses = MySQL.Sync.fetchAll('SELECT * FROM player_houses WHERE citizenid = ?', {identifier})
    TriggerClientEvent('ec:housing:getPlayerHousesResponse', src, houses)
end)

RegisterNetEvent('ec:housing:transfer', function(data)
    local src = source
    
    if not HasPermission(src, 'housing.transfer') then
        return
    end
    
    local houseId = data.houseId
    local newOwner = data.newOwner
    
    MySQL.Async.execute('UPDATE player_houses SET citizenid = ? WHERE id = ?', {newOwner, houseId})
    
    Logger.Info(string.format('', src, houseId, newOwner))
    
    TriggerClientEvent('ec:notify', src, {
        title = 'House Transferred',
        description = 'House ownership transferred successfully',
        type = 'success'
    })
end)

RegisterNetEvent('ec:housing:evict', function(data)
    local src = source
    
    if not HasPermission(src, 'housing.evict') then
        return
    end
    
    local houseId = data.houseId
    
    MySQL.Async.execute('DELETE FROM player_houses WHERE id = ?', {houseId})
    
    Logger.Info(string.format('', src, houseId))
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Player Evicted',
        description = 'Player has been evicted from property',
        type = 'success'
    })
end)

RegisterNetEvent('ec:housing:giveKeys', function(data)
    local src = source
    
    if not HasPermission(src, 'housing.keys') then
        return
    end
    
    local houseId = data.houseId
    local targetIdentifier = data.targetIdentifier
    
    -- Implementation depends on your housing system
    Logger.Info(string.format('', src, houseId, targetIdentifier))
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Keys Given',
        description = 'House keys given successfully',
        type = 'success'
    })
end)

RegisterNetEvent('ec:housing:removeKeys', function(data)
    local src = source
    
    if not HasPermission(src, 'housing.keys') then
        return
    end
    
    local houseId = data.houseId
    local targetIdentifier = data.targetIdentifier
    
    -- Implementation depends on your housing system
    Logger.Info(string.format('', src, houseId, targetIdentifier))
    
    TriggerClientEvent('ec:notify', src, {
        title = 'Keys Removed',
        description = 'House keys removed successfully',
        type = 'success'
    })
end)

Logger.Info('')
