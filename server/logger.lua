--[[
    EC Admin Ultimate - Centralized Logger
    Provides unified logging system for all server-side scripts
    
    Usage:
    Logger.Info('message')
    Logger.Success('message')
    Logger.Warn('message')
    Logger.Error('message')
    Logger.Debug('message')
]]

Logger = Logger or {}

-- Configuration (can be overridden by config.lua)
local LogLevel = 'INFO' -- DEBUG, INFO, WARN, ERROR, NONE
local LogFormat = 'detailed' -- simple, detailed, minimal
local LogIcons = false
local DebugMode = false

-- Load config if available
if Config then
    if Config.LogLevel then LogLevel = string.upper(Config.LogLevel) end
    if Config.LogFormat then LogFormat = Config.LogFormat end
    if Config.LogIcons ~= nil then LogIcons = Config.LogIcons end
    if Config.Debug then DebugMode = Config.Debug end
end

-- Log level hierarchy
local LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    NONE = 5
}

local currentLogLevel = LOG_LEVELS[LogLevel] or LOG_LEVELS.INFO

-- Helper: Get timestamp
local function getTimestamp()
    if LogFormat == 'detailed' then
        return os.date('[%Y-%m-%d %H:%M:%S]')
    end
    return ''
end

-- Helper: Format message
local function formatMessage(level, message, icon)
    local prefix = '[EC Admin]'
    local timestamp = getTimestamp()
    
    if LogFormat == 'minimal' then
        return string.format('%s %s %s', prefix, timestamp, message)
    elseif LogFormat == 'simple' then
        if LogIcons and icon then
            return string.format('%s %s %s', prefix, icon, message)
        end
        return string.format('%s %s', prefix, message)
    else -- detailed
        local levelStr = string.format('[%s]', level)
        if LogIcons and icon then
            return string.format('%s %s %s %s %s', timestamp, icon, prefix, levelStr, message)
        end
        return string.format('%s %s %s %s', timestamp, prefix, levelStr, message)
    end
end

-- Helper: Should log
local function shouldLog(level)
    if DebugMode and level == 'DEBUG' then
        return true
    end
    local levelNum = LOG_LEVELS[level] or LOG_LEVELS.INFO
    return levelNum >= currentLogLevel
end

-- Logger functions
function Logger.Info(message)
    if shouldLog('INFO') then
        print(formatMessage('INFO', message, LogIcons and '✅' or nil))
    end
end

function Logger.Success(message)
    if shouldLog('INFO') then
        print(formatMessage('SUCCESS', message, LogIcons and '✅' or nil))
    end
end

function Logger.Warn(message)
    if shouldLog('WARN') then
        print(formatMessage('WARN', message, LogIcons and '⚠️' or nil))
    end
end

function Logger.Error(message)
    if shouldLog('ERROR') then
        print(formatMessage('ERROR', message, LogIcons and '❌' or nil))
    end
end

function Logger.Debug(message)
    if shouldLog('DEBUG') then
        print(formatMessage('DEBUG', message, LogIcons and '🔍' or nil))
    end
end

-- NUI Error Logging (if enabled)
function Logger.NUIError(errorType, errorMessage, errorDetails)
    if not Config or not Config.LogNUIErrors then
        return  -- NUI error logging disabled
    end
    
    local detailsStr = ''
    if errorDetails then
        if type(errorDetails) == 'table' then
            detailsStr = ' | ' .. json.encode(errorDetails)
        else
            detailsStr = ' | ' .. tostring(errorDetails)
        end
    end
    
    local fullMessage = string.format("[NUI] [%s] %s%s", errorType, errorMessage, detailsStr)
    Logger.Error(fullMessage)
end

-- Export
_G.Logger = Logger

print("^2[Logger]^7 Centralized logging system loaded^0")

