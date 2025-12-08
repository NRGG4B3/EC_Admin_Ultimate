--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                EC ADMIN ULTIMATE - Configuration              ║
    ║                 CUSTOMER MODE - Public Distribution           ║
    ║                    NRG Development © 2025                     ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    This is the CUSTOMER configuration file for EC Admin Ultimate.
    All API endpoints connect to api.ecbetasolutions.com
    No internal IPs or ports are exposed to customers.
]]

Config = Config or {}

-- ============================================================================
--  🌐 API BASE URL (Customer Mode - Always uses public API)
-- ============================================================================
local function getApiBaseUrl()
    -- Customer servers always connect to the public API domain
    return "https://api.ecbetasolutions.com"
end

-- ============================================================================
--  🔧 BASIC SETTINGS
-- ============================================================================

Config.MenuKey = 'F2'  -- Key to open admin menu (F1-F12 recommended)
Config.Framework = 'auto'  -- Auto-detect framework: 'auto', 'qb', 'qbx', 'esx', 'standalone'

-- Server Identity (shown in UI)
Config.ServerName = 'Your Server Name'  -- Displayed in admin panel header (CHANGE THIS!)
Config.ServerLogo = ''  -- URL to your server logo (optional - leave empty if none)

-- ============================================================================
--  📋 LOGGING CONFIGURATION (Centralized Logger)
-- ============================================================================

Config.LogFormat = 'detailed'  -- PRODUCTION DEFAULT: 'detailed' (timestamps, full context)
Config.LogLevel = 'INFO'  -- PRODUCTION: 'INFO' shows normal operations without excessive debug spam
Config.Debug = false  -- PRODUCTION: Set to false to disable excessive debug logging
Config.LogIcons = false  -- Emojis make logs easier to scan (recommended for 'detailed' format)
Config.LogNUIErrors = true  -- ⚠️ CRITICAL: Set to true to log ALL NUI errors (React errors, fetch failures, console errors, etc.)

-- ============================================================================
--  🔔 WEBHOOKS & DISCORD LOGGING (Visible in UI > Webhook Settings)
-- ============================================================================
-- To get a Discord webhook URL:
--   1. Go to your Discord server settings
--   2. Navigate to Integrations > Webhooks
--   3. Create a new webhook or copy an existing one
--   4. Paste the webhook URL below

