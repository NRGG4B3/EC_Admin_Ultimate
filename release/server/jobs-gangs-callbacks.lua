--[[
    EC Admin Ultimate - Jobs & Gangs Complete Callbacks with Database Auto-Detection
    Supports: QB-Core, QBX, ESX with automatic database structure detection
    Version: 2.0.0 - Production Ready
]]

Logger.Info('💼 Loading Jobs & Gangs Complete Callbacks (v2.0)...')

-- ============================================================================
-- FRAMEWORK & DATABASE DETECTION
-- ============================================================================

local Framework = nil
local FrameworkType = nil
local DatabaseStructure = {
    jobs = {},
    gangs = {},
    players = nil,
    society = nil
}

-- Detect Framework
local function DetectFramework()
    if GetResourceState('qbx_core') == 'started' then
        FrameworkType = 'qbx'
        Framework = exports.qbx_core
        Logger.Info('🎯 Framework: QBX Core')
    elseif GetResourceState('qb-core') == 'started' then
        FrameworkType = 'qb'
        Framework = exports['qb-core']:GetCoreObject()
        Logger.Info('🎯 Framework: QB-Core')
    elseif GetResourceState('es_extended') == 'started' then
        FrameworkType = 'esx'
        Framework = exports['es_extended']:getSharedObject()
        Logger.Info('🎯 Framework: ESX')
    else
        FrameworkType = 'standalone'
        Logger.Info('⚠️  Framework: Standalone (Limited functionality)')
    end
    return FrameworkType
end

-- Detect Database Structure
local function DetectDatabaseStructure()
    Logger.Info('🔍 Auto-detecting database structure...')
    
    -- Detect player table structure
    local playerTables = {'players', 'player_data', 'users', 'characters'}
    for _, tableName in ipairs(playerTables) do
        local result = MySQL.query.await('SHOW TABLES LIKE ?', {tableName})
        if result and #result > 0 then
            DatabaseStructure.players = tableName
            Logger.Info(string.format('', tableName))
            
            -- Check for job column
            local columns = MySQL.query.await(string.format('SHOW COLUMNS FROM %s LIKE "job"', tableName))
            if columns and #columns > 0 then
                Logger.Info('✅ Job column found in player table')
            end
            
            -- Check for gang column
            columns = MySQL.query.await(string.format('SHOW COLUMNS FROM %s LIKE "gang"', tableName))
            if columns and #columns > 0 then
                Logger.Info('✅ Gang column found in player table')
            end
            break
        end
    end
    
    -- Detect job tables
    local jobTables = {'jobs', 'job_grades', 'qb_jobs', 'esx_jobs'}
    for _, tableName in ipairs(jobTables) do
        local result = MySQL.query.await('SHOW TABLES LIKE ?', {tableName})
        if result and #result > 0 then
            table.insert(DatabaseStructure.jobs, tableName)
            Logger.Info(string.format('', tableName))
        end
    end
    
    -- Detect gang tables
    local gangTables = {'gangs', 'gang_grades', 'qb_gangs', 'player_gangs'}
    for _, tableName in ipairs(gangTables) do
        local result = MySQL.query.await('SHOW TABLES LIKE ?', {tableName})
        if result and #result > 0 then
            table.insert(DatabaseStructure.gangs, tableName)
            Logger.Info(string.format('', tableName))
        end
    end
    
    -- Detect society/addon account tables
    local societyTables = {'addon_account', 'society_accounts', 'qb_society', 'gang_accounts'}
    for _, tableName in ipairs(societyTables) do
        local result = MySQL.query.await('SHOW TABLES LIKE ?', {tableName})
        if result and #result > 0 then
            DatabaseStructure.society = tableName
            Logger.Info(string.format('', tableName))
            break
        end
    end
    
    Logger.Info('🎉 Database structure detection complete!')
    return DatabaseStructure
end

-- Initialize
DetectFramework()
CreateThread(function()
    Wait(2000) -- Wait for MySQL to be ready
    DetectDatabaseStructure()
end)

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Helper to get player object (QB/QBX compatible)
local function GetFrameworkPlayer(source)
    if not Framework then return nil end
    
    if FrameworkType == 'qb' then
        return Framework.Functions.GetPlayer(source)
    elseif FrameworkType == 'qbx' then
        return exports.qbx_core:GetPlayer(source)
    end
    return nil
