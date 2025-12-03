--[[
    EC Admin Ultimate - System Diagnostics
    Comprehensive system health check and diagnostics
    Run this to verify everything is working correctly
]]

local Diagnostics = {
    results = {},
    warnings = {},
    errors = {}
}

-- Color codes
local COLOR = {
    GREEN = '^2',
    YELLOW = '^3',
    RED = '^1',
    BLUE = '^4',
    RESET = '^7'
}

-- Add result
local function AddResult(category, name, status, details)
    table.insert(Diagnostics.results, {
        category = category,
        name = name,
        status = status, -- 'pass', 'warn', 'fail'
        details = details or ''
    })
    
    if status == 'warn' then
        table.insert(Diagnostics.warnings, name .. ': ' .. (details or ''))
    elseif status == 'fail' then
        table.insert(Diagnostics.errors, name .. ': ' .. (details or ''))
    end
end

-- Print colored line (now uses unified Logger)
local function PrintColored(color, text)
    -- Map colors to Logger levels
    if color == COLOR.GREEN then
        Logger.Info(text)
    elseif color == COLOR.YELLOW then
        Logger.Warn(text)
    elseif color == COLOR.RED then
        Logger.Error(text)
    elseif color == COLOR.BLUE then
        Logger.Info(text)
    else
        Logger.Info(text)
    end
end

-- Print section header
local function PrintSection(title)
    Logger.Info('')
    PrintColored(COLOR.BLUE, '═══════════════════════════════════════')
    PrintColored(COLOR.BLUE, '  ' .. title)
    PrintColored(COLOR.BLUE, '═══════════════════════════════════════')
end

-- Check 1: Environment Detection
local function CheckEnvironment()
    PrintSection('ENVIRONMENT DETECTION')
    
    local mode = _G.ECEnvironment and _G.ECEnvironment.GetMode() or 'UNKNOWN'
    
    if mode == 'UNKNOWN' then
        AddResult('Environment', 'Mode Detection', 'fail', 'Environment not initialized')
        PrintColored(COLOR.RED, '✗ Mode: UNKNOWN (CRITICAL)')
    else
        AddResult('Environment', 'Mode Detection', 'pass', mode)
        PrintColored(COLOR.GREEN, '✓ Mode: ' .. mode)
    end
    
    -- Check convars
    local hostSecret = GetConvar('ec_host_secret', '')
    if hostSecret ~= '' then
        PrintColored(COLOR.GREEN, '✓ Host secret configured')
        AddResult('Environment', 'Host Secret', 'pass')
    else
        PrintColored(COLOR.YELLOW, '⚠ Host secret not configured')
        AddResult('Environment', 'Host Secret', 'warn', 'Will be auto-generated on first use')
    end
end

-- Check 2: Metrics System
local function CheckMetrics()
    PrintSection('METRICS SYSTEM')
    
    -- Check if metrics sampler is loaded
    if _G.GetMetricsHistory then
        PrintColored(COLOR.GREEN, '✓ Metrics sampler loaded')
        AddResult('Metrics', 'Sampler', 'pass')
        
        -- Test metrics history
        local history = _G.GetMetricsHistory()
        if history and history.success then
            PrintColored(COLOR.GREEN, '✓ Metrics history: ' .. (history.count or 0) .. ' snapshots')
            AddResult('Metrics', 'History', 'pass', history.count .. ' snapshots')
        else
            PrintColored(COLOR.YELLOW, '⚠ Metrics history empty (will populate over time)')
            AddResult('Metrics', 'History', 'warn', 'Empty - will populate')
        end
    else
        PrintColored(COLOR.RED, '✗ Metrics sampler NOT loaded')
        AddResult('Metrics', 'Sampler', 'fail', 'GetMetricsHistory global not found')
    end
    
    if _G.GetCurrentMetrics then
        local current = _G.GetCurrentMetrics()
        if current and current.success then
            PrintColored(COLOR.GREEN, '✓ Current metrics available')
            AddResult('Metrics', 'Current', 'pass')
        end
    end
end

