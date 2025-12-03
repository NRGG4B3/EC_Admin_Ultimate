@echo off
:: ============================================================================
:: EC ADMIN ULTIMATE - MASTER SETUP SCRIPT
:: For NRG Development Team ONLY - Host Mode Setup
:: ============================================================================
:: This script:
::   1. Builds the UI (React/Vite)
::   2. Installs Host API dependencies (Node.js)
::   3. Sets up Host database
::   4. Creates customer release package
::   5. Moves host-specific files to host/ folder
:: ============================================================================

setlocal enabledelayedexpansion

title EC Admin Ultimate - Host Setup

:: Colors for output
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "CYAN=[96m"
set "RESET=[0m"

echo.
echo %CYAN%========================================%RESET%
echo %CYAN%  EC ADMIN ULTIMATE - HOST SETUP%RESET%
echo %CYAN%  NRG Development Internal Use Only%RESET%
echo %CYAN%========================================%RESET%
echo.

:: ============================================================================
:: STEP 1: VERIFY NODE.JS AND NPM
:: ============================================================================
echo %YELLOW%[STEP 1/6] Verifying Node.js and npm...%RESET%
where node >nul 2>nul
if errorlevel 1 (
    echo %RED%ERROR: Node.js is not installed!%RESET%
    echo Please install Node.js 18+ from https://nodejs.org/
    pause
    exit /b 1
)

where npm >nul 2>nul
if errorlevel 1 (
    echo %RED%ERROR: npm is not installed!%RESET%
    pause
    exit /b 1
)

node --version
npm --version
echo %GREEN%Node.js and npm verified successfully%RESET%
echo.

:: ============================================================================
:: STEP 2: BUILD UI (React + Vite)
:: ============================================================================
echo %YELLOW%[STEP 2/6] Building UI (React + Vite)...%RESET%
cd ui

if not exist "package.json" (
    echo %RED%ERROR: package.json not found in ui/ directory%RESET%
    cd ..
    pause
    exit /b 1
)

echo Installing UI dependencies...
call npm install
if errorlevel 1 (
    echo %RED%ERROR: Failed to install UI dependencies%RESET%
    cd ..
    pause
    exit /b 1
)

echo Building production UI...
call npm run build
if errorlevel 1 (
    echo %RED%ERROR: Failed to build UI%RESET%
    cd ..
    pause
    exit /b 1
)

if not exist "dist\index.html" (
    echo %RED%ERROR: UI build output not found (dist/index.html missing)%RESET%
    cd ..
    pause
    exit /b 1
)

echo %GREEN%UI built successfully - dist/ folder ready%RESET%
cd ..
echo.

:: ============================================================================
:: STEP 3: INSTALL HOST API DEPENDENCIES
:: ============================================================================
echo %YELLOW%[STEP 3/6] Installing Host API dependencies...%RESET%
cd host\node-server

if not exist "package.json" (
    echo %RED%ERROR: package.json not found in host/node-server/ directory%RESET%
    cd ..\..
    pause
    exit /b 1
)

echo Installing Host API Node.js dependencies...
call npm install --production
if errorlevel 1 (
    echo %RED%ERROR: Failed to install Host API dependencies%RESET%
    cd ..\..
    pause
    exit /b 1
)

:: Verify critical dependencies
if not exist "node_modules\express" (
    echo %RED%ERROR: Express not installed properly%RESET%
    cd ..\..
    pause
    exit /b 1
)

echo %GREEN%Host API dependencies installed successfully%RESET%
cd ..\..
echo.

