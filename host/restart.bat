@echo off
title NRG EC Admin Ultimate - Restart Server

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║     RESTARTING HOST SERVER                               ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

echo [1/2] Stopping server...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo [2/2] Starting server...
cd node-server
start "" node server.js

echo.
echo [✓] Server restarted!
echo.
pause
