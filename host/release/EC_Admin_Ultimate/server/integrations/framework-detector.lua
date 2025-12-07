--[[
    EC Admin Ultimate - Framework Detector
    Auto-detects and provides unified API for all frameworks
    
    Supported:
    - QBCore (qb-core)
    - QBX (qbx_core / qbx-core)
    - ESX (es_extended / esx_legacy)
    - Standalone
]]

Framework = {
    Type = nil,
    Resource = nil,
    Core = nil,
    Ready = false
}

-- Detection functions
local function DetectQBCore()
    local resources = {'qb-core', 'qbx_core', 'qbx-core'}
    
    for _, res in ipairs(resources) do
        if GetResourceState(res) == 'started' then
            local success, core = pcall(function()
                return exports[res]:GetCoreObject()
            end)
            
            if success and core then
                Framework.Type = res:match('qbx') and 'qbx' or 'qbcore'
                Framework.Resource = res
                Framework.Core = core
                Framework.Ready = true
                return true
            end
        end
    end
    
    return false
end

local function DetectESX()
    local resources = {'es_extended', 'esx_legacy'}
    
    for _, res in ipairs(resources) do
        if GetResourceState(res) == 'started' then
            local success, core = pcall(function()
                return exports[res]:getSharedObject()
            end)
            
            if success and core then
                Framework.Type = 'esx'
                Framework.Resource = res
                Framework.Core = core
                Framework.Ready = true
                return true
            end
        end
    end
    
    return false
end

-- Initialize framework detection
CreateThread(function()
    Wait(1000) -- Wait for resources to start
    
    Logger.Info('Detecting framework...')
    
    if DetectQBCore() then
        Logger.Info('✅ Framework detected: ' .. Framework.Type .. ' (' .. Framework.Resource .. ')')
    elseif DetectESX() then
        Logger.Info('✅ Framework detected: ' .. Framework.Type .. ' (' .. Framework.Resource .. ')')
    else
        Framework.Type = 'standalone'
        Framework.Ready = true
        Logger.Info('ℹ️  No framework detected, running in standalone mode')
    end
    
    _G.ECFramework = Framework
end)

-- =====================================================
--  UNIFIED FRAMEWORK API
-- =====================================================

-- Get player data (works across all frameworks)
function Framework:GetPlayer(source)
    if not self.Ready then return nil end
    
    if self.Type == 'qbcore' or self.Type == 'qbx' then
        return self.Core.Functions.GetPlayer(source)
    elseif self.Type == 'esx' then
        return self.Core.GetPlayerFromId(source)
    else
        -- Standalone - return basic data
        return {
            PlayerData = {
                source = source,
                identifier = GetPlayerIdentifierByType(source, 'license'),
                name = GetPlayerName(source)
            }
        }
    end
end

-- Get player identifier
function Framework:GetIdentifier(source)
    if not self.Ready then return nil end
    
    local player = self:GetPlayer(source)
    if not player then return nil end
    
    if self.Type == 'qbcore' or self.Type == 'qbx' then
        return player.PlayerData.citizenid or player.PlayerData.license
    elseif self.Type == 'esx' then
        return player.identifier
    else
        return GetPlayerIdentifierByType(source, 'license')
    end
end

-- Get player money
function Framework:GetMoney(source, moneyType)
    if not self.Ready then return 0 end
    
    moneyType = moneyType or 'cash'
    local player = self:GetPlayer(source)
    if not player then return 0 end
    
    if self.Type == 'qbcore' or self.Type == 'qbx' then
        return player.PlayerData.money[moneyType] or 0
    elseif self.Type == 'esx' then
        local accountType = moneyType == 'cash' and 'money' or moneyType
        return player.getAccount(accountType).money or 0
    else
        return 0
    end
end

-- Add money
function Framework:AddMoney(source, moneyType, amount)
    if not self.Ready then return false end
    
    local player = self:GetPlayer(source)
    if not player then return false end
    
    if self.Type == 'qbcore' or self.Type == 'qbx' then
        player.Functions.AddMoney(moneyType, amount)
        return true
    elseif self.Type == 'esx' then
        local accountType = moneyType == 'cash' and 'money' or moneyType
        player.addAccountMoney(accountType, amount)
        return true
    else
        return false
    end
end

-- Remove money
function Framework:RemoveMoney(source, moneyType, amount)
    if not self.Ready then return false end
    
    local player = self:GetPlayer(source)
    if not player then return false end
    
    if self.Type == 'qbcore' or self.Type == 'qbx' then
        player.Functions.RemoveMoney(moneyType, amount)
        return true
    elseif self.Type == 'esx' then
        local accountType = moneyType == 'cash' and 'money' or moneyType
        player.removeAccountMoney(accountType, amount)
        return true
    else
        return false
    end