:: ============================================================================
:: STEP 4: SETUP HOST DATABASE
:: ============================================================================
echo %YELLOW%[STEP 4/6] Setting up Host database...%RESET%
echo.
echo %CYAN%MANUAL STEP REQUIRED:%RESET%
echo 1. Open your MySQL client (HeidiSQL, phpMyAdmin, etc.)
echo 2. Create a new database: ec_admin_host
echo 3. Import: host/database-host.sql
echo 4. Import: host/sql/*.sql (all files in sql folder)
echo.
echo %YELLOW%Press any key once database setup is complete...%RESET%
pause >nul
echo %GREEN%Database setup marked complete%RESET%
echo.

:: ============================================================================
:: STEP 5: CREATE CUSTOMER RELEASE PACKAGE
:: ============================================================================
echo %YELLOW%[STEP 5/6] Creating customer release package...%RESET%

if not exist "host\release" mkdir "host\release"

echo Creating release directory structure...
if exist "host\release\EC_Admin_Ultimate" rmdir /s /q "host\release\EC_Admin_Ultimate"
mkdir "host\release\EC_Admin_Ultimate"

:: Copy customer files (EXCLUDE host/, setup.bat, start.bat, stop.bat)
echo Copying customer files...

xcopy /E /I /Y "client" "host\release\EC_Admin_Ultimate\client" >nul
xcopy /E /I /Y "server" "host\release\EC_Admin_Ultimate\server" >nul
xcopy /E /I /Y "shared" "host\release\EC_Admin_Ultimate\shared" >nul
xcopy /E /I /Y "sql" "host\release\EC_Admin_Ultimate\sql" >nul
xcopy /E /I /Y "ui\dist" "host\release\EC_Admin_Ultimate\ui\dist" >nul

copy /Y "config.lua" "host\release\EC_Admin_Ultimate\config.lua" >nul
copy /Y "fxmanifest.lua" "host\release\EC_Admin_Ultimate\fxmanifest.lua" >nul
copy /Y "README.md" "host\release\EC_Admin_Ultimate\README.md" >nul

:: Create customer-specific README
(
echo # EC ADMIN ULTIMATE - Customer Release
echo.
echo ## Installation
echo 1. Extract to your server's resources folder
echo 2. Ensure dependencies are started BEFORE this resource:
echo    - oxmysql
echo    - ox_lib
echo    - Your framework ^(qb-core / qbx_core / es_extended^)
echo 3. Add to server.cfg: ensure EC_Admin_Ultimate
echo 4. Configure config.lua with your settings
echo 5. Import sql/ec_admin_database.sql to your database
echo 6. Restart server
echo.
echo ## Configuration
echo Edit config.lua in the resource root to customize:
echo - Menu key ^(default F2^)
echo - Framework detection ^(auto/qb/esx/standalone^)
echo - Permissions ^(ACE or owner identifiers^)
echo - Logging preferences
echo.
echo ## Support
echo For support, contact NRG Development
echo.
echo ## Version
echo Built: %date% %time%
) > "host\release\EC_Admin_Ultimate\INSTALL.md"

echo %GREEN%Customer release package created: host/release/EC_Admin_Ultimate/%RESET%
echo.

:: ============================================================================
:: STEP 6: CREATE HOST ENVIRONMENT FILE
:: ============================================================================
echo %YELLOW%[STEP 6/6] Creating Host environment configuration...%RESET%

if not exist "host\node-server\.env" (
    (
    echo # EC Admin Ultimate - Host API Configuration
    echo # Generated by setup.bat on %date% %time%
    echo.
    echo PORT=30121
    echo HOST=0.0.0.0
    echo.
    echo # Database Configuration
    echo DB_HOST=localhost
    echo DB_PORT=3306
    echo DB_NAME=ec_admin_host
    echo DB_USER=root
    echo DB_PASSWORD=
    echo.
    echo # Security
    echo JWT_SECRET=CHANGE_THIS_TO_RANDOM_STRING
    echo API_KEY=CHANGE_THIS_TO_RANDOM_API_KEY
    echo.
    echo # Environment
    echo NODE_ENV=production
    ) > "host\node-server\.env"
    
    echo %GREEN%Created .env file: host/node-server/.env%RESET%
    echo %YELLOW%IMPORTANT: Edit host/node-server/.env and set:
    echo   - JWT_SECRET to a random string
    echo   - API_KEY to a random API key
    echo   - DB_PASSWORD to your MySQL password%RESET%
) else (
    echo %YELLOW%.env file already exists - skipping%RESET%
)

echo.

:: ============================================================================
:: COMPLETION
:: ============================================================================
echo %GREEN%========================================%RESET%
echo %GREEN%  SETUP COMPLETE!%RESET%
echo %GREEN%========================================%RESET%
echo.
echo %CYAN%Next Steps:%RESET%
echo 1. Configure host/node-server/.env with your credentials
echo 2. Import host/database-host.sql to your MySQL database
echo 3. Run start.bat to start the Host API server
echo 4. Package host/release/EC_Admin_Ultimate/ for customers
echo.
echo %YELLOW%Customer Package Location:%RESET%
echo host\release\EC_Admin_Ultimate\
echo.
echo %YELLOW%Host API Port:%RESET% 30121
echo %YELLOW%API Status:%RESET% http://localhost:30121/health
echo.
echo %CYAN%Next Steps:%RESET%
echo 1. Edit host/node-server/.env with your database credentials
echo 2. Run start.bat to start the Host API server
echo 3. Customer release is in: host/release/EC_Admin_Ultimate/
echo 4. Test the admin panel in-game with %Config.MenuKey% (default F2)
echo.
echo %YELLOW%Host-Specific Files (for NRG Development only):%RESET%
echo - host/node-server/ (API server)
echo - host/api/ (API routes)
echo - host/sql/ (Host database migrations)
echo - setup.bat, start.bat, stop.bat
echo.
echo %YELLOW%Customer receives:%RESET%
echo - host/release/EC_Admin_Ultimate/ (everything they need)
echo - NO setup/start/stop scripts
echo - NO host/ folder contents
echo.
pause
