--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                EC ADMIN ULTIMATE - Configuration              ║
    ║                 Production-Ready Configuration                ║
    ║                    NRG Development © 2025                     ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    This is the main configuration file for EC Admin Ultimate.
    Configure once and deploy - designed for production use.
]]

Config = {}

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

--[[
    Log Format Examples:
    
    'detailed' (SHIPPING DEFAULT - Full context with timestamps):
        [2025-12-01 20:49:00] ✅ [EC Admin] [SUCCESS] Dashboard callbacks loaded successfully
        [2025-12-01 20:49:00] ⚠️ [EC Admin] [WARN] Config.Webhooks.enabled is false
        [2025-12-01 20:49:00] ❌ [EC Admin] [ERROR] Failed to connect to database
        Best for: Production - clear timestamps, easy troubleshooting
    
    'simple' (Clean and readable - No timestamps):
        [EC Admin] ✅ Dashboard callbacks loaded successfully
        [EC Admin] ⚠️ Config.Webhooks.enabled is false
        [EC Admin] ❌ Failed to connect to database
        Best for: Development - less clutter, faster scanning
    
    'minimal' (No icons, no levels - Cleanest):
        [EC Admin] Dashboard callbacks loaded successfully
        [EC Admin] Config.Webhooks.enabled is false
        [EC Admin] Failed to connect to database
        Best for: Minimalist production - no emoji clutter
]]

-- Log Level - Controls what messages are shown (each level shows itself + more severe levels)
-- Options: 'DEBUG', 'INFO', 'WARN', 'ERROR', 'NONE'
Config.LogLevel = 'info'  -- PRODUCTION: 'info' shows normal operations without excessive debug spam

--[[
    Log Level Hierarchy (what each level shows):
    
    'DEBUG':  Shows EVERYTHING
              ✓ Debug messages, Info, Success, Warnings, Errors, System messages
              Use for: Development, troubleshooting
    
    'INFO':   Shows normal operations + issues
              ✓ Info, Success, Warnings, Errors, System messages
              ✗ Debug messages hidden
              Use for: Production (DEFAULT), normal server operation
    
    'WARN':   Shows only warnings and errors
              ✓ Warnings, Errors
              ✗ Debug, Info, Success hidden
              Use for: Production with minimal logging
    
    'ERROR':  Shows ONLY errors
              ✓ Errors only
              ✗ Everything else hidden (warnings, info, success, debug)
              Use for: Silent production, only want to see problems
    
    'NONE':   Complete silence - NO LOGS AT ALL
              ✗ Everything hidden
              Use for: Completely silent operation
]]

-- Debug Mode - Shortcut to enable all debug messages (overrides LogLevel to DEBUG)
Config.Debug = false  -- PRODUCTION: Set to false to disable excessive debug logging

-- Show Icons in Logs - Set to false to remove emojis from console
Config.LogIcons = false  -- Emojis make logs easier to scan (recommended for 'detailed' format)

-- NUI Error Logging - Log NUI/UI errors through centralized Logger
Config.LogNUIErrors = true  -- PRODUCTION: true (catch React errors, fetch failures, etc.)

-- ============================================================================
--  � WEBHOOKS & DISCORD LOGGING (Visible in UI > Webhook Settings)
-- ============================================================================
-- This section mirrors the Webhook Settings page in the admin menu so you can
-- see and edit everything from config as well. The UI reads and writes these.

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
    -- Named channels (replace with your actual webhook URLs)
    -- These map to the menu's Webhook Settings channels
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
--  �🚗 VEHICLE SCANNING (Auto-detect all vehicle packs)
-- ============================================================================
-- Automatically scans ALL loaded vehicles from resource meta files
-- Supports: FiveM vehicle packs, custom addon vehicles, DLC vehicles

Config.VehicleScanning = {
    enabled = true,  -- Enable automatic vehicle scanning (RECOMMENDED)
    scanOnStartup = true,  -- Scan all vehicles when resource starts
    scanInterval = 300000,  -- Re-scan every 5 minutes (300000ms) to detect new vehicles
    scanDeepCheck = true,  -- Verify each vehicle model exists in game (slower but more accurate)
    excludeResources = {  -- Resources to skip during vehicle scanning
        'mapmanager',
        'chat',
        'spawnmanager',
        'sessionmanager',
        'basic-gamemode',
        'hardcap',
        'rconlog'
    }
}

