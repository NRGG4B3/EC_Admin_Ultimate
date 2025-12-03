-- EC Admin Ultimate - Economy System (PRODUCTION STABLE)
-- Version: 1.0.0 - Safe economy tracking with framework integration

Logger.Info('💰 Loading economy system...')

local Economy = {}

-- Economy state
local economyData = {
    transactions = {},
    playerBalances = {},
    serverStats = {
        totalCash = 0,
        totalBank = 0,
        totalTransactions = 0,
        averageWealth = 0,
        lastUpdate = 0
    },
    alerts = {},
    config = {
        updateInterval = 60000,     -- 1 minute
        alertThreshold = 100000,    -- Alert on transactions over $100k
        suspiciousThreshold = 250000, -- Flag transactions over $250k
        maxTransactionHistory = 100
    }
}

-- Framework detection
local Framework = nil
local FrameworkObject = nil

-- Safe framework detection
local function DetectFramework()
    -- Detect QBCore (with multiple attempts and fallbacks)
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('💰 QBCore (qbx_core) detected, attempting to get core object...')
        
        -- Try multiple times with different approaches
        local success, coreObj = pcall(function()
            return exports['qbx_core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('💰 QBCore framework successfully connected for economy tracking')
            return true
        else
            Logger.Info('💰 QBCore detected but core object unavailable - using basic tracking')
            FrameworkObject = nil
            return true -- Still return true as framework is detected
        end
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('💰 QBCore (qb-core) detected, attempting to get core object...')
        
        local success, coreObj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('💰 QBCore framework successfully connected for economy tracking')
            return true
        else
            Logger.Info('💰 QBCore detected but core object unavailable - using basic tracking')
            FrameworkObject = nil
            return true -- Still return true as framework is detected
        end
    end
    
    -- Detect ESX
    if GetResourceState('es_extended') == 'started' then
        Framework = 'ESX'
        local success, esxObj = pcall(function()
            return exports["es_extended"]:getSharedObject()
        end)
        if success and esxObj then
            FrameworkObject = esxObj
            Logger.Info('💰 ESX framework detected for economy tracking')
            return true
        end
    end
    
    Logger.Info('⚠️ No supported framework detected for economy tracking')
    return false
end

-- Safe player balance retrieval
local function GetPlayerBalance(source, type)
    if not Framework or not FrameworkObject then return 0 end
    
    local success, balance = pcall(function()
        if Framework == 'QBCore' then
            local Player = FrameworkObject.Functions.GetPlayer(source)
            if Player then
                if type == 'cash' then
                    return Player.PlayerData.money['cash'] or 0
                elseif type == 'bank' then
                    return Player.PlayerData.money['bank'] or 0
                end
            end
        elseif Framework == 'ESX' then
            local xPlayer = FrameworkObject.GetPlayerFromId(source)
            if xPlayer then
                if type == 'cash' then
                    return xPlayer.getMoney() or 0
                elseif type == 'bank' then
                    return xPlayer.getAccount('bank').money or 0
                end
            end
        end
        return 0
    end)
    
    return success and balance or 0
end

-- Safe player identification
local function GetPlayerIdentifier(source)
    if not source or source == 0 then return nil end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, "steam:") then
            return identifier
        end
    end
    
    return identifiers[1]
end

-- Update player balance cache
function Economy.UpdatePlayerBalance(source)
    local identifier = GetPlayerIdentifier(source)
    if not identifier then return end
    
    local playerData = {
        source = source,
        identifier = identifier,
        name = GetPlayerName(source) or 'Unknown',
        cash = GetPlayerBalance(source, 'cash'),
        bank = GetPlayerBalance(source, 'bank'),
        lastUpdate = os.time()
    }
    
    playerData.total = playerData.cash + playerData.bank
    
    economyData.playerBalances[identifier] = playerData
end

-- Update server economy statistics
function Economy.UpdateServerStats()
    local totalCash = 0
    local totalBank = 0
    local playerCount = 0
    
    -- Calculate totals from active players
    for identifier, playerData in pairs(economyData.playerBalances) do
        -- Only count recent data (last 5 minutes)
        if os.time() - playerData.lastUpdate < 300 then
            totalCash = totalCash + playerData.cash
            totalBank = totalBank + playerData.bank
            playerCount = playerCount + 1
        end
    end
    
    economyData.serverStats.totalCash = totalCash
    economyData.serverStats.totalBank = totalBank
    economyData.serverStats.averageWealth = playerCount > 0 and ((totalCash + totalBank) / playerCount) or 0
    economyData.serverStats.lastUpdate = os.time()
    
    return economyData.serverStats
end

-- Log transaction
function Economy.LogTransaction(source, type, amount, details)
    local identifier = GetPlayerIdentifier(source)
    if not identifier then return end
    
    local transaction = {
        id = string.format('%d_%d', os.time(), math.random(1000, 9999)),
        identifier = identifier,
        playerName = GetPlayerName(source) or 'Unknown',
        type = type, -- 'receive', 'spend', 'transfer'
        amount = amount,
        details = details or '',
        timestamp = os.time()
    }
    
    table.insert(economyData.transactions, transaction)
    economyData.serverStats.totalTransactions = economyData.serverStats.totalTransactions + 1
    
    -- Keep only last N transactions
    while #economyData.transactions > economyData.config.maxTransactionHistory do
        table.remove(economyData.transactions, 1)
    end
    
    -- Check for suspicious activity
    if amount > economyData.config.suspiciousThreshold then
        local alert = {
            id = string.format('econ_alert_%d', os.time()),
            type = 'suspicious_transaction',
            message = string.format('Large transaction detected: $%s by %s', 
                                  Economy.FormatMoney(amount), transaction.playerName),
            severity = 'high',
            timestamp = os.time(),
            data = transaction
        }
        
        table.insert(economyData.alerts, alert)
        
        -- Send to monitoring system if available
        if _G.ECMonitoring and _G.ECMonitoring.CreateAlert then
            _G.ECMonitoring.CreateAlert('economy', alert.message, alert.severity)
        end
        
        Logger.Info('🚨 Suspicious transaction: $' .. Economy.FormatMoney(amount) .. ' by ' .. transaction.playerName)
    end
    
    -- Log to database if available
    if _G.ECDatabase and _G.ECDatabase.Insert then
        Citizen.CreateThread(function()
            _G.ECDatabase.Insert('ec_economy_transactions', {
                identifier = transaction.identifier,
                player_name = transaction.playerName,
                transaction_type = transaction.type,
                amount = transaction.amount,
                details = transaction.details,
                timestamp = os.date('%Y-%m-%d %H:%M:%S', transaction.timestamp)
            })
        end)
    end
    
    return transaction
end

-- Format money for display
function Economy.FormatMoney(amount)
    if amount >= 1000000 then
        return string.format('%.1fM', amount / 1000000)
    elseif amount >= 1000 then
        return string.format('%.1fK', amount / 1000)
    else
        return tostring(amount)
    end
end

-- Get economy data
function Economy.GetServerStats()
    return Economy.UpdateServerStats()
end

function Economy.GetPlayerBalances()
    return economyData.playerBalances
end

function Economy.GetTransactions()
    return economyData.transactions
end

function Economy.GetAlerts()
    return economyData.alerts
end

-- Admin functions
function Economy.GiveMoney(adminSource, targetSource, type, amount, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'giveMoney') then
        return false, 'Insufficient permissions'
    end
    
    if not Framework or not FrameworkObject then
        return false, 'No supported framework detected'
    end
    
    local success = pcall(function()
        if Framework == 'QBCore' then
            local Player = FrameworkObject.Functions.GetPlayer(targetSource)
            if Player then
                Player.Functions.AddMoney(type, amount, reason)
            end
        elseif Framework == 'ESX' then
            local xPlayer = FrameworkObject.GetPlayerFromId(targetSource)
            if xPlayer then
                if type == 'cash' then
                    xPlayer.addMoney(amount)
                elseif type == 'bank' then
                    xPlayer.addAccountMoney('bank', amount)
                end
            end
        end
    end)
    
    if success then
        Economy.LogTransaction(targetSource, 'admin_give', amount, reason)
        return true, 'Money given successfully'
    else
        return false, 'Failed to give money'
    end
end

function Economy.RemoveMoney(adminSource, targetSource, type, amount, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'removeMoney') then
        return false, 'Insufficient permissions'
    end
    
    if not Framework or not FrameworkObject then
        return false, 'No supported framework detected'
    end
    
    local success = pcall(function()
        if Framework == 'QBCore' then
            local Player = FrameworkObject.Functions.GetPlayer(targetSource)
            if Player then
                Player.Functions.RemoveMoney(type, amount, reason)
            end
        elseif Framework == 'ESX' then
            local xPlayer = FrameworkObject.GetPlayerFromId(targetSource)
            if xPlayer then
                if type == 'cash' then
                    xPlayer.removeMoney(amount)
                elseif type == 'bank' then
                    xPlayer.removeAccountMoney('bank', amount)
                end
            end
        end
    end)
    
    if success then
        Economy.LogTransaction(targetSource, 'admin_remove', amount, reason)
        return true, 'Money removed successfully'
    else
        return false, 'Failed to remove money'
    end
end

-- Initialize economy system
function Economy.Initialize()
    Logger.Info('💰 Initializing economy system...')
    
    -- Detect framework
    local frameworkDetected = DetectFramework()
    if not frameworkDetected then
        Logger.Info('⚠️ Economy system disabled - no supported framework')
        return false
    end
    
    -- Start monitoring loop
    Citizen.CreateThread(function()
        Citizen.Wait(5000) -- Wait for server to settle
        
        while true do
            Citizen.Wait(economyData.config.updateInterval)
            
            -- Update all player balances
            for i = 0, GetNumPlayerIndices() - 1 do
                local player = GetPlayerFromIndex(i)
                if player and tonumber(player) and tonumber(player) > 0 then
                    Economy.UpdatePlayerBalance(player)
                end
            end
            
            -- Update server stats
            Economy.UpdateServerStats()
        end
    end)
    
    Logger.Info('✅ Economy system initialized with ' .. Framework .. ' framework')
    return true
end

-- REMOVED: Event handlers moved to player-events.lua for centralization
-- The centralized handler calls Economy.UpdatePlayerBalance

-- Bulk economy operations
local economyFrozen = false

function Economy.SendMoneyToAll(adminSource, amount, moneyType, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'economy.bulk') then
        return false, 'Insufficient permissions'
    end
    
    if economyFrozen then
        return false, 'Economy is frozen'
    end
    
    local successCount = 0
    local totalAmount = 0
    
    for i = 0, GetNumPlayerIndices() - 1 do
        local player = GetPlayerFromIndex(i)
        if player and player > 0 then
            local success, _ = Economy.GiveMoney(adminSource, player, moneyType, amount, reason)
            if success then
                successCount = successCount + 1
                totalAmount = totalAmount + amount
            end
        end
    end
    
    Logger.Info(string.format('', 
          Economy.FormatMoney(amount), successCount, Economy.FormatMoney(totalAmount)))
    
    return true, string.format('Sent $%s to %d players', Economy.FormatMoney(amount), successCount)
end

function Economy.RemovePercentageFromAll(adminSource, percentage, moneyType, reason)
    if not _G.ECPermissions or not_G.ECPermissions.HasPermission(adminSource, 'economy.bulk') then
        return false, 'Insufficient permissions'
    end
    
    if economyFrozen then
        return false, 'Economy is frozen'
    end
    
    local successCount = 0
    local totalRemoved = 0
    
    for i = 0, GetNumPlayerIndices() - 1 do
        local player = GetPlayerFromIndex(i)
        if player and player > 0 then
            local balance = 0
            if moneyType == 'all' then
                balance = GetPlayerBalance(player, 'cash') + GetPlayerBalance(player, 'bank')
            else
                balance = GetPlayerBalance(player, moneyType)
            end
            
            local removeAmount = math.floor(balance * (percentage / 100))
            
            if removeAmount > 0 then
                if moneyType == 'all' then
                    Economy.RemoveMoney(adminSource, player, 'cash', math.floor(GetPlayerBalance(player, 'cash') * (percentage / 100)), reason)
                    Economy.RemoveMoney(adminSource, player, 'bank', math.floor(GetPlayerBalance(player, 'bank') * (percentage / 100)), reason)
                else
                    Economy.RemoveMoney(adminSource, player, moneyType, removeAmount, reason)
                end
                successCount = successCount + 1
                totalRemoved = totalRemoved + removeAmount
            end
        end
    end
    
    Logger.Info(string.format('', 
          percentage, successCount, Economy.FormatMoney(totalRemoved)))
    
    return true, string.format('Removed %d%% from %d players', percentage, successCount)
end

function Economy.WipeAllMoney(adminSource, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'economy.wipe') then
        return false, 'Insufficient permissions - requires WIPE permission'
    end
    
    local successCount = 0
    local totalRemoved = 0
    
    for i = 0, GetNumPlayerIndices() - 1 do
        local player = GetPlayerFromIndex(i)
        if player and player > 0 then
            local cash = GetPlayerBalance(player, 'cash')
            local bank = GetPlayerBalance(player, 'bank')
            
            Economy.RemoveMoney(adminSource, player, 'cash', cash, reason)
            Economy.RemoveMoney(adminSource, player, 'bank', bank, reason)
            
            successCount = successCount + 1
            totalRemoved = totalRemoved + cash + bank
        end
    end
    
    Logger.Info(string.format('', 
          successCount, Economy.FormatMoney(totalRemoved)))
    
    return true, string.format('Wiped all money from %d players', successCount)
end

function Economy.FreezeEconomy(adminSource, freeze, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'economy.freeze') then
        return false, 'Insufficient permissions'
    end
    
    economyFrozen = freeze
    
    local adminName = GetPlayerName(adminSource) or 'Admin'
    local status = freeze and 'FROZEN' or 'UNFROZEN'
    
    Logger.Info(string.format('', status, adminName, reason))
    
    -- Notify all players
    TriggerClientEvent('chat:addMessage', -1, {
        color = freeze and {255, 100, 100} or {100, 255, 100},
        multiline = true,
        args = {'[EC Admin]', string.format('Economy has been %s by an administrator', status:lower())}
    })
    
    return true, string.format('Economy %s', status:lower())
end

function Economy.RedistributeWealth(adminSource, minWealth, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'economy.redistribute') then
        return false, 'Insufficient permissions'
    end
    
    if economyFrozen then
        return false, 'Economy is frozen'
    end
    
    local richPlayers = {}
    local poorPlayers = {}
    local totalTaken = 0
    
    -- Categorize players
    for i = 0, GetNumPlayerIndices() - 1 do
        local player = GetPlayerFromIndex(i)
        if player and player > 0 then
            local total = GetPlayerBalance(player, 'cash') + GetPlayerBalance(player, 'bank')
            if total > minWealth then
                table.insert(richPlayers, {source = player, wealth = total})
            elseif total < minWealth then
                table.insert(poorPlayers, {source = player, wealth = total})
            end
        end
    end
    
    -- Take 10% from rich players
    for _, player in ipairs(richPlayers) do
        local takeAmount = math.floor(GetPlayerBalance(player.source, 'bank') * 0.1)
        if takeAmount > 0 then
            Economy.RemoveMoney(adminSource, player.source, 'bank', takeAmount, reason)
            totalTaken = totalTaken + takeAmount
        end
    end
    
    -- Distribute to poor players
    if #poorPlayers > 0 and totalTaken > 0 then
        local perPlayerGive = math.floor(totalTaken / #poorPlayers)
        for _, player in ipairs(poorPlayers) do
            Economy.GiveMoney(adminSource, player.source, 'bank', perPlayerGive, reason)
        end
    end
    
    Logger.Info(string.format('', 
          Economy.FormatMoney(totalTaken), #richPlayers, #poorPlayers))
    
    return true, string.format('Redistributed $%s from %d to %d players', 
           Economy.FormatMoney(totalTaken), #richPlayers, #poorPlayers)
end

function Economy.IsFrozen()
    return economyFrozen
end

-- Server events
RegisterNetEvent('ec-admin:getEconomyData')
AddEventHandler('ec-admin:getEconomyData', function()
    local source = source
    
    local response = {
        serverStats = Economy.GetServerStats(),
        playerBalances = Economy.GetPlayerBalances(),
        recentTransactions = Economy.GetTransactions(),
        alerts = Economy.GetAlerts(),
        framework = Framework,
        frozen = economyFrozen
    }
    
    TriggerClientEvent('ec-admin:receiveEconomyData', source, response)
end)

-- Bulk operation server events
RegisterNetEvent('ec-admin:economy:sendToAll')
AddEventHandler('ec-admin:economy:sendToAll', function(data, cb)
    local source = source
    local success, message = Economy.SendMoneyToAll(source, data.amount or 0, data.moneyType or 'cash', data.reason or 'Bulk send')
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:economy:removePercent')
AddEventHandler('ec-admin:economy:removePercent', function(data, cb)
    local source = source
    local success, message = Economy.RemovePercentageFromAll(source, data.percentage or 10, data.moneyType or 'cash', data.reason or 'Inflation control')
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:economy:wipeAll')
AddEventHandler('ec-admin:economy:wipeAll', function(data, cb)
    local source = source
    local success, message = Economy.WipeAllMoney(source, data.reason or 'Economy reset')
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:economy:freeze')
AddEventHandler('ec-admin:economy:freeze', function(data, cb)
    local source = source
    local freeze = not economyFrozen -- Toggle
    local success, message = Economy.FreezeEconomy(source, freeze, data.reason or 'Administrative action')
    
    if cb then
        cb({ success = success, message = message, frozen = economyFrozen })
    end
end)

RegisterNetEvent('ec-admin:economy:redistribute')
AddEventHandler('ec-admin:economy:redistribute', function(data, cb)
    local source = source
    local success, message = Economy.RedistributeWealth(source, data.minWealth or 100000, data.reason or 'Wealth redistribution')
    
    if cb then
        cb({ success = success, message = message })
    end
end)

-- Exports
exports('GetServerStats', function()
    return Economy.GetServerStats()
end)

exports('LogTransaction', function(source, type, amount, details)
    return Economy.LogTransaction(source, type, amount, details)
end)

exports('GiveMoney', function(adminSource, targetSource, type, amount, reason)
    return Economy.GiveMoney(adminSource, targetSource, type, amount, reason)
end)

exports('RemoveMoney', function(adminSource, targetSource, type, amount, reason)
    return Economy.RemoveMoney(adminSource, targetSource, type, amount, reason)
end)

exports('IsFrozen', function()
    return Economy.IsFrozen()
end)

-- Initialize when loaded
Economy.Initialize()

-- Make available globally
_G.ECEconomy = Economy

-- Register with centralized player events system
if _G.ECPlayerEvents then
    _G.ECPlayerEvents.RegisterSystem('economy')
end

Logger.Info('✅ Economy system loaded successfully')