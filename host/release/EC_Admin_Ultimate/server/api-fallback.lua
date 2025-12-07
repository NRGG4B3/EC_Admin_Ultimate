-- EC Admin Ultimate - API Fallback Functions
-- Local implementations when NRG APIs are offline
-- Version: 1.0.0

Logger.Info('🔄 API Fallback System loaded')

local APIFallback = {
    localBans = {},
    localWarnings = {},
    localReports = {},
    localAntiCheatFlags = {},
    localPlayerData = {}
}

-- ============================================================================
-- PLAYER DATA FALLBACK (when PlayerData API offline)
-- ============================================================================

function APIFallback.GetPlayerData(source)
    if not APIFallback.localPlayerData[source] then
        local identifiers = GetPlayerIdentifiers(source)
        local license = nil
        
        for _, id in ipairs(identifiers) do
            if string.match(id, "license:") then
                license = id
                break
            end
        end
        
        APIFallback.localPlayerData[source] = {
            source = source,
            name = GetPlayerName(source),
            license = license,
            identifiers = identifiers,
            playtime = 0,
            joinTime = os.time(),
            warnings = {},
            bans = {}
        }
    end
    
    return APIFallback.localPlayerData[source]
end

function APIFallback.SavePlayerData(source, data)
    APIFallback.localPlayerData[source] = data
    Logger.Info('💾 Fallback: Saved player data locally (source: ' .. source .. ')')
end

-- ============================================================================
-- GLOBAL BANS FALLBACK (when GlobalBans API offline)
-- ============================================================================

function APIFallback.AddBan(license, reason, adminName, duration)
    local ban = {
        license = license,
        reason = reason,
        adminName = adminName,
        bannedAt = os.time(),
        expiresAt = duration > 0 and (os.time() + duration) or nil,
        permanent = duration == 0
    }
    
    APIFallback.localBans[license] = ban
    
    Logger.Info('🚫 Fallback: Ban added locally')
    Logger.Info('License: ' .. license)
    Logger.Info('Reason: ' .. reason)
    Logger.Info('Duration: ' .. (duration == 0 and 'Permanent' or duration .. ' seconds'))
    
    return ban
end

function APIFallback.CheckBan(license)
    local ban = APIFallback.localBans[license]
    
    if not ban then
        return false, nil
    end
    
    -- Check if temporary ban expired
    if ban.expiresAt and os.time() >= ban.expiresAt then
        APIFallback.localBans[license] = nil
        return false, nil
    end
    
    return true, ban
end

function APIFallback.RemoveBan(license)
    if APIFallback.localBans[license] then
        APIFallback.localBans[license] = nil
        Logger.Info('✅ Fallback: Ban removed locally for ' .. license)
        return true
    end
    
    return false
end

function APIFallback.GetAllBans()
    local bans = {}
    
    for license, ban in pairs(APIFallback.localBans) do
        -- Skip expired bans
        if not ban.expiresAt or os.time() < ban.expiresAt then
            table.insert(bans, ban)
        end
    end
    
    return bans
end

-- ============================================================================
-- WARNINGS FALLBACK
-- ============================================================================

function APIFallback.AddWarning(license, reason, adminName)
    if not APIFallback.localWarnings[license] then
        APIFallback.localWarnings[license] = {}
    end
    
    local warning = {
        reason = reason,
        adminName = adminName,
        timestamp = os.time()
    }
    
    table.insert(APIFallback.localWarnings[license], warning)
    
    Logger.Info('⚠️  Fallback: Warning added locally for ' .. license)
    
    return warning
end

function APIFallback.GetWarnings(license)
    return APIFallback.localWarnings[license] or {}
end

function APIFallback.ClearWarnings(license)
    APIFallback.localWarnings[license] = {}
    Logger.Info('✅ Fallback: Warnings cleared locally for ' .. license)
end

-- ============================================================================
-- ANTI-CHEAT FALLBACK (when AntiCheat API offline)
-- ============================================================================

function APIFallback.LogCheatDetection(license, cheatType, confidence, details)
    if not APIFallback.localAntiCheatFlags[license] then
        APIFallback.localAntiCheatFlags[license] = {}
    end
    
    local flag = {
        cheatType = cheatType,
        confidence = confidence,
        details = details,
        timestamp = os.time()
    }
    
    table.insert(APIFallback.localAntiCheatFlags[license], flag)
    
    Logger.Info('🛡️  Fallback: Anti-cheat flag logged locally')
    Logger.Info('Type: ' .. cheatType .. ' | Confidence: ' .. confidence .. '%')
    
    return flag
end

function APIFallback.GetCheatFlags(license)
    return APIFallback.localAntiCheatFlags[license] or {}
end

-- ============================================================================
-- REPORTS FALLBACK
-- ============================================================================

function APIFallback.CreateReport(reporterSource, targetSource, reason, category)
    local report = {
        id = #APIFallback.localReports + 1,
        reporterSource = reporterSource,
        reporterName = GetPlayerName(reporterSource),
        targetSource = targetSource,
        targetName = GetPlayerName(targetSource),
        reason = reason,
        category = category,
        timestamp = os.time(),
        status = 'open'
    }
    
    table.insert(APIFallback.localReports, report)
    
    Logger.Info('📋 Fallback: Report created locally (#' .. report.id .. ')')
    
    return report
end

function APIFallback.GetReports(filter)
    local reports = {}
    
    for _, report in ipairs(APIFallback.localReports) do
        if not filter or filter == 'all' or report.status == filter then
            table.insert(reports, report)
        end
    end
    
    return reports
end

function APIFallback.UpdateReportStatus(reportId, status, adminName)
    for _, report in ipairs(APIFallback.localReports) do
        if report.id == reportId then
            report.status = status
            report.handledBy = adminName
            report.handledAt = os.time()
            
            Logger.Info('✅ Fallback: Report #' .. reportId .. ' updated to ' .. status)
            
            return true
        end
    end
    
    return false
end

-- ============================================================================
-- ANALYTICS FALLBACK (when Analytics API offline)
-- ============================================================================

function APIFallback.LogEvent(eventType, data)
    -- Just log to console, don't store (analytics not critical)
    Logger.Info('📊 Fallback: Event logged - ' .. eventType)
end

function APIFallback.GetAnalytics()
    return {
        message = "Analytics API offline - using fallback mode",
        fallbackMode = true,
        data = {}
    }
end

-- ============================================================================
-- MONITORING FALLBACK (when Monitoring API offline)
-- ============================================================================

function APIFallback.GetServerStats()
    return {
        players = GetNumPlayerIndices(),
        maxPlayers = GetConvarInt('sv_maxclients', 32),
        uptime = os.time(),
        fallbackMode = true
    }
end

-- ============================================================================
-- EXPORTS & GLOBAL ACCESS
-- ============================================================================

-- Export all fallback functions
for funcName, func in pairs(APIFallback) do
    if type(func) == 'function' then
        exports('Fallback_' .. funcName, func)
    end
end

-- Global access
_G.APIFallback = APIFallback

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    local source = source
    
    if APIFallback.localPlayerData[source] then
        APIFallback.localPlayerData[source] = nil
    end
end)

Logger.Info('✅ API Fallback System ready')
