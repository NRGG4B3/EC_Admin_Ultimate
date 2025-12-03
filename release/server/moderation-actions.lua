--[[
    EC Admin Ultimate - Moderation Actions
    Event handlers for moderation features
]]

RegisterNetEvent('ec_admin:sendAnnouncement', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    if data and data.message then
        TriggerClientEvent('chat:addMessage', -1, {
            template = '<div class="chat-message announcement"><b>ANNOUNCEMENT</b>: {0}</div>',
            args = { data.message }
        })
        
        TriggerEvent('ec_admin:logActivity', {
            type = 'announcement',
            admin = GetPlayerName(src),
            description = 'Sent announcement: ' .. data.message
        })
    end
end)

RegisterNetEvent('ec_admin:clearChat', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    local targetId = data and data.playerId or -1
    
    TriggerClientEvent('chat:clear', targetId)
    
    TriggerEvent('ec_admin:logActivity', {
        type = 'chat_clear',
        admin = GetPlayerName(src),
        target = targetId == -1 and 'All players' or GetPlayerName(targetId),
        description = 'Cleared chat'
    })
end)

RegisterNetEvent('ec_admin:mutePlayer', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    if data and data.playerId then
        local targetId = tonumber(data.playerId)
        local duration = data.duration or 300 -- 5 minutes default
        
        TriggerClientEvent('ec_admin:setMuted', targetId, true, duration)
        
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = string.format('Muted %s for %d seconds', GetPlayerName(targetId), duration)
        })
        
        TriggerEvent('ec_admin:logActivity', {
            type = 'player_mute',
            admin = GetPlayerName(src),
            target = GetPlayerName(targetId),
            description = string.format('Muted for %d seconds', duration)
        })
    end
end)

RegisterNetEvent('ec_admin:unmutePlayer', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    if data and data.playerId then
        local targetId = tonumber(data.playerId)
        
        TriggerClientEvent('ec_admin:setMuted', targetId, false)
        
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = string.format('Unmuted %s', GetPlayerName(targetId))
        })
    end
end)

Logger.Info("^7 Moderation actions loaded")
