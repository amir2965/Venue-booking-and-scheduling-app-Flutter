@echo off
echo Starting Billiards Hub Server with Notification System...
echo.
echo Server will be available at:
echo - API Base URL: http://localhost:5000/api
echo - Health Check: http://localhost:5000/api/health
echo - Notifications: http://localhost:5000/api/notifications
echo.
cd /d "%~dp0"
node server.js
