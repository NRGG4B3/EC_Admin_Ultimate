--[[
    EC Admin Ultimate - Host Access Check (LEGACY)
    This file is now deprecated - functionality moved to host-validation.lua
    Kept for backwards compatibility only
]]

-- Redirect to new validation system
local function IsHostModeEnabled()
    return exports['ec_admin_ultimate']:IsHostModeEnabled() or false
end

-- Export the check function for backwards compatibility
exports('IsHostModeEnabled', IsHostModeEnabled)

Logger.Info('ℹ️  Legacy host access check loaded (redirects to host-validation.lua)')
