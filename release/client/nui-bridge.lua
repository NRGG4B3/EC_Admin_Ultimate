--[[
    EC Admin Ultimate - NUI Bridge (Client Side)
    Handles NUI lifecycle: mount on OPEN, unmount on CLOSE
    NO overlay on spawn, proper focus management
]]

print('^2[EC Admin NUI] Initializing NUI bridge...^0')

local menuOpen = false
local hasPermission = false
local isHost = false
local devMode = GetConvar('ec_dev_mode', 'false') == 'true'

if devMode then
    print('^3[EC Admin NUI] DEV MODE ENABLED - Extra logging active^0')
end

-- Detect if this is a host installation
local function IsHostInstallation()
    -- Check for /host/ folder existence (host-only)
    -- This is set by server on connect
    return isHost
end

RegisterNetEvent('ec_admin:setHostStatus')
AddEventHandler('ec_admin:setHostStatus', function(hostStatus)
    isHost = hostStatus
    print(string.format('^2[EC Admin NUI] Host status: %s^0', tostring(hostStatus)))
    
    -- Forward to NUI so React can detect host mode
    SendNUIMessage({
        type = 'EC_HOST_STATUS',
        isHost = hostStatus
    })
end)

-- Check permission from server
RegisterNetEvent('ec_admin:permissionResult')
AddEventHandler('ec_admin:permissionResult', function(allowed)
    hasPermission = allowed
    print(string.format('^2[EC Admin NUI] Permission set to: %s^0', tostring(allowed)))
end)

-- Also listen for old event name (backwards compatibility)
RegisterNetEvent('ec_admin:setPermission')
AddEventHandler('ec_admin:setPermission', function(allowed)
    hasPermission = allowed
    print(string.format('^2[EC Admin NUI] Permission set to: %s^0', tostring(allowed)))
end)

-- Request permission on resource start
Citizen.CreateThread(function()
    Wait(2000) -- Wait for server to fully initialize
    TriggerServerEvent('ec_admin:checkPermission')
    print('^3[EC Admin NUI] Requesting permission from server...^0')
end)

-- ==========================================
-- MENU CONTROL - STRICT OPEN/CLOSE RULES
-- ==========================================
-- OPEN ONLY VIA: /hud command OR F2 key
-- CLOSE ONLY VIA: ESC key, X button, or configured Quick Actions
-- ==========================================

-- ESC key handler to prevent freeze
local function CloseMenu()
    if menuOpen then
        print('^3[EC Admin NUI] CloseMenu() called - Closing menu...^0')
        menuOpen = false
        
        -- CRITICAL: Disable NUI focus FIRST - FORCE IT MULTIPLE TIMES
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        Wait(50)  -- Small delay to ensure FiveM processes it
        SetNuiFocus(false, false)  -- Double tap for safety
        
        -- Then notify React to close
        SendNUIMessage({
            type = 'EC_SET_VISIBILITY',
            open = false
        })
        
        -- Clean up states
        TriggerEvent('ec_admin:cleanupAllStates')
        
        -- Force clear cursor just in case
        SetCursorLocation(0.5, 0.5)
        
        print('^2[EC Admin NUI] ✅ Menu closed - NUI focus removed^0')
    else
        print('^3[EC Admin NUI] CloseMenu() called but menu was already closed^0')
    end
end

-- NUI Callback for when React closes the panel (X button)
RegisterNUICallback('closePanel', function(data, cb)
    print('[EC Admin NUI] closePanel callback received from React')
    CloseMenu()
    cb('ok')
end)

-- Also handle alternative close event names
RegisterNUICallback('close', function(data, cb)
    print('[EC Admin NUI] close callback received from React')
    CloseMenu()
    cb('ok')
end)

RegisterNUICallback('hideUI', function(data, cb)
    print('[EC Admin NUI] hideUI callback received from React')
    CloseMenu()
    cb('ok')
end)

-- Track if Quick Actions is open in standalone mode
local quickActionsOpen = false

