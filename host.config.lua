--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                EC ADMIN ULTIMATE - Configuration              ║
    ║                 HOST MODE - NRG INTERNAL USE ONLY             ║
    ║                    NRG Development © 2025                     ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    ⚠️ WARNING: This is the HOST configuration file
    ⚠️ This file contains internal IPs and secrets
    ⚠️ DO NOT distribute this file to customers
    ⚠️ This file is automatically loaded when host/ folder is detected
]]

Config = Config or {}

-- ============================================================================
--  🔐 HOST API CONFIGURATION (Must be at top - loaded before other configs)
-- ============================================================================
-- Host API Secret (must match .env HOST_SECRET)
Config.HostApi = {
    enabled = true,
    secret = "pER8jwAvs/K++anilkRWj74/9aZlIP3Sw1gSwx+0430="
}

-- ============================================================================
--  🌐 API BASE URL HELPER (Auto-detects host vs customer mode)
-- ============================================================================
local function getApiBaseUrl()
    if GetConvar and (GetConvar('ec_mode', 'CUSTOMER') == 'HOST') then
        return "http://127.0.0.1:3000"
    else
        return "https://api.ecbetasolutions.com"
    end
end

-- ============================================================================
--  🔧 BASIC SETTINGS
-- ============================================================================

Config.MenuKey = 'F2'  -- Key to open admin menu (F1-F12 recommended)
Config.Framework = 'auto'  -- Auto-detect framework: 'auto', 'qb', 'qbx', 'esx', 'standalone'

-- Server Identity (shown in UI)
Config.ServerName = 'NRG Development City'  -- Displayed in admin panel header
Config.ServerLogo = 'https://imgur.com/a/MDLTu7j'  -- URL to your server logo (optional)

-- ============================================================================
--  📋 LOGGING CONFIGURATION (Centralized Logger)
-- ============================================================================
-- ALL logs (server, client, NUI errors) go through the centralized Logger.
-- NO console.log, print, or direct output - everything uses Logger.*

-- Log Format Mode - Controls how messages appear in console
-- Options: 'simple', 'detailed', 'minimal'
Config.LogFormat = 'detailed'  -- PRODUCTION DEFAULT: 'detailed' (timestamps, full context)

-- Log Level - Controls what messages are shown (each level shows itself + more severe levels)
-- Options: 'DEBUG', 'INFO', 'WARN', 'ERROR', 'NONE'
Config.LogLevel = 'INFO'  -- PRODUCTION: 'INFO' shows normal operations without excessive debug spam

-- Debug Mode - Shortcut to enable all debug messages (overrides LogLevel to DEBUG)
Config.Debug = false  -- PRODUCTION: Set to false to disable excessive debug logging

-- Show Icons in Logs - Set to false to remove emojis from console
Config.LogIcons = false  -- Emojis make logs easier to scan (recommended for 'detailed' format)

-- NUI Error Logging - Log NUI/UI errors through centralized Logger
Config.LogNUIErrors = true  -- ⚠️ CRITICAL: Set to true to log ALL NUI errors (React errors, fetch failures, console errors, etc.)

-- ============================================================================
--  🔔 WEBHOOKS & DISCORD LOGGING (Visible in UI > Webhook Settings)
-- ============================================================================

