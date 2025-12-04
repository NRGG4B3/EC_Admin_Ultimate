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
    'ui/dist/assets/*.ttf'
}

-- Shared configuration
shared_scripts {
    '@ox_lib/init.lua',
    'shared/framework.lua',
    'config.lua',
    'shared/utils.lua',
    'shared/vehicle-database.lua'
}

-- Server scripts (LOAD ORDER IS CRITICAL!)
server_scripts {
    '@oxmysql/lib/MySQL.lua',  -- Load MySQL first
    
    -- ==========================================
    -- CORE SERVER FILES (Load First)
    -- ==========================================
    'server/logger.lua',               -- ⚠️ CRITICAL: Load logger FIRST (before ANY file that uses Logger)
    'server/database/sql-auto-apply-immediate.lua',  -- ⚠️ CRITICAL: SQL migrations IMMEDIATELY after logger
    'server/host-validation.lua',      -- Host mode validation
    'server/environment.lua',          -- Environment detection (prod/dev/host) - NOW uses Logger
    'server/validation-helpers.lua',   -- Input validation (load first)
    'server/rate-limiter.lua',         -- Rate limiting (load early)
    'server/path-validator.lua',       -- Path validation for security
    'server/host-security-validator.lua', -- Host-mode security checks
    
    -- PLAYERS
    'server/players.lua',
    'server/players-callbacks.lua',
    'server/players-actions.lua',
    'server/player-profile-callbacks.lua',
    'server/player-history-tracker.lua',
    'server/players-api.lua',
    
    -- DASHBOARD
    'server/dashboard.lua',
    'server/dashboard-callbacks.lua',
    'server/dashboard-actions.lua',
    'server/dashboard-api.lua',
    
    -- REPORTS
    'server/reports.lua',
    'server/reports-callbacks.lua',  -- RE-ENABLED: Contains lib.callback.register (server-side)
    'server/reports-actions.lua',
    -- 'server/advanced-reports-callbacks.lua',  -- KEEP DISABLED: Analytics helpers only (no callbacks needed)
    
    -- ECONOMY
    'server/economy.lua',
    'server/economy-callbacks.lua',
    'server/economy-actions.lua',
    
    -- MODERATION
    'server/moderation.lua',
    'server/moderation-callbacks.lua',
    'server/moderation-actions.lua',
    
    -- MONITORING
    'server/monitoring.lua',
    'server/monitoring-callbacks.lua',
    'server/monitoring-actions.lua',
    
    -- SETTINGS
    'server/settings-callbacks-enhanced.lua',
    'server/settings-actions.lua',
    
    -- WHITELIST
    'server/whitelist.lua',
    'server/whitelist-callbacks.lua',
    'server/whitelist-actions.lua',
    'server/whitelist-advanced.lua',
    
    -- ADMIN TEAM
    'server/admin-team-manager.lua',
    'server/admin-team-migration.lua',
    'server/callbacks/admin-team-callbacks.lua',

    -- PERMISSIONS (centralized access control)
    'server/permissions.lua',
    'server/nrg-staff-auto-access.lua',  -- Auto-grant NRG co-owners access
    
    -- DATABASE & MIGRATIONS (after permissions, before features)
    'server/database.lua',               -- DB abstraction layer
    'server/database-init.lua',          -- Ensure critical tables exist
    'server/database-migrations.lua',    -- Schema versioning & migrations
    'server/database/auto-migrate.lua',  -- Auto-migration on startup
    'server/database/auto-setup.lua',    -- Database initialization
    'server/database-migration-ai.lua',  -- AI Detection tables migration
    'server/auto-migrate-sql.lua',       -- Automatic SQL migration system (runs all SQL files)
    'server/database/sql-auto-migration.lua', -- SQL schema auto-import (creates all tables)
    'server/config-management.lua',      -- Live config updates from UI
    'server/action-logger.lua',          -- Centralized action logger (console + webhook + DB)
    
    -- AUTO-SETUP & DIAGNOSTICS (after DB, before features)
    'server/auto-setup.lua',             -- Host/Customer auto-configuration
    'server/diagnostics.lua',            -- System health checks
    
    -- INTEGRATIONS (framework/inventory detection)
    'server/integrations/framework-detector.lua',
    'server/integrations/inventory-detector.lua',
    
    -- ==========================================
    -- API ROUTING & DOMAIN CONFIG (before feature modules)
    -- ==========================================
    'server/api-domain-config.lua',      -- API domain routing (IP-hidden for customers)
    'server/unified-router.lua',         -- HTTP endpoint router (production-ready)
    -- NOTE: api-router.lua is LEGACY - replaced by unified-router.lua
    
    -- ==========================================
    -- OTHER FEATURE MODULES (alphabetical)
    -- ==========================================
    'server/admin-abuse.lua',
    'server/admin-abuse-callbacks.lua',
    'server/admin-actions.lua',
    'server/admin-actions-server.lua',
    'server/discord-ace-integration.lua',
    'server/api-connection-manager.lua',
    'server/api-health-monitor.lua',     
    'server/api-fallback.lua',
    'server/api-redundancy.lua',           -- API failover & redundancy
    'server/api-wrapper.lua',
    'server/admin-profile-callbacks.lua',  -- Admin profile system
    'server/ai-analytics.lua',
    'server/ai-analytics-callbacks.lua',
    'server/ai-detection.lua',
    'server/ai-detection-callbacks.lua',
    'server/ai-detection-api-integration.lua',
    'server/anticheat-advanced.lua',
    'server/anticheat-callbacks.lua',
    'server/backups.lua',
    'server/bans-callbacks.lua',
    'server/bans-events.lua',
    'server/cleanup.lua',
    'server/communications.lua',
    'server/community-callbacks.lua',
    'server/data-sync.lua',                -- Real-time data synchronization
    'server/database-auto-setup.lua',
    'server/dev-tools-callbacks.lua',
    'server/exports.lua',
    'server/global-tools-callbacks.lua',
    'server/global-tools.lua',
    'server/events.lua',
    'server/event-handlers.lua',
    'server/global-ban-registration.lua',
    'server/global-ban-integration.lua',
    'server/host-api-connector.lua',
    'server/host.lua',
    'server/host-callbacks.lua',
    'server/host-actions.lua',
    'server/host-access-check.lua',
    'server/host-global-bans.lua',
    'server/host-webhooks.lua',
    'server/host-nrg-auth.lua',
    'server/host-api-management.lua',      -- Host API management
    'server/host-api-management-callbacks.lua',
    'server/host-api-management-actions.lua',
    'server/host-api-proxy.lua',           -- API proxy for host mode
    'server/host-control-handlers.lua',    -- Host control handlers
    'server/host-management-callbacks.lua',
    'server/host-management-actions.lua',
    'server/host-dashboard-callbacks.lua',
    'server/host-revenue-callbacks.lua',  -- Fixed path from host/host-revenue-callbacks.lua
    'server/housing.lua',
    'server/housing-callbacks.lua',
    'server/housing-events.lua',
    'server/missing-callbacks.lua',
    'server/missing-callbacks-CRITICAL.lua',
    'server/inventory.lua',
    'server/inventory-callbacks.lua',
    'server/inventory-events.lua',
    'server/jobs-gangs.lua',
    'server/jobs-gangs-callbacks.lua',
    'server/jobs-gangs-management.lua',
    'server/jobs-gangs-events.lua',
    'server/livemap.lua',
    'server/livemap-callbacks.lua',
    'server/live-metrics-pusher.lua',
    'server/metrics-api.lua',
    'server/metrics-database.lua',         -- ✅ Database persistence for metrics/webhooks/API usage
    'server/metrics-sampler.lua',
    'server/owner-protection.lua',
    'server/performance.lua',
    'server/player-events.lua',            -- Centralized player event handling
    'server/quick-actions-server.lua',
    'server/remote-admin.lua',             -- Remote admin access (secure)
    'server/resources.lua',
    'server/security.lua',
    'server/startup-clean.lua',            -- Startup cleanup & initialization
    'server/time-monitoring.lua',          -- Player time tracking
    'server/settings-callbacks.lua',  -- Settings management system
    'server/system-management-callbacks.lua',
    'server/topbar-callbacks.lua',  -- RE-ENABLED: Contains lib.callback.register (server-side)
    'server/vehicle-management-api.lua',
    'server/vehicle-pack-detector.lua',
    'server/vehicles-callbacks.lua',
    'server/vehicles-events.lua',
    'server/vps-performance-optimizer.lua', -- VPS performance optimization
    'server/webhooks.lua',
    'server/logging-config.lua',    -- Console message filtering
    'server/main.lua',              -- CRITICAL: Permission checks and basic events
    'server/web-realtime-sync.lua', -- Real-time web sync for browser access
    'server/web-server-endpoint.lua' -- Web server endpoint (customers can access via browser)
}

