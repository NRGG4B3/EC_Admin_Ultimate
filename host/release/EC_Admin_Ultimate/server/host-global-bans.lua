-- EC Admin Ultimate - Host Global Bans Management
-- Global ban system for all connected cities
-- Author: NRG Development
-- Version: 1.0.0

-- Apply global ban across all cities
function ApplyGlobalBan(source, banData)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.ban') then
        return false, 'No permission'
    end
    
    local identifier = GetPlayerIdentifiers(source)[1]
    local adminName = GetPlayerName(source)
    
    -- Insert into global bans table
    local insertId = MySQL.insert.await([[
        INSERT INTO ec_host_global_bans 
        (identifier, player_name, reason, banned_by, banned_at, expires_at, is_permanent, active, applied_cities, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1, '[]', ?)
    ]], {
        banData.identifier,
        banData.playerName,
        banData.reason,
        adminName,
        os.time(),
        banData.expiresAt or nil,
        banData.isPermanent and 1 or 0,
        banData.notes or ''
    })
    
    if not insertId then
        return false, 'Database error'
    end
    
    -- Send to global-bans API
    local endpoint = '/api/v1/bans/global'
    local data = {
        banId = insertId,
        identifier = banData.identifier,
        playerName = banData.playerName,
        reason = banData.reason,
        bannedBy = adminName,
        bannedAt = os.time(),
        expiresAt = banData.expiresAt,
        isPermanent = banData.isPermanent,
        applyToAllCities = true
    }
    
    exports['ec_admin_ultimate']:CallHostAPI(endpoint, 'POST', data, function(success, response)
        if success then
            -- Get connected cities and apply ban
            local cities = exports['ec_admin_ultimate']:GetConnectedCities()
            local appliedCities = {}
            
            for _, city in ipairs(cities) do
                exports['ec_admin_ultimate']:ExecuteCityCommand(source, city.id, 'apply_ban', {
                    identifier = banData.identifier,
                    playerName = banData.playerName,
                    reason = banData.reason,
                    bannedBy = adminName,
                    duration = banData.duration,
                    globalBanId = insertId
                })
                table.insert(appliedCities, city.id)
            end
            
            -- Update applied cities
            MySQL.update('UPDATE ec_host_global_bans SET applied_cities = ? WHERE id = ?', 
                {json.encode(appliedCities), insertId})
            
            -- Log action
            LogHostAction(source, 'GLOBAL_BAN_APPLIED', {
                banId = insertId,
                identifier = banData.identifier,
                playerName = banData.playerName,
                citiesCount = #appliedCities
            })
            
            -- Send webhook
            SendHostWebhook('global_ban', {
                banId = insertId,
                identifier = banData.identifier,
                playerName = banData.playerName,
                reason = banData.reason,
                bannedBy = adminName,
                isPermanent = banData.isPermanent,
                citiesApplied = #appliedCities
            })
        end
    end)
    
    return true, 'Global ban applied to all cities', insertId
end

-- Remove global ban from all cities
function RemoveGlobalBan(source, banId, reason)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.unban') then
        return false, 'No permission'
    end
    
    -- Get ban details
    local ban = MySQL.single.await('SELECT * FROM ec_host_global_bans WHERE id = ?', {banId})
    
    if not ban then
        return false, 'Ban not found'
    end
    
    local adminName = GetPlayerName(source)
    
    -- Mark as inactive
    MySQL.update('UPDATE ec_host_global_bans SET active = 0 WHERE id = ?', {banId})
    
    -- Send to global-bans API
    local endpoint = '/api/v1/bans/global/' .. banId
    
    exports['ec_admin_ultimate']:CallHostAPI(endpoint, 'DELETE', {
        removedBy = adminName,
        reason = reason
    }, function(success, response)
        if success then
            -- Get connected cities and remove ban
            local cities = exports['ec_admin_ultimate']:GetConnectedCities()
            
            for _, city in ipairs(cities) do
                exports['ec_admin_ultimate']:ExecuteCityCommand(source, city.id, 'remove_ban', {
                    identifier = ban.identifier,
                    globalBanId = banId,
                    removedBy = adminName,
                    reason = reason
                })
            end
            
            -- Log action
            LogHostAction(source, 'GLOBAL_BAN_REMOVED', {
                banId = banId,
                identifier = ban.identifier,
                playerName = ban.player_name,
                reason = reason,
                citiesCount = #cities
            })
            
            -- Send webhook
            SendHostWebhook('global_unban', {
                banId = banId,
                identifier = ban.identifier,
                playerName = ban.player_name,
                removedBy = adminName,
                reason = reason,
                citiesAffected = #cities
            })
        end
    end)
    
    return true, 'Global ban removed from all cities'
end

-- Get all global bans
function GetGlobalBans(filters)
    local query = 'SELECT * FROM ec_host_global_bans WHERE 1=1'
    local params = {}
    
    if filters then
        if filters.active ~= nil then
            query = query .. ' AND active = ?'
            table.insert(params, filters.active and 1 or 0)
        end
        
        if filters.identifier then
            query = query .. ' AND identifier LIKE ?'
            table.insert(params, '%' .. filters.identifier .. '%')
        end
        
        if filters.playerName then
            query = query .. ' AND player_name LIKE ?'
            table.insert(params, '%' .. filters.playerName .. '%')
        end
    end
    
    query = query .. ' ORDER BY banned_at DESC LIMIT 100'
    
    return MySQL.query.await(query, params) or {}