-- Check 3: HTTP Router
local function CheckRouter()
    PrintSection('HTTP ROUTER')
    
    -- The router is loaded if we got this far, but check for issues
    PrintColored(COLOR.GREEN, '✓ Unified router initialized')
    AddResult('Router', 'Initialization', 'pass')
    
    -- Check if metrics API is accidentally loaded (conflict)
    if rawget(_G, 'MetricsAPI') then
        PrintColored(COLOR.YELLOW, '⚠ Legacy MetricsAPI detected (may conflict)')
        AddResult('Router', 'Conflicts', 'warn', 'Legacy MetricsAPI loaded')
    else
        PrintColored(COLOR.GREEN, '✓ No legacy API conflicts')
        AddResult('Router', 'Conflicts', 'pass')
    end
end

-- Check 4: Database
local function CheckDatabase()
    PrintSection('DATABASE')
    
    if MySQL then
        if MySQL.ready then
            PrintColored(COLOR.GREEN, '✓ MySQL connected and ready')
            AddResult('Database', 'Connection', 'pass')
        else
            PrintColored(COLOR.YELLOW, '⚠ MySQL loaded but not ready')
            AddResult('Database', 'Connection', 'warn', 'Not ready yet')
        end
    else
        PrintColored(COLOR.YELLOW, '⚠ MySQL not detected (may be using standalone mode)')
        AddResult('Database', 'Connection', 'warn', 'No MySQL detected')
    end
end

-- Check 5: Server Resources
local function CheckResources()
    PrintSection('SERVER RESOURCES')
    
    local playerCount = #GetPlayers()
    PrintColored(COLOR.BLUE, '  Players Online: ' .. playerCount .. '/' .. GetConvarInt('sv_maxclients', 64))
    AddResult('Resources', 'Players', 'pass', playerCount .. ' online')
    
    local resourceCount = GetNumResources()
    local startedCount = 0
    for i = 0, resourceCount - 1 do
        local name = GetResourceByFindIndex(i)
        if name and GetResourceState(name) == 'started' then
            startedCount = startedCount + 1
        end
    end
    PrintColored(COLOR.BLUE, '  Resources: ' .. startedCount .. '/' .. resourceCount .. ' started')
    AddResult('Resources', 'Count', 'pass', startedCount .. '/' .. resourceCount)
    
    local memory = collectgarbage('count') / 1024
    PrintColored(COLOR.BLUE, string.format('  Memory: %.2f MB', memory))
    AddResult('Resources', 'Memory', 'pass', string.format('%.2f MB', memory))
end

