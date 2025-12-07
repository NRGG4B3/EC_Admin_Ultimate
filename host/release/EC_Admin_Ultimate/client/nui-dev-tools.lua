--[[
    EC Admin Ultimate - Dev Tools NUI Callbacks (Client)
]]

-- Get dev tools data
RegisterNUICallback('devTools:getData', function(data, cb)
    -- Use modern callback with fallback
    local success, result = pcall(function()
        return lib.callback.await('ec_admin:getDevToolsData', false, data)
    end)
    
    if success and result then
        cb(result)
    else
        -- Fallback to legacy event
        TriggerServerEvent('ec_admin_ultimate:server:getDevToolsData')
        cb({ success = true })
    end
end)

-- Save script
RegisterNUICallback('devTools:saveScript', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:saveScript', data)
    cb({ success = true })
end)

-- Delete script
RegisterNUICallback('devTools:deleteScript', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:deleteScript', data)
    cb({ success = true })
end)

-- Execute script
RegisterNUICallback('devTools:executeScript', function(data, cb)
    local scriptType = data.scriptType
    local scriptContent = data.scriptContent
    
    if scriptType == 'client' then
        -- Execute client-side script
        local success, err = pcall(function()
            load(scriptContent)()
        end)
        
        if success then
            cb({ 
                success = true, 
                message = 'Client script executed successfully' 
            })
        else
            cb({ 
                success = false, 
                message = 'Script execution failed: ' .. tostring(err)
            })
        end
    else
        -- Send to server for execution
        TriggerServerEvent('ec_admin_ultimate:server:executeScript', data)
        cb({ success = true })
    end
end)

-- Save resource
RegisterNUICallback('devTools:saveResource', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:saveResource', data)
    cb({ success = true })
end)

-- Log console message
RegisterNUICallback('devTools:logConsole', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:logConsole', data)
    cb({ success = true })
end)

-- Clear console logs
RegisterNUICallback('devTools:clearConsoleLogs', function(data, cb)
    TriggerServerEvent('ec_admin_ultimate:server:clearConsoleLogs')
    cb({ success = true })
end)

-- Receive dev tools data
RegisterNetEvent('ec_admin_ultimate:client:receiveDevToolsData', function(result)
    SendNUIMessage({
        action = 'devToolsData',
        data = result
    })
end)

-- Receive dev tools response
RegisterNetEvent('ec_admin_ultimate:client:devToolsResponse', function(result)
    SendNUIMessage({
        action = 'devToolsResponse',
        data = result
    })
end)

-- Execute client script (from server)
RegisterNetEvent('ec_admin_ultimate:client:executeClientScript', function(data)
    local script = data.script
    
    local success, err = pcall(function()
        load(script)()
    end)
    
    if not success then
        print('[EC Admin Dev Tools] Client script error:', err)
    end
end)

Logger.Info('Dev Tools NUI callbacks loaded')
