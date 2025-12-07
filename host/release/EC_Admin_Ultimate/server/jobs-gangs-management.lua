--[[
    EC Admin Ultimate - Jobs & Gangs Management Events
    Create, Update, Delete Jobs and Gangs dynamically
]]

Logger.Info('💼 Loading Jobs & Gangs Management Events...')

-- ============================================================================
-- CREATE JOB
-- ============================================================================

RegisterServerEvent('ec_admin:createJob')
AddEventHandler('ec_admin:createJob', function(data)
    local source = source
    local jobName = data.name
    local jobLabel = data.label or jobName
    local jobType = data.type or 'none'
    
    if not jobName then
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'error',
            title = 'Error',
            message = 'Job name is required'
        })
        return
    end
    
    -- Check framework
    local frameworkType = nil
    local Framework = nil
    
    if GetResourceState('qbx_core') == 'started' then
        frameworkType = 'qbx'
        Framework = exports.qbx_core
    elseif GetResourceState('qb-core') == 'started' then
        frameworkType = 'qb'
        Framework = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        frameworkType = 'esx'
        Framework = exports['es_extended']:getSharedObject()
    end
    
    if frameworkType == 'qb' or frameworkType == 'qbx' then
        -- Add to QB-Core Shared.Jobs
        local SharedJobs = nil
        
        if frameworkType == 'qbx' then
            -- QBX doesn't use Shared.Jobs - skip or use different method
            Logger.Info('QBX doesn\'t support runtime job creation - jobs must be added to qbx_core/shared/jobs.lua')
            return { success = false, message = 'QBX requires manual job configuration in qbx_core/shared/jobs.lua' }
        elseif Framework and Framework.Shared and Framework.Shared.Jobs then
            -- QB-Core uses Framework.Shared.Jobs
            Framework.Shared.Jobs[jobName] = {
                label = jobLabel,
                type = jobType,
                defaultduty = true,
                offDutyPay = false,
                grades = {
                    ['0'] = { name = 'Trainee', payment = 50 },
                    ['1'] = { name = 'Employee', payment = 100 },
                    ['2'] = { name = 'Supervisor', payment = 150 },
                    ['3'] = { name = 'Manager', payment = 200 },
                    ['4'] = { name = 'Boss', isboss = true, payment = 250 }
                }
            }
            
            TriggerClientEvent('ec_admin:notify', source, {
                type = 'success',
                title = 'Success',
                message = string.format('Job "%s" created successfully', jobLabel)
            })
            
            Logger.Info(string.format('', jobLabel, jobName))
        end
        
    elseif frameworkType == 'esx' then
        -- Insert into ESX jobs table
        MySQL.insert('INSERT INTO jobs (name, label) VALUES (?, ?)', {jobName, jobLabel}, function(id)
            if id then
                -- Create default grades
                for i = 0, 4 do
                    local gradeName = ({'Trainee', 'Employee', 'Supervisor', 'Manager', 'Boss'})[i + 1]
                    local salary = (i + 1) * 50
                    MySQL.insert('INSERT INTO job_grades (job_name, grade, name, label, salary) VALUES (?, ?, ?, ?, ?)', 
                        {jobName, i, gradeName, gradeName, salary})
                end
                
                TriggerClientEvent('ec_admin:notify', source, {
                    type = 'success',
                    title = 'Success',
                    message = string.format('Job "%s" created successfully', jobLabel)
                })
                
                Logger.Info(string.format('', jobLabel, jobName))
            end
        end)
    end
end)

-- ============================================================================
-- DELETE JOB
-- ============================================================================

RegisterServerEvent('ec_admin:deleteJob')
AddEventHandler('ec_admin:deleteJob', function(data)
    local source = source
    local jobName = data.name
    
    if not jobName then return end
    
    -- Check framework
    local frameworkType = nil
    local Framework = nil
    
    if GetResourceState('qbx_core') == 'started' then
        frameworkType = 'qbx'
        Framework = exports.qbx_core
    elseif GetResourceState('qb-core') == 'started' then
        frameworkType = 'qb'
        Framework = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        frameworkType = 'esx'
        Framework = exports['es_extended']:getSharedObject()
    end
    
    if frameworkType == 'qb' or frameworkType == 'qbx' then
        -- Remove from QB-Core Shared.Jobs
        if Framework.Shared and Framework.Shared.Jobs then
            Framework.Shared.Jobs[jobName] = nil
            
            -- Set all players with this job to unemployed
            for _, playerId in ipairs(GetPlayers()) do
                local Player = Framework.Functions.GetPlayer(tonumber(playerId))
                if Player and Player.PlayerData.job and Player.PlayerData.job.name == jobName then
                    Player.Functions.SetJob('unemployed', 0)
                end
            end
            
            TriggerClientEvent('ec_admin:notify', source, {
                type = 'success',
                title = 'Success',
                message = string.format('Job "%s" deleted', jobName)
            })
            
            Logger.Info(string.format('', jobName))
        end
        
    elseif frameworkType == 'esx' then
        -- Delete from ESX database
        MySQL.query('DELETE FROM job_grades WHERE job_name = ?', {jobName})
        MySQL.query('DELETE FROM jobs WHERE name = ?', {jobName}, function(affectedRows)
            if affectedRows > 0 then
                TriggerClientEvent('ec_admin:notify', source, {
                    type = 'success',
                    title = 'Success',
                    message = string.format('Job "%s" deleted', jobName)
                })
                
                Logger.Info(string.format('', jobName))
            end
        end)
    end
end)

