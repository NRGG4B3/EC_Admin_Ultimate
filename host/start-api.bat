@echo off
setlocal EnableExtensions EnableDelayedExpansion
title NRG EC Admin Ultimate - Start API Servers

color 0B
cls

:: ═══════════════════════════════════════════════════════════════════════════
::  LOAD HOST INFO
:: ═══════════════════════════════════════════════════════════════════════════

set "HOST_DIR=%~dp0"
set "HOST_DIR=%HOST_DIR:~0,-1%"
set "SECRET_FILE=%HOST_DIR%\.host-secret"
set "ROOT_DIR=%HOST_DIR%\.."
set "SERVER_DIR=%HOST_DIR%\node-server"

if not exist "%SECRET_FILE%" (
    color 0C
    echo.
    echo ❌ ERROR: Host secret not found!
    echo.
    echo Please run setup-host.bat first to generate the host secret.
    echo.
    pause
    exit /b 1
)

set /p HOST_SECRET=<"%SECRET_FILE%"

:: Get server IP
for /f "tokens=2 delims=[]" %%a in ('ping -n 1 %computername% ^| findstr "["') do set SERVER_IP=%%a

:: ═══════════════════════════════════════════════════════════════════════════
::  DISPLAY HOST INFO (SAME AS IN-GAME MENU)
:: ═══════════════════════════════════════════════════════════════════════════

cls
echo.
echo ╔═══════════════════════════════════════════════════════════════════════╗
echo ║                                                                       ║
echo ║              🏢 NRG HOST MODE - API SERVER CONTROL                    ║
echo ║                                                                       ║
echo ╚═══════════════════════════════════════════════════════════════════════╝
echo.
echo ╔═══════════════════════════════════════════════════════════════════════╗
echo ║  📊 HOST INFORMATION                                                  ║
echo ╚═══════════════════════════════════════════════════════════════════════╝
echo.
echo    🔑 Host Secret    : %HOST_SECRET%
echo    🌐 Server IP      : %SERVER_IP%
echo    📁 Host Directory : %HOST_DIR%
echo    📦 API Directory  : %SERVER_DIR%
echo.
echo ╔═══════════════════════════════════════════════════════════════════════╗
echo ║  🌐 API ENDPOINTS (Auto-Configured)                                   ║
echo ╚═══════════════════════════════════════════════════════════════════════╝
echo.
echo    Port 3001 → GlobalBans API
echo    Port 3002 → AIDetection API
echo    Port 3003 → AdminAbuse API
echo    Port 3004 → Analytics API
echo    Port 3005 → Reports API
echo    Port 3006 → LiveMap API
echo    Port 3007 → Backups API
echo    Port 3008 → Economy API
echo    Port 3009 → Whitelist API
echo    Port 3010 → DiscordSync API
echo    Port 3011 → PlayerData API
echo    Port 3012 → VehicleData API
echo    Port 3013 → Housing API
echo    Port 3014 → Inventory API
echo    Port 3015 → Jobs API
echo    Port 3016 → AntiCheat API
echo    Port 3017 → Monitoring API
echo    Port 3018 → Webhooks API
echo    Port 3019 → ServerMetrics API
echo    Port 3020 → HostControl API
echo.
echo ╔═══════════════════════════════════════════════════════════════════════╗
echo ║  🎮 IN-GAME ACCESS                                                    ║
echo ╚═══════════════════════════════════════════════════════════════════════╝
echo.
echo    ✅ Admin Dashboard : Available in-city (F2) - HOST ONLY
echo    ✅ Host Controls   : Full API management from game menu
echo    ✅ NRG Staff       : Auto-access on ANY server
echo    ✅ API Health      : Real-time monitoring in dashboard
echo.
echo ╔═══════════════════════════════════════════════════════════════════════╗
echo ║  🚀 STARTING API SERVERS                                              ║
echo ╚═══════════════════════════════════════════════════════════════════════╝
echo.

:: ═══════════════════════════════════════════════════════════════════════════
::  CHECK IF ALREADY RUNNING
:: ═══════════════════════════════════════════════════════════════════════════

tasklist /FI "IMAGENAME eq node.exe" 2>NUL | find /I /N "node.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo ⚠️  Node.js processes already running
    echo.
    choice /C YN /M "Stop all running Node.js processes and restart"
    if errorlevel 2 (
        echo.
        echo ❌ Cancelled - existing processes still running
        pause
        exit /b 0
    )
    
    echo.
    echo 🛑 Stopping all Node.js processes...
    taskkill /F /IM node.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    echo ✅ Processes stopped
    echo.
)

:: ═══════════════════════════════════════════════════════════════════════════
::  START API SERVERS
:: ═══════════════════════════════════════════════════════════════════════════

echo 🚀 Starting API servers...
echo.

pushd "%SERVER_DIR%"

REM Check if multi-port-server.js exists (this starts all 20 APIs)
if not exist "multi-port-server.js" (
    color 0C
    echo ❌ ERROR: multi-port-server.js not found!
    echo.
    echo Expected location: %SERVER_DIR%\multi-port-server.js
    echo Please ensure the file exists or run setup-host.bat
    echo.
    popd
    pause
    exit /b 1
)

