@echo off
REM ============================================================================
REM EC Admin Ultimate - Unified Build Script (Host & Customer)
REM 
REM This script:
REM   - Builds UI for both host and customer
REM   - Creates customer ZIP (customer.config.lua -> config.lua, no host folder)
REM   - Keeps host files as-is (host.config.lua stays, host/ folder included)
REM   - Prepares APIs for customer connection (documentation only - customers connect to host APIs)
REM ============================================================================

setlocal enabledelayedexpansion

echo ====== EC Admin Ultimate - Unified Build Script ======
echo.

REM Get current directory
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

REM Check if Node.js is installed
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

echo [1] Building UI...
cd ui

REM Clean previous build
if exist dist (
    echo Cleaning previous build...
    rmdir /s /q dist
)

REM Install dependencies if needed
if not exist node_modules (
    echo Installing UI dependencies...
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to install UI dependencies
        cd ..
        pause
        exit /b 1
    )
)

REM Build UI
echo Building UI...
call npm run build
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] UI build failed
    cd ..
    pause
    exit /b 1
)

cd ..

echo.
echo [2] Preparing Customer Release...

REM Create temporary customer release directory
set "CUSTOMER_RELEASE_DIR=ec_admin_ultimate_customer_release"
if exist "%CUSTOMER_RELEASE_DIR%" (
    echo Cleaning previous customer release directory...
    rmdir /s /q "%CUSTOMER_RELEASE_DIR%"
)
mkdir "%CUSTOMER_RELEASE_DIR%"

echo [3] Copying files for customer release (excluding host folder)...

REM Use robocopy to copy files (excludes host folder, node_modules, .git, build scripts, docs)
robocopy . "%CUSTOMER_RELEASE_DIR%" /E /XD host node_modules .git "%CUSTOMER_RELEASE_DIR%" /XF customer.config.lua host.config.lua build-release.bat build-customer-release.bat build-customer-release.sh *.md .gitignore .env .env.example /NFL /NDL /NJH /NJS >nul

REM Remove any accidentally copied host files (double-check)
if exist "%CUSTOMER_RELEASE_DIR%\host" rmdir /s /q "%CUSTOMER_RELEASE_DIR%\host" 2>nul
if exist "%CUSTOMER_RELEASE_DIR%\host.config.lua" del /F /Q "%CUSTOMER_RELEASE_DIR%\host.config.lua" 2>nul
if exist "%CUSTOMER_RELEASE_DIR%\customer.config.lua" del /F /Q "%CUSTOMER_RELEASE_DIR%\customer.config.lua" 2>nul

REM Remove build scripts and host files from customer release
if exist "%CUSTOMER_RELEASE_DIR%\build-release.bat" del /F /Q "%CUSTOMER_RELEASE_DIR%\build-release.bat"
if exist "%CUSTOMER_RELEASE_DIR%\build-customer-release.bat" del /F /Q "%CUSTOMER_RELEASE_DIR%\build-customer-release.bat"
if exist "%CUSTOMER_RELEASE_DIR%\build-customer-release.sh" del /F /Q "%CUSTOMER_RELEASE_DIR%\build-customer-release.sh"
if exist "%CUSTOMER_RELEASE_DIR%\host" rmdir /s /q "%CUSTOMER_RELEASE_DIR%\host" 2>nul
if exist "%CUSTOMER_RELEASE_DIR%\host.config.lua" del /F /Q "%CUSTOMER_RELEASE_DIR%\host.config.lua" 2>nul

echo [4] Copying customer.config.lua as config.lua...
if exist "customer.config.lua" (
    copy /Y "customer.config.lua" "%CUSTOMER_RELEASE_DIR%\config.lua" >nul
    echo   ✓ customer.config.lua copied as config.lua
) else (
    echo   ⚠ WARNING: customer.config.lua not found!
)