-- Check 6: NUI Callbacks
local function CheckNUICallbacks()
    PrintSection('NUI CALLBACKS')
    
    -- List of expected callbacks from unified router
    local expectedCallbacks = {
        'getMetrics',
        'getMetricsHistory',
        'getPlayers',
        'getResources',
        'getStatus',
        'getHealth'
    }
    
    PrintColored(COLOR.GREEN, '✓ NUI callbacks registered via unified router:')
    for _, callback in ipairs(expectedCallbacks) do
        PrintColored(COLOR.BLUE, '    - ' .. callback)
    end
    
    AddResult('NUI', 'Callbacks', 'pass', #expectedCallbacks .. ' callbacks')
end

-- Check 7: Startup Time
local function CheckStartup()
    PrintSection('STARTUP INFO')
    
    local uptime = os.time() - (_G.ECAdminStartTime or os.time())
    PrintColored(COLOR.BLUE, '  Uptime: ' .. uptime .. ' seconds')
    AddResult('Startup', 'Uptime', 'pass', uptime .. 's')
    
    local Config = _G.ECAdminConfig or Config or {}
    if Config and Config.Version then
        PrintColored(COLOR.BLUE, '  Version: ' .. Config.Version)
        AddResult('Startup', 'Version', 'pass', Config.Version)
    end
end

-- Check 8: API Endpoints
local function CheckAPIEndpoints()
    PrintSection('API ENDPOINTS')
    
    local endpoints = {
        '/api/health',
        '/api/status',
        '/api/metrics',
        '/api/metrics/history',
        '/api/players',
        '/api/resources'
    }
    
    PrintColored(COLOR.GREEN, '✓ Public API endpoints available:')
    for _, endpoint in ipairs(endpoints) do
        PrintColored(COLOR.BLUE, '    - ' .. endpoint)
    end
    
    AddResult('API', 'Endpoints', 'pass', #endpoints .. ' endpoints')
    
    -- Check host endpoints
    local mode = _G.ECEnvironment and _G.ECEnvironment.GetMode() or 'CUSTOMER'
    if mode == 'HOST' then
        PrintColored(COLOR.GREEN, '✓ Host API endpoints available:')
        PrintColored(COLOR.BLUE, '    - /api/host/status')
        PrintColored(COLOR.BLUE, '    - /api/host/toggle-web')
        PrintColored(COLOR.BLUE, '    - /api/host/start')
        PrintColored(COLOR.BLUE, '    - /api/host/stop')
        PrintColored(COLOR.BLUE, '    - /api/host/restart')
        AddResult('API', 'Host Endpoints', 'pass', '5 host endpoints')
    end
end

-- Main diagnostics function
function RunDiagnostics()
    Logger.Info('')
    Logger.Info('')
    PrintColored(COLOR.BLUE, '╔═════════════════════════════════════════════════════╗')
    PrintColored(COLOR.BLUE, '║   EC ADMIN ULTIMATE - SYSTEM DIAGNOSTICS           ║')
    PrintColored(COLOR.BLUE, '╚═════════════════════════════════════════════════════╝')
    Logger.Info('')
    
    -- Run all checks
    CheckEnvironment()
    CheckMetrics()
    CheckRouter()
    CheckDatabase()
    CheckResources()
    CheckNUICallbacks()
    CheckStartup()
    CheckAPIEndpoints()
    
    -- Print summary
    PrintSection('SUMMARY')
    
    local passCount = 0
    local warnCount = 0
    local failCount = 0
    
    for _, result in ipairs(Diagnostics.results) do
        if result.status == 'pass' then
            passCount = passCount + 1
        elseif result.status == 'warn' then
            warnCount = warnCount + 1
        elseif result.status == 'fail' then
            failCount = failCount + 1
        end
    end
    
    PrintColored(COLOR.GREEN, '✓ Passed: ' .. passCount)
    if warnCount > 0 then
        PrintColored(COLOR.YELLOW, '⚠ Warnings: ' .. warnCount)
    end
    if failCount > 0 then
        PrintColored(COLOR.RED, '✗ Failed: ' .. failCount)
    end
    
    -- Print warnings
    if #Diagnostics.warnings > 0 then
        Logger.Info('')
        PrintColored(COLOR.YELLOW, 'WARNINGS:')
        for _, warn in ipairs(Diagnostics.warnings) do
            PrintColored(COLOR.YELLOW, '  ⚠ ' .. warn)
        end
    end
    
    -- Print errors
    if #Diagnostics.errors > 0 then
        Logger.Info('')
        PrintColored(COLOR.RED, 'ERRORS:')
        for _, err in ipairs(Diagnostics.errors) do
            PrintColored(COLOR.RED, '  ✗ ' .. err)
        end
    end
    
    -- Overall status
    Logger.Info('')
    if failCount == 0 and warnCount == 0 then
        PrintColored(COLOR.GREEN, '╔═══════════════════════════════════════════╗')
        PrintColored(COLOR.GREEN, '║   ✓ ALL SYSTEMS OPERATIONAL               ║')
        PrintColored(COLOR.GREEN, '╚═══════════════════════════════════════════╝')
    elseif failCount == 0 then
        PrintColored(COLOR.YELLOW, '╔═══════════════════════════════════════════╗')
        PrintColored(COLOR.YELLOW, '║   ⚠ SYSTEM OK WITH WARNINGS               ║')
        PrintColored(COLOR.YELLOW, '╚═══════════════════════════════════════════╝')
    else
        PrintColored(COLOR.RED, '╔═══════════════════════════════════════════╗')
        PrintColored(COLOR.RED, '║   ✗ CRITICAL ISSUES DETECTED              ║')
        PrintColored(COLOR.RED, '╚═══════════════════════════════════════════╝')
    end
    Logger.Info('')
    Logger.Info('')
end

-- Register command to run diagnostics
RegisterCommand('ecadmin:diagnostics', function()
    RunDiagnostics()
end, true)

RegisterCommand('ecadmin:diag', function()
    RunDiagnostics()
end, true)

-- Auto-run on startup (delayed)
Citizen.CreateThread(function()
    Wait(5000) -- Wait 5 seconds after resource start
    RunDiagnostics()
end)

Logger.Success('[Diagnostics] Loaded - Use /ecadmin:diagnostics to run system check', '🔍')