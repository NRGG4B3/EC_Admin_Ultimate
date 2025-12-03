--[[
    EC Admin Ultimate - Player History Tracker
    Tracks player counts every hour for 24-hour activity charts
]]

Logger.Info('📊 Player History Tracker loading...')

-- ============================================================================
-- PLAYER HISTORY STORAGE
-- ============================================================================

PlayerHistory = PlayerHistory or {
    hourly = {},      -- Last 24 hours of data
    peakToday = 0,    -- Peak player count today
    currentCount = 0  -- Current player count
}

-- ============================================================================
-- SAMPLE PLAYER COUNT (Called every 5 minutes)
-- ============================================================================

local function SamplePlayerCount()
    local players = GetPlayers()
    local count = #players
    
    PlayerHistory.currentCount = count
    
    -- Update peak today
    if count > PlayerHistory.peakToday then
        PlayerHistory.peakToday = count
    end
    
    -- Get current hour (0-23)
    local currentHour = tonumber(os.date('%H'))
    local currentDate = os.date('%Y-%m-%d')
    
    -- Initialize hour data if doesn't exist
    if not PlayerHistory.hourly[currentDate] then
        PlayerHistory.hourly[currentDate] = {}
    end
    
    if not PlayerHistory.hourly[currentDate][currentHour] then
        PlayerHistory.hourly[currentDate][currentHour] = {
            hour = currentHour,
            count = count,
            peak = count,
            samples = 1,
            timestamp = os.time()
        }
    else
        -- Update existing hour data
        local hourData = PlayerHistory.hourly[currentDate][currentHour]
        hourData.count = count
        hourData.samples = hourData.samples + 1
        
        if count > hourData.peak then
            hourData.peak = count
        end
        
        hourData.timestamp = os.time()
    end
    
    -- Clean up old data (keep only last 48 hours for safety)
    local cutoffTime = os.time() - (48 * 60 * 60)
    for date, hours in pairs(PlayerHistory.hourly) do
        for hour, data in pairs(hours) do
            if data.timestamp < cutoffTime then
                PlayerHistory.hourly[date][hour] = nil
            end
        end
        
        -- Remove empty dates
        if next(hours) == nil then
            PlayerHistory.hourly[date] = nil
        end
    end
end

-- ============================================================================
-- GET 24-HOUR HISTORY
-- ============================================================================

function GetPlayer24HourHistory()
    local history = {}
    local now = os.time()
    local currentDate = os.date('%Y-%m-%d')
    local currentHour = tonumber(os.date('%H'))
    
    -- Generate last 24 hours
    for i = 23, 0, -1 do
        local timestamp = now - (i * 60 * 60)
        local date = os.date('%Y-%m-%d', timestamp)
        local hour = tonumber(os.date('%H', timestamp))
        local hourLabel = os.date('%I %p', timestamp) -- "01 PM", "02 PM", etc.
        
        local count = 0
        local peak = 0
        
        -- Get data if exists
        if PlayerHistory.hourly[date] and PlayerHistory.hourly[date][hour] then
            local hourData = PlayerHistory.hourly[date][hour]
            count = hourData.count
            peak = hourData.peak
        end
        
        table.insert(history, {
            hour = hourLabel,
            time = hour,
            players = count,
            peak = peak,
            timestamp = timestamp
        })
    end
    
    return history
end

-- ============================================================================
-- RESET DAILY PEAK (at midnight)
-- ============================================================================

local function CheckMidnightReset()
    local currentDate = os.date('%Y-%m-%d')
    
    if not PlayerHistory.lastDate then
        PlayerHistory.lastDate = currentDate
    end
    
    if PlayerHistory.lastDate ~= currentDate then
        -- New day, reset peak
        PlayerHistory.peakToday = 0
        PlayerHistory.lastDate = currentDate
        Logger.Info('📊 Player peak reset for new day')
    end
end

-- ============================================================================
-- START TRACKING
-- ============================================================================

CreateThread(function()
    -- Initial sample
    SamplePlayerCount()
    CheckMidnightReset()
    
    -- Sample every 5 minutes (300,000ms)
    while true do
        Wait(300000)
        SamplePlayerCount()
        CheckMidnightReset()
    end
end)

-- Also sample on player join/leave for more accuracy
AddEventHandler('playerJoining', function()
    Wait(1000) -- Wait for player to fully join
    SamplePlayerCount()
end)

AddEventHandler('playerDropped', function()
    Wait(1000) -- Wait for cleanup
    SamplePlayerCount()
end)

Logger.Info('✅ Player History Tracker started (5min intervals)')
