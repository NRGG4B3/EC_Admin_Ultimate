-- ============================================================================
-- EC ADMIN ULTIMATE - CLIENT-SIDE ACTION LOGGER
-- ============================================================================
-- Captures ALL UI interactions and sends to server for logging
-- Logs every click, page change, and menu interaction
-- ============================================================================

Logger.Info('📋 Client-Side Action Logger - Loading...')

local ClientLogger = {}
ClientLogger.currentPage = 'dashboard'
ClientLogger.menuOpen = false

-- ============================================================================
-- LOG MENU CLICK (Every Button/Element Click in UI)
-- ============================================================================
function ClientLogger.LogClick(button, component)
    if not Config.Discord or not Config.Discord.consoleLogging or not Config.Discord.consoleLogging.logMenuClicks then
        return
    end
    
    TriggerServerEvent('ec_admin:log:menuClick', button, ClientLogger.currentPage, component or 'unknown')
    Logger.Debug(string.format('🖱️ UI Click: %s on %s', button, ClientLogger.currentPage))
end

-- ============================================================================
-- LOG PAGE CHANGE (Navigation Between Menu Pages)
-- ============================================================================
function ClientLogger.LogPageChange(newPage)
    if not Config.Discord or not Config.Discord.consoleLogging or not Config.Discord.consoleLogging.logMenuNavigation then
        return
    end
    
    local oldPage = ClientLogger.currentPage
    TriggerServerEvent('ec_admin:log:pageChange', oldPage, newPage)
    Logger.Debug(string.format('📄 Page Change: %s → %s', oldPage, newPage))
    ClientLogger.currentPage = newPage
end

-- ============================================================================
-- LOG MENU OPEN
-- ============================================================================
function ClientLogger.LogMenuOpen()
    if ClientLogger.menuOpen then
        return  -- Already logged
    end
    
    ClientLogger.menuOpen = true
    TriggerServerEvent('ec_admin:log:menuOpen')
    Logger.Debug('🎮 Admin Menu Opened')
end

-- ============================================================================
-- LOG MENU CLOSE
-- ============================================================================
function ClientLogger.LogMenuClose()
    if not ClientLogger.menuOpen then
        return  -- Already logged
    end
    
    ClientLogger.menuOpen = false
    TriggerServerEvent('ec_admin:log:menuClose')
    Logger.Debug('🎮 Admin Menu Closed')
end

-- ============================================================================
-- LOG PLAYER SELECTION (When Admin Clicks on a Player)
-- ============================================================================
function ClientLogger.LogPlayerSelect(targetId, targetName)
    TriggerServerEvent('ec_admin:log:playerSelect', targetId, targetName)
    Logger.Debug(string.format('👤 Player Selected: %s [%s]', targetName, targetId))
end

-- ============================================================================
-- HOOK INTO NUI CALLBACKS (Capture All UI Interactions)
-- ============================================================================

-- Wrapper for RegisterNUICallback to log all interactions
local OriginalRegisterNUICallback = RegisterNUICallback
RegisterNUICallback = function(callbackName, callback)
    OriginalRegisterNUICallback(callbackName, function(data, cb)
        -- Log the NUI callback
        if Config.Discord and Config.Discord.consoleLogging and Config.Discord.consoleLogging.logMenuClicks then
            ClientLogger.LogClick(callbackName, 'NUI Callback')
        end
        
        -- Call original callback
        callback(data, cb)
    end)
end

-- ============================================================================
-- LISTEN FOR NUI MESSAGES (Track Page Changes)
-- ============================================================================
RegisterNUICallback('pageChange', function(data, cb)
    if data and data.page then
        ClientLogger.LogPageChange(data.page)
    end
    cb({ success = true })
end)

RegisterNUICallback('menuOpen', function(data, cb)
    ClientLogger.LogMenuOpen()
    cb({ success = true })
end)

RegisterNUICallback('menuClose', function(data, cb)
    ClientLogger.LogMenuClose()
    cb({ success = true })
end)

RegisterNUICallback('playerSelect', function(data, cb)
    if data and data.playerId and data.playerName then
        ClientLogger.LogPlayerSelect(data.playerId, data.playerName)
    end
    cb({ success = true })
end)

-- Generic click logger for all UI buttons
RegisterNUICallback('logClick', function(data, cb)
    if data and data.button then
        ClientLogger.LogClick(data.button, data.component)
    end
    cb({ success = true })
end)

-- ============================================================================
-- DETECT MENU OPEN/CLOSE (Via NUI Focus State)
-- ============================================================================
CreateThread(function()
    local wasMenuOpen = false
    
    while true do
        Wait(500)  -- Check every 500ms
        
        local isMenuOpen = IsNuiFocused() or false
        
        if isMenuOpen and not wasMenuOpen then
            ClientLogger.LogMenuOpen()
            wasMenuOpen = true
        elseif not isMenuOpen and wasMenuOpen then
            ClientLogger.LogMenuClose()
            wasMenuOpen = false
        end
    end
end)

-- ============================================================================
-- EXPORT FUNCTIONS
-- ============================================================================
exports('LogClick', function(button, component)
    ClientLogger.LogClick(button, component)
end)

exports('LogPageChange', function(newPage)
    ClientLogger.LogPageChange(newPage)
end)

exports('LogPlayerSelect', function(targetId, targetName)
    ClientLogger.LogPlayerSelect(targetId, targetName)
end)

-- Make globally available
_G.ClientLogger = ClientLogger

Logger.Success('✅ Client-Side Action Logger Loaded')
Logger.Info('   🖱️ Tracking: All UI clicks and interactions')
Logger.Info('   📄 Tracking: Page navigation in admin menu')
Logger.Info('   🎮 Tracking: Menu open/close events')
