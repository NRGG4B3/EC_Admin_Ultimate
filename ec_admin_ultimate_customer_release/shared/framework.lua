--[[
    EC Admin Ultimate - Framework Bridge
    Unified detection + helpers for QB-Core, QBX, ESX and standalone.
    Safe for both server and client contexts (IsDuplicityVersion checks).
]]

ECFramework = ECFramework or {}
local FrameworkState = {
    framework = nil,
    core = nil,
    detectedAt = 0
}

local function log(msg)
    print(string.format('^2[EC Framework]^7 %s^0', msg))
end

local function setFramework(name, core)
    FrameworkState.framework = name
    FrameworkState.core = core
    -- Use client-safe time function
    if GetGameTimer then
        FrameworkState.detectedAt = math.floor(GetGameTimer() / 1000) -- Convert ms to seconds
    else
        FrameworkState.detectedAt = os.time() or 0 -- Server-side fallback
    end
end

local function getTimeMs()
    if GetGameTimer then
        return GetGameTimer()
    end
    return math.floor(os.clock() * 1000)
end

local function safeConfigFramework()
    local ok, value = pcall(function()
        return Config and Config.Framework or 'auto'
    end)
    if not ok then return 'auto' end
    return value or 'auto'
end

local function detectFramework()
    if FrameworkState.framework then
        return FrameworkState.framework, FrameworkState.core
    end

    local configured = safeConfigFramework()
    local function tryQBX()
        if GetResourceState('qbx_core') == 'started' then
            local ok, core = pcall(function()
                return exports['qbx_core']:GetCoreObject()
            end)
            if ok and core then
                setFramework('qbx', core)
                log('Detected QBX framework')
                return true
            end
        end
        return false
    end

    local function tryQBCore()
        if GetResourceState('qb-core') == 'started' then
            local ok, core = pcall(function()
                return exports['qb-core']:GetCoreObject()
            end)
            if ok and core then
                setFramework('qb', core)
                log('Detected QB-Core framework')
                return true
            end
        end
        return false
    end

    local function tryESX()
        if GetResourceState('es_extended') == 'started' then
            local ok, core = pcall(function()
                return exports['es_extended']:getSharedObject()
            end)
            if ok and core then
                setFramework('esx', core)
                log('Detected ESX framework')
                return true
            end
        end
        return false
    end

    local function tryOX()
        if GetResourceState('ox_core') == 'started' then
            local ok, core = pcall(function()
                return exports['ox_core']
            end)
            if ok and core then
                setFramework('ox', core)
                log('Detected ox_core framework')
                return true
            end
        end
        return false
    end

    local function attemptDetection()
        if configured == 'qbx' or configured == 'qbox' then
            if not tryQBX() then
                log('Configured for QBX but resource not running, falling back to auto')
            end
        elseif configured == 'qbcore' or configured == 'qb' then
            if not tryQBCore() then
                log('Configured for QB-Core but resource not running, falling back to auto')
            end
        elseif configured == 'esx' then
            if not tryESX() then
                log('Configured for ESX but resource not running, falling back to auto')
            end
        elseif configured == 'ox' then
            if not tryOX() then
                log('Configured for ox_core but resource not running, falling back to auto')
            end
        end

        -- Auto mode fallback order: QBX -> QB-Core -> ESX -> ox_core
        if not FrameworkState.framework then
            if not tryQBX() then
                if not tryQBCore() then
                    if not tryESX() then
                        tryOX()
                    end
                end
            end
        end
    end

    local start = getTimeMs()
    local timeout = start + 5000
    while not FrameworkState.framework and getTimeMs() < timeout do
        attemptDetection()
        if FrameworkState.framework then break end
        Wait(500)
    end

    if not FrameworkState.framework then
        attemptDetection()
    end

    if not FrameworkState.framework then
        setFramework('standalone', nil)
        log('Running in Standalone mode')
    end

    return FrameworkState.framework, FrameworkState.core
end

function ECFramework.GetFramework()
    local fw = FrameworkState.framework
    if not fw then
        fw = detectFramework()
    end
    return fw
