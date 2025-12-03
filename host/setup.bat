@echo off
:: EC ADMIN ULTIMATE - MINIMAL SETUP (AUTO-RUN, NO STOPS)
setlocal enabledelayedexpansion
title EC Admin Ultimate - Auto Setup

:: Normalize to resource root using absolute path
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\"
cd /d "%ROOT_DIR%"

echo ========================================
echo   EC ADMIN ULTIMATE - AUTO SETUP
echo ========================================
echo Root: %ROOT_DIR%
echo.

echo ============================================================================
echo STEP 1: VERIFY NODE/NPM (NON-BLOCKING)
echo ============================================================================
echo [STEP 1/5] Checking Node.js and npm...
where node >nul 2>nul
if errorlevel 1 (
    echo [WARN] Node.js not found - some steps may fail
) else (
    node --version 2>nul
)
where npm >nul 2>nul
if errorlevel 1 (
    echo [WARN] npm not found - some steps may fail
) else (
    npm --version 2>nul
)
echo [OK] Step 1 done
echo.

:: ============================================================================
:: STEP 2: BUILD UI (BEST-EFFORT)
:: ============================================================================
echo [STEP 2/5] Building UI...
if exist "ui\package.json" (
    pushd ui
    echo [INFO] npm install (ui)
    call npm install 2>nul
    echo [INFO] npm run build (ui)
    call npm run build 2>nul
    if exist "dist\index.html" (
        echo [OK] UI built successfully
    ) else (
        echo [WARN] UI build incomplete - continuing
    )
    popd
) else (
    echo [WARN] ui/package.json not found - skipping
)
echo [OK] Step 2 done
echo.

:: ============================================================================
:: STEP 3: INSTALL HOST API DEPS (BEST-EFFORT)
:: ============================================================================
echo [STEP 3/5] Installing Host API dependencies...
if exist "host\node-server\package.json" (
    pushd host\node-server
    echo [INFO] npm install --production
    call npm install --production 2>nul
    if exist "node_modules\express" (
        echo [OK] Express installed
    ) else (
        echo [WARN] Express not found - continuing
    )
    popd
) else (
    echo [WARN] host/node-server/package.json not found - skipping
)
echo [OK] Step 3 done
echo.

:: ============================================================================
:: STEP 4: CREATE CUSTOMER RELEASE PACKAGE
:: ============================================================================
echo [STEP 4/5] Creating customer release package...

if not exist "host\release" mkdir "host\release" 2>nul
if exist "host\release\EC_Admin_Ultimate" rmdir /s /q "host\release\EC_Admin_Ultimate" 2>nul
mkdir "host\release\EC_Admin_Ultimate" 2>nul

echo [INFO] Copying files to release...
if exist "client" xcopy /E /I /Y "client" "host\release\EC_Admin_Ultimate\client" >nul 2>nul
if exist "server" xcopy /E /I /Y "server" "host\release\EC_Admin_Ultimate\server" >nul 2>nul
if exist "shared" xcopy /E /I /Y "shared" "host\release\EC_Admin_Ultimate\shared" >nul 2>nul
if exist "sql" xcopy /E /I /Y "sql" "host\release\EC_Admin_Ultimate\sql" >nul 2>nul
if exist "ui\dist" xcopy /E /I /Y "ui\dist" "host\release\EC_Admin_Ultimate\ui\dist" >nul 2>nul

if exist "config.lua" copy /Y "config.lua" "host\release\EC_Admin_Ultimate\config.lua" >nul 2>nul
if exist "fxmanifest.lua" copy /Y "fxmanifest.lua" "host\release\EC_Admin_Ultimate\fxmanifest.lua" >nul 2>nul
if exist "README.md" copy /Y "README.md" "host\release\EC_Admin_Ultimate\README.md" >nul 2>nul

:: Create customer README
(
echo # EC ADMIN ULTIMATE - Customer Release
echo.
echo ## Installation
echo 1. Extract to your server's resources folder
echo 2. Ensure dependencies are started before this resource
echo 3. Add to server.cfg: ensure EC_Admin_Ultimate
echo 4. Configure config.lua
echo 5. Import sql/ec_admin_database.sql
echo 6. Restart server
echo.
echo ## Support
echo Contact NRG Development
) > "host\release\EC_Admin_Ultimate\INSTALL.md" 2>nul

echo [OK] Customer package created
echo.

:: ============================================================================
:: STEP 5: CREATE RELEASE.ZIP
:: ============================================================================
echo [STEP 5/5] Packaging to release.zip...
powershell -NoProfile -Command "Compress-Archive -Path '%ROOT_DIR%host\release\EC_Admin_Ultimate\*' -DestinationPath '%ROOT_DIR%release.zip' -Force" 2>nul
if exist "release.zip" (
    for %%F in (release.zip) do echo [OK] release.zip created: %%~zF bytes
) else (
    echo [WARN] release.zip not created - check PowerShell availability
)
echo.

:: ============================================================================
:: CREATE .ENV IF MISSING
:: ============================================================================
if not exist "host\node-server\.env" (
    (
    echo PORT=30121
    echo HOST=0.0.0.0
    echo DB_HOST=localhost
    echo DB_PORT=3306
    echo DB_NAME=ec_admin_host
    echo DB_USER=root
    echo DB_PASSWORD=
    echo JWT_SECRET=CHANGE_THIS_TO_RANDOM_STRING
    echo API_KEY=CHANGE_THIS_TO_RANDOM_API_KEY
    echo NODE_ENV=production
    ) > "host\node-server\.env" 2>nul
    echo [OK] Created host/node-server/.env
) else (
    echo [INFO] .env already exists
)
echo.

:: ============================================================================
:: COMPLETION
:: ============================================================================
echo ========================================
echo   SETUP COMPLETE
echo ========================================
echo.
echo Customer Package: host\release\EC_Admin_Ultimate\
echo Release Archive: release.zip
echo.
echo Next Steps:
echo 1. Edit host/node-server/.env with your database credentials
echo 2. Import host/database-host.sql to MySQL
echo 3. Run host/start.bat to start the Host API
echo.
echo Auto-closing in 5 seconds...
timeout /t 5 /nobreak >nul
