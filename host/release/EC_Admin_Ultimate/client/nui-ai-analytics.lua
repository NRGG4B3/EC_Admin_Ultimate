--[[
    EC Admin Ultimate - AI Analytics NUI Callbacks (Client)
]]

-- Get AI analytics data
RegisterNUICallback('aiAnalytics:getData', function(data, cb)
    -- Use modern callback with fallback
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getAIAnalytics', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        -- Fallback to legacy event
        TriggerServerEvent('ec_admin_ultimate:server:getAIAnalytics')
        cb({ success = true })
    end
end)

-- Export report
RegisterNUICallback('aiAnalytics:exportReport', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:exportAIReport', data)
    cb({ success = true })
end)

-- Receive AI analytics data
RegisterNetEvent('ec_admin_ultimate:client:receiveAIAnalytics', function(result)
    SendNUIMessage({
        action = 'aiAnalyticsData',
        data = result
    })
end)

-- Receive generated report
RegisterNetEvent('ec_admin_ultimate:client:aiReportGenerated', function(result)
    SendNUIMessage({
        action = 'aiReportGenerated',
        data = result
    })
end)

Logger.Info('AI Analytics NUI callbacks loaded')
