@echo off
REM EC_Admin_Ultimate - Quick Setup
REM This script handles everything: UI build, API setup, packaging

setlocal enabledelayedexpansion
cls

color 0A
echo.
echo ╔════════════════════════════════════════════╗
echo ║     EC_Admin_Ultimate - Quick Setup       ║
echo ║                v1.0.0                      ║
echo ╚════════════════════════════════════════════╝
echo.

REM Change to parent directory
cd /d "%~dp0.."

echo [Step 1/7] Checking prerequisites...
echo.

REM Check Node.js
where /q node >nul 2>&1
if !errorlevel! neq 0 (
    echo ✗ FATAL: Node.js not found
    echo   Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('node --version') do echo ✓ Node.js: %%i
)

REM Check npm
where /q npm >nul 2>&1
if !errorlevel! neq 0 (
    echo ✗ FATAL: npm not found
    echo   Please install Node.js (includes npm)
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%i in ('npm --version') do echo ✓ npm: %%i
)

echo.
echo [Step 2/7] Building UI with Vite...
echo.

if not exist "ui\package.json" (
    echo ✗ FATAL: ui\package.json not found
    pause
    exit /b 1
)

cd ui
echo   Installing UI dependencies (this may take a minute)...
call npm install --omit=optional >nul 2>&1
if !errorlevel! neq 0 (
    echo ✗ ERROR: npm install failed
    call npm install
    pause
    exit /b 1
)
echo   ✓ Dependencies installed

echo   Building UI for production...
call npm run build >nul 2>&1
if !errorlevel! neq 0 (
    echo ✗ ERROR: Build failed
    call npm run build
    pause
    exit /b 1
)

if not exist "dist\index.html" (
    echo ✗ ERROR: Build did not create dist/index.html
    pause
    exit /b 1
)
echo   ✓ UI built successfully

cd ..
echo.
echo [Step 3/7] Setting up Host API...
echo.

if not exist "host\node-server\package.json" (
    echo ✗ WARNING: Host API not found (optional)
) else (
    cd host\node-server
    echo   Installing API dependencies...
    call npm install --production --omit=optional >nul 2>&1
    if !errorlevel! neq 0 (
        echo ✗ WARNING: API setup failed (optional)
    ) else (
        echo   ✓ API dependencies installed
    )
    cd ..\..
)

echo.
echo [Step 4/7] Creating release package...
echo.

if exist "host\release\EC_Admin_Ultimate" (
    echo   Cleaning old release...
    rmdir /s /q "host\release\EC_Admin_Ultimate" >nul 2>&1
)

if not exist "host\release" mkdir "host\release"
mkdir "host\release\EC_Admin_Ultimate"

echo   Copying client files...
xcopy /E /I /Y /Q "client" "host\release\EC_Admin_Ultimate\client" >nul 2>&1

echo   Copying server files...
xcopy /E /I /Y /Q "server" "host\release\EC_Admin_Ultimate\server" >nul 2>&1

echo   Copying shared files...
xcopy /E /I /Y /Q "shared" "host\release\EC_Admin_Ultimate\shared" >nul 2>&1

echo   Copying database schemas...
xcopy /E /I /Y /Q "sql" "host\release\EC_Admin_Ultimate\sql" >nul 2>&1

echo   Copying UI distribution...
if exist "ui\dist" (
    xcopy /E /I /Y /Q "ui\dist" "host\release\EC_Admin_Ultimate\ui\dist" >nul 2>&1
    echo   ✓ UI files included
) else (
    echo   ✗ ERROR: ui\dist not found
    pause
    exit /b 1
)

echo   Copying configuration files...
copy /Y "config.lua" "host\release\EC_Admin_Ultimate\" >nul 2>&1
copy /Y "fxmanifest.lua" "host\release\EC_Admin_Ultimate\" >nul 2>&1
copy /Y "README.md" "host\release\EC_Admin_Ultimate\" >nul 2>&1

if not exist "host\release\EC_Admin_Ultimate\fxmanifest.lua" (
    echo ✗ ERROR: Package creation failed
    pause
    exit /b 1
)
echo ✓ Release package created

echo.
echo [Step 5/7] Creating ZIP archive...
echo.

cd /d "%~dp0.."
PowerShell -NoProfile -Command "& {$Path='%CD%\host\release\EC_Admin_Ultimate'; $Dest='%CD%\release.zip'; Compress-Archive -LiteralPath $Path -DestinationPath $Dest -Force}"

if exist "release.zip" (
    for %%A in ("release.zip") do (
        set SIZE=%%~zA
        echo ✓ Archive created: !SIZE! bytes
    )
) else (
    echo ✗ WARNING: ZIP creation failed (but package is ready)
)

echo.
echo [Step 6/7] Configuring environment...
echo.

if not exist "host\node-server\.env" (
    echo   Creating .env file...
    (
        echo PORT=30121
        echo HOST=0.0.0.0
        echo DB_HOST=localhost
        echo DB_PORT=3306
        echo DB_NAME=ec_admin_host
        echo DB_USER=root
        echo DB_PASSWORD=
        echo JWT_SECRET=CHANGE_ME_TO_RANDOM_STRING
        echo API_KEY=CHANGE_ME_TO_YOUR_API_KEY
        echo NODE_ENV=production
    ) > "host\node-server\.env"
    echo ✓ .env created (update with your settings)
) else (
    echo ✓ .env already exists
)

echo.
echo [Step 7/7] Verification...
echo.

set ERRORS=0

if exist "host\release\EC_Admin_Ultimate\ui\dist\index.html" (
    echo ✓ UI built and packaged
) else (
    echo ✗ UI not found in package
    set ERRORS=1
)

if exist "host\release\EC_Admin_Ultimate\config.lua" (
    echo ✓ Server files packaged
) else (
    echo ✗ Server files missing
    set ERRORS=1
)

if exist "host\node-server\.env" (
    echo ✓ Environment file configured
) else (
    echo ✗ Environment file missing
    set ERRORS=1
)

echo.
echo ╔════════════════════════════════════════════╗
if !ERRORS! equ 0 (
    echo ║      SETUP COMPLETE - ALL OK!           ║
) else (
    echo ║   SETUP COMPLETE - CHECK WARNINGS       ║
)
echo ╚════════════════════════════════════════════╝
echo.

echo Next Steps:
echo.
echo 1. CONFIGURE DATABASE (REQUIRED)
echo    Edit: host\node-server\.env
echo    Set:  DB_HOST, DB_PORT, DB_USER, DB_PASSWORD
echo.
echo 2. START HOST SERVER
echo    Run:  host\start.bat
echo.
echo 3. DEPLOY TO FIVEM SERVER
echo    Upload: release.zip to your server's resources folder
echo    Extract and add to server.cfg:
echo    ^> ensure EC_Admin_Ultimate
echo.
echo Location:  %CD%
echo Package:   %CD%\host\release\EC_Admin_Ultimate
echo Archive:   %CD%\release.zip
echo.

pause
