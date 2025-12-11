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
        echo.
        echo Troubleshooting:
        echo   1. Check your internet connection
        echo   2. Try running: npm install --verbose
        echo   3. Check if npm is working: npm --version
        echo.
        pause
        exit /b 1
    )
    echo   ✓ Dependencies installed
) else (
    echo   ✓ Dependencies already installed
    REM Check if key dependencies exist
    if not exist "node_modules\express" (
        echo   ⚠ WARNING: node_modules exists but express not found - reinstalling...
        call npm install
        if %ERRORLEVEL% NEQ 0 (
            echo [ERROR] Failed to reinstall dependencies
            pause
            exit /b 1
        )
    )
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

echo [5] Verifying required files...
set "MISSING_FILES=0"

if not exist "%API_DIR%\middleware\auth.js" (
    echo [ERROR] Missing required file: middleware\auth.js
    set "MISSING_FILES=1"
)
if not exist "%API_DIR%\middleware\error-handler.js" (
    echo [ERROR] Missing required file: middleware\error-handler.js
    set "MISSING_FILES=1"
)
if not exist "%API_DIR%\utils\logger.js" (
    echo [ERROR] Missing required file: utils\logger.js
    set "MISSING_FILES=1"
)

REM Check service files
if not exist "%API_DIR%\services\monitoring-api.js" (
    echo [ERROR] Missing required file: services\monitoring-api.js
    set "MISSING_FILES=1"
)
if not exist "%API_DIR%\services\global-ban-api.js" (
    echo [ERROR] Missing required file: services\global-ban-api.js
    set "MISSING_FILES=1"
)
if not exist "%API_DIR%\services\ai-analytics-api.js" (
    echo [ERROR] Missing required file: services\ai-analytics-api.js
    set "MISSING_FILES=1"
)

if %MISSING_FILES% EQU 1 (
    echo.
    echo [ERROR] One or more required files are missing!
    echo Please ensure all files are present before starting the server.
    echo.
    pause
    exit /b 1
)

echo   ✓ All required files found

REM Change to API directory
cd /d "%API_DIR%"

REM Test if Node.js can parse the server file
echo [6] Testing server.js syntax...
node --check server.js >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] server.js has syntax errors!
    echo.
    echo Testing syntax (showing errors):
    node --check server.js
    echo.
    echo Please fix syntax errors before starting the server.
    pause
    exit /b 1
)
echo   ✓ server.js syntax is valid

echo.
echo [7] Starting API server...
echo.
echo ========================================
echo   Starting Node.js API server...
echo ========================================
echo.
echo Server will run in this window.
echo Press Ctrl+C to stop the server.
echo.
echo If you see errors below, check:
echo   - All dependencies are installed (npm install)
echo   - .env file is configured correctly
echo   - Port is not already in use
echo.
echo ========================================
echo.

REM Start the server (errors will be shown in console)
node server.js

REM If we get here, the server exited
set "EXIT_CODE=%ERRORLEVEL%"
if %EXIT_CODE% NEQ 0 (
    echo.
    echo ========================================
    echo [ERROR] API server exited with error code: %EXIT_CODE%
    echo ========================================
    echo.
    echo Common issues and solutions:
    echo.
    echo 1. Missing dependencies:
    echo    Solution: Run 'npm install' in %API_DIR%
    echo.
    echo 2. Port already in use:
    echo    Solution: Check if another server is running on port 3000
    echo    Or change PORT in .env file
    echo.
    echo 3. Missing or invalid .env file:
    echo    Solution: Copy .env.example to .env and configure it
    echo.
    echo 4. Syntax errors in service files:
    echo    Solution: Check error messages above for file names
    echo.
    echo 5. Module not found errors:
    echo    Solution: Run 'npm install' to install all dependencies
    echo.
    echo Check the error messages above for specific details.
    echo.
    pause
    exit /b %EXIT_CODE%
) else (
    echo.
    echo ========================================
    echo Server stopped normally.
    echo ========================================
    echo.
    pause
)
