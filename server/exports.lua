--[[
    EC Admin Ultimate - Exports
    Centralized export functions for other resources to use
]]

-- Re-export permission functions (from permissions.lua)
exports('HasPermission', function(source, permission)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, permission)
    end
    -- Fallback to permissions.lua if available
    if _G.HasPermission then
        return _G.HasPermission(source, permission)
    end
    return false
end)

exports('EC_Perms', function(source, permission)
    return exports('ec_admin_ultimate', 'HasPermission', source, permission)
end)

-- Export setting functions (from settings.lua)
exports('GetSetting', function(category, key, defaultValue)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].GetSetting then
        return exports['ec_admin_ultimate']:GetSetting(category, key, defaultValue)
    end
    return defaultValue
end)

exports('SetSetting', function(category, key, value, adminId)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].SetSetting then
        return exports['ec_admin_ultimate']:SetSetting(category, key, value, adminId)
    end
end)

-- Export whitelist check (from whitelist.lua)
exports('IsWhitelisted', function(identifier)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].IsWhitelisted then
        return exports['ec_admin_ultimate']:IsWhitelisted(identifier)
    end
    return true -- Default to allowed if whitelist system not available
end)

-- Export anticheat detection logging (from anticheat.lua)
exports('LogDetection', function(playerId, detectionType, category, severity, confidence, location, coords, evidence, aiAnalyzed, pattern)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].LogDetection then
        return exports['ec_admin_ultimate']:LogDetection(playerId, detectionType, category, severity, confidence, location, coords, evidence, aiAnalyzed, pattern)
    end
    return false
end)

-- Export API functions (from api-domain-config.lua)
exports('GetAPIEndpoint', function(endpoint)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].GetAPIEndpoint then
        return exports['ec_admin_ultimate']:GetAPIEndpoint(endpoint)
    end
    return endpoint
end)

exports('GetFullAPIEndpoint', function(endpoint)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].GetFullAPIEndpoint then
        return exports['ec_admin_ultimate']:GetFullAPIEndpoint(endpoint)
    end
    return endpoint
end)

exports('CallAPI', function(endpoint, method, data, headers)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallAPI then
        return exports['ec_admin_ultimate']:CallAPI(endpoint, method, data, headers)
    end
    return { success = false, error = 'API not available' }
end)

-- Export host detection functions (from host-detection.lua)
exports('IsHostMode', function()
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].IsHostMode then
        return exports['ec_admin_ultimate']:IsHostMode()
    end
    return false
end)

exports('IsNRGStaff', function(source)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].IsNRGStaff then
        return exports['ec_admin_ultimate']:IsNRGStaff(source)
    end
    return false
end)

exports('CanAccessHostDashboard', function(source)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CanAccessHostDashboard then
        return exports['ec_admin_ultimate']:CanAccessHostDashboard(source)
    end
    return false
end)

-- Export host API client function (from host-api-client.lua)
exports('CallHostAPI', function(endpoint, method, data)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].CallHostAPI then
        return exports['ec_admin_ultimate']:CallHostAPI(endpoint, method, data)
    end
    return { success = false, error = 'Host API not available' }
end)

print("^2[Exports]^7 Export functions loaded^0")

