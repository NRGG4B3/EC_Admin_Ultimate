--[[
    EC Admin Ultimate - Host API: Analytics
    Aggregated analytics across all servers
    DISABLED: RegisterNUICallback is client-side only
]]

local CREATE_TABLES = [[
    CREATE TABLE IF NOT EXISTS `nrg_analytics_players` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `server_id` VARCHAR(100) NOT NULL,
        `total_players` INT DEFAULT 0,
        `new_players` INT DEFAULT 0,
        `returning_players` INT DEFAULT 0,
        `peak_players` INT DEFAULT 0,
        `avg_session_time` INT DEFAULT 0,
        `recorded_date` DATE NOT NULL,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY unique_server_date (server_id, recorded_date),
        INDEX idx_date (recorded_date)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    CREATE TABLE IF NOT EXISTS `nrg_analytics_economy` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `server_id` VARCHAR(100) NOT NULL,
        `currency_type` VARCHAR(50) DEFAULT 'cash',
        `total_in_circulation` BIGINT DEFAULT 0,
        `total_transactions` INT DEFAULT 0,
        `avg_transaction_value` DECIMAL(15,2) DEFAULT 0,
        `inflation_rate` FLOAT DEFAULT 0,
        `recorded_date` DATE NOT NULL,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_server_date (server_id, recorded_date)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    CREATE TABLE IF NOT EXISTS `nrg_analytics_performance` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `server_id` VARCHAR(100) NOT NULL,
        `avg_cpu` FLOAT DEFAULT 0,
        `avg_memory` FLOAT DEFAULT 0,
        `avg_tick_rate` FLOAT DEFAULT 0,
        `total_errors` INT DEFAULT 0,
        `total_warnings` INT DEFAULT 0,
        `uptime_percentage` FLOAT DEFAULT 100,
        `recorded_date` DATE NOT NULL,
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_server_date (server_id, recorded_date)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    
    CREATE TABLE IF NOT EXISTS `nrg_analytics_events` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `server_id` VARCHAR(100) NOT NULL,
        `event_type` VARCHAR(100) NOT NULL,
        `event_count` INT DEFAULT 1,
        `event_data` TEXT,
        `severity` ENUM('info', 'warning', 'error', 'critical') DEFAULT 'info',
        `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_server_type (server_id, event_type),
        INDEX idx_created (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

CreateThread(function()
    Wait(1000)
    if MySQL then
        MySQL.Async.execute(CREATE_TABLES, {}, function()
            print('[NRG Analytics] Database initialized')
        end)
    end
end)

-- =====================================================
--  API ENDPOINTS
-- =====================================================

-- GET /api/analytics/overview - Global overview
RegisterNUICallback('host/analytics/overview', function(data, cb)
    local timeRange = data.timeRange or 'today' -- today, week, month, year
    
    local dateFilter = ''
    if timeRange == 'today' then
        dateFilter = 'recorded_date = CURDATE()'
    elseif timeRange == 'week' then
        dateFilter = 'recorded_date >= CURDATE() - INTERVAL 7 DAY'
    elseif timeRange == 'month' then
        dateFilter = 'recorded_date >= CURDATE() - INTERVAL 30 DAY'
    elseif timeRange == 'year' then
        dateFilter = 'recorded_date >= CURDATE() - INTERVAL 365 DAY'
    end
    
    -- Get player stats
    MySQL.Async.fetchAll([[
        SELECT 
            SUM(total_players) as total_players,
            SUM(new_players) as new_players,
            MAX(peak_players) as peak_players,
            AVG(avg_session_time) as avg_session_time
        FROM nrg_analytics_players
        WHERE ]] .. dateFilter, {}, function(playerStats)
        
        -- Get economy stats
        MySQL.Async.fetchAll([[
            SELECT 
                currency_type,
                SUM(total_in_circulation) as total_circulation,
                SUM(total_transactions) as total_transactions,
                AVG(avg_transaction_value) as avg_transaction
            FROM nrg_analytics_economy
            WHERE ]] .. dateFilter .. [[
            GROUP BY currency_type
        ]], {}, function(economyStats)
            
            -- Get performance stats
            MySQL.Async.fetchAll([[
                SELECT 
                    AVG(avg_cpu) as avg_cpu,
                    AVG(avg_memory) as avg_memory,
                    AVG(avg_tick_rate) as avg_tick,
                    SUM(total_errors) as total_errors,
                    AVG(uptime_percentage) as avg_uptime
                FROM nrg_analytics_performance
                WHERE ]] .. dateFilter, {}, function(perfStats)
                
                -- Get active servers count
                MySQL.Async.fetchScalar([[
                    SELECT COUNT(*) 
                    FROM nrg_servers 
                    WHERE is_active = 1
                ]], {}, function(activeServers)
                    
                    cb({
                        success = true,
                        overview = {
                            players = playerStats[1] or {},
                            economy = economyStats or {},
                            performance = perfStats[1] or {},
                            activeServers = activeServers or 0,
                            timeRange = timeRange
                        }
                    })
                end)
            end)
        end)
    end)
end)

-- POST /api/analytics/report - Submit analytics report (from customer server)
RegisterNUICallback('host/analytics/report', function(data, cb)
    local serverId = data.serverId
    local reportType = data.reportType -- 'players', 'economy', 'performance'
    local reportData = data.data
    
    if not serverId or not reportType or not reportData then
        cb({ success = false, error = 'Missing required fields' })
        return
    end
    
    local today = os.date('%Y-%m-%d')
    
    if reportType == 'players' then
        MySQL.Async.execute([[
            INSERT INTO nrg_analytics_players 
            (server_id, total_players, new_players, returning_players, peak_players, avg_session_time, recorded_date)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                total_players = VALUES(total_players),
                new_players = VALUES(new_players),
                returning_players = VALUES(returning_players),
                peak_players = GREATEST(peak_players, VALUES(peak_players)),
                avg_session_time = VALUES(avg_session_time)
        ]], {
            serverId,
            reportData.totalPlayers or 0,
            reportData.newPlayers or 0,
            reportData.returningPlayers or 0,
            reportData.peakPlayers or 0,
            reportData.avgSessionTime or 0,
            today
        }, function()
            cb({ success = true, message = 'Player analytics recorded' })
        end)
        
    elseif reportType == 'economy' then
        MySQL.Async.execute([[
            INSERT INTO nrg_analytics_economy 
            (server_id, currency_type, total_in_circulation, total_transactions, avg_transaction_value, inflation_rate, recorded_date)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                total_in_circulation = VALUES(total_in_circulation),
                total_transactions = total_transactions + VALUES(total_transactions),
                avg_transaction_value = VALUES(avg_transaction_value),
                inflation_rate = VALUES(inflation_rate)
        ]], {
            serverId,
            reportData.currencyType or 'cash',
            reportData.totalCirculation or 0,
            reportData.totalTransactions or 0,
            reportData.avgTransaction or 0,
            reportData.inflationRate or 0,
            today
        }, function()
            cb({ success = true, message = 'Economy analytics recorded' })
        end)
        
    elseif reportType == 'performance' then
        MySQL.Async.execute([[
            INSERT INTO nrg_analytics_performance 
            (server_id, avg_cpu, avg_memory, avg_tick_rate, total_errors, total_warnings, uptime_percentage, recorded_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                avg_cpu = (avg_cpu + VALUES(avg_cpu)) / 2,
                avg_memory = (avg_memory + VALUES(avg_memory)) / 2,
                avg_tick_rate = (avg_tick_rate + VALUES(avg_tick_rate)) / 2,
                total_errors = total_errors + VALUES(total_errors),
                total_warnings = total_warnings + VALUES(total_warnings),
                uptime_percentage = VALUES(uptime_percentage)
        ]], {
            serverId,
            reportData.avgCPU or 0,
            reportData.avgMemory or 0,
            reportData.avgTickRate or 0,
            reportData.totalErrors or 0,
            reportData.totalWarnings or 0,
            reportData.uptimePercentage or 100,
            today
        }, function()
            cb({ success = true, message = 'Performance analytics recorded' })
        end)
    else
        cb({ success = false, error = 'Invalid report type' })
    end
end)

-- POST /api/analytics/event - Log analytics event
RegisterNUICallback('host/analytics/event', function(data, cb)
    local serverId = data.serverId
    local eventType = data.eventType
    local eventData = data.eventData or {}
    local severity = data.severity or 'info'
    
    if not serverId or not eventType then
        cb({ success = false, error = 'Missing required fields' })
        return
    end
    
    MySQL.Async.execute([[
        INSERT INTO nrg_analytics_events 
        (server_id, event_type, event_data, severity)
        VALUES (?, ?, ?, ?)
    ]], {
        serverId,
        eventType,
        json.encode(eventData),
        severity
    }, function()
        cb({ success = true, message = 'Event logged' })
    end)
end)

-- GET /api/analytics/trends - Get trend data
RegisterNUICallback('host/analytics/trends', function(data, cb)
    local serverId = data.serverId -- optional, all servers if not provided
    local metric = data.metric -- 'players', 'economy', 'performance'
    local days = data.days or 30
    
    if not metric then
        cb({ success = false, error = 'Missing metric' })
        return
    end
    
    local serverFilter = serverId and 'AND server_id = ' .. MySQL.Sync.escape(serverId) or ''
    local table = 'nrg_analytics_' .. metric
    
    MySQL.Async.fetchAll([[
        SELECT * FROM ]] .. table .. [[ 
        WHERE recorded_date >= CURDATE() - INTERVAL ? DAY
        ]] .. serverFilter .. [[
        ORDER BY recorded_date ASC
    ]], {days}, function(trends)
        cb({
            success = true,
            trends = trends,
            metric = metric,
            days = days
        })
    end)
end)

Logger.Info('host/api/analytics.lua loaded (NUI callbacks disabled)')
return