end

local function GetPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    
    for _, id in pairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    return identifiers[1]
end

local function GetPlayerCitizenId(source)
    if not Framework then return nil end
    
    if FrameworkType == 'qb' then
        local Player = Framework.Functions.GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    elseif FrameworkType == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    elseif FrameworkType == 'esx' then
        local xPlayer = Framework.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    end
    return nil
end

-- ============================================================================
-- HELPER: GET PLAYER IDENTIFIER
-- ============================================================================

local function GetPlayerIdentifierForFramework(source)
    if not Framework then return nil end
    
    if FrameworkType == 'qb' then
        local Player = Framework.Functions.GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    elseif FrameworkType == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    elseif FrameworkType == 'esx' then
        local xPlayer = Framework.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    end
    
    return nil
end

-- ============================================================================
-- GET ALL JOBS FROM FRAMEWORK
-- ============================================================================

local function GetAllJobs()
    local jobs = {}
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        -- Get from shared.lua Jobs table
        local SharedJobs = nil
        
        if FrameworkType == 'qbx' then
            -- QBX uses different exports
            local success, qbxJobs = pcall(function()
                return exports.qbx_core:GetJobs() or {}
            end)
            if success then
                SharedJobs = qbxJobs
            end
        elseif Framework and Framework.Shared and Framework.Shared.Jobs then
            -- QB-Core uses Framework.Shared.Jobs
            SharedJobs = Framework.Shared.Jobs
        end
        
        if SharedJobs then
            for jobName, jobData in pairs(SharedJobs) do
                local onlineCount = 0
                local totalCount = 0
                
                -- Count online employees
                for _, playerId in ipairs(GetPlayers()) do
                    local Player = nil
                    if FrameworkType == 'qbx' then
                        Player = exports.qbx_core:GetPlayer(tonumber(playerId))
                    else
                        Player = Framework.Functions.GetPlayer(tonumber(playerId))
                    end
                    
                    if Player and Player.PlayerData.job and Player.PlayerData.job.name == jobName then
                        onlineCount = onlineCount + 1
                    end
                end
                
                -- Count total employees from database
                if DatabaseStructure.players then
                    local result = MySQL.query.await(string.format(
                        'SELECT COUNT(*) as count FROM %s WHERE JSON_EXTRACT(job, "$.name") = ?', 
                        DatabaseStructure.players
                    ), {jobName})
                    totalCount = result and result[1] and result[1].count or 0
                end
                
                table.insert(jobs, {
                    name = jobName,
                    label = jobData.label or jobName,
                    type = jobData.type or 'none',
                    defaultDuty = jobData.defaultduty or false,
                    offDutyPay = jobData.offDutyPay or false,
                    grades = jobData.grades or {},
                    onlineEmployees = onlineCount,
                    totalEmployees = totalCount,
                    whitelisted = true
                })
            end
        end
        
    elseif FrameworkType == 'esx' then
        -- Get from database
        if DatabaseStructure.jobs and #DatabaseStructure.jobs > 0 then
            local result = MySQL.query.await(string.format('SELECT * FROM %s', DatabaseStructure.jobs[1]))
            if result then
                for _, jobData in ipairs(result) do
                    local onlineCount = 0
                    local totalCount = 0
                    
                    -- Count online employees
                    for _, playerId in ipairs(GetPlayers()) do
                        local xPlayer = Framework.GetPlayerFromId(tonumber(playerId))
                        if xPlayer and xPlayer.job and xPlayer.job.name == jobData.name then
                            onlineCount = onlineCount + 1
                        end
                    end
                    
                    -- Count total from database
                    if DatabaseStructure.players then
                        local countResult = MySQL.query.await(string.format(
                            'SELECT COUNT(*) as count FROM %s WHERE job = ?', 
                            DatabaseStructure.players
                        ), {jobData.name})
                        totalCount = countResult and countResult[1] and countResult[1].count or 0
                    end
                    
                    table.insert(jobs, {
                        name = jobData.name,
                        label = jobData.label or jobData.name,
                        type = 'job',
                        onlineEmployees = onlineCount,
                        totalEmployees = totalCount,
                        whitelisted = jobData.whitelisted == 1
                    })
                end
            end
        end
    end
    
    return jobs