Config.Webhooks = {
    enabled = true,                   -- Master switch: enable/disable all webhooks
    provider = 'discord',             -- 'discord' (current) | future: 'web', 'slack'
    defaultWebhookUrl = 'https://discord.com/api/webhooks/1436109648272035950/R1bZZJs5Tu9ERSmxSMAY845MhO_25b9iICphwDnM0QyL62MulkVAbBL0v-ac4SWK5mQk',           -- Fallback URL if a category-specific URL is missing

    -- Embed appearance (Discord)
    embed = {
        username = 'EC Admin Logger', -- Bot name shown in Discord
        avatar = 'https://i.imgur.com/5cOmJ9y.png', -- Bot avatar URL
        footer = 'EC Admin Ultimate', -- Footer text
        showTimestamps = true,        -- Add timestamps to embeds
        color = {
            menuClick    = 3447003,   -- Blue
            menuOpen     = 3066993,   -- Green
            menuClose    = 3066993,   -- Green
            pageChange   = 3447003,   -- Blue
            playerSelect = 16776960,  -- Yellow
            adminAction  = 15158332,  -- Red
            configChange = 10181046   -- Purple
        }
    },

    -- Per-category toggles (UI: Webhook Settings > Toggle Logging)
    toggles = {
        menuClicks       = true,
        menuOpens        = true,
        pageChanges      = true,
        playerSelection  = true,
        configChanges    = true,
        adminActions     = true,   -- master for all admin actions below
        teleports        = true,
        spectate         = true,
        noclip           = true,
        godMode          = true,
        freeze           = true,
        revive           = true,
        weaponGive       = true,
        itemGive         = true,
        moneyGive        = true,
        jobChange        = true,
        bans             = true,
        kicks            = true,
        warns            = true
    },

    -- Per-category webhook URLs (UI: Webhook Settings > URLs)
    urls = {
        adminMain       = 'https://discord.com/api/webhooks/1436109648272035950/R1bZZJs5Tu9ERSmxSMAY845MhO_25b9iICphwDnM0QyL62MulkVAbBL0v-ac4SWK5mQk',  -- "admin main" channel
        adminActions    = 'https://discord.com/api/webhooks/1444399117705941126/sKwNWESRPYOCF80BgwQrbg6iHotcIJTKGCLEWnWNrGo9HpIHftVvEn7Q0mVPtBl7vPso',  -- "admin actions" channel
        adminBans       = 'https://discord.com/api/webhooks/1444399345938989108/hJMDKrWAgJOY9_zXBK8476oCGY3baFLdFWEykBp2YAmSdQX1C2YZ0324LcSfXhfQftmU',  -- "admin bans" channel
        adminReports    = 'https://discord.com/api/webhooks/1444399619428716604/Cy_ihdmlj5ruZoQtJt91avHeyeF9_1w4euRmLZ-fy5y5MaFUWIXEftXyTDoQ5PyJyYAo',  -- "admin reports" channel
        adminEconomy    = 'https://discord.com/api/webhooks/1444399871648993472/FQn0yTMJJHSnKYVMPJ4iD-DI8Tq8hKpaTyJ4-r7voSWjwBEan3ghHTdefCZgP_l08v9r',  -- "admin economy" channel
        adminAntiCheat  = 'https://discord.com/api/webhooks/1444400029086257253/LQEkNOcfez9y4clH6pVmlRo429IaYROm3GGVeBVXp8dp23wfALcySiODdDEPKzeskk01',  -- "admin anti cheat" channel
        adminAIDetection= 'https://discord.com/api/webhooks/1444400228248719413/f215IFEpNejmMkWiT6mM4mr_CfHeUFvonF9L8kAV5Nw0vbX5Tiyl5LnxndjEfOGoUwHJ',  -- "admin ai detection" channel
        adminWhitelist  = 'https://discord.com/api/webhooks/1444400367029719170/0mXZjZck5Q_gQKQaD3OwhMGw43VO7t2F5Lmj2pnbNHdUVdbaU83IVwh7CjkdBHa7oBCc'   -- "admin whitelist" channel
    }
}

-- ============================================================================
--  🚗 VEHICLE SCANNING (Auto-detect all vehicle packs)
-- ============================================================================

Config.VehicleScanning = {
    enabled = true,
    scanOnStartup = true,
    scanInterval = 300000,
    scanDeepCheck = true,
    excludeResources = {
        'mapmanager',
        'chat',
        'spawnmanager',
        'sessionmanager',
        'basic-gamemode',
        'hardcap',
        'rconlog'
    }
}

Config.VehicleSpawn = {
    defaultPlate = 'ECBetaG4B3',
    spawnInVehicle = true,
    fullyUpgraded = false,
    godMode = false
}

-- ============================================================================
--  🎨 UI SETTINGS
-- ============================================================================

Config.UI = {
    openKey = 'F2',
    theme = 'dark',
    language = 'en',
    animations = true,
    sounds = true,
    compactMode = true,
    showWelcome = true,
    autoRefresh = true,
    refreshInterval = 10,
    accentColor = '#3b82f6',
    enableSounds = true,
    showTooltips = true,
    dateFormat = 'YYYY-MM-DD',
    timeFormat = '24h',
    timezone = 'UTC'
}

-- ============================================================================
--  PERMISSIONS SETUP
-- ============================================================================

