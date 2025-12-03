--[[
    EC Admin Ultimate - Environment Helper
    Manages DEV / HOST / CUSTOMER modes
    Mode is determined by /host/ folder existence and convars
]]

local Environment = {
    mode = nil,
    modes = {
        DEV = 'DEV',
        HOST = 'HOST',
        CUSTOMER = 'CUSTOMER'
    }
}

-- Check if /host/ folder exists
local function CheckHostFolder()
    -- Try to read any file in /host/ folder
    local hostCheck = LoadResourceFile(GetCurrentResourceName(), 'host/package.json')
    if hostCheck then
        return true
    end
    
    -- Try README.md
    hostCheck = LoadResourceFile(GetCurrentResourceName(), 'host/README.md')
    if hostCheck then
        return true
    end
    
    -- Try .gitkeep
    hostCheck = LoadResourceFile(GetCurrentResourceName(), 'host/.gitkeep')
    if hostCheck then
        return true
    end
    
    return false
end

-- Read host secret from /.host-secret file (root of resource, not /host/)
local function ReadHostSecret()
    -- Try root .host-secret first (preferred location)
    local secret = LoadResourceFile(GetCurrentResourceName(), '.host-secret')
    
    if secret and #secret > 32 then
        -- Trim whitespace
        secret = secret:match('^%s*(.-)%s*$')
        return secret
    end
    
    -- Fallback: try /host/.host-secret
    secret = LoadResourceFile(GetCurrentResourceName(), 'host/.host-secret')
    
    if secret and #secret > 32 then
        secret = secret:match('^%s*(.-)%s*$')
        return secret
    end
    
    -- AUTO-GENERATE if missing (no warnings!)
    local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    secret = 'nrg_host_'
    math.randomseed(os.time())
    for i = 1, 64 do
        local rand = math.random(1, #chars)
        secret = secret .. chars:sub(rand, rand)
    end
    
    -- Try to save it (silent fail if can't write)
    SaveResourceFile(GetCurrentResourceName(), '.host-secret', secret, -1)
    
    return secret
end

-- Detect mode from convars and folder structure
local function DetectMode()
    -- Check for explicit mode setting
    local explicitMode = GetConvar('ec_mode', '')
    
    if explicitMode ~= '' then
        explicitMode = string.upper(explicitMode)
        if explicitMode == 'DEV' or explicitMode == 'HOST' or explicitMode == 'CUSTOMER' then
            return explicitMode
        end
    end
    
    -- Auto-detect based on /host/ folder
    local hasHostFolder = CheckHostFolder()
    
    -- Auto-detect based on other convars
    local isDevMode = GetConvar('ec_dev_mode', 'false') == 'true'
    
    if isDevMode then
        return Environment.modes.DEV
    elseif hasHostFolder then
        -- If host folder exists, try to load secret
        local hostSecret = ReadHostSecret()
        if hostSecret then
            -- Set it globally for other modules
            SetConvar('ec_host_api_key', hostSecret)
            -- Also update config if it's available
            if Config and Config.HostApi then
                Config.HostApi.secret = hostSecret
                Config.HostApi.enabled = true
            end
        else
            Logger.Warn('[Environment] Host folder detected but .host-secret not found', '⚠️')
            Logger.Warn('[Environment] Host API features may be limited', '⚠️')
        end
        return Environment.modes.HOST
    else
        return Environment.modes.CUSTOMER
    end
end

-- Initialize mode
function Environment.Init()
    Environment.mode = DetectMode()
    
    Logger.Success('[Environment] Mode detected: ' .. Environment.mode, '🔧')
    
    -- Set convar for client/UI access
    SetConvar('ec_runtime_mode', Environment.mode)
    
    return Environment.mode
end

-- Get current mode
function Environment.GetMode()
    if not Environment.mode then
        Environment.Init()
    end
    return Environment.mode
end

-- Check if current mode is DEV
function Environment.IsDev()
    return Environment.GetMode() == Environment.modes.DEV
end

-- Check if current mode is HOST
function Environment.IsHost()
    return Environment.GetMode() == Environment.modes.HOST
end

-- Check if current mode is CUSTOMER
function Environment.IsCustomer()
    return Environment.GetMode() == Environment.modes.CUSTOMER
end

-- Set mode (for setup wizard)
function Environment.SetMode(mode)
    mode = string.upper(mode)
    if mode == 'DEV' or mode == 'HOST' or mode == 'CUSTOMER' then
        Environment.mode = mode
        SetConvar('ec_mode', mode)
        SetConvar('ec_runtime_mode', mode)
        Logger.Info('[Environment] Mode set to: ' .. mode, '🔧')
        return true
    else
        Logger.Error('[Environment] Invalid mode: ' .. tostring(mode), '❌')
        return false
    end
end

-- Export globally
_G.ECEnvironment = Environment

-- Initialize on load
Environment.Init()

Logger.Info('[Environment] Helper initialized', '🔧')
Logger.Info('  Available modes: DEV, HOST, CUSTOMER')
Logger.Info('  Set mode with: setr ec_mode "HOST" or "CUSTOMER"')
Logger.Info('  Dev mode: setr ec_dev_mode "true"')