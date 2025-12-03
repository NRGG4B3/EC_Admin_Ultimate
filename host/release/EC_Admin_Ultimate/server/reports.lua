--[[
    EC Admin Ultimate - Reports Main Logic
    Core report management functions
]]

local Reports = {}

-- ==========================================
-- REPORT MANAGEMENT
-- ==========================================

function Reports.GetAll(filters)
    if not MySQL then
        return {}
    end
    
    local query = 'SELECT * FROM ec_admin_reports'
    local params = {}
    local where = {}
    
    if filters then
        if filters.status then
            table.insert(where, 'status = ?')
            table.insert(params, filters.status)
        end
        
        if filters.type then
            table.insert(where, 'type = ?')
            table.insert(params, filters.type)
        end
    end
    
    if #where > 0 then
        query = query .. ' WHERE ' .. table.concat(where, ' AND ')
    end
    
    query = query .. ' ORDER BY timestamp DESC LIMIT 100'
    
    local result = MySQL.query.await(query, params)
    return result or {}
end

function Reports.GetById(reportId)
    if not MySQL or not reportId then
        return nil
    end
    
    local result = MySQL.query.await('SELECT * FROM ec_admin_reports WHERE id = ?', {reportId})
    return result and result[1] or nil
end

function Reports.Create(data)
    if not MySQL then
        return false, 'Database not available'
    end
    
    local success = MySQL.insert.await([[
        INSERT INTO ec_admin_reports 
        (reporter_id, reporter_name, target_id, target_name, type, reason, description, status, timestamp) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.reporterId,
        data.reporterName,
        data.targetId,
        data.targetName,
        data.type or 'other',
        data.reason or 'No reason provided',
        data.description or '',
        'open',
        os.time()
    })
    
    return success ~= nil, success
end

function Reports.Update(reportId, updates)
    if not MySQL or not reportId then
        return false
    end
    
    local set = {}
    local params = {}
    
    if updates.status then
        table.insert(set, 'status = ?')
        table.insert(params, updates.status)
    end
    
    if updates.admin_id then
        table.insert(set, 'admin_id = ?')
        table.insert(params, updates.admin_id)
    end
    
    if updates.admin_name then
        table.insert(set, 'admin_name = ?')
        table.insert(params, updates.admin_name)
    end
    
    if updates.response then
        table.insert(set, 'admin_response = ?')
        table.insert(params, updates.response)
    end
    
    if #set == 0 then
        return false
    end
    
    table.insert(params, reportId)
    
    local query = 'UPDATE ec_admin_reports SET ' .. table.concat(set, ', ') .. ' WHERE id = ?'
    local success = MySQL.update.await(query, params)
    
    return success > 0
end

function Reports.Delete(reportId)
    if not MySQL or not reportId then
        return false
    end
    
    local success = MySQL.execute.await('DELETE FROM ec_admin_reports WHERE id = ?', {reportId})
    return success > 0
end

function Reports.GetStats()
    if not MySQL then
        return {
            total = 0,
            open = 0,
            closed = 0,
            resolved = 0
        }
    end
    
    local total = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_reports')
    local open = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_reports WHERE status = ?', {'open'})
    local closed = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_reports WHERE status = ?', {'closed'})
    local resolved = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_reports WHERE status = ?', {'resolved'})
    
    return {
        total = total and total[1] and total[1].count or 0,
        open = open and open[1] and open[1].count or 0,
        closed = closed and closed[1] and closed[1].count or 0,
        resolved = resolved and resolved[1] and resolved[1].count or 0
    }
end

-- ==========================================
-- EXPORT
-- ==========================================

_G.Reports = Reports

Logger.Info("^7 Reports main logic loaded")
