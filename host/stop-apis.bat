@echo off
REM ============================================================================
REM EC Admin Ultimate - Host API Server Stopper
REM Stops all running Node.js API services
REM ============================================================================

setlocal enabledelayedexpansion

echo ====== EC Admin Ultimate - Host API Server Stopper ======
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "API_DIR=%SCRIPT_DIR%api"

echo [1] Finding Node.js processes...

REM Find Node.js processes running server.js in the API directory
for /f "tokens=2" %%P in ('tasklist /FI "IMAGENAME eq node.exe" /FO LIST ^| findstr /C:"PID:"') do (
    set "PID=%%P"
    
    REM Check if this process is running our server.js
    wmic process where "ProcessId=!PID!" get CommandLine 2>nul | findstr /i "server.js" >nul
    if !ERRORLEVEL! EQU 0 (
        echo   Found API server process: PID !PID!
        echo   Stopping process !PID!...
        taskkill /PID !PID! /F >nul 2>&1
        if !ERRORLEVEL! EQU 0 (
            echo   ✓ Stopped process !PID!
        ) else (
            echo   ⚠ Failed to stop process !PID!
        )
    )
)

REM Alternative: Kill all node.exe processes (more aggressive)
echo.
echo [2] Checking for remaining Node.js processes...
tasklist /FI "IMAGENAME eq node.exe" 2>nul | find /I "node.exe" >nul
if %ERRORLEVEL% EQU 0 (
    echo   ⚠ Node.js processes still running
    echo   Use taskkill /F /IM node.exe to force stop all Node.js processes
    echo.
    set /p CONFIRM="Kill ALL Node.js processes? (Y/N): "
    if /i "!CONFIRM!"=="Y" (
        echo   Stopping all Node.js processes...
        taskkill /F /IM node.exe >nul 2>&1
        if !ERRORLEVEL! EQU 0 (
            echo   ✓ All Node.js processes stopped
        ) else (
            echo   ⚠ Failed to stop Node.js processes
        )
    )
) else (
    echo   ✓ No Node.js processes running
)

echo.
echo ====== API Server Stopped ======
echo.
pause
