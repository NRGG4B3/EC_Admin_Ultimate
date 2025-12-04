--[[
    EC Admin Ultimate - Monitoring NUI Callbacks (CLIENT)
    Server performance and resource monitoring
]]

Logger.Info('📊 Server Monitoring NUI callbacks loading...')

-- ============================================================================
-- GET MONITORING DATA
-- ============================================================================

RegisterNUICallback('getMonitoring', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getMonitoring', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, resources = {}, performance = {} })
    end
end)

-- ============================================================================
-- RESTART RESOURCE
-- ============================================================================

RegisterNUICallback('restartResource', function(data, cb)
    TriggerServerEvent('ec_admin:restartResource', data)
    cb({ success = true })
end)

-- ============================================================================
-- STOP RESOURCE
-- ============================================================================

RegisterNUICallback('stopResource', function(data, cb)
    TriggerServerEvent('ec_admin:stopResource', data)
    cb({ success = true })
end)

-- ============================================================================
-- START RESOURCE
-- ============================================================================

RegisterNUICallback('startResource', function(data, cb)
    TriggerServerEvent('ec_admin:startResource', data)
    cb({ success = true })
end)

Logger.Info('✅ Server Monitoring NUI callbacks loaded')
