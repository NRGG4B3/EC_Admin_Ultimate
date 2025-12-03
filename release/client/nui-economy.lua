--[[
    EC Admin Ultimate - Economy NUI Callbacks (Client)
    Bridges UI requests to server callbacks
]]

-- ============================================================================
-- ECONOMY DATA
-- ============================================================================

RegisterNUICallback('economy:getData', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getEconomyData', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, data = {}, error = 'Failed to get economy data' })
    end
end)

-- ============================================================================
-- PLAYER MONEY MANAGEMENT
-- ============================================================================

RegisterNUICallback('economy:setPlayerMoney', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:setPlayerMoney', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to set player money' })
    end
end)

RegisterNUICallback('economy:addMoney', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:addMoney', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to add money' })
    end
end)

RegisterNUICallback('economy:removeMoney', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:removeMoney', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to remove money' })
    end
end)

-- ============================================================================
-- GLOBAL ECONOMY TOOLS
-- ============================================================================

RegisterNUICallback('economy:globalAdjustment', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:globalMoneyAdjustment', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to perform global adjustment' })
    end
end)

RegisterNUICallback('economy:wipePlayerMoney', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:wipePlayerMoney', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to wipe player money' })
    end
end)

RegisterNUICallback('economy:taxPlayers', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:taxPlayers', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to tax players' })
    end
end)

-- ============================================================================
-- TRANSACTION HISTORY
-- ============================================================================

RegisterNUICallback('economy:getTransactionHistory', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getTransactionHistory', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, data = {} })
    end
end)

Logger.Info('Economy NUI callbacks registered')