local function CloseQuickActions()
    if quickActionsOpen then
        print('^3[EC Admin NUI] CloseQuickActions() called - Closing Quick Actions...^0')
        quickActionsOpen = false
        
        -- Force disable NUI focus
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        Wait(50)
        SetNuiFocus(false, false)  -- Double tap
        
        SendNUIMessage({
            type = 'EC_CLOSE_QUICK_ACTIONS_STANDALONE'
        })
        
        print('^2[EC Admin NUI] ✅ Quick Actions closed - NUI focus removed^0')
    else
        print('^3[EC Admin NUI] CloseQuickActions() called but Quick Actions was already closed^0')
    end
end

-- Event to close menu from Quick Actions (configurable)
RegisterNetEvent('ec_admin:forceCloseMenu')
AddEventHandler('ec_admin:forceCloseMenu', function()
    print('^3[EC Admin NUI] Menu closed via Quick Action^0')
    CloseMenu()
end)

-- ESC key detection - ONLY FOR CLOSING
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- CRITICAL: Check if Quick Actions is open in standalone mode OR full menu is open
        if menuOpen or quickActionsOpen then
            -- Disable default controls while menu is open
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            
            -- BULLETPROOF ESC KEY DETECTION - Works with ALL frameworks
            -- We DO NOT disable control 322 (ESC) so we can detect it!
            
            -- Method 1: Control 322 (ESC/Cancel) - MOST RELIABLE
            if IsControlJustPressed(0, 322) then
                Logger.Info('')
                if menuOpen then
                    CloseMenu()
                elseif quickActionsOpen then
                    CloseQuickActions()
                end
            end
            
            -- Method 2: Control 177 (Phone Cancel) - Backup for some frameworks
            if IsControlJustPressed(0, 177) then
                Logger.Info('')
                if menuOpen then
                    CloseMenu()
                elseif quickActionsOpen then
                    CloseQuickActions()
                end
            end
            
            -- Method 3: Control 202 (ESC/Pause Menu) - Secondary backup
            if IsControlJustPressed(0, 202) then
                Logger.Info('')
                if menuOpen then
                    CloseMenu()
                elseif quickActionsOpen then
                    CloseQuickActions()
                end
            end
            
            -- Method 4: If pause menu opened while admin menu is open, close admin menu
            if IsPauseMenuActive() then
                Logger.Info('')
                if menuOpen then
                    CloseMenu()
                elseif quickActionsOpen then
                    CloseQuickActions()
                end
            end
        else
            -- If not open, don't loop every frame
            Citizen.Wait(500)
        end
    end
end)

-- PRIMARY COMMAND: /hud (Admin Menu)
RegisterCommand('hud', function()
    print('^3[EC Admin NUI] /hud command triggered - checking permission...^0')
    
    -- Check menu gating (host can disable panel)
    if not exports[GetCurrentResourceName()]:CanOpenAdminMenu() then
        print('^1[EC Admin NUI] ❌ Admin menu is disabled by host^0')
        return
    end
    
    -- Check if player has permission from server
    if not hasPermission then
        print('^1[EC Admin NUI] ❌ No permission - requesting from server...^0')
        
        -- Notify player (with fallback for all frameworks)
        if lib and lib.notify then
            lib.notify({
                title = 'Access Denied',
                description = 'You need admin permission to use the admin panel. If you should have access, check your Config.Owners settings or ACE permissions.',
                type = 'error'
            })
        else
            -- Fallback to chat message
            TriggerEvent('chat:addMessage', {
                color = {255, 0, 0},
                multiline = true,
                args = {"EC Admin", "Access Denied - You need admin permission to use the admin panel"}
            })
        end
        
        -- Re-request permission in case it wasn't set
        TriggerServerEvent('ec_admin:checkPermission')
        return
    end
    
    -- STRICT: Prevent opening if pause menu is active
    if IsPauseMenuActive() then
        Logger.Info('')
        return
    end
    
    -- Only OPEN the menu (never close via command)
    if not menuOpen then
        menuOpen = true
        SetNuiFocus(true, true)
        
        SendNUIMessage({
            type = 'EC_SET_VISIBILITY',
            open = true
        })
        
        -- Request initial data
        TriggerServerEvent('ec_admin:requestInitialData')
        print('^2[EC Admin NUI] Menu opened via /hud - focus set^0')
    else
        print('^3[EC Admin NUI] Menu already open - use ESC or X to close^0')
    end
end, false)

