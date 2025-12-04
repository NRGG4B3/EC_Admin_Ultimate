@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0.."

cls
color 0A
echo.
echo ====== EC_Admin_Ultimate Setup ======
echo Current Directory: %CD%
echo.

echo [1] Checking Prerequisites
where /q node >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('node --version') do echo ✓ Node.js: %%i
) else (
    echo ✗ Node.js not found
    echo   Download from: https://nodejs.org/
    pause
    exit /b 1
)

where /q npm >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%i in ('npm --version') do echo ✓ npm: %%i
) else (
    echo ✗ npm not found
    pause
    exit /b 1
)
echo.

echo [2] Building UI
echo.

if not exist "ui\package.json" (
    echo ✗ ERROR: ui\package.json not found
    pause
    exit /b 1
)

echo Cleaning previous build...
cd ui
if exist "node_modules" rmdir /s /q node_modules >nul 2>&1
if exist "dist" rmdir /s /q dist >nul 2>&1
if exist "package-lock.json" del /q package-lock.json >nul 2>&1
if exist ".npmrc" del /q .npmrc >nul 2>&1

echo Creating .npmrc for stable installs...
(
    echo legacy-peer-deps=true
    echo engine-strict=false
) > .npmrc

echo Installing dependencies ^(this may take 2-3 minutes^)...
call npm install
if !errorlevel! neq 0 (
    echo.
    echo ✗ npm install failed, trying alternative...
    call npm install --force
    if !errorlevel! neq 0 (
        echo ✗ FATAL: Installation failed
        pause
        exit /b 1
    )
)
echo ✓ Dependencies installed

echo Building UI...
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
echo ✓ UI built successfully

cd ..
echo.

echo [3] Setting up Host API
if not exist "host\node-server\package.json" (
    echo ✓ SKIP: Host API ^(optional^)
) else (
    cd host\node-server
    echo Installing API dependencies...
    call npm install --production >nul 2>&1
    if !errorlevel! neq 0 (
        echo ✓ SKIP: API dependencies ^(optional^)
    ) else (
        echo ✓ API dependencies installed
    )
    cd ..\..
)
echo.

echo [4] Creating Release Package
echo.

if exist "host\release\EC_Admin_Ultimate" (
    echo Cleaning old release...
    rmdir /s /q "host\release\EC_Admin_Ultimate" >nul 2>&1
)

if not exist "host\release" mkdir "host\release"
mkdir "host\release\EC_Admin_Ultimate"

echo Copying files...
xcopy /E /I /Y /Q "client" "host\release\EC_Admin_Ultimate\client" >nul 2>&1
xcopy /E /I /Y /Q "server" "host\release\EC_Admin_Ultimate\server" >nul 2>&1
xcopy /E /I /Y /Q "shared" "host\release\EC_Admin_Ultimate\shared" >nul 2>&1
xcopy /E /I /Y /Q "sql" "host\release\EC_Admin_Ultimate\sql" >nul 2>&1

echo Copying UI...
if exist "ui\dist" (
    xcopy /E /I /Y /Q "ui\dist" "host\release\EC_Admin_Ultimate\ui\dist" >nul 2>&1
    echo ✓ UI included
) else (
    echo ✗ ERROR: ui\dist not found
    pause
    exit /b 1
)

echo Copying root files...
copy /Y "config.lua" "host\release\EC_Admin_Ultimate\" >nul 2>&1
copy /Y "fxmanifest.lua" "host\release\EC_Admin_Ultimate\" >nul 2>&1
copy /Y "README.md" "host\release\EC_Admin_Ultimate\" >nul 2>&1

if not exist "host\release\EC_Admin_Ultimate\fxmanifest.lua" (
    echo ✗ Package creation failed
    pause
    exit /b 1
)
echo ✓ Release package ready
echo.

echo [5] Creating ZIP Archive
cd /d "%~dp0.."
PowerShell -NoProfile -Command "& {$Path='%CD%\host\release\EC_Admin_Ultimate'; $Dest='%CD%\release.zip'; Compress-Archive -LiteralPath $Path -DestinationPath $Dest -Force}"

if exist "release.zip" (
    for %%A in ("release.zip") do (
        set SIZE=%%~zA
        echo ✓ Archive created: !SIZE! bytes
    )
) else (
    echo ✓ Package created (ZIP optional)
)
echo.

echo [6] Configuring Environment
if not exist "host\node-server\.env" (
    echo Creating .env file...
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
    echo ✓ .env created
) else (
    echo ✓ .env already exists
)
echo.

echo [7] Verification
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
echo ===============================================
if !ERRORS! equ 0 (
    echo   SETUP COMPLETE - ALL OK!
) else (
    echo   SETUP COMPLETE - WITH WARNINGS
)
echo ===============================================
echo.

echo Next Steps:
echo.
echo 1. CONFIGURE DATABASE
echo    File: host\node-server\.env
echo    Edit: DB_HOST, DB_USER, DB_PASSWORD
echo.
echo 2. START SERVER
echo    Run: host\start.bat
echo.
echo 3. DEPLOY
echo    Upload release.zip to FiveM server
echo.
echo.
echo Location:  %CD%
echo Package:   %CD%\host\release\EC_Admin_Ultimate
echo Archive:   %CD%\release.zip
echo.

pause
