-- EC Admin Ultimate - Jobs & Gangs Management System (PRODUCTION STABLE)
-- Version: 1.0.0 - Complete job and gang management with framework integration

Logger.Info('💼 Loading jobs & gangs management system...')

local JobsGangs = {}

-- Framework detection
local Framework = nil
local FrameworkObject = nil

-- Jobs & Gangs cache
local jobsData = {
    jobs = {},
    employees = {},
    gangs = {},
    gangMembers = {},
    lastUpdate = 0
}

-- Configuration
local config = {
    updateInterval = 60000,     -- 1 minute
    cacheEnabled = true
}

-- Safe framework detection
local function DetectFramework()
    -- Detect QBCore
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('💼 QBCore (qbx_core) detected')
        
        local success, coreObj = pcall(function()
            return exports['qbx_core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('💼 QBCore framework successfully connected')
            return true
        end
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'QBCore'
        Logger.Info('💼 QBCore (qb-core) detected')
        
        local success, coreObj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        
        if success and coreObj then
            FrameworkObject = coreObj
            Logger.Info('💼 QBCore framework successfully connected')
            return true
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
            Logger.Info('💼 ESX framework detected')
            return true
        end
    end
    
    Logger.Info('⚠️ No supported framework detected for jobs & gangs')
    return false
end

-- Get all jobs from framework
function JobsGangs.GetAllJobs()
    if not Framework or not FrameworkObject then
        return {}
    end
    
    local jobs = {}
    
    if Framework == 'QBCore' then
        -- Get jobs from QB-Core shared data
        local QBJobs = FrameworkObject.Shared.Jobs
        
        for jobName, jobData in pairs(QBJobs) do
            local employeeCount = 0
            local onlineCount = 0
            local societyMoney = 0
            
            -- Count employees
            for _, player in pairs(GetPlayers()) do
                local Player = FrameworkObject.Functions.GetPlayer(tonumber(player))
                if Player and Player.PlayerData.job.name == jobName then
                    employeeCount = employeeCount + 1
                    onlineCount = onlineCount + 1
                end
            end
            
            -- Get society money if management resource exists
            if GetResourceState('qb-management') == 'started' then
                local success, result = pcall(function()
                    return exports['qb-management']:GetAccount(jobName)
                end)
                if success and result then
                    societyMoney = result or 0
                end
            end
            
            table.insert(jobs, {
                name = jobName,
                label = jobData.label or jobName,
                totalEmployees = employeeCount,
                onlineEmployees = onlineCount,
                whitelisted = jobData.type == 'leo' or jobData.type == 'ems',
                societyMoney = societyMoney,
                type = jobData.type or 'citizen',
                grades = jobData.grades or {}
            })
        end
        
    elseif Framework == 'ESX' then
        -- Get jobs from ESX
        local ESXJobs = FrameworkObject.GetJobs()
        
        for jobName, jobData in pairs(ESXJobs) do
            local employeeCount = 0
            local onlineCount = 0
            local societyMoney = 0
            
            -- Count employees
            for _, player in pairs(GetPlayers()) do
                local xPlayer = FrameworkObject.GetPlayerFromId(tonumber(player))
                if xPlayer and xPlayer.job.name == jobName then
                    employeeCount = employeeCount + 1
                    onlineCount = onlineCount + 1
                end
            end
            
            -- Get society money
            if GetResourceState('esx_society') == 'started' then
                local success, result = pcall(function()
                    return exports['esx_society']:GetSocietyMoney(jobName)
                end)
                if success and result then
                    societyMoney = result or 0
                end
            end
            
            table.insert(jobs, {
                name = jobName,
                label = jobData.label or jobName,
                totalEmployees = employeeCount,
                onlineEmployees = onlineCount,
                whitelisted = jobData.whitelisted or false,
                societyMoney = societyMoney,
                type = jobData.type or 'public',
                grades = jobData.grades or {}
            })
        end
    end
    
    return jobs
end

-- Get all employees for a specific job
function JobsGangs.GetJobEmployees(jobName)
    if not Framework or not FrameworkObject then
        return {}
    end
    
    local employees = {}
    
    if Framework == 'QBCore' then
        -- Query database for all players with this job
        local result = MySQL.query.await('SELECT * FROM players WHERE JSON_EXTRACT(job, "$.name") = ?', {jobName})
        
        if result then
            for _, row in ipairs(result) do
                local jobData = json.decode(row.job or '{}')
                local charinfo = json.decode(row.charinfo or '{}')
                
                -- Check if player is online
                local isOnline = false
                for _, playerId in pairs(GetPlayers()) do
                    local identifier = GetPlayerIdentifier(tonumber(playerId), 0)
                    if identifier == row.license then
                        isOnline = true
                        break
                    end
                end
                
                table.insert(employees, {
                    identifier = row.license,
                    citizenid = row.citizenid,
                    name = charinfo.firstname .. ' ' .. charinfo.lastname,
                    job = jobData.name or jobName,
                    grade = jobData.label or 'Unknown',
                    gradeLevel = jobData.grade or 0,
                    salary = jobData.payment or 0,
                    hired = row.created_at or 'Unknown',
                    online = isOnline
                })
            end
        end
        
    elseif Framework == 'ESX' then
        -- Query database for ESX
        local result = MySQL.query.await('SELECT * FROM users WHERE job = ?', {jobName})
        
        if result then
            for _, row in ipairs(result) do
                -- Check if player is online
                local isOnline = false
                for _, playerId in pairs(GetPlayers()) do
                    local identifier = GetPlayerIdentifier(tonumber(playerId), 0)
                    if identifier == row.identifier then
                        isOnline = true
                        break
                    end
                end
                
                table.insert(employees, {
                    identifier = row.identifier,
                    name = row.firstname .. ' ' .. row.lastname,
                    job = row.job,
                    grade = row.job_grade or 0,
                    gradeLevel = row.job_grade or 0,
                    salary = 0, -- ESX stores this differently
                    hired = 'Unknown',
                    online = isOnline
                })
            end
        end
    end
    
    return employees
end

-- Get all gangs
function JobsGangs.GetAllGangs()
    if not Framework or not FrameworkObject then
        return {}
    end
    
    local gangs = {}
    
    if Framework == 'QBCore' then
        -- Get gangs from QB-Core shared data
        local QBGangs = FrameworkObject.Shared.Gangs
        
        if QBGangs then
            for gangName, gangData in pairs(QBGangs) do
                local memberCount = 0
                local onlineCount = 0
                local leader = 'Unknown'
                
                -- Count members
                for _, player in pairs(GetPlayers()) do
                    local Player = FrameworkObject.Functions.GetPlayer(tonumber(player))
                    if Player and Player.PlayerData.gang and Player.PlayerData.gang.name == gangName then
                        memberCount = memberCount + 1
                        onlineCount = onlineCount + 1
                        
                        -- Check if leader (grade 4 usually)
                        if Player.PlayerData.gang.grade and Player.PlayerData.gang.grade.level == 4 then
                            local charinfo = Player.PlayerData.charinfo
                            leader = charinfo.firstname .. ' ' .. charinfo.lastname
                        end
                    end
                end
                
                table.insert(gangs, {
                    name = gangName,
                    label = gangData.label or gangName,
                    totalMembers = memberCount,
                    onlineMembers = onlineCount,
                    leader = leader,
                    territory = 'Unknown', -- Would need additional data
                    reputation = 0, -- Would need additional data
                    color = gangData.color or 'White',
                    grades = gangData.grades or {}
                })
            end
        end
    end
    
    return gangs
end

-- Get gang members
function JobsGangs.GetGangMembers(gangName)
    if not Framework or not FrameworkObject then
        return {}
    end
    
    local members = {}
    
    if Framework == 'QBCore' then
        -- Query database for gang members
        local result = MySQL.query.await('SELECT * FROM players WHERE JSON_EXTRACT(gang, "$.name") = ?', {gangName})
        
        if result then
            for _, row in ipairs(result) do
                local gangData = json.decode(row.gang or '{}')
                local charinfo = json.decode(row.charinfo or '{}')
                
                -- Check if player is online
                local isOnline = false
                for _, playerId in pairs(GetPlayers()) do
                    local identifier = GetPlayerIdentifier(tonumber(playerId), 0)
                    if identifier == row.license then
                        isOnline = true
                        break
                    end
                end
                
                table.insert(members, {
                    identifier = row.license,
                    citizenid = row.citizenid,
                    name = charinfo.firstname .. ' ' .. charinfo.lastname,
                    gang = gangData.name or gangName,
                    rank = gangData.label or 'Member',
                    rankLevel = gangData.grade or 0,
                    joined = row.created_at or 'Unknown',
                    online = isOnline
                })
            end
        end
    end
    
    return members
end

-- Set player job
function JobsGangs.SetPlayerJob(adminSource, targetSource, jobName, gradeLevel, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'setJob') then
        return false, 'Insufficient permissions'
    end
    
    if not Framework or not FrameworkObject then
        return false, 'No supported framework detected'
    end
    
    local success = pcall(function()
        if Framework == 'QBCore' then
            local Player = FrameworkObject.Functions.GetPlayer(targetSource)
            if Player then
                Player.Functions.SetJob(jobName, gradeLevel)
            end
        elseif Framework == 'ESX' then
            local xPlayer = FrameworkObject.GetPlayerFromId(targetSource)
            if xPlayer then
                xPlayer.setJob(jobName, gradeLevel)
            end
        end
    end)
    
    if success then
        Logger.Info(string.format('', 
              GetPlayerName(targetSource), jobName, gradeLevel))
        return true, 'Job set successfully'
    else
        return false, 'Failed to set job'
    end
end

-- Set player gang (QB-Core only)
function JobsGangs.SetPlayerGang(adminSource, targetSource, gangName, gradeLevel, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'setGang') then
        return false, 'Insufficient permissions'
    end
    
    if Framework ~= 'QBCore' or not FrameworkObject then
        return false, 'Gangs only supported on QB-Core'
    end
    
    local success = pcall(function()
        local Player = FrameworkObject.Functions.GetPlayer(targetSource)
        if Player then
            Player.Functions.SetGang(gangName, gradeLevel)
        end
    end)
    
    if success then
        Logger.Info(string.format('', 
              GetPlayerName(targetSource), gangName, gradeLevel))
        return true, 'Gang set successfully'
    else
        return false, 'Failed to set gang'
    end
end

-- Fire player from job
function JobsGangs.FirePlayer(adminSource, targetSource, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'firePlayer') then
        return false, 'Insufficient permissions'
    end
    
    return JobsGangs.SetPlayerJob(adminSource, targetSource, 'unemployed', 0, reason)
end

-- Add/Remove society money
function JobsGangs.ModifySocietyMoney(adminSource, jobName, amount, add, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'modifySocietyMoney') then
        return false, 'Insufficient permissions'
    end
    
    if Framework == 'QBCore' and GetResourceState('qb-management') == 'started' then
        local success = pcall(function()
            if add then
                exports['qb-management']:AddMoney(jobName, amount)
            else
                exports['qb-management']:RemoveMoney(jobName, amount)
            end
        end)
        
        if success then
            Logger.Info(string.format('', 
                  add and 'added' or 'removed', jobName, amount, reason))
            return true, string.format('$%d %s society account', amount, add and 'added to' or 'removed from')
        end
    elseif Framework == 'ESX' and GetResourceState('esx_society') == 'started' then
        local success = pcall(function()
            if add then
                exports['esx_society']:AddMoney(jobName, amount)
            else
                exports['esx_society']:RemoveMoney(jobName, amount)
            end
        end)
        
        if success then
            return true, string.format('$%d %s society account', amount, add and 'added to' or 'removed from')
        end
    end
    
    return false, 'Failed to modify society money'
end

-- Add/Remove gang money (QB-Core only)
function JobsGangs.ModifyGangMoney(adminSource, gangName, amount, add, reason)
    if not _G.ECPermissions or not _G.ECPermissions.HasPermission(adminSource, 'modifyGangMoney') then
        return false, 'Insufficient permissions'
    end
    
    if Framework ~= 'QBCore' then
        return false, 'Gang money management only supported on QB-Core'
    end
    
    -- Check for qb-management or qb-banking
    if GetResourceState('qb-management') == 'started' then
        local success = pcall(function()
            if add then
                exports['qb-management']:AddGangMoney(gangName, amount)
            else
                exports['qb-management']:RemoveGangMoney(gangName, amount)
            end
        end)
        
        if success then
            Logger.Info(string.format('', 
                  add and 'added' or 'removed', gangName, amount, reason))
            return true, string.format('$%d %s gang account', amount, add and 'added to' or 'removed from')
        end
    end
    
    -- Alternative: Direct database modification if management resource not available
    -- Some QB servers store gang money in a gangs table
    local success, err = pcall(function()
        if MySQL and MySQL.Sync then
            local query = add and 
                'UPDATE gangs SET money = money + ? WHERE name = ?' or
                'UPDATE gangs SET money = money - ? WHERE name = ?'
            MySQL.Sync.execute(query, {amount, gangName})
        elseif MySQL and MySQL.query then
            local query = add and 
                'UPDATE gangs SET money = money + ? WHERE name = ?' or
                'UPDATE gangs SET money = money - ? WHERE name = ?'
            MySQL.query.await(query, {amount, gangName})
        end
    end)
    
    if success then
        Logger.Info(string.format('', 
              add and 'added' or 'removed', gangName, amount, reason))
        return true, string.format('$%d %s gang account', amount, add and 'added to' or 'removed from')
    end
    
    return false, 'Failed to modify gang money'
end

-- Get comprehensive jobs & gangs data
function JobsGangs.GetAllData()
    local data = {
        jobs = JobsGangs.GetAllJobs(),
        gangs = JobsGangs.GetAllGangs(),
        framework = Framework,
        stats = {
            totalJobs = 0,
            totalEmployees = 0,
            totalGangs = 0,
            totalGangMembers = 0,
            onlineEmployees = 0,
            onlineGangMembers = 0
        }
    }
    
    -- Calculate stats
    for _, job in ipairs(data.jobs) do
        data.stats.totalJobs = data.stats.totalJobs + 1
        data.stats.totalEmployees = data.stats.totalEmployees + job.totalEmployees
        data.stats.onlineEmployees = data.stats.onlineEmployees + job.onlineEmployees
    end
    
    for _, gang in ipairs(data.gangs) do
        data.stats.totalGangs = data.stats.totalGangs + 1
        data.stats.totalGangMembers = data.stats.totalGangMembers + gang.totalMembers
        data.stats.onlineGangMembers = data.stats.onlineGangMembers + gang.onlineMembers
    end
    
    return data
end

-- Initialize
function JobsGangs.Initialize()
    Logger.Info('💼 Initializing jobs & gangs system...')
    
    local frameworkDetected = DetectFramework()
    if not frameworkDetected then
        Logger.Info('⚠️ Jobs & Gangs system disabled - no supported framework')
        return false
    end
    
    -- Update cache periodically
    CreateThread(function()
        while true do
            Wait(config.updateInterval)
            
            jobsData.jobs = JobsGangs.GetAllJobs()
            jobsData.gangs = JobsGangs.GetAllGangs()
            jobsData.lastUpdate = os.time()
        end
    end)
    
    Logger.Info('✅ Jobs & Gangs system initialized with ' .. Framework .. ' framework')
    return true
end

-- Server events
RegisterNetEvent('ec-admin:getJobsGangsData')
AddEventHandler('ec-admin:getJobsGangsData', function()
    local source = source
    local data = JobsGangs.GetAllData()
    TriggerClientEvent('ec-admin:receiveJobsGangsData', source, data)
end)

RegisterNetEvent('ec-admin:getJobEmployees')
AddEventHandler('ec-admin:getJobEmployees', function(jobName)
    local source = source
    local employees = JobsGangs.GetJobEmployees(jobName)
    TriggerClientEvent('ec-admin:receiveJobEmployees', source, employees)
end)

RegisterNetEvent('ec-admin:getGangMembers')
AddEventHandler('ec-admin:getGangMembers', function(gangName)
    local source = source
    local members = JobsGangs.GetGangMembers(gangName)
    TriggerClientEvent('ec-admin:receiveGangMembers', source, members)
end)

-- Admin action events
RegisterNetEvent('ec-admin:jobs:setJob')
AddEventHandler('ec-admin:jobs:setJob', function(data, cb)
    local source = source
    local success, message = JobsGangs.SetPlayerJob(source, data.targetSource, data.jobName, data.gradeLevel or 0, data.reason or 'Admin action')
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:jobs:setGang')
AddEventHandler('ec-admin:jobs:setGang', function(data, cb)
    local source = source
    local success, message = JobsGangs.SetPlayerGang(source, data.targetSource, data.gangName, data.rankLevel or 0, data.reason or 'Admin action')
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:jobs:firePlayer')
AddEventHandler('ec-admin:jobs:firePlayer', function(data, cb)
    local source = source
    local success, message = JobsGangs.FirePlayer(source, data.targetSource, data.reason or 'Fired by admin')
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:jobs:modifySocietyMoney')
AddEventHandler('ec-admin:jobs:modifySocietyMoney', function(data, cb)
    local source = source
    local success, message = JobsGangs.ModifySocietyMoney(source, data.jobName, data.amount, data.add, data.reason or 'Admin modification')
    
    if cb then
        cb({ success = success, message = message })
    end
end)

RegisterNetEvent('ec-admin:jobs:modifyGangMoney')
AddEventHandler('ec-admin:jobs:modifyGangMoney', function(data, cb)
    local source = source
    local success, message = JobsGangs.ModifyGangMoney(source, data.gangName, data.amount, data.add, data.reason or 'Admin modification')
    
    if cb then
        cb({ success = success, message = message })
    end
end)

-- Exports
exports('GetAllJobs', function()
    return JobsGangs.GetAllJobs()
end)

exports('GetAllGangs', function()
    return JobsGangs.GetAllGangs()
end)

exports('SetPlayerJob', function(adminSource, targetSource, jobName, gradeLevel, reason)
    return JobsGangs.SetPlayerJob(adminSource, targetSource, jobName, gradeLevel, reason)
end)

exports('SetPlayerGang', function(adminSource, targetSource, gangName, gradeLevel, reason)
    return JobsGangs.SetPlayerGang(adminSource, targetSource, gangName, gradeLevel, reason)
end)

-- Initialize
JobsGangs.Initialize()

-- Make available globally
_G.ECJobsGangs = JobsGangs

Logger.Info('✅ Jobs & Gangs system loaded successfully')
