--[[
    EC Admin Ultimate - Jobs & Gangs NUI Callbacks (CLIENT)
    Handles all jobs and gangs management with database auto-detection
]]

Logger.Info('💼 Jobs & Gangs NUI callbacks loading...')

-- ============================================================================
-- GET JOBS & GANGS DATA
-- ============================================================================

RegisterNUICallback('jobs-gangs:getData', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getJobsGangsData', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, data = {} })
    end
end)

-- ============================================================================
-- JOB MANAGEMENT
-- ============================================================================

RegisterNUICallback('jobs-gangs:createJob', function(data, cb)
    TriggerServerEvent('ec_admin:createJob', data)
    cb({ success = true })
end)

RegisterNUICallback('jobs-gangs:deleteJob', function(data, cb)
    TriggerServerEvent('ec_admin:deleteJob', data)
    cb({ success = true })
end)

RegisterNUICallback('jobs-gangs:updateJob', function(data, cb)
    TriggerServerEvent('ec_admin:updateJob', data)
    cb({ success = true })
end)

-- ============================================================================
-- EMPLOYEE MANAGEMENT
-- ============================================================================

RegisterNUICallback('jobs-gangs:hirePlayer', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:hirePlayer', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to hire player' })
    end
end)

RegisterNUICallback('jobs-gangs:firePlayer', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:firePlayer', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to fire player' })
    end
end)

RegisterNUICallback('jobs-gangs:promoteEmployee', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:promoteEmployee', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to promote employee' })
    end
end)

RegisterNUICallback('jobs-gangs:demoteEmployee', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:demoteEmployee', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to demote employee' })
    end
end)

RegisterNUICallback('jobs-gangs:setGrade', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:setEmployeeGrade', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to set grade' })
    end
end)

-- ============================================================================
-- GANG MANAGEMENT
-- ============================================================================

RegisterNUICallback('jobs-gangs:createGang', function(data, cb)
    TriggerServerEvent('ec_admin:createGang', data)
    cb({ success = true })
end)

RegisterNUICallback('jobs-gangs:deleteGang', function(data, cb)
    TriggerServerEvent('ec_admin:deleteGang', data)
    cb({ success = true })
end)

RegisterNUICallback('jobs-gangs:updateGang', function(data, cb)
    TriggerServerEvent('ec_admin:updateGang', data)
    cb({ success = true })
end)

-- ============================================================================
-- GANG MEMBER MANAGEMENT
-- ============================================================================

RegisterNUICallback('jobs-gangs:recruitMember', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:recruitGangMember', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to recruit member' })
    end
end)

RegisterNUICallback('jobs-gangs:removeMember', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:removeGangMember', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to remove member' })
    end
end)

RegisterNUICallback('jobs-gangs:promoteGangMember', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:promoteGangMember', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to promote member' })
    end
end)

RegisterNUICallback('jobs-gangs:demoteGangMember', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:demoteGangMember', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to demote member' })
    end
end)

RegisterNUICallback('jobs-gangs:setGangRank', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:setGangMemberRank', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to set rank' })
    end
end)

-- ============================================================================
-- SOCIETY/GANG MONEY
-- ============================================================================

RegisterNUICallback('jobs-gangs:setSocietyMoney', function(data, cb)
    TriggerServerEvent('ec_admin:setSocietyMoney', data)
    cb({ success = true })
end)

RegisterNUICallback('jobs-gangs:setGangMoney', function(data, cb)
    TriggerServerEvent('ec_admin:setGangMoney', data)
    cb({ success = true })
end)

-- ============================================================================
-- REACT UI COMPATIBILITY ALIASES
-- ============================================================================

-- Alias: fireEmployee (React UI uses this instead of firePlayer)
RegisterNUICallback('jobs-gangs:fireEmployee', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:firePlayer', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to fire employee' })
    end
end)

-- Alias: recruitGangMember (React UI uses this instead of recruitMember)
RegisterNUICallback('jobs-gangs:recruitGangMember', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:recruitGangMember', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to recruit gang member' })
    end
end)

-- Alias: removeGangMember (React UI uses this instead of removeMember)
RegisterNUICallback('jobs-gangs:removeGangMember', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:removeGangMember', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to remove gang member' })
    end
end)

Logger.Info('✅ Jobs & Gangs NUI callbacks loaded')