-- F2 KEYBIND: Opens admin menu
RegisterKeyMapping('hud', 'Open Admin Menu (F2)', 'keyboard', 'F2')

-- F3 KEYBIND: Opens Quick Actions menu directly (NO BACKGROUND PANEL)
RegisterCommand('quickactions', function()
    print('^3[EC Admin NUI] /quickactions command triggered - checking permission...^0')
    
    -- Check if player has permission (reuse server-provided flag)
    local allowed = hasPermission

    if not allowed then
        print('^1[EC Admin NUI] ❌ No permission for Quick Actions - requesting from server^0')

        -- Notify player with best available method
        if lib and lib.notify then
            lib.notify({
                title = 'Access Denied',
                description = 'You need admin permission to use Quick Actions.',
                type = 'error'
            })
        else
            TriggerEvent('chat:addMessage', {
                color = {255, 0, 0},
                multiline = true,
                args = {'EC Admin', 'Access Denied - You need admin permission to use Quick Actions'}
            })
        end

        -- Ask the server to refresh permissions in case they were not set yet
        TriggerServerEvent('ec_admin:checkPermission')
        return
    end
    
    -- CRITICAL: F3 should ONLY open Quick Actions, not the full admin panel
    -- This is a standalone mode - just the Quick Actions overlay
    if not quickActionsOpen then
        -- Set standalone Quick Actions state
        quickActionsOpen = true
        
        -- Set NUI focus for Quick Actions only
        SetNuiFocus(true, true)
        
        SendNUIMessage({
            type = 'EC_OPEN_QUICK_ACTIONS_ONLY'  -- New message type for standalone Quick Actions
        })
        
        print('^2[EC Admin NUI] Quick Actions opened (standalone mode - no background panel)^0')
        print('^3[EC Admin NUI] DEBUG: Sent EC_OPEN_QUICK_ACTIONS_ONLY message to React^0')
        print('^3[EC Admin NUI] DEBUG: NUI Focus set to true^0')
    else
        print('^3[EC Admin NUI] Quick Actions already open - use ESC to close^0')
    end
end, false)

RegisterKeyMapping('quickactions', 'Open Quick Actions (F3)', 'keyboard', 'F3')

-- Legacy command support (redirect to /hud)
RegisterCommand('adminmenu', function()
    ExecuteCommand('hud')
end, false)

-- Alternative command
RegisterCommand('ecadmin', function()
    ExecuteCommand('hud')
end, false)

-- DEBUG COMMAND: Force close admin menu (for when it's stuck)
RegisterCommand('forceclose', function()
    print('^1[EC Admin NUI] FORCE CLOSING ALL MENUS^0')
    menuOpen = false
    quickActionsOpen = false
    
    -- Force disable NUI focus aggressively
    for i = 1, 5 do
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        Wait(10)
    end
    
    -- Send close messages
    SendNUIMessage({
        type = 'EC_SET_VISIBILITY',
        open = false
    })
    
    SendNUIMessage({
        type = 'EC_CLOSE_QUICK_ACTIONS_STANDALONE'
    })
    
    print('^2[EC Admin NUI] ✅ Force close complete - if still stuck, restart resource^0')
end, false)

-- EMERGENCY: Force close menu and unlock screen
RegisterCommand('ec_unlock', function()
    Logger.Info('')
    menuOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        type = 'EC_SET_VISIBILITY',
        open = false
    })
    
    TriggerEvent('ec_admin:cleanupAllStates')
    
    lib.notify({
        title = 'EC Admin',
        description = 'Screen unlocked!',
        type = 'success'
    })
end, false)

-- Also allow via chat
TriggerEvent('chat:addSuggestion', '/ec_unlock', 'Force unlock screen if frozen (emergency)')

