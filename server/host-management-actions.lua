-- EC Admin Ultimate - Host Management Actions
-- All RegisterNetEvent for host management features
-- Author: NRG Development
-- Version: 1.0.0

-- Apply global ban
RegisterNetEvent('ec_admin:host:applyGlobalBan', function(banData)
    local source = source
    local success, message, banId = exports['ec_admin_ultimate']:ApplyGlobalBan(source, banData)
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'apply_global_ban',
        success = success,
        message = message,
        data = { banId = banId }
    })
end)

-- Remove global ban
RegisterNetEvent('ec_admin:host:removeGlobalBan', function(banId, reason)
    local source = source
    local success, message = exports['ec_admin_ultimate']:RemoveGlobalBan(source, banId, reason)
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'remove_global_ban',
        success = success,
        message = message,
        data = { banId = banId }
    })
end)

-- Submit ban appeal
RegisterNetEvent('ec_admin:host:submitBanAppeal', function(banId, appealData)
    local success, message, appealId = exports['ec_admin_ultimate']:SubmitBanAppeal(banId, appealData)
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'submit_appeal',
        success = success,
        message = message,
        data = { appealId = appealId }
    })
end)

-- Process ban appeal
RegisterNetEvent('ec_admin:host:processBanAppeal', function(appealId, action, reviewNotes)
    local source = source
    local success, message = exports['ec_admin_ultimate']:ProcessBanAppeal(source, appealId, action, reviewNotes)
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'process_appeal',
        success = success,
        message = message,
        data = { appealId = appealId, appealAction = action }
    })
    
    -- Notify all admins if appeal was processed
    if success then
        for _, playerId in ipairs(GetPlayers()) do
            if exports['ec_admin_ultimate']:HasPermission(playerId, 'ec_admin.host.view') then
                TriggerClientEvent('ec_admin:host:appealProcessed', playerId, {
                    appealId = appealId,
                    action = action,
                    processedBy = GetPlayerName(source)
                })
            end
        end
    end
end)

-- Issue global warning
RegisterNetEvent('ec_admin:host:issueGlobalWarning', function(warningData)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.warn') then
        TriggerClientEvent('ec_admin:host:actionResult', source, {
            action = 'issue_warning',
            success = false,
            message = 'No permission'
        })
        return
    end
    
    local adminName = GetPlayerName(source)
    
    -- Insert warning
    local insertId = MySQL.insert.await([[
        INSERT INTO ec_host_global_warnings 
        (identifier, player_name, reason, issued_by, issued_at, severity, active, applied_cities)
        VALUES (?, ?, ?, ?, ?, ?, 1, '[]')
    ]], {
        warningData.identifier,
        warningData.playerName,
        warningData.reason,
        adminName,
        os.time(),
        warningData.severity or 'medium'
    })
    
    if insertId then
        -- Apply to all cities
        local cities = exports['ec_admin_ultimate']:GetConnectedCities()
        local appliedCities = {}
        
        for _, city in ipairs(cities) do
            exports['ec_admin_ultimate']:ExecuteCityCommand(source, city.id, 'apply_warning', {
                identifier = warningData.identifier,
                playerName = warningData.playerName,
                reason = warningData.reason,
                issuedBy = adminName,
                severity = warningData.severity
            })
            table.insert(appliedCities, city.id)
        end
        
        -- Update applied cities
        MySQL.update('UPDATE ec_host_global_warnings SET applied_cities = ? WHERE id = ?',
            {json.encode(appliedCities), insertId})
        
        -- Send webhook
        SendHostWebhook('global_warning', {
            warningId = insertId,
            identifier = warningData.identifier,
            playerName = warningData.playerName,
            reason = warningData.reason,
            issuedBy = adminName,
            severity = warningData.severity,
            citiesApplied = #appliedCities
        })
        
        TriggerClientEvent('ec_admin:host:actionResult', source, {
            action = 'issue_warning',
            success = true,
            message = 'Global warning issued to all cities',
            data = { warningId = insertId }
        })
    else
        TriggerClientEvent('ec_admin:host:actionResult', source, {
            action = 'issue_warning',
            success = false,
            message = 'Failed to issue warning'
        })
    end
end)

-- Remove global warning
RegisterNetEvent('ec_admin:host:removeGlobalWarning', function(warningId, reason)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.warn') then
        return
    end
    
    local warning = MySQL.single.await('SELECT * FROM ec_host_global_warnings WHERE id = ?', {warningId})
    
    if warning then
        -- Mark as inactive
        MySQL.update('UPDATE ec_host_global_warnings SET active = 0 WHERE id = ?', {warningId})
        
        -- Remove from cities
        local cities = exports['ec_admin_ultimate']:GetConnectedCities()
        
        for _, city in ipairs(cities) do
            exports['ec_admin_ultimate']:ExecuteCityCommand(source, city.id, 'remove_warning', {
                warningId = warningId,
                identifier = warning.identifier
            })
        end
        
        TriggerClientEvent('ec_admin:host:actionResult', source, {
            action = 'remove_warning',
            success = true,
            message = 'Global warning removed'
        })
    end
end)

