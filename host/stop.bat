@echo off
title NRG EC Admin Ultimate - Stop Server

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║     STOPPING HOST SERVER                                 ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

echo [!] Stopping Node.js processes...
taskkill /F /IM node.exe 2>nul

if errorlevel 1 (
    echo [!] No Node processes found
) else (
    echo [✓] Server stopped
)

echo.
pause
