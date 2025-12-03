--[[
    EC ADMIN ULTIMATE - Configuration
    Simple configuration file for server owners
]]

Config = {}

-- ============================================================================
--  BASIC SETTINGS
-- ============================================================================

Config.MenuKey = 'F2'  -- Key to open admin menu
Config.Framework = 'qb'  -- auto, qb, esx, standalone

-- ============================================================================
--  LOGGING CONFIGURATION
-- ============================================================================

-- Log Format Mode - Controls how messages appear in console
-- Options: 'simple', 'detailed', 'minimal'
Config.LogFormat = 'detailed'  -- SHIPPING DEFAULT: 'detailed' (recommended)

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
Config.LogLevel = 'debug'  -- SHIPPING DEFAULT: 'info' (recommended for production)

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
Config.Debug = true  -- Set to true to see ALL debug messages

-- Show Icons in Logs - Set to false to remove emojis from console
Config.LogIcons = true  -- Emojis make logs easier to scan (recommended for 'detailed' format)

-- UI Settings (for client.lua compatibility)
Config.UI = {
    openKey = 'F2',
    theme = 'dark',
    language = 'en',
    animations = true
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
    steam = '',  -- steam:110000XXXXXXXXX (YOUR Steam Hex - See console when you join!)
    license = '',  -- license:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    discord = '',  -- discord:XXXXXXXXXXXXXXXXXX
    fivem = ''  -- fivem:XXXXXX
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
    webhook = "",  -- Your Discord webhook URL
    logBans = true,
    logKicks = true,
    logWarns = true,
    logEconomy = true,
    logVehicles = true,
    
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
--  APIs (DO NOT EDIT - MANAGED BY NRG)
-- ============================================================================

-- API endpoints are hardcoded and managed by NRG
-- Customers cannot change these - they connect to production API automatically

Config.APIs = {
    -- All APIs enabled by default - connect to api.ecbetasolutions.com
    GlobalBans = {
        enabled = true,
        bypassOwners = true,  -- Server owners NEVER get banned
        bypassNRGStaff = true  -- NRG staff bypass all bans
    },
    
    AIDetection = {
        enabled = true
    },
    
    AdminAbuse = {
        enabled = true
    },
    
    Analytics = {
        enabled = true
    },
    
    ServerMetrics = {
        enabled = true
    },
    
    Reports = {
        enabled = true
    },
    
    LiveMap = {
        enabled = true
    },
    
    Backups = {
        enabled = true
    },
    
    Economy = {
        enabled = true
    },
    
    Whitelist = {
        enabled = true
    },
    
    DiscordSync = {
        enabled = true
    },
    
    VehicleData = {
        enabled = true
    },
    
    Housing = {
        enabled = true,
        endpoint = "https://api.nrg.gg/api/housing"
    },
    
    Inventory = {
        enabled = true,
        endpoint = "https://api.nrg.gg/api/inventory"
    },
    
    Jobs = {
        enabled = true,
        endpoint = "https://api.nrg.gg/api/jobs"
    },
    
    AntiCheat = {
        enabled = true
    },
    
    Monitoring = {
        enabled = true
    },
    
    Webhooks = {
        enabled = true
    }
}

-- DO NOT EDIT: API endpoints are managed internally and cannot be changed by customers

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
    discordWebhook = "",  -- Discord webhook for cheat alerts
    sendScreenshots = false,  -- Attempt to capture screenshots (advanced)
    
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
--  PERFORMANCE
-- ============================================================================

Config.Performance = {
    optimized = true,  -- Enable performance optimizations
    cachePlayerData = true,
    cacheDuration = 300  -- seconds
}

-- ============================================================================
--  HOST MODE CONFIGURATION (DO NOT EDIT - AUTO-CONFIGURED)
-- ============================================================================

-- 🔒 CUSTOMERS: DO NOT EDIT THIS SECTION
-- This section is automatically configured based on /host/ folder detection
-- Host mode is for NRG internal use only
-- Customer installations automatically connect to NRG API suite
-- You will NEVER need to configure this section

-- This section is auto-configured by the server based on /host/ folder detection
-- Manual changes will be overwritten

Config.Host = {
    enabled = true,  -- Auto-set to true if /host/ folder exists
    secret = "nrg_host_tnD8W1nm1shTIZ3KO4DxGPzCydYfRFKUjyJvskFQBMAdNyj7EPuqosf8ZCfEAJyq",  -- NRG internal secret
    apis = {}  -- Auto-populated with localhost:3001-3020
}

-- Host API configuration (for Node.js API server)
-- 🔒 INTERNAL USE ONLY - Customers never configure this
Config.HostApi = {
    enabled = true,  -- Auto-set to true if /host/ folder exists
    baseUrl = "http://127.0.0.1:3000",  -- Localhost only (proxied by FiveM)
    secret = "nrg_host_tnD8W1nm1shTIZ3KO4DxGPzCydYfRFKUjyJvskFQBMAdNyj7EPuqosf8ZCfEAJyq",  -- Auto-loaded from .host-secret
    timeoutMs = 10000  -- Request timeout
}

-- Host mode auto-enables all APIs and connects to localhost
-- Customer mode auto-connects to NRG API suite
-- No configuration needed for NRG staff OR customers

-- ============================================================================
--  END OF CONFIGURATION
-- ============================================================================

-- Don't edit below this line
return Config