end

-- ============================================================================
-- GET ALL GANGS FROM FRAMEWORK
-- ============================================================================

local function GetAllGangs()
    local gangs = {}
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        -- Get from shared.lua Gangs table
        local SharedGangs = nil
        
        if FrameworkType == 'qbx' then
            -- QBX uses different exports
            local success, qbxGangs = pcall(function()
                return exports.qbx_core:GetGangs() or {}
            end)
            if success then
                SharedGangs = qbxGangs
            end
        elseif Framework and Framework.Shared and Framework.Shared.Gangs then
            -- QB-Core uses Framework.Shared.Gangs
            SharedGangs = Framework.Shared.Gangs
        end
        
        if SharedGangs then
            for gangName, gangData in pairs(SharedGangs) do
                local onlineCount = 0
                local totalCount = 0
                
                -- Count online members
                for _, playerId in ipairs(GetPlayers()) do
                    local Player = nil
                    if FrameworkType == 'qbx' then
                        Player = exports.qbx_core:GetPlayer(tonumber(playerId))
                    elseif FrameworkType == 'qb' then
                        Player = Framework.Functions.GetPlayer(tonumber(playerId))
                    end
                    
                    if Player and Player.PlayerData.gang and Player.PlayerData.gang.name == gangName then
                        onlineCount = onlineCount + 1
                    end
                end
                
                -- Count total members from database
                if DatabaseStructure.players then
                    local result = MySQL.query.await(string.format(
                        'SELECT COUNT(*) as count FROM %s WHERE JSON_EXTRACT(gang, "$.name") = ?', 
                        DatabaseStructure.players
                    ), {gangName})
                    totalCount = result and result[1] and result[1].count or 0
                end
                
                table.insert(gangs, {
                    name = gangName,
                    label = gangData.label or gangName,
                    grades = gangData.grades or {},
                    onlineMembers = onlineCount,
                    totalMembers = totalCount,
                    leader = 'N/A',
                    territory = 'Unknown',
                    reputation = 0,
                    color = '#FF0000'
                })
            end
        end
    end
    
    return gangs
end

-- ============================================================================
-- GET EMPLOYEES FOR A JOB
-- ============================================================================

local function GetJobEmployees(jobName)
    local employees = {}
    
    if not DatabaseStructure.players then return employees end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local result = MySQL.query.await(string.format(
            'SELECT citizenid, charinfo, job FROM %s WHERE JSON_EXTRACT(job, "$.name") = ?',
            DatabaseStructure.players
        ), {jobName})
        
        if result then
            for _, row in ipairs(result) do
                local charinfo = json.decode(row.charinfo or '{}')
                local jobData = json.decode(row.job or '{}')
                local playerId = nil
                local isOnline = false
                
                -- Check if player is online
                for _, pid in ipairs(GetPlayers()) do
                    local Player = nil
                    if FrameworkType == 'qbx' then
                        Player = exports.qbx_core:GetPlayer(tonumber(pid))
                    elseif FrameworkType == 'qb' then
                        Player = Framework.Functions.GetPlayer(tonumber(pid))
                    end
                    
                    if Player and Player.PlayerData.citizenid == row.citizenid then
                        playerId = tonumber(pid)
                        isOnline = true
                        break
                    end
                end
                
                table.insert(employees, {
                    citizenid = row.citizenid,
                    name = charinfo.firstname and (charinfo.firstname .. ' ' .. charinfo.lastname) or 'Unknown',
                    job = jobName,
                    grade = jobData.grade and jobData.grade.name or 'Unknown',
                    gradeLevel = jobData.grade and jobData.grade.level or 0,
                    salary = jobData.payment or 0,
                    onDuty = jobData.onduty or false,
                    online = isOnline,
                    source = playerId
                })
            end
        end
        
    elseif FrameworkType == 'esx' then
        local result = MySQL.query.await(string.format(
            'SELECT identifier, firstname, lastname, job, job_grade FROM %s WHERE job = ?',
            DatabaseStructure.players
        ), {jobName})
        
        if result then
            for _, row in ipairs(result) do
                local playerId = nil
                local isOnline = false
                
                -- Check if player is online
                for _, pid in ipairs(GetPlayers()) do
                    local xPlayer = Framework.GetPlayerFromId(tonumber(pid))
                    if xPlayer and xPlayer.identifier == row.identifier then
                        playerId = tonumber(pid)
                        isOnline = true
                        break
                    end
                end
                
                table.insert(employees, {
                    identifier = row.identifier,
                    name = (row.firstname or 'Unknown') .. ' ' .. (row.lastname or ''),
                    job = jobName,
                    grade = 'Grade ' .. (row.job_grade or 0),
                    gradeLevel = row.job_grade or 0,
                    salary = 0,
                    onDuty = false,
                    online = isOnline,
                    source = playerId
                })
            end
        end
    end
    
    return employees
