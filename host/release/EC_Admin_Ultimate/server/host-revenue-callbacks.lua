-- Host Revenue Callbacks
-- Handles revenue tracking and reporting for host mode

if GetResourceState('oxmysql') ~= 'started' then
    print('^1ERROR: oxmysql not started^7')
    return
end

-- Register revenue tracking callback
lib.callback.register('host-revenue:getStats', function()
    return {
        status = 'ok',
        revenue = 0,
        transactions = 0,
        customers = 0
    }
end)

-- Track admin revenue actions
lib.callback.register('host-revenue:trackAction', function(source, action, amount)
    return true
end)