-- ============================================================================
-- CREATE GANG
-- ============================================================================

RegisterServerEvent('ec_admin:createGang')
AddEventHandler('ec_admin:createGang', function(data)
    local source = source
    local gangName = data.name
    local gangLabel = data.label or gangName
    
    if not gangName then
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'error',
            title = 'Error',
            message = 'Gang name is required'
        })
        return
    end
    
    -- Check framework (gangs only on QB)
    local frameworkType = nil
    local Framework = nil
    
    if GetResourceState('qbx_core') == 'started' then
        frameworkType = 'qbx'
        Framework = exports.qbx_core
    elseif GetResourceState('qb-core') == 'started' then
        frameworkType = 'qb'
        Framework = exports['qb-core']:GetCoreObject()
    end
    
    if frameworkType == 'qb' or frameworkType == 'qbx' then
        -- Add to QB-Core Shared.Gangs
        if Framework.Shared and Framework.Shared.Gangs then
            Framework.Shared.Gangs[gangName] = {
                label = gangLabel,
                grades = {
                    ['0'] = { name = 'Recruit' },
                    ['1'] = { name = 'Member' },
                    ['2'] = { name = 'Enforcer' },
                    ['3'] = { name = 'Lieutenant', isboss = true },
                    ['4'] = { name = 'Boss', isboss = true }
                }
            }
            
            TriggerClientEvent('ec_admin:notify', source, {
                type = 'success',
                title = 'Success',
                message = string.format('Gang "%s" created successfully', gangLabel)
            })
            
            Logger.Info(string.format('', gangLabel, gangName))
        end
    else
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'error',
            title = 'Error',
            message = 'Gangs are only supported on QB-Core/QBX'
        })
    end
end)

-- ============================================================================
-- DELETE GANG
-- ============================================================================

RegisterServerEvent('ec_admin:deleteGang')
AddEventHandler('ec_admin:deleteGang', function(data)
    local source = source
    local gangName = data.name
    
    if not gangName then return end
    
    -- Check framework
    local frameworkType = nil
    local Framework = nil
    
    if GetResourceState('qbx_core') == 'started' then
        frameworkType = 'qbx'
        Framework = exports.qbx_core
    elseif GetResourceState('qb-core') == 'started' then
        frameworkType = 'qb'
        Framework = exports['qb-core']:GetCoreObject()
    end
    
    if frameworkType == 'qb' or frameworkType == 'qbx' then
        -- Remove from QB-Core Shared.Gangs
        if Framework.Shared and Framework.Shared.Gangs then
            Framework.Shared.Gangs[gangName] = nil
            
            -- Remove all players from this gang
            for _, playerId in ipairs(GetPlayers()) do
                local Player = Framework.Functions.GetPlayer(tonumber(playerId))
                if Player and Player.PlayerData.gang and Player.PlayerData.gang.name == gangName then
                    Player.Functions.SetGang('none', 0)
                end
            end
            
            TriggerClientEvent('ec_admin:notify', source, {
                type = 'success',
                title = 'Success',
                message = string.format('Gang "%s" deleted', gangName)
            })
            
            Logger.Info(string.format('', gangName))
        end
    end
end)

-- ============================================================================
-- SET SOCIETY MONEY
-- ============================================================================

RegisterServerEvent('ec_admin:setSocietyMoney')
AddEventHandler('ec_admin:setSocietyMoney', function(data)
    local source = source
    local jobName = data.jobName
    local amount = tonumber(data.amount)
    
    if not jobName or not amount then return end
    
    -- Check for management resources
    if GetResourceState('qb-management') == 'started' then
        -- QB Management
        exports['qb-management']:AddMoney(jobName, amount)
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'success',
            title = 'Success',
            message = string.format('Set %s society money to $%d', jobName, amount)
        })
    elseif GetResourceState('esx_society') == 'started' then
        -- ESX Society
        TriggerEvent('esx_society:setMoney', jobName, amount)
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'success',
            title = 'Success',
            message = string.format('Set %s society money to $%d', jobName, amount)
        })
    else
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'error',
            title = 'Error',
            message = 'No society management resource found'
        })
    end
end)

-- ============================================================================
-- SET GANG MONEY
-- ============================================================================

RegisterServerEvent('ec_admin:setGangMoney')
AddEventHandler('ec_admin:setGangMoney', function(data)
    local source = source
    local gangName = data.gangName
    local amount = tonumber(data.amount)
    
    if not gangName or not amount then return end
    
    -- Check for gang management resources
    if GetResourceState('qb-gangs') == 'started' then
        exports['qb-gangs']:SetMoney(gangName, amount)
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'success',
            title = 'Success',
            message = string.format('Set %s gang money to $%d', gangName, amount)
        })
    else
        TriggerClientEvent('ec_admin:notify', source, {
            type = 'warning',
            title = 'Warning',
            message = 'No gang management resource found'
        })
    end
end)

Logger.Info('✅ Jobs & Gangs Management Events loaded!')