end

-- ============================================================================
-- GET GANG MEMBERS
-- ============================================================================

local function GetGangMembers(gangName)
    local members = {}
    
    if not DatabaseStructure.players then return members end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local result = MySQL.query.await(string.format(
            'SELECT citizenid, charinfo, gang FROM %s WHERE JSON_EXTRACT(gang, "$.name") = ?',
            DatabaseStructure.players
        ), {gangName})
        
        if result then
            for _, row in ipairs(result) do
                local charinfo = json.decode(row.charinfo or '{}')
                local gangData = json.decode(row.gang or '{}')
                local playerId = nil
                local isOnline = false
                
                -- Check if player is online
                for _, pid in ipairs(GetPlayers()) do
                    local Player = nil
                    if FrameworkType == 'qbx' then
                        Player = exports.qbx_core:GetPlayer(tonumber(pid))
                    elseif FrameworkType == 'qb' then
                        Player = Framework.Functions.GetPlayer(tonumber(pid))
                    end
                    
                    if Player and Player.PlayerData.citizenid == row.citizenid then
                        playerId = tonumber(pid)
                        isOnline = true
                        break
                    end
                end
                
                table.insert(members, {
                    citizenid = row.citizenid,
                    name = charinfo.firstname and (charinfo.firstname .. ' ' .. charinfo.lastname) or 'Unknown',
                    gang = gangName,
                    rank = gangData.grade and gangData.grade.name or 'Unknown',
                    rankLevel = gangData.grade and gangData.grade.level or 0,
                    online = isOnline,
                    source = playerId
                })
            end
        end
    end
    
    return members
end

-- ============================================================================
-- CALLBACK: GET ALL JOBS & GANGS DATA
-- ============================================================================

lib.callback.register('ec_admin:getJobsGangsData', function(source)
    local jobs = GetAllJobs()
    local gangs = GetAllGangs()
    
    -- Get all employees
    local allEmployees = {}
    for _, job in ipairs(jobs) do
        local employees = GetJobEmployees(job.name)
        for _, emp in ipairs(employees) do
            table.insert(allEmployees, emp)
        end
    end
    
    -- Get all gang members
    local allGangMembers = {}
    for _, gang in ipairs(gangs) do
        local members = GetGangMembers(gang.name)
        for _, member in ipairs(members) do
            table.insert(allGangMembers, member)
        end
    end
    
    -- Calculate stats
    local onlineEmployees = 0
    local onlineGangMembers = 0
    for _, emp in ipairs(allEmployees) do
        if emp.online then onlineEmployees = onlineEmployees + 1 end
    end
    for _, member in ipairs(allGangMembers) do
        if member.online then onlineGangMembers = onlineGangMembers + 1 end
    end
    
    return {
        success = true,
        data = {
            jobs = jobs,
            gangs = gangs,
            employees = allEmployees,
            gangMembers = allGangMembers,
            stats = {
                totalJobs = #jobs,
                totalEmployees = #allEmployees,
                totalGangs = #gangs,
                totalGangMembers = #allGangMembers,
                onlineEmployees = onlineEmployees,
                onlineGangMembers = onlineGangMembers
            },
            framework = FrameworkType,
            databaseStructure = DatabaseStructure
        }
    }
end)

-- ============================================================================
-- CALLBACK: HIRE PLAYER
-- ============================================================================

