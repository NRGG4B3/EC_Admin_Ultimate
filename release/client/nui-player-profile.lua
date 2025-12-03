--[[
    EC Admin Ultimate - Player Profile NUI Callbacks (CLIENT)
    Handles all player profile requests
]]

Logger.Info('✅ Player Profile NUI callbacks registered (CLIENT)')

-- ============================================================================
-- GET PLAYER PROFILE
-- ============================================================================

RegisterNUICallback('getPlayerProfile', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getPlayerProfile', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({
            success = false,
            error = 'Failed to fetch player profile'
        })
    end
end)

-- ============================================================================
-- GET PLAYER INVENTORY
-- ============================================================================

RegisterNUICallback('getPlayerInventory', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getPlayerInventory', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({
            success = false,
            error = 'Failed to fetch player inventory'
        })
    end
end)

-- ============================================================================
-- GET PLAYER VEHICLES
-- ============================================================================

RegisterNUICallback('getPlayerVehicles', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getPlayerVehicles', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({
            success = false,
            error = 'Failed to fetch player vehicles'
        })
    end
end)

-- ============================================================================
-- GET PLAYER LOGS
-- ============================================================================

RegisterNUICallback('getPlayerLogs', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getPlayerLogs', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({
            success = false,
            error = 'Failed to fetch player logs'
        })
    end
end)