echo [5] Creating customer API connection documentation...
(
    echo # EC Admin Ultimate - Customer API Connection
    echo.
    echo ## Overview
    echo.
    echo Customer servers connect to NRG Host APIs via HTTPS.
    echo **No Node.js installation required on customer servers.**
    echo.
    echo ## API Endpoints
    echo.
    echo All customer servers connect to: **https://api.ecbetasolutions.com**
    echo.
    echo ## Configuration
    echo.
    echo The config.lua file (from customer.config.lua) is pre-configured with the correct API endpoints.
    echo No additional setup required - just configure your API key in config.lua.
    echo.
    echo ## Available APIs
    echo.
    echo 1. **Monitoring API** - Server monitoring and metrics
    echo 2. **Global Ban API** - Cross-server ban synchronization
    echo 3. **AI Analytics API** - Player behavior analysis
    echo 4. **NRG Staff API** - Staff verification
    echo 5. **Remote Admin API** - Remote administration
    echo 6. **Self-Heal API** - Automatic issue detection
    echo 7. **Update Checker API** - Version updates
    echo.
    echo ## Authentication
    echo.
    echo All API requests use the API key configured in config.lua
    echo Set your API key in: Config.HostApi.secret (if using host mode) or Config.APIKey (customer mode)
    echo.
    echo ## Connection
    echo.
    echo Customer servers automatically connect to host APIs when:
    echo - config.lua has API endpoints configured
    echo - API key is set correctly
    echo - Server has internet access
    echo.
    echo No Node.js, npm, or additional software required!
    echo.
) > "%CUSTOMER_RELEASE_DIR%\API_CONNECTION.md"

echo   ✓ API connection documentation created

echo [6] Verifying customer release structure...
if not exist "%CUSTOMER_RELEASE_DIR%\config.lua" (
    echo   ⚠ WARNING: config.lua not found in customer release!
) else (
    echo   ✓ config.lua exists
)
if exist "%CUSTOMER_RELEASE_DIR%\host" (
    echo   ⚠ WARNING: host folder still exists in customer release!
) else (
    echo   ✓ host folder excluded
)
if exist "%CUSTOMER_RELEASE_DIR%\host.config.lua" (
    echo   ⚠ WARNING: host.config.lua still exists in customer release!
) else (
    echo   ✓ host.config.lua excluded
)

echo [7] Creating customer ZIP file...

REM Check if PowerShell is available (for ZIP creation)
where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    REM Use PowerShell to create ZIP
    set "CUSTOMER_ZIP=EC_Admin_Ultimate_Customer_v1.0.0.zip"
    if exist "%CUSTOMER_ZIP%" del /F /Q "%CUSTOMER_ZIP%"
    
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; Compress-Archive -Path '%CUSTOMER_RELEASE_DIR%\*' -DestinationPath '%CUSTOMER_ZIP%' -Force"
    
    if %ERRORLEVEL% EQU 0 (
        echo   ✓ Customer ZIP created: %CUSTOMER_ZIP%
    ) else (
        echo   ⚠ WARNING: Failed to create customer ZIP file
        echo   Customer release files are in: %CUSTOMER_RELEASE_DIR%
    )
) else (
    echo   ⚠ WARNING: PowerShell not available - cannot create ZIP
    echo   Customer release files are in: %CUSTOMER_RELEASE_DIR%
)

echo.
echo [8] Host Release Status...
echo   ✓ Host files remain unchanged (host.config.lua, host/ folder)
echo   ✓ UI built and ready
echo   ✓ All files in workspace are ready for host use

echo.
echo ====== Build Complete ======
echo.
echo Host Release:
echo   - All files in workspace (ready to use)
echo   - host.config.lua (unchanged)
echo   - host/ folder (unchanged)
echo   - UI built in ui/dist/
echo.
echo Customer Release:
if exist "%CUSTOMER_ZIP%" (
    echo   - ZIP: %CUSTOMER_ZIP%
) else (
    echo   - Directory: %CUSTOMER_RELEASE_DIR%
)
echo   - config.lua (from customer.config.lua)
echo   - NO host/ folder
echo   - NO host.config.lua
echo   - API connection documentation included
echo.
echo Customer servers connect to host APIs at: https://api.ecbetasolutions.com
echo No Node.js required on customer servers.
echo.
pause
