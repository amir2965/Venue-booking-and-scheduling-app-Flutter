@echo off
echo Starting Mock API Server for Billiards Hub...
echo.
echo This server uses in-memory storage and does not require MongoDB
echo All data will be lost when the server is restarted
echo.
cd %~dp0

echo Installing dependencies...
npm install

echo Starting the mock server...
set PORT=3000
node mock_server.js
pause