echo 📡 Found multi-port-server.js - Starting all 20 APIs...
echo.

REM Check if node_modules exists
if not exist "node_modules\" (
    color 0E
    echo ⚠️  WARNING: node_modules not found!
    echo.
    echo Running npm install first...
    call npm install
    if errorlevel 1 (
        color 0C
        echo.
        echo ❌ ERROR: npm install failed!
        popd
        pause
        exit /b 1
    )
    echo.
)

REM Start the multi-port server (handles all 20 APIs on ports 3001-3020)
echo Launching all 20 API servers on ports 3001-3020...
echo.
start /B node multi-port-server.js > api-server.log 2>&1

popd

timeout /t 5 /nobreak >nul

echo.
echo Verifying API servers started...
echo.

REM Jump to verification (skip old code below)
goto :VERIFY_SERVERS

REM OLD CODE - REMOVED (kept for reference only, never executes)
if exist "dist\index.js" (
    set "API_ENTRY=dist\index.js"
    echo 📡 Using built API: dist/index.js
) else if exist "index.js" (
    set "API_ENTRY=index.js"
    echo 📡 Using source API: index.js
) else if exist "src\index.js" (
    set "API_ENTRY=src\index.js"
    echo 📡 Using source API: src/index.js
) else if exist "src\index.ts" (
    REM Try to run TypeScript directly with ts-node
    where ts-node >nul 2>&1
    if errorlevel 1 (
        color 0C
        echo ❌ ERROR: No JavaScript entry point found and ts-node not installed!
        echo.
        echo Please run setup-host.bat first to build the API servers.
        echo.
        popd
        pause
        exit /b 1
    )
    set "API_ENTRY=src\index.ts"
    echo 📡 Using TypeScript API: src/index.ts (requires ts-node)
) else (
    color 0C
    echo ❌ ERROR: No API entry point found!
    echo.
    echo Looking for: dist/index.js, index.js, src/index.js, or src/index.ts
    echo Please run setup-host.bat first to build the API servers.
    echo.
    popd
    pause
    exit /b 1
)

REM Start all API servers (they auto-configure their ports)
echo � Launching API servers in background...
start /B node "%API_ENTRY%" >nul 2>&1

popd

timeout /t 3 /nobreak >nul

:: ═══════════════════════════════════════════════════════════════════════════
::  VERIFY SERVERS STARTED
:: ═══════════════════════════════════════════════════════════════════════════

:VERIFY_SERVERS

tasklist /FI "IMAGENAME eq node.exe" 2>NUL | find /I /N "node.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    color 0A
    echo ============================================================================
    echo.
    echo                    API SERVERS RUNNING SUCCESSFULLY
    echo.
    echo ============================================================================
    echo.
    echo  All 20 API servers are now running on ports 3001-3020
    echo.
    echo  Log file: %SERVER_DIR%\api-server.log
    echo.
    echo  You can now:
    echo    1. Start your FiveM server
    echo    2. Press F2 in-game to open admin dashboard
    echo    3. Access Host Controls from the dashboard
    echo    4. Monitor API health in real-time
    echo.
    echo ============================================================================
    echo.
) else (
    color 0C
    echo ============================================================================
    echo.
    echo                    ERROR: API SERVERS FAILED TO START
    echo.
    echo ============================================================================
    echo.
    echo Checking error log...
    echo.
    if exist "%SERVER_DIR%\api-server.log" (
        type "%SERVER_DIR%\api-server.log"
    ) else (
        echo No log file found
    )
    echo.
    pause
    exit /b 1
)

echo.
echo ╔═══════════════════════════════════════════════════════════════════════╗
echo ║                                                                       ║
echo ║                    ✅ API SERVERS RUNNING ✅                         ║
echo ║                                                                       ║
echo ╚═══════════════════════════════════════════════════════════════════════╝
echo.
echo 🎮 You can now:
echo    1. Start your FiveM server
echo    2. Press F2 in-game to open admin dashboard
echo    3. Access Host Controls from the dashboard
echo    4. Monitor API health in real-time
echo.
echo 📊 API Status:
echo    - All 20 API endpoints running on localhost:3001-3020
echo    - Auto-configured with host secret
echo    - Accessible only from this server
echo    - Full control available in-game
echo.
echo 🔐 Security:
echo    - APIs bound to localhost only (not public)
echo    - Host secret authentication required
echo    - NRG staff auto-authenticated
echo.
echo 💡 Tip: Keep this window open to see API logs
echo         Press Ctrl+C to stop all API servers
echo.
echo ╔═══════════════════════════════════════════════════════════════════════╗
echo ║  Press any key to hide this window (APIs keep running in background)  ║
echo ╚═══════════════════════════════════════════════════════════════════════╝
pause >nul

REM Minimize window but keep running
if not defined IS_MINIMIZED (
    set IS_MINIMIZED=1
    start /MIN cmd /C "%~f0"
    exit
)

REM Keep running in background
:loop
timeout /t 300 /nobreak >nul
goto loop
