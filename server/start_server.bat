@echo off
echo Starting MongoDB API Server for Billiards Hub...
echo.
echo Make sure MongoDB is running on your system!
echo If you need to install MongoDB, please visit: https://www.mongodb.com/try/download/community
echo.
cd %~dp0

echo Installing dependencies...
npm install

echo Starting the server...
set MONGODB_URI=mongodb://localhost:27017/billiards_hub
set PORT=3000
node server.js
pause
