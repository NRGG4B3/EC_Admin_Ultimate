@echo off
REM ============================================================================
REM EC Admin Ultimate - Host API Server Starter
REM Starts all Node.js API services for customer connections
REM ============================================================================

setlocal enabledelayedexpansion

echo ====== EC Admin Ultimate - Host API Server Starter ======
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "API_DIR=%SCRIPT_DIR%api"

REM Check if Node.js is installed
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check if API directory exists
if not exist "%API_DIR%" (
    echo [ERROR] API directory not found: %API_DIR%
    pause
    exit /b 1
)

echo [1] Checking API services...

REM Check for package.json in API directory
if not exist "%API_DIR%\package.json" (
    echo [WARNING] package.json not found in API directory
    echo Creating package.json...
    
    (
        echo {
        echo   "name": "ec-admin-host-apis",
        echo   "version": "1.0.0",
        echo   "type": "module",
        echo   "description": "EC Admin Ultimate Host APIs",
        echo   "main": "server.js",
        echo   "scripts": {
        echo     "start": "node server.js",
        echo     "dev": "node --watch server.js"
        echo   },
        echo   "dependencies": {
        echo     "express": "^4.18.2",
        echo     "cors": "^2.8.5",
        echo     "dotenv": "^16.3.1",
        echo     "jsonwebtoken": "^9.0.2",
        echo     "helmet": "^7.1.0",
        echo     "express-rate-limit": "^7.1.5"
        echo   }
        echo }
    ) > "%API_DIR%\package.json"
    
    echo   ✓ package.json created
)

echo [2] Installing API dependencies...
cd /d "%API_DIR%"
if not exist "node_modules" (
    echo Installing Node.js dependencies (this may take a minute)...
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to install API dependencies
        pause
        exit /b 1
    )
    echo   ✓ Dependencies installed
) else (
    echo   ✓ Dependencies already installed
    echo   (Run 'npm install' manually if you need to update dependencies)
)

echo [3] Checking for server.js...
if not exist "%API_DIR%\server.js" (
    echo [ERROR] server.js not found!
    echo Please ensure server.js exists in: %API_DIR%
    pause
    exit /b 1
)

echo [4] Checking for .env file...
if not exist "%API_DIR%\.env" (
    if exist "%API_DIR%\.env.example" (
        echo   ⚠ .env file not found - copying from .env.example
        copy /Y "%API_DIR%\.env.example" "%API_DIR%\.env" >nul
        echo   ✓ .env file created (please configure it!)
        echo   ⚠ WARNING: Using default values - configure .env for production!
    ) else (
        echo   ⚠ .env file not found - using default values
    )
) else (
    echo   ✓ .env file found
)

echo [5] Starting API server...
echo.
echo Starting Node.js API server...
echo Server will run in this window
echo Press Ctrl+C to stop the server
echo.
echo ========================================
echo.

REM Change to API directory and start server
cd /d "%API_DIR%"
node server.js

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] API server failed to start
    echo Check the error messages above
    pause
    exit /b 1
)
