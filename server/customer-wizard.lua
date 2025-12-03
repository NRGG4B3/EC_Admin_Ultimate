--[[
    EC Admin Ultimate - Customer Setup Wizard
    Shows config questions and NRG API selection
    Mandatory APIs: Always enabled for security/core features
    Optional APIs: Customer choice based on their needs
]]

local WIZARD = {}

-- Mandatory NRG APIs (always enabled - not selectable)
WIZARD.MANDATORY_APIS = {
    {
        id = 'global_bans',
        name = '🚫 Global Ban System',
        description = 'Share bans across all NRG-connected servers. Prevents banned players from evading.',
        endpoint = 'https://api.nrg.gg/bans',
        category = 'security',
        required = true
    },
    {
        id = 'ai_detection',
        name = '🤖 AI Cheat Detection',
        description = 'ML-powered anticheat with pattern recognition. Detects new exploits automatically.',
        endpoint = 'https://api.nrg.gg/ai-detection',
        category = 'security',
        required = true
    },
    {
        id = 'admin_abuse',
        name = '👮 Admin Abuse Detection',
        description = 'Track and prevent admin power abuse. Protects your server from rogue staff.',
        endpoint = 'https://api.nrg.gg/admin-abuse',
        category = 'security',
        required = true
    },
    {
        id = 'analytics',
        name = '📊 Server Analytics',
        description = 'Advanced server metrics and AI insights. Essential for monitoring server health.',
        endpoint = 'https://api.nrg.gg/analytics',
        category = 'monitoring',
        required = true
    },
    {
        id = 'reports',
        name = '📝 Report Management',
        description = 'Centralized player report system. Core moderation feature.',
        endpoint = 'https://api.nrg.gg/reports',
        category = 'moderation',
        required = true
    }
}

-- Optional NRG APIs (customer can choose which to enable)
WIZARD.OPTIONAL_APIS = {
    {
        id = 'live_map',
        name = '🗺️ Live Map Sync',
        description = 'Real-time player positions and server status on web dashboard.',
        endpoint = 'https://api.nrg.gg/livemap',
        category = 'monitoring',
        required = false,
        recommended = true
    },
    {
        id = 'backups',
        name = '💾 Cloud Backups',
        description = 'Automatic database backups to NRG cloud. Restore in case of data loss.',
        endpoint = 'https://api.nrg.gg/backups',
        category = 'data',
        required = false,
        recommended = true
    },
    {
        id = 'economy',
        name = '💰 Economy Sync',
        description = 'Multi-server economy synchronization. Share money/items across servers.',
        endpoint = 'https://api.nrg.gg/economy',
        category = 'gameplay',
        required = false,
        recommended = false
    },
    {
        id = 'whitelist',
        name = '✅ Advanced Whitelist',
        description = 'Cloud-based whitelist with Discord integration and auto-approval.',
        endpoint = 'https://api.nrg.gg/whitelist',
        category = 'security',
        required = false,
        recommended = false
    },
    {
        id = 'discord_sync',
        name = '🎮 Discord Integration',
        description = 'Sync roles, commands, and notifications with Discord bot.',
        endpoint = 'https://api.nrg.gg/discord',
        category = 'integration',
        required = false,
        recommended = true
    },
    {
        id = 'performance',
        name = '⚡ Performance Optimizer',
        description = 'AI-powered performance optimization and resource monitoring.',
        endpoint = 'https://api.nrg.gg/performance',
        category = 'monitoring',
        required = false,
        recommended = true
    },
    {
        id = 'player_tracking',
        name = '👤 Advanced Player Tracking',
        description = 'Detailed player behavior analytics and playtime tracking.',
        endpoint = 'https://api.nrg.gg/player-tracking',
        category = 'monitoring',
        required = true,
        recommended = true
    }
}

-- Register HTTP endpoints for wizard
function WIZARD.RegisterEndpoints()
    -- Get available APIs (split into mandatory and optional)
    SetHttpHandler(function(req, res)
        local path = req.path
        
        if path == '/api/setup/available-apis' and req.method == 'GET' then
            res.writeHead(200, { ['Content-Type'] = 'application/json' })
            res.send(json.encode({
                ok = true,
                mandatory = WIZARD.MANDATORY_APIS,
                optional = WIZARD.OPTIONAL_APIS,
                info = {
                    mandatory_count = #WIZARD.MANDATORY_APIS,
                    optional_count = #WIZARD.OPTIONAL_APIS,
                    message = "Mandatory APIs are always enabled for security and core features."
                }
            }))
            return
        end
        
        if path == '/api/setup/configure' and req.method == 'POST' then
            local body = req.body
            local config = json.decode(body)
            
            -- Validate required fields
            if not config.cityName or not config.ownerInfo then
                res.writeHead(400, { ['Content-Type'] = 'application/json' })
                res.send(json.encode({ ok = false, error = 'Missing required fields' }))
                return
            end
            
            -- Save configuration
            local success = WIZARD.SaveConfig(config)
            
            if success then
                res.writeHead(200, { ['Content-Type'] = 'application/json' })
                res.send(json.encode({
                    ok = true,
                    message = 'Configuration saved! Restarting resource...'
                }))
                
                -- Restart resource to apply config
                SetTimeout(2000, function()
                    ExecuteCommand('restart ' .. GetCurrentResourceName())
                end)
            else
                res.writeHead(500, { ['Content-Type'] = 'application/json' })
                res.send(json.encode({ ok = false, error = 'Failed to save configuration' }))
            end
            return
        end
    end)
