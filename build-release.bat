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

REM Error tracking variables
set "UI_BUILD_SUCCESS=0"
set "CUSTOMER_RELEASE_SUCCESS=0"
set "ZIP_CREATE_SUCCESS=0"
set "HAS_ERRORS=0"

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
    set "HAS_ERRORS=1"
    goto :summary
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
        set "HAS_ERRORS=1"
        cd ..
        goto :continue_build
    )
)

REM Build UI
echo Building UI...
echo Running: npx vite build
call npx vite build
set "BUILD_EXIT_CODE=%ERRORLEVEL%"
echo Build command exit code: %BUILD_EXIT_CODE%

REM Wait a moment for file system to catch up
timeout /t 1 /nobreak >nul

REM Check if dist folder was created
if not exist dist (
    echo [ERROR] UI build failed - dist folder not created
    echo [ERROR] Build exit code: %BUILD_EXIT_CODE%
    echo [ERROR] Try running: cd ui && npm install && npx vite build
    set "HAS_ERRORS=1"
    set "UI_BUILD_SUCCESS=0"
    cd ..
    goto :continue_build
)

echo   ✓ dist folder created

REM Check if index.html exists
if not exist dist\index.html (
    echo [ERROR] UI build incomplete - index.html not found in dist
    echo [ERROR] Build may have failed silently
    set "HAS_ERRORS=1"
    set "UI_BUILD_SUCCESS=0"
    cd ..
    goto :continue_build
)

echo   ✓ index.html exists

REM Check if assets folder exists
if not exist dist\assets (
    echo [ERROR] UI build incomplete - assets folder not found in dist
    set "HAS_ERRORS=1"
    set "UI_BUILD_SUCCESS=0"
    cd ..
    goto :continue_build
)

echo   ✓ assets folder exists

REM Run post-build scripts
echo Running post-build scripts...
if %BUILD_EXIT_CODE% EQU 0 (
    echo   Running fix-html.js...
    call node scripts/fix-html.js
    if %ERRORLEVEL% NEQ 0 (
        echo [WARNING] fix-html.js failed, but continuing...
    ) else (
        echo   ✓ fix-html.js completed
    )
    
    echo   Running copy-dark-css.js...
    call node scripts/copy-dark-css.js
    if %ERRORLEVEL% NEQ 0 (
        echo [WARNING] copy-dark-css.js failed, but continuing...
    ) else (
        echo   ✓ copy-dark-css.js completed
    )
    
    echo   ✓ UI build successful
    set "UI_BUILD_SUCCESS=1"
) else (
    echo [ERROR] UI build failed with exit code %BUILD_EXIT_CODE%
    echo [ERROR] However, dist folder exists - attempting to continue...
    set "HAS_ERRORS=1"
    REM Still try to run post-build scripts if dist exists
    if exist dist\index.html (
        echo   Attempting to run post-build scripts anyway...
        call node scripts/fix-html.js
        call node scripts/copy-dark-css.js
    )
    set "UI_BUILD_SUCCESS=0"
)

cd ..

:continue_build

echo.
echo [2] Preparing Customer Release...

REM Create temporary customer release directory
set "CUSTOMER_RELEASE_DIR=ec_admin_ultimate_customer_release"
if exist "%CUSTOMER_RELEASE_DIR%" (
    echo Cleaning previous customer release directory...
    rmdir /s /q "%CUSTOMER_RELEASE_DIR%" 2>nul
)
mkdir "%CUSTOMER_RELEASE_DIR%" 2>nul
if not exist "%CUSTOMER_RELEASE_DIR%" (
    echo [ERROR] Failed to create customer release directory
    set "HAS_ERRORS=1"
    goto :summary
)

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
    if exist "%CUSTOMER_ZIP%" del /F /Q "%CUSTOMER_ZIP%" 2>nul
    
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; Compress-Archive -Path '%CUSTOMER_RELEASE_DIR%\*' -DestinationPath '%CUSTOMER_ZIP%' -Force" 2>nul
    
    if %ERRORLEVEL% EQU 0 (
        if exist "%CUSTOMER_ZIP%" (
            echo   ✓ Customer ZIP created: %CUSTOMER_ZIP%
            set "ZIP_CREATE_SUCCESS=1"
        ) else (
            echo   ⚠ WARNING: ZIP file not found after creation
            set "HAS_ERRORS=1"
        )
    ) else (
        echo   ⚠ WARNING: Failed to create customer ZIP file
        echo   Customer release files are in: %CUSTOMER_RELEASE_DIR%
        set "HAS_ERRORS=1"
    )
) else (
    echo   ⚠ WARNING: PowerShell not available - cannot create ZIP
    echo   Customer release files are in: %CUSTOMER_RELEASE_DIR%
    set "HAS_ERRORS=1"
)

echo.
echo [8] Host Release Status...
if %UI_BUILD_SUCCESS% EQU 1 (
    echo   ✓ Host files remain unchanged (host.config.lua, host/ folder)
    echo   ✓ UI built and ready
    echo   ✓ All files in workspace are ready for host use
) else (
    echo   ⚠ WARNING: UI build failed - host files may not be ready
)

echo.
echo ====== Build Summary ======
echo.

REM Check customer release success
if exist "%CUSTOMER_RELEASE_DIR%\config.lua" (
    set "CUSTOMER_RELEASE_SUCCESS=1"
)

echo Host Release:
if %UI_BUILD_SUCCESS% EQU 1 (
    echo   ✓ UI built in ui/dist/
) else (
    echo   ✗ UI build FAILED
)
echo   ✓ host.config.lua (unchanged)
echo   ✓ host/ folder (unchanged)
echo   ✓ All files in workspace (ready to use)
echo.

echo Customer Release:
if %CUSTOMER_RELEASE_SUCCESS% EQU 1 (
    echo   ✓ config.lua (from customer.config.lua)
) else (
    echo   ✗ config.lua MISSING
)
if not exist "%CUSTOMER_RELEASE_DIR%\host" (
    echo   ✓ host/ folder excluded
) else (
    echo   ✗ host/ folder still present
)
if not exist "%CUSTOMER_RELEASE_DIR%\host.config.lua" (
    echo   ✓ host.config.lua excluded
) else (
    echo   ✗ host.config.lua still present
)
if exist "%CUSTOMER_RELEASE_DIR%\API_CONNECTION.md" (
    echo   ✓ API connection documentation included
) else (
    echo   ✗ API documentation missing
)
if %ZIP_CREATE_SUCCESS% EQU 1 (
    if exist "%CUSTOMER_ZIP%" (
        echo   ✓ ZIP: %CUSTOMER_ZIP%
    ) else (
        echo   ✗ ZIP file not found
    )
) else (
    echo   ⚠ ZIP: Not created (files in %CUSTOMER_RELEASE_DIR%)
)
echo.

if %HAS_ERRORS% EQU 1 (
    echo ====== WARNING: Build completed with errors ======
    echo.
    echo Some steps failed, but the build process continued.
    echo Please review the errors above and fix them before distributing.
    echo.
) else (
    echo ====== Build Complete - All Steps Successful ======
    echo.
)

echo Customer servers connect to host APIs at: https://api.ecbetasolutions.com
echo No Node.js required on customer servers.
echo.

:summary
echo Press any key to exit...
pause >nul
