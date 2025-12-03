--[[
    EC Admin Ultimate - Client-Side Logger
    Centralized logging controlled by Config.LogLevel
    
    Usage:
        Logger.Debug('Debug message', 'icon')
        Logger.Info('Info message', 'icon')
        Logger.Warn('Warning message', 'icon')
        Logger.Error('Error message', 'icon')
        Logger.Success('Success message', 'icon')
]]

Logger = {}

-- Color codes
local Colors = {
    DEBUG = '^5',    -- Purple
    INFO = '^4',     -- Blue
    WARN = '^3',     -- Yellow
    ERROR = '^1',    -- Red
    SUCCESS = '^2',  -- Green
    RESET = '^7'     -- White
}

-- Log level configuration
local LogLevel = {
    DEBUG = 0,
    INFO = 1,
    SUCCESS = 1,
    WARN = 2,
    ERROR = 3,
    NONE = 99
}

-- Current log level
local currentLevel = LogLevel.INFO
local showIcons = true

-- Initialize from config
CreateThread(function()
    Wait(500)
    
    if Config and Config.LogLevel then
        local configuredLevel = Config.LogLevel:upper()
        currentLevel = LogLevel[configuredLevel] or LogLevel.INFO
    end
    
    if Config and Config.LogIcons ~= nil then
        showIcons = Config.LogIcons
    end
    
    if Config and Config.Debug then
        currentLevel = LogLevel.DEBUG
    end
end)

-- Format log message
local function formatMessage(level, msg, icon)
    local color = Colors[level] or Colors.INFO
    local prefix = '^3[EC Admin]^0'
    
    if showIcons and icon then
        return string.format('%s %s %s%s^0', prefix, icon, color, msg)
    else
        return string.format('%s %s%s^0', prefix, color, msg)
    end
end

-- Check if message should be logged
local function shouldLog(level)
    return currentLevel <= LogLevel[level]
end

-- Debug logging
function Logger.Debug(msg, icon)
    if shouldLog('DEBUG') then
        print(formatMessage('DEBUG', msg, icon or '🐛'))
    end
end

-- Info logging
function Logger.Info(msg, icon)
    if shouldLog('INFO') then
        print(formatMessage('INFO', msg, icon or 'ℹ'))
    end
end

-- Success logging
function Logger.Success(msg, icon)
    if shouldLog('SUCCESS') then
        print(formatMessage('SUCCESS', msg, icon or '✅'))
    end
end

-- Warning logging
function Logger.Warn(msg, icon)
    if shouldLog('WARN') then
        print(formatMessage('WARN', msg, icon or '⚠'))
    end
end

-- Error logging (always shows unless NONE)
function Logger.Error(msg, icon)
    if shouldLog('ERROR') then
        print(formatMessage('ERROR', msg, icon or '❌'))
    end
end

-- System logging (same level as INFO)
function Logger.System(msg, icon)
    if shouldLog('INFO') then
        print(formatMessage('INFO', msg, icon or '🔧'))
    end
end
