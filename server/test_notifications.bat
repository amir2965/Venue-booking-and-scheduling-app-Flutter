@echo off
echo Testing Notification API Endpoints...
echo ====================================
cd /d "%~dp0"

echo.
echo Make sure the server is running first!
echo You can start it with: start_notification_server.bat
echo.
echo Running notification tests...
echo.

node test_notifications.js

echo.
echo Test completed. Press any key to exit.
pause