Config.Webhooks = {
    enabled = true,
    provider = 'discord',
    defaultWebhookUrl = '',  -- Fallback URL if a category-specific URL is missing (ADD YOUR WEBHOOK HERE)

    embed = {
        username = 'EC Admin Logger',
        avatar = 'https://i.imgur.com/5cOmJ9y.png',
        footer = 'EC Admin Ultimate',
        showTimestamps = true,
        color = {
            menuClick    = 3447003,
            menuOpen     = 3066993,
            menuClose    = 3066993,
            pageChange   = 3447003,
            playerSelect = 16776960,
            adminAction  = 15158332,
            configChange = 10181046
        }
    },

    toggles = {
        menuClicks       = true,
        menuOpens        = true,
        pageChanges      = true,
        playerSelection  = true,
        configChanges    = true,
        adminActions     = true,
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

    urls = {
        adminMain = '',        -- 1. MAIN CHANNEL - General admin panel activity
        adminActions = '',     -- 2. ACTIONS - All admin actions
        adminBans = '',        -- 3. BANS - Player bans and unban actions
        adminReports = '',     -- 4. REPORTS - Player reports and report management
        adminEconomy = '',     -- 5. ECONOMY - Money/item transactions
        adminAntiCheat = '',   -- 6. ANTICHEAT - Anti-cheat detections
        adminAIDetection = '', -- 7. AI DETECTION - AI-powered behavior detection
        adminWhitelist = ''    -- 8. WHITELIST - Whitelist applications
    }
}

-- ============================================================================
--  🚗 VEHICLE SCANNING
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
    defaultPlate = 'ADMIN',
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
--  OWNER IDENTIFIERS (Fill in YOUR identifiers)
-- ============================================================================
-- HOW TO GET YOUR IDENTIFIERS:
-- 1. Join your server
-- 2. Open F8 console
-- 3. Look for "[EC Admin] Player identifiers:" in console logs
-- 4. Copy your Steam/License/Discord ID from the log
-- 5. Paste it below (keep the quotes!)

Config.Owners = {
    steam = '',      -- YOUR Steam Hex (e.g., 'steam:110000XXXXXXXXX')
    license = '',    -- YOUR License (e.g., 'license:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
    discord = '',    -- YOUR Discord ID (e.g., 'discord:123456789012345678')
    fivem = ''       -- YOUR FiveM ID (e.g., 'fivem:123456')
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
--  🌐 API CONFIGURATION (Customer Mode - Public API Only)
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
--  🔌 API MODULES (Customer Mode - Public API Gateway)
-- ============================================================================
-- All modules connect to api.ecbetasolutions.com
-- URLs are automatically resolved via the API gateway

Config.APIs = {
    GlobalBans = {
        enabled = true,
        bypassOwners = true,
        syncInterval = 60,
        cacheEnabled = true
    },
    AIDetection = {
        enabled = true,
        realtime = true,
        confidenceThreshold = 75,
        sendPlayerData = true,
        learningMode = true
    },
    AdminAbuse = {
        enabled = true,
        trackActions = true,
        flagSuspicious = true,
        alertOwners = true,
        thresholdScore = 80
    },
    Analytics = {
        enabled = true,
        trackPlayers = true,
        trackEconomy = true,
        trackPerformance = true,
        updateInterval = 300
    },
    ServerMetrics = {
        enabled = true,
        trackFPS = true,
        trackMemory = true,
        trackCPU = true,
        trackNetwork = true,
        alertOnIssues = true,
        reportInterval = 60
    },
    Reports = {
        enabled = true,
        allowPlayerReports = true,
        autoAssign = true,
        notifyAdmins = true,
        categories = { "Cheating", "Abuse", "RDM", "VDM", "Bug", "Other" }
    },
    LiveMap = {
        enabled = true,
        updateInterval = 5,
        showPlayers = true,
        showVehicles = true,
        showBlips = true,
        allowSpectate = true
    },
    Backups = {
        enabled = true,
        autoBackup = true,
        backupInterval = 3600,
        backupTypes = { "database", "resources", "config" },
        retention = 168
    },
    Economy = {
        enabled = true,
        trackTransactions = true,
        detectExploits = true,
        syncPlayerMoney = true,
        alertThreshold = 1000000
    },
    Whitelist = {
        enabled = true,
        enforceWhitelist = false,
        autoSync = true,
        allowApplications = true,
        notifyAdmins = true
    },
    DiscordSync = {
        enabled = true,
        syncRoles = true,
        syncNames = true,
        logActions = true,
        webhooks = true
    },
    VehicleData = {
        enabled = true,
        syncSpawned = true,
        syncOwnership = true,
        syncModifications = true,
        cacheVehicleList = true
    },
    Housing = {
        enabled = true,
        syncOwnership = true,
        syncInventories = true,
        allowRemoteManagement = true,
        trackActivity = true
    },
    Inventory = {
        enabled = true,
        syncPlayerInventories = true,
        syncStashes = true,
        trackItemFlow = true,
        detectDuplication = true
    },
    Jobs = {
        enabled = true,
        syncJobData = true,
        syncGangData = true,
        trackActivity = true,
        allowRemoteManagement = true
    },
    AntiCheat = {
        enabled = true,
        cloudDetection = true,
        shareDetections = true,
        autoUpdate = true,
        bannedResourcesCheck = true
    },
    Monitoring = {
        enabled = true,
        uptimeTracking = true,
        errorTracking = true,
        crashReporting = true,
        performanceAlerts = true
    },
    Webhooks = {
        enabled = true,
        allowCustomWebhooks = true,
        rateLimit = true,
        retryFailed = true
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
        enabled = true,
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
--  END OF CONFIGURATION
-- ============================================================================

return Config
