--[[
    EC Admin Ultimate - Dashboard Main Logic
    Core dashboard data aggregation and statistics
]]

local Dashboard = {}

-- ==========================================
-- SERVER STATISTICS
-- ==========================================

function Dashboard.GetServerStats()
    local players = GetPlayers()
    local resourceCount = GetNumResources()
    
    return {
        players = {
            online = #players,
            max = GetConvarInt('sv_maxclients', 32)
        },
        server = {
            name = GetConvar('sv_hostname', 'FiveM Server'),
            uptime = os.time(),
            resources = resourceCount
        }
    }
end

function Dashboard.GetResourceList()
    local resources = {}
    local resourceCount = GetNumResources()
    
    for i = 0, resourceCount - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local state = GetResourceState(resourceName)
            table.insert(resources, {
                name = resourceName,
                state = state,
                running = state == 'started'
            })
        end
    end
    
    return resources
end

function Dashboard.GetSystemHealth()
    return {
        cpu = 0, -- Cannot get from Lua
        memory = collectgarbage('count'),
        threads = 0,
        uptime = os.time()
    }
end

-- ==========================================
-- ACTIVITY STATISTICS
-- ==========================================

local activityLog = {}
local MAX_ACTIVITY_LOGS = 100

function Dashboard.LogActivity(activity)
    table.insert(activityLog, 1, {
        timestamp = os.time(),
        type = activity.type,
        admin = activity.admin,
        target = activity.target,
        description = activity.description
    })
    
    -- Keep only last 100 activities
    if #activityLog > MAX_ACTIVITY_LOGS then
        table.remove(activityLog, #activityLog)
    end
end

function Dashboard.GetRecentActivity(limit)
    limit = limit or 20
    local result = {}
    
    for i = 1, math.min(limit, #activityLog) do
        table.insert(result, activityLog[i])
    end
    
    return result
end

-- ==========================================
-- QUICK STATS
-- ==========================================

function Dashboard.GetQuickStats()
    local players = #GetPlayers()
    
    -- Get reports count
    local reportsCount = 0
    if MySQL then
        local result = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_reports WHERE status = ?', {'open'})
        if result and result[1] then
            reportsCount = result[1].count or 0
        end
    end
    
    -- Get warnings count (today)
    local warningsToday = 0
    if MySQL then
        local todayStart = os.time() - (24 * 60 * 60)
        local result = MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_warnings WHERE timestamp >= ?', {todayStart})
        if result and result[1] then
            warningsToday = result[1].count or 0
        end
    end
    
    -- Get bans count (active) with error handling
    local activeBans = 0
    if MySQL then
        local success, result = pcall(function()
            return MySQL.query.await('SELECT COUNT(*) as count FROM ec_admin_bans WHERE is_active = ?', {1})
        end)
        if success and result and result[1] then
            activeBans = result[1].count or 0
        end
    end
    
    return {
        players = players,
        reports = reportsCount,
        warnings = warningsToday,
        bans = activeBans
    }
end

-- ==========================================
-- EXPORT
-- ==========================================

_G.Dashboard = Dashboard

-- Log activity globally
RegisterNetEvent('ec_admin:logActivity', function(activity)
    Dashboard.LogActivity(activity)
end)

Logger.Info("^7 Dashboard main logic loaded")