-- ==========================================
-- UNIVERSAL CLOSE HANDLER
-- Works in QBX, QB-Core, ESX, and Standalone
-- ==========================================
local function UniversalCloseMenu()
    Logger.Info('')
    
    -- Clear states
    menuOpen = false
    quickActionsOpen = false
    
    -- CRITICAL: Release NUI focus (works in ALL frameworks)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    -- Double-check focus is cleared (standalone compatibility)
    Citizen.CreateThread(function()
        Citizen.Wait(50)
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end)
    
    -- Clean up all active states
    TriggerEvent('ec_admin:cleanupAllStates')
    
    -- Send close message to NUI
    SendNUIMessage({
        type = 'EC_SET_VISIBILITY',
        open = false
    })
    
    SendNUIMessage({
        action = 'closeMenu'
    })
    
    Logger.Info('')
end

-- Close menu (NUI callback) - UNIVERSAL
RegisterNUICallback('closeMenu', function(data, cb)
    UniversalCloseMenu()
    cb({ ok = true })
end)

-- ec:close callback (from React)
RegisterNUICallback('ec:close', function(data, cb)
    UniversalCloseMenu()
    cb(true)
end)

-- NUI Callback: Close Quick Actions (standalone mode)
RegisterNUICallback('closeQuickActions', function(data, cb)
    print('^3[EC Admin NUI] Received closeQuickActions callback (standalone mode)^0')
    
    -- CRITICAL: Force clear NUI focus multiple times (standalone fix)
    quickActionsOpen = false
    SetNuiFocus(false, false)
    SetNuiFocus(false, false)  -- Call twice for standalone mode
    
    -- Ensure cursor is hidden with delay
    Citizen.CreateThread(function()
        Citizen.Wait(50)
        SetNuiFocus(false, false)
    end)
    
    cb({ ok = true })
    print('^2[EC Admin NUI] Quick Actions closed - focus cleared^0')
end)

-- ==========================================
-- HOST ACCESS CHECK
-- ==========================================
-- Check if player has access to host features
RegisterNUICallback('checkHostAccess', function(data, cb)
    print('[EC Admin NUI] Checking host access...')
    
    -- Request host status from server
    local result = lib.callback.await('ec_admin:checkHostAccess', false)
    
    if result then
        print(string.format('[EC Admin NUI] Host access check result: hostMode=%s, isNRGStaff=%s', 
            tostring(result.hostMode), tostring(result.isNRGStaff)))
        cb(result)
    else
        print('[EC Admin NUI] Host access check failed - defaulting to customer mode')
        cb({ hostMode = false, isNRGStaff = false })
    end
end)

-- Sidebar: Get system info (framework/database)
RegisterNUICallback('sidebar:getSystemInfo', function(data, cb)
    local info = lib.callback.await('ec_admin:getSystemInfo', false)
    if info then
        cb(info)
    else
        cb({
            framework = { detected = false, type = 'standalone' },
            database = { connected = false, type = 'none' }
        })
    end
end)