end

-- Get ban appeals
function GetBanAppeals(filters)
    local query = [[
        SELECT ba.*, gb.identifier, gb.player_name, gb.reason as ban_reason, gb.banned_by, gb.banned_at
        FROM ec_host_ban_appeals ba
        LEFT JOIN ec_host_global_bans gb ON ba.ban_id = gb.id
        WHERE 1=1
    ]]
    local params = {}
    
    if filters then
        if filters.status then
            query = query .. ' AND ba.status = ?'
            table.insert(params, filters.status)
        end
        
        if filters.banId then
            query = query .. ' AND ba.ban_id = ?'
            table.insert(params, filters.banId)
        end
    end
    
    query = query .. ' ORDER BY ba.submitted_at DESC LIMIT 100'
    
    return MySQL.query.await(query, params) or {}
end

-- Submit ban appeal
function SubmitBanAppeal(banId, appealData)
    local insertId = MySQL.insert.await([[
        INSERT INTO ec_host_ban_appeals 
        (ban_id, appeal_reason, evidence, contact_info, submitted_at, status)
        VALUES (?, ?, ?, ?, ?, 'pending')
    ]], {
        banId,
        appealData.reason,
        appealData.evidence or '',
        appealData.contactInfo or '',
        os.time()
    })
    
    if insertId then
        -- Send webhook notification
        SendHostWebhook('ban_appeal_submitted', {
            appealId = insertId,
            banId = banId,
            reason = appealData.reason
        })
        
        return true, 'Ban appeal submitted', insertId
    end
    
    return false, 'Failed to submit appeal'
end

-- Process ban appeal (approve/deny)
function ProcessBanAppeal(source, appealId, action, reviewNotes)
    if not exports['ec_admin_ultimate']:HasPermission(source, 'ec_admin.host.appeals') then
        return false, 'No permission'
    end
    
    local adminName = GetPlayerName(source)
    local status = action == 'approve' and 'approved' or 'denied'
    
    -- Update appeal
    MySQL.update([[
        UPDATE ec_host_ban_appeals 
        SET status = ?, reviewed_by = ?, reviewed_at = ?, review_notes = ?
        WHERE id = ?
    ]], {status, adminName, os.time(), reviewNotes or '', appealId})
    
    -- If approved, remove the global ban
    if action == 'approve' then
        local appeal = MySQL.single.await('SELECT * FROM ec_host_ban_appeals WHERE id = ?', {appealId})
        if appeal and appeal.ban_id then
            RemoveGlobalBan(source, appeal.ban_id, 'Ban appeal approved: ' .. appealId)
        end
    end
    
    -- Log action
    LogHostAction(source, 'BAN_APPEAL_PROCESSED', {
        appealId = appealId,
        action = action,
        reviewNotes = reviewNotes
    })
    
    -- Send webhook
    SendHostWebhook('ban_appeal_processed', {
        appealId = appealId,
        action = action,
        reviewedBy = adminName,
        notes = reviewNotes
    })
    
    return true, 'Ban appeal ' .. status
end

-- Log host action
function LogHostAction(source, actionType, details)
    local identifier = GetPlayerIdentifiers(source)[1]
    local playerName = GetPlayerName(source)
    
    MySQL.insert([[
        INSERT INTO ec_host_actions (admin_id, admin_name, action_type, details, timestamp)
        VALUES (?, ?, ?, ?, ?)
    ]], {identifier, playerName, actionType, json.encode(details), os.time()})
    
    -- Send to audit-logging API
    exports['ec_admin_ultimate']:CallHostAPI('/api/v1/audit/log', 'POST', {
        adminId = identifier,
        adminName = playerName,
        actionType = actionType,
        details = details,
        timestamp = os.time()
    })
end

-- Send host webhook
function SendHostWebhook(eventType, data)
    -- Get webhook URL from database or config
    local webhook = MySQL.single.await([[
        SELECT webhook_url FROM ec_host_webhooks 
        WHERE event_type = ? AND enabled = 1
    ]], {eventType})
    
    if webhook and webhook.webhook_url then
        -- Send via webhook-relay API
        exports['ec_admin_ultimate']:CallHostAPI('/api/v1/webhooks/send', 'POST', {
            webhookUrl = webhook.webhook_url,
            eventType = eventType,
            data = data,
            timestamp = os.time()
        })
    end
end

-- Export functions
exports('ApplyGlobalBan', ApplyGlobalBan)
exports('RemoveGlobalBan', RemoveGlobalBan)
exports('GetGlobalBans', GetGlobalBans)
exports('GetBanAppeals', GetBanAppeals)
exports('SubmitBanAppeal', SubmitBanAppeal)
exports('ProcessBanAppeal', ProcessBanAppeal)

Logger.Info('🔨 Host Global Bans system loaded')
