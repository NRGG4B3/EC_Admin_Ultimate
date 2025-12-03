-- EC Admin Ultimate - Economy Callbacks (Complete FiveM Integration)
-- Version: 1.0.0 - Production-Ready with 20+ Economy Actions
-- Supports: QB-Core, QBX, ESX, Standalone

-- ============================================================================
-- IMPORTANT: This file uses lib.callback.register ONLY (server-side)
-- RegisterNUICallback is CLIENT-SIDE ONLY and has been removed
-- ============================================================================

Logger.Info('💰 Loading economy callbacks...')

-- ============================================================================
-- ECONOMY CALLBACKS - COMPLETE FIVEM INTEGRATION
-- ============================================================================

-- Utility Functions
local function GetFrameworkData()
    if GetResourceState('qb-core') == 'started' then
        return exports['qb-core']:GetCoreObject(), 'qb-core'
    elseif GetResourceState('qbx_core') == 'started' then
        return exports.qbx_core, 'qbx'
    elseif GetResourceState('es_extended') == 'started' then
        return exports['es_extended']:getSharedObject(), 'esx'
    end
    return nil, 'standalone'
end

local Framework, FrameworkType = GetFrameworkData()

-- Safe execution wrapper
local function SafeExecute(callback, errorMessage)
    local success, result = pcall(callback)
    if not success then
        Logger.Info('⚠️ ' .. errorMessage .. ': ' .. tostring(result))
        return false, result
    end
    return true, result
end

-- Get player money
local function GetPlayerMoney(source, moneyType)
    if not Framework then return 0 end
    
    local success, amount = SafeExecute(function()
        if FrameworkType == 'qbx' then
            -- QBX uses direct export
            local Player = exports.qbx_core:GetPlayer(source)
            if Player then
                return Player.PlayerData.money[moneyType] or 0
            end
        elseif FrameworkType == 'qb-core' then
            -- QB-Core uses GetCoreObject
            local Player = Framework.Functions.GetPlayer(source)
            if Player then
                return Player.PlayerData.money[moneyType] or 0
            end
        elseif FrameworkType == 'esx' then
            local xPlayer = Framework.GetPlayerFromId(source)
            if xPlayer then
                if moneyType == 'cash' or moneyType == 'money' then
                    return xPlayer.getMoney() or 0
                elseif moneyType == 'bank' then
                    return xPlayer.getAccount('bank').money or 0
                end
            end
        end
        return 0
    end, 'Get player money failed')
    
    return success and amount or 0
end

-- Add money to player
local function AddPlayerMoney(source, moneyType, amount, reason)
    if not Framework then return false end
    
    return SafeExecute(function()
        if FrameworkType == 'qbx' then
            -- QBX uses direct export
            local Player = exports.qbx_core:GetPlayer(source)
            if Player then
                Player.Functions.AddMoney(moneyType, amount, reason)
                return true
            end
        elseif FrameworkType == 'qb-core' then
            -- QB-Core uses GetCoreObject
            local Player = Framework.Functions.GetPlayer(source)
            if Player then
                Player.Functions.AddMoney(moneyType, amount, reason)
                return true
            end
        elseif FrameworkType == 'esx' then
            local xPlayer = Framework.GetPlayerFromId(source)
            if xPlayer then
                if moneyType == 'cash' or moneyType == 'money' then
                    xPlayer.addMoney(amount)
                elseif moneyType == 'bank' then
                    xPlayer.addAccountMoney('bank', amount)
                end
                return true
            end
        end
        return false
    end, 'Add player money failed')
end

-- Remove money from player
local function RemovePlayerMoney(source, moneyType, amount, reason)
    if not Framework then return false end
    
    return SafeExecute(function()
        if FrameworkType == 'qbx' then
            -- QBX uses direct export
            local Player = exports.qbx_core:GetPlayer(source)
            if Player then
                Player.Functions.RemoveMoney(moneyType, amount, reason)
                return true
            end
        elseif FrameworkType == 'qb-core' then
            -- QB-Core uses GetCoreObject
            local Player = Framework.Functions.GetPlayer(source)
            if Player then
                Player.Functions.RemoveMoney(moneyType, amount, reason)
                return true
            end
        elseif FrameworkType == 'esx' then
            local xPlayer = Framework.GetPlayerFromId(source)
            if xPlayer then
                if moneyType == 'cash' or moneyType == 'money' then
                    xPlayer.removeMoney(amount)
                elseif moneyType == 'bank' then
                    xPlayer.removeAccountMoney('bank', amount)
                end
                return true
            end
        end
        return false
    end, 'Remove player money failed')
