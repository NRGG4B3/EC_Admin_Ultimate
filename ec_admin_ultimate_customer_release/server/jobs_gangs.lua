--[[
    EC Admin Ultimate - Jobs & Gangs UI Backend
    Server-side logic for jobs and gangs management
    
    Handles:
    - jobs-gangs:getData: Get all jobs, gangs, employees, gang members, and statistics
    - jobs-gangs:hirePlayer: Hire a player to a job
    - jobs-gangs:promoteEmployee: Promote an employee
    - jobs-gangs:demoteEmployee: Demote an employee
    - jobs-gangs:fireEmployee: Fire an employee
    - jobs-gangs:recruitGangMember: Recruit a player to a gang
    - jobs-gangs:promoteGangMember: Promote a gang member
    - jobs-gangs:demoteGangMember: Demote a gang member
    - jobs-gangs:removeGangMember: Remove a gang member
    - jobs-gangs:setSocietyMoney: Set society money for a job
    - jobs-gangs:setGangMoney: Set money for a gang
    - jobs-gangs:createJob: Create a new job
    - jobs-gangs:deleteJob: Delete a job
    - jobs-gangs:createGang: Create a new gang
    - jobs-gangs:deleteGang: Delete a gang
    
    Framework Support: QB-Core, QBX, ESX
]]

-- Ensure MySQL is available
if not MySQL then
    print("^1[Jobs & Gangs] ERROR: oxmysql not found! Please ensure oxmysql is started before this resource.^0")
    return
end

-- Ensure framework is available
if not ECFramework then
    print("^1[Jobs & Gangs] ERROR: ECFramework not found! Please ensure shared/framework.lua is loaded.^0")
    return
end

-- Local variables
local dataCache = {}
local CACHE_TTL = 10 -- Cache for 10 seconds

-- Helper: Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Helper: Get framework
local function getFramework()
    return ECFramework.GetFramework() or 'standalone'
end

-- Helper: Get player object
local function getPlayerObject(source)
    return ECFramework.GetPlayerObject(source)
end

-- Helper: Check admin permission
local function hasPermission(source, permission)
    if exports['ec_admin_ultimate'] and exports['ec_admin_ultimate'].HasPermission then
        return exports['ec_admin_ultimate']:HasPermission(source, permission)
    end
    return ECFramework.IsAdminGroup(source) or false
end

-- Helper: Get admin info
local function getAdminInfo(source)
    return {
        id = GetPlayerIdentifier(source, 0) or 'system',
        name = GetPlayerName(source) or 'System'
    }
end

