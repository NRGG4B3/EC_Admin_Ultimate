--[[
    EC Admin Ultimate - Reports NUI Callbacks (CLIENT)
    Handles all player report requests
]]

Logger.Info('📋 Reports NUI callbacks loading...')

-- ============================================================================
-- GET ALL REPORTS
-- ============================================================================

RegisterNUICallback('getReports', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getReports', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, reports = {}, total = 0 })
    end
end)

-- ============================================================================
-- GET REPORT DETAILS
-- ============================================================================

RegisterNUICallback('getReportDetails', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getReportDetails', false, data.reportId)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false })
    end
end)

-- ============================================================================
-- REPORT ACTIONS (Server Events)
-- ============================================================================

RegisterNUICallback('createReport', function(data, cb)
    TriggerServerEvent('ec_admin:createReport', data)
    cb({ success = true })
end)

RegisterNUICallback('closeReport', function(data, cb)
    TriggerServerEvent('ec_admin:closeReport', data)
    cb({ success = true })
end)

RegisterNUICallback('assignReport', function(data, cb)
    TriggerServerEvent('ec_admin:assignReport', data)
    cb({ success = true })
end)

RegisterNUICallback('updateReportStatus', function(data, cb)
    TriggerServerEvent('ec_admin:updateReportStatus', data)
    cb({ success = true })
end)

RegisterNUICallback('deleteReport', function(data, cb)
    TriggerServerEvent('ec_admin:deleteReport', data)
    cb({ success = true })
end)

Logger.Info('✅ Reports NUI callbacks loaded')
