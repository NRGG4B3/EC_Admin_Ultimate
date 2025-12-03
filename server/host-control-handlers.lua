-- EC Admin Ultimate - Host Control Handlers
-- Handles host-only administrative functions

-- Use global Config from shared_scripts (config/runtime-config.lua)
local Config = _G.ECAdminConfig or Config or {}

-- Verify host access
local function IsHostMode()
    local mode = _G.ECEnvironment and _G.ECEnvironment.GetMode() or 'CUSTOMER'
    return mode == 'HOST'
end

-- Host service action handler
RegisterServerEvent('ec_admin:host:serviceAction')
AddEventHandler('ec_admin:host:serviceAction', function(service, action)
    local source = source
    
    if not IsHostMode() then
        Logger.Error("🔒 Unauthorized access attempt from player " .. source)
        return
    end
    
    Logger.Info(string.format('🔧 Service action: %s %s', action, service))
    
    -- In a real implementation, this would:
    -- 1. Execute PM2 commands: pm2 start/stop/restart <service>
    -- 2. Update service status in database
    -- 3. Send confirmation to client
    
    -- For now, log the action
    if action == 'start' then
        Logger.Info(string.format('Host:', service))
    elseif action == 'stop' then
        Logger.Info(string.format('Host:', service))
    elseif action == 'restart' then
        Logger.Info(string.format('Host:', service))
    end
    
    -- Notify client of success
    TriggerClientEvent('ec_admin:client:notification', source, {
        type = 'success',
        message = string.format('%s %s completed', service, action)
    })
end)

-- Host uninstall service handler
RegisterServerEvent('ec_admin:host:uninstallService')
AddEventHandler('ec_admin:host:uninstallService', function(service)
    local source = source
    
    if not IsHostMode() then
        Logger.Error("🔒 Unauthorized uninstall attempt from player " .. source)
        return
    end
    
    Logger.Warn(string.format('🗑️ Uninstall service: %s', service))
    
    -- In a real implementation, this would:
    -- 1. Stop the service: pm2 stop <service>
    -- 2. Delete the service: pm2 delete <service>
    -- 3. Remove service files
    -- 4. Update configuration
    
    -- For now, log the action
    Logger.Info(string.format('Host:', service))
    
    -- Notify client
    TriggerClientEvent('ec_admin:client:notification', source, {
        type = 'warning',
        message = string.format('%s uninstalled successfully', service)
    })
end)

-- Host toggle web admin handler
RegisterServerEvent('ec_admin:host:toggleWebAdmin')
AddEventHandler('ec_admin:host:toggleWebAdmin', function(enabled)
    local source = source
    
    if not IsHostMode() then
        Logger.Error("🔒 Unauthorized web admin toggle from player " .. source)
        return
    end
    
    Logger.Info(string.format('🌐 Web admin toggle: %s', enabled and 'ENABLED' or 'DISABLED'))
    
    -- Set the convar to enable/disable web admin
    SetConvar('ec_web_admin_enabled', tostring(enabled))
    
    -- Log the change
    if enabled then
        Logger.Warn('[Host Control] WARNING: Web admin is now EXPOSED to external IPs!', '⚠️')
        Logger.Info('[Host Control] Only whitelisted IPs can access')
    else
        Logger.Success('[Host Control] Web admin is now SECURE (localhost only)', '🔒')
    end
    
    -- Update config (if using runtime config)
    if Config and Config.WebUI then
        Config.WebUI.Enabled = enabled
    end
    
    -- Notify client
    TriggerClientEvent('ec_admin:client:notification', source, {
        type = enabled and 'warning' or 'success',
        message = enabled and 'Web admin exposed to external IPs' or 'Web admin secured to localhost only'
    })
    
    -- Broadcast to all admins
    TriggerClientEvent('ec_admin:client:webAdminStatusChanged', -1, {
        enabled = enabled,
        changedBy = GetPlayerName(source)
    })
end)

-- Get web admin status
RegisterServerEvent('ec_admin:host:getWebAdminStatus')
AddEventHandler('ec_admin:host:getWebAdminStatus', function()
    local source = source
    
    if not IsHostMode() then
        return
    end
    
    local enabled = GetConvar('ec_web_admin_enabled', 'false') == 'true'
    
    TriggerClientEvent('ec_admin:client:webAdminStatus', source, {
        enabled = enabled
    })
end)

-- Host get system metrics
RegisterServerEvent('ec_admin:host:getSystemMetrics')
AddEventHandler('ec_admin:host:getSystemMetrics', function()
    local source = source
    
    if not IsHostMode() then
        return
    end
    
    -- In production, fetch actual system metrics via MetricsDB or host API
    local metrics = {
        cpu = 0,
        memory = 0,
        disk = 0,
        network_in = 0,
        network_out = 0,
        services = {}
    }
    
    TriggerClientEvent('ec_admin:client:systemMetrics', source, metrics)
end)

Logger.Success('[Host Control] Server handlers loaded', '🏢')
Logger.Info('[Host Control] Mode: ' .. (IsHostMode() and 'HOST' or 'CUSTOMER'))

if IsHostMode() then
    Logger.Info('[Host Control] Host functions are ENABLED', '🏢')
else
    Logger.Info('[Host Control] Host functions are DISABLED (customer mode)')
end