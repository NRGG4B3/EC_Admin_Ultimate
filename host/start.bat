@echo off
:: ============================================================================
:: EC ADMIN ULTIMATE - HOST API SERVER START
:: For NRG Development Team ONLY
:: ============================================================================
:: Starts the Host API server (Node.js Express)
:: ============================================================================

setlocal

title EC Admin Ultimate - Host API Server

:: Colors
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "CYAN=[96m"
set "RESET=[0m"

echo.
echo %CYAN%========================================%RESET%
echo %CYAN%  EC ADMIN ULTIMATE - HOST API%RESET%
echo %CYAN%  Starting Server...%RESET%
echo %CYAN%========================================%RESET%
echo.

:: Verify Node.js
where node >nul 2>nul
if errorlevel 1 (
    echo %RED%ERROR: Node.js is not installed!%RESET%
    pause
    exit /b 1
)

:: Check if node-server exists
if not exist "host\node-server\index.js" (
    echo %RED%ERROR: Host API server not found!%RESET%
    echo Run setup.bat first to install dependencies.
    pause
    exit /b 1
)

:: Check if dependencies are installed
if not exist "host\node-server\node_modules" (
    echo %RED%ERROR: Node modules not found!%RESET%
    echo Run setup.bat first to install dependencies.
    pause
    exit /b 1
)

:: Check if .env exists
if not exist "host\node-server\.env" (
    echo %YELLOW%WARNING: .env file not found!%RESET%
    echo Creating default .env file...
    (
    echo PORT=30121
    echo HOST=0.0.0.0
    echo DB_HOST=localhost
    echo DB_PORT=3306
    echo DB_NAME=ec_admin_host
    echo DB_USER=root
    echo DB_PASSWORD=
    echo JWT_SECRET=CHANGE_THIS_NOW
    echo API_KEY=CHANGE_THIS_NOW
    echo NODE_ENV=production
    ) > "host\node-server\.env"
    echo %YELLOW%Please edit host/node-server/.env before continuing!%RESET%
    pause
)

:: Check if server is already running
tasklist /FI "IMAGENAME eq node.exe" 2>NUL | find /I /N "node.exe">NUL
if not errorlevel 1 (
    echo %YELLOW%WARNING: Node.js is already running!%RESET%
    echo %YELLOW%If Host API is already started, close it first with stop.bat%RESET%
    choice /C YN /M "Continue anyway"
    if errorlevel 2 exit /b 0
)

:: Navigate to server directory
cd host\node-server

echo %GREEN%Starting Host API server...%RESET%
echo.
echo %CYAN%Server will run on:%RESET% http://localhost:30121
echo %CYAN%Health Check:%RESET% http://localhost:30121/health
echo %CYAN%Press Ctrl+C to stop%RESET%
echo.

:: Start the server
node index.js

:: If server exits, show message
echo.
echo %YELLOW%Host API server stopped.%RESET%
cd ..\..
pause
