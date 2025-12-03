--[[
    EC Admin Ultimate - Settings Actions
    Event handlers for settings changes
]]

-- ==========================================
-- SAVE SETTINGS
-- ==========================================

RegisterNetEvent('ec_admin:saveSettings', function(data)
    local src = source
    
    if not data or not data.settings then return end
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    -- Save settings to file or database
    if MySQL then
        MySQL.execute.await([[
            INSERT INTO ec_admin_settings (settings_data, updated_by, updated_at) 
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE 
            settings_data = VALUES(settings_data), 
            updated_by = VALUES(updated_by), 
            updated_at = VALUES(updated_at)
        ]], {
            json.encode(data.settings),
            GetPlayerName(src),
            os.time()
        })
    end
    
    TriggerClientEvent('ec_admin:notify', src, {
        type = 'success',
        message = 'Settings saved successfully'
    })
    
    -- Log activity
    TriggerEvent('ec_admin:logActivity', {
        type = 'settings_saved',
        admin = GetPlayerName(src),
        description = 'Updated admin panel settings'
    })
    
    -- Broadcast to all admins
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local id = tonumber(playerId)
        if id and IsPlayerAceAllowed(id, 'admin.access') then
            TriggerClientEvent('ec_admin:settingsUpdated', id, data.settings)
        end
    end
end)

-- ==========================================
-- RESET SETTINGS
-- ==========================================

RegisterNetEvent('ec_admin:resetSettings', function()
    local src = source
    
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    -- Reset to default settings
    if MySQL then
        MySQL.execute.await('DELETE FROM ec_admin_settings')
    end
    
    TriggerClientEvent('ec_admin:notify', src, {
        type = 'success',
        message = 'Settings reset to default'
    })
    
    -- Log activity
    TriggerEvent('ec_admin:logActivity', {
        type = 'settings_reset',
        admin = GetPlayerName(src),
        description = 'Reset settings to default'
    })
end)

-- ==========================================
-- UPDATE WEBHOOK
-- ==========================================

RegisterNetEvent('ec_admin:updateWebhook', function(data)
    local src = source
    
    if not data or not data.type or not data.url then return end
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    -- Save webhook URL to database
    if MySQL then
        MySQL.execute.await([[
            INSERT INTO ec_admin_webhooks (type, url, updated_by, updated_at) 
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE 
            url = VALUES(url), 
            updated_by = VALUES(updated_by), 
            updated_at = VALUES(updated_at)
        ]], {
            data.type,
            data.url,
            GetPlayerName(src),
            os.time()
        })
    end
    
    TriggerClientEvent('ec_admin:notify', src, {
        type = 'success',
        message = 'Webhook updated'
    })
end)

Logger.Info("^7 Settings actions loaded")
