--[[
    EC Admin Ultimate - Moderation NUI Callbacks (Client)
    Bridges UI moderation requests to server callbacks
]]

-- ============================================================================
-- MODERATION DATA
-- ============================================================================

RegisterNUICallback('moderation:getData', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getModerationData', false, data)
    end)

    if success and result then
        if result.success == nil then
            result.success = true
        end
        cb(result)
    else
        cb({ success = false, data = {}, error = 'Failed to get moderation data' })
    end
end)

-- ============================================================================
-- WARNING SYSTEM
-- ============================================================================

RegisterNUICallback('moderation:issueWarning', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:issueWarning', false, data)
    end)

    if success and result then
        if result.success == nil then
            result.success = true
        end
        cb(result)
    else
        cb({ success = false, message = 'Failed to issue warning' })
    end
end)

RegisterNUICallback('moderation:removeWarning', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:removeWarning', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to remove warning' })
    end
end)

-- ============================================================================
-- KICK & MUTE
-- ============================================================================

RegisterNUICallback('moderation:kickPlayer', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:kickPlayer', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to kick player' })
    end
end)

RegisterNUICallback('moderation:mutePlayer', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:mutePlayer', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to mute player' })
    end
end)

RegisterNUICallback('moderation:unmutePlayer', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:unmutePlayer', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to unmute player' })
    end
end)

-- ============================================================================
-- BAN MANAGEMENT
-- ============================================================================

RegisterNUICallback('moderation:banPlayer', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:banPlayer', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to ban player' })
    end
end)

RegisterNUICallback('moderation:unbanPlayer', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:unbanPlayer', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to unban player' })
    end
end)

-- ============================================================================
-- REPORTS
-- ============================================================================

RegisterNUICallback('moderation:getReports', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getReports', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, reports = {} })
    end
end)

RegisterNUICallback('moderation:updateReportStatus', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:updateReportStatus', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to update report' })
    end
end)

RegisterNUICallback('moderation:assignReport', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:assignReport', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to assign report' })
    end
end)

-- ============================================================================
-- FREEZE & SPECTATE
-- ============================================================================

RegisterNUICallback('moderation:freezePlayer', function(data, cb)
    TriggerServerEvent('ec_admin:freezePlayer', data)
    cb({ success = true })
end)

RegisterNUICallback('moderation:spectatePlayer', function(data, cb)
    TriggerServerEvent('ec_admin:spectatePlayer', data)
    cb({ success = true })
end)

Logger.Info('Moderation NUI callbacks registered')