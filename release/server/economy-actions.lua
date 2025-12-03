--[[
    EC Admin Ultimate - Economy Actions
    Event handlers for economy management (money, items, etc.)
]]

-- ==========================================
-- MONEY MANAGEMENT
-- ==========================================

local function DetectFramework()
    if GetResourceState('qbx_core') == 'started' then
        return 'qbx', exports.qbx_core
    elseif GetResourceState('qb-core') == 'started' then
        return 'qb', exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx', exports['es_extended']:getSharedObject()
    end

    return 'standalone', nil
end

local FrameworkType, Framework = DetectFramework()

local function GetFrameworkPlayer(targetId)
    if FrameworkType == 'qbx' then
        return Framework:GetPlayer(targetId)
    elseif FrameworkType == 'qb' then
        return Framework.Functions.GetPlayer(targetId)
    elseif FrameworkType == 'esx' then
        return Framework.GetPlayerFromId(targetId)
    end

    return nil
end

local function HasMoneyAccount(player, account)
    if not player then return false end

    if FrameworkType == 'qbx' or FrameworkType == 'qb' then
        return player.PlayerData and player.PlayerData.money and player.PlayerData.money[account] ~= nil
    elseif FrameworkType == 'esx' then
        if account == 'cash' or account == 'money' then
            return true
        end

        return player.getAccount ~= nil and player.getAccount(player, account) ~= nil
    end

    return false
end

local function PerformMoneyAction(action, player, account, amount)
    if FrameworkType == 'qbx' or FrameworkType == 'qb' then
        if action == 'add' then
            player.Functions.AddMoney(account, amount, 'EC Admin economy action')
        elseif action == 'remove' then
            player.Functions.RemoveMoney(account, amount, 'EC Admin economy action')
        elseif action == 'set' then
            player.Functions.SetMoney(account, amount, 'EC Admin economy action')
        end

        return true
    elseif FrameworkType == 'esx' then
        if account == 'cash' or account == 'money' then
            if action == 'add' then
                player.addMoney(amount)
            elseif action == 'remove' then
                player.removeMoney(amount)
            elseif action == 'set' then
                player.setMoney(amount)
            end
        else
            if action == 'add' then
                player.addAccountMoney(account, amount)
            elseif action == 'remove' then
                player.removeAccountMoney(account, amount)
            elseif action == 'set' then
                player.setAccountMoney(account, amount)
            end
        end

        return true
    end

    return false
end

local function NotifyStandalone(action, adminSource, targetId, amount, moneyType)
    Logger.Info(string.format('', action, amount, moneyType, tostring(targetId)))

    TriggerClientEvent('ec_admin:notify', adminSource, {
        type = 'info',
        message = string.format('[Standalone] Requested %s %s %s for player %s', action, moneyType, amount, tostring(targetId))
    })
end

RegisterNetEvent('ec_admin:giveMoney', function(data)
    local src = source
    
    if not data or not data.playerId or not data.amount then return end
    
    -- Permission check
    if not HasPermission or not HasPermission(src) then 
        Logger.Info('')
        return 
    end
    
    -- Rate limit check
    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:giveMoney') then
        return
    end
    
    local targetId = tonumber(data.playerId)
    local amount = tonumber(data.amount)
    local moneyType = data.type or 'cash' -- cash, bank
    
    -- Validate amount
    if not targetId or not amount then 
        return 
    end
    
    -- Check for NaN
    if amount ~= amount then
        Logger.Info('' .. GetPlayerName(src) .. '^0')
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'Invalid amount'
        })
        return
    end
    
    -- Check reasonable bounds
    local MAX_AMOUNT = 10000000 -- $10M max
    local MIN_AMOUNT = 1
    
    if amount < MIN_AMOUNT or amount > MAX_AMOUNT then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = string.format('Amount must be between $%d and $%d', MIN_AMOUNT, MAX_AMOUNT)
        })
        Logger.Info(string.format('', amount, GetPlayerName(src)))
        return
    end
    
    if FrameworkType == 'standalone' or not Framework then
        NotifyStandalone('give', src, targetId, amount, moneyType)
        return
    end

    local player = GetFrameworkPlayer(targetId)

    if not player then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'Target player not found'
        })
        return
    end

    if not HasMoneyAccount(player, moneyType) then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = string.format('Account type %s is not available for this player', moneyType)
        })
        return
    end

    if PerformMoneyAction('add', player, moneyType, amount) then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = string.format('Gave $%d %s to %s', amount, moneyType, GetPlayerName(targetId))
        })

        TriggerClientEvent('ec_admin:notify', targetId, {
            type = 'success',
            message = string.format('Received $%d %s', amount, moneyType)
        })
    end

    -- Log activity
    TriggerEvent('ec_admin:logActivity', {
        type = 'money_give',
        admin = GetPlayerName(src),
        target = GetPlayerName(targetId),
        description = string.format('Gave $%d %s', amount, moneyType)
    })
