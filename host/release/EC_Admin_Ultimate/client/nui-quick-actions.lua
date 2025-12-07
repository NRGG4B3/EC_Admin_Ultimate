-- EC Admin Ultimate - Client NUI Callbacks for ALL Quick Actions
-- Handles all quick actions from the Quick Actions Center UI
-- Version: 4.0.0 - COMPLETE (86+ Actions)

Logger.Info(" Loading Quick Actions NUI Callbacks...^0")

-- Import menuOpen state from nui-bridge.lua
-- We'll trigger an event to close the menu properly
local function CloseAdminMenu()
    -- CRITICAL: Use centralized close event to properly sync menuOpen state
    -- This prevents focus thread from re-enabling focus
    TriggerEvent('ec_admin:forceCloseMenu')
    
    Logger.Info('')
end

-- ====================
-- MASTER NUI CALLBACK FOR ALL 86+ ACTIONS
-- ====================

RegisterNUICallback('quickAction', function(data, cb)
    local action = data.action
    local actionData = data.data or {}
    
    print(string.format("^3[EC Admin] Quick Action: %s^0", action))
    
    -- ========================================
    -- SELF ACTIONS (18 actions)
    -- ========================================
    
    -- Health & Status
    if action == 'heal' then
        TriggerServerEvent('ec_admin:quickaction:heal')
        
    elseif action == 'revive_self' then
        TriggerEvent('ec_admin:reviveSelf')
        
    elseif action == 'armor' then
        TriggerServerEvent('ec_admin:quickaction:armor')
        
    elseif action == 'clean_clothes' then
        TriggerEvent('ec_admin:cleanClothes')
        
    elseif action == 'wash_player' then
        TriggerEvent('ec_admin:washPlayer')
        
    elseif action == 'clear_blood' then
        TriggerEvent('ec_admin:clearBlood')
        
    elseif action == 'fix_hunger' then
        TriggerServerEvent('ec_admin:quickaction:fix_hunger')
        
    elseif action == 'fix_thirst' then
        TriggerServerEvent('ec_admin:quickaction:fix_thirst')
        
    elseif action == 'fix_stress' then
        TriggerServerEvent('ec_admin:quickaction:fix_stress')
        
    -- Powers
    elseif action == 'noclip' then
        TriggerEvent('ec_admin:toggleNoclip')
        
    elseif action == 'godmode' then
        TriggerEvent('ec_admin:toggleGodMode')
        
    elseif action == 'invisible' then
        TriggerEvent('ec_admin:toggleInvisible')
        
    elseif action == 'stamina' then
        TriggerEvent('ec_admin:toggleStamina')
        
    elseif action == 'super_jump' then
        TriggerEvent('ec_admin:toggleSuperJump')
        
    elseif action == 'fast_run' then
        TriggerEvent('ec_admin:toggleFastRun')
        
    elseif action == 'fast_swim' then
        TriggerEvent('ec_admin:toggleFastSwim')
        
    -- Ped
    elseif action == 'change_ped' then
        -- Opens ped menu - handled by UI
    
    -- ========================================
    -- TELEPORT ACTIONS (7 actions)
    -- ========================================
    
    elseif action == 'tpm' then
        TriggerEvent('ec_admin:teleportToMarker')
        
    elseif action == 'tp_coords' then
        if actionData.coords then
            TriggerServerEvent('ec_admin:quickaction:tp_coords', 
                tonumber(actionData.coords.x),
                tonumber(actionData.coords.y),
                tonumber(actionData.coords.z)
            )
        end
        
    elseif action == 'tp_back' then
        TriggerEvent('ec_admin:teleportBack')
        
    elseif action == 'bring' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:bring', playerId)
        end
        
    elseif action == 'goto' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:goto', playerId)
        end
        
    elseif action == 'save_location' then
        TriggerEvent('ec_admin:savePosition')
        
    elseif action == 'load_location' then
        TriggerEvent('ec_admin:loadPosition')
    
    -- ========================================
    -- PLAYER ACTIONS (23 actions)
    -- ========================================
    
    -- Health & Status
    elseif action == 'heal_player' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:heal_player', playerId)
        end
        
    elseif action == 'revive' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:revive', playerId)
        end
        
    elseif action == 'kill_player' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:kill_player', playerId)
        end
        
    -- Movement
    elseif action == 'freeze' then
        local playerId = tonumber(actionData.playerId)
        local freeze = actionData.freeze
        if freeze == nil then freeze = true end
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:freeze', playerId, freeze)
        end
        
    elseif action == 'sit_player' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:sit_player', playerId)
        end
        
    elseif action == 'drag_player' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:drag_player', playerId)
        end
        
    -- Restraints
    elseif action == 'cuff_player' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:cuff_player', playerId)
        end
        
    elseif action == 'uncuff_player' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:uncuff_player', playerId)
        end
        
    -- Appearance
    elseif action == 'remove_mask' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:remove_mask', playerId)
        end
        
    elseif action == 'remove_hat' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:remove_hat', playerId)
        end
        
    -- Wanted Level
    elseif action == 'clear_wanted' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:clear_wanted', playerId)
        end
        
    -- Inventory & Items
    elseif action == 'give_item' then
        local playerId = tonumber(actionData.playerId)
        local item = actionData.item or 'water'
        local amount = tonumber(actionData.amount) or 1
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:give_item', playerId, item, amount)
        end
        
    elseif action == 'remove_item' then
        local playerId = tonumber(actionData.playerId)
        local item = actionData.item or 'water'
        local amount = tonumber(actionData.amount) or 1
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:remove_item', playerId, item, amount)
        end
        
    elseif action == 'clear_inventory' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:clear_inventory', playerId)
        end
        
    -- Moderation
    elseif action == 'spectate' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:spectate', playerId)
        end
        
    elseif action == 'kick' then
        local playerId = tonumber(actionData.playerId)
        local reason = actionData.reason or "No reason provided"
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:kick', playerId, reason)
        end
        
    elseif action == 'ban' then
        local playerId = tonumber(actionData.playerId)
        local reason = actionData.reason or "No reason provided"
        local duration = tonumber(actionData.duration) or 0
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:ban', playerId, reason, duration)
        end
        
    elseif action == 'warn' then
        local playerId = tonumber(actionData.playerId)
        local reason = actionData.reason or "No reason provided"
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:warn', playerId, reason)
        end
        
    elseif action == 'mute' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:mute', playerId)
        end
        
    elseif action == 'unmute' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:unmute', playerId)
        end
        
    elseif action == 'slap' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:slap', playerId)
        end
        
    elseif action == 'strip' then
        local playerId = tonumber(actionData.playerId)
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:strip', playerId)
        end
        
    -- Weapons & Combat
    elseif action == 'give_weapon' then
        local playerId = tonumber(actionData.playerId)
        local weapon = actionData.weapon or "WEAPON_PISTOL"
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:give_weapon', playerId, weapon)
        end
        
    elseif action == 'set_health' then
        local playerId = tonumber(actionData.playerId)
        local health = tonumber(actionData.health) or 200
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:set_health', playerId, health)
        end
        
    elseif action == 'set_armor' then
        local playerId = tonumber(actionData.playerId)
        local armor = tonumber(actionData.armor) or 100
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:set_armor', playerId, armor)
        end
        
    -- Money & Economy
    elseif action == 'give_money' then
        local playerId = tonumber(actionData.playerId)
        local moneyType = actionData.moneyType or 'cash'
        local amount = tonumber(actionData.amount) or 1000
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:give_money', playerId, moneyType, amount)
        end
        
    elseif action == 'remove_money' then
        local playerId = tonumber(actionData.playerId)
        local moneyType = actionData.moneyType or 'cash'
        local amount = tonumber(actionData.amount) or 1000
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:remove_money', playerId, moneyType, amount)
        end
        
    -- Jobs & Gangs
    elseif action == 'set_job' then
        local playerId = tonumber(actionData.playerId)
        local job = actionData.job or 'unemployed'
        local grade = tonumber(actionData.grade) or 0
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:set_job', playerId, job, grade)
        end
        
    elseif action == 'set_gang' then
        local playerId = tonumber(actionData.playerId)
        local gang = actionData.gang or 'none'
        local grade = tonumber(actionData.grade) or 0
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:set_gang', playerId, gang, grade)
        end
        
    elseif action == 'change_player_ped' then
        local playerId = tonumber(actionData.playerId)
        local model = actionData.model or 'mp_m_freemode_01'
        if playerId then
            TriggerServerEvent('ec_admin:quickaction:change_player_ped', playerId, model)
        end
    
    -- ========================================
    -- VEHICLE ACTIONS (12 actions)
    -- ========================================
    
    -- Self Vehicle
    elseif action == 'fix' then
        TriggerEvent('ec_admin:fixVehicle')
        
    elseif action == 'deleteveh' then
        TriggerEvent('ec_admin:deleteVehicle')
        
    elseif action == 'flip' then
        TriggerEvent('ec_admin:flipVehicle')
        
    elseif action == 'clean' then
        TriggerEvent('ec_admin:cleanVehicle')
        
    elseif action == 'maxmod' then
        TriggerEvent('ec_admin:maxTuneVehicle')
        
    elseif action == 'boost' then
        TriggerEvent('ec_admin:toggleBoost')
        
    elseif action == 'rainbow' then
        TriggerEvent('ec_admin:toggleRainbow')
        
    -- Vehicle Management
    elseif action == 'spawnveh' then
        local model = actionData.model or actionData.vehicleName or 'adder'
        TriggerServerEvent('ec_admin:quickaction:spawnveh', model)
        
    elseif action == 'change_plate' then
        local plate = actionData.plate or 'ADMIN'
        TriggerServerEvent('ec_admin:quickaction:change_plate', plate)
        
    elseif action == 'unlock_vehicle' then
        TriggerEvent('ec_admin:unlockVehicle')
        
    elseif action == 'lock_vehicle' then
        TriggerEvent('ec_admin:lockVehicle')
        
    elseif action == 'hop_driver' then
        TriggerEvent('ec_admin:hopIntoDriver')
        
    -- ========================================
    -- SERVER / WORLD ACTIONS (13 actions)
    -- ========================================
    
    -- Announcements
    elseif action == 'announce' then
        local message = actionData.message or "Server announcement"
        local announcementType = actionData.announcementType or 'info'
        TriggerServerEvent('ec_admin:quickaction:announce', message, announcementType)
        
    -- Server Control
    elseif action == 'restart' then
        local minutes = tonumber(actionData.minutes) or 5
        TriggerServerEvent('ec_admin:quickaction:restart', minutes)
        
    -- World Cleanup
    elseif action == 'cleararea' then
        TriggerEvent('ec_admin:clearArea')
        
    elseif action == 'clear_all_vehicles' then
        TriggerServerEvent('ec_admin:quickaction:clear_all_vehicles')
        
    elseif action == 'clear_all_peds' then
        TriggerServerEvent('ec_admin:quickaction:clear_all_peds')
        
    elseif action == 'garage_radius' then
        local radius = tonumber(actionData.radius) or 50
        TriggerServerEvent('ec_admin:quickaction:garage_radius', radius)
        
    elseif action == 'garage_all' then
        TriggerServerEvent('ec_admin:quickaction:garage_all')
        
    -- Environment
    elseif action == 'weather' then
        local weatherType = actionData.weatherType or 'CLEAR'
        TriggerServerEvent('ec_admin:quickaction:weather', weatherType)
        
    elseif action == 'time' then
        local hour = tonumber(actionData.hour) or 12
        local minute = tonumber(actionData.minute) or 0
        TriggerServerEvent('ec_admin:quickaction:time', hour, minute)
        
    elseif action == 'blackout' then
        local enabled = actionData.enabled
        if enabled == nil then enabled = true end
        TriggerServerEvent('ec_admin:quickaction:blackout', enabled)
        
    -- Mass Actions
    elseif action == 'revive_all' then
        TriggerServerEvent('ec_admin:quickaction:revive_all')
        
    elseif action == 'heal_all' then
        TriggerServerEvent('ec_admin:quickaction:heal_all')
        
    elseif action == 'kick_all' then
        local reason = actionData.reason or "Server maintenance"
        TriggerServerEvent('ec_admin:quickaction:kick_all', reason)
        
    else
        print(string.format("^1[EC Admin] ❌ Unknown quick action: %s^0", action))
    end
    
    -- REMOVED: Don't auto-close menu here - React handles it via autoClose flag
    -- The Quick Actions Center component decides when to close based on action.autoClose
    -- CloseAdminMenu() call removed - React will handle closing for gameplay actions
    
    cb({ success = true })
end)

-- ====================
-- PED MENU CALLBACK
-- ====================

RegisterNUICallback('changePed', function(data, cb)
    local pedModel = data.pedModel or data.model
    local targetPlayerId = data.targetPlayerId
    
    if targetPlayerId then
        -- Change another player's ped
        TriggerServerEvent('ec_admin:quickaction:change_player_ped', targetPlayerId, pedModel)
    else
        -- Change own ped
        local modelHash = GetHashKey(pedModel)
        
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
        
        if HasModelLoaded(modelHash) then
            SetPlayerModel(PlayerId(), modelHash)
            SetModelAsNoLongerNeeded(modelHash)
            print(string.format("^2[EC Admin] ✅ Ped changed to: %s^0", pedModel))
        else
            print(string.format("^1[EC Admin] ❌ Failed to load model: %s^0", pedModel))
        end
    end
    
    cb({ success = true })
end)

Logger.Info('')