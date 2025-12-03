--[[
    EC Admin Ultimate - Logger Module
    Centralized logging with levels and formatting
    
    Usage:
        Logger.Debug('Debug message', 'icon')
        Logger.Info('Info message', 'icon')
        Logger.Warn('Warning message', 'icon')
        Logger.Error('Error message', 'icon')
        Logger.Success('Success message', 'icon')
]]

local Logger = {}

-- Color codes
local Colors = {
    DEBUG = '^5',    -- Purple
    INFO = '^4',     -- Blue
    WARN = '^3',     -- Yellow
    ERROR = '^1',    -- Red
    SUCCESS = '^2',  -- Green
    SYSTEM = '^6',   -- Cyan
    RESET = '^7'     -- White
}

-- Log level configuration
-- Lower numbers = more verbose. Each level shows itself + higher severity levels.
-- DEBUG (0): Shows everything (debug + info + success + warn + error + system)
-- INFO (1): Shows info + success + warn + error + system (hides debug)
-- WARN (2): Shows warn + error (hides info, success, debug)
-- ERROR (3): Shows only errors (hides everything else)
-- NONE (99): Shows nothing (complete silence)
local LogLevel = {
    DEBUG = 0,      -- Most verbose
    INFO = 1,       -- Normal operation
    SUCCESS = 1,    -- Same priority as INFO (shown together)
    WARN = 2,       -- Warnings only
    ERROR = 3,      -- Errors only
    SYSTEM = 1,     -- System messages (same as INFO)
    NONE = 99       -- Complete silence
}

-- Current log level and format
-- Initialize immediately from Config (if available) to catch early startup logs
local currentLevel = LogLevel.INFO
local logFormat = 'simple'  -- simple, detailed, minimal
local showIcons = true

-- Try to initialize immediately from Config (synchronous)
if Config and Config.LogLevel then
    local configuredLevel = Config.LogLevel:upper()
    currentLevel = LogLevel[configuredLevel] or LogLevel.INFO
end
if Config and Config.LogFormat then
    logFormat = Config.LogFormat
end
if Config and Config.LogIcons ~= nil then
    showIcons = Config.LogIcons
end

-- Initialize logger settings from config (async update with convars)
CreateThread(function()
    Wait(500)  -- Wait for any late-loading config
    
    -- Determine log format from Config
    if Config and Config.LogFormat then
        logFormat = Config.LogFormat
    end
    
    -- Determine icon display
    if Config and Config.LogIcons ~= nil then
        showIcons = Config.LogIcons
    end
    
    -- Check if debug mode is enabled via convar or Config.Debug
    local debugConvar = GetConvarInt('ec_debug_mode', -1)
    local isDebugEnabled = false
    
    if debugConvar ~= -1 then
        -- Convar overrides everything
        isDebugEnabled = debugConvar == 1
    elseif Config and Config.Debug ~= nil then
        -- Use Config.Debug if set
        isDebugEnabled = Config.Debug
    end
    
    -- Set log level based on debug mode or Config.LogLevel
    if isDebugEnabled then
        currentLevel = LogLevel.DEBUG
        Logger.System('Debug mode ENABLED - Verbose logging active', '🐛')
    else
        -- Use Config.LogLevel or convar or default to INFO
        local configuredLevel = 'INFO'
        if Config and Config.LogLevel then
            configuredLevel = Config.LogLevel:upper()
        else
            configuredLevel = GetConvar('ec_log_level', 'INFO'):upper()
        end
        currentLevel = LogLevel[configuredLevel] or LogLevel.INFO
    end
    
    -- Announce log format (only if not in silent mode)
    if currentLevel < LogLevel.NONE then
        if logFormat == 'detailed' then
            Logger.System('Log format: DETAILED (timestamps + levels)', '📋')
        elseif logFormat == 'minimal' then
            Logger.System('Log format: MINIMAL (no icons)', '📋')
        else
            Logger.System('Log format: SIMPLE (clean)', '📋')
        end
    end
end)

-- Format timestamp
local function GetTimestamp()
    return os.date('[%Y-%m-%d %H:%M:%S]')
end