Config.Permissions = {
    system = 'both',
    syncInterval = 300
}

-- ============================================================================
--  OWNER IDENTIFIERS
-- ============================================================================

Config.Owners = {
    steam = 'live:914798925490170',
    license = 'license:8a8b3d2426734b69ac381c536c670f6958283cda',
    discord = 'discord:1219846819417292833',
    fivem = 'fivem:14682797'
}

-- ============================================================================
--  ADMIN TEAM
-- ============================================================================

Config.AdminTeam = {
    members = {},
    ranks = {
        owner = {
            label = "Owner",
            permissions = {"ec_admin.all"},
            color = "#FF0000"
        },
        super_admin = {
            label = "Super Admin",
            permissions = {
                "ec_admin.menu",
                "ec_admin.ban",
                "ec_admin.kick",
                "ec_admin.warn",
                "ec_admin.teleport",
                "ec_admin.noclip",
                "ec_admin.spectate",
                "ec_admin.freeze",
                "ec_admin.revive",
                "ec_admin.givemoney",
                "ec_admin.giveitem",
                "ec_admin.vehicle.spawn",
                "ec_admin.vehicle.delete",
                "ec_admin.announce",
                "ec_admin.reports.manage"
            },
            color = "#FF4444"
        },
        admin = {
            label = "Admin",
            permissions = {
                "ec_admin.menu",
                "ec_admin.kick",
                "ec_admin.warn",
                "ec_admin.teleport",
                "ec_admin.freeze",
                "ec_admin.revive",
                "ec_admin.vehicle.spawn",
                "ec_admin.reports.view"
            },
            color = "#4444FF"
        },
        moderator = {
            label = "Moderator",
            permissions = {
                "ec_admin.menu",
                "ec_admin.warn",
                "ec_admin.freeze",
                "ec_admin.reports.view"
            },
            color = "#44FF44"
        },
        support = {
            label = "Support",
            permissions = {
                "ec_admin.menu",
                "ec_admin.teleport",
                "ec_admin.revive",
                "ec_admin.reports.view"
            },
            color = "#FFAA00"
        }
    }
}

-- ============================================================================
--  DATABASE
-- ============================================================================

Config.Database = {
    enabled = true,
    useMySQL = true
}

-- ============================================================================
--  🌐 API CONFIGURATION (HOST MODE - Localhost APIs)
-- ============================================================================

Config.API = {
    baseUrl = getApiBaseUrl(),
    timeout = 10000,
    retryAttempts = 3,
    retryDelay = 1000,
    authentication = {
        enabled = true,
        method = "bearer",
        autoRefresh = true,
        tokenExpiry = 3600
    },
    rateLimit = {
        enabled = true,
        requestsPerMinute = 120,
        burstLimit = 30
    }
}

-- ============================================================================
--  🔌 API MODULES (HOST MODE - Localhost URLs)
-- ============================================================================