lib.callback.register('ec_admin:hirePlayer', function(source, data)
    local targetSource = tonumber(data.playerId)
    local jobName = data.jobName
    local gradeLevel = tonumber(data.gradeLevel) or 0
    
    if not targetSource or not jobName then
        return { success = false, message = 'Invalid parameters' }
    end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local Player = GetFrameworkPlayer(targetSource)  -- Use helper function
        if Player then
            Player.Functions.SetJob(jobName, gradeLevel)
            return { success = true, message = string.format('Hired player as %s (Grade %d)', jobName, gradeLevel) }
        end
    elseif FrameworkType == 'esx' then
        local xPlayer = Framework.GetPlayerFromId(targetSource)
        if xPlayer then
            xPlayer.setJob(jobName, gradeLevel)
            return { success = true, message = string.format('Hired player as %s (Grade %d)', jobName, gradeLevel) }
        end
    end
    
    return { success = false, message = 'Player not found or framework not supported' }
end)

-- ============================================================================
-- CALLBACK: FIRE PLAYER
-- ============================================================================

lib.callback.register('ec_admin:firePlayer', function(source, data)
    local targetSource = tonumber(data.playerId)
    
    if not targetSource then
        return { success = false, message = 'Invalid player ID' }
    end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local Player = Framework.Functions.GetPlayer(targetSource)
        if Player then
            Player.Functions.SetJob('unemployed', 0)
            return { success = true, message = 'Player fired and set to unemployed' }
        end
    elseif FrameworkType == 'esx' then
        local xPlayer = Framework.GetPlayerFromId(targetSource)
        if xPlayer then
            xPlayer.setJob('unemployed', 0)
            return { success = true, message = 'Player fired and set to unemployed' }
        end
    end
    
    return { success = false, message = 'Player not found' }
end)

-- ============================================================================
-- CALLBACK: PROMOTE EMPLOYEE
-- ============================================================================

lib.callback.register('ec_admin:promoteEmployee', function(source, data)
    local targetSource = tonumber(data.playerId)
    
    if not targetSource then
        return { success = false, message = 'Invalid player ID' }
    end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local Player = Framework.Functions.GetPlayer(targetSource)
        if Player and Player.PlayerData.job then
            local currentGrade = Player.PlayerData.job.grade.level
            local newGrade = currentGrade + 1
            Player.Functions.SetJob(Player.PlayerData.job.name, newGrade)
            return { success = true, message = string.format('Promoted to Grade %d', newGrade) }
        end
    elseif FrameworkType == 'esx' then
        local xPlayer = Framework.GetPlayerFromId(targetSource)
        if xPlayer and xPlayer.job then
            local currentGrade = xPlayer.job.grade
            local newGrade = currentGrade + 1
            xPlayer.setJob(xPlayer.job.name, newGrade)
            return { success = true, message = string.format('Promoted to Grade %d', newGrade) }
        end
    end
    
    return { success = false, message = 'Failed to promote employee' }
end)

-- ============================================================================
-- CALLBACK: DEMOTE EMPLOYEE
-- ============================================================================

lib.callback.register('ec_admin:demoteEmployee', function(source, data)
    local targetSource = tonumber(data.playerId)
    
    if not targetSource then
        return { success = false, message = 'Invalid player ID' }
    end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local Player = Framework.Functions.GetPlayer(targetSource)
        if Player and Player.PlayerData.job then
            local currentGrade = Player.PlayerData.job.grade.level
            local newGrade = math.max(0, currentGrade - 1)
            Player.Functions.SetJob(Player.PlayerData.job.name, newGrade)
            return { success = true, message = string.format('Demoted to Grade %d', newGrade) }
        end
    elseif FrameworkType == 'esx' then
        local xPlayer = Framework.GetPlayerFromId(targetSource)
        if xPlayer and xPlayer.job then
            local currentGrade = xPlayer.job.grade
            local newGrade = math.max(0, currentGrade - 1)
            xPlayer.setJob(xPlayer.job.name, newGrade)
            return { success = true, message = string.format('Demoted to Grade %d', newGrade) }
        end
    end
    
    return { success = false, message = 'Failed to demote employee' }
end)

-- ============================================================================
-- CALLBACK: SET EMPLOYEE GRADE
-- ============================================================================

