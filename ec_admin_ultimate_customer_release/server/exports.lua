--[[
    EC Admin Ultimate - Exports
    Centralized export functions for other resources to use
]]

-- NOTE: Permission, Settings, and Whitelist functions are already exported in their respective source files:
-- - HasPermission, EC_Perms: exported in permissions.lua
-- - GetSetting, SetSetting: exported in settings.lua  
-- - IsWhitelisted: exported in whitelist.lua
-- We don't re-export them here to avoid infinite recursion issues.

-- NOTE: All export functions are already exported in their respective source files:
-- - LogDetection: exported in anticheat.lua
-- - GetAPIEndpoint, GetFullAPIEndpoint, CallAPI: exported in api-domain-config.lua
-- - IsHostMode, IsNRGStaff, CanAccessHostDashboard: exported in host-detection.lua
-- - CallHostAPI: exported in host-api-client.lua
-- We don't re-export them here to avoid infinite recursion issues.
-- The exports from their source files are the actual implementations.

print("^2[Exports]^7 Export functions loaded^0")

