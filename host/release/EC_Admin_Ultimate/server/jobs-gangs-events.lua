--[[
    EC Admin Ultimate - Jobs & Gangs Server Events
    Server-side implementation for job and gang management
]]

Logger.Info('')

local function HasPermission(src, permission)
    return IsPlayerAceAllowed(src, 'ec_admin.' .. permission) or
           IsPlayerAceAllowed(src, 'ec_admin.all')
end

local function GetFramework()
    if GetResourceState('qbx_core') == 'started' then
        return 'qbx', exports.qbx_core
    elseif GetResourceState('qb-core') == 'started' then
        return 'qb', exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx', exports['es_extended']:getSharedObject()
    end
    return 'standalone', nil
end

local function GetJobsForFramework(fwType, fw)
    if fwType == 'qbx' then
        local success, jobs = pcall(function()
            return fw:GetJobs()
        end)
        if success and jobs then return jobs end
    elseif fwType == 'qb' then
        return fw.Shared and fw.Shared.Jobs or {}
    elseif fwType == 'esx' then
        return fw.GetJobs and fw:GetJobs() or {}
    end

    return {}
end

local function GetGangsForFramework(fwType, fw)
    if fwType == 'qbx' then
        local success, gangs = pcall(function()
            return fw:GetGangs()
        end)
        if success and gangs then return gangs end
    elseif fwType == 'qb' then
        return fw.Shared and fw.Shared.Gangs or {}
    end

    return {}
end

local function NormalizeGrade(grades, requestedGrade)
    if type(grades) ~= 'table' then return 0 end

    local numericGrade = tonumber(requestedGrade)
    if numericGrade and (grades[numericGrade] or grades[tostring(numericGrade)]) then
        return numericGrade
    end

    if type(requestedGrade) == 'string' then
        local target = requestedGrade:lower()
        for key, gradeData in pairs(grades) do
            if type(gradeData) == 'table' then
                local gradeName = gradeData.name or gradeData.label or gradeData.rank
                if gradeName and gradeName:lower() == target then
                    return tonumber(key) or gradeData.grade or gradeData.level or 0
                end
            end
        end
    end

    local lowest = nil
    for key in pairs(grades) do
        local num = tonumber(key) or (type(key) == 'number' and key) or nil
        if num and (lowest == nil or num < lowest) then
            lowest = num
        end
    end

    return lowest or 0
end

local function ValidateJobAndGrade(fwType, fw, jobName, requestedGrade)
    local jobs = GetJobsForFramework(fwType, fw)
    local jobData = jobs and jobs[jobName]

    if not jobData then
        return false, string.format('Job %s does not exist', tostring(jobName))
    end

    local gradeTable = jobData.grades or jobData.Grades or {}
    local grade = NormalizeGrade(gradeTable, requestedGrade)

    if not gradeTable[grade] and not gradeTable[tostring(grade)] then
        return false, string.format('Grade %s is not valid for job %s', tostring(requestedGrade), tostring(jobName))
    end

    return true, grade
end

RegisterNetEvent('ec:jobs:getAll', function(data)
    local src = source
    
    if not HasPermission(src, 'jobs.view') then
        return
    end

    local fwType, fw = GetFramework()
    local jobs = GetJobsForFramework(fwType, fw)

    if fwType == 'standalone' then
        Logger.Info('')
    end

    TriggerClientEvent('ec:jobs:getAllResponse', src, jobs or {})
end)

RegisterNetEvent('ec:jobs:setPlayerJob', function(data)
    local src = source
    
    if not HasPermission(src, 'jobs.manage') then
        return
    end
    
    local targetId = data.playerId
    local jobName = data.jobName
    local grade = data.grade or 0

    local fwType, fw = GetFramework()

    if fwType == 'standalone' or not fw then
        Logger.Info(string.format('', tostring(jobName), tostring(grade), tostring(targetId)))
        return
    end

    local isValid, resolvedGradeOrError = ValidateJobAndGrade(fwType, fw, jobName, grade)
    if not isValid then
        TriggerClientEvent('ec:notify', src, {
            title = 'Job Update Failed',
            description = resolvedGradeOrError,
            type = 'error'
        })
        return
    end

    local resolvedGrade = resolvedGradeOrError

    if fwType == 'qbx' then
        local Player = fw:GetPlayer(targetId)
        if Player then
            Player.Functions.SetJob(jobName, resolvedGrade)
            Logger.Info(string.format('',
                src, targetId, jobName, tostring(resolvedGrade)))
        end
    elseif fwType == 'qb' then
        local Player = fw.Functions.GetPlayer(targetId)
        if Player then
            Player.Functions.SetJob(jobName, resolvedGrade)
            Logger.Info(string.format('',
                src, targetId, jobName, tostring(resolvedGrade)))
        end
    elseif fwType == 'esx' then
        local xPlayer = fw.GetPlayerFromId(targetId)
        if xPlayer then
            xPlayer.setJob(jobName, resolvedGrade)
        end
    end

    TriggerClientEvent('ec:notify', src, {
        title = 'Job Updated',
        description = 'Player job has been updated',
        type = 'success'
    })
end)

RegisterNetEvent('ec:gangs:getAll', function(data)
    local src = source
    
    if not HasPermission(src, 'gangs.view') then
        return
    end

    local fwType, fw = GetFramework()
    local gangs = GetGangsForFramework(fwType, fw)

    if fwType == 'standalone' then
        Logger.Info('')
    end

    TriggerClientEvent('ec:gangs:getAllResponse', src, gangs)
end)

RegisterNetEvent('ec:gangs:setPlayerGang', function(data)
    local src = source
    
    if not HasPermission(src, 'gangs.manage') then
        return
    end
    
    local targetId = data.playerId
    local gangName = data.gangName
    local grade = data.grade or 0

    local fwType, fw = GetFramework()

    if fwType == 'standalone' or not fw then
        Logger.Info(string.format('', tostring(gangName), tostring(grade), tostring(targetId)))
        return
    end

    local gangs = GetGangsForFramework(fwType, fw)
    local gangData = gangs and gangs[gangName]

    if not gangData then
        TriggerClientEvent('ec:notify', src, {
            title = 'Gang Update Failed',
            description = string.format('Gang %s does not exist', tostring(gangName)),
            type = 'error'
        })
        return
    end

    local resolvedGrade = NormalizeGrade(gangData.grades or gangData.Grades or {}, grade)

    if fwType == 'qbx' then
        local Player = fw:GetPlayer(targetId)
        if Player then
            Player.Functions.SetGang(gangName, resolvedGrade)
            Logger.Info(string.format('',
                src, targetId, gangName, tostring(resolvedGrade)))
        end
    elseif fwType == 'qb' then
        local Player = fw.Functions.GetPlayer(targetId)
        if Player then
            Player.Functions.SetGang(gangName, resolvedGrade)
            Logger.Info(string.format('',
                src, targetId, gangName, tostring(resolvedGrade)))
        end
    end

    TriggerClientEvent('ec:notify', src, {
        title = 'Gang Updated',
        description = 'Player gang has been updated',
        type = 'success'
    })
end)

Logger.Info('')
