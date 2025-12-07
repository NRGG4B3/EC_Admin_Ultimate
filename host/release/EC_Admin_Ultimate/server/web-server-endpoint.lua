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

Logger.Info('[EC Admin Web] Initializing web access command...')

-- Check if this is a host installation
local isHost = false
local hostFile = LoadResourceFile(GetCurrentResourceName(), 'host/setup.bat')
if hostFile then
    isHost = true
    Logger.Warn('[EC Admin Web] HOST MODE DETECTED')
else
    Logger.Success('[EC Admin Web] Customer mode - web access enabled')
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
            Logger.Error(('[EC Admin Web] Permission check failed: %s'):format(result))
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
        
        Logger.Info(('✅ %s requested web access'):format(GetPlayerName(player)))
    else
        -- Server console
        Logger.Info('════════════════════════════════════════════════════════')
        Logger.Info('  EC ADMIN ULTIMATE - WEB ACCESS URLS')
        Logger.Info('════════════════════════════════════════════════════════')
        Logger.Info(('  Local:   %s'):format(localUrl))
        Logger.Info(('  Network: %s'):format(webUrl))
        Logger.Info('════════════════════════════════════════════════════════')
        
        if isHost then
            Logger.Warn('  HOST MODE: Use http://127.0.0.1:3019 instead')
            Logger.Info('════════════════════════════════════════════════════════')
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

Logger.Success('[EC Admin Web] Commands registered: /webadmin, /ecweb')

-- ==========================================
-- STARTUP INFO
-- ==========================================

CreateThread(function()
    -- Wait for resource to fully load
    Wait(3000)
    
    if not isHost then
        Logger.Info('')
        Logger.Info('╔═════════════════════════════════════════════════════════════╗')
        Logger.Info('║                                                             ║')
        Logger.Info('║  🌐 EC ADMIN ULTIMATE - WEB ACCESS READY!                  ║')
        Logger.Info('║                                                             ║')
        Logger.Info('╠═════════════════════════════════════════════════════════════╣')
        Logger.Info('║                                                             ║')
        Logger.Info('║  📱 Access Methods:                                         ║')
        Logger.Info('║     • Type /webadmin in chat or console                    ║')
        Logger.Info('║     • Press F2 for in-game menu                            ║')
        Logger.Info('║                                                             ║')
        Logger.Info('║  🔗 Direct Links:                                           ║')
        Logger.Info(('║     Local:   %-46s║'):format(localUrl:sub(1, 46)))
        if #localUrl > 46 then
            Logger.Info(('║              %-46s║'):format(localUrl:sub(47)))
        end
        Logger.Info('║                                                             ║')
        Logger.Info(('║     Network: %-46s║'):format(webUrl:sub(1, 46)))
        if #webUrl > 46 then
            Logger.Info(('║              %-46s║'):format(webUrl:sub(47)))
        end
        Logger.Info('║                                                             ║')
        Logger.Info('║  ⚡ Features:                                                ║')
        Logger.Info('║     • No Node.js required!                                  ║')
        Logger.Info('║     • No setup or installation!                             ║')
        Logger.Info('║     • Real-time sync with in-game admins                    ║')
        Logger.Info('║     • Access from any browser                               ║')
        Logger.Info('║     • Mobile friendly                                       ║')
        Logger.Info('║                                                             ║')
        Logger.Info('╚═════════════════════════════════════════════════════════════╝')
        Logger.Info('')
    else
        Logger.Info('')
        Logger.Warn('╔═════════════════════════════════════════════════════════════╗')
        Logger.Warn('║  HOST MODE - NRG Internal Dashboard                        ║')
        Logger.Warn('╠═════════════════════════════════════════════════════════════╣')
        Logger.Warn('║  Your Dashboard: http://127.0.0.1:3019                       ║')
        Logger.Warn('║  Customer Command: /webadmin                                ║')
        Logger.Warn('╚═════════════════════════════════════════════════════════════╝')
        Logger.Info('')
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

Logger.Success('[EC Admin Web] Web access initialized successfully!')