Config.APIs = {
    GlobalBans = {
        enabled = true,
        url = "http://127.0.0.1:3001/api/global-bans",
        bypassOwners = true,
        bypassNRGStaff = true,
        syncInterval = 60,
        cacheEnabled = true
    },
    AIDetection = {
        enabled = true,
        url = "http://127.0.0.1:3002/api/ai-detection",
        realtime = true,
        confidenceThreshold = 75,
        sendPlayerData = true,
        learningMode = true
    },
    AdminAbuse = {
        enabled = true,
        url = "http://127.0.0.1:3018/api/emergency",
        trackActions = true,
        flagSuspicious = true,
        alertOwners = true,
        thresholdScore = 80
    },
    Analytics = {
        enabled = true,
        url = "http://127.0.0.1:3003/api/analytics",
        trackPlayers = true,
        trackEconomy = true,
        trackPerformance = true,
        updateInterval = 300
    },
    ServerMetrics = {
        enabled = true,
        url = "http://127.0.0.1:3004/api/metrics",
        trackFPS = true,
        trackMemory = true,
        trackCPU = true,
        trackNetwork = true,
        alertOnIssues = true,
        reportInterval = 60
    },
    Reports = {
        enabled = true,
        url = "http://127.0.0.1:3005/api/reports",
        allowPlayerReports = true,
        autoAssign = true,
        notifyAdmins = true,
        categories = { "Cheating", "Abuse", "RDM", "VDM", "Bug", "Other" }
    },
    LiveMap = {
        enabled = true,
        url = "http://127.0.0.1:3012/api/servers",
        updateInterval = 5,
        showPlayers = true,
        showVehicles = true,
        showBlips = true,
        allowSpectate = true
    },
    Backups = {
        enabled = true,
        url = "http://127.0.0.1:3007/api/backups",
        autoBackup = true,
        backupInterval = 3600,
        backupTypes = { "database", "resources", "config" },
        retention = 168
    },
    Economy = {
        enabled = true,
        url = "http://127.0.0.1:3013/api/license",
        trackTransactions = true,
        detectExploits = true,
        syncPlayerMoney = true,
        alertThreshold = 1000000
    },
    Whitelist = {
        enabled = true,
        url = "http://127.0.0.1:3014/api/updates",
        enforceWhitelist = false,
        autoSync = true,
        allowApplications = true,
        notifyAdmins = true
    },
    DiscordSync = {
        enabled = true,
        url = "http://127.0.0.1:3015/api/audit",
        syncRoles = true,
        syncNames = true,
        logActions = true,
        webhooks = true
    },
    VehicleData = {
        enabled = true,
        url = "http://127.0.0.1:3016/api/performance",
        syncSpawned = true,
        syncOwnership = true,
        syncModifications = true,
        cacheVehicleList = true
    },
    Housing = {
        enabled = true,
        url = "http://127.0.0.1:3017/api/resources",
        syncOwnership = true,
        syncInventories = true,
        allowRemoteManagement = true,
        trackActivity = true
    },
    Inventory = {
        enabled = true,
        url = "http://127.0.0.1:3008/api/screenshots",
        syncPlayerInventories = true,
        syncStashes = true,
        trackItemFlow = true,
        detectDuplication = true
    },
    Jobs = {
        enabled = true,
        url = "http://127.0.0.1:3010/api/chat",
        syncJobData = true,
        syncGangData = true,
        trackActivity = true,
        allowRemoteManagement = true
    },
    AntiCheat = {
        enabled = true,
        url = "http://127.0.0.1:3006/api/anticheat",
        cloudDetection = true,
        shareDetections = true,
        autoUpdate = true,
        bannedResourcesCheck = true
    },
    Monitoring = {
        enabled = true,
        url = "http://127.0.0.1:3011/api/players",
        uptimeTracking = true,
        errorTracking = true,
        crashReporting = true,
        performanceAlerts = true
    },
    Webhooks = {
        enabled = true,
        url = "http://127.0.0.1:3009/api/webhooks",
        allowCustomWebhooks = true,
        rateLimit = true,
        retryFailed = true
    },
    HostDashboard = {
        enabled = true,
        url = "http://127.0.0.1:3019/api/host",
        nrgStaffAutoAccess = true,
        requireApproval = true,
        showRevenue = true,
        showServers = true,
        showAnalytics = true
    }
}

-- ============================================================================
--  👥 NRG STAFF CONFIGURATION (Auto-Access System)
-- ============================================================================

Config.NRGStaff = {
    autoAccess = {
        enabled = true,
        checkAPI = true,
        grantPermissions = {
            "ec_admin.all",
            "ec_admin.host.dashboard",
            "ec_admin.nrg.staff"
        },
        showHostDashboard = true,
        bypassWhitelist = true,
        bypassBans = true,
        logAccess = true
    },
    verification = {
        method = "api",
        cacheTimeout = 3600,
        fallbackToLocal = true
    },
    hostDashboard = {
        autoShow = true,
        requireApproval = true,
        permissions = {
            "view_revenue",
            "view_servers",
            "view_analytics",
            "manage_apis",
            "manage_features"
        }
    }
}

-- ============================================================================
--  FEATURES
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
    fpsOptimizer = true
}

-- ============================================================================
--  SECURITY & ANTI-CHEAT CONFIGURATION
-- ============================================================================

