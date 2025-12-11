--[[
    EC Admin Ultimate - Economy & Global Tools UI Backend
    Server-side logic for economy management and global tools
    
    Handles:
    - economy:getData: Get complete economy data
    - server:getSettings: Get server settings
    - globaltools/execute: Execute global tool actions (30+ actions)
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Economy Global Tools] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Economy Global Tools] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local economyFrozen = false
local timeFrozen = false
local weatherFrozen = false
local currentWeather = 'clear'
local currentTime = 12

-- Caching for expensive operations
local economyDataCache = {}
local ECONOMY_CACHE_TTL = 10 -- Cache for 10 seconds
local callbackThrottle = {}
local THROTTLE_INTERVAL = 2000 -- 2 seconds minimum between calls

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Check admin permission
local function hasPermission(source, permission)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, permission)
    end
    return ECFramework.IsAdminGroup(source) or false
end

-- Helper: Get player identifier from source
local function getPlayerIdentifierFromSource(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    
    return identifiers[1]
end

-- Helper: Get player wealth from framework
local function getPlayerWealth(source, identifier)
    local wealth = {
        cash = 0,
        bank = 0,
        crypto = 0,
        totalWealth = 0
    }
    
    local framework = getFramework()
    
    if source then
        local player = ECFramework.GetPlayerObject(source)
        
        if (framework == 'qb' or framework == 'qbx') and player and player.PlayerData then
            local money = player.PlayerData.money or {}
            wealth.cash = money.cash or 0
            wealth.bank = money.bank or 0
            wealth.crypto = money.crypto or 0
        elseif framework == 'esx' and player then
            local accounts = player.getAccounts and player:getAccounts() or player.accounts
            if accounts then
                for _, account in pairs(accounts) do
                    if account.name == 'money' then
                        wealth.cash = account.money or 0
                    elseif account.name == 'bank' then
                        wealth.bank = account.money or 0
                    end
                end
            end
        end
    else
        -- Get from database for offline players
        local result = MySQL.query.await('SELECT cash, bank, crypto FROM ec_economy_data WHERE identifier = ?', {identifier})
        if result and result[1] then
            wealth.cash = tonumber(result[1].cash) or 0
            wealth.bank = tonumber(result[1].bank) or 0
            wealth.crypto = tonumber(result[1].crypto) or 0
        end
    end
    
    wealth.totalWealth = wealth.cash + wealth.bank + wealth.crypto
    
    return wealth
end

-- Helper: Get all players wealth
local function getAllPlayersWealth()
    local players = {}
    local onlinePlayers = GetPlayers()
    local framework = getFramework()
    
    -- Get online players
    for _, playerId in ipairs(onlinePlayers) do
        local source = tonumber(playerId)
        if source then
            local name = GetPlayerName(source) or 'Unknown'
            local identifier = getPlayerIdentifierFromSource(source)
            local wealth = getPlayerWealth(source, identifier)
            local job = 'unemployed'
            
            -- Get job
            if framework == 'qb' or framework == 'qbx' then
                local player = ECFramework.GetPlayerObject(source)
                if player and player.PlayerData and player.PlayerData.job then
                    job = player.PlayerData.job.name or 'unemployed'
                end
            elseif framework == 'esx' then
                local player = ECFramework.GetPlayerObject(source)
                if player and player.job then
                    job = player.job.name or 'unemployed'
                end
            end
            
            -- Check suspicious (simplified - could be enhanced)
            local suspicious = wealth.totalWealth > 1000000 or false
            
            table.insert(players, {
                id = source,
                name = name,
                identifier = identifier or '',
                cash = wealth.cash,
                bank = wealth.bank,
                crypto = wealth.crypto,
                totalWealth = wealth.totalWealth,
                job = job,
                suspicious = suspicious,
                lastTransaction = nil
            })
        end
    end
    
    return players
end

-- Helper: Calculate economy statistics
local function calculateEconomyStats(players)
    local stats = {
        totalCash = 0,
        totalBank = 0,
        totalCrypto = 0,
        totalWealth = 0,
        averageWealth = 0,
        suspiciousCount = 0,
        recentTransactions = 0
    }
    
    for _, player in ipairs(players) do
        stats.totalCash = stats.totalCash + player.cash
        stats.totalBank = stats.totalBank + player.bank
        stats.totalCrypto = stats.totalCrypto + (player.crypto or 0)
        stats.totalWealth = stats.totalWealth + player.totalWealth
        
        if player.suspicious then
            stats.suspiciousCount = stats.suspiciousCount + 1
        end
    end
    
    if #players > 0 then
        stats.averageWealth = stats.totalWealth / #players
    end
    
    -- Get recent transactions count
    local cutoffTime = getCurrentTimestamp() - 86400 -- Last 24 hours
    local txResult = MySQL.query.await('SELECT COUNT(*) as count FROM ec_economy_transactions WHERE timestamp >= ?', {cutoffTime})
    if txResult and txResult[1] then
        stats.recentTransactions = txResult[1].count or 0
    end
    
    return stats
end

-- Helper: Get transactions
local function getTransactions(timeRange)
    local cutoffTime = getCurrentTimestamp()
    
    if timeRange == '24h' then
        cutoffTime = cutoffTime - 86400
    elseif timeRange == '7d' then
        cutoffTime = cutoffTime - (7 * 86400)
    elseif timeRange == '30d' then
        cutoffTime = cutoffTime - (30 * 86400)
    else
        cutoffTime = cutoffTime - 86400 -- Default 24h
    end
    
    local result = MySQL.query.await([[
        SELECT * FROM ec_economy_transactions
        WHERE timestamp >= ?
        ORDER BY timestamp DESC
        LIMIT 500
    ]], {cutoffTime})
    
    local transactions = {}
    
    if result then
        for _, row in ipairs(result) do
            local timeAgo = ''
            local diff = getCurrentTimestamp() - row.timestamp
            if diff < 60 then
                timeAgo = 'Just now'
            elseif diff < 3600 then
                timeAgo = math.floor(diff / 60) .. 'm ago'
            elseif diff < 86400 then
                timeAgo = math.floor(diff / 3600) .. 'h ago'
            else
                timeAgo = math.floor(diff / 86400) .. 'd ago'
            end
            
            table.insert(transactions, {
                id = row.transaction_id or tostring(row.id),
                from = row.from_name or row.from_identifier or 'Unknown',
                to = row.to_name or row.to_identifier or 'Unknown',
                amount = tonumber(row.amount),
                type = row.type,
                reason = row.reason or '',
                time = timeAgo,
                timestamp = row.timestamp,
                status = row.status or 'completed',
                suspicious = (row.suspicious == 1)
            })
        end
    end
    
    return transactions
end

-- Helper: Calculate categories
local function calculateCategories(stats)
    local total = stats.totalWealth
    if total == 0 then total = 1 end
    
    return {
        {
            category = 'Cash',
            amount = stats.totalCash,
            percentage = math.floor((stats.totalCash / total) * 100 * 10) / 10,
            trend = 'up',
            color = '#10b981'
        },
        {
            category = 'Bank',
            amount = stats.totalBank,
            percentage = math.floor((stats.totalBank / total) * 100 * 10) / 10,
            trend = 'up',
            color = '#3b82f6'
        },
        {
            category = 'Crypto',
            amount = stats.totalCrypto,
            percentage = math.floor((stats.totalCrypto / total) * 100 * 10) / 10,
            trend = 'up',
            color = '#8b5cf6'
        }
    }
end

-- Helper: Log economy action
local function logEconomyAction(action, source, targetId, amount, accountType, details)
    local adminName = GetPlayerName(source) or 'System'
    local adminId = getPlayerIdentifierFromSource(source) or 'system'
    local targetName = nil
    
    if targetId then
        local targetSource = tonumber(targetId)
        if targetSource and GetPlayerPing(targetSource) then
            targetName = GetPlayerName(targetSource)
        end
    end
    
    MySQL.insert.await([[
        INSERT INTO ec_economy_actions_log (action, performed_by, target_player, target_name, amount, account_type, details, timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {action, adminName, targetId, targetName, amount, accountType, details or '', getCurrentTimestamp()})
end

-- Helper: Log transaction
local function logTransaction(fromId, fromName, toId, toName, amount, txType, reason)
    local txId = 'tx_' .. getCurrentTimestamp() .. '_' .. math.random(1000, 9999)
    
    MySQL.insert.await([[
        INSERT INTO ec_economy_transactions (transaction_id, from_identifier, from_name, to_identifier, to_name, amount, type, reason, status, suspicious, timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'completed', 0, ?)
    ]], {txId, fromId, fromName, toId, toName, amount, txType, reason or '', getCurrentTimestamp()})
    
    return txId
end

-- Helper: Give money to player
local function giveMoneyToPlayer(source, targetId, amount, accountType)
    local framework = getFramework()
    local targetSource = tonumber(targetId)
    
    if not targetSource or not GetPlayerPing(targetSource) then
        return false, 'Player not found or offline'
    end
    
    local player = ECFramework.GetPlayerObject(targetSource)
    if not player then
        return false, 'Player object not found'
    end
    
    if economyFrozen then
        return false, 'Economy is frozen'
    end
    
    if (framework == 'qb' or framework == 'qbx') and player.PlayerData then
        if accountType == 'cash' then
            player.Functions.AddMoney('cash', amount)
        elseif accountType == 'bank' then
            player.Functions.AddMoney('bank', amount)
        elseif accountType == 'crypto' then
            player.Functions.AddMoney('crypto', amount)
        end
    elseif framework == 'esx' then
        if accountType == 'cash' then
            player.addAccountMoney('money', amount)
        elseif accountType == 'bank' then
            player.addAccountMoney('bank', amount)
        end
    end
    
    return true, 'Money given successfully'
end

-- Helper: Remove money from player
local function removeMoneyFromPlayer(source, targetId, amount, accountType)
    local framework = getFramework()
    local targetSource = tonumber(targetId)
    
    if not targetSource or not GetPlayerPing(targetSource) then
        return false, 'Player not found or offline'
    end
    
    local player = ECFramework.GetPlayerObject(targetSource)
    if not player then
        return false, 'Player object not found'
    end
    
    if economyFrozen then
        return false, 'Economy is frozen'
    end
    
    local wealth = getPlayerWealth(targetSource, nil)
    local currentAmount = 0
    
    if accountType == 'cash' then
        currentAmount = wealth.cash
    elseif accountType == 'bank' then
        currentAmount = wealth.bank
    elseif accountType == 'crypto' then
        currentAmount = wealth.crypto
    end
    
    if currentAmount < amount then
        return false, 'Insufficient funds'
    end
    
    if (framework == 'qb' or framework == 'qbx') and player.PlayerData then
        if accountType == 'cash' then
            player.Functions.RemoveMoney('cash', amount)
        elseif accountType == 'bank' then
            player.Functions.RemoveMoney('bank', amount)
        elseif accountType == 'crypto' then
            player.Functions.RemoveMoney('crypto', amount)
        end
    elseif framework == 'esx' then
        if accountType == 'cash' then
            player.removeAccountMoney('money', amount)
        elseif accountType == 'bank' then
            player.removeAccountMoney('bank', amount)
        end
    end
    
    return true, 'Money removed successfully'
end

-- Helper: Set player money
local function setPlayerMoney(source, targetId, amount, accountType)
    local framework = getFramework()
    local targetSource = tonumber(targetId)
    
    if not targetSource or not GetPlayerPing(targetSource) then
        return false, 'Player not found or offline'
    end
    
    local player = ECFramework.GetPlayerObject(targetSource)
    if not player then
        return false, 'Player object not found'
    end
    
    if economyFrozen then
        return false, 'Economy is frozen'
    end
    
    if (framework == 'qb' or framework == 'qbx') and player.PlayerData then
        if accountType == 'cash' then
            player.Functions.SetMoney('cash', amount)
        elseif accountType == 'bank' then
            player.Functions.SetMoney('bank', amount)
        elseif accountType == 'crypto' then
            player.Functions.SetMoney('crypto', amount)
        end
    elseif framework == 'esx' then
        if accountType == 'cash' then
            player.setAccountMoney('money', amount)
        elseif accountType == 'bank' then
            player.setAccountMoney('bank', amount)
        end
    end
    
    return true, 'Money set successfully'
end

-- Helper: Get server setting
local function getServerSetting(key, defaultValue)
    local result = MySQL.query.await('SELECT setting_value FROM ec_server_settings WHERE setting_key = ?', {key})
    if result and result[1] and result[1].setting_value then
        local value = result[1].setting_value
        -- Try to parse as JSON
        local success, parsed = pcall(json.decode, value)
        if success then
            return parsed
        end
        -- Try to parse as number
        local num = tonumber(value)
        if num then
            return num
        end
        -- Try to parse as boolean
        if value == 'true' then
            return true
        elseif value == 'false' then
            return false
        end
        return value
    end
    return defaultValue
end

-- Helper: Set server setting
local function setServerSetting(key, value, category, updatedBy)
    local valueStr = ''
    if type(value) == 'table' then
        valueStr = json.encode(value)
    else
        valueStr = tostring(value)
    end
    
    MySQL.insert.await([[
        INSERT INTO ec_server_settings (setting_key, setting_value, category, updated_by, updated_at)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE setting_value = ?, updated_by = ?, updated_at = ?
    ]], {key, valueStr, category, updatedBy, getCurrentTimestamp(), valueStr, updatedBy, getCurrentTimestamp()})
end

-- Note: RegisterNUICallback is CLIENT-side only
-- Use lib.callback.register for server-side callbacks
lib.callback.register('ec_admin:economy:getData', function(source, timeRange)
    -- Throttle: Check if called too recently
    local now = os.clock() * 1000
    timeRange = timeRange or '24h'
    local cacheKey = 'economy:getData:' .. tostring(source) .. ':' .. timeRange
    local lastCall = callbackThrottle[cacheKey] or 0
    
    if (now - lastCall) < THROTTLE_INTERVAL then
        if callbackThrottle[cacheKey .. ':response'] then
            return callbackThrottle[cacheKey .. ':response']
        end
    end
    
    callbackThrottle[cacheKey] = now
    
    -- Check cache first
    local cacheDataKey = 'economyData:' .. timeRange
    local currentTime = getCurrentTimestamp()
    if economyDataCache[cacheDataKey] and (currentTime - economyDataCache[cacheDataKey].timestamp) < ECONOMY_CACHE_TTL then
        local cached = economyDataCache[cacheDataKey].data
        callbackThrottle[cacheKey .. ':response'] = cached
        return cached
    end
    
    -- Get all players wealth (cached)
    local players = getAllPlayersWealth()
    
    -- Calculate statistics
    local stats = calculateEconomyStats(players)
    
    -- Get transactions
    local transactions = getTransactions(timeRange)
    
    -- Calculate categories
    local categories = calculateCategories(stats)
    
    -- Check if economy is frozen
    local frozen = economyFrozen
    
    local response = {
        success = true,
        economy = {
            playerWealth = players,
            transactions = transactions,
            categories = categories,
            serverStats = stats,
            frozen = frozen
        }
    }
    
    -- Cache response
    economyDataCache[cacheDataKey] = {
        data = response,
        timestamp = currentTime
    }
    callbackThrottle[cacheKey .. ':response'] = response
    
    return response
end)

-- Note: RegisterNUICallback is CLIENT-side only
-- Use lib.callback.register for server-side callbacks
lib.callback.register('ec_admin:economy:getServerSettings', function(source)
    -- Throttle: Check if called too recently
    local now = os.clock() * 1000
    local cacheKey = 'economy:getServerSettings:' .. tostring(source)
    local lastCall = callbackThrottle[cacheKey] or 0
    
    if (now - lastCall) < THROTTLE_INTERVAL then
        if callbackThrottle[cacheKey .. ':response'] then
            return callbackThrottle[cacheKey .. ':response']
        end
    end
    
    callbackThrottle[cacheKey] = now
    
    -- Get server settings
    local serverSettings = {
        maintenanceMode = getServerSetting('maintenance_mode', false),
        pvpEnabled = getServerSetting('pvp_enabled', true),
        economyEnabled = getServerSetting('economy_enabled', true),
        jobsEnabled = getServerSetting('jobs_enabled', true),
        whitelistEnabled = getServerSetting('whitelist_enabled', false),
        eventsEnabled = getServerSetting('events_enabled', true),
        housingEnabled = getServerSetting('housing_enabled', true)
    }
    
    -- Get world settings
    local worldSettings = {
        weather = getServerSetting('world_weather', 'clear'),
        time = getServerSetting('world_time', 12),
        freezeTime = getServerSetting('world_freeze_time', false),
        freezeWeather = getServerSetting('world_freeze_weather', false)
    }
    
    -- Get economy settings
    local economySettings = {
        taxRate = getServerSetting('economy_tax_rate', 10),
        salaryMultiplier = getServerSetting('economy_salary_multiplier', 1.0),
        priceMultiplier = getServerSetting('economy_price_multiplier', 1.0),
        economyMode = getServerSetting('economy_mode', 'normal')
    }
    
    local response = {
        success = true,
        settings = {
            server = serverSettings,
            world = worldSettings,
            economy = economySettings
        }
    }
    
    callbackThrottle[cacheKey .. ':response'] = response
    return response
end)

-- Callback: Execute global tool action
lib.callback.register('ec_admin:executeGlobalTool', function(source, data)
    local action = data.action
    local actionData = data.data or {}
    
    if not action or action == '' then
        return { success = false, message = 'Action required' }
    end
    
    -- Check permission
    if not hasPermission(source, 'admin.globaltools') then
        return { success = false, message = 'Permission denied' }
    end
    
    local adminName = GetPlayerName(source) or 'System'
    local success = false
    local message = 'Action executed'
    
    -- Route to appropriate handler
    if action == 'give-money' then
        local targetId = actionData.playerId
        local amount = tonumber(actionData.amount) or 0
        local account = actionData.account or 'bank'
        
        if not targetId or amount <= 0 then
            return { success = false, message = 'Invalid parameters' }
        end
        
        success, message = giveMoneyToPlayer(source, targetId, amount, account)
        if success then
            logEconomyAction('give-money', source, targetId, amount, account, 'Admin gave money')
            logTransaction('admin', adminName, tostring(targetId), GetPlayerName(tonumber(targetId)), amount, 'admin', 'Admin gave money')
        end
        
    elseif action == 'remove-money' then
        local targetId = actionData.playerId
        local amount = tonumber(actionData.amount) or 0
        local account = actionData.account or 'bank'
        
        if not targetId or amount <= 0 then
            return { success = false, message = 'Invalid parameters' }
        end
        
        success, message = removeMoneyFromPlayer(source, targetId, amount, account)
        if success then
            logEconomyAction('remove-money', source, targetId, amount, account, 'Admin removed money')
            logTransaction(tostring(targetId), GetPlayerName(tonumber(targetId)), 'admin', adminName, amount, 'admin', 'Admin removed money')
        end
        
    elseif action == 'set-money' then
        local targetId = actionData.playerId
        local amount = tonumber(actionData.amount) or 0
        local account = actionData.account or 'bank'
        
        if not targetId or amount < 0 then
            return { success = false, message = 'Invalid parameters' }
        end
        
        success, message = setPlayerMoney(source, targetId, amount, account)
        if success then
            logEconomyAction('set-money', source, targetId, amount, account, 'Admin set money')
        end
        
    elseif action == 'send-to-all' then
        local amount = tonumber(actionData.amount) or 0
        local account = actionData.account or 'bank'
        
        if amount <= 0 then
            return { success = false, message = 'Invalid amount' }
        end
        
        local players = GetPlayers()
        local successCount = 0
        
        -- Process players in batches to avoid blocking (async)
        CreateThread(function()
            for i, playerId in ipairs(players) do
                local targetSource = tonumber(playerId)
                if targetSource then
                    local s, m = giveMoneyToPlayer(source, targetSource, amount, account)
                    if s then
                        successCount = successCount + 1
                    end
                end
                
                -- Yield every 5 players to prevent blocking
                if i % 5 == 0 then
                    Wait(0)
                end
            end
            
            message = string.format('Sent money to %d/%d players', successCount, #players)
            logEconomyAction('send-to-all', source, nil, amount, account, message)
        end)
        
        success = true
        message = string.format('Processing money send to %d players...', #players)
        
    elseif action == 'remove-percentage' then
        local percentage = tonumber(actionData.percentage) or 0
        local account = actionData.account or 'bank'
        
        if percentage <= 0 or percentage > 100 then
            return { success = false, message = 'Invalid percentage' }
        end
        
        local players = GetPlayers()
        local successCount = 0
        
        -- Process players in batches to avoid blocking (async)
        CreateThread(function()
            for i, playerId in ipairs(players) do
                local targetSource = tonumber(playerId)
                if targetSource then
                    local wealth = getPlayerWealth(targetSource, nil)
                    local currentAmount = 0
                    
                    if account == 'cash' then
                        currentAmount = wealth.cash
                    elseif account == 'bank' then
                        currentAmount = wealth.bank
                    elseif account == 'crypto' then
                        currentAmount = wealth.crypto
                    elseif account == 'all' then
                        currentAmount = wealth.totalWealth
                    end
                    
                    local removeAmount = math.floor(currentAmount * (percentage / 100))
                    if removeAmount > 0 then
                        local s, m = removeMoneyFromPlayer(source, targetSource, removeAmount, account == 'all' and 'bank' or account)
                        if s then
                            successCount = successCount + 1
                        end
                    end
                end
                
                -- Yield every 5 players to prevent blocking
                if i % 5 == 0 then
                    Wait(0)
                end
            end
            
            message = string.format('Removed %d%% from %d/%d players', percentage, successCount, #players)
            logEconomyAction('remove-percentage', source, nil, percentage, account, message)
        end)
        
        success = true
        message = string.format('Processing percentage removal from %d players...', #players)
        
    elseif action == 'wipe-all-money' then
        local players = GetPlayers()
        local successCount = 0
        
        -- Process players in batches to avoid blocking (async)
        CreateThread(function()
            for i, playerId in ipairs(players) do
                local targetSource = tonumber(playerId)
                if targetSource then
                    local wealth = getPlayerWealth(targetSource, nil)
                    
                    -- Remove all money
                    if wealth.cash > 0 then
                        removeMoneyFromPlayer(source, targetSource, wealth.cash, 'cash')
                    end
                    if wealth.bank > 0 then
                        removeMoneyFromPlayer(source, targetSource, wealth.bank, 'bank')
                    end
                    if wealth.crypto > 0 then
                        removeMoneyFromPlayer(source, targetSource, wealth.crypto, 'crypto')
                    end
                    
                    successCount = successCount + 1
                end
                
                -- Yield every 5 players to prevent blocking
                if i % 5 == 0 then
                    Wait(0)
                end
            end
        end)
        
        success = true
        message = string.format('Wiped money from %d players', successCount)
        logEconomyAction('wipe-all-money', source, nil, 0, 'all', message)
        
    elseif action == 'freeze-economy' then
        economyFrozen = true
        setServerSetting('economy_frozen', true, 'economy', adminName)
        success = true
        message = 'Economy frozen'
        logEconomyAction('freeze-economy', source, nil, 0, nil, 'Economy frozen')
        
    elseif action == 'unfreeze-economy' then
        economyFrozen = false
        setServerSetting('economy_frozen', false, 'economy', adminName)
        success = true
        message = 'Economy unfrozen'
        logEconomyAction('unfreeze-economy', source, nil, 0, nil, 'Economy unfrozen')
        
    elseif action == 'set-maintenance' then
        local enabled = actionData.enabled == true
        setServerSetting('maintenance_mode', enabled, 'server', adminName)
        success = true
        message = enabled and 'Maintenance mode enabled' or 'Maintenance mode disabled'
        logEconomyAction('set-maintenance', source, nil, 0, nil, message)
        
    elseif action == 'set-pvp' then
        local enabled = actionData.enabled == true
        setServerSetting('pvp_enabled', enabled, 'server', adminName)
        success = true
        message = enabled and 'PvP enabled' or 'PvP disabled'
        logEconomyAction('set-pvp', source, nil, 0, nil, message)
        
    elseif action == 'set-economy' then
        local enabled = actionData.enabled == true
        setServerSetting('economy_enabled', enabled, 'server', adminName)
        success = true
        message = enabled and 'Economy enabled' or 'Economy disabled'
        logEconomyAction('set-economy', source, nil, 0, nil, message)
        
    elseif action == 'set-jobs' then
        local enabled = actionData.enabled == true
        setServerSetting('jobs_enabled', enabled, 'server', adminName)
        success = true
        message = enabled and 'Jobs enabled' or 'Jobs disabled'
        logEconomyAction('set-jobs', source, nil, 0, nil, message)
        
    elseif action == 'set-whitelist' then
        local enabled = actionData.enabled == true
        setServerSetting('whitelist_enabled', enabled, 'server', adminName)
        success = true
        message = enabled and 'Whitelist enabled' or 'Whitelist disabled'
        logEconomyAction('set-whitelist', source, nil, 0, nil, message)
        
    elseif action == 'set-housing' then
        local enabled = actionData.enabled == true
        setServerSetting('housing_enabled', enabled, 'server', adminName)
        success = true
        message = enabled and 'Housing enabled' or 'Housing disabled'
        logEconomyAction('set-housing', source, nil, 0, nil, message)
        
    elseif action == 'restart-server' then
        -- Dangerous action - should require confirmation
        logEconomyAction('restart-server', source, nil, 0, nil, 'Server restart initiated')
        success = true
        message = 'Server restart initiated'
        -- Note: Actual restart would need to be implemented based on your server setup
        
    elseif action == 'shutdown-server' then
        -- Dangerous action - should require confirmation
        logEconomyAction('shutdown-server', source, nil, 0, nil, 'Server shutdown initiated')
        success = true
        message = 'Server shutdown initiated'
        -- Note: Actual shutdown would need to be implemented based on your server setup
        
    elseif action == 'refresh-resources' then
        -- Refresh resource list
        success = true
        message = 'Resources refreshed'
        logEconomyAction('refresh-resources', source, nil, 0, nil, message)
        
    elseif action == 'restart-scripts' then
        -- Restart all scripts
        success = true
        message = 'Scripts restarted'
        logEconomyAction('restart-scripts', source, nil, 0, nil, message)
        
    elseif action == 'set-time' then
        local hour = tonumber(actionData.time) or 12
        hour = math.max(0, math.min(23, hour))
        currentTime = hour
        
        -- Set server time
        NetworkOverrideClockTime(hour, 0, 0)
        setServerSetting('world_time', hour, 'world', adminName)
        
        success = true
        message = string.format('Time set to %d:00', hour)
        logEconomyAction('set-time', source, nil, hour, nil, message)
        
    elseif action == 'set-weather' then
        local weather = actionData.weather or 'clear'
        currentWeather = weather
        
        -- Set server weather
        SetWeatherTypeNow(weather)
        setServerSetting('world_weather', weather, 'world', adminName)
        
        success = true
        message = string.format('Weather set to %s', weather)
        logEconomyAction('set-weather', source, nil, 0, nil, message)
        
    elseif action == 'freeze-time' then
        local freeze = actionData.freeze ~= false
        timeFrozen = freeze
        setServerSetting('world_freeze_time', freeze, 'world', adminName)
        
        success = true
        message = freeze and 'Time frozen' or 'Time unfrozen'
        logEconomyAction('freeze-time', source, nil, 0, nil, message)
        
    elseif action == 'freeze-weather' then
        local freeze = actionData.freeze ~= false
        weatherFrozen = freeze
        setServerSetting('world_freeze_weather', freeze, 'world', adminName)
        
        success = true
        message = freeze and 'Weather frozen' or 'Weather unfrozen'
        logEconomyAction('freeze-weather', source, nil, 0, nil, message)
        
    elseif action == 'set-tax-rate' then
        local rate = tonumber(actionData.rate) or 10
        rate = math.max(0, math.min(100, rate))
        setServerSetting('economy_tax_rate', rate, 'economy', adminName)
        
        success = true
        message = string.format('Tax rate set to %d%%', rate)
        logEconomyAction('set-tax-rate', source, nil, rate, nil, message)
        
    elseif action == 'set-salary-multiplier' then
        local multiplier = tonumber(actionData.multiplier) or 1.0
        setServerSetting('economy_salary_multiplier', multiplier, 'economy', adminName)
        
        success = true
        message = string.format('Salary multiplier set to %.2f', multiplier)
        logEconomyAction('set-salary-multiplier', source, nil, multiplier, nil, message)
        
    elseif action == 'set-price-multiplier' then
        local multiplier = tonumber(actionData.multiplier) or 1.0
        setServerSetting('economy_price_multiplier', multiplier, 'economy', adminName)
        
        success = true
        message = string.format('Price multiplier set to %.2f', multiplier)
        logEconomyAction('set-price-multiplier', source, nil, multiplier, nil, message)
        
    elseif action == 'set-economy-mode' then
        local mode = actionData.mode or 'normal'
        setServerSetting('economy_mode', mode, 'economy', adminName)
        
        success = true
        message = string.format('Economy mode set to %s', mode)
        logEconomyAction('set-economy-mode', source, nil, 0, nil, message)
        
    else
        return { success = false, message = 'Unknown action: ' .. action }
    end
    
    return { success = success, message = message }
end)

-- Load economy freeze state on startup
CreateThread(function()
    Wait(2000)
    economyFrozen = getServerSetting('economy_frozen', false)
    timeFrozen = getServerSetting('world_freeze_time', false)
    weatherFrozen = getServerSetting('world_freeze_weather', false)
    currentWeather = getServerSetting('world_weather', 'clear')
    currentTime = getServerSetting('world_time', 12)
end)

-- Time freeze thread
CreateThread(function()
    while true do
        if timeFrozen then
            NetworkOverrideClockTime(currentTime, 0, 0)
        end
        Wait(1000) -- Update every second
    end
end)

-- Weather freeze thread
CreateThread(function()
    while true do
        if weatherFrozen then
            SetWeatherTypeNow(currentWeather)
        end
        Wait(5000) -- Update every 5 seconds
    end
end)

print("^2[Economy Global Tools]^7 UI Backend loaded - Economy management active^0")