end

function ECFramework.GetCore()
    if not FrameworkState.core then
        detectFramework()
    end
    return FrameworkState.core
end

function ECFramework.GetIdentifiers(source)
    local identifiers = {
        steam = '',
        license = '',
        discord = '',
        fivem = '',
        ip = ''
    }

    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.find(id, 'steam:') then
            identifiers.steam = id
        elseif string.find(id, 'license:') then
            identifiers.license = id
        elseif string.find(id, 'discord:') then
            identifiers.discord = id
        elseif string.find(id, 'fivem:') then
            identifiers.fivem = id
        elseif string.find(id, 'ip:') then
            identifiers.ip = id
        end
    end

    return identifiers
end

local function getQBPlayer(core, source)
    if not core then return nil end

    if core.Player then -- Some QBX builds expose :Player(source)
        local ok, player = pcall(function()
            return core:Player(source)
        end)
        if ok and player then return player end
    end

    if core.GetPlayer then
        local ok, player = pcall(function()
            return core:GetPlayer(source)
        end)
        if ok and player then return player end
    end

    if core.Functions and core.Functions.GetPlayer then
        return core.Functions.GetPlayer(source)
    end

    if core.GetPlayerFromId then
        return core.GetPlayerFromId(source)
    end

    return nil
end

local function getOXPlayer(core, source)
    if not core then return nil end

    local ok, player = pcall(function()
        if core.GetPlayer then
            return core:GetPlayer(source)
        end

        if core.getPlayer then
            return core:getPlayer(source)
        end

        if core.GetPlayerFromId then
            return core:GetPlayerFromId(source)
        end

        if core.Player and core.Player.get then
            return core.Player:get(source)
        end

        return nil
    end)

    if ok then return player end
    return nil
end

function ECFramework.GetPlayerObject(source)
    local framework, core = detectFramework()
    if framework == 'qb' or framework == 'qbx' then
        return getQBPlayer(core, source)
    elseif framework == 'esx' and core then
        if core.GetPlayerFromId then
            return core.GetPlayerFromId(source)
        end
    elseif framework == 'ox' then
        return getOXPlayer(core, source)
    end
    return nil
end

function ECFramework.GetPlayerInfo(source)
    local ped = GetPlayerPed(source)
    local coords = vector3(0, 0, 0)
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        coords = GetEntityCoords(ped)
    end
    local info = {
        id = source,
        name = GetPlayerName(source) or ('Player ' .. tostring(source)),
        job = 'unemployed',
        gang = 'none',
        cash = 0,
        bank = 0,
        coords = { x = coords.x, y = coords.y, z = coords.z }
    }

    local framework, core = detectFramework()
    local player = ECFramework.GetPlayerObject(source)

    if (framework == 'qb' or framework == 'qbx') and player and player.PlayerData then
        local jobData = player.PlayerData.job or {}
        info.job = jobData.name or info.job
        local gangData = player.PlayerData.gang or {}
        info.gang = gangData.name or info.gang
        local money = player.PlayerData.money or {}
        info.cash = money.cash or info.cash
        info.bank = money.bank or info.bank
    elseif framework == 'esx' and player then
        local jobData = player.job or {}
        info.job = jobData.name or info.job
        local accounts = player.getAccounts and player:getAccounts() or player.accounts
        if accounts then
            for _, account in pairs(accounts) do
                if account.name == 'money' then
                    info.cash = account.money or info.cash
                elseif account.name == 'bank' then
                    info.bank = account.money or info.bank
                end
            end
        end
    elseif framework == 'ox' and player then
        local okIdentity, identity = pcall(function()
            if player.getIdentity then
                return player:getIdentity()
            end
            return player.identity
        end)

        if okIdentity and identity then
            local first = identity.firstName or identity.firstname or ''
            local last = identity.lastName or identity.lastname or ''
            local fullName = (first .. ' ' .. last):gsub('^%s*(.-)%s*$', '%1')
            if fullName ~= '' then
                info.name = fullName
            end
        end

        local okGroups, groups = pcall(function()
            if player.getGroups then
                return player:getGroups()
            end
            return player.groups
        end)

        if okGroups and groups then
            for group, _ in pairs(groups) do
                info.job = group
                break
            end
        end

        local okCash, cashAccount, bankAccount = pcall(function()
            if player.getAccount then
                return player:getAccount('cash'), player:getAccount('bank')
            end
            if player.get then
                return player:get('cash'), player:get('bank')
            end
            return nil, nil
        end)

        if okCash then
            if type(cashAccount) == 'table' then
                info.cash = cashAccount.money or cashAccount.balance or info.cash
            elseif type(cashAccount) == 'number' then
                info.cash = cashAccount
            end

            if type(bankAccount) == 'table' then
                info.bank = bankAccount.money or bankAccount.balance or info.bank
            elseif type(bankAccount) == 'number' then
                info.bank = bankAccount
            end
        end
    end

    return info
