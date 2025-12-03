--[[
    EC Admin Ultimate - AI Detection NUI Callbacks (Client)
]]

-- Get AI detection data
RegisterNUICallback('aiDetection:getData', function(data, cb)
    -- Use modern callback with fallback
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getAIDetectionData', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        -- Fallback to legacy event
        TriggerServerEvent('ec_admin_ultimate:server:getAIDetectionData')
        cb({ success = true })
    end
end)

-- Log behavior
RegisterNUICallback('aiDetection:logBehavior', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:logBehavior', data)
    cb({ success = true })
end)

-- Analyze player
RegisterNUICallback('aiDetection:analyzePlayer', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:analyzePlayer', data)
    cb({ success = true })
end)

-- Mark as bot
RegisterNUICallback('aiDetection:markAsBot', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:markAsBot', data)
    cb({ success = true })
end)

-- Clear bot flag
RegisterNUICallback('aiDetection:clearBotFlag', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:clearBotFlag', data)
    cb({ success = true })
end)

-- Receive AI detection data
RegisterNetEvent('ec_admin_ultimate:client:receiveAIDetectionData', function(result)
    SendNUIMessage({
        action = 'aiDetectionData',
        data = result
    })
end)

-- Receive AI detection response
RegisterNetEvent('ec_admin_ultimate:client:aiDetectionResponse', function(result)
    SendNUIMessage({
        action = 'aiDetectionResponse',
        data = result
    })
end)

-- Receive AI detection alert
RegisterNetEvent('ec_admin_ultimate:client:aiDetectionAlert', function(data)
    SendNUIMessage({
        action = 'aiDetectionAlert',
        data = data
    })
    
    -- Show notification
    if exports['ec_admin_ultimate'] then
        exports['ec_admin_ultimate']:ShowNotification({
            title = '🤖 AI Detection Alert',
            message = data.playerName .. ' - ' .. data.detectionType .. ' (' .. math.floor(data.confidence * 100) .. '%)',
            type = 'warning',
            duration = 8000
        })
    end
end)

Logger.Info('AI Detection NUI callbacks loaded')
