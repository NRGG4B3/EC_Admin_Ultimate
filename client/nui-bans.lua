--[[
    EC Admin Ultimate - Bans & Warnings NUI Callbacks (CLIENT)
    Handles all ban/warning requests
]]

Logger.Info('🚫 Bans & Warnings NUI callbacks loading...')

-- ============================================================================
-- GET ALL BANS
-- ============================================================================

RegisterNUICallback('getBans', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getBans', false, data)
    end)

    if success and result then
        if type(result) == 'table' and result.success == nil then
            result.success = true
        end
        cb(result)
    else
        cb({ success = false, bans = {}, total = 0 })
    end
end)

-- ============================================================================
-- GET ALL WARNINGS
-- ============================================================================

RegisterNUICallback('getWarnings', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getWarnings', false, data)
    end)

    if success and result then
        if type(result) == 'table' and result.success == nil then
            result.success = true
        end
        cb(result)
    else
        cb({ success = false, warnings = {}, total = 0 })
    end
end)

-- ============================================================================
-- BAN ACTIONS (Server Events)
-- ============================================================================

RegisterNUICallback('createBan', function(data, cb)
    TriggerServerEvent('ec_admin:createBan', data)
    cb({ success = true })
end)

RegisterNUICallback('revokeBan', function(data, cb)
    TriggerServerEvent('ec_admin:revokeBan', data)
    cb({ success = true })
end)

RegisterNUICallback('updateBan', function(data, cb)
    TriggerServerEvent('ec_admin:updateBan', data)
    cb({ success = true })
end)

-- ============================================================================
-- WARNING ACTIONS (Server Events)
-- ============================================================================

RegisterNUICallback('createWarning', function(data, cb)
    TriggerServerEvent('ec_admin:createWarning', data)
    cb({ success = true })
end)

RegisterNUICallback('deleteWarning', function(data, cb)
    TriggerServerEvent('ec_admin:deleteWarning', data)
    cb({ success = true })
end)

-- ============================================================================
-- KICK ACTION (Server Event)
-- ============================================================================

RegisterNUICallback('kickPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:kickPlayer', data)
    cb({ success = true })
end)

Logger.Info('✅ Bans & Warnings NUI callbacks loaded')