end

-- Build enabled services table (mandatory + selected optional)
function WIZARD.BuildEnabledServices(selectedOptionalApis)
    local services = {}
    
    -- Add all mandatory APIs (always enabled)
    for _, api in ipairs(WIZARD.MANDATORY_APIS) do
        services[api.id] = true
    end
    
    -- Add selected optional APIs
    if selectedOptionalApis then
        for _, apiId in ipairs(selectedOptionalApis) do
            services[apiId] = true
        end
    end
    
    return services
end

-- Save customer configuration
function WIZARD.SaveConfig(config)
    -- Build enabled services (mandatory + optional)
    local enabledServices = WIZARD.BuildEnabledServices(config.selectedOptionalApis)
    
    -- Build config.lua content
    local configContent = [[-- EC Admin Ultimate Configuration
-- Auto-generated by Setup Wizard
-- Date: ]] .. os.date('%Y-%m-%d %H:%M:%S') .. [[


Config = {}
Config.Version = "2.0.0"

-- ============================================================================
-- CITY INFORMATION
-- ============================================================================
Config.CityName = "]] .. (config.cityName or 'My Server') .. [["
Config.Framework = "]] .. (config.framework or 'qbcore') .. [["

-- ============================================================================
-- OWNER IDENTIFIERS
-- ============================================================================
Config.Owners = {
    license = "]] .. (config.ownerInfo.license or '') .. [[",
    discord = "]] .. (config.ownerInfo.discord or '') .. [[",
    steam = "]] .. (config.ownerInfo.steam or '') .. [[",
    fivem = "]] .. (config.ownerInfo.fivem or '') .. [["
}

-- ============================================================================
-- DISCORD WEBHOOKS
-- ============================================================================
Config.Webhooks = {
    adminActions = "]] .. (config.webhooks and config.webhooks.adminActions or '') .. [[",
    bans = "]] .. (config.webhooks and config.webhooks.bans or '') .. [[",
    reports = "]] .. (config.webhooks and config.webhooks.reports or '') .. [[",
    economy = "]] .. (config.webhooks and config.webhooks.economy or '') .. [[",
    staffAccess = "]] .. (config.webhooks and config.webhooks.staffAccess or '') .. [["
}

-- ============================================================================
-- NRG API CONFIGURATION
-- ============================================================================
Config.NRG_APIs = {
    enabled = true,
    baseUrl = "https://api.nrg.gg",
    apiKey = "customer_]] .. tostring(os.time()) .. [[_]] .. tostring(math.random(100000, 999999)) .. [[",
    
    -- Enabled Services (Mandatory + Optional Selected)
    enabledServices = {
]]

    -- Add enabled services
    for serviceId, enabled in pairs(enabledServices) do
        if enabled then
            configContent = configContent .. '        ' .. serviceId .. ' = true,\n'
        end
    end
    
    configContent = configContent .. [[    },
    
    -- Service Info
    mandatoryServices = {
        "global_bans",
        "ai_detection",
        "admin_abuse",
        "analytics",
        "reports"
    },
    
    -- Connection settings
    timeoutMs = 10000,
    retryAttempts = 3,
    cacheTTL = 300
}

-- ============================================================================
-- SECURITY SETTINGS
-- ============================================================================
Config.Security = {
    -- Rate limiting (enabled for customers)
    RateLimit = {
        enabled = true,
        requestsPerMinute = 60,
        burst = 30,
        blockDuration = 300
    },
    
    -- CORS settings
    CORS = {
        enabled = false,
        allowedOrigins = {
            "http://127.0.0.1:30120",
            "http://localhost:30120"
        }
    },
    
    -- Session management
    sessionTimeout = 3600,
    maxLoginAttempts = 5,
    lockoutDuration = 900,
    
    -- IP whitelist (disabled by default)
    enableIPWhitelist = false,
    allowedIPs = {}
}

-- ============================================================================
-- FEATURES
-- ============================================================================
Config.Features = {
    playerManagement = true,
    vehicleManagement = true,
    banSystem = true,
    reportSystem = true,
    economyTools = true,
    jobManagement = true,
    serverControl = true,
    monitoring = true,
    housingManagement = true,
    inventoryManagement = true,
    whitelistSystem = ]] .. tostring(enabledServices.whitelist == true) .. [[,
    discordIntegration = ]] .. tostring(enabledServices.discord_sync == true) .. [[
}

-- ============================================================================
-- UI SETTINGS
-- ============================================================================
Config.UI = {
    openKey = "]] .. (config.ui and config.ui.openKey or 'F2') .. [[",
    theme = "]] .. (config.ui and config.ui.theme or 'dark') .. [[",
    language = "]] .. (config.ui and config.ui.language or 'en') .. [[",
    animations = true,
    soundEffects = true
}

-- ============================================================================
-- HOST API (Disabled for customers - connects to NRG hosted APIs)
-- ============================================================================
Config.Host = {
    enabled = false
}

Config.HostApi = {
    enabled = false
}

-- ============================================================================
-- PERMISSIONS
-- ============================================================================
Config.Permissions = {
    god = {
        level = 100,
        label = 'God',
        color = '#FF0000'
    },
    admin = {
        level = 90,
        label = 'Admin',
        color = '#FF6B6B'
    },
    moderator = {
        level = 70,
        label = 'Moderator',
        color = '#4ECDC4'
    },
    support = {
        level = 50,
        label = 'Support',
        color = '#95E1D3'
    }
}

return Config
]]

    -- Save to file
    local success = SaveResourceFile(GetCurrentResourceName(), 'config.lua', configContent, -1)
    
    if success then
        print('^2[Customer Wizard] ✅ Configuration saved^0')
        print('^2[Customer Wizard] Enabled APIs:^0')
        print('^2  Mandatory (always on):^0')
        for _, api in ipairs(WIZARD.MANDATORY_APIS) do
            print('^2    • ' .. api.name .. '^0')
        end
        if config.selectedOptionalApis and #config.selectedOptionalApis > 0 then
            print('^2  Optional (selected):^0')
            for _, apiId in ipairs(config.selectedOptionalApis) do
                for _, api in ipairs(WIZARD.OPTIONAL_APIS) do
                    if api.id == apiId then
                        print('^2    • ' .. api.name .. '^0')
                        break
                    end
                end
            end
        end
        
        -- Mark setup as complete
        SetConvar('ec_setup_complete', 'true')
        SetConvar('ec_install_token', 'customer_' .. os.time())
        
        -- Add owner to admin group
        if config.ownerInfo then
            if config.ownerInfo.license and config.ownerInfo.license ~= '' then
                ExecuteCommand(('add_principal identifier.license:%s group.god'):format(config.ownerInfo.license))
                ExecuteCommand(('add_principal identifier.license:%s group.admin'):format(config.ownerInfo.license))
                print('^2[Customer Wizard] ✅ Owner license added to god/admin groups^0')
            end
            
            if config.ownerInfo.discord and config.ownerInfo.discord ~= '' then
                -- Remove discord: prefix if present
                local discordId = config.ownerInfo.discord:gsub('^discord:', '')
                ExecuteCommand(('add_principal identifier.discord:%s group.god'):format(discordId))
                ExecuteCommand(('add_principal identifier.discord:%s group.admin'):format(discordId))
                print('^2[Customer Wizard] ✅ Owner discord added to god/admin groups^0')
            end
        end
        
        return true
    else
        print('^1[Customer Wizard] ❌ Failed to save configuration^0')
        return false
    end
end

-- Check if wizard should be shown
function WIZARD.ShouldShow()
    local mode = GetConvar('ec_mode', 'CUSTOMER')
    local setupComplete = GetConvar('ec_setup_complete', 'false')
    
    -- NEVER show in HOST mode
    if mode == 'HOST' then
        return false
    end
    
    return mode == 'CUSTOMER' and setupComplete ~= 'true'
end

-- Initialize
CreateThread(function()
    Wait(3000)
    
    if WIZARD.ShouldShow() then
        WIZARD.RegisterEndpoints()
        print('^3╔════════════════════════════════════════════════════════╗^0')
        print('^3║  🟢 CUSTOMER SETUP WIZARD READY                       ║^0')
        print('^3╚════════════════════════════════════════════════════════╝^0')
        print('^3[Customer Wizard] 👉 Browse to: http://YOUR_IP:30120/admin^0')
        print('^3[Customer Wizard] 👉 Complete setup to activate EC Admin^0')
    end
end)

return WIZARD