-- Save webhook
RegisterNetEvent('ec_admin:host:saveWebhook', function(webhookData)
    local source = source
    local success, message, webhookId = exports['ec_admin_ultimate']:SaveHostWebhook(source, webhookData)
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'save_webhook',
        success = success,
        message = message,
        data = { webhookId = webhookId }
    })
end)

-- Delete webhook
RegisterNetEvent('ec_admin:host:deleteWebhook', function(webhookId)
    local source = source
    local success, message = exports['ec_admin_ultimate']:DeleteHostWebhook(source, webhookId)
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'delete_webhook',
        success = success,
        message = message
    })
end)

-- Test webhook
RegisterNetEvent('ec_admin:host:testWebhook', function(webhookId)
    local source = source
    local success, message = exports['ec_admin_ultimate']:TestHostWebhook(source, webhookId)
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'test_webhook',
        success = success,
        message = message
    })
end)

-- Toggle webhook
RegisterNetEvent('ec_admin:host:toggleWebhook', function(webhookId, enabled)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.webhooks') then
        return
    end
    
    MySQL.update('UPDATE ec_host_webhooks SET enabled = ? WHERE id = ?', 
        {enabled and 1 or 0, webhookId})
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'toggle_webhook',
        success = true,
        message = enabled and 'Webhook enabled' or 'Webhook disabled'
    })
end)

-- Add NRG staff
RegisterNetEvent('ec_admin:host:addNRGStaff', function(staffData)
    local source = source
    local success, message = exports['ec_admin_ultimate']:AddNRGStaff(source, staffData)
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'add_staff',
        success = success,
        message = message
    })
end)

-- Remove NRG staff
RegisterNetEvent('ec_admin:host:removeNRGStaff', function(identifier)
    local source = source
    local success, message = exports['ec_admin_ultimate']:RemoveNRGStaff(source, identifier)
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'remove_staff',
        success = success,
        message = message
    })
end)

-- Bulk action on bans
RegisterNetEvent('ec_admin:host:bulkBanAction', function(banIds, action, reason)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.ban') then
        return
    end
    
    local successCount = 0
    local failCount = 0
    
    for _, banId in ipairs(banIds) do
        if action == 'remove' then
            local success = exports['ec_admin_ultimate']:RemoveGlobalBan(source, banId, reason)
            if success then
                successCount = successCount + 1
            else
                failCount = failCount + 1
            end
        end
    end
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'bulk_ban_action',
        success = successCount > 0,
        message = string.format('Processed %d bans (%d success, %d failed)', 
            #banIds, successCount, failCount)
    })
end)

-- Export city data
RegisterNetEvent('ec_admin:host:exportData', function(exportType, filters)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.export') then
        return
    end
    
    local data = {}
    
    if exportType == 'bans' then
        data = exports['ec_admin_ultimate']:GetGlobalBans(filters)
    elseif exportType == 'appeals' then
        data = exports['ec_admin_ultimate']:GetBanAppeals(filters)
    elseif exportType == 'warnings' then
        data = MySQL.query.await('SELECT * FROM ec_host_global_warnings') or {}
    elseif exportType == 'actions' then
        data = MySQL.query.await('SELECT * FROM ec_host_actions LIMIT 1000') or {}
    end
    
    TriggerClientEvent('ec_admin:host:exportReady', source, {
        type = exportType,
        data = data,
        exportedAt = os.time(),
        exportedBy = GetPlayerName(source)
    })
end)

-- Acknowledge alert
RegisterNetEvent('ec_admin:host:acknowledgeAlert', function(alertId)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.view') then
        return
    end
    
    local adminName = GetPlayerName(source)
    
    MySQL.update([[
        UPDATE ec_host_alerts 
        SET acknowledged = 1, acknowledged_by = ?, acknowledged_at = ?
        WHERE id = ?
    ]], {adminName, os.time(), alertId})
    
    TriggerClientEvent('ec_admin:host:actionResult', source, {
        action = 'acknowledge_alert',
        success = true,
        message = 'Alert acknowledged'
    })
end)

-- Create system alert
RegisterNetEvent('ec_admin:host:createAlert', function(alertData)
    local source = source
    
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.alerts') then
        return
    end
    
    local insertId = MySQL.insert.await([[
        INSERT INTO ec_host_alerts 
        (alert_type, severity, source, message, details, timestamp)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        alertData.type,
        alertData.severity,
        'manual',
        alertData.message,
        json.encode(alertData.details or {}),
        os.time()
    })
    
    if insertId then
        -- Notify all admins
        for _, playerId in ipairs(GetPlayers()) do
            if exports['ec_admin_ultimate']:HasPermission(playerId, 'ec_admin.host.view') then
                TriggerClientEvent('ec_admin:host:newAlert', playerId, {
                    id = insertId,
                    type = alertData.type,
                    severity = alertData.severity,
                    message = alertData.message
                })
            end
        end
        
        TriggerClientEvent('ec_admin:host:actionResult', source, {
            action = 'create_alert',
            success = true,
            message = 'Alert created'
        })
    end
end)

Logger.Info('🏢 Host Management actions registered')