Config.AntiCheat = {
    enabled = true,
    aiIntegration = true,
    autoActions = false,
    sensitivity = 75,
    banThreshold = 90,
    kickThreshold = 75,
    warnThreshold = 60,
    scanInterval = 500,
    scanAllPlayers = true,
    logAll = true,
    verboseLogging = false,
    discordWebhook = "https://discord.com/api/webhooks/1444400029086257253/LQEkNOcfez9y4clH6pVmlRo429IaYROm3GGVeBVXp8dp23wfALcySiODdDEPKzeskk01",
    sendScreenshots = true,
    modules = {
        speedHack = { enabled = true, sensitivity = 85, autoAction = 'ban', thresholds = { vehicle = 500, player = 50 } },
        teleportHack = { enabled = true, sensitivity = 80, autoAction = 'kick', thresholds = { distance = 100, timeWindow = 1000 } },
        noClip = { enabled = true, sensitivity = 90, autoAction = 'ban', exemptAdmins = true },
        aimbot = { enabled = true, sensitivity = 90, autoAction = 'ban', thresholds = { headshotRate = 85, aimSpeed = 500 } },
        triggerbot = { enabled = true, sensitivity = 70, autoAction = 'warn', thresholds = { reactionTime = 50 } },
        godMode = { enabled = true, sensitivity = 95, autoAction = 'ban', exemptAdmins = true },
        esp = { enabled = true, sensitivity = 75, autoAction = 'warn', thresholds = { wallKills = 10 } },
        luaInjection = { enabled = true, sensitivity = 98, autoAction = 'ban' },
        resourceInjection = { enabled = true, sensitivity = 95, autoAction = 'ban' },
        moneyExploit = { enabled = true, sensitivity = 85, autoAction = 'kick', thresholds = { moneyPerMinute = 100000, instantIncrease = 500000 } },
        itemDuplication = { enabled = true, sensitivity = 80, autoAction = 'kick', thresholds = { itemsPerMinute = 10, duplicateThreshold = 5 } },
        vehicleModification = { enabled = true, sensitivity = 85, autoAction = 'kick', thresholds = { modificationLevel = 150 } }
    },
    whitelist = {},
    trustSystem = {
        enabled = false,
        startingScore = 50,
        increaseRate = 1,
        decreaseOnDetection = { critical = 30, high = 20, medium = 10, low = 5 },
        riskLevels = { safe = 80, low = 60, medium = 40, high = 20, critical = 0 }
    }
}

-- ============================================================================
--  SECURITY
-- ============================================================================

Config.Security = {
    RateLimit = { enabled = true, requestsPerMinute = 60, burst = 30 },
    CORS = { enabled = true, origins = { "http://127.0.0.1", "http://localhost" }, methods = { "GET", "POST", "OPTIONS" }, headers = { "Content-Type", "Authorization" } },
    sessionTimeout = 3600,
    maxLoginAttempts = 5,
    lockoutDuration = 300,
    sqlProtection = true,
    xssProtection = true,
    bruteForceProtection = { enabled = true, maxAttempts = 5, timeWindow = 300, banDuration = 3600 },
    ipWhitelist = { enabled = false, ips = {} },
    encryption = { enabled = true, algorithm = "AES256", rotateKeys = true, keyRotationInterval = 604800 }
}

-- ============================================================================
--  PERFORMANCE & OPTIMIZATION
-- ============================================================================

Config.Performance = {
    optimized = true,
    cachePlayerData = true,
    cacheDuration = 300,
    threads = { useNatives = true, reduceTicks = true, smartThreading = true },
    fpsOptimizer = { enabled = true, removeUnusedPeds = true, removeUnusedVehicles = true, optimizeDistance = true, distanceChecks = { players = 250.0, vehicles = 200.0, objects = 150.0 } },
    database = { pooling = true, maxConnections = 10, preparedStatements = true, transactionBatching = true },
    network = { compression = true, batchEvents = true, throttleUpdates = true, maxPacketSize = 16384 }
}

-- ============================================================================
--  ✅ WHITELIST CONFIGURATION (ON by default for host)
-- ============================================================================

Config.Whitelist = {
    enabled = false,  -- Whitelist is OFF by default (can be enabled)
    requireApproval = false,
    autoApprove = false,
    discordRoleId = '1422467513224007760',  -- Discord role ID for whitelist (if using role-based)
    discordBotToken = '',  -- Discord bot token (optional, for role checking)
    discordGuildId = ''   -- Discord server/guild ID (optional, for role checking)
}

-- ============================================================================
--  GAMEPLAY SETTINGS
-- ============================================================================

