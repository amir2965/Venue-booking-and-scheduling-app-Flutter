@echo off
echo ========================================
echo   Billiards Hub - Quick Setup
echo ========================================
echo.

REM Check if MongoDB is installed
echo [1/5] Checking MongoDB...
mongod --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ MongoDB is NOT installed
    echo.
    echo Please install MongoDB Community Edition:
    echo https://www.mongodb.com/try/download/community
    echo.
    pause
    exit /b 1
) else (
    echo ✓ MongoDB is installed
)
echo.

REM Check if MongoDB service is running
echo [2/5] Checking MongoDB service...
sc query MongoDB | find "RUNNING" >nul
if %errorlevel% neq 0 (
    echo ! MongoDB service is not running
    echo   Attempting to start MongoDB service...
    net start MongoDB >nul 2>&1
    if %errorlevel% neq 0 (
        echo ✗ Failed to start MongoDB service
        echo   Please start it manually or check if MongoDB is installed as a service
        pause
        exit /b 1
    ) else (
        echo ✓ MongoDB service started
    )
) else (
    echo ✓ MongoDB service is running
)
echo.

REM Install server dependencies
echo [3/5] Installing server dependencies...
cd server
if not exist "node_modules\" (
    echo   Installing npm packages...
    call npm install
    if %errorlevel% neq 0 (
        echo ✗ Failed to install server dependencies
        pause
        exit /b 1
    )
    echo ✓ Server dependencies installed
) else (
    echo ✓ Server dependencies already installed
)
cd ..
echo.

REM Get Flutter dependencies
echo [4/5] Getting Flutter dependencies...
call flutter pub get >nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ Failed to get Flutter dependencies
    pause
    exit /b 1
) else (
    echo ✓ Flutter dependencies ready
)
echo.

echo [5/5] Setup complete!
echo.
echo ========================================
echo   Setup Complete! ✓
echo ========================================
echo.
echo Next steps:
echo   1. Run 'start_dev.bat' to start both server and app
echo   2. Or manually start:
echo      - Server: cd server ^& node server.js
echo      - App: flutter run -d chrome
echo.
pause
