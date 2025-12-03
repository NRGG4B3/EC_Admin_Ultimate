--[[
    EC Admin Ultimate - Players Actions
    Event handlers for player actions (kick, ban, teleport, etc.)
]]

-- ==========================================
-- PLAYER MODERATION ACTIONS
-- ==========================================

RegisterNetEvent('ec_admin:kickPlayer', function(data)
    local src = source
    
    if not data or not data.playerId then
        Logger.Info(" Invalid kick data^7")
        return
    end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:kickPlayer') then
        return
    end

    local targetId = tonumber(data.playerId)
    local reason = data.reason or "No reason provided"
    local adminName = GetPlayerName(src) or "Console"
    
    if targetId and GetPlayerName(targetId) then
        DropPlayer(targetId, string.format("Kicked by %s: %s", adminName, reason))
        print(string.format("^2[EC Admin]^7 %s kicked player %d - Reason: %s", adminName, targetId, reason))
        
        -- Log to webhook if configured
        if Config and Config.Webhooks and Config.Webhooks.moderation then
            TriggerEvent('ec_admin:sendWebhook', 'moderation', {
                title = "Player Kicked",
                description = string.format("**Admin:** %s\n**Player:** %s (%d)\n**Reason:** %s", 
                    adminName, GetPlayerName(targetId), targetId, reason),
                color = 16744192
            })
        end
    end
end)

RegisterNetEvent('ec_admin:banPlayer', function(data)
    local src = source
    
    if not data or not data.playerId then
        Logger.Info(" Invalid ban data^7")
        return
    end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:banPlayer') then
        return
    end

    local targetId = tonumber(data.playerId)
    local reason = data.reason or "No reason provided"
    local duration = data.duration or 0 -- 0 = permanent
    local adminName = GetPlayerName(src) or "Console"
    
    if targetId and GetPlayerName(targetId) then
        local identifiers = GetPlayerIdentifiers(targetId)
        local license = nil
        
        for _, id in pairs(identifiers) do
            if string.match(id, "license:") then
                license = id
                break
            end
        end
        
        if license then
            -- Store ban in database
            TriggerEvent('ec_admin:addBan', {
                identifier = license,
                playerName = GetPlayerName(targetId),
                reason = reason,
                adminName = adminName,
                duration = duration,
                timestamp = os.time()
            })
            
            -- Kick the player
            DropPlayer(targetId, string.format("Banned by %s: %s", adminName, reason))
            
            print(string.format("^2[EC Admin]^7 %s banned player %d - Reason: %s", adminName, targetId, reason))
            
            -- Log to webhook
            if Config and Config.Webhooks and Config.Webhooks.moderation then
                TriggerEvent('ec_admin:sendWebhook', 'moderation', {
                    title = "Player Banned",
                    description = string.format("**Admin:** %s\n**Player:** %s (%d)\n**Reason:** %s\n**Duration:** %s", 
                        adminName, GetPlayerName(targetId), targetId, reason, 
                        duration == 0 and "Permanent" or duration .. " days"),
                    color = 16711680
                })
            end
        end
    end
end)

RegisterNetEvent('ec_admin:warnPlayer', function(data)
    local src = source
    
    if not data or not data.playerId then return end
    
    local targetId = tonumber(data.playerId)
    local reason = data.reason or "No reason provided"
    local adminName = GetPlayerName(src) or "Console"
    
    if targetId and GetPlayerName(targetId) then
        -- Send warning to target player
        TriggerClientEvent('ec_admin:receiveWarning', targetId, {
            admin = adminName,
            reason = reason
        })
        
        print(string.format("^2[EC Admin]^7 %s warned player %d - Reason: %s", adminName, targetId, reason))
    end
end)

RegisterNetEvent('ec_admin:freezePlayer', function(data)
    local src = source
    
    if not data or not data.playerId then return end
    
    local targetId = tonumber(data.playerId)
    local freeze = data.freeze ~= false -- default true
    
    if targetId and GetPlayerName(targetId) then
        TriggerClientEvent('ec_admin:setFreeze', targetId, freeze)
        
        local adminName = GetPlayerName(src) or "Console"
        print(string.format("^2[EC Admin]^7 %s %s player %d", 
            adminName, freeze and "froze" or "unfroze", targetId))
    end
end)

RegisterNetEvent('ec_admin:teleportToPlayer', function(data)
    local src = source
    
    if not data or not data.playerId then return end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:teleportToPlayer') then
        return
    end

    local targetId = tonumber(data.playerId)

    if targetId and GetPlayerName(targetId) then
        local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
        TriggerClientEvent('ec_admin:teleportToCoords', src, targetCoords)
    end
end)

RegisterNetEvent('ec_admin:bringPlayer', function(data)
    local src = source
    
    if not data or not data.playerId then return end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:bringPlayer') then
        return
    end

    local targetId = tonumber(data.playerId)

    if targetId and GetPlayerName(targetId) then
        local adminCoords = GetEntityCoords(GetPlayerPed(src))
        TriggerClientEvent('ec_admin:teleportToCoords', targetId, adminCoords)
    end
end)

RegisterNetEvent('ec_admin:spectatePlayer', function(data)
    local src = source

    if not data or not data.playerId then return end

    local targetId = tonumber(data.playerId)

    if targetId and GetPlayerName(targetId) then
        TriggerClientEvent('ec_admin:startSpectate', src, targetId)
    end
end)

RegisterNetEvent('ec_admin:revivePlayer', function(data)
    local src = source
    
    if not data or not data.playerId then return end
    
    local targetId = tonumber(data.playerId)
    
    if targetId and GetPlayerName(targetId) then
        -- Trigger framework-specific revive
        TriggerEvent('ec_admin:reviveTarget', targetId)
        TriggerClientEvent('ec_admin:revive', targetId)
    end
end)

RegisterNetEvent('ec_admin:healPlayer', function(data)
    local src = source

    if not data or not data.playerId then return end

    if CheckRateLimit and not CheckRateLimit(src, 'ec_admin:healPlayer') then
        return
    end

    local targetId = tonumber(data.playerId)

    if targetId and GetPlayerName(targetId) then
        TriggerClientEvent('ec_admin:heal', targetId)
    end
end)

Logger.Info("^7 Players actions loaded")