-- Vehicle Spawn Settings
Config.VehicleSpawn = {
    defaultPlate = 'ECBetaG4B3',  -- Default plate for spawned vehicles
    spawnInVehicle = true,  -- Put admin in vehicle after spawning
    fullyUpgraded = false,  -- Max upgrades on spawned vehicles
    godMode = false  -- Make spawned vehicles invincible
}

-- ============================================================================
--  🎨 UI SETTINGS
-- ============================================================================

Config.UI = {
    openKey = 'F2',  -- Key to open admin panel
    theme = 'dark',  -- 'dark' or 'light' (dark recommended)
    language = 'en',  -- 'en', 'es', 'fr', 'de' (more coming soon)
    animations = true,  -- Enable UI animations
    sounds = true,  -- Enable UI sounds
    compactMode = true,  -- Compact sidebar (more screen space)
    showWelcome = true  -- Show welcome message on first open
}

-- ============================================================================
--  PERMISSIONS SETUP - READ THIS!
-- ============================================================================
--
-- METHOD 1: ACE PERMISSIONS (Recommended - Add to server.cfg)
--   add_ace identifier.steam:YOUR_STEAM_HEX ec_admin.all allow
--   add_ace identifier.license:YOUR_LICENSE ec_admin.all allow
--   add_ace identifier.discord:YOUR_DISCORD_ID ec_admin.all allow
--
-- METHOD 2: OWNER IDENTIFIERS (See below)
--   Fill in Config.Owners with your Steam/License/Discord/FiveM ID
--
-- METHOD 3: FRAMEWORK GROUPS (Automatic)
--   Admin/god job or superadmin group gets access automatically
--
-- ============================================================================

Config.Permissions = {
    system = 'both',  -- both (ACE + Database), ace (ACE only), or database (DB only)
    syncInterval = 300  -- seconds between permission refreshes
}

-- ============================================================================
--  OWNER IDENTIFIERS (Method 2 - Fill in YOUR identifiers)
-- ============================================================================
--
-- HOW TO GET YOUR IDENTIFIERS:
-- 1. Join your server
-- 2. Open F8 console
-- 3. Look for "[EC Admin] Player identifiers:" in console logs
-- 4. Copy your Steam/License/Discord ID from the log
-- 5. Paste it below (keep the quotes!)
--
-- EXAMPLE:
-- Config.Owners = {
--     steam = 'steam:110000103fd1bb1',
--     license = 'license:a1b2c3d4e5f6g7h8i9j0',
--     discord = 'discord:123456789012345678',
--     fivem = 'fivem:123456'
-- }
-- ============================================================================

Config.Owners = {
    steam = 'live:914798925490170',  -- steam:110000XXXXXXXXX (YOUR Steam Hex - See console when you join!)
    license = 'license:8a8b3d2426734b69ac381c536c670f6958283cda',  -- license:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    discord = 'discord:1219846819417292833',  -- discord:XXXXXXXXXXXXXXXXXX
    fivem = 'fivem:14682797'  -- fivem:XXXXXX
}

-- ============================================================================
--  ADMIN TEAM (Configure your admins here OR in-game via UI)
-- ============================================================================