end

function ECFramework.IsAdminGroup(source)
    local framework, _ = detectFramework()
    local player = ECFramework.GetPlayerObject(source)
    if not player then return false end

    if framework == 'qb' or framework == 'qbx' then
        local job = player.PlayerData and player.PlayerData.job or {}
        local gradeName = job.grade and (job.grade.name or job.grade.level) or ''
        if job.name == 'admin' or job.name == 'god' or gradeName == 'boss' or gradeName == 'admin' then
            return true
        end
    elseif framework == 'esx' then
        if player.getGroup and type(player.getGroup) == 'function' then
            local group = player:getGroup()
            if group == 'admin' or group == 'superadmin' or group == 'god' or group == 'owner' then
                return true
            end
        end
    end

    return false
end

function ECFramework.AddMoney(source, account, amount)
    local framework = ECFramework.GetFramework()
    local player = ECFramework.GetPlayerObject(source)
    if not player then return false end

    if (framework == 'qb' or framework == 'qbx') and player.Functions and player.Functions.AddMoney then
        player.Functions.AddMoney(account, amount)
        return true
    elseif framework == 'esx' then
        local accountName = account == 'cash' and 'money' or account
        if player.addAccountMoney then
            player.addAccountMoney(accountName, amount)
            return true
        end
    elseif framework == 'ox' then
        local ok = pcall(function()
            if player.addMoney then
                player:addMoney(account, amount)
            elseif player.addAccountMoney then
                player:addAccountMoney(account, amount)
            elseif player.add then
                player:add(account, amount)
            end
        end)
        if ok then return true end
    end

    return false
end

function ECFramework.SetJob(source, job, grade)
    local framework = ECFramework.GetFramework()
    local player = ECFramework.GetPlayerObject(source)
    if not player then return false end

    if (framework == 'qb' or framework == 'qbx') and player.Functions and player.Functions.SetJob then
        player.Functions.SetJob(job, grade)
        return true
    elseif framework == 'esx' and player.setJob then
        player.setJob(job, grade)
        return true
    elseif framework == 'ox' then
        local ok = pcall(function()
            if player.setGroup then
                player:setGroup(job, grade)
            elseif player.setJob then
                player:setJob(job, grade)
            end
        end)
        if ok then return true end
    end

    return false
end

function ECFramework.AddItem(source, item, amount, metadata)
    local framework = ECFramework.GetFramework()
    local player = ECFramework.GetPlayerObject(source)
    if not player then return false end

    if (framework == 'qb' or framework == 'qbx') and player.Functions and player.Functions.AddItem then
        player.Functions.AddItem(item, amount, false, metadata)
        return true
    elseif framework == 'esx' and player.addInventoryItem then
        player.addInventoryItem(item, amount, false, metadata)
        return true
    elseif framework == 'ox' then
        local ok = pcall(function()
            if player.addInventoryItem then
                player:addInventoryItem(item, amount, false, metadata)
            elseif GetResourceState('ox_inventory') == 'started' then
                exports.ox_inventory:AddItem(source, item, amount, metadata)
            end
        end)
        if ok then return true end
    end

    return false