end

-- Get player job
function Framework:GetJob(source)
    if not self.Ready then return nil end
    
    local player = self:GetPlayer(source)
    if not player then return nil end
    
    if self.Type == 'qbcore' or self.Type == 'qbx' then
        return {
            name = player.PlayerData.job.name,
            label = player.PlayerData.job.label,
            grade = player.PlayerData.job.grade.level,
            gradeLabel = player.PlayerData.job.grade.name,
            onDuty = player.PlayerData.job.onduty,
            payment = player.PlayerData.job.payment
        }
    elseif self.Type == 'esx' then
        return {
            name = player.job.name,
            label = player.job.label,
            grade = player.job.grade,
            gradeLabel = player.job.grade_label,
            onDuty = true,
            payment = player.job.grade_salary
        }
    else
        return {
            name = 'unemployed',
            label = 'Unemployed',
            grade = 0,
            gradeLabel = 'None',
            onDuty = false,
            payment = 0
        }
    end
end

-- Set player job
function Framework:SetJob(source, jobName, grade)
    if not self.Ready then return false end
    
    local player = self:GetPlayer(source)
    if not player then return false end
    
    grade = grade or 0
    
    if self.Type == 'qbcore' or self.Type == 'qbx' then
        player.Functions.SetJob(jobName, grade)
        return true
    elseif self.Type == 'esx' then
        player.setJob(jobName, grade)
        return true
    else
        return false
    end
end

-- Get player gang (QB only)
function Framework:GetGang(source)
    if not self.Ready then return nil end
    if self.Type ~= 'qbcore' and self.Type ~= 'qbx' then return nil end
    
    local player = self:GetPlayer(source)
    if not player then return nil end
    
    return {
        name = player.PlayerData.gang.name,
        label = player.PlayerData.gang.label,
        grade = player.PlayerData.gang.grade.level,
        gradeLabel = player.PlayerData.gang.grade.name
    }
end

-- Set player gang (QB only)
function Framework:SetGang(source, gangName, grade)
    if not self.Ready then return false end
    if self.Type ~= 'qbcore' and self.Type ~= 'qbx' then return false end
    
    local player = self:GetPlayer(source)
    if not player then return false end
    
    grade = grade or 0
    player.Functions.SetGang(gangName, grade)
    return true
end

-- Get all online players
function Framework:GetPlayers()
    if not self.Ready then return {} end
    
    if self.Type == 'qbcore' or self.Type == 'qbx' then
        return self.Core.Functions.GetQBPlayers()
    elseif self.Type == 'esx' then
        return self.Core.GetExtendedPlayers()
    else
        local players = {}
        for _, playerId in ipairs(GetPlayers()) do
            players[tonumber(playerId)] = {
                PlayerData = {
                    source = playerId,
                    identifier = GetPlayerIdentifierByType(playerId, 'license'),
                    name = GetPlayerName(playerId)
                }
            }
        end
        return players
    end
end

-- Get player inventory
function Framework:GetInventory(source)
    if not self.Ready then return {} end
    
    local player = self:GetPlayer(source)
    if not player then return {} end
    
    if self.Type == 'qbcore' or self.Type == 'qbx' then
        return player.PlayerData.items or {}
    elseif self.Type == 'esx' then
        return player.inventory or {}
    else
        return {}
    end
end

-- Add item
function Framework:AddItem(source, item, amount, metadata)
    if not self.Ready then return false end
    
    local player = self:GetPlayer(source)
    if not player then return false end
    
    amount = amount or 1
    metadata = metadata or {}
    
    if self.Type == 'qbcore' or self.Type == 'qbx' then
        return player.Functions.AddItem(item, amount, nil, metadata)
    elseif self.Type == 'esx' then
        player.addInventoryItem(item, amount)
        return true
    else
        return false
    end
end

-- Remove item
function Framework:RemoveItem(source, item, amount)
    if not self.Ready then return false end
    
    local player = self:GetPlayer(source)
    if not player then return false end
    
    amount = amount or 1
    
    if self.Type == 'qbcore' or self.Type == 'qbx' then
        return player.Functions.RemoveItem(item, amount)
    elseif self.Type == 'esx' then
        player.removeInventoryItem(item, amount)
        return true
    else
        return false
    end
end

-- Exports
exports('GetFramework', function()
    return Framework
end)

exports('GetFrameworkType', function()
    return Framework.Type
end)

exports('IsFrameworkReady', function()
    return Framework.Ready
end)

Logger.Info('Framework detector loaded')
