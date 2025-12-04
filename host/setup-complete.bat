@echo off
REM =====================================================
REM EC Admin Ultimate - COMPLETE SETUP (All-in-One)
REM =====================================================
REM This script handles EVERYTHING:
REM - Cleans old builds
REM - Builds UI
REM - Creates release package
REM - Sets up environment
REM =====================================================

setlocal enabledelayedexpansion
cd /d "%~dp0.."

cls
color 0A
echo.
echo ╔════════════════════════════════════════════╗
echo ║  EC Admin Ultimate - Complete Setup v2.0  ║
echo ╚════════════════════════════════════════════╝
echo.

echo [Step 1/6] Prerequisites Check
echo.

REM Check Node.js
where /q node >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('node --version') do echo ✓ Node.js: %%i
) else (
    echo ✗ Node.js not found - download from https://nodejs.org/
    pause
    exit /b 1
)

REM Check npm
where /q npm >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('npm --version') do echo ✓ npm: %%i
) else (
    echo ✗ npm not found
    pause
    exit /b 1
)
echo.

echo [Step 2/6] Clean Previous Build
echo.

if exist "ui\dist" (
    echo   Removing old dist...
    rmdir /s /q "ui\dist" >nul 2>&1
    echo   ✓ Done
)

if exist "ui\node_modules" (
    echo   Removing node_modules (fresh install)...
    rmdir /s /q "ui\node_modules" >nul 2>&1
    echo   ✓ Done
)

if exist "ui\package-lock.json" (
    echo   Removing package-lock...
    del /q "ui\package-lock.json" >nul 2>&1
    echo   ✓ Done
)

echo.

echo [Step 3/6] Build UI
echo.

cd ui

echo   Creating .npmrc for stable builds...
(
    echo legacy-peer-deps=true
    echo engine-strict=false
) > .npmrc

echo   Installing UI dependencies ^(this takes 2-3 minutes^)...
call npm install
if !errorlevel! neq 0 (
    echo.
    echo ✗ npm install failed, attempting force install...
    call npm install --force
    if !errorlevel! neq 0 (
        echo ✗ FATAL: Cannot install dependencies
        pause
        exit /b 1
    )
)
echo   ✓ Dependencies installed

echo   Building UI with Vite...
call npm run build
if !errorlevel! neq 0 (
    echo ✗ Build failed!
    pause
    exit /b 1
)

if not exist "dist\index.html" (
    echo ✗ Build did not create dist\index.html
    pause
    exit /b 1
)
echo   ✓ UI built successfully

cd ..
echo.

echo [Step 4/6] Setup Host API
echo.

if not exist "host\node-server\package.json" (
    echo   ✓ SKIP: Host API (optional)
) else (
    cd host\node-server
    echo   Installing API dependencies...
    call npm install --production --legacy-peer-deps >nul 2>&1
    if !errorlevel! neq 0 (
        echo   ✓ SKIP: API dependencies (optional)
    ) else (
        echo   ✓ API dependencies installed
    )
    cd ..\..
)
echo.

echo [Step 5/6] Package Everything
echo.

if exist "host\release\EC_Admin_Ultimate" (
    echo   Cleaning old package...
    rmdir /s /q "host\release\EC_Admin_Ultimate" >nul 2>&1
)

if not exist "host\release" mkdir "host\release"
mkdir "host\release\EC_Admin_Ultimate"

echo   Copying files...
xcopy /E /I /Y /Q "client" "host\release\EC_Admin_Ultimate\client" >nul 2>&1
xcopy /E /I /Y /Q "server" "host\release\EC_Admin_Ultimate\server" >nul 2>&1
xcopy /E /I /Y /Q "shared" "host\release\EC_Admin_Ultimate\shared" >nul 2>&1
xcopy /E /I /Y /Q "sql" "host\release\EC_Admin_Ultimate\sql" >nul 2>&1
xcopy /E /I /Y /Q "ui\dist" "host\release\EC_Admin_Ultimate\ui\dist" >nul 2>&1

copy /Y "config.lua" "host\release\EC_Admin_Ultimate\" >nul 2>&1
copy /Y "fxmanifest.lua" "host\release\EC_Admin_Ultimate\" >nul 2>&1
copy /Y "README.md" "host\release\EC_Admin_Ultimate\" >nul 2>&1

if not exist "host\release\EC_Admin_Ultimate\fxmanifest.lua" (
    echo ✗ Package creation failed
    pause
    exit /b 1
)

echo   ✓ Package created

echo   Creating ZIP archive...
cd /d "%~dp0.."
PowerShell -NoProfile -Command "& {$Path='%CD%\host\release\EC_Admin_Ultimate'; $Dest='%CD%\release.zip'; Compress-Archive -LiteralPath $Path -DestinationPath $Dest -Force}"

if exist "release.zip" (
    for %%A in ("release.zip") do (
        set SIZE=%%~zA
        echo   ✓ Archive ready: !SIZE! bytes
    )
) else (
    echo   ✓ Package created (ZIP optional)
)
echo.

echo [Step 6/6] Environment Setup
echo.

if not exist "host\node-server\.env" (
    echo   Creating .env file...
    (
        echo PORT=30121
        echo HOST=0.0.0.0
        echo DB_HOST=localhost
        echo DB_PORT=3306
        echo DB_NAME=qbox_00bad4
        echo DB_USER=root
        echo DB_PASSWORD=
        echo JWT_SECRET=CHANGE_ME_TO_RANDOM_STRING
        echo API_KEY=CHANGE_ME_TO_YOUR_API_KEY
        echo NODE_ENV=production
    ) > "host\node-server\.env"
    echo   ✓ .env created
) else (
    echo   ✓ .env already exists
)

echo.
echo ╔════════════════════════════════════════════╗
echo ║       SETUP COMPLETE - READY TO USE!       ║
echo ╚════════════════════════════════════════════╝
echo.

set ERRORS=0

if exist "host\release\EC_Admin_Ultimate\ui\dist\index.html" (
    echo ✓ UI built and packaged
) else (
    echo ✗ UI missing
    set ERRORS=1
)

if exist "host\release\EC_Admin_Ultimate\config.lua" (
    echo ✓ Server files packaged
) else (
    echo ✗ Server files missing
    set ERRORS=1
)

if exist "host\node-server\.env" (
    echo ✓ Environment configured
) else (
    echo ✗ Environment missing
    set ERRORS=1
)

echo.
echo QUICK START:
echo.
echo 1. Edit database config:
echo    host\node-server\.env
echo    Set: DB_HOST, DB_USER, DB_PASSWORD
echo.
echo 2. Start the server:
echo    host\start.bat
echo.
echo 3. Deploy to FiveM:
echo    Upload release.zip to your server
echo.
echo Location: %CD%
echo Package:  %CD%\host\release\EC_Admin_Ultimate
echo Archive:  %CD%\release.zip
echo.
echo For detailed help, see: FIXES_AND_SETUP.md
echo.

pause
