--[[
    EC Admin Ultimate - Global Tools NUI Callbacks (CLIENT)
    Handles all global tools and server management requests
]]

Logger.Info('🌐 Global Tools NUI callbacks loading...')

-- ============================================================================
-- GET ECONOMY DATA (for Economy & Global Tools page)
-- ============================================================================

RegisterNUICallback('economy:getData', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getEconomyData', false, data)
    end)
    
    if success and result then
        cb({ success = true, economy = result })
    else
        cb({
            success = false,
            error = 'Failed to fetch economy data'
        })
    end
end)

-- ============================================================================
-- GET SERVER SETTINGS (World, Economy, Server)
-- ============================================================================

RegisterNUICallback('server:getSettings', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getServerSettings', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({
            success = false,
            error = 'Failed to fetch server settings'
        })
    end
end)

-- ============================================================================
-- SET SERVER SETTING
-- ============================================================================

RegisterNUICallback('server:setSetting', function(data, cb)
    TriggerServerEvent('ec_admin:setServerSetting', data)
    cb({ success = true })
end)

-- ============================================================================
-- WORLD MANAGEMENT
-- ============================================================================

RegisterNUICallback('world:setWeather', function(data, cb)
    TriggerServerEvent('ec_admin:setWeather', data)
    cb({ success = true })
end)

RegisterNUICallback('world:setTime', function(data, cb)
    TriggerServerEvent('ec_admin:setTime', data)
    cb({ success = true })
end)

RegisterNUICallback('world:freezeTime', function(data, cb)
    TriggerServerEvent('ec_admin:freezeTime', data)
    cb({ success = true })
end)

RegisterNUICallback('world:freezeWeather', function(data, cb)
    TriggerServerEvent('ec_admin:freezeWeather', data)
    cb({ success = true })
end)

-- ============================================================================
-- SERVER MANAGEMENT
-- ============================================================================

RegisterNUICallback('server:toggleMaintenance', function(data, cb)
    TriggerServerEvent('ec_admin:toggleMaintenance', data)
    cb({ success = true })
end)

RegisterNUICallback('server:toggleWhitelist', function(data, cb)
    TriggerServerEvent('ec_admin:toggleWhitelist', data)
    cb({ success = true })
end)

RegisterNUICallback('server:togglePVP', function(data, cb)
    TriggerServerEvent('ec_admin:togglePVP', data)
    cb({ success = true })
end)

RegisterNUICallback('server:toggleEconomy', function(data, cb)
    TriggerServerEvent('ec_admin:toggleEconomy', data)
    cb({ success = true })
end)

RegisterNUICallback('server:kickAll', function(data, cb)
    TriggerServerEvent('ec_admin:kickAll', data)
    cb({ success = true })
end)

RegisterNUICallback('server:restartResource', function(data, cb)
    TriggerServerEvent('ec_admin:restartResource', data)
    cb({ success = true })
end)

-- ============================================================================
-- ECONOMY MANAGEMENT
-- ============================================================================

RegisterNUICallback('economy:setTaxRate', function(data, cb)
    TriggerServerEvent('ec_admin:setTaxRate', data)
    cb({ success = true })
end)

RegisterNUICallback('economy:setSalaryMultiplier', function(data, cb)
    TriggerServerEvent('ec_admin:setSalaryMultiplier', data)
    cb({ success = true })
end)

RegisterNUICallback('economy:setPriceMultiplier', function(data, cb)
    TriggerServerEvent('ec_admin:setPriceMultiplier', data)
    cb({ success = true })
end)

Logger.Info('✅ Global Tools NUI callbacks loaded')
