--[[
    EC Admin Ultimate - Quick Actions Hotkeys
    Registers hotkeys for quick actions (1-9, 0, etc.)
]]

-- Hotkey mappings for quick actions
local QUICK_ACTION_HOTKEYS = {
    ['1'] = 'noclip',
    ['2'] = 'godmode',
    ['3'] = 'heal',
    ['4'] = 'tpm',
    ['5'] = 'revive',
    ['6'] = 'spawn_vehicle',
    ['7'] = 'fix_vehicle',
    ['8'] = 'delete_vehicle',
    ['9'] = 'weather',
    ['0'] = 'time',
    -- Add more hotkeys as needed
}

-- Register hotkey commands
for key, actionId in pairs(QUICK_ACTION_HOTKEYS) do
    RegisterCommand('qa_' .. key, function()
        -- Execute quick action via callback
        if lib and lib.callback then
            lib.callback.await('ec_admin:quickAction', false, {
                action = actionId,  -- Use 'action' not 'actionId'
                data = {}
            })
        else
            -- Fallback: Use server event
            TriggerServerEvent('ec_admin:executeQuickAction', {
                action = actionId,
                data = {}
            })
        end
    end, false)
    
    -- Register key mapping
    RegisterKeyMapping('qa_' .. key, 'Quick Action ' .. key .. ' (' .. actionId .. ')', 'keyboard', key)
end

-- Register number pad hotkeys (if available)
local NUMPAD_HOTKEYS = {
    ['numpad1'] = 'noclip',
    ['numpad2'] = 'godmode',
    ['numpad3'] = 'heal',
    ['numpad4'] = 'tpm',
    ['numpad5'] = 'revive',
}

for key, actionId in pairs(NUMPAD_HOTKEYS) do
    RegisterCommand('qa_' .. key, function()
        if lib and lib.callback then
            lib.callback.await('ec_admin:quickAction', false, {
                action = actionId,  -- Use 'action' not 'actionId'
                data = {}
            })
        else
            TriggerServerEvent('ec_admin:executeQuickAction', {
                action = actionId,
                data = {}
            })
        end
    end, false)
    
    RegisterKeyMapping('qa_' .. key, 'Quick Action ' .. key .. ' (' .. actionId .. ')', 'keyboard', key)
end

print("^2[Quick Actions Hotkeys]^7 Hotkeys registered (1-9, 0, numpad)^0")