Config.AdminTeam = {
    -- Admin Team Members (can be managed from UI Settings > Admin Team)
    members = {
        -- Example entries (remove or uncomment to use):
        -- {
        --     identifier = "steam:110000123456789",  -- Steam/License/Discord ID
        --     name = "John Doe",                      -- Display name
        --     rank = "super_admin",                   -- admin, super_admin, moderator
        --     permissions = {"ec_admin.all"}          -- Custom permissions (optional)
        -- },
        -- {
        --     identifier = "license:abc123def456",
        --     name = "Jane Smith",
        --     rank = "admin",
        --     permissions = {"ec_admin.menu", "ec_admin.ban", "ec_admin.kick"}
        -- },
    },
    
    -- Rank Templates (predefined permission sets)
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
--  DATABASE (OPTIONAL)
-- ============================================================================

Config.Database = {
    enabled = true,  -- Set false to disable (uses memory only)
    useMySQL = true  -- true for MySQL/MariaDB, false for SQLite
}

-- ============================================================================
-- IMPORTANT: MySQL Configuration is done in server.cfg, NOT here!
-- ============================================================================
--
-- Add this to your server.cfg:
--
--     ensure oxmysql
--     set mysql_connection_string "mysql://username:password@localhost/database_name"
--
-- Replace with your actual database credentials:
--   username = your MySQL username (e.g., root)
--   password = your MySQL password
--   localhost = your MySQL server IP (localhost if on same machine)
--   database_name = your database name (e.g., fivem or ec_admin)
--
-- Example:
--     set mysql_connection_string "mysql://root:MyPassword123@localhost/fivem"
--
-- If you DON'T have a database set up:
--   1. Set Config.Database.enabled = false above
--   2. EC Admin will work in memory-only mode (data lost on restart)
--
-- ============================================================================

-- ============================================================================
--  DISCORD (OPTIONAL)
-- ============================================================================

Config.Discord = {
    enabled = true,  -- Enable Discord webhooks
    webhook = "https://discord.com/api/webhooks/1436109648272035950/R1bZZJs5Tu9ERSmxSMAY845MhO_25b9iICphwDnM0QyL62MulkVAbBL0v-ac4SWK5mQk",  -- Your Discord webhook URL
    
    -- Action Logging (what gets logged to Discord)
    logBans = true,
    logKicks = true,
    logWarns = true,
    logEconomy = true,
    logVehicles = true,
    logTeleports = true,
    logSpectate = true,
    logNoclip = true,
    logGodMode = true,
    logFreeze = true,
    logRevive = true,
    logWeaponGive = true,
    logItemGive = true,
    logMoneyGive = true,
    logJobChange = true,
    logAdminActions = true,  -- Log ALL admin actions
    logMenuOpens = true,  -- Log when menu is opened
    logMenuClicks = true,  -- Log every menu click/interaction
    logPageChanges = true,  -- Log page navigation in menu
    logPlayerSelection = true,  -- Log when admin selects a player
    logConfigChanges = true,  -- Log config changes from UI
    
    -- Console Logging (what gets logged to server console)
    consoleLogging = {
        enabled = true,  -- Enable console logging
        logLevel = 'info',  -- debug, info, warn, error
        logMenuClicks = false,  -- Log every UI click to console
        logMenuNavigation = false,  -- Log page changes to console
        logPlayerActions = true,  -- Log player actions to console
        logAdminActions = true,  -- Log admin actions to console
        showTimestamps = true,  -- Show timestamps in console logs
        showAdminName = true,  -- Show admin name in logs
        showTargetName = true  -- Show target player name in logs
    },
    
    -- Discord Role-Based Permissions (NEW!)
    rolePermissions = {
        enabled = false,  -- Enable Discord role-based permissions
        guildId = "",  -- Your Discord server ID
        botToken = "",  -- Your Discord bot token (keep secret!)
        
        -- Admin Roles (grant ec_admin.menu permission)
        adminRoles = {
            -- Example: "1234567890123456789",  -- Admin role ID
            -- Example: "9876543210987654321",  -- Moderator role ID
        },
        
        -- Super Admin Roles (grant ec_admin.super permission)
        superAdminRoles = {
            -- Example: "1111111111111111111",  -- Head Admin role ID
        },
        
        -- Full Access Roles (grant all permissions)
        fullAccessRoles = {
            -- Example: "2222222222222222222",  -- Owner role ID
        },
        
        -- Custom Role Mappings (map Discord roles to specific ACE permissions)
        customRoleMappings = {
            -- Example:
            -- {
            --     roleId = "3333333333333333333",  -- Support role ID
            --     acePermissions = {
            --         "ec_admin.menu",
            --         "ec_admin.teleport",
            --         "ec_admin.revive",
            --         "ec_admin.reports.view"
            --     }
            -- },
            -- {
            --     roleId = "4444444444444444444",  -- Trial Mod role ID
            --     acePermissions = {
            --         "ec_admin.menu",
            --         "ec_admin.warn",
            --         "ec_admin.freeze"
            --     }
            -- }
        }
    }
}

-- ============================================================================
--  🌐 API CONFIGURATION (ALL APIs at api.ecbetasolutions.com)
-- ============================================================================
-- ALL API endpoints connect to api.ecbetasolutions.com
-- VPS IPs are NEVER exposed to customers
-- NRG staff get automatic access when visiting customer servers

Config.API = {
    -- Base API Configuration
    baseUrl = "https://api.ecbetasolutions.com",  -- Production API endpoint
    timeout = 10000,  -- Request timeout (milliseconds)
    retryAttempts = 3,  -- Retry failed requests
    retryDelay = 1000,  -- Delay between retries (milliseconds)
    
    -- API Authentication (auto-managed)
    authentication = {
        enabled = true,
        method = "bearer",  -- bearer token authentication
        autoRefresh = true,  -- Auto-refresh expired tokens
        tokenExpiry = 3600  -- Token validity (seconds)
    },
    
    -- Rate Limiting (prevent API abuse)
    rateLimit = {
        enabled = true,
        requestsPerMinute = 120,
        burstLimit = 30
    }
}

-- ============================================================================
--  🔌 API MODULES (Enable/Disable Features)
-- ============================================================================
-- All modules connect to api.ecbetasolutions.com
-- Enable/disable features as needed for your server

Config.APIs = {
    -- Global Ban System (shared bans across all NRG servers)
    GlobalBans = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3001/api/global-bans",
        bypassOwners = true,
        bypassNRGStaff = true,
        syncInterval = 60,
        cacheEnabled = true
    },
    
    -- AI Detection & Behavior Analytics
    AIDetection = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3002/api/ai-detection",
        realtime = true,
        confidenceThreshold = 75,
        sendPlayerData = true,
        learningMode = true
    },
    
    -- Admin Abuse Monitoring (prevents admin power abuse)
    AdminAbuse = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3002/api/admin-abuse",
        trackActions = true,
        flagSuspicious = true,
        alertOwners = true,
        thresholdScore = 80
    },
    
    -- Server Analytics & Statistics
    Analytics = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3003/api/player-analytics",
        trackPlayers = true,
        trackEconomy = true,
        trackPerformance = true,
        updateInterval = 300
    },
    
    -- Server Metrics & Health Monitoring
    ServerMetrics = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3004/api/server-metrics",
        trackFPS = true,
        trackMemory = true,
        trackCPU = true,
        trackNetwork = true,
        alertOnIssues = true,
        reportInterval = 60
    },
    
    -- Player Reports System
    Reports = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3005/api/reports",
        allowPlayerReports = true,
        autoAssign = true,
        notifyAdmins = true,
        categories = { "Cheating", "Abuse", "RDM", "VDM", "Bug", "Other" }
    },
    
    -- Live Server Map (real-time player positions)
    LiveMap = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3010/api/livemap",
        updateInterval = 5,
        showPlayers = true,
        showVehicles = true,
        showBlips = true,
        allowSpectate = true
    },
    
    -- Automated Backups
    Backups = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3007/api/backups",
        autoBackup = true,
        backupInterval = 3600,
        backupTypes = { "database", "resources", "config" },
        retention = 168
    },
    
    -- Economy Management & Tracking
    Economy = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3009/api/economy",
        trackTransactions = true,
        detectExploits = true,
        syncPlayerMoney = true,
        alertThreshold = 1000000
    },
    
    -- Whitelist System
    Whitelist = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3013/api/whitelist",
        enforceWhitelist = false,
        autoSync = true,
        allowApplications = true,
        notifyAdmins = true
    },
    
    -- Discord Integration & Sync
    DiscordSync = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3000/api/discord",
        syncRoles = true,
        syncNames = true,
        logActions = true,
        webhooks = true
    },
    
    -- Vehicle Database & Management
    VehicleData = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3000/api/vehicles",
        syncSpawned = true,
        syncOwnership = true,
        syncModifications = true,
        cacheVehicleList = true
    },
    
    -- Housing System Integration
    Housing = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3000/api/housing",
        syncOwnership = true,
        syncInventories = true,
        allowRemoteManagement = true,
        trackActivity = true
    },
    
    -- Inventory System Integration
    Inventory = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3000/api/inventory",
        syncPlayerInventories = true,
        syncStashes = true,
        trackItemFlow = true,
        detectDuplication = true
    },
    
    -- Jobs & Gangs Management
    Jobs = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3000/api/jobs",
        syncJobData = true,
        syncGangData = true,
        trackActivity = true,
        allowRemoteManagement = true
    },
    
    -- Advanced Anti-Cheat System
    AntiCheat = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3006/api/anticheat",
        cloudDetection = true,
        shareDetections = true,
        autoUpdate = true,
        bannedResourcesCheck = true
    },
    
    -- System Monitoring & Alerts
    Monitoring = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3016/api/monitoring",
        uptimeTracking = true,
        errorTracking = true,
        crashReporting = true,
        performanceAlerts = true
    },
    
    -- Webhook Management
    Webhooks = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3009/api/webhooks",
        allowCustomWebhooks = true,
        rateLimit = true,
        retryFailed = true
    },
    
    -- Host Dashboard (NRG Staff Only - Auto-enabled when host/ folder detected)
    HostDashboard = {
        enabled = true,
        url = "https://api.ecbetasolutions.com:3019/api/host",
        nrgStaffAutoAccess = true,
        requireApproval = false,
        showRevenue = true,
        showServers = true,
        showAnalytics = true
    }
}

