--[[
    EC Admin Ultimate - Reports Actions
    Event handlers for report management actions
]]

-- ==========================================
-- CREATE REPORT
-- ==========================================

RegisterNetEvent('ec_admin:createReport', function(data)
    local src = source
    
    if not data or not data.targetId or not data.reason then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'Invalid report data'
        })
        return
    end
    
    local reporterName = GetPlayerName(src) or 'Unknown'
    local targetName = GetPlayerName(tonumber(data.targetId)) or 'Unknown'
    
    local success, reportId = Reports.Create({
        reporterId = src,
        reporterName = reporterName,
        targetId = data.targetId,
        targetName = targetName,
        type = data.type or 'other',
        reason = data.reason,
        description = data.description or ''
    })
    
    if success then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = 'Report submitted successfully'
        })
        
        -- Notify all admins
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local id = tonumber(playerId)
            if id and HasPermission and HasPermission(id) then
                TriggerClientEvent('ec_admin:newReport', id, {
                    id = reportId,
                    reporter = reporterName,
                    target = targetName,
                    reason = data.reason
                })
            end
        end
        
        -- Log activity
        TriggerEvent('ec_admin:logActivity', {
            type = 'report_created',
            admin = reporterName,
            target = targetName,
            description = 'Created report: ' .. data.reason
        })
    else
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'Failed to create report'
        })
    end
end)

-- ==========================================
-- HANDLE REPORT
-- ==========================================

RegisterNetEvent('ec_admin:handleReport', function(data)
    local src = source
    
    if not data or not data.reportId then return end
    
    if not HasPermission or not HasPermission(src) then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'error',
            message = 'No permission'
        })
        return
    end
    
    local adminName = GetPlayerName(src) or 'Unknown'
    
    local success = Reports.Update(data.reportId, {
        status = 'in_progress',
        admin_id = src,
        admin_name = adminName
    })
    
    if success then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = 'Now handling report'
        })
        
        -- Log activity
        TriggerEvent('ec_admin:logActivity', {
            type = 'report_handled',
            admin = adminName,
            target = 'Report #' .. data.reportId,
            description = 'Started handling report'
        })
    end
end)

-- ==========================================
-- RESOLVE REPORT
-- ==========================================

RegisterNetEvent('ec_admin:resolveReport', function(data)
    local src = source
    
    if not data or not data.reportId then return end
    
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    local adminName = GetPlayerName(src) or 'Unknown'
    
    local success = Reports.Update(data.reportId, {
        status = 'resolved',
        admin_id = src,
        admin_name = adminName,
        response = data.response or 'Resolved'
    })
    
    if success then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = 'Report resolved'
        })
        
        -- Notify reporter if online
        local report = Reports.GetById(data.reportId)
        if report and report.reporter_id then
            local reporterId = tonumber(report.reporter_id)
            if reporterId and GetPlayerName(reporterId) then
                TriggerClientEvent('ec_admin:reportResolved', reporterId, {
                    id = data.reportId,
                    response = data.response
                })
            end
        end
        
        -- Log activity
        TriggerEvent('ec_admin:logActivity', {
            type = 'report_resolved',
            admin = adminName,
            target = 'Report #' .. data.reportId,
            description = 'Resolved report'
        })
    end
end)

-- ==========================================
-- CLOSE REPORT
-- ==========================================

RegisterNetEvent('ec_admin:closeReport', function(data)
    local src = source
    
    if not data or not data.reportId then return end
    
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    local adminName = GetPlayerName(src) or 'Unknown'
    
    local success = Reports.Update(data.reportId, {
        status = 'closed',
        admin_id = src,
        admin_name = adminName,
        response = data.response or 'Closed'
    })
    
    if success then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = 'Report closed'
        })
        
        -- Log activity
        TriggerEvent('ec_admin:logActivity', {
            type = 'report_closed',
            admin = adminName,
            target = 'Report #' .. data.reportId,
            description = 'Closed report'
        })
    end
end)

-- ==========================================
-- DELETE REPORT
-- ==========================================

RegisterNetEvent('ec_admin:deleteReport', function(data)
    local src = source
    
    if not data or not data.reportId then return end
    
    if not IsPlayerAceAllowed(src, 'admin.access') then return end
    
    local adminName = GetPlayerName(src) or 'Unknown'
    
    local success = Reports.Delete(data.reportId)
    
    if success then
        TriggerClientEvent('ec_admin:notify', src, {
            type = 'success',
            message = 'Report deleted'
        })
        
        -- Log activity
        TriggerEvent('ec_admin:logActivity', {
            type = 'report_deleted',
            admin = adminName,
            target = 'Report #' .. data.reportId,
            description = 'Deleted report'
        })
    end
end)

Logger.Info("^7 Reports actions loaded")
