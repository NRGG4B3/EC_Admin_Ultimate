--[[
    EC Admin Ultimate - Global Tools Client Handlers
    Handles client-side world management
]]

Logger.Info('🌐 Loading global tools client handlers...')

-- ============================================================================
-- STATE
-- ============================================================================

local timeFrozen = false
local frozenHour = 12
local frozenMinute = 0

-- ============================================================================
-- SET WEATHER
-- ============================================================================

RegisterNetEvent('ec_admin:client:setWeather')
AddEventHandler('ec_admin:client:setWeather', function(weather)
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypePersist(weather)
    
    Logger.Info(string.format('', weather))
end)

-- ============================================================================
-- SET TIME
-- ============================================================================

RegisterNetEvent('ec_admin:client:setTime')
AddEventHandler('ec_admin:client:setTime', function(hour, minute)
    NetworkOverrideClockTime(hour, minute or 0, 0)
    
    Logger.Info(string.format('', hour, minute or 0))
end)

-- ============================================================================
-- FREEZE TIME
-- ============================================================================

RegisterNetEvent('ec_admin:client:freezeTime')
AddEventHandler('ec_admin:client:freezeTime', function(freeze)
    timeFrozen = freeze
    
    if freeze then
        frozenHour = GetClockHours()
        frozenMinute = GetClockMinutes()
    end
    
    Logger.Info(string.format('', freeze and 'frozen' or 'unfrozen'))
end)

-- Time freeze loop
CreateThread(function()
    while true do
        if timeFrozen then
            NetworkOverrideClockTime(frozenHour, frozenMinute, 0)
        end
        Wait(1000)
    end
end)

-- ============================================================================
-- TOGGLE PVP
-- ============================================================================

local pvpEnabled = true

RegisterNetEvent('ec_admin:client:togglePVP')
AddEventHandler('ec_admin:client:togglePVP', function(enabled)
    pvpEnabled = enabled
    
    -- Set player invincibility based on PVP setting
    SetPlayerInvincible(PlayerId(), not enabled)
    
    Logger.Info(string.format('', enabled and 'enabled' or 'disabled'))
end)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('IsPVPEnabled', function()
    return pvpEnabled
end)

exports('IsTimeFrozen', function()
    return timeFrozen
end)

Logger.Info('✅ Global tools client handlers loaded')