-- Core logging function with format support
local function Log(level, color, prefix, message, icon)
    if LogLevel[level] < currentLevel then
        return  -- Don't log if below current level
    end
    
    local iconStr = (icon and showIcons) and (icon .. ' ') or ''
    local formattedMessage = ''
    
    if logFormat == 'detailed' then
        -- DETAILED: [2025-12-01 19:40:47] 📊 [EC Admin] [INFO] Message
        local timestamp = GetTimestamp()
        formattedMessage = string.format(
            '%s%s %s[EC Admin] [%s] %s%s',
            color,
            timestamp,
            iconStr,
            level,
            tostring(message),
            Colors.RESET
        )
    elseif logFormat == 'minimal' then
        -- MINIMAL: [EC Admin] Message (no icons, no levels, no timestamps)
        formattedMessage = string.format(
            '%s[EC Admin] %s%s',
            color,
            tostring(message),
            Colors.RESET
        )
    else
        -- SIMPLE (default): [EC Admin] ✅ Message
        formattedMessage = string.format(
            '%s[EC Admin] %s%s%s',
            color,
            iconStr,
            tostring(message),
            Colors.RESET
        )
    end
    
    print(formattedMessage)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Debug: Verbose logging for development (only shown in debug mode)
function Logger.Debug(message, icon)
    Log('DEBUG', Colors.DEBUG, '', message, icon or '🐛')
end

-- Info: General informational messages
function Logger.Info(message, icon)
    Log('INFO', Colors.INFO, '', message, icon or 'ℹ️')
end

-- Warning: Non-critical issues that should be addressed
function Logger.Warn(message, icon)
    Log('WARN', Colors.WARN, '', message, icon or '⚠️')
end

-- Alias for Warn
function Logger.Warning(message, icon)
    Logger.Warn(message, icon)
end

-- Error: Critical issues that need immediate attention
function Logger.Error(message, icon)
    Log('ERROR', Colors.ERROR, '', message, icon or '❌')
end

-- System: Important system-level messages (always shown regardless of level)
function Logger.System(message, icon)
    Log('SYSTEM', Colors.SYSTEM, '', message, icon or '⚙️')
end

-- Success: Positive confirmation messages (shown at SUCCESS level = INFO priority)
function Logger.Success(message, icon)
    Log('SUCCESS', Colors.SUCCESS, '', message, icon or '✅')
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Set log level programmatically
function Logger.SetLevel(level)
    if LogLevel[level:upper()] then
        currentLevel = LogLevel[level:upper()]
        Logger.System('Log level set to: ' .. level:upper())
    else
        Logger.Error('Invalid log level: ' .. tostring(level))
    end
end

-- Get current log level
function Logger.GetLevel()
    for name, value in pairs(LogLevel) do
        if value == currentLevel then
            return name
        end
    end
    return 'UNKNOWN'
end

-- Log with custom color
function Logger.Custom(message, color, icon)
    local timestamp = GetTimestamp()
    local iconStr = icon and (icon .. ' ') or ''
    print(string.format(
        '%s%s %s[EC Admin] %s%s',
        color or Colors.RESET,
        timestamp,
        iconStr,
        tostring(message),
        Colors.RESET
    ))
end

-- Log table/object (for debugging)
function Logger.Table(tbl, name, indent)
    if LogLevel.DEBUG < currentLevel then
        return  -- Don't log tables if not in debug mode
    end
    
    indent = indent or 0
    name = name or 'Table'
    local indentStr = string.rep('  ', indent)
    
    Logger.Debug(indentStr .. name .. ' = {')
    
    if type(tbl) ~= 'table' then
        Logger.Debug(indentStr .. '  ' .. tostring(tbl))
    else
        for k, v in pairs(tbl) do
            if type(v) == 'table' then
                Logger.Table(v, tostring(k), indent + 1)
            else
                Logger.Debug(string.format('%s  %s = %s', indentStr, tostring(k), tostring(v)))
            end
        end
    end
    
    Logger.Debug(indentStr .. '}')
end

-- Log separator line
function Logger.Separator(char, length)
    char = char or '═'
    length = length or 60
    Logger.Custom(string.rep(char, length), Colors.SYSTEM)
end

-- Log section header
function Logger.Section(title)
    Logger.Separator('═', 60)
    Logger.System('  ' .. title:upper())
    Logger.Separator('═', 60)
end

-- ============================================================================
-- OVERRIDE GLOBAL print() TO RESPECT LOG LEVEL
-- ============================================================================

-- Store original print function
local _print = print

-- Override print() to respect LogLevel configuration
print = function(...)
    -- If log level is NONE, suppress all print statements
    if currentLevel >= LogLevel.NONE then
        return
    end
    
    -- Otherwise, call original print
    _print(...)
end

-- ============================================================================
-- EXPORT MODULE AS GLOBAL (so all files can access it without require)
-- ============================================================================

-- Make Logger available globally
_G.Logger = Logger

-- Also return it for files that prefer to require() it
return Logger
