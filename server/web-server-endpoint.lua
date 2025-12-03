--[[
    EC Admin Ultimate - Web Access Command
    
    Allows customers to access their admin panel from a web browser
    WITHOUT needing Node.js, npm, or any external setup!
    
    How it works:
    1. Customer types /webadmin in console, chat, or F8
    2. Gets a clickable link that opens in browser
    3. Full admin panel in browser with real-time data
    
    For Host (NRG):
    - Your multi-port-server.js serves on port 3019
    - You see ALL cities and ALL APIs
    
    For Customers:
    - Just type /webadmin to get the link
    - Opens NUI in browser tab
    - They see THEIR city only
]]

print('^2[EC Admin Web] Initializing web access command...^0')

-- Check if this is a host installation
local isHost = false
local hostFile = LoadResourceFile(GetCurrentResourceName(), 'host/setup.bat')
if hostFile then
    isHost = true
    print('^3[EC Admin Web] HOST MODE DETECTED^0')
else
    print('^2[EC Admin Web] Customer mode - web access enabled^0')
end

-- Get server info
local serverIp = GetConvar('ec_server_ip', '127.0.0.1')
local serverPort = GetConvar('sv_port', '30120')
local serverName = GetConvar('sv_hostname', 'FiveM Server')
local resourceName = GetCurrentResourceName()

-- Construct web URL
-- FiveM serves resource files at: http://IP:PORT/RESOURCE_NAME/FILE_PATH
local webUrl = string.format('http://%s:%s/%s/ui/dist/index.html', serverIp, serverPort, resourceName)

-- Alternative localhost URL for local testing
local localUrl = string.format('http://127.0.0.1:%s/%s/ui/dist/index.html', serverPort, resourceName)

-- ==========================================
-- COMMANDS
-- ==========================================

