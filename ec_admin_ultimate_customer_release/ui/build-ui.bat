@echo off
REM Simple UI build script with error checking
setlocal enabledelayedexpansion

echo ====== Building UI ======
echo.

cd /d "%~dp0"

REM Check Node.js
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js is not installed
    exit /b 1
)

REM Install dependencies if needed
if not exist node_modules (
    echo Installing dependencies...
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] npm install failed
        exit /b 1
    )
)

REM Clean dist
if exist dist (
    echo Cleaning dist folder...
    rmdir /s /q dist
)

REM Build
echo Building with Vite...
call npx vite build
set "BUILD_EXIT=%ERRORLEVEL%"

if %BUILD_EXIT% NEQ 0 (
    echo [ERROR] Vite build failed with exit code %BUILD_EXIT%
    exit /b 1
)

REM Check if dist was created
if not exist dist (
    echo [ERROR] dist folder was not created
    exit /b 1
)

if not exist dist\index.html (
    echo [ERROR] dist\index.html was not created
    exit /b 1
)

echo.
echo Running post-build scripts...
call node scripts/fix-html.js
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] fix-html.js failed
)

call node scripts/copy-dark-css.js
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] copy-dark-css.js failed
)

echo.
echo ====== Build Complete ======
echo dist folder: %CD%\dist
if exist dist\index.html (
    echo ✓ index.html exists
) else (
    echo ✗ index.html missing
    exit /b 1
)

if exist dist\assets (
    echo ✓ assets folder exists
    dir /b dist\assets | find /c /v "" >nul
    if %ERRORLEVEL% EQU 0 (
        echo ✓ assets folder contains files
    ) else (
        echo ✗ assets folder is empty
        exit /b 1
    )
) else (
    echo ✗ assets folder missing
    exit /b 1
)

echo.
echo Build successful!
exit /b 0
