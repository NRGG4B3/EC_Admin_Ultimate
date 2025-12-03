@echo off
:: ============================================================================
:: EC ADMIN ULTIMATE - HOST API SERVER STOP
:: For NRG Development Team ONLY
:: ============================================================================
:: Stops the Host API server gracefully
:: ============================================================================

setlocal

title EC Admin Ultimate - Stop Host API

:: Colors
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "CYAN=[96m"
set "RESET=[0m"

echo.
echo %CYAN%========================================%RESET%
echo %CYAN%  EC ADMIN ULTIMATE - STOP HOST API%RESET%
echo %CYAN%========================================%RESET%
echo.

:: Kill all node processes running index.js
echo %YELLOW%Stopping Host API server...%RESET%
echo.

tasklist /FI "IMAGENAME eq node.exe" 2>NUL | find /I /N "node.exe">NUL
if errorlevel 1 (
    echo %YELLOW%No Node.js processes running%RESET%
    echo %GREEN%Host API is already stopped%RESET%
) else (
    echo %CYAN%Found running Node.js processes...%RESET%
    
    :: Try graceful shutdown first
    echo %CYAN%Attempting graceful shutdown...%RESET%
    taskkill /IM node.exe >nul 2>nul
    timeout /t 3 /nobreak >nul
    
    :: Check if still running
    tasklist /FI "IMAGENAME eq node.exe" 2>NUL | find /I /N "node.exe">NUL
    if not errorlevel 1 (
        echo %YELLOW%Processes still running, forcing termination...%RESET%
        taskkill /F /IM node.exe >nul 2>nul
    )
    
    if errorlevel 1 (
        echo %RED%Failed to stop some processes - they may require admin rights%RESET%
        echo %YELLOW%Try running this script as Administrator%RESET%
    ) else (
        echo %GREEN%Host API server stopped successfully%RESET%
    )
)

echo.
echo %GREEN%Done!%RESET%
echo.
pause
