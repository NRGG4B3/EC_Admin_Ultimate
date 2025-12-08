fx_version 'cerulean'
game 'gta5'

name 'EC Admin Ultimate'
description 'Comprehensive FiveM Admin Panel with NRG API Suite Integration'
author 'NRG Development'
version '1.0.0'

lua54 'yes'

-- ============================================================================
-- DEPENDENCIES (Load Order Critical)
-- ============================================================================
-- Soft dependencies - these must be started BEFORE this resource
-- If your server uses non-standard resource names, adjust accordingly
dependencies {
    '/onesync',  -- Required for server-side entity management
}

-- Optional dependencies (detected at runtime via GetResourceState)
-- oxmysql - Required for database operations
-- ox_lib - Required for callbacks and UI components
-- qb-core / qbx_core / es_extended - Framework detection (at least one recommended)

-- ⚠️ IMPORTANT: Ensure these resources start before EC_Admin_Ultimate:
--   1. oxmysql (database)
--   2. ox_lib (callbacks & UI)
--   3. Your framework (qb-core / qbx_core / es_extended)
--
-- Example server.cfg order:
--   ensure oxmysql
--   ensure ox_lib
--   ensure qb-core  # or qbx_core / es_extended
--   ensure EC_Admin_Ultimate
-- ============================================================================

-- Escrow Exemption (config and Host files are NOT escrowed - Host is internal NRG use only)
escrow_ignore {
    'config.lua',
    'host/**/*',
    'server/host-validation.lua'
}

-- NUI Configuration
ui_page 'ui/dist/index.html'

files {
    'ui/dist/index.html',
    'ui/dist/assets/*.js',
    'ui/dist/assets/*.css',
    'ui/dist/assets/*.png',
    'ui/dist/assets/*.jpg',
    'ui/dist/assets/*.svg',
    'ui/dist/assets/*.woff',
    'ui/dist/assets/*.woff2',
    'ui/dist/assets/*.ttf',
    'ui/dist/images/map/*.png',  -- GTA V Live Map image
    'ui/dist/images/map/*.jpg'  -- GTA V Live Map image (if using JPG)
}

-- Shared configuration
shared_scripts {
    '@ox_lib/init.lua',
    'shared/config-loader.lua',  -- ⚠️ CRITICAL: Load config-loader FIRST (copies host.config.lua or customer.config.lua to config.lua)
    'shared/framework.lua',
    'config.lua',  -- Loaded after config-loader has copied the correct file
    'shared/utils.lua',
    'shared/vehicle-database.lua'
}

-- Server scripts (LOAD ORDER IS CRITICAL!)
server_scripts {
    '@oxmysql/lib/MySQL.lua',  -- Load MySQL first
    
    -- ==========================================
    -- CORE SERVER FILES (Load First)
    -- ==========================================
    'server/logger.lua',                      -- ⚠️ CRITICAL: Load logger FIRST (before ANY file that uses Logger)
    'server/database/sql-auto-migration.lua',  -- ⚠️ CRITICAL: SQL auto-migration IMMEDIATELY after logger
    'server/permissions.lua',                 -- Permissions system (needed by all UI backends)
    'server/exports.lua',                     -- Export functions
    'server/host-detection.lua',               -- Host mode detection (must load before host-dashboard)
    'server/main.lua',                         -- Basic events and initialization
    
    -- ==========================================
    -- API ROUTING & DOMAIN CONFIG
    -- ==========================================
    'server/api-domain-config.lua',           -- API domain routing (IP-hidden for customers)
    'server/unified-router.lua',              -- HTTP endpoint router (production-ready)
    
    -- ==========================================
    -- UI BACKEND (NUI Server-Side Handlers)
    -- ==========================================
    'server/admin_profile.lua',               -- Admin profile UI backend
    'server/quick_actions.lua',               -- Quick actions UI backend (60+ actions)
    'server/dashboard.lua',                   -- Dashboard UI backend (metrics & statistics)
    'server/player_database.lua',             -- Player database UI backend (player management)
    'server/player_profile.lua',              -- Player profile UI backend (detailed player data)
    'server/vehicles.lua',                    -- Vehicles UI backend (vehicle management with auto-detection)
    'server/server_monitor.lua',              -- Server monitor UI backend (server monitoring & resources)
    'server/economy_global_tools.lua',       -- Economy & global tools UI backend (economy management & global actions)
    'server/jobs_gangs.lua',                  -- Jobs & gangs UI backend (jobs and gangs management)
    'server/inventory.lua',                   -- Inventory UI backend (inventory management)
    'server/housing.lua',                     -- Housing UI backend (housing management)
    'server/moderation.lua',                  -- Moderation UI backend (moderation management)
    'server/anticheat.lua',                   -- Anticheat & AI detection UI backend (anticheat management)
    'server/system_management.lua',          -- System management UI backend (system management)
    'server/community.lua',                   -- Community UI backend (community management)
    'server/whitelist.lua',                   -- Whitelist UI backend (whitelist management)
    'server/settings.lua',                    -- Settings UI backend (settings management)
    'server/host-dashboard.lua',              -- Host dashboard UI backend (host mode only, or NRG staff)
    'server/host-api-client.lua',            -- Host API client (host mode only - communicates with Node.js backend)
    'server/dev_tools.lua'                    -- Dev tools UI backend (developer tools)
}

