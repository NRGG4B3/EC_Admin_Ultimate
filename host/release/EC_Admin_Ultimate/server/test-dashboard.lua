-- Test Dashboard Connection
-- Run: /test:dashboard

TriggerEvent('chat:addSuggestion', '/test:dashboard', 'Test dashboard callbacks')

RegisterCommand('test:dashboard', function(source, args, rawCommand)
    local player = source
    
    print('^2[TEST] Dashboard Connection Test^7')
    print('^3Testing ec_admin:getServerMetrics...^7')
    
    lib.callback('ec_admin:getServerMetrics', player, function(result)
        if result then
            print('^2[TEST] ✅ Metrics retrieved:^7')
            print(json.encode(result))
        else
            print('^1[TEST] ❌ Metrics call failed^7')
        end
    end)
    
    SetTimeout(2000, function()
        print('^3Testing ec_admin:getAIAnalytics...^7')
        lib.callback('ec_admin:getAIAnalytics', player, function(result)
            if result then
                print('^2[TEST] ✅ AI Analytics retrieved:^7')
                print(json.encode(result))
            else
                print('^1[TEST] ❌ AI Analytics call failed^7')
            end
        end)
    end)
    
end, false)
