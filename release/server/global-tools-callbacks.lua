--[[
    EC Admin Ultimate - Global Tools Callbacks (SERVER)
    Handles server-wide settings and management
]]

Logger.Info('🌐 Loading global tools callbacks...')

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

local ServerSettings = {
    maintenanceMode = false,
    pvpEnabled = true,
    economyEnabled = true,
    jobsEnabled = true,
    whitelistEnabled = false,
    eventsEnabled = true,
    housingEnabled = true
}

local WorldSettings = {
    weather = 'CLEAR',
    time = 12,
    freezeTime = false,
    freezeWeather = false
}

local EconomySettings = {
    taxRate = 10,
    salaryMultiplier = 1.0,
    priceMultiplier = 1.0,
    economyMode = 'normal'
}

-- ============================================================================
-- GET SERVER SETTINGS
-- ============================================================================

lib.callback.register('ec_admin:getServerSettings', function(source)
    return {
        success = true,
        settings = {
            server = ServerSettings,
            world = WorldSettings,
            economy = EconomySettings
        }
    }
end)

-- ============================================================================
-- SET SERVER SETTING
-- ============================================================================

RegisterServerEvent('ec_admin:setServerSetting')
AddEventHandler('ec_admin:setServerSetting', function(data)
    local source = source
    
    -- Permission check (FIXED: Was TODO!)
    if not HasPermission or not HasPermission(source) then
        Logger.Info('')
        return
    end
    
    if data.category == 'server' and ServerSettings[data.setting] ~= nil then
        ServerSettings[data.setting] = data.value
        Logger.Info(string.format('', data.setting, tostring(data.value)))
    elseif data.category == 'world' and WorldSettings[data.setting] ~= nil then
        WorldSettings[data.setting] = data.value
        Logger.Info(string.format('', data.setting, tostring(data.value)))
    elseif data.category == 'economy' and EconomySettings[data.setting] ~= nil then
        EconomySettings[data.setting] = data.value
        Logger.Info(string.format('', data.setting, tostring(data.value)))
    end
end)

-- ============================================================================
-- WORLD MANAGEMENT
-- ============================================================================

RegisterServerEvent('ec_admin:setWeather')
AddEventHandler('ec_admin:setWeather', function(data)
    local source = source
    
    -- Permission check
    if not HasPermission or not HasPermission(source) then
        Logger.Info('')
        return
    end
    
    local weather = data.weather or 'CLEAR'
    WorldSettings.weather = weather
    
    -- Apply weather to all clients
    TriggerClientEvent('ec_admin:client:setWeather', -1, weather)
    
    Logger.Info(string.format('', weather))
end)

RegisterServerEvent('ec_admin:setTime')
AddEventHandler('ec_admin:setTime', function(data)
    local source = source
    
    -- Permission check
    if not HasPermission or not HasPermission(source) then
        Logger.Info('')
        return
    end
    
    local time = data.time or 12
    WorldSettings.time = time
    
    -- Apply time to all clients
    TriggerClientEvent('ec_admin:client:setTime', -1, time, 0)
    
    Logger.Info(string.format('', time))
end)

RegisterServerEvent('ec_admin:freezeTime')
AddEventHandler('ec_admin:freezeTime', function(data)
    local source = source
    
    -- Permission check
    if not HasPermission or not HasPermission(source) then
        Logger.Info('')
        return
    end
    
    WorldSettings.freezeTime = data.freeze
    
    -- Notify all clients
    TriggerClientEvent('ec_admin:client:freezeTime', -1, data.freeze)
    
    Logger.Info(string.format('', data.freeze and 'frozen' or 'unfrozen'))
end)

RegisterServerEvent('ec_admin:freezeWeather')
AddEventHandler('ec_admin:freezeWeather', function(data)
    local source = source
    
    -- Permission check
    if not HasPermission or not HasPermission(source) then
        Logger.Info('')
        return
    end
    
    WorldSettings.freezeWeather = data.freeze
    
    Logger.Info(string.format('', data.freeze and 'frozen' or 'unfrozen'))
end)

-- ============================================================================
-- SERVER MANAGEMENT
-- ============================================================================

