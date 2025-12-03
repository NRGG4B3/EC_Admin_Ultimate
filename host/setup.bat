@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0.."

echo.
echo ====== EC_Admin_Ultimate Setup ======
echo Current Directory: %CD%
echo.

echo [1] Node and npm
where /q node && echo OK || echo WARN: Node missing
where /q npm && echo OK || echo WARN: npm missing
echo.

echo [2] Build UI
if exist "ui\package.json" (
    echo - Installing UI dependencies...
    cd ui
    call npm install
    if !errorlevel! neq 0 (
        echo ERROR: npm install failed
        pause
        goto :end
    )
    echo - Building UI with Vite...
    call npm run build
    if !errorlevel! neq 0 (
        echo ERROR: UI build failed
        pause
        goto :end
    )
    cd ..
    if exist "ui\dist\index.html" (
        echo OK: UI built successfully - dist folder ready
    ) else (
        echo ERROR: UI build did not create dist folder
        pause
        goto :end
    )
) else (
    echo ERROR: no UI - ui\package.json not found
    pause
    goto :end
)
echo.

echo [3] Host API
if exist "host\node-server\package.json" (
    cd host\node-server
    call npm install --production --silent
    cd ..\..
    echo OK: Host API deps installed
) else (
    echo SKIP: no Host API
)
echo.

echo [4] Release Package
if exist "host\release\EC_Admin_Ultimate" rmdir /s /q "host\release\EC_Admin_Ultimate"
if not exist "host\release" mkdir "host\release"
mkdir "host\release\EC_Admin_Ultimate"

echo - Copying client...
xcopy /E /I /Y "client" "host\release\EC_Admin_Ultimate\client" /Q
echo - Copying server...
xcopy /E /I /Y "server" "host\release\EC_Admin_Ultimate\server" /Q
echo - Copying shared...
xcopy /E /I /Y "shared" "host\release\EC_Admin_Ultimate\shared" /Q
echo - Copying sql...
xcopy /E /I /Y "sql" "host\release\EC_Admin_Ultimate\sql" /Q
echo - Copying ui\dist...
if exist "ui\dist" (
    xcopy /E /I /Y "ui\dist" "host\release\EC_Admin_Ultimate\ui\dist" /Q
    echo   (UI dist copied successfully)
) else (
    echo   ERROR: ui\dist folder not found - UI build may have failed
    pause
    goto :end
)
echo - Copying root files...
copy "config.lua" "host\release\EC_Admin_Ultimate\"
copy "fxmanifest.lua" "host\release\EC_Admin_Ultimate\"
copy "README.md" "host\release\EC_Admin_Ultimate\"

if exist "host\release\EC_Admin_Ultimate\config.lua" (
    echo OK: Package created
) else (
    echo FAIL: Package not created
    goto :end
)
echo.

echo [5] ZIP Archive
cd /d "%~dp0.."
PowerShell -NoProfile -Command "& {$Path='%CD%\host\release\EC_Admin_Ultimate'; $Dest='%CD%\release.zip'; Compress-Archive -LiteralPath $Path -DestinationPath $Dest -Force}"
if exist "release.zip" (
    for %%A in ("release.zip") do (
        set SIZE=%%~zA
        echo OK: release.zip created - !SIZE! bytes
    )
) else (
    echo ERROR: ZIP creation failed
    pause
    goto :end
)
echo.

echo [6] .env Setup
if not exist "host\node-server\.env" (
    (
        echo PORT=30121
        echo HOST=0.0.0.0
        echo DB_HOST=localhost
        echo DB_PORT=3306
        echo DB_NAME=ec_admin_host
        echo DB_USER=root
        echo DB_PASSWORD=
        echo JWT_SECRET=CHANGE_ME
        echo API_KEY=CHANGE_ME
        echo NODE_ENV=production
    ) > "host\node-server\.env"
    echo OK: .env created
) else (
    echo SKIP: .env exists
)
echo.

echo ===============================================
echo   SETUP COMPLETE
echo ===============================================
echo.
echo ✓ Location: %CD%
echo ✓ Package:  %CD%\host\release\EC_Admin_Ultimate
echo ✓ Archive:  %CD%\release.zip
echo.
echo [Verification]
if exist "host\release\EC_Admin_Ultimate\ui\dist\index.html" (
    echo ✓ UI built and packaged successfully
) else (
    echo ✗ WARNING: UI dist files not found in package
)
if exist "host\release\EC_Admin_Ultimate\config.lua" (
    echo ✓ Lua files packaged
) else (
    echo ✗ WARNING: Lua files missing
)
echo.
echo [Next Steps]
echo 1. Edit: host\node-server\.env (configure database)
echo 2. Run:  host\start.bat (start the host server)
echo 3. Upload release.zip to your server
echo.
echo Setup is ready!
echo.

:end