end

function ECFramework.RemoveItem(source, item, amount)
    local framework = ECFramework.GetFramework()
    local player = ECFramework.GetPlayerObject(source)
    if not player then return false end

    if (framework == 'qb' or framework == 'qbx') and player.Functions and player.Functions.RemoveItem then
        player.Functions.RemoveItem(item, amount)
        return true
    elseif framework == 'esx' and player.removeInventoryItem then
        player.removeInventoryItem(item, amount)
        return true
    elseif framework == 'ox' then
        local ok = pcall(function()
            if player.removeInventoryItem then
                player:removeInventoryItem(item, amount)
            elseif GetResourceState('ox_inventory') == 'started' then
                exports.ox_inventory:RemoveItem(source, item, amount)
            end
        end)
        if ok then return true end
    end

    return false
end

function ECFramework.GiveWeapon(source, weapon, ammo)
    local framework = ECFramework.GetFramework()
    local player = ECFramework.GetPlayerObject(source)
    if not player then return false end

    if (framework == 'qb' or framework == 'qbx') and player.Functions and player.Functions.AddItem then
        player.Functions.AddItem(weapon, 1, false, { ammo = ammo or 0 })
        return true
    elseif framework == 'esx' and player.addWeapon then
        player.addWeapon(weapon, ammo or 0)
        return true
    elseif framework == 'ox' then
        local ok = pcall(function()
            if player.addInventoryItem then
                player:addInventoryItem(weapon, 1, false, { ammo = ammo or 0 })
            elseif GetResourceState('ox_inventory') == 'started' then
                exports.ox_inventory:AddItem(source, weapon, 1, { ammo = ammo or 0 })
            end
        end)
        if ok then return true end
    end

    return false
end

function ECFramework.RemoveWeapon(source, weapon)
    local framework = ECFramework.GetFramework()
    local player = ECFramework.GetPlayerObject(source)
    if not player then return false end

    if (framework == 'qb' or framework == 'qbx') and player.Functions and player.Functions.RemoveItem then
        player.Functions.RemoveItem(weapon, 1)
        return true
    elseif framework == 'esx' and player.removeWeapon then
        player.removeWeapon(weapon)
        return true
    elseif framework == 'ox' then
        local ok = pcall(function()
            if player.removeInventoryItem then
                player:removeInventoryItem(weapon, 1)
            elseif GetResourceState('ox_inventory') == 'started' then
                exports.ox_inventory:RemoveItem(source, weapon, 1)
            end
        end)
        if ok then return true end
    end

    return false
end

function ECFramework.Notify(source, message, notifType)
    if not source then return end
    local ok = pcall(function()
        TriggerClientEvent('ec_admin:notification', source, message, notifType or 'info')
    end)

    if ok then return end

    local framework, core = detectFramework()
    local notifyType = notifType or 'info'

    if (framework == 'qb' or framework == 'qbx') and core then
        if core.Functions and core.Functions.Notify then
            local safe = pcall(core.Functions.Notify, source, message, notifyType)
            if safe then return end
        end

        if core.Notify then
            local safe = pcall(core.Notify, source, message, notifyType)
            if safe then return end
        end
    elseif framework == 'esx' and core then
        if core.ShowNotification then
            local safe = pcall(core.ShowNotification, source, message, notifyType)
            if safe then return end
        end
        TriggerClientEvent('esx:showNotification', source, message)
    elseif framework == 'ox' and core then
        local safe = pcall(function()
            if core.Notify then
                core:Notify(source, message, notifyType)
                return true
            end
            if core.notify then
                core:notify(source, message, notifyType)
                return true
            end
            if core.client and core.client.notify then
                core.client.notify(source, { description = message, type = notifyType })
            end
        end)
        if safe then return end
    end
end

-- Simple export helpers for other resources
if IsDuplicityVersion() then
    exports('GetFramework', ECFramework.GetFramework)
    exports('GetCore', ECFramework.GetCore)
    exports('GetPlayerObject', ECFramework.GetPlayerObject)
end

return ECFramework