-- NUI Callback: Execute action
RegisterNUICallback('executeAction', function(data, cb)
    print('^3[EC Admin NUI] Received executeAction callback^0')
    
    -- Handle the action based on data.action
    if data.action == 'kickPlayer' then
        TriggerServerEvent('ec_admin:kickPlayer', data)
    elseif data.action == 'banPlayer' then
        TriggerServerEvent('ec_admin:banPlayer', data)
    elseif data.action == 'teleportToPlayer' then
        TriggerServerEvent('ec_admin:teleportToPlayer', data)
    elseif data.action == 'bringPlayer' then
        TriggerServerEvent('ec_admin:bringPlayer', data)
    elseif data.action == 'freezePlayer' then
        TriggerServerEvent('ec_admin:freezePlayer', data)
    elseif data.action == 'spectatePlayer' then
        TriggerServerEvent('ec_admin:spectatePlayer', data)
    elseif data.action == 'spawnVehicle' then
        TriggerServerEvent('ec_admin:spawnVehicle', data)
    elseif data.action == 'deleteVehicle' then
        TriggerServerEvent('ec_admin:deleteVehicle', data)
    elseif data.action == 'repairVehicle' then
        TriggerServerEvent('ec_admin:repairVehicle', data)
    elseif data.action == 'giveMoney' then
        TriggerServerEvent('ec_admin:giveMoney', data)
    elseif data.action == 'takeMoney' then
        TriggerServerEvent('ec_admin:takeMoney', data)
    elseif data.action == 'setMoney' then
        TriggerServerEvent('ec_admin:setMoney', data)
    elseif data.action == 'giveItem' then
        local result = lib.callback.await('ec_admin:giveItem', false, data)
        cb(result or { success = false, message = 'Failed to give item' })
    elseif data.action == 'removeItem' then
        local result = lib.callback.await('ec_admin:removeItem', false, data)
        cb(result or { success = false, message = 'Failed to remove item' })
    elseif data.action == 'unbanPlayer' then
        TriggerServerEvent('ec_admin:unbanPlayer', data)
    elseif data.action == 'warnPlayer' then
        TriggerServerEvent('ec_admin:warnPlayer', data)
    elseif data.action == 'handleReport' then
        TriggerServerEvent('ec_admin:handleReport', data)
    elseif data.action == 'closeReport' then
        TriggerServerEvent('ec_admin:closeReport', data)
    elseif data.action == 'restartResource' then
        TriggerServerEvent('ec_admin:restartResource', data)
    elseif data.action == 'stopResource' then
        TriggerServerEvent('ec_admin:stopResource', data)
    elseif data.action == 'startResource' then
        TriggerServerEvent('ec_admin:startResource', data)
    elseif data.action == 'healPlayer' then
        TriggerServerEvent('ec_admin:healPlayer', data)
    elseif data.action == 'revivePlayer' then
        TriggerServerEvent('ec_admin:revivePlayer', data)
    elseif data.action == 'giveArmor' then
        TriggerServerEvent('ec_admin:giveArmor', data)
    elseif data.action == 'setJob' then
        TriggerServerEvent('ec_admin:setJob', data)
    elseif data.action == 'kickPlayers' then
        -- data.playerIds is an array of player IDs to kick
        -- data.reason is the kick reason
        for _, playerId in ipairs(data.playerIds or {}) do
            TriggerServerEvent('ec_admin:kickPlayer', {
                playerId = playerId,
                reason = data.reason or 'Bulk kick action'
            })
        end
        cb({ ok = true, success = true })
    elseif data.action == 'teleportPlayers' then
        -- data.playerIds is an array of player IDs to teleport
        -- data.coords is the destination coordinates
        for _, playerId in ipairs(data.playerIds or {}) do
            TriggerServerEvent('ec_admin:teleportToPlayer', {
                playerId = playerId,
                coords = data.coords
            })
        end
        cb({ ok = true, success = true })
    elseif data.action == 'globaltools/execute' then
        local result = lib.callback.await('ec_admin:globalToolExecute', false, data)
        cb(result or { success = false, error = 'No response from server' })
    elseif data.action == 'whitelist/approve' then
        TriggerServerEvent('ec_admin:approveWhitelist', data)
        cb({ ok = true, success = true })
    elseif data.action == 'whitelist/deny' then
        TriggerServerEvent('ec_admin:denyWhitelist', data)
        cb({ ok = true, success = true })
    elseif data.action == 'whitelist/remove' then
        TriggerServerEvent('ec_admin:removeWhitelist', data)
        cb({ ok = true, success = true })
    else
        print('^1[EC Admin NUI] Unknown action received: ' .. data.action ^0)
        cb({ ok = false, error = 'Unknown action' })
    end
end)

-- ==========================================
-- FOCUS LOSS DETECTION (Monitor Switch Safety)
-- ==========================================

