--[[
    EC Admin Ultimate - Admin Menu Control
    Handles F2/F3 keybinds and UI visibility
]]

local isMenuOpen = false
local isQuickActionsOpen = false

-- Initialize: Hide UI on startup
CreateThread(function()
    Wait(1000) -- Wait for UI to load
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'EC_SET_VISIBILITY',
        open = false,
        visible = false
    })
end)

-- F2: Toggle Main Menu
RegisterCommand('adminmenu', function()
    if not isMenuOpen then
        -- Open main menu
        print("^2[Admin Menu Control]^7 F2 pressed - Opening main menu^0")
        isMenuOpen = true
        isQuickActionsOpen = false
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'EC_SET_VISIBILITY',
            open = true,
            visible = true
        })
        print("^2[Admin Menu Control]^7 Sent EC_SET_VISIBILITY with open=true^0")
    else
        -- Close menu
        print("^2[Admin Menu Control]^7 F2 pressed - Closing main menu^0")
        isMenuOpen = false
        isQuickActionsOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = 'EC_SET_VISIBILITY',
            open = false,
            visible = false
        })
        print("^2[Admin Menu Control]^7 Sent EC_SET_VISIBILITY with open=false^0")
    end
end, false)

-- F3: Toggle Quick Actions (standalone, no background panel)
RegisterCommand('quickactions', function()
    if not isQuickActionsOpen then
        -- Open quick actions only (standalone mode)
        isQuickActionsOpen = true
        isMenuOpen = false
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'EC_OPEN_QUICK_ACTIONS_ONLY'
        })
    else
        -- Close quick actions
        isQuickActionsOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = 'EC_CLOSE_QUICK_ACTIONS_STANDALONE'
        })
    end
end, false)

-- Register F2 keybind
RegisterKeyMapping('adminmenu', 'Open Admin Menu', 'keyboard', 'F2')

-- Register F3 keybind
RegisterKeyMapping('quickactions', 'Open Quick Actions', 'keyboard', 'F3')

-- Listen for NUI close events
RegisterNUICallback('closeMenu', function(data, cb)
    isMenuOpen = false
    isQuickActionsOpen = false
    SetNuiFocus(false, false)
    cb({ success = true })
end)

RegisterNUICallback('closeQuickActions', function(data, cb)
    isQuickActionsOpen = false
    SetNuiFocus(false, false)
    cb({ success = true })
end)

-- Handle ESC key to close menu
CreateThread(function()
    while true do
        Wait(0)
        if isMenuOpen or isQuickActionsOpen then
            if IsControlJustPressed(0, 322) then -- ESC key
                if isQuickActionsOpen and not isMenuOpen then
                    -- Close standalone quick actions
                    isQuickActionsOpen = false
                    SetNuiFocus(false, false)
                    SendNUIMessage({
                        type = 'EC_CLOSE_QUICK_ACTIONS_STANDALONE'
                    })
                else
                    -- Close main menu
                    isMenuOpen = false
                    isQuickActionsOpen = false
                    SetNuiFocus(false, false)
                    SendNUIMessage({
                        type = 'EC_SET_VISIBILITY',
                        open = false,
                        visible = false
                    })
                end
            end
        end
    end
end)

print("^2[Admin Menu Control]^7 F2/F3 keybinds registered - UI hidden by default^0")