RegisterServerEvent('ec_admin:toggleMaintenance')
AddEventHandler('ec_admin:toggleMaintenance', function(data)
    local source = source
    
    -- Permission check
    if not HasPermission or not HasPermission(source) then
        Logger.Info('')
        return
    end
    
    ServerSettings.maintenanceMode = data.enabled
    
    if data.enabled then
        -- Kick all non-admin players
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local pid = tonumber(playerId)
            if pid then
                -- Check if player is admin before kicking (FIXED: Was TODO!)
                local isAdmin = HasPermission and HasPermission(pid) or false
                
                if not isAdmin then
                    DropPlayer(pid, 'Server is in maintenance mode')
                end
            end
        end
    end
    
    Logger.Info(string.format('', data.enabled and 'enabled' or 'disabled'))
end)

RegisterServerEvent('ec_admin:toggleWhitelist')
AddEventHandler('ec_admin:toggleWhitelist', function(data)
    local source = source
    
    -- Permission check
    if not HasPermission or not HasPermission(source) then
        Logger.Info('')
        return
    end
    
    ServerSettings.whitelistEnabled = data.enabled
    
    Logger.Info(string.format('', data.enabled and 'enabled' or 'disabled'))
end)

RegisterServerEvent('ec_admin:togglePVP')
AddEventHandler('ec_admin:togglePVP', function(data)
    local source = source
    
    -- Permission check
    if not HasPermission or not HasPermission(source) then
        Logger.Info('')
        return
    end
    
    ServerSettings.pvpEnabled = data.enabled
    
    -- Notify all clients
    TriggerClientEvent('ec_admin:client:togglePVP', -1, data.enabled)
    
    Logger.Info(string.format('', data.enabled and 'enabled' or 'disabled'))
end)

RegisterServerEvent('ec_admin:toggleEconomy')
AddEventHandler('ec_admin:toggleEconomy', function(data)
    ServerSettings.economyEnabled = data.enabled
    
    Logger.Info(string.format('', data.enabled and 'enabled' or 'disabled'))
end)

RegisterServerEvent('ec_admin:kickAll')
AddEventHandler('ec_admin:kickAll', function(data)
    local reason = data.reason or 'Server restart'
    local adminSource = source
    
    -- Kick all players except the admin who triggered it
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local source = tonumber(playerId)
        if source and source ~= adminSource then
            DropPlayer(source, reason)
        end
    end
    
    Logger.Info(string.format('', reason))
end)

RegisterServerEvent('ec_admin:restartResource')
AddEventHandler('ec_admin:restartResource', function(data)
    local resourceName = data.resourceName
    
    if resourceName and GetResourceState(resourceName) ~= 'missing' then
        ExecuteCommand('restart ' .. resourceName)
        Logger.Info(string.format('', resourceName))
    end
end)

-- ============================================================================
-- ECONOMY MANAGEMENT
-- ============================================================================

RegisterServerEvent('ec_admin:setTaxRate')
AddEventHandler('ec_admin:setTaxRate', function(data)
    EconomySettings.taxRate = data.rate or 10
    
    Logger.Info(string.format('', EconomySettings.taxRate))
end)

RegisterServerEvent('ec_admin:setSalaryMultiplier')
AddEventHandler('ec_admin:setSalaryMultiplier', function(data)
    EconomySettings.salaryMultiplier = data.multiplier or 1.0
    
    Logger.Info(string.format('', EconomySettings.salaryMultiplier))
end)

RegisterServerEvent('ec_admin:setPriceMultiplier')
AddEventHandler('ec_admin:setPriceMultiplier', function(data)
    EconomySettings.priceMultiplier = data.multiplier or 1.0
    
    Logger.Info(string.format('', EconomySettings.priceMultiplier))
end)

-- ============================================================================
-- EXPORTS FOR OTHER RESOURCES
-- ============================================================================

exports('GetServerSettings', function()
    return ServerSettings
end)

exports('GetWorldSettings', function()
    return WorldSettings
end)

exports('GetEconomySettings', function()
    return EconomySettings
end)

exports('IsMaintenanceMode', function()
    return ServerSettings.maintenanceMode
end)

exports('IsPVPEnabled', function()
    return ServerSettings.pvpEnabled
end)

exports('IsWhitelistEnabled', function()
    return ServerSettings.whitelistEnabled
end)

Logger.Info('✅ Global tools callbacks loaded')