-- Client scripts
client_scripts {
    -- ==========================================
    -- CORE CLIENT FILES
    -- ==========================================
    'client/startup-clean.lua',
    'client/error-handler.lua',
    'client/nui-error-handler.lua',           -- ⚠️ CRITICAL: NUI error handler (catches ALL NUI errors)
    'client/ai-behavior-tracker.lua',
    'client/fps-optimizer.lua',
    'client/global-tools-client.lua',
    'client/host-status.lua',                 -- Host status detection (sends to NUI)
    
    -- ==========================================
    -- NUI BRIDGES (UI Backend Client Handlers)
    -- ==========================================
    'client/nui-admin-profile.lua',      -- Admin profile NUI bridge
    'client/nui-dashboard.lua',          -- Dashboard NUI bridge
    'client/nui-players.lua',            -- Players NUI bridge
    'client/nui-player-profile.lua',     -- Player profile NUI bridge
    'client/nui-quick-actions.lua',      -- Quick actions NUI bridge
    'client/nui-server-monitor.lua',     -- Server monitor NUI bridge
    'client/nui-vehicles.lua',           -- Vehicles NUI bridge
    'client/nui-economy-global-tools.lua',  -- Economy & global tools NUI bridge
    'client/nui-host-dashboard.lua',     -- Host dashboard NUI bridge
    'client/nui-host-control.lua',      -- Host control NUI bridge
    'client/nui-host-management.lua',   -- Host management NUI bridge
    'client/nui-host-access.lua',       -- Host access NUI bridge (checks host mode and NRG staff)
    'client/nui-dev-tools.lua',        -- Dev tools NUI bridge
    'client/nui-testing-checklist.lua' -- Testing checklist NUI bridge
}

-- Exports
exports {
    'HasPermission',
    'EC_Perms',
    -- API Domain exports (from api-domain-config.lua)
    'GetAPIEndpoint',
    'GetFullAPIEndpoint',
    'CallAPI',
    -- Settings exports (from settings.lua)
    'GetSetting',
    'SetSetting',
    -- Whitelist exports (from whitelist.lua)
    'IsWhitelisted',
    -- Anticheat exports (from anticheat.lua)
    'LogDetection',
    -- Host detection exports (from host-detection.lua)
    'IsHostMode',
    'IsNRGStaff',
    'CanAccessHostDashboard',
    -- Host API client exports (from host-api-client.lua)
    'CallHostAPI'
}

server_exports {
    'HasPermission',
    'EC_Perms',
    'GetAPIEndpoint',
    'GetFullAPIEndpoint',
    'CallAPI',
    'GetSetting',
    'SetSetting',
    'IsWhitelisted',
    'LogDetection',
    'IsHostMode',
    'IsNRGStaff',
    'CanAccessHostDashboard',
    'CallHostAPI'
}
