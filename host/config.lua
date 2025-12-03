--[[
    EC ADMIN ULTIMATE - HOST CONFIGURATION
    ⚠️ WARNING: THIS FILE IS FOR NRG INTERNAL USE ONLY
    ⚠️ DO NOT DISTRIBUTE TO CUSTOMERS
]]--

HostConfig = {}

-- ============================================================================
--  🔒 HOST API CONFIGURATION (NRG INTERNAL ONLY)
-- ============================================================================

-- Multi-Port API Server Configuration
-- Each API runs on its own dedicated port (3000-3019)
HostConfig.API = {
    -- Base URL for local API server
    baseURL = 'http://127.0.0.1',
    
    -- API Port Configuration (20 APIs)
    ports = {
        gateway = 3000,           -- Main Gateway
        globalBan = 3001,         -- Global Ban System
        aiDetection = 3002,       -- AI Detection
        playerAnalytics = 3003,   -- Player Analytics
        serverMetrics = 3004,     -- Server Metrics
        reports = 3005,           -- Report System
        anticheat = 3006,         -- Anticheat Sync
        backups = 3007,           -- Backup Storage
        screenshots = 3008,       -- Screenshot Storage
        webhooks = 3009,          -- Webhook Relay
        globalChat = 3010,        -- Global Chat Hub
        playerTracking = 3011,    -- Player Tracking
        serverRegistry = 3012,    -- Server Registry
        license = 3013,           -- License Validation
        updates = 3014,           -- Update Checker
        auditLogs = 3015,         -- Audit Logging
        performance = 3016,       -- Performance Monitor
        resources = 3017,         -- Resource Hub
        emergency = 3018,         -- Emergency Control
        hostDashboard = 3019      -- Host Dashboard
    },
    
    -- Full API Endpoints (auto-generated from ports)
    endpoints = {}  -- Will be populated automatically
}

-- Auto-generate full endpoint URLs
for name, port in pairs(HostConfig.API.ports) do
    HostConfig.API.endpoints[name] = string.format('%s:%d', HostConfig.API.baseURL, port)
end

-- ============================================================================
--  🌐 CUSTOMER FACING CONFIGURATION
-- ============================================================================

-- This is what customers connect to (domain name, not IP)
HostConfig.CustomerAPI = {
    domain = 'api.ecbetasolutions.com',
    ports = HostConfig.API.ports  -- Same ports, different domain
}

-- ============================================================================
--  🔐 SECURITY CONFIGURATION
-- ============================================================================

HostConfig.Security = {
    -- Host secret file location
    secretFile = '.host-secret',
    
    -- Auto-generate secret if missing
    autoGenerateSecret = true,
    
    -- IP that customers should never see
    internalIP = '45.144.225.227',
    
    -- Only bind to localhost (customers can't access directly)
    bindToLocalhost = true
}

-- ============================================================================
--  📊 MONITORING & LOGGING
-- ============================================================================

HostConfig.Monitoring = {
    -- Enable detailed API logging
    enableLogging = true,
    
    -- Log file location
    logFile = 'host/node-server/api-server.log',
    
    -- Enable performance monitoring
    enablePerformanceMonitoring = true,
    
    -- Alert thresholds
    alerts = {
        cpuThreshold = 80,      -- Alert if CPU > 80%
        memoryThreshold = 90,   -- Alert if memory > 90%
        apiResponseTime = 5000  -- Alert if response > 5s
    }
}

-- ============================================================================
--  🚀 AUTO-SETUP CONFIGURATION
-- ============================================================================

HostConfig.AutoSetup = {
    -- Automatically configure NRG staff permissions
    enableNRGStaffAutoAccess = true,
    
    -- NRG Staff Identifiers (auto-granted full access)
    nrgStaff = {
        {
            name = "NRG Co-Owner 1",
            identifier = "steam:110000105e96fb2",
            rank = "owner"
        },
        {
            name = "NRG Co-Owner 2",
            identifier = "steam:11000010d4e1c87",
            rank = "owner"
        }
    },
    
    -- Automatically start API server on resource start
    autoStartAPIServer = true,
    
    -- Automatically test all API endpoints
    autoTestEndpoints = true
}

-- ============================================================================
--  📦 CUSTOMER PACKAGE CONFIGURATION
-- ============================================================================

HostConfig.CustomerPackage = {
    -- Files to exclude from customer package
    excludeFiles = {
        'host/',
        '.host-secret',
        'REBUILD_UI_NOW.md',
        'FINAL_STATUS.md',
        'RESTART_NOW.md',
        'MULTI_PORT_COMPLETE.md',
        'FIX_NOW.md',
        'FIXES_APPLIED.md',
        'PORT_REFERENCE.md'
    },
    
    -- Output location for customer package
    outputDir = 'release/',
    
    -- Package name format
    packageName = 'EC_Admin_Ultimate_v%s_Customer',  -- %s = version
    
    -- Current version
    version = '3.5'
}

-- ============================================================================
--  🔍 VALIDATION RULES
-- ============================================================================

HostConfig.Validation = {
    -- Files to check for IP leaks (customer-facing files only)
    checkFiles = {
        'client/**/*.lua',
        'server/**/*.lua',
        'shared/**/*.lua',
        'ui/**/*.*',
        'config.lua',
        'fxmanifest.lua'
    },
    
    -- Files to EXCLUDE from IP leak check (HOST-only)
    excludeFromValidation = {
        'server/api-domain-config.lua',
        'server/host-api-*.lua',
        'host/**/*.*'
    },
    
    -- Patterns that indicate IP leak
    ipLeakPatterns = {
        '45.144.225.227',
        '127.0.0.1:300[0-9]',
        'localhost:300[0-9]'
    }
}

-- ============================================================================
--  📝 NOTES FOR NRG STAFF
-- ============================================================================

--[[
    🔒 SECURITY NOTES:
    
    1. This file (host/config.lua) is NEVER distributed to customers
    2. All API endpoints use localhost (127.0.0.1) in HOST mode
    3. Customers connect via domain (api.ecbetasolutions.com)
    4. The IP (45.144.225.227) is never exposed to customers
    5. All customer-facing code uses the domain, not the IP
    
    🚀 USAGE:
    
    1. This config is auto-loaded when host/ folder exists
    2. APIs run on localhost ports 3000-3019
    3. Customer package is auto-generated with correct settings
    4. NRG staff get automatic admin access
    
    🔧 MAINTENANCE:
    
    1. To add new API: Add to ports table, increment port number
    2. To change IP: Update Security.internalIP
    3. To add NRG staff: Add to AutoSetup.nrgStaff table
    4. To exclude files from customer package: Add to CustomerPackage.excludeFiles
]]--

return HostConfig
