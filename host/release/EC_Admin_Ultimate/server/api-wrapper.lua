-- EC Admin Ultimate - API Wrapper with Auto-Fallback
-- Automatically switches between API and fallback based on connection status
-- Version: 1.0.0

Logger.Info('🔌 API Wrapper with Auto-Fallback loaded')

local APIWrapper = {}

-- Wait for dependencies to load
local function WaitForDependencies()
    local timeout = 0
    while (not _G.APIHealth or not _G.APIFallback) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not _G.APIHealth or not _G.APIFallback then
        Logger.Info('')
        return false
    end
    
    return true
end

-- ============================================================================
-- PLAYER DATA WRAPPER
-- ============================================================================

function APIWrapper.GetPlayerData(source)
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.GetPlayerData(source)
    end
    
    -- Try API first
    local success, result = pcall(function()
        -- Call your actual API here
        -- return API.GetPlayerData(source)
    end)
    
    if not success then
        Logger.Info('⚠️  API call failed, using fallback for GetPlayerData')
        return _G.APIFallback.GetPlayerData(source)
    end
    
    return result
end

function APIWrapper.SavePlayerData(source, data)
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.SavePlayerData(source, data)
    end
    
    local success = pcall(function()
        -- Call your actual API here
        -- API.SavePlayerData(source, data)
    end)
    
    if not success then
        Logger.Info('⚠️  API call failed, using fallback for SavePlayerData')
        return _G.APIFallback.SavePlayerData(source, data)
    end
end

-- ============================================================================
-- BANS WRAPPER
-- ============================================================================

function APIWrapper.AddBan(license, reason, adminName, duration)
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.AddBan(license, reason, adminName, duration)
    end
    
    local success, result = pcall(function()
        -- Call your actual API here
        -- return API.AddBan(license, reason, adminName, duration)
    end)
    
    if not success then
        Logger.Info('⚠️  API call failed, using fallback for AddBan')
        return _G.APIFallback.AddBan(license, reason, adminName, duration)
    end
    
    return result
end

function APIWrapper.CheckBan(license)
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.CheckBan(license)
    end
    
    local success, isBanned, banData = pcall(function()
        -- Call your actual API here
        -- return API.CheckBan(license)
    end)
    
    if not success then
        Logger.Info('⚠️  API call failed, using fallback for CheckBan')
        return _G.APIFallback.CheckBan(license)
    end
    
    return isBanned, banData
end

function APIWrapper.RemoveBan(license)
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.RemoveBan(license)
    end
    
    local success, result = pcall(function()
        -- Call your actual API here
        -- return API.RemoveBan(license)
    end)
    
    if not success then
        Logger.Info('⚠️  API call failed, using fallback for RemoveBan')
        return _G.APIFallback.RemoveBan(license)
    end
    
    return result
end

function APIWrapper.GetAllBans()
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.GetAllBans()
    end
    
    local success, result = pcall(function()
        -- Call your actual API here
        -- return API.GetAllBans()
    end)
    
    if not success then
        Logger.Info('⚠️  API call failed, using fallback for GetAllBans')
        return _G.APIFallback.GetAllBans()
    end
    
    return result
end

-- ============================================================================
-- WARNINGS WRAPPER
-- ============================================================================

function APIWrapper.AddWarning(license, reason, adminName)
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.AddWarning(license, reason, adminName)
    end
    
    local success, result = pcall(function()
        -- Call your actual API here
        -- return API.AddWarning(license, reason, adminName)
    end)
    
    if not success then
        Logger.Info('⚠️  API call failed, using fallback for AddWarning')
        return _G.APIFallback.AddWarning(license, reason, adminName)
    end
    
    return result
end

function APIWrapper.GetWarnings(license)
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.GetWarnings(license)
    end
    
    local success, result = pcall(function()
        -- Call your actual API here
        -- return API.GetWarnings(license)
    end)
    
    if not success then
        Logger.Info('⚠️  API call failed, using fallback for GetWarnings')
        return _G.APIFallback.GetWarnings(license)
    end
    
    return result
end

-- ============================================================================
-- ANTI-CHEAT WRAPPER
-- ============================================================================

function APIWrapper.LogCheatDetection(license, cheatType, confidence, details)
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.LogCheatDetection(license, cheatType, confidence, details)
    end
    
    local success, result = pcall(function()
        -- Call your actual API here
        -- return API.LogCheatDetection(license, cheatType, confidence, details)
    end)
    
    if not success then
        Logger.Info('⚠️  API call failed, using fallback for LogCheatDetection')
        return _G.APIFallback.LogCheatDetection(license, cheatType, confidence, details)
    end
    
    return result
end

-- ============================================================================
-- REPORTS WRAPPER
-- ============================================================================

function APIWrapper.CreateReport(reporterSource, targetSource, reason, category)
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.CreateReport(reporterSource, targetSource, reason, category)
    end
    
    local success, result = pcall(function()
        -- Call your actual API here
        -- return API.CreateReport(reporterSource, targetSource, reason, category)
    end)
    
    if not success then
        Logger.Info('⚠️  API call failed, using fallback for CreateReport')
        return _G.APIFallback.CreateReport(reporterSource, targetSource, reason, category)
    end
    
    return result
end

function APIWrapper.GetReports(filter)
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.GetReports(filter)
    end
    
    local success, result = pcall(function()
        -- Call your actual API here
        -- return API.GetReports(filter)
    end)
    
    if not success then
        Logger.Info('⚠️  API call failed, using fallback for GetReports')
        return _G.APIFallback.GetReports(filter)
    end
    
    return result
end

-- ============================================================================
-- ANALYTICS WRAPPER
-- ============================================================================

function APIWrapper.LogEvent(eventType, data)
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.LogEvent(eventType, data)
    end
    
    pcall(function()
        -- Call your actual API here (fire and forget)
        -- API.LogEvent(eventType, data)
    end)
end

-- ============================================================================
-- MONITORING WRAPPER
-- ============================================================================

function APIWrapper.GetServerStats()
    if _G.APIHealth and _G.APIHealth.IsUsingFallback() then
        return _G.APIFallback.GetServerStats()
    end
    
    local success, result = pcall(function()
        -- Call your actual API here
        -- return API.GetServerStats()
    end)
    
    if not success then
        return _G.APIFallback.GetServerStats()
    end
    
    return result
end

-- ============================================================================
-- EXPORTS & INITIALIZATION
-- ============================================================================

-- Export all wrapper functions
for funcName, func in pairs(APIWrapper) do
    if type(func) == 'function' then
        exports(funcName, func)
    end
end

-- Global access
_G.APIWrapper = APIWrapper

-- Initialize after dependencies load
CreateThread(function()
    if WaitForDependencies() then
        Logger.Info('✅ API Wrapper ready - Auto-fallback enabled')
    else
        Logger.Warn('⚠️ API Wrapper initialized with degraded dependencies')
    end
end)