-- Customer command: /webadmin
RegisterCommand('webadmin', function(source, args, rawCommand)
    local player = source
    
    -- Check if player has admin permission
    if player > 0 then
        local hasPermission = false

        -- Use the current resource name to call our export safely (case-sensitive on some setups)
        local ok, result = pcall(function()
            if exports[resourceName] and exports[resourceName].HasPermission then
                return exports[resourceName]:HasPermission(player)
            end
            return false
        end)

        if ok then
            hasPermission = result and true or false
        else
            print(('^1[EC Admin Web] Permission check failed: %s^0'):format(result))
        end
        
        if not hasPermission then
            TriggerClientEvent('chat:addMessage', player, {
                color = { 255, 0, 0 },
                multiline = true,
                args = { "[EC Admin]", "You don't have permission to access the web admin panel!" }
            })
            return
        end
        
        -- Send clickable link to player
        TriggerClientEvent('chat:addMessage', player, {
            color = { 0, 255, 127 },
            multiline = true,
            args = { "[EC Admin]", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" }
        })
        
        TriggerClientEvent('chat:addMessage', player, {
            color = { 0, 255, 127 },
            multiline = true,
            args = { "[EC Admin]", "🌐 WEB ADMIN ACCESS" }
        })
        
        TriggerClientEvent('chat:addMessage', player, {
            color = { 255, 255, 255 },
            multiline = true,
            args = { "", "Click to open: " .. localUrl }
        })
        
        TriggerClientEvent('chat:addMessage', player, {
            color = { 255, 255, 255 },
            multiline = true,
            args = { "", "Network: " .. webUrl }
        })
        
        TriggerClientEvent('chat:addMessage', player, {
            color = { 0, 255, 127 },
            multiline = true,
            args = { "[EC Admin]", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" }
        })
        
        -- Also send as notification
        if GetResourceState(resourceName) == 'started' then
            TriggerClientEvent('ec_admin:notify', player, {
                title = 'EC Admin Web',
                message = 'Web admin link sent to chat! Click to open in browser.',
                type = 'success'
            })
        end
        
        print(string.format('^2[EC Admin Web] %s requested web access^0', GetPlayerName(player)))
    else
        -- Server console
        print('^2════════════════════════════════════════════════════════^0')
        print('^2  EC ADMIN ULTIMATE - WEB ACCESS URLS^0')
        print('^2════════════════════════════════════════════════════════^0')
        print(string.format('^3  Local:   %s^0', localUrl))
        print(string.format('^3  Network: %s^0', webUrl))
        print('^2════════════════════════════════════════════════════════^0')
        
        if isHost then
            print('^3  HOST MODE: Use http://127.0.0.1:3019 instead^0')
            print('^2════════════════════════════════════════════════════════^0')
        end
    end
end, false)

-- Add command suggestion
TriggerEvent('chat:addSuggestion', '/webadmin', 'Get link to open admin panel in browser')

-- Alternative alias
RegisterCommand('ecweb', function(source, args, rawCommand)
    ExecuteCommand('webadmin')
end, false)

TriggerEvent('chat:addSuggestion', '/ecweb', 'Get link to open admin panel in browser (alias)')

print('^2[EC Admin Web] Commands registered: /webadmin, /ecweb^0')

-- ==========================================
-- STARTUP INFO
-- ==========================================

Citizen.CreateThread(function()
    -- Wait for resource to fully load
    Wait(3000)
    
    if not isHost then
        print('')
        print('^2╔═════════════════════════════════════════════════════════════╗^0')
        print('^2║                                                             ║^0')
        print('^2║  🌐 EC ADMIN ULTIMATE - WEB ACCESS READY!                  ║^0')
        print('^2║                                                             ║^0')
        print('^2╠═════════════════════════════════════════════════════════════╣^0')
        print('^2║                                                             ║^0')
        print('^2║  📱 Access Methods:                                         ║^0')
        print('^2║     • Type ^3/webadmin^2 in chat or console                    ║^0')
        print('^2║     • Press ^3F2^2 for in-game menu                            ║^0')
        print('^2║                                                             ║^0')
        print('^2║  🔗 Direct Links:                                           ║^0')
        print(string.format('^2║     Local:   ^3%-46s^2║^0', localUrl:sub(1, 46)))
        if #localUrl > 46 then
            print(string.format('^2║              ^3%-46s^2║^0', localUrl:sub(47)))
        end
        print('^2║                                                             ║^0')
        print(string.format('^2║     Network: ^3%-46s^2║^0', webUrl:sub(1, 46)))
        if #webUrl > 46 then
            print(string.format('^2║              ^3%-46s^2║^0', webUrl:sub(47)))
        end
        print('^2║                                                             ║^0')
        print('^2║  ⚡ Features:                                                ║^0')
        print('^2║     • No Node.js required!                                  ║^0')
        print('^2║     • No setup or installation!                             ║^0')
        print('^2║     • Real-time sync with in-game admins                    ║^0')
        print('^2║     • Access from any browser                               ║^0')
        print('^2║     • Mobile friendly                                       ║^0')
        print('^2║                                                             ║^0')
        print('^2╚═════════════════════════════════════════════════════════════╝^0')
        print('')
    else
        print('')
        print('^3╔═════════════════════════════════════════════════════════════╗^0')
        print('^3║  HOST MODE - NRG Internal Dashboard                        ║^0')
        print('^3╠═════════════════════════════════════════════════════════════╣^0')
        print('^3║  Your Dashboard: ^2http://127.0.0.1:3019^3                       ║^0')
        print('^3║  Customer Command: ^2/webadmin^3                                ║^0')
        print('^3╚═════════════════════════════════════════════════════════════╝^0')
        print('')
    end
end)

-- ==========================================
-- MODE DETECTION FOR UI
-- ==========================================

-- Callback for UI to detect mode
lib.callback.register('ec_admin:getWebConfig', function(source)
    return {
        mode = isHost and 'host' or 'customer',
        isHost = isHost,
        webAccess = true,
        serverName = serverName,
        serverIp = serverIp,
        serverPort = serverPort,
        localUrl = localUrl,
        networkUrl = webUrl
    }
end)

print('^2[EC Admin Web] Web access initialized successfully!^0')