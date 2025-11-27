@echo off
title Billiards Hub - Development Environment
echo ========================================
echo   Starting Billiards Hub
echo ========================================
echo.

REM Check if MongoDB is running
echo Checking MongoDB service...
sc query MongoDB | find "RUNNING" >nul
if %errorlevel% neq 0 (
    echo MongoDB is not running. Attempting to start...
    net start MongoDB >nul 2>&1
    if %errorlevel% neq 0 (
        echo.
        echo ✗ ERROR: Could not start MongoDB!
        echo   Please ensure MongoDB is installed and configured as a service.
        echo   Or install it from: https://www.mongodb.com/try/download/community
        echo.
        pause
        exit /b 1
    )
)
echo ✓ MongoDB is running
echo.

REM Start server in a new window
echo Starting server...
start "Billiards Hub Server" cmd /k "cd server && echo Starting MongoDB API Server... && node server.js"
timeout /t 3 /nobreak >nul
echo ✓ Server started in new window
echo.

REM Wait a bit for server to initialize
echo Waiting for server to initialize...
timeout /t 2 /nobreak >nul

REM Start Flutter app
echo Starting Flutter app on Chrome...
echo This may take a moment on first run...
echo.
start "Billiards Hub App" cmd /k "flutter run -d chrome"

echo.
echo ========================================
echo   Development Environment Started!
echo ========================================
echo.
echo Two windows have been opened:
echo   1. Server (port 5000)
echo   2. Flutter App (Chrome)
echo.
echo Press any key to close this window...
echo (The server and app will keep running)
echo.
pause >nul