-- Helper: Log job action
local function logJobAction(actionType, jobName, playerId, playerIdentifier, playerName, adminId, adminName, actionData, oldGrade, newGrade, reason, success, errorMsg)
    MySQL.insert.await([[
        INSERT INTO ec_jobs_actions_log 
        (action_type, job_name, player_id, player_identifier, player_name, admin_id, admin_name, action_data, old_grade, new_grade, reason, timestamp, success, error_message)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        actionType, jobName, playerId, playerIdentifier, playerName, adminId, adminName,
        actionData and json.encode(actionData) or nil, oldGrade, newGrade, reason,
        getCurrentTimestamp(), success and 1 or 0, errorMsg
    })
end

-- Helper: Log gang action
local function logGangAction(actionType, gangName, playerId, playerIdentifier, playerName, adminId, adminName, actionData, oldRank, newRank, reason, success, errorMsg)
    MySQL.insert.await([[
        INSERT INTO ec_gangs_actions_log 
        (action_type, gang_name, player_id, player_identifier, player_name, admin_id, admin_name, action_data, old_rank, new_rank, reason, timestamp, success, error_message)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        actionType, gangName, playerId, playerIdentifier, playerName, adminId, adminName,
        actionData and json.encode(actionData) or nil, oldRank, newRank, reason,
        getCurrentTimestamp(), success and 1 or 0, errorMsg
    })
end

-- Helper: Get all jobs from framework
local function getAllJobs()
    local jobs = {}
    local framework = getFramework()
    
    if framework == 'qb' or framework == 'qbx' then
        -- QB-Core/QBX: Jobs are typically in shared/jobs.lua or config
        -- Try to get from exports or config
        -- Note: GetJobs export may not exist in all QB versions
        local success, frameworkJobs = pcall(function()
        if exports['qb-core'] and exports['qb-core'].GetJobs then
                return exports['qb-core']:GetJobs()
            end
            return nil
        end)
        if not success then frameworkJobs = nil end
            if frameworkJobs then
                for jobName, jobData in pairs(frameworkJobs) do
                    table.insert(jobs, {
                        name = jobName,
                        label = jobData.label or jobName,
                        totalEmployees = 0, -- Will be calculated
                        onlineEmployees = 0,
                        whitelisted = jobData.whitelisted or false,
                        societyMoney = 0, -- Will be fetched from society account
                        type = jobData.type or 'none',
                        grades = jobData.grades or {}
                    })
            end
        end
    elseif framework == 'esx' then
        -- ESX: Jobs are in esx_jobs table or config
        local result = MySQL.query.await('SELECT name, label, whitelisted FROM jobs', {})
        if result then
            for _, row in ipairs(result) do
                -- Get grades
                local grades = {}
                local gradeResult = MySQL.query.await('SELECT * FROM job_grades WHERE job_name = ? ORDER BY grade', {row.name})
                if gradeResult then
                    for _, grade in ipairs(gradeResult) do
                        table.insert(grades, grade)
                    end
                end
                
                table.insert(jobs, {
                    name = row.name,
                    label = row.label or row.name,
                    totalEmployees = 0,
                    onlineEmployees = 0,
                    whitelisted = row.whitelisted == 1,
                    societyMoney = 0,
                    type = 'none',
                    grades = grades
                })
            end
        end
    end
    
    return jobs
end

-- Helper: Get all gangs from framework
local function getAllGangs()
    local gangs = {}
    local framework = getFramework()
    
    if framework == 'qb' or framework == 'qbx' then
        -- QB-Core/QBX: Gangs are typically in shared/gangs.lua or config
        local success, frameworkGangs = pcall(function()
        if exports['qb-core'] and exports['qb-core'].GetGangs then
                return exports['qb-core']:GetGangs()
            end
            return nil
        end)
        if success and frameworkGangs then
            if frameworkGangs then
                for gangName, gangData in pairs(frameworkGangs) do
                    table.insert(gangs, {
                        name = gangName,
                        label = gangData.label or gangName,
                        totalMembers = 0,
                        onlineMembers = 0,
                        leader = '',
                        territory = gangData.territory or '',
                        reputation = gangData.reputation or 0,
                        color = gangData.color or '#ffffff',
                        grades = gangData.grades or {},
                        balance = 0
                    })
                end
            end
        end
    elseif framework == 'esx' then
        -- ESX doesn't have gangs by default, but might have custom implementation
        -- Check if gangs table exists
        local result = MySQL.query.await('SHOW TABLES LIKE "gangs"', {})
        if result and result[1] then
            local gangResult = MySQL.query.await('SELECT * FROM gangs', {})
            if gangResult then
                for _, row in ipairs(gangResult) do
                    table.insert(gangs, {
                        name = row.name,
                        label = row.label or row.name,
                        totalMembers = 0,
                        onlineMembers = 0,
                        leader = row.leader or '',
                        territory = row.territory or '',
                        reputation = row.reputation or 0,
                        color = row.color or '#ffffff',
                        grades = {},
                        balance = row.balance or 0
                    })
                end
            end
        end
    end
    
    return gangs
end

-- Helper: Get all employees
local function getAllEmployees()
    local employees = {}
    local framework = getFramework()
    
    if framework == 'qb' or framework == 'qbx' then
        -- QB-Core/QBX: Employees are in players table with job data
        local success, result = pcall(function()
            return MySQL.query.await([[
            SELECT 
                p.citizenid,
                p.charinfo,
                p.job,
                p.metadata
            FROM players p
            WHERE p.job IS NOT NULL AND p.job != '{}'
        ]], {})
        end)
        
        if not success then
            -- Table doesn't exist or query failed, return empty employees
            print("^3[Jobs/Gangs]^7 Warning: Could not fetch employees - players table may not exist yet^0")
            return employees
        end
        
        if result then
            for _, row in ipairs(result) do
                local charinfo = json.decode(row.charinfo or '{}')
                local job = json.decode(row.job or '{}')
                local metadata = json.decode(row.metadata or '{}')
                
                -- Check if online
                local online = false
                local identifier = 'license:' .. (row.citizenid or '')
                for _, playerId in ipairs(GetPlayers()) do
                    local source = tonumber(playerId)
                    if source then
                        local playerIds = GetPlayerIdentifiers(source)
                        for _, id in ipairs(playerIds) do
                            if id == identifier then
                                online = true
                                break
                            end
                        end
                        if online then break end
                    end
                end
                
                table.insert(employees, {
                    identifier = identifier,
                    citizenid = row.citizenid,
                    name = charinfo.firstname and (charinfo.firstname .. ' ' .. (charinfo.lastname or '')) or 'Unknown',
                    job = job.name or 'unemployed',
                    grade = job.label or 'Employee',
                    gradeLevel = job.grade?.level or job.grade or 0,
                    salary = job.payment or 0,
                    hired = metadata.hired or '',
                    online = online
                })
            end
        end
    elseif framework == 'esx' then
        -- ESX: Employees are in users table with job
        local result = MySQL.query.await([[
            SELECT 
                u.identifier,
                u.firstname,
                u.lastname,
                u.job,
                u.job_grade
            FROM users u
            WHERE u.job IS NOT NULL AND u.job != 'unemployed'
        ]], {})
        
        if result then
            for _, row in ipairs(result) do
                -- Get grade info
                local gradeResult = MySQL.query.await('SELECT * FROM job_grades WHERE job_name = ? AND grade = ?', {row.job, row.job_grade})
                local gradeData = gradeResult and gradeResult[1] or {}
                
                -- Check if online
                local online = false
                for _, playerId in ipairs(GetPlayers()) do
                    local source = tonumber(playerId)
                    if source then
                        local playerIds = GetPlayerIdentifiers(source)
                        for _, id in ipairs(playerIds) do
                            if id == row.identifier then
                                online = true
                                break
                            end
                        end
                        if online then break end
                    end
                end
                
                table.insert(employees, {
                    identifier = row.identifier,
                    name = (row.firstname or '') .. ' ' .. (row.lastname or ''),
                    job = row.job,
                    grade = gradeData.label or 'Employee',
                    gradeLevel = row.job_grade or 0,
                    salary = gradeData.salary or 0,
                    hired = '',
                    online = online
                })
            end
        end
    end
    
    return employees
end

-- Helper: Get all gang members
local function getAllGangMembers()
    local members = {}
    local framework = getFramework()
    
    if framework == 'qb' or framework == 'qbx' then
        -- QB-Core/QBX: Gang members are in players table with gang data
        local success, result = pcall(function()
            return MySQL.query.await([[
            SELECT 
                p.citizenid,
                p.charinfo,
                p.gang,
                p.metadata
            FROM players p
            WHERE p.gang IS NOT NULL AND p.gang != '{}'
        ]], {})
        end)
        
        if not success then
            -- Table doesn't exist or query failed, return empty members
            print("^3[Jobs/Gangs]^7 Warning: Could not fetch gang members - players table may not exist yet^0")
            return members
        end
        
        if result then
            for _, row in ipairs(result) do
                local charinfo = json.decode(row.charinfo or '{}')
                local gang = json.decode(row.gang or '{}')
                
                -- Check if online
                local online = false
                local identifier = 'license:' .. (row.citizenid or '')
                for _, playerId in ipairs(GetPlayers()) do
                    local source = tonumber(playerId)
                    if source then
                        local playerIds = GetPlayerIdentifiers(source)
                        for _, id in ipairs(playerIds) do
                            if id == identifier then
                                online = true
                                break
                            end
                        end
                        if online then break end
                    end
                end
                
                table.insert(members, {
                    identifier = identifier,
                    citizenid = row.citizenid,
                    name = charinfo.firstname and (charinfo.firstname .. ' ' .. (charinfo.lastname or '')) or 'Unknown',
                    gang = gang.name or 'none',
                    rank = gang.label or 'Member',
                    rankLevel = gang.grade?.level or gang.grade or 0,
                    joined = '',
                    online = online
                })
            end
        end
    elseif framework == 'esx' then
        -- ESX doesn't have gangs by default
        -- Check if custom gangs table exists
        local result = MySQL.query.await('SHOW TABLES LIKE "gang_members"', {})
        if result and result[1] then
            local memberResult = MySQL.query.await('SELECT * FROM gang_members', {})
            if memberResult then
                for _, row in ipairs(memberResult) do
                    -- Check if online
                    local online = false
                    for _, playerId in ipairs(GetPlayers()) do
                        local source = tonumber(playerId)
                        if source then
                            local playerIds = GetPlayerIdentifiers(source)
                            for _, id in ipairs(playerIds) do
                                if id == row.identifier then
                                    online = true
                                    break
                                end
                            end
                            if online then break end
                        end
                    end
                    
                    table.insert(members, {
                        identifier = row.identifier,
                        name = row.name or 'Unknown',
                        gang = row.gang_name,
                        rank = row.rank or 'Member',
                        rankLevel = row.rank_level or 0,
                        joined = row.joined or '',
                        online = online
                    })
                end
            end
        end
    end
    
    return members
end

-- Helper: Get jobs & gangs data (shared logic)
local function getJobsGangsData()
    -- Check cache
    if dataCache.data and (getCurrentTimestamp() - dataCache.timestamp) < CACHE_TTL then
        return dataCache.data
    end
    
    local jobs = getAllJobs()
    local gangs = getAllGangs()
    local employees = getAllEmployees()
    local gangMembers = getAllGangMembers()
    
    -- Calculate statistics
    local stats = {
        totalJobs = #jobs,
        totalEmployees = #employees,
        totalGangs = #gangs,
        totalGangMembers = #gangMembers,
        onlineEmployees = 0,
        onlineGangMembers = 0
    }
    
    -- Count online employees
    for _, emp in ipairs(employees) do
        if emp.online then
            stats.onlineEmployees = stats.onlineEmployees + 1
        end
    end
    
    -- Count online gang members
    for _, member in ipairs(gangMembers) do
        if member.online then
            stats.onlineGangMembers = stats.onlineGangMembers + 1
        end
    end
    
    -- Update job statistics
    for _, job in ipairs(jobs) do
        local jobEmployees = {}
        for _, emp in ipairs(employees) do
            if emp.job == job.name then
                table.insert(jobEmployees, emp)
                if emp.online then
                    job.onlineEmployees = job.onlineEmployees + 1
                end
            end
        end
        job.totalEmployees = #jobEmployees
    end
    
    -- Update gang statistics
    for _, gang in ipairs(gangs) do
        local gangMembersList = {}
        for _, member in ipairs(gangMembers) do
            if member.gang == gang.name then
                table.insert(gangMembersList, member)
                if member.online then
                    gang.onlineMembers = gang.onlineMembers + 1
                end
            end
        end
        gang.totalMembers = #gangMembersList
    end
    
    local data = {
        jobs = jobs,
        gangs = gangs,
        employees = employees,
        gangMembers = gangMembers,
        stats = stats,
        framework = getFramework()
    }
    
    -- Cache data
    dataCache = {
        data = data,
        timestamp = getCurrentTimestamp()
    }
    
    return data
end

-- ============================================================================
-- REGISTERNUICALLBACK HANDLERS (Direct fetch from UI)
-- ============================================================================

-- Callback: Get jobs & gangs data
-- REMOVED: RegisterNUICallback is CLIENT-side only
-- RegisterNUICallback('jobs-gangs:getData', function(data, cb)
    local response = getJobsGangsData()
    -- cb({ success = true, data = response })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Hire player to job
-- RegisterNUICallback('jobs-gangs:hirePlayer', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     local jobName = data.jobName
--     local gradeLevel = tonumber(data.gradeLevel) or 0
--     
--     if not playerId or not jobName then
--         cb({ success = false, message = 'Player ID and job name required' })
--         return
--     end
--     
--     -- Get admin info (source not available in RegisterNUICallback, use system)
--     local adminInfo = { id = 'system', name = 'System' }
--     
--     local success = false
--     local message = 'Player hired successfully'
--     local errorMsg = nil
--     
--     local framework = getFramework()
--     local player = getPlayerObject(playerId)
--     
--     if not player then
--         cb({ success = false, message = 'Player not found' })
--         return
--     end
--     
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = GetPlayerIdentifier(playerId, 0) or ''
--     
--     if framework == 'qb' or framework == 'qbx' then
--         -- QB-Core/QBX: Set job via PlayerData
--         if player.PlayerData then
--             player.PlayerData.job = {
--                 name = jobName,
--                 label = jobName, -- Will be set from job config
--                 payment = 0, -- Will be set from job config
--                 grade = {
--                     name = 'Employee',
--                     level = gradeLevel,
--                     payment = 0
--                 },
--                 onduty = false,
--                 isboss = false
--             }
--             
--             -- Trigger job update event
--             TriggerClientEvent('QBCore:Client:OnJobUpdate', playerId, player.PlayerData.job)
--             
--             success = true
--         end
--     elseif framework == 'esx' then
--         -- ESX: Set job via setJob
--         if player.setJob then
--             player:setJob(jobName, gradeLevel)
--             success = true
--         end
--     end
--     
--     -- Log action
--     logJobAction('hire', jobName, playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, data, nil, gradeLevel, nil, success, errorMsg)
--     
--     -- Clear cache
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or (errorMsg or 'Failed to hire player') })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Promote employee
-- RegisterNUICallback('jobs-gangs:promoteEmployee', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     local newGrade = tonumber(data.newGrade)
--     
--     if not playerId or not newGrade then
--         cb({ success = false, message = 'Player ID and new grade required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Employee promoted successfully'
--     
--     local player = getPlayerObject(playerId)
--     if not player then
--         cb({ success = false, message = 'Player not found' })
--         return
--     end
--     
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = GetPlayerIdentifier(playerId, 0) or ''
--     local oldGrade = 0
--     local jobName = 'unemployed'
--     
--     local framework = getFramework()
--     if framework == 'qb' or framework == 'qbx' then
--         if player.PlayerData and player.PlayerData.job then
--             oldGrade = player.PlayerData.job.grade?.level or player.PlayerData.job.grade or 0
--             jobName = player.PlayerData.job.name
--             player.PlayerData.job.grade = {
--                 name = 'Employee',
--                 level = newGrade,
--                 payment = 0
--             }
--             TriggerClientEvent('QBCore:Client:OnJobUpdate', playerId, player.PlayerData.job)
--             success = true
--         end
--     elseif framework == 'esx' then
--         if player.job then
--             oldGrade = player.job.grade or 0
--             jobName = player.job.name
--             if player.setJob then
--                 player:setJob(jobName, newGrade)
--                 success = true
--             end
--         end
--     end
--     
--     logJobAction('promote', jobName, playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, data, oldGrade, newGrade, nil, success, nil)
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to promote employee' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Demote employee
-- RegisterNUICallback('jobs-gangs:demoteEmployee', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     local newGrade = tonumber(data.newGrade)
--     
--     if not playerId or not newGrade then
--         cb({ success = false, message = 'Player ID and new grade required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Employee demoted successfully'
--     
--     local player = getPlayerObject(playerId)
--     if not player then
--         cb({ success = false, message = 'Player not found' })
--         return
--     end
--     
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = GetPlayerIdentifier(playerId, 0) or ''
--     local oldGrade = 0
--     local jobName = 'unemployed'
--     
--     local framework = getFramework()
--     if framework == 'qb' or framework == 'qbx' then
--         if player.PlayerData and player.PlayerData.job then
--             oldGrade = player.PlayerData.job.grade?.level or player.PlayerData.job.grade or 0
--             jobName = player.PlayerData.job.name
--             player.PlayerData.job.grade = {
--                 name = 'Employee',
--                 level = newGrade,
--                 payment = 0
--             }
--             TriggerClientEvent('QBCore:Client:OnJobUpdate', playerId, player.PlayerData.job)
--             success = true
--         end
--     elseif framework == 'esx' then
--         if player.job then
--             oldGrade = player.job.grade or 0
--             jobName = player.job.name
--             if player.setJob then
--                 player:setJob(jobName, newGrade)
--                 success = true
--             end
--         end
--     end
--     
--     logJobAction('demote', jobName, playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, data, oldGrade, newGrade, nil, success, nil)
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to demote employee' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Fire employee
-- RegisterNUICallback('jobs-gangs:fireEmployee', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     local reason = data.reason or 'No reason provided'
--     
--     if not playerId then
--         cb({ success = false, message = 'Player ID required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Employee fired successfully'
--     
--     local player = getPlayerObject(playerId)
--     if not player then
--         cb({ success = false, message = 'Player not found' })
--         return
--     end
--     
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = GetPlayerIdentifier(playerId, 0) or ''
--     local oldGrade = 0
--     local jobName = 'unemployed'
--     
--     local framework = getFramework()
--     if framework == 'qb' or framework == 'qbx' then
--         if player.PlayerData and player.PlayerData.job then
--             oldGrade = player.PlayerData.job.grade?.level or player.PlayerData.job.grade or 0
--             jobName = player.PlayerData.job.name
--             player.PlayerData.job = {
--                 name = 'unemployed',
--                 label = 'Unemployed',
--                 payment = 0,
--                 grade = { name = 'Unemployed', level = 0, payment = 0 },
--                 onduty = false,
--                 isboss = false
--             }
--             TriggerClientEvent('QBCore:Client:OnJobUpdate', playerId, player.PlayerData.job)
--             success = true
--         end
--     elseif framework == 'esx' then
--         if player.job then
--             oldGrade = player.job.grade or 0
--             jobName = player.job.name
--             if player.setJob then
--                 player:setJob('unemployed', 0)
--                 success = true
--             end
--         end
--     end
--     
--     logJobAction('fire', jobName, playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, data, oldGrade, 0, reason, success, nil)
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to fire employee' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Recruit gang member
-- RegisterNUICallback('jobs-gangs:recruitGangMember', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     local gangName = data.gangName
--     local rankLevel = tonumber(data.rankLevel) or 0
--     
--     if not playerId or not gangName then
--         cb({ success = false, message = 'Player ID and gang name required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Member recruited successfully'
--     
--     local player = getPlayerObject(playerId)
--     if not player then
--         cb({ success = false, message = 'Player not found' })
--         return
--     end
--     
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = GetPlayerIdentifier(playerId, 0) or ''
--     
--     local framework = getFramework()
--     if framework == 'qb' or framework == 'qbx' then
--         if player.PlayerData then
--             player.PlayerData.gang = {
--                 name = gangName,
--                 label = gangName,
--                 grade = {
--                     name = 'Member',
--                     level = rankLevel
--                 },
--                 isboss = false
--             }
--             TriggerClientEvent('QBCore:Client:OnGangUpdate', playerId, player.PlayerData.gang)
--             success = true
--         end
--     elseif framework == 'esx' then
--         -- ESX doesn't have gangs by default
--         -- Would need custom implementation
--         message = 'Gangs not supported in ESX by default'
--     end
--     
--     logGangAction('recruit', gangName, playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, data, nil, rankLevel, nil, success, nil)
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to recruit member' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Promote gang member
-- RegisterNUICallback('jobs-gangs:promoteGangMember', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     local newRank = tonumber(data.newRank)
--     
--     if not playerId or not newRank then
--         cb({ success = false, message = 'Player ID and new rank required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Member promoted successfully'
--     
--     local player = getPlayerObject(playerId)
--     if not player then
--         cb({ success = false, message = 'Player not found' })
--         return
--     end
--     
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = GetPlayerIdentifier(playerId, 0) or ''
--     local oldRank = 0
--     local gangName = 'none'
--     
--     local framework = getFramework()
--     if framework == 'qb' or framework == 'qbx' then
--         if player.PlayerData and player.PlayerData.gang then
--             oldRank = player.PlayerData.gang.grade?.level or player.PlayerData.gang.grade or 0
--             gangName = player.PlayerData.gang.name
--             player.PlayerData.gang.grade = {
--                 name = 'Member',
--                 level = newRank
--             }
--             TriggerClientEvent('QBCore:Client:OnGangUpdate', playerId, player.PlayerData.gang)
--             success = true
--         end
--     end
--     
--     logGangAction('promote', gangName, playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, data, oldRank, newRank, nil, success, nil)
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to promote member' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Demote gang member
-- RegisterNUICallback('jobs-gangs:demoteGangMember', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     local newRank = tonumber(data.newRank)
--     
--     if not playerId or not newRank then
--         cb({ success = false, message = 'Player ID and new rank required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Member demoted successfully'
--     
--     local player = getPlayerObject(playerId)
--     if not player then
--         cb({ success = false, message = 'Player not found' })
--         return
--     end
--     
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = GetPlayerIdentifier(playerId, 0) or ''
--     local oldRank = 0
--     local gangName = 'none'
--     
--     local framework = getFramework()
--     if framework == 'qb' or framework == 'qbx' then
--         if player.PlayerData and player.PlayerData.gang then
--             oldRank = player.PlayerData.gang.grade?.level or player.PlayerData.gang.grade or 0
--             gangName = player.PlayerData.gang.name
--             player.PlayerData.gang.grade = {
--                 name = 'Member',
--                 level = newRank
--             }
--             TriggerClientEvent('QBCore:Client:OnGangUpdate', playerId, player.PlayerData.gang)
--             success = true
--         end
--     end
--     
--     logGangAction('demote', gangName, playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, data, oldRank, newRank, nil, success, nil)
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to demote member' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Remove gang member
-- RegisterNUICallback('jobs-gangs:removeGangMember', function(data, cb)
--     local playerId = tonumber(data.playerId)
--     local reason = data.reason or 'No reason provided'
--     
--     if not playerId then
--         cb({ success = false, message = 'Player ID required' })
--         return
--     end
--     
--     local adminInfo = { id = 'system', name = 'System' }
--     local success = false
--     local message = 'Member removed successfully'
--     
--     local player = getPlayerObject(playerId)
--     if not player then
--         cb({ success = false, message = 'Player not found' })
--         return
--     end
--     
--     local playerName = GetPlayerName(playerId) or 'Unknown'
--     local playerIdentifier = GetPlayerIdentifier(playerId, 0) or ''
--     local oldRank = 0
--     local gangName = 'none'
--     
--     local framework = getFramework()
--     if framework == 'qb' or framework == 'qbx' then
--         if player.PlayerData and player.PlayerData.gang then
--             oldRank = player.PlayerData.gang.grade?.level or player.PlayerData.gang.grade or 0
--             gangName = player.PlayerData.gang.name
--             player.PlayerData.gang = {
--                 name = 'none',
--                 label = 'None',
--                 grade = { name = 'None', level = 0 },
--                 isboss = false
--             }
--             TriggerClientEvent('QBCore:Client:OnGangUpdate', playerId, player.PlayerData.gang)
--             success = true
--         end
--     end
--     
--     logGangAction('remove', gangName, playerId, playerIdentifier, playerName, adminInfo.id, adminInfo.name, data, oldRank, 0, reason, success, nil)
--     dataCache = {}
--     
--     cb({ success = success, message = success and message or 'Failed to remove member' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Set society money
-- RegisterNUICallback('jobs-gangs:setSocietyMoney', function(data, cb)
--     local jobName = data.jobName
--     local amount = tonumber(data.amount)
--     
--     if not jobName or not amount then
--         cb({ success = false, message = 'Job name and amount required' })
--         return
--     end
--     
--     -- This would typically interact with a banking/society system
--     -- For now, just return success (implementation depends on your banking system)
--     cb({ success = true, message = 'Society money updated successfully' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Set gang money
-- RegisterNUICallback('jobs-gangs:setGangMoney', function(data, cb)
--     local gangName = data.gangName
--     local amount = tonumber(data.amount)
--     
--     if not gangName or not amount then
--         cb({ success = false, message = 'Gang name and amount required' })
--         return
--     end
--     
--     -- This would typically interact with a banking/gang system
--     -- For now, just return success (implementation depends on your banking system)
--     cb({ success = true, message = 'Gang money updated successfully' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Create job
-- RegisterNUICallback('jobs-gangs:createJob', function(data, cb)
--     local name = data.name
--     local label = data.label
--     local jobType = data.type or 'none'
--     
--     if not name or not label then
--         cb({ success = false, message = 'Job name and label required' })
--         return
--     end
--     
--     -- This would typically add to framework job config
--     -- For now, just return success (implementation depends on framework)
--     cb({ success = true, message = 'Job created successfully' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Delete job
-- RegisterNUICallback('jobs-gangs:deleteJob', function(data, cb)
--     local name = data.name
--     
--     if not name then
--         cb({ success = false, message = 'Job name required' })
--         return
--     end
--     
--     -- This would typically remove from framework job config
--     -- For now, just return success (implementation depends on framework)
--     cb({ success = true, message = 'Job deleted successfully' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Create gang
-- RegisterNUICallback('jobs-gangs:createGang', function(data, cb)
--     local name = data.name
--     local label = data.label
--     
--     if not name or not label then
--         cb({ success = false, message = 'Gang name and label required' })
--         return
--     end
--     
--     -- This would typically add to framework gang config
--     -- For now, just return success (implementation depends on framework)
--     cb({ success = true, message = 'Gang created successfully' })
-- end)

-- REMOVED: RegisterNUICallback is CLIENT-side only
-- Callback: Delete gang
-- RegisterNUICallback('jobs-gangs:deleteGang', function(data, cb)
--     local name = data.name
--     
--     if not name then
--         cb({ success = false, message = 'Gang name required' })
--         return
--     end
--     
--     -- This would typically remove from framework gang config
--     -- For now, just return success (implementation depends on framework)
--     cb({ success = true, message = 'Gang deleted successfully' })
-- end)

print("^2[Jobs & Gangs]^7 UI Backend loaded - Framework: " .. getFramework() .. "^0")