-- Client scripts
client_scripts {
    -- ⚠️ CRITICAL: Logger must load FIRST before any other client scripts
    'client/logger.lua',                -- Client-side Logger initialization (LOAD FIRST!)
    
    'client/startup-clean.lua',         
    'client/error-handler.lua',         
    'client/notifications.lua',
    'client/action-logger.lua',          -- Client-side action logger (UI clicks tracking)
    'client/nui-bridge.lua',            
    'client/nui-topbar.lua',            
    'client/nui-dashboard.lua',        
    'client/nui-players.lua',           
    'client/nui-player-profile.lua',
    'client/player-action-handlers.lua',  -- CRITICAL: Handles all client-side player actions
    'client/admin-menu-gating.lua',
    'client/ai-behavior-tracker.lua',     
    'client/fps-optimizer.lua',
    'client/live-data-receivers.lua',
    'client/nui-admin-abuse.lua',
    'client/nui-admin-profile.lua',
    'client/nui-ai-analytics.lua',
    'client/nui-ai-detection.lua',
    'client/nui-anticheat.lua',
    'client/nui-bans.lua',
    'client/nui-community.lua',         
    'client/nui-dev-tools.lua',         
    'client/nui-economy.lua',
    'client/nui-global-tools.lua',
    'client/host.lua',
    'client/host-callbacks.lua',
    'client/host-actions.lua',
    'client/nui-host-control.lua',
    'client/nui-host-dashboard.lua',
    'client/nui-host-management.lua',
    'client/nui-host-api-management.lua',  -- Host API management UI callbacks
    'client/nui-housing.lua',
    'client/nui-inventory.lua',
    'client/nui-jobs-gangs.lua',
    'client/nui-livemap.lua',
    'client/nui-moderation.lua',        
    'client/nui-monitoring.lua',
    'client/nui-quick-actions.lua',
    'client/nui-reports.lua',
    'client/nui-settings-enhanced.lua', 
    'client/nui-system-management.lua', 
    'client/nui-vehicles.lua',
    'client/nui-whitelist.lua',         
    'client/quick-actions-handlers.lua',
    'client/quick-actions-client.lua',   
    'client/global-tools-client.lua',    
    'client/topbar-actions.lua',
    'client/vehicle-management.lua',
    'client/vehicle-scanner.lua',          
    'client/vehicles-handlers.lua',      
    'client/whitelist-application.lua'
}

-- ============================================================================
-- DISABLED FILES REFERENCE
-- ============================================================================
-- These files exist but are NOT loaded:
--   • server/api-router.lua - LEGACY: Replaced by unified-router.lua
--   • server/advanced-reports-callbacks.lua - Analytics helpers only
--   • server/customer-wizard.lua - FUTURE: Setup wizard (incomplete)
--   • client/main.lua - LEGACY: Replaced by nui-bridge.lua (DO NOT ENABLE)
--   • client/nui.lua - LEGACY: Replaced by nui-bridge.lua (DO NOT ENABLE)
-- ============================================================================

-- Exports
exports {
    'HasPermission',
    'EC_Perms',
    -- API Domain exports (from api-domain-config.lua)
    'GetAPIEndpoint',
    'GetFullAPIEndpoint',
    'CallAPI'
}

server_exports {
    'HasPermission',
    'EC_Perms',
    'GetAPIEndpoint',
    'GetFullAPIEndpoint',
    'CallAPI'
}