end)

RegisterNetEvent('ec_admin:removeMoney', function(data)
    local src = source
    
    if not data or not data.playerId or not data.amount then return end
    
    -- Permission check
    if not HasPermission or not HasPermission(src) then 
        Logger.Info('')
        return 
    end
    
    -- Rate limit check
    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:removeMoney') then
        return
    end
    
    local targetId = tonumber(data.playerId)
    local amount = tonumber(data.amount)
    local moneyType = data.type or 'cash'
    
    -- Validate amount
    if not targetId or not amount then 
        return 
    end
    
    -- Check for NaN
    if amount ~= amount then
        Logger.Info('' .. GetPlayerName(src) .. '^0')
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'Invalid amount'
        })
        return
    end
    
    -- Check reasonable bounds
    local MAX_AMOUNT = 10000000 -- $10M max
    local MIN_AMOUNT = 1
    
    if amount < MIN_AMOUNT or amount > MAX_AMOUNT then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = string.format('Amount must be between $%d and $%d', MIN_AMOUNT, MAX_AMOUNT)
        })
        Logger.Info(string.format('', amount, GetPlayerName(src)))
        return
    end
    
    if FrameworkType == 'standalone' or not Framework then
        NotifyStandalone('remove', src, targetId, amount, moneyType)
        return
    end

    local player = GetFrameworkPlayer(targetId)

    if not player then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'Target player not found'
        })
        return
    end

    if not HasMoneyAccount(player, moneyType) then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = string.format('Account type %s is not available for this player', moneyType)
        })
        return
    end

    if PerformMoneyAction('remove', player, moneyType, amount) then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = string.format('Removed $%d %s from %s', amount, moneyType, GetPlayerName(targetId))
        })
    end

    -- Log activity
    TriggerEvent('ec_admin:logActivity', {
        type = 'money_remove',
        admin = GetPlayerName(src),
        target = GetPlayerName(targetId),
        description = string.format('Removed $%d %s', amount, moneyType)
    })
end)

RegisterNetEvent('ec_admin:setMoney', function(data)
    local src = source
    
    if not data or not data.playerId or not data.amount then return end
    if not IsPlayerAceAllowed(src, 'admin.access') then return end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:setMoney') then
        return
    end

    local targetId = tonumber(data.playerId)
    local amount = tonumber(data.amount)
    local moneyType = data.type or 'cash'
    
    if not targetId or not amount or amount < 0 then return end
    
    if FrameworkType == 'standalone' or not Framework then
        NotifyStandalone('set', src, targetId, amount, moneyType)
        return
    end

    local player = GetFrameworkPlayer(targetId)

    if not player then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'Target player not found'
        })
        return
    end

    if not HasMoneyAccount(player, moneyType) then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = string.format('Account type %s is not available for this player', moneyType)
        })
        return
    end

    if PerformMoneyAction('set', player, moneyType, amount) then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = string.format('Set %s to $%d for %s', moneyType, amount, GetPlayerName(targetId))
        })
    end

    -- Log activity
    TriggerEvent('ec_admin:logActivity', {
        type = 'money_set',
        admin = GetPlayerName(src),
        target = GetPlayerName(targetId),
        description = string.format('Set %s to $%d', moneyType, amount)
    })
end)

Logger.Info("^7 Economy actions loaded")
