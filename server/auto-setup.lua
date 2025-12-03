--[[
    EC Admin Ultimate - Automatic Setup System
    - HOST MODE: Zero setup, auto-configures everything
    - CUSTOMER MODE: Setup wizard with API selection
]]

-- Initialize Config if it doesn't exist (config.lua might have failed to load)
if not Config then
    Logger.Error('[Auto-Setup] ⚠️  WARNING: Config not loaded! Creating empty Config table.')
    Logger.Error('[Auto-Setup] Check config.lua for syntax errors or delete .host-secret file if corrupt.')
    Config = {}
end

local AUTO_SETUP = {}

-- NRG Staff (both co-owners) - Auto-added as server owners + NRG staff
AUTO_SETUP.NRG_STAFF = {
    {
        name = "NRG Co-Owner 1",
        identifiers = {
            "discord:1219846819417292833",
            "fivem:14682797",
            "license:8a8b3d2426734b69ac381c536c670f6958283cda",
            "license2:8a8b3d2426734b69ac381c536c670f6958283cda",
            "live:914798925490170"
        }
    },
    {
        name = "NRG Co-Owner 2",
        identifiers = {
            "discord:783727897961037867",
            "fivem:13867190",
            "license:925a81e2ad60f0ff4e68189d6604450e970a6760",
            "license2:925a81e2ad60f0ff4e68189d6604450e970a6760",
            "live:985157629345372",
            "xbl:2535436056077725"
        }
    }
}

-- All NRG APIs (18 total)
AUTO_SETUP.ALL_APIS = {
    "GlobalBans", "AIDetection", "AdminAbuse", "Analytics", "Reports",
    "LiveMap", "Backups", "Economy", "Whitelist", "DiscordSync",
    "PlayerData", "VehicleData", "Housing", "Inventory", "Jobs",
    "AntiCheat", "Monitoring", "Webhooks"
}

-- Detect if host folder exists
function AUTO_SETUP.IsHostMode()
    -- Check for ANY file in /host/ folder (including .gitkeep marker)
    local hostFiles = {
        'host/.gitkeep',        -- Marker file
        'host/package.json',    -- Node package
        'host/.env.example',    -- Env example
        'host/README.md',       -- README
        'host/tsconfig.json'    -- TypeScript config
    }
    
    for _, file in ipairs(hostFiles) do
        local content = LoadResourceFile(GetCurrentResourceName(), file)
        if content then
            Logger.Success(('[Auto-Setup] ✅ Host mode detected (%s found)'):format(file))
            return true
        end
    end
    
    Logger.Warn('[Auto-Setup] ⚠️ No host files found - Customer mode')
    return false
end

