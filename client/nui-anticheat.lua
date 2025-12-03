--[[
    EC Admin Ultimate - Anticheat NUI Callbacks (Client)
    Bridges UI anticheat requests to server callbacks
]]

-- ============================================================================
-- ANTICHEAT DATA
-- ============================================================================

RegisterNUICallback('anticheat:getData', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getAnticheatData', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, data = {}, error = 'Failed to get anticheat data' })
    end
end)

-- ============================================================================
-- AI ANALYTICS
-- ============================================================================

RegisterNUICallback('anticheat:getAIAnalytics', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getAIAnalytics', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, data = {} })
    end
end)

RegisterNUICallback('anticheat:getDetections', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getDetections', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, detections = {} })
    end
end)

-- ============================================================================
-- DETECTION MANAGEMENT
-- ============================================================================

RegisterNUICallback('anticheat:resolveDetection', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:resolveDetection', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to resolve detection' })
    end
end)

RegisterNUICallback('anticheat:dismissDetection', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:dismissDetection', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to dismiss detection' })
    end
end)

RegisterNUICallback('anticheat:escalateDetection', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:escalateDetection', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to escalate detection' })
    end
end)

-- ============================================================================
-- ANTICHEAT CONFIGURATION
-- ============================================================================

RegisterNUICallback('anticheat:updateConfig', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:updateAnticheatConfig', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to update config' })
    end
end)

RegisterNUICallback('anticheat:toggleModule', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:toggleAnticheatModule', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to toggle module' })
    end
end)

-- ============================================================================
-- PLAYER ANALYSIS
-- ============================================================================

RegisterNUICallback('anticheat:analyzePlayer', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:analyzePlayer', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, analysis = {} })
    end
end)

RegisterNUICallback('anticheat:getPlayerFlags', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getPlayerFlags', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, flags = {} })
    end
end)

-- ============================================================================
-- REACT UI COMPATIBILITY ALIASES
-- ============================================================================

-- handleDetection - generic detection handler for React UI
RegisterNUICallback('handleDetection', function(data, cb)
    local action = data.action
    local detectionId = data.detectionId
    
    local success, result = pcall(function()
        if action == 'dismiss' then
            return lib.callback.await('ec_admin:dismissDetection', false, { detectionId = detectionId })
        elseif action == 'warn' or action == 'kick' or action == 'ban' then
            return lib.callback.await('ec_admin:resolveDetection', false, { 
                detectionId = detectionId, 
                action = action 
            })
        else
            return { success = false, message = 'Invalid action' }
        end
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to handle detection' })
    end
end)

-- updateAnticheatConfig - alias for anticheat:updateConfig (React UI compatibility)
RegisterNUICallback('updateAnticheatConfig', function(data, cb)
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:updateAnticheatConfig', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        cb({ success = false, message = 'Failed to update config' })
    end
end)

Logger.Info('Anticheat NUI callbacks registered')