lib.callback.register('ec_admin:setEmployeeGrade', function(source, data)
    local targetSource = tonumber(data.playerId)
    local gradeLevel = tonumber(data.gradeLevel)
    
    if not targetSource or not gradeLevel then
        return { success = false, message = 'Invalid parameters' }
    end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local Player = Framework.Functions.GetPlayer(targetSource)
        if Player and Player.PlayerData.job then
            Player.Functions.SetJob(Player.PlayerData.job.name, gradeLevel)
            return { success = true, message = string.format('Set grade to %d', gradeLevel) }
        end
    elseif FrameworkType == 'esx' then
        local xPlayer = Framework.GetPlayerFromId(targetSource)
        if xPlayer and xPlayer.job then
            xPlayer.setJob(xPlayer.job.name, gradeLevel)
            return { success = true, message = string.format('Set grade to %d', gradeLevel) }
        end
    end
    
    return { success = false, message = 'Failed to set grade' }
end)

-- ============================================================================
-- GANG MEMBER MANAGEMENT (QB/QBX ONLY)
-- ============================================================================

lib.callback.register('ec_admin:recruitGangMember', function(source, data)
    local targetSource = tonumber(data.playerId)
    local gangName = data.gangName
    local rankLevel = tonumber(data.rankLevel) or 0
    
    if not targetSource or not gangName then
        return { success = false, message = 'Invalid parameters' }
    end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local Player = Framework.Functions.GetPlayer(targetSource)
        if Player then
            Player.Functions.SetGang(gangName, rankLevel)
            return { success = true, message = string.format('Recruited to %s (Rank %d)', gangName, rankLevel) }
        end
    end
    
    return { success = false, message = 'Gangs only supported on QB-Core/QBX' }
end)

lib.callback.register('ec_admin:removeGangMember', function(source, data)
    local targetSource = tonumber(data.playerId)
    
    if not targetSource then
        return { success = false, message = 'Invalid player ID' }
    end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local Player = Framework.Functions.GetPlayer(targetSource)
        if Player then
            Player.Functions.SetGang('none', 0)
            return { success = true, message = 'Removed from gang' }
        end
    end
    
    return { success = false, message = 'Player not found' }
end)

lib.callback.register('ec_admin:promoteGangMember', function(source, data)
    local targetSource = tonumber(data.playerId)
    
    if not targetSource then
        return { success = false, message = 'Invalid player ID' }
    end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local Player = Framework.Functions.GetPlayer(targetSource)
        if Player and Player.PlayerData.gang then
            local currentRank = Player.PlayerData.gang.grade.level
            local newRank = currentRank + 1
            Player.Functions.SetGang(Player.PlayerData.gang.name, newRank)
            return { success = true, message = string.format('Promoted to Rank %d', newRank) }
        end
    end
    
    return { success = false, message = 'Failed to promote member' }
end)

lib.callback.register('ec_admin:demoteGangMember', function(source, data)
    local targetSource = tonumber(data.playerId)
    
    if not targetSource then
        return { success = false, message = 'Invalid player ID' }
    end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local Player = Framework.Functions.GetPlayer(targetSource)
        if Player and Player.PlayerData.gang then
            local currentRank = Player.PlayerData.gang.grade.level
            local newRank = math.max(0, currentRank - 1)
            Player.Functions.SetGang(Player.PlayerData.gang.name, newRank)
            return { success = true, message = string.format('Demoted to Rank %d', newRank) }
        end
    end
    
    return { success = false, message = 'Failed to demote member' }
end)

lib.callback.register('ec_admin:setGangMemberRank', function(source, data)
    local targetSource = tonumber(data.playerId)
    local rankLevel = tonumber(data.rankLevel)
    
    if not targetSource or not rankLevel then
        return { success = false, message = 'Invalid parameters' }
    end
    
    if FrameworkType == 'qb' or FrameworkType == 'qbx' then
        local Player = Framework.Functions.GetPlayer(targetSource)
        if Player and Player.PlayerData.gang then
            Player.Functions.SetGang(Player.PlayerData.gang.name, rankLevel)
            return { success = true, message = string.format('Set rank to %d', rankLevel) }
        end
    end
    
    return { success = false, message = 'Failed to set rank' }
end)

Logger.Info('✅ Jobs & Gangs Complete Callbacks loaded!')