Config.Gameplay = {
    teleport = { enabled = true, showMarker = true, fadeScreen = true, soundEffect = true, cooldown = 0 },
    spectate = { enabled = true, showHUD = true, showNames = true, allowControls = false, exitKey = 'BACK' },
    noclip = { enabled = true, speed = { normal = 1.0, fast = 5.0, superFast = 10.0 }, showControls = true, soundEffects = true },
    revive = { enabled = true, fullHealth = true, fullArmor = false, healInjuries = true, soundEffect = true },
    godMode = { enabled = true, invincible = true, noRagdoll = true, infiniteStamina = true, unlimitedAmmo = false },
    freeze = { enabled = true, showNotification = true, allowLook = true, showTimer = true }
}

-- ============================================================================
--  ECONOMY SETTINGS
-- ============================================================================

Config.Economy = {
    money = { defaultCurrency = "cash", maxAmount = 999999999, minAmount = 0, logTransactions = true, preventNegative = true },
    giveMoney = { enabled = true, maxAmountPerGive = 1000000, requireReason = true, notifyPlayer = true, thresholdForNotification = 10000 },
    removeMoney = { enabled = true, requireReason = true, notifyPlayer = true, allowNegativeBalance = false },
    items = { enabled = true, maxStackSize = 999, logGiven = true, preventDuplicates = true }
}

-- ============================================================================
--  HOUSING INTEGRATION
-- ============================================================================

Config.Housing = {
    enabled = true,
    framework = "auto",
    management = { viewAll = true, editOwnership = true, viewInventories = true, teleportToHouse = true, unlockHouses = true },
    remoteAccess = { enabled = true, viewFromMap = true, editFromPanel = true }
}

-- ============================================================================
--  INVENTORY INTEGRATION
-- ============================================================================

Config.Inventory = {
    enabled = true,
    framework = "auto",
    management = { viewPlayerInventory = true, editPlayerInventory = true, giveItems = true, removeItems = true, clearInventory = true, viewStashes = true },
    restrictions = { blacklistedItems = {}, maxWeight = 100000, maxSlots = 50 }
}

-- ============================================================================
--  JOBS & GANGS INTEGRATION
-- ============================================================================

Config.Jobs = {
    enabled = true,
    framework = "auto",
    management = { setPlayerJob = true, setJobGrade = true, viewAllJobs = true, editJobData = true, createJobs = true },
    gangs = { enabled = true, setPlayerGang = true, viewAllGangs = true, editGangData = true }
}

-- ============================================================================
--  EMERGENCY SERVICES
-- ============================================================================

Config.Emergency = {
    police = { enabled = true, viewActiveCalls = true, viewOfficers = true, dispatchCalls = true, managePursuits = true },
    ems = { enabled = true, viewActiveCalls = true, viewMedics = true, dispatchCalls = true, forceRevive = true }
}

-- ============================================================================
--  WORLD SETTINGS
-- ============================================================================

Config.World = {
    time = { enabled = true, allowChange = true, syncWithRealTime = false, defaultHour = 12 },
    weather = { enabled = true, allowChange = true, syncedWeather = true, availableWeathers = { "CLEAR", "EXTRASUNNY", "CLOUDS", "OVERCAST", "RAIN", "THUNDER", "CLEARING", "NEUTRAL", "SNOW", "BLIZZARD", "SNOWLIGHT", "XMAS" } },
    blackout = { enabled = true, affectTrafficLights = true, affectStreetLights = true }
}

-- ============================================================================
--  HOST MODE CONFIGURATION (AUTO-DETECTED)
-- ============================================================================

Config.Host = Config.Host or {
    enabled = false,  -- Auto-set to true ONLY if /host/ folder exists
    mode = "customer",
    api = {
        enabled = true,
        port = 30121,
        protocol = "http",
        host = "127.0.0.1",
        secret = "pER8jwAvs/K++anilkRWj74/9aZlIP3Sw1gSwx+0430=",
        timeout = 10000
    },
    revenue = {
        enabled = true,
        trackSubscriptions = true,
        trackUsage = true,
        reportInterval = 3600
    },
    servers = {
        enabled = true,
        autoDiscover = true,
        centralizedLogs = true,
        globalAnalytics = true
    }
}

-- ============================================================================
--  END OF CONFIGURATION
-- ============================================================================

return Config