-- Detect when game loses focus (alt-tab, monitor switch)
local isFocused = true

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100) -- Check every 100ms
        
        -- CRITICAL: Only care about focus if menu is actually open
        if not menuOpen then
            -- Reset focus state when menu is closed
            isFocused = true
            Citizen.Wait(500)
        else
            -- Menu is open, monitor focus changes
            local currentFocus = IsPauseMenuActive() == false and IsPlayerPlaying(PlayerId())
            
            -- Focus lost
            if isFocused and not currentFocus then
                isFocused = false
                
                -- If menu is open, ensure NUI focus is properly set
                if menuOpen then
                    Logger.Info('')
                    -- Don't auto-close, but ensure states are safe
                    TriggerEvent('ec_admin:pauseActiveStates')
                end
            end
            
            -- Focus regained
            if not isFocused and currentFocus then
                isFocused = true
                
                -- CRITICAL: Double-check menuOpen is STILL true before restoring focus
                if menuOpen then
                    Logger.Info('')
                    -- Restore NUI focus if menu is still open
                    SetNuiFocus(true, true)
                    TriggerEvent('ec_admin:resumeActiveStates')
                end
            end
        end
    end
end)

-- Emergency cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Logger.Info('')
    
    -- Close menu
    menuOpen = false
    SetNuiFocus(false, false)
    
    -- Clean up all states
    TriggerEvent('ec_admin:cleanupAllStates')
end)

-- ==========================================
-- PLAYER MANAGEMENT
-- ==========================================

-- REMOVED: getPlayers - duplicate with nui-players.lua

RegisterNUICallback('kickPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:kickPlayer', data)
    cb({ ok = true })
end)

RegisterNUICallback('banPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:banPlayer', data)
    cb({ ok = true })
end)

RegisterNUICallback('teleportToPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:teleportToPlayer', data)
    cb({ ok = true })
end)

RegisterNUICallback('bringPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:bringPlayer', data)
    cb({ ok = true })
end)

RegisterNUICallback('freezePlayer', function(data, cb)
    TriggerServerEvent('ec_admin:freezePlayer', data)
    cb({ ok = true })
end)

RegisterNUICallback('spectatePlayer', function(data, cb)
    TriggerServerEvent('ec_admin:spectatePlayer', data)
    cb({ ok = true })
end)

-- ==========================================
-- VEHICLE MANAGEMENT
-- ==========================================

-- REMOVED: getVehicles - duplicate with nui-vehicles.lua

RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:spawnVehicle', data)
    cb({ ok = true })
end)

RegisterNUICallback('deleteVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:deleteVehicle', data)
    cb({ ok = true })
end)

RegisterNUICallback('repairVehicle', function(data, cb)
    TriggerServerEvent('ec_admin:repairVehicle', data)
    cb({ ok = true })
end)

-- ==========================================
-- ECONOMY MANAGEMENT
-- ==========================================