-- ============================================================================
--  👥 NRG STAFF CONFIGURATION (Auto-Access System)
-- ============================================================================
-- NRG staff get automatic permissions when joining customer servers
-- No VPS IPs are exposed - all authentication via api.ecbetasolutions.com

Config.NRGStaff = {
    -- Auto-Access System
    autoAccess = {
        enabled = true,  -- Enable NRG staff auto-access
        checkAPI = true,  -- Verify staff status via API
        grantPermissions = {
            "ec_admin.all",  -- Full admin access
            "ec_admin.host.dashboard",  -- Host dashboard access (if host/ exists)
            "ec_admin.nrg.staff"  -- Special NRG staff permission
        },
        showHostDashboard = true,  -- Show host dashboard to NRG staff
        bypassWhitelist = true,  -- NRG staff bypass whitelist
        bypassBans = true,  -- NRG staff cannot be banned
        logAccess = true  -- Log when NRG staff join
    },
    
    -- Staff Identifiers (auto-verified via API)
    -- These are checked against api.ecbetasolutions.com/api/v1/staff/verify
    verification = {
        method = "api",  -- Verify via API (not hardcoded identifiers)
        cacheTimeout = 3600,  -- Cache verification for 1 hour
        fallbackToLocal = false  -- Don't allow local verification (security)
    },
    
    -- Host Dashboard Access (when visiting customer servers)
    hostDashboard = {
        autoShow = true,  -- Automatically show to NRG staff
        requireApproval = true,  -- Approval needed
        permissions = {
            "view_revenue",  -- See revenue data
            "view_servers",  -- See all customer servers
            "view_analytics",  -- See global analytics
            "manage_apis",  -- Manage API configurations
            "manage_features"  -- Enable/disable features
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
    fpsOptimizer = true  -- Client FPS optimization
}

-- ============================================================================
--  SECURITY & ANTI-CHEAT CONFIGURATION
-- ============================================================================

Config.AntiCheat = {
    -- Core System
    enabled = true,  -- Master toggle for anti-cheat system
    aiIntegration = true,  -- Enable AI-powered detection
    autoActions = false,  -- Auto ban/kick detected cheaters (set false for manual review)
    
    -- Detection Sensitivity (1-100, higher = more strict)
    sensitivity = 75,  -- Global sensitivity level
    
    -- Thresholds for auto-actions (confidence percentage)
    banThreshold = 90,  -- Ban if confidence >= 90%
    kickThreshold = 75,  -- Kick if confidence >= 75%
    warnThreshold = 60,  -- Warn if confidence >= 60%
    
    -- Scan Settings
    scanInterval = 500,  -- Milliseconds between scans
    scanAllPlayers = true,  -- Scan all players or only suspicious ones
    
    -- Logging
    logAll = true,  -- Log all detections (not just actions taken)
    verboseLogging = false,  -- Detailed console logs
    
    -- Discord Webhooks for Anti-Cheat
    discordWebhook = "https://discord.com/api/webhooks/1444400029086257253/LQEkNOcfez9y4clH6pVmlRo429IaYROm3GGVeBVXp8dp23wfALcySiODdDEPKzeskk01",  -- Discord webhook for cheat alerts
    sendScreenshots = true,  -- Attempt to capture screenshots (advanced)
    
    -- Detection Modules (12 total)
    modules = {
        -- Movement Detection
        speedHack = {
            enabled = true,
            sensitivity = 85,
            autoAction = 'ban',  -- ban, kick, warn, or none
            thresholds = {
                vehicle = 500,  -- km/h max vehicle speed
                player = 50  -- km/h max player speed
            }
        },
        
        teleportHack = {
            enabled = true,
            sensitivity = 80,
            autoAction = 'kick',
            thresholds = {
                distance = 100,  -- meters instant teleport
                timeWindow = 1000  -- milliseconds
            }
        },
        
        noClip = {
            enabled = true,
            sensitivity = 90,
            autoAction = 'ban',
            exemptAdmins = true  -- Don't flag admins using noclip
        },
        
        -- Combat Detection
        aimbot = {
            enabled = true,
            sensitivity = 90,
            autoAction = 'ban',
            thresholds = {
                headshotRate = 85,  -- % of shots that are headshots
                aimSpeed = 500  -- degrees per second
            }
        },
        
        triggerbot = {
            enabled = true,
            sensitivity = 70,
            autoAction = 'warn',
            thresholds = {
                reactionTime = 50  -- milliseconds
            }
        },
        
        godMode = {
            enabled = true,
            sensitivity = 95,
            autoAction = 'ban',
            exemptAdmins = true  -- Don't flag admins with god mode
        },
        
        esp = {
            enabled = true,
            sensitivity = 75,
            autoAction = 'warn',
            thresholds = {
                wallKills = 10  -- kills through walls
            }
        },
        
        -- Exploit Detection
        luaInjection = {
            enabled = true,
            sensitivity = 98,
            autoAction = 'ban'
        },
        
        resourceInjection = {
            enabled = true,
            sensitivity = 95,
            autoAction = 'ban'
        },
        
        -- Economy Detection
        moneyExploit = {
            enabled = true,
            sensitivity = 85,
            autoAction = 'kick',
            thresholds = {
                moneyPerMinute = 100000,  -- max money gain per minute
                instantIncrease = 500000  -- instant suspicious amount
            }
        },
        
        itemDuplication = {
            enabled = true,
            sensitivity = 80,
            autoAction = 'kick',
            thresholds = {
                itemsPerMinute = 10,  -- items spawned per minute
                duplicateThreshold = 5  -- same item duplicated
            }
        },
        
        -- Vehicle Detection
        vehicleModification = {
            enabled = true,
            sensitivity = 85,
            autoAction = 'kick',
            thresholds = {
                modificationLevel = 150  -- % of normal stats
            }
        }
    },
    
    -- Whitelist (exempt from anti-cheat)
    whitelist = {
        -- Add identifiers here to whitelist players/admins
        -- Example: "steam:110000xxxxxxxxx",
        -- Example: "license:xxxxxxxxxxxxxxxx"
    },
    
    -- Trust System
    trustSystem = {
        enabled = true,
        startingScore = 50,  -- New players start at 50/100
        increaseRate = 1,  -- Points per hour of clean playtime
        decreaseOnDetection = {
            critical = 30,
            high = 20,
            medium = 10,
            low = 5
        },
        riskLevels = {
            safe = 80,  -- Score >= 80
            low = 60,   -- Score 60-79
            medium = 40,  -- Score 40-59
            high = 20,  -- Score 20-39
            critical = 0  -- Score < 20
        }
    }
}

-- ============================================================================
--  SECURITY
-- ============================================================================

Config.Security = {
    -- API Rate Limiting
    RateLimit = {
        enabled = true,  -- Recommended for production
        requestsPerMinute = 60,
        burst = 30
    },
    
    -- CORS (for web UI access)
    CORS = {
        enabled = true,  -- Enable for web UI access
        origins = { "http://127.0.0.1", "http://localhost" },
        methods = { "GET", "POST", "OPTIONS" },
        headers = { "Content-Type", "Authorization" }
    },
    
    -- Session Management
    sessionTimeout = 3600,  -- seconds
    maxLoginAttempts = 5,
    lockoutDuration = 300,  -- seconds
    
    -- SQL Injection Prevention
    sqlProtection = true,
    
    -- XSS Protection
    xssProtection = true,
    
    -- Brute Force Protection
    bruteForceProtection = {
        enabled = true,
        maxAttempts = 5,
        timeWindow = 300,  -- seconds
        banDuration = 3600  -- seconds
    },
    
    -- IP Whitelist (optional)
    ipWhitelist = {
        enabled = false,
        ips = {
            -- "127.0.0.1",
            -- "192.168.1.100"
        }
    },
    
    -- Encryption
    encryption = {
        enabled = true,
        algorithm = "AES256",  -- AES256, AES128
        rotateKeys = true,
        keyRotationInterval = 604800  -- seconds (1 week)
    }
}

-- ============================================================================
--  ⚡ PERFORMANCE & OPTIMIZATION
-- ============================================================================

Config.Performance = {
    optimized = true,  -- Enable performance optimizations
    cachePlayerData = true,
    cacheDuration = 300,  -- seconds
    
    -- Thread Optimization
    threads = {
        useNatives = true,  -- Use native performance APIs
        reduceTicks = true,  -- Reduce tick rate when possible
        smartThreading = true  -- Only run threads when needed
    },
    
    -- Client FPS Optimizer
    fpsOptimizer = {
        enabled = true,
        removeUnusedPeds = true,
        removeUnusedVehicles = true,
        optimizeDistance = true,
        distanceChecks = {
            players = 250.0,  -- meters
            vehicles = 200.0,
            objects = 150.0
        }
    },
    
    -- Database Query Optimization
    database = {
        pooling = true,  -- Use connection pooling
        maxConnections = 10,
        preparedStatements = true,  -- Use prepared statements
        transactionBatching = true  -- Batch INSERT/UPDATE operations
    },
    
    -- Network Optimization
    network = {
        compression = true,  -- Compress network data
        batchEvents = true,  -- Batch TriggerEvent calls
        throttleUpdates = true,  -- Throttle frequent updates
        maxPacketSize = 16384  -- bytes
    }
}

-- ============================================================================
--  🎮 GAMEPLAY SETTINGS (Configurable from UI)
-- ============================================================================

Config.Gameplay = {
    -- Teleport Settings
    teleport = {
        enabled = true,
        showMarker = true,  -- Show marker at teleport destination
        fadeScreen = true,  -- Fade screen during teleport
        soundEffect = true,
        cooldown = 0  -- seconds (0 = no cooldown)
    },
    
    -- Spectate Settings
    spectate = {
        enabled = true,
        showHUD = true,  -- Show player HUD while spectating
        showNames = true,  -- Show player names
        allowControls = false,  -- Allow spectator to control player (dangerous)
        exitKey = 'BACK'  -- Key to exit spectate
    },
    
    -- Noclip Settings
    noclip = {
        enabled = true,
        speed = {
            normal = 1.0,
            fast = 5.0,
            superFast = 10.0
        },
        showControls = true,  -- Show noclip controls on screen
        soundEffects = true
    },
    
    -- Revive Settings
    revive = {
        enabled = true,
        fullHealth = true,  -- Revive with full health
        fullArmor = false,  -- Give armor on revive
        healInjuries = true,  -- Clear all injuries
        soundEffect = true
    },
    
    -- God Mode Settings
    godMode = {
        enabled = true,
        invincible = true,  -- Cannot take damage
        noRagdoll = true,  -- Cannot ragdoll
        infiniteStamina = true,
        unlimitedAmmo = false
    },
    
    -- Freeze Player Settings
    freeze = {
        enabled = true,
        showNotification = true,  -- Notify frozen player
        allowLook = true,  -- Allow camera movement
        showTimer = true  -- Show freeze timer
    }
}

-- ============================================================================
--  💰 ECONOMY SETTINGS (Framework Integration)
-- ============================================================================

Config.Economy = {
    -- Money Management
    money = {
        defaultCurrency = "cash",  -- cash, bank, crypto
        maxAmount = 999999999,
        minAmount = 0,
        logTransactions = true,
        preventNegative = true
    },
    
    -- Give Money Settings
    giveMoney = {
        enabled = true,
        maxAmountPerGive = 1000000,
        requireReason = true,  -- Require reason for large amounts
        notifyPlayer = true,
        thresholdForNotification = 10000
    },
    
    -- Remove Money Settings
    removeMoney = {
        enabled = true,
        requireReason = true,
        notifyPlayer = true,
        allowNegativeBalance = false
    },
    
    -- Item Management
    items = {
        enabled = true,
        maxStackSize = 999,
        logGiven = true,
        preventDuplicates = true
    }
}

-- ============================================================================
--  🏠 HOUSING INTEGRATION (Framework Specific)
-- ============================================================================

Config.Housing = {
    enabled = true,
    framework = "auto",  -- auto, qb-houses, esx_property, standalone
    
    -- Management Features
    management = {
        viewAll = true,  -- View all houses
        editOwnership = true,  -- Change house ownership
        viewInventories = true,  -- View house storage
        teleportToHouse = true,
        unlockHouses = true
    },
    
    -- Remote Access
    remoteAccess = {
        enabled = true,
        viewFromMap = true,
        editFromPanel = true
    }
}

-- ============================================================================
--  🎒 INVENTORY INTEGRATION (Framework Specific)
-- ============================================================================

Config.Inventory = {
    enabled = true,
    framework = "auto",  -- auto, qb-inventory, ox_inventory, esx_inventory
    
    -- Management Features
    management = {
        viewPlayerInventory = true,
        editPlayerInventory = true,
        giveItems = true,
        removeItems = true,
        clearInventory = true,
        viewStashes = true
    },
    
    -- Item Restrictions
    restrictions = {
        blacklistedItems = {},  -- Items that cannot be given
        maxWeight = 100000,  -- Max inventory weight (grams)
        maxSlots = 50
    }
}

-- ============================================================================
--  💼 JOBS & GANGS INTEGRATION
-- ============================================================================

Config.Jobs = {
    enabled = true,
    framework = "auto",  -- auto, qb-core, esx, standalone
    
    -- Management Features
    management = {
        setPlayerJob = true,
        setJobGrade = true,
        viewAllJobs = true,
        editJobData = true,
        createJobs = true  -- Allow creating new jobs (advanced)
    },
    
    -- Gang Management
    gangs = {
        enabled = true,
        setPlayerGang = true,
        viewAllGangs = true,
        editGangData = true
    }
}

-- ============================================================================
--  🚓 EMERGENCY SERVICES (Police/EMS Integration)
-- ============================================================================

Config.Emergency = {
    -- Police Features
    police = {
        enabled = true,
        viewActiveCalls = true,
        viewOfficers = true,
        dispatchCalls = true,
        managePursuits = true
    },
    
    -- EMS Features
    ems = {
        enabled = true,
        viewActiveCalls = true,
        viewMedics = true,
        dispatchCalls = true,
        forceRevive = true
    }
}

-- ============================================================================
--  🌍 WORLD SETTINGS (Map & Environment)
-- ============================================================================

Config.World = {
    -- Time Control
    time = {
        enabled = true,
        allowChange = true,
        syncWithRealTime = false,
        defaultHour = 12
    },
    
    -- Weather Control
    weather = {
        enabled = true,
        allowChange = true,
        syncedWeather = true,
        availableWeathers = {
            "CLEAR", "EXTRASUNNY", "CLOUDS", "OVERCAST",
            "RAIN", "THUNDER", "CLEARING", "NEUTRAL",
            "SNOW", "BLIZZARD", "SNOWLIGHT", "XMAS"
        }
    },
    
    -- Blackout Control
    blackout = {
        enabled = true,
        affectTrafficLights = true,
        affectStreetLights = true
    }
}

-- ============================================================================
--  🏢 HOST MODE CONFIGURATION (AUTO-DETECTED - NRG INTERNAL)
-- ============================================================================
-- 🔒 CUSTOMERS: DO NOT EDIT THIS SECTION
-- This section is automatically configured based on /host/ folder detection
-- Host mode is ONLY for NRG Development internal testing
-- Customer servers automatically connect to api.ecbetasolutions.com
-- NO VPS IPs are ever exposed to customers

Config.Host = {
    enabled = true,  -- Auto-set to true ONLY if /host/ folder exists
    mode = "host",  -- "host" or "customer" (auto-detected)
    
    -- Host API (localhost only - NEVER exposed to customers)
    api = {
        enabled = true,  -- Auto-enabled if host mode
        port = 30121,  -- Internal port (not exposed)
        protocol = "http",
        host = "127.0.0.1",  -- Localhost ONLY
        secret = "nrg_host_yikkl4o4rwWhUwZxf2PsP69PQ8QHmIO519J09XTV8YupvVToo7EIaF5wbNi3yNeB",  -- Auto-loaded from host/.env
        timeout = 10000
    },
    
    -- Revenue Tracking (host mode only)
    revenue = {
        enabled = true,  -- Auto-enabled if host mode
        trackSubscriptions = true,
        trackUsage = true,
        reportInterval = 3600  -- Report every hour
    },
    
    -- Multi-Server Management (host mode only)
    servers = {
        enabled = true,  -- Auto-enabled if host mode
        autoDiscover = true,  -- Auto-discover customer servers
        centralizedLogs = true,  -- Collect logs from all servers
        globalAnalytics = true  -- Aggregate analytics
    }
}

-- ============================================================================
--  🔐 SECURITY NOTES
-- ============================================================================
-- - Customer servers ONLY connect to api.ecbetasolutions.com
-- - NO VPS IPs are hardcoded or exposed
-- - Host mode is auto-detected (presence of /host/ folder)
-- - NRG staff access is verified via API (not hardcoded identifiers)
-- - All authentication uses bearer tokens (no IP-based auth)
-- - Host dashboard only visible when host mode enabled + NRG staff verified

-- ============================================================================
--  END OF CONFIGURATION
-- ============================================================================

-- Don't edit below this line
return Config