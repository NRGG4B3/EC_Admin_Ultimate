--[[
    EC Admin Ultimate - Enhanced Settings NUI Callbacks (Client)
    Handles Settings page UI interactions + Config Management
]]

-- ============================================================================
-- CONFIG MANAGEMENT (Live updates to config.lua)
-- ============================================================================

-- Get server config (all config.lua values + live overrides)
RegisterNUICallback('config:getServerConfig', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getServerConfig', false, data)
    end)
    if success and result then
        cb(result)
    else
        Logger.Error('Failed to get server config')
        cb({ success = false, error = 'Failed to retrieve config' })
    end
end)

-- Save single config value
RegisterNUICallback('config:saveValue', function(data, cb)
    if not data or not data.key or data.value == nil then
        cb({ success = false, error = 'Invalid data - key and value required' })
        return
    end
    
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:saveServerConfig', false, data)
    end)
    if success and result then
        Logger.Success(string.format('Config updated: %s', data.key))
        cb(result)
    else
        Logger.Error(string.format('Failed to save config: %s', data.key))
        cb({ success = false, error = 'Failed to save config value' })
    end
end)

-- Update multiple config values (bulk update)
RegisterNUICallback('config:updateMultiple', function(data, cb)
    if not data or not data.changes or type(data.changes) ~= 'table' then
        cb({ success = false, error = 'Invalid data - changes table required' })
        return
    end
    
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:updateServerConfig', false, data)
    end)
    if success and result then
        Logger.Success(string.format('Bulk config update: %d changes', result.successCount or 0))
        cb(result)
    else
        Logger.Error('Failed to update multiple config values')
        cb({ success = false, error = 'Failed to update config values' })
    end
end)

-- Reset config value to default (remove override)
RegisterNUICallback('config:resetValue', function(data, cb)
    if not data or not data.key then
        cb({ success = false, error = 'Invalid data - key required' })
        return
    end
    
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:resetConfigValue', false, data)
    end)
    if success and result then
        Logger.Success(string.format('Config reset: %s', data.key))
        cb(result)
    else
        Logger.Error(string.format('Failed to reset config: %s', data.key))
        cb({ success = false, error = 'Failed to reset config value' })
    end
end)

-- Reset all config values to defaults
RegisterNUICallback('config:resetAll', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:resetAllConfig', false, data)
    end)
    if success and result then
        Logger.Success('All config values reset to defaults')
        cb(result)
    else
        Logger.Error('Failed to reset all config values')
        cb({ success = false, error = 'Failed to reset config' })
    end
end)

-- Listen for config updates from server
RegisterNetEvent('ec_admin:configUpdated', function(key, value)
    Logger.Info(string.format('Config updated: %s = %s', key, tostring(value)))
    SendNUIMessage({
        action = 'configUpdated',
        key = key,
        value = value
    })
end)

-- Listen for config reset events
RegisterNetEvent('ec_admin:configReset', function(key)
    Logger.Info(string.format('Config reset: %s', key))
    SendNUIMessage({
        action = 'configReset',
        key = key
    })
end)

RegisterNetEvent('ec_admin:configResetAll', function()
    Logger.Info('All config values reset')
    SendNUIMessage({
        action = 'configResetAll'
    })
end)

-- ============================================================================
-- LEGACY SETTINGS (Webhooks, General Settings)
-- ============================================================================

-- Get settings
RegisterNUICallback('settings:getData', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getSettings', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:getSettings')
        cb({ success = true })
    end
end)

-- Save settings
RegisterNUICallback('settings:save', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:saveSettings', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:saveSettings', data)
        cb({ success = true })
    end
end)

-- Save webhooks
RegisterNUICallback('settings:saveWebhooks', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:saveWebhooks', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:saveWebhooks', data)
        cb({ success = true })
    end
end)

-- Test webhook
RegisterNUICallback('settings:testWebhook', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:testWebhook', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:testWebhook', data)
        cb({ success = true })
    end
end)

-- Reset settings
RegisterNUICallback('settings:reset', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:resetSettings', false, data)
    end)
    if success and result then
        cb(result)
    else
        TriggerServerEvent('ec_admin_ultimate:server:resetSettings', data)
        cb({ success = true })
    end
end)

-- Receive settings data
RegisterNetEvent('ec_admin_ultimate:client:receiveSettings', function(result)
    SendNUIMessage({
        action = 'settingsData',
        data = result
    })
end)

-- Receive settings response
RegisterNetEvent('ec_admin_ultimate:client:settingsResponse', function(result)
    SendNUIMessage({
        action = 'settingsResponse',
        data = result
    })
end)

Logger.Success('✅ Enhanced Settings + Config Management NUI callbacks loaded')
Logger.Info('   - Live config updates from UI')
Logger.Info('   - Bulk config operations')
Logger.Info('   - Reset to defaults')