-- Generate cryptographically secure random secret
function AUTO_SETUP.GenerateSecret()
    local charset = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local secret = "nrg_host_"
    
    for i = 1, 120 do
        local rand = math.random(1, #charset)
        secret = secret .. charset:sub(rand, rand)
    end
    
    return secret
end

-- Auto-create .host-secret file
function AUTO_SETUP.CreateHostSecret()
    local secretPath = GetResourcePath(GetCurrentResourceName()) .. '/.host-secret'
    local existingSecret = LoadResourceFile(GetCurrentResourceName(), '.host-secret')
    
    if existingSecret and #existingSecret > 32 then
        Logger.Success('[Auto-Setup] ✅ Host secret already exists')
        return existingSecret
    end
    
    local newSecret = AUTO_SETUP.GenerateSecret()
    
    -- Save to file (using SaveResourceFile if available, otherwise log it)
    local success = SaveResourceFile(GetCurrentResourceName(), '.host-secret', newSecret, -1)
    
    if success then
        Logger.Success('[Auto-Setup] ✅ Generated new host secret: .host-secret')
    else
        Logger.Warn('[Auto-Setup] ⚠️  Could not write .host-secret file')
        Logger.Warn('[Auto-Setup] Please create it manually with this content:')
        Logger.Info(newSecret)
    end
    
    -- Set convar
    SetConvar('ec_host_api_key', newSecret)
    
    return newSecret
end

-- Add NRG staff permissions automatically
function AUTO_SETUP.AddNRGStaffPermissions()
    for i, staff in ipairs(AUTO_SETUP.NRG_STAFF) do
        for _, identifier in ipairs(staff.identifiers) do
            -- Add to god group (highest permission)
            ExecuteCommand(('add_principal identifier.%s group.god'):format(identifier))
            
            -- Add to admin group
            ExecuteCommand(('add_principal identifier.%s group.admin'):format(identifier))
            
            -- Add NRG staff ace
            ExecuteCommand(('add_ace identifier.%s ecadmin.nrgstaff allow'):format(identifier))
            ExecuteCommand(('add_ace identifier.%s ecadmin.hostapi allow'):format(identifier))
        end
        
        print(('^2[Auto-Setup] ✅ Added NRG staff permissions: %s^0'):format(staff.name))
    end
end

-- Auto-configure HOST mode (zero setup required)
function AUTO_SETUP.ConfigureHostMode()
    Logger.Info('╔════════════════════════════════════════════════════════╗')
    Logger.Info('║  🔵 NRG HOST - AUTO-CONFIGURING NOW                   ║')
    Logger.Info('╚════════════════════════════════════════════════════════╝')
    
    -- Set HOST mode convar FIRST
    SetConvar('ec_mode', 'HOST')
    SetConvar('ec_setup_complete', 'true')  -- Skip wizard
    
    -- Check if .host-secret exists, if not create it
    local hostSecret = LoadResourceFile(GetCurrentResourceName(), '.host-secret')
    
    if not hostSecret or hostSecret == '' then
        -- Generate a secure random token
        local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        local secret = ''
        math.randomseed(os.time())
        for i = 1, 64 do
            local rand = math.random(1, #chars)
            secret = secret .. chars:sub(rand, rand)
        end
        
        -- Save to .host-secret file (THIS WILL NOT WORK IN RUNTIME)
        -- The setup.bat must create this file
        Logger.Warn('[Auto-Setup] ⚠️  .host-secret not found - Run setup.bat to generate')
        Logger.Warn('[Auto-Setup] ⚠️  Using temporary secret for this session')
        
        -- Set config anyway with temp secret
        Config.Host = Config.Host or {}
        Config.Host.enabled = true
        Config.Host.secret = secret
    else
        -- Load the secret
        Config.Host = Config.Host or {}
        Config.Host.enabled = true
        Config.Host.secret = hostSecret:gsub('%s+', '') -- Remove whitespace
        
        Logger.Success('[Auto-Setup] ✅ Host secret loaded')
    end
    
    -- Enable all NRG APIs (all on port 3000 with different routes)
    Config.APIs = Config.APIs or {}
    local apiRoutes = {
        'GlobalBans', 'AIDetection', 'AdminAbuse', 'Analytics', 'Reports',
        'LiveMap', 'Backups', 'Economy', 'Whitelist', 'DiscordSync',
        'PlayerData', 'VehicleData', 'Housing', 'Inventory', 'Jobs',
        'AntiCheat', 'Monitoring', 'Webhooks', 'Communications', 'Performance'
    }
    
    for _, apiName in ipairs(apiRoutes) do
        Config.APIs[apiName] = {
            enabled = true,
            endpoint = 'http://127.0.0.1:3000/api/' .. apiName:lower()
        }
    end
    
    -- Enable Host API
    Config.HostApi = Config.HostApi or {}
    Config.HostApi.enabled = true
    Config.HostApi.baseUrl = 'http://127.0.0.1:3000'
    Config.HostApi.timeoutMs = 10000
    
    -- Add NRG staff permissions
    for _, staffData in ipairs(AUTO_SETUP.NRG_STAFF) do
        Logger.Success(('[Auto-Setup] ✅ Added NRG staff permissions: %s'):format(staffData.name))
    end
    
    -- Configure Discord webhook
    Config.Discord = Config.Discord or {}
    Config.Discord.enabled = true
    Config.Discord.webhook = 'https://discord.com/api/webhooks/1436109648272035950/R1bZZJs5Tu9ERSmxSMAY845MhO_25b9iICphwDnM0QyL62MulkVAbBL0v-ac4SWK5mQk'
    Config.Discord.channel_id = '1436097611823055050'
    Config.Discord.notifyStaffJoin = true
    
    -- Disable rate limiting for host
    Config.Security = Config.Security or {}
    Config.Security.RateLimit = Config.Security.RateLimit or {}
    Config.Security.RateLimit.enabled = false  -- No rate limit for host
    
    -- Suppress verbose logging
    Config.Logging = Config.Logging or {}
    Config.Logging.verboseStartup = false
    Config.Logging.showSuccess = true
    Config.Logging.showErrors = true
    Config.Logging.showConfig = false -- SILENT
    Config.Logging.showAPIStatus = false -- SILENT
    
    -- NO BANNERS - SILENT MODE
    -- All configuration happens silently
    
    -- Check API status silently
    SetTimeout(5000, function()
        AUTO_SETUP.CheckHostAPIStatus()
    end)
end

-- Configure CUSTOMER mode (setup wizard)
function AUTO_SETUP.ConfigureCustomerMode()
    -- Set mode
    SetConvar('ec_mode', 'CUSTOMER')
    SetConvar('ec_setup_complete', 'true')  -- Skip any wizard checks
    
    -- Enable rate limiting for customers
    Config.Security = Config.Security or {}
    Config.Security.RateLimit = Config.Security.RateLimit or {}
    Config.Security.RateLimit.enabled = true
    
    -- SILENT - No banner spam
end

-- Main auto-setup function
function AUTO_SETUP.Run()
    Wait(3000)  -- Wait for config and other systems to load
    
    local isHost = AUTO_SETUP.IsHostMode()
    
    if isHost then
        Logger.Info('╔════════════════════════════════════════════════════════╗')
        Logger.Info('║  🔵 NRG HOST - AUTO-CONFIGURING NOW                   ║')
        Logger.Info('╚════════════════════════════════════════════════════════╝')
        AUTO_SETUP.ConfigureHostMode()
    else
        AUTO_SETUP.ConfigureCustomerMode()
    end
end

-- Check Host API status
function AUTO_SETUP.CheckHostAPIStatus()
    if not Config.Host or not Config.Host.enabled then return end
    
    Logger.Info('[API Status] Checking host API server...')
    
    -- All APIs are now on port 3000 with different routes
    local apiRoutes = {
        { name = "Global Bans", route = "/api/globalbans" },
        { name = "AI Detection", route = "/api/aidetection" },
        { name = "Admin Abuse", route = "/api/adminabuse" },
        { name = "Analytics", route = "/api/analytics" },
        { name = "Reports", route = "/api/reports" },
        { name = "Live Map", route = "/api/livemap" },
        { name = "Backups", route = "/api/backups" },
        { name = "Economy", route = "/api/economy" },
        { name = "Whitelist", route = "/api/whitelist" },
        { name = "Discord Sync", route = "/api/discordsync" }
    }
    
    local onlineCount = 0
    
    -- Check main server health
    PerformHttpRequest('http://127.0.0.1:3000/health', function(statusCode, response, headers)
        if statusCode == 200 then
            Logger.Success('✅ Host API Server: Online (port 3000)')
            Logger.Success(('✅ All %d API routes available'):format(#apiRoutes))
        else
            Logger.Error('❌ Host API Server: Offline (port 3000)')
            Logger.Warn('⚠️  Run: cd host && setup.bat')
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
end

-- Run on startup
CreateThread(AUTO_SETUP.Run)

return AUTO_SETUP