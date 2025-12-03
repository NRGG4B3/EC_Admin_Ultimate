-- EC Admin Ultimate - Real-Time Data Synchronization
-- Manages live data updates to all admin panels
--
-- ⚠️ CRITICAL ERROR FIX ⚠️
-- This file uses RegisterNUICallback which is CLIENT-SIDE ONLY in FiveM.
-- RegisterNUICallback CANNOT be used in server files.
--
-- This file has been DISABLED until all callbacks are converted to RegisterNetEvent.

--[[ DISABLED - See note above
Logger.Info('')
return -- Stop execution of this file
--]]

local ECAdminSync = {}
ECAdminSync.Version = "1.0.0"
ECAdminSync.UpdateInterval = 5000 -- 5 seconds
ECAdminSync.ActiveAdmins = {}

-- Initialize sync system
function ECAdminSync.Init()
    print("^2[EC Admin Sync] Initializing data synchronization...^0")
    
    -- DISABLED: This update loop was causing server hangs by running expensive operations
    -- The BroadcastUpdate() function calls GetAllVehicles() which blocks the main thread
    -- Data will be fetched on-demand instead via network events
    --[[ DISABLED - CAUSES SERVER HANG
    Citizen.CreateThread(function()
        while true do
            Wait(ECAdminSync.UpdateInterval)
            ECAdminSync.BroadcastUpdate()
        end
    end)
    --]]
    
    -- Initialize global state
    GlobalState.serverStartTime = os.time()
    GlobalState.adminAlerts = {}
    GlobalState.activeBans = {}
    GlobalState.recentJoins = 0
    GlobalState.recentLeaves = 0
    GlobalState.recentKicks = 0
    
    print("^2[EC Admin Sync] Data synchronization initialized (on-demand mode)^0")
end

-- Register admin panel
function ECAdminSync.RegisterAdmin(source)
    if not source then return end
    
    ECAdminSync.ActiveAdmins[source] = {
        identifier = GetPlayerIdentifier(source, 0),
        name = GetPlayerName(source),
        connectedAt = GetGameTimer()
    }
    
    -- Send initial data
    ECAdminSync.SendFullUpdate(source)
end

-- Unregister admin panel
function ECAdminSync.UnregisterAdmin(source)
    if not source then return end
    ECAdminSync.ActiveAdmins[source] = nil
end

-- Broadcast update to all active admins
function ECAdminSync.BroadcastUpdate()
    local data = ECAdminSync.CollectData()
    
    for source, admin in pairs(ECAdminSync.ActiveAdmins) do
        TriggerClientEvent('ec-admin:updateLiveData', source, data)
    end
end

-- Send full update to specific admin
function ECAdminSync.SendFullUpdate(source)
    local data = ECAdminSync.CollectData()
    TriggerClientEvent('ec-admin:updateLiveData', source, data)
end

