@echo off
echo =============================================
echo   Billiards Hub Notification System
echo   Complete Setup and Test Script
echo =============================================
echo.

cd /d "%~dp0"

echo [1/4] Installing dependencies...
call npm install
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo [2/4] Starting server in background...
start /B node server.js
echo Waiting for server to start...
timeout /t 3 /nobreak >nul

echo.
echo [3/4] Testing server health...
curl -s http://localhost:5000/api/health || (
    echo ERROR: Server health check failed
    echo Make sure the server is running properly
    pause
    exit /b 1
)

echo.
echo [4/4] Running notification endpoint tests...
node test_notifications.js

echo.
echo =============================================
echo   Setup Complete!
echo =============================================
echo.
echo Your notification system is now running on:
echo - Server: http://localhost:5000
echo - API: http://localhost:5000/api
echo - Health: http://localhost:5000/api/health
echo.
echo Available endpoints:
echo - POST   /api/notifications
echo - GET    /api/notifications/:userId
echo - GET    /api/notifications/:userId/unread-count
echo - PATCH  /api/notifications/:notificationId/read
echo - PATCH  /api/notifications/:userId/mark-all-read
echo - DELETE /api/notifications/:notificationId
echo.
echo The server is running in the background.
echo Press any key to stop the server and exit.
pause

echo.
echo Stopping server...
taskkill /f /im node.exe 2>nul
echo Done!