end

-- Set player money
local function SetPlayerMoney(source, moneyType, amount, reason)
    if not Framework then return false end
    
    return SafeExecute(function()
        if FrameworkType == 'qbx' then
            -- QBX uses direct export
            local Player = exports.qbx_core:GetPlayer(source)
            if Player then
                Player.Functions.SetMoney(moneyType, amount, reason)
                return true
            end
        elseif FrameworkType == 'qb-core' then
            -- QB-Core uses GetCoreObject
            local Player = Framework.Functions.GetPlayer(source)
            if Player then
                Player.Functions.SetMoney(moneyType, amount, reason)
                return true
            end
        elseif FrameworkType == 'esx' then
            local xPlayer = Framework.GetPlayerFromId(source)
            if xPlayer then
                if moneyType == 'cash' or moneyType == 'money' then
                    xPlayer.setMoney(amount)
                elseif moneyType == 'bank' then
                    xPlayer.setAccountMoney('bank', amount)
                end
                return true
            end
        end
        return false
    end, 'Set player money failed')
end

-- Get player identifier
local function GetPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    for _, id in pairs(identifiers) do
        if string.find(id, 'steam:') then
            return id
        end
    end
    return identifiers[1]
end

-- ============================================================================
-- CALLBACK: GET ECONOMY DATA (for Economy page)
-- ============================================================================

lib.callback.register('ec_admin:getEconomyData', function(source, data)
    local players = GetPlayers()
    local playerList = {}
    local totalCash = 0
    local totalBank = 0
    local richestPlayer = { name = 'N/A', amount = 0 }
    
    for _, playerId in ipairs(players) do
        local id = tonumber(playerId)
        if id then
            local name = GetPlayerName(id)
            local cash = GetPlayerMoney(id, 'cash')
            local bank = GetPlayerMoney(id, 'bank')
            local totalWealth = cash + bank
            
            totalCash = totalCash + cash
            totalBank = totalBank + bank
            
            if totalWealth > richestPlayer.amount then
                richestPlayer.name = name
                richestPlayer.amount = totalWealth
            end
            
            table.insert(playerList, {
                source = id,
                name = name,
                identifier = GetPlayerIdentifier(id),
                cash = cash,
                bank = bank,
                totalWealth = totalWealth,
                transactions = 0
            })
        end
    end
    
    local totalMoney = totalCash + totalBank
    local averageMoney = #playerList > 0 and (totalMoney / #playerList) or 0
    
    return {
        success = true,
        playerWealth = playerList,
        transactions = {},
        categories = {},
        serverStats = {
            totalCash = totalCash,
            totalBank = totalBank,
            totalCrypto = 0,
            totalWealth = totalMoney,
            averageWealth = math.floor(averageMoney),
            suspiciousCount = 0,
            recentTransactions = 0
        },
        frozen = false
    }
end)

-- ============================================================================
-- CALLBACK: GET MONEY (for individual player)
-- ============================================================================

lib.callback.register('ec_admin:getPlayerMoney', function(source, data)
    local playerId = tonumber(data.playerId)
    
    if not playerId then
        return {success = false, message = 'Invalid player ID'}
    end
    
    local cash = GetPlayerMoney(playerId, 'cash')
    local bank = GetPlayerMoney(playerId, 'bank')
    local identifier = GetPlayerIdentifier(playerId)
    
    return {
        success = true,
        player = {
            id = playerId,
            name = GetPlayerName(playerId),
            identifier = identifier,
            cash = cash,
            bank = bank,
            totalWealth = cash + bank,
            transactions = {}
        }
    }
end)

Logger.Info('✅ Economy callbacks loaded')
Logger.Info('💰 Framework detected: ' .. FrameworkType)
