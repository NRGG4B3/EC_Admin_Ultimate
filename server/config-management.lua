-- ============================================================================
-- EC ADMIN ULTIMATE - CONFIG MANAGEMENT SYSTEM
-- Server-Side Config Updates (Live without restart)
-- ============================================================================
-- Allows admins to update config.lua values from UI
-- Changes persist across restarts and can be edited live
-- ============================================================================

Logger.Info('📋 Config Management System - Loading...')

local ConfigManager = {}
ConfigManager.LiveConfig = {}  -- Live config overrides (in-memory)
ConfigManager.ConfigFilePath = GetResourcePath(GetCurrentResourceName()) .. '/config.lua'

-- ============================================================================
-- LOAD LIVE CONFIG FROM DATABASE (Persistent overrides)
-- ============================================================================
function ConfigManager.LoadLiveConfig()
    if not Config.Database.enabled then
        Logger.Warn('Database disabled - live config changes will not persist')
        return
    end
    
    MySQL.Async.fetchAll('SELECT config_key, config_value, value_type FROM ec_admin_config WHERE enabled = 1', {}, function(results)
        if results then
            ConfigManager.LiveConfig = {}
            for _, row in ipairs(results) do
                -- Parse value based on type
                local value = row.config_value
                if row.value_type == 'number' then
                    value = tonumber(value)
                elseif row.value_type == 'boolean' then
                    value = (value == 'true' or value == '1')
                elseif row.value_type == 'json' then
                    value = json.decode(value)
                end
                
                ConfigManager.LiveConfig[row.config_key] = value
            end
            
            Logger.Success(string.format('✅ Loaded %d live config overrides from database', #results))
        else
            Logger.Debug('No live config overrides found in database')
        end
    end)
end

-- ============================================================================
-- GET CONFIG VALUE (Check live config first, then fallback to config.lua)
-- ============================================================================
function ConfigManager.Get(key)
    -- Check live overrides first
    if ConfigManager.LiveConfig[key] ~= nil then
        return ConfigManager.LiveConfig[key]
    end
    
    -- Fallback to config.lua (split by dots for nested keys)
    local keys = {}
    for k in string.gmatch(key, '[^%.]+') do
        table.insert(keys, k)
    end
    
    local value = Config
    for _, k in ipairs(keys) do
        if type(value) == 'table' and value[k] ~= nil then
            value = value[k]
        else
            return nil
        end
    end
    
    return value
end

-- ============================================================================
-- SET CONFIG VALUE (Live + persistent to database)
-- ============================================================================
function ConfigManager.Set(key, value, adminSource)
    -- Validate key exists in config.lua
    local currentValue = ConfigManager.Get(key)
    if currentValue == nil then
        return false, string.format('Config key not found: %s', key)
    end
    
    -- Update live config
    ConfigManager.LiveConfig[key] = value
    
    -- Determine value type
    local valueType = type(value)
    local serializedValue = value
    
    if valueType == 'table' then
        serializedValue = json.encode(value)
        valueType = 'json'
    elseif valueType == 'boolean' then
        serializedValue = value and 'true' or 'false'
    else
        serializedValue = tostring(value)
    end
    
    -- Save to database (persistent)
    if Config.Database.enabled then
        MySQL.Async.execute(
            'INSERT INTO ec_admin_config (config_key, config_value, value_type, updated_by, updated_at) VALUES (?, ?, ?, ?, NOW()) ON DUPLICATE KEY UPDATE config_value = ?, value_type = ?, updated_by = ?, updated_at = NOW()',
            { key, serializedValue, valueType, adminSource or 'system', serializedValue, valueType, adminSource or 'system' },
            function(result)
                if result then
                    Logger.Success(string.format('✅ Config updated: %s = %s', key, serializedValue))
                else
                    Logger.Error(string.format('❌ Failed to save config to database: %s', key))
                end
            end
        )
    end
    
    -- Trigger client updates
    TriggerClientEvent('ec_admin:configUpdated', -1, key, value)
    
    return true, 'Config value updated successfully'
end

-- ============================================================================
-- GET ALL CONFIG (Merge config.lua + live overrides)
-- ============================================================================
function ConfigManager.GetAll()
    local merged = {}
    
    -- Deep copy config.lua
    for k, v in pairs(Config) do
        merged[k] = v
    end
    
    -- Apply live overrides
    for key, value in pairs(ConfigManager.LiveConfig) do
        -- Support nested keys (e.g., "AntiCheat.enabled")
        local keys = {}
        for k in string.gmatch(key, '[^%.]+') do
            table.insert(keys, k)
        end
        
        local current = merged
        for i = 1, #keys - 1 do
            if type(current[keys[i]]) ~= 'table' then
                current[keys[i]] = {}
            end
            current = current[keys[i]]
        end
        current[keys[#keys]] = value
    end
    
    return merged
end

-- ============================================================================
-- RESET CONFIG VALUE (Remove override, revert to config.lua)
-- ============================================================================
function ConfigManager.Reset(key, adminSource)
    ConfigManager.LiveConfig[key] = nil
    
    if Config.Database.enabled then
        MySQL.Async.execute('DELETE FROM ec_admin_config WHERE config_key = ?', { key }, function(result)
            if result then
                Logger.Success(string.format('✅ Config reset: %s', key))
            end
        end)
    end
    
    TriggerClientEvent('ec_admin:configReset', -1, key)
    
    return true, 'Config value reset to default'
end

-- ============================================================================
-- RESET ALL CONFIG (Clear all overrides)
-- ============================================================================
function ConfigManager.ResetAll(adminSource)
    ConfigManager.LiveConfig = {}
    
    if Config.Database.enabled then
        MySQL.Async.execute('DELETE FROM ec_admin_config', {}, function(result)
            if result then
                Logger.Success('✅ All config overrides cleared')
            end
        end)
    end
    
    TriggerClientEvent('ec_admin:configResetAll', -1)
    
    return true, 'All config values reset to defaults'
end

-- ============================================================================
-- LIB.CALLBACK: Get Server Config
-- ============================================================================
lib.callback.register('ec_admin:getServerConfig', function(source, data)
    if not exports['EC_Admin_Ultimate']:HasPermission(source, 'ec_admin.settings') then
        return { success = false, error = 'No permission' }
    end
    
    local config = ConfigManager.GetAll()
    
    -- Remove sensitive keys
    config.HostApi = nil
    config.Host = nil
    
    return {
        success = true,
        config = config,
        liveOverrides = ConfigManager.LiveConfig
    }
end)

-- ============================================================================
-- LIB.CALLBACK: Save Server Config
-- ============================================================================
lib.callback.register('ec_admin:saveServerConfig', function(source, data)
    if not exports['EC_Admin_Ultimate']:HasPermission(source, 'ec_admin.settings') then
        return { success = false, error = 'No permission' }
    end
    
    if not data or not data.key or data.value == nil then
        return { success = false, error = 'Invalid data - key and value required' }
    end
    
    local success, message = ConfigManager.Set(data.key, data.value, GetPlayerIdentifierByType(source, 'license'))
    
    -- Log admin action
    TriggerEvent('ec_admin:logAction', source, 'CONFIG_UPDATE', {
        key = data.key,
        oldValue = ConfigManager.Get(data.key),
        newValue = data.value
    })
    
    return {
        success = success,
        message = message
    }
end)

-- ============================================================================
-- LIB.CALLBACK: Update Multiple Config Values
-- ============================================================================
lib.callback.register('ec_admin:updateServerConfig', function(source, data)
    if not exports['EC_Admin_Ultimate']:HasPermission(source, 'ec_admin.settings') then
        return { success = false, error = 'No permission' }
    end
    
    if not data or not data.changes or type(data.changes) ~= 'table' then
        return { success = false, error = 'Invalid data - changes table required' }
    end
    
    local results = {}
    local successCount = 0
    local failCount = 0
    
    for key, value in pairs(data.changes) do
        local success, message = ConfigManager.Set(key, value, GetPlayerIdentifierByType(source, 'license'))
        
        table.insert(results, {
            key = key,
            success = success,
            message = message
        })
        
        if success then
            successCount = successCount + 1
        else
            failCount = failCount + 1
        end
    end
    
    -- Log admin action
    TriggerEvent('ec_admin:logAction', source, 'CONFIG_BULK_UPDATE', {
        changesCount = #results,
        successCount = successCount,
        failCount = failCount
    })
    
    return {
        success = true,
        results = results,
        successCount = successCount,
        failCount = failCount
    }
end)

-- ============================================================================
-- LIB.CALLBACK: Reset Config Value
-- ============================================================================
lib.callback.register('ec_admin:resetConfigValue', function(source, data)
    if not exports['EC_Admin_Ultimate']:HasPermission(source, 'ec_admin.settings') then
        return { success = false, error = 'No permission' }
    end
    
    if not data or not data.key then
        return { success = false, error = 'Invalid data - key required' }
    end
    
    local success, message = ConfigManager.Reset(data.key, GetPlayerIdentifierByType(source, 'license'))
    
    -- Log admin action
    TriggerEvent('ec_admin:logAction', source, 'CONFIG_RESET', {
        key = data.key
    })
    
    return {
        success = success,
        message = message
    }
end)

-- ============================================================================
-- LIB.CALLBACK: Reset All Config
-- ============================================================================
lib.callback.register('ec_admin:resetAllConfig', function(source, data)
    if not exports['EC_Admin_Ultimate']:HasPermission(source, 'ec_admin.settings') then
        return { success = false, error = 'No permission' }
    end
    
    local success, message = ConfigManager.ResetAll(GetPlayerIdentifierByType(source, 'license'))
    
    -- Log admin action
    TriggerEvent('ec_admin:logAction', source, 'CONFIG_RESET_ALL', {})
    
    return {
        success = success,
        message = message
    }
end)

-- ============================================================================
-- CONSOLE COMMANDS (Server Console Only)
-- ============================================================================

RegisterCommand('ec:config:get', function(source, args, rawCommand)
    if source ~= 0 then
        return
    end
    
    if #args == 0 then
        Logger.Warn('⚠️ Usage: ec:config:get <key>')
        return
    end
    
    local value = ConfigManager.Get(args[1])
    Logger.Info(string.format('📋 Config.%s = %s', args[1], json.encode(value)))
end, true)

RegisterCommand('ec:config:set', function(source, args, rawCommand)
    if source ~= 0 then
        return
    end
    
    if #args < 2 then
        Logger.Warn('⚠️ Usage: ec:config:set <key> <value>')
        return
    end
    
    local key = args[1]
    local value = table.concat(args, ' ', 2)
    
    -- Try to parse value
    if value == 'true' then
        value = true
    elseif value == 'false' then
        value = false
    elseif tonumber(value) then
        value = tonumber(value)
    end
    
    local success, message = ConfigManager.Set(key, value, 'console')
    Logger.Success(message)
end, true)

RegisterCommand('ec:config:reset', function(source, args, rawCommand)
    if source ~= 0 then
        return
    end
    
    if #args == 0 then
        Logger.Warn('⚠️ Usage: ec:config:reset <key>')
        return
    end
    
    local success, message = ConfigManager.Reset(args[1], 'console')
    Logger.Info(message)
end, true)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
CreateThread(function()
    Wait(3000)  -- Wait for database
    ConfigManager.LoadLiveConfig()
end)

Logger.Success('✅ Config Management System Loaded (Live updates enabled)')

return ConfigManager