RegisterNUICallback('getPlayerMoney', function(data, cb)
    local result = lib.callback.await('ec_admin:getPlayerMoney', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('giveMoney', function(data, cb)
    TriggerServerEvent('ec_admin:giveMoney', data)
    cb({ ok = true })
end)

RegisterNUICallback('takeMoney', function(data, cb)
    TriggerServerEvent('ec_admin:takeMoney', data)
    cb({ ok = true })
end)

RegisterNUICallback('setMoney', function(data, cb)
    TriggerServerEvent('ec_admin:setMoney', data)
    cb({ ok = true })
end)

-- Align with UI bridge API: removeMoney
RegisterNUICallback('removeMoney', function(data, cb)
    local result = lib.callback.await('ec_admin:removeMoney', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

-- ==========================================
-- INVENTORY MANAGEMENT
-- ==========================================

RegisterNUICallback('getInventory', function(data, cb)
    local result = lib.callback.await('ec_admin:getInventory', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('giveItem', function(data, cb)
    local result = lib.callback.await('ec_admin:giveItem', false, data)
    cb(result or { success = false, message = 'Failed to give item' })
end)

RegisterNUICallback('removeItem', function(data, cb)
    local result = lib.callback.await('ec_admin:removeItem', false, data)
    cb(result or { success = false, message = 'Failed to remove item' })
end)

-- ==========================================
-- BANS & WARNINGS
-- ==========================================

RegisterNUICallback('getBans', function(data, cb)
    local result = lib.callback.await('ec_admin:getBans', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('unbanPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:unbanPlayer', data)
    cb({ ok = true })
end)

RegisterNUICallback('warnPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:warnPlayer', data)
    cb({ ok = true })
end)

RegisterNUICallback('getWarnings', function(data, cb)
    local result = lib.callback.await('ec_admin:getWarnings', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

-- ==========================================
-- REPORTS
-- ==========================================

RegisterNUICallback('getReports', function(data, cb)
    local result = lib.callback.await('ec_admin:getReports', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('handleReport', function(data, cb)
    TriggerServerEvent('ec_admin:handleReport', data)
    cb({ ok = true })
end)

RegisterNUICallback('closeReport', function(data, cb)
    TriggerServerEvent('ec_admin:closeReport', data)
    cb({ ok = true })
end)

-- ==========================================
-- SERVER MANAGEMENT
-- ==========================================

RegisterNUICallback('getServerInfo', function(data, cb)
    local result = lib.callback.await('ec_admin:getMonitoring', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('getResources', function(data, cb)
    local result = lib.callback.await('ec_admin:getResources', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('getNetworkMetrics', function(data, cb)
    local result = lib.callback.await('ec_admin:getNetworkMetrics', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('getDatabaseMetrics', function(data, cb)
    local result = lib.callback.await('ec_admin:getDatabaseMetrics', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('getPlayerPositions', function(data, cb)
    local result = lib.callback.await('ec_admin:getPlayerPositions', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('restartResource', function(data, cb)
    TriggerServerEvent('ec_admin:restartResource', data)
    cb({ ok = true })
end)

RegisterNUICallback('stopResource', function(data, cb)
    TriggerServerEvent('ec_admin:stopResource', data)
    cb({ ok = true })
end)

RegisterNUICallback('startResource', function(data, cb)
    TriggerServerEvent('ec_admin:startResource', data)
    cb({ ok = true })
end)

-- ==========================================
-- QUICK ACTIONS
-- ==========================================

-- NOTE: All quick actions are now handled in nui-quick-actions.lua
-- This prevents duplicate RegisterNUICallback errors

RegisterNUICallback('healPlayer', function(data, cb)
    TriggerServerEvent('ec_admin:healPlayer', data)
    cb({ ok = true })
end)

RegisterNUICallback('revivePlayer', function(data, cb)
    TriggerServerEvent('ec_admin:revivePlayer', data)
    cb({ ok = true })
end)

RegisterNUICallback('giveArmor', function(data, cb)
    TriggerServerEvent('ec_admin:giveArmor', data)
    cb({ ok = true })
end)

RegisterNUICallback('setJob', function(data, cb)
    TriggerServerEvent('ec_admin:setJob', data)
    cb({ ok = true })
end)

-- Bulk player actions
RegisterNUICallback('kickPlayers', function(data, cb)
    -- data.playerIds is an array of player IDs to kick
    -- data.reason is the kick reason
    for _, playerId in ipairs(data.playerIds or {}) do
        TriggerServerEvent('ec_admin:kickPlayer', {
            playerId = playerId,
            reason = data.reason or 'Bulk kick action'
        })
    end
    cb({ ok = true, success = true })
end)

RegisterNUICallback('teleportPlayers', function(data, cb)
    -- data.playerIds is an array of player IDs to teleport
    -- data.coords is the destination coordinates
    for _, playerId in ipairs(data.playerIds or {}) do
        TriggerServerEvent('ec_admin:teleportToPlayer', {
            playerId = playerId,
            coords = data.coords
        })
    end
    cb({ ok = true, success = true })
end)

-- ==========================================
-- LIVE MAP
-- ==========================================

RegisterNUICallback('getLiveMap', function(data, cb)
    local result = lib.callback.await('ec_admin:getLiveMap', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

-- ==========================================
-- ANALYTICS & MONITORING
-- ==========================================

RegisterNUICallback('getAnalytics', function(data, cb)
    local result = lib.callback.await('ec_admin:getAIAnalytics', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('getMetrics', function(data, cb)
    local result = lib.callback.await('ec_admin:getServerMetrics', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

-- ==========================================
-- EXPORTS
-- ==========================================

-- Export menu state for other scripts
exports('isMenuOpen', function()
    return menuOpen or false
end)

exports('isQuickActionsOpen', function()
    return quickActionsOpen or false
end)

exports('closeMenu', function()
    UniversalCloseMenu()
end)

print('^2[EC Admin NUI] ✅ Client bridge loaded successfully^0')

RegisterNUICallback('getAIInsights', function(data, cb)
    local result = lib.callback.await('ec_admin:getAIAnalytics', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

-- ==========================================
-- HOUSING & JOBS
-- ==========================================

RegisterNUICallback('getHousing', function(data, cb)
    local result = lib.callback.await('ec_admin:getHousing', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('getJobs', function(data, cb)
    local result = lib.callback.await('ec_admin:getJobs', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('getGangs', function(data, cb)
    local result = lib.callback.await('ec_admin:getJobs', false, data) -- Uses same callback as jobs
    cb(result or { success = false, error = 'No response from server' })
end)

-- ==========================================
-- ANTI-CHEAT
-- ==========================================

RegisterNUICallback('getAnticheatAlerts', function(data, cb)
    local result = lib.callback.await('ec_admin:getAnticheatData', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('acknowledgeAlert', function(data, cb)
    TriggerServerEvent('ec_admin:acknowledgeAlert', data)
    cb({ ok = true })
end)

-- ==========================================
-- ADMIN PROFILE
-- ==========================================

-- NOTE: getAdminProfile is now handled in nui-admin-profile.lua to prevent duplicates
-- Removed from here to avoid RegisterNUICallback conflicts

RegisterNUICallback('updateAdminSettings', function(data, cb)
    TriggerServerEvent('ec_admin:updateAdminSettings', data)
    cb({ ok = true })
end)

-- ==========================================
-- HOST CONTROL (Host mode only)
-- ==========================================

RegisterNUICallback('hostToggle', function(data, cb)
    TriggerServerEvent('ec_admin:hostToggle', data)
    cb({ ok = true })
end)

RegisterNUICallback('getHostStatus', function(data, cb)
    TriggerServerEvent('ec_admin:getHostStatus', cb)
end)

-- ==========================================
-- LIVE DATA UPDATES
-- ==========================================

-- Receive live data from server
RegisterNetEvent('ec_admin:updateData', function(type, data)
    SendNUIMessage({
        action = 'updateData',
        dataType = type,
        data = data
    })
end)

-- Receive notifications
RegisterNetEvent('ec_admin:notify', function(message, type)
    SendNUIMessage({
        action = 'notify',
        message = message,
        type = type or 'info'
    })
end)

-- ==========================================
-- TELEPORT HANDLERS
-- ==========================================

RegisterNetEvent('ec_admin:beBrought', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
end)

RegisterNetEvent('ec_admin:doTeleport', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
end)

-- ==========================================
-- GLOBAL TOOLS (Economy/Moderation)
-- ==========================================

RegisterNUICallback('globaltools/execute', function(data, cb)
    local result = lib.callback.await('ec_admin:globalToolExecute', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

-- ==========================================
-- WHITELIST MANAGEMENT
-- ==========================================

RegisterNUICallback('whitelist/getData', function(data, cb)
    local result = lib.callback.await('ec_admin:getWhitelistData', false, data)
    cb(result or { success = false, error = 'No response from server' })
end)

RegisterNUICallback('whitelist/approve', function(data, cb)
    TriggerServerEvent('ec_admin:approveWhitelist', data)
    cb({ ok = true, success = true })
end)

RegisterNUICallback('whitelist/deny', function(data, cb)
    TriggerServerEvent('ec_admin:denyWhitelist', data)
    cb({ ok = true, success = true })
end)

RegisterNUICallback('whitelist/remove', function(data, cb)
    TriggerServerEvent('ec_admin:removeWhitelist', data)
    cb({ ok = true, success = true })
end)

print('^2[EC Admin NUI] NUI bridge initialized successfully^0')
print('^2[EC Admin NUI] Press F2 to open admin menu^0')