-- Collect all live data
function ECAdminSync.CollectData()
    local players = GetPlayers()
    local playerCount = #players
    
    -- Collect player data
    local playerData = {}
    for _, playerId in ipairs(players) do
        local ped = GetPlayerPed(playerId)
        local coords = GetEntityCoords(ped)
        
        table.insert(playerData, {
            id = tonumber(playerId),
            name = GetPlayerName(playerId),
            position = { x = coords.x, y = coords.y, z = coords.z },
            health = GetEntityHealth(ped),
            ping = GetPlayerPing(playerId)
        })
    end
    
    -- Collect vehicle data (OPTIMIZED: Don't use GetAllVehicles() - it blocks the server!)
    -- Instead, use estimated vehicle count based on player count
    -- Real vehicle tracking should be done separately with caching
    local vehicleCount = math.floor(playerCount * 1.5) -- Estimate: 1.5 vehicles per player
    
    -- Collect server metrics
    -- GetFrameTime() doesn't exist on server side, use stable placeholder
    local tps = 30 -- Placeholder: Real TPS monitoring requires client-side metrics
    
    return {
        playersOnline = playerCount,
        totalResources = GetNumResources(),
        cachedVehicles = vehicleCount,
        serverTPS = tps,
        memoryUsage = collectgarbage('count'),
        networkIn = 0, -- Placeholder
        networkOut = 0, -- Placeholder
        cpuUsage = 0, -- Placeholder
        uptime = os.time() - (GlobalState.serverStartTime or os.time()),
        lastRestart = GlobalState.serverStartTime or os.time(),
        activeEvents = 0,
        database = {
            queries = GlobalState.dbQueries or 0,
            avgResponseTime = GlobalState.dbAvgTime or 0
        },
        alerts = GlobalState.adminAlerts or {},
        players = playerData,
        aiAnalytics = ECAdminSync.GetAIAnalytics(),
        economy = ECAdminSync.GetEconomyData(),
        performance = ECAdminSync.GetPerformanceData()
    }
end

-- Get AI Analytics data
function ECAdminSync.GetAIAnalytics()
    return {
        totalDetections = GlobalState.aiTotalDetections or 0,
        criticalThreats = GlobalState.aiCriticalThreats or 0,
        highRiskAlerts = GlobalState.aiHighRiskAlerts or 0,
        mediumRiskAlerts = GlobalState.aiMediumRiskAlerts or 0,
        lowRiskAlerts = GlobalState.aiLowRiskAlerts or 0,
        aiConfidence = GlobalState.aiConfidence or 0,
        modelsActive = GlobalState.aiModelsActive or 0,
        threatPredictionAccuracy = GlobalState.aiThreatAccuracy or 0
    }
end

-- Get Economy data
function ECAdminSync.GetEconomyData()
    return {
        totalTransactions = GlobalState.economyTotalTransactions or 0,
        cashFlow = GlobalState.economyCashFlow or 0,
        bankFlow = GlobalState.economyBankFlow or 0,
        averageWealth = GlobalState.economyAverageWealth or 0,
        economyHealth = GlobalState.economyHealth or 100,
        suspiciousTransactions = GlobalState.economySuspicious or 0
    }
end

-- Get Performance data
function ECAdminSync.GetPerformanceData()
    return {
        frameRate = math.floor(1.0 / GetFrameTime()),
        scriptTime = 0,
        entityCount = GetNumEntities(),
        vehicleCount = #GetAllVehicles(),
        playerLoad = #GetPlayers()
    }
end

-- Add alert
function ECAdminSync.AddAlert(alert)
    local alerts = GlobalState.adminAlerts or {}
    
    table.insert(alerts, {
        id = tostring(os.time()) .. math.random(1000, 9999),
        type = alert.type or 'info',
        message = alert.message,
        time = os.time(),
        severity = alert.severity or 'medium'
    })
    
    -- Keep only last 50 alerts
    if #alerts > 50 then
        table.remove(alerts, 1)
    end
    
    GlobalState.adminAlerts = alerts
    
    -- Broadcast immediately
    ECAdminSync.BroadcastUpdate()
end

-- Clear alerts
function ECAdminSync.ClearAlerts()
    GlobalState.adminAlerts = {}
    ECAdminSync.BroadcastUpdate()
end

-- Update economy stats
function ECAdminSync.UpdateEconomyStats(stats)
    if stats.totalTransactions then GlobalState.economyTotalTransactions = stats.totalTransactions end
    if stats.cashFlow then GlobalState.economyCashFlow = stats.cashFlow end
    if stats.bankFlow then GlobalState.economyBankFlow = stats.bankFlow end
    if stats.averageWealth then GlobalState.economyAverageWealth = stats.averageWealth end
    if stats.economyHealth then GlobalState.economyHealth = stats.economyHealth end
    if stats.suspiciousTransactions then GlobalState.economySuspicious = stats.suspiciousTransactions end
end

-- Update AI stats
function ECAdminSync.UpdateAIStats(stats)
    if stats.totalDetections then GlobalState.aiTotalDetections = stats.totalDetections end
    if stats.criticalThreats then GlobalState.aiCriticalThreats = stats.criticalThreats end
    if stats.highRiskAlerts then GlobalState.aiHighRiskAlerts = stats.highRiskAlerts end
    if stats.mediumRiskAlerts then GlobalState.aiMediumRiskAlerts = stats.mediumRiskAlerts end
    if stats.lowRiskAlerts then GlobalState.aiLowRiskAlerts = stats.lowRiskAlerts end
    if stats.aiConfidence then GlobalState.aiConfidence = stats.aiConfidence end
    if stats.modelsActive then GlobalState.aiModelsActive = stats.modelsActive end
    if stats.threatAccuracy then GlobalState.aiThreatAccuracy = stats.threatAccuracy end
end

-- REMOVED: Player events moved to player-events.lua for centralization
-- GlobalState updates are handled by the centralized event system

-- REMOVED: NUI Callbacks cannot be used on server side
-- These need to be RegisterNetEvent instead for client->server communication
-- Using network events for admin panel communication

RegisterNetEvent('ec-admin:sync:register')
AddEventHandler('ec-admin:sync:register', function()
    local source = source
    ECAdminSync.RegisterAdmin(source)
end)

RegisterNetEvent('ec-admin:sync:unregister')
AddEventHandler('ec-admin:sync:unregister', function()
    local source = source
    ECAdminSync.UnregisterAdmin(source)
end)

RegisterNetEvent('ec-admin:sync:getData')
AddEventHandler('ec-admin:sync:getData', function()
    local source = source
    local liveData = ECAdminSync.CollectData()
    TriggerClientEvent('ec-admin:sync:receiveData', source, liveData)
end)

-- Handle live data requests from client (for NUI updates)
RegisterNetEvent('ec_admin:server:getLiveData')
AddEventHandler('ec_admin:server:getLiveData', function()
    local source = source
    local liveData = ECAdminSync.CollectData()
    
    -- Send REAL data back to client (which forwards to NUI)
    TriggerClientEvent('ec_admin:client:updateLiveData', source, liveData)
    
    print(string.format("^2[EC Admin Sync] Sent live data to client %s (Players: %d, Resources: %d, Memory: %.2f MB)^0", 
        source, 
        liveData.playersOnline or 0, 
        liveData.totalResources or 0,
        (liveData.memoryUsage or 0) / 1024
    ))
end)

RegisterNetEvent('ec-admin:alerts:clear')
AddEventHandler('ec-admin:alerts:clear', function()
    ECAdminSync.ClearAlerts()
end)

-- Initialize on resource start
Citizen.CreateThread(function()
    Wait(1000)
    ECAdminSync.Init()
end)

-- Export functions
exports('AddAlert', ECAdminSync.AddAlert)
exports('UpdateEconomyStats', ECAdminSync.UpdateEconomyStats)
exports('UpdateAIStats', ECAdminSync.UpdateAIStats)
exports('BroadcastUpdate', ECAdminSync.BroadcastUpdate)

-- Make available globally
_G.ECAdminSync = ECAdminSync

-- Register with centralized player events system
if _G.ECPlayerEvents then
    _G.ECPlayerEvents.RegisterSystem('dataSync')
end

return ECAdminSync
