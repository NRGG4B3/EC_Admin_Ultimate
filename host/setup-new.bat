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
    cd ui
    call npm install --silent
    call npm run build --silent
    cd ..
    echo OK: UI built
) else (
    echo SKIP: no UI
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
xcopy /E /I /Y "ui\dist" "host\release\EC_Admin_Ultimate\ui\dist" /Q
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
    for %%A in ("release.zip") do echo OK: release.zip created - %%~zA bytes
) else (
    echo FAIL: ZIP failed
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
echo Location: %CD%
echo Package:  %CD%\host\release\EC_Admin_Ultimate
echo Archive:  %CD%\release.zip
echo.
echo Next: Edit host/node-server/.env and run host/start.bat
echo.

:end
