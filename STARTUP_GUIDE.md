# 🚀 Billiards Hub - Complete Startup Guide

## Prerequisites

Before starting, ensure you have:
- ✅ Node.js (v20.18.0 or later) - Already installed
- ✅ Flutter SDK - Already installed
- ⚠️ MongoDB - **Required** (see installation below)

---

## 📦 Option 1: Local MongoDB (Recommended for Development)

### Install MongoDB Community Edition

1. **Download MongoDB:**
   - Visit: https://www.mongodb.com/try/download/community
   - Select: Windows, MSI installer
   - Download and run the installer

2. **Installation Steps:**
   - Choose "Complete" installation
   - Install as a Windows Service (recommended)
   - Install MongoDB Compass (GUI tool) - optional but helpful

3. **Verify Installation:**
   ```powershell
   mongod --version
   ```

4. **Start MongoDB Service:**
   ```powershell
   # MongoDB should start automatically as a service
   # To check status:
   Get-Service MongoDB
   
   # To start manually if needed:
   net start MongoDB
   ```

### Configure for Local MongoDB

Your `.env` file is already configured for local MongoDB:
```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/billiards_hub
NODE_ENV=development
```

---

## 🌐 Option 2: MongoDB Atlas (Cloud)

If you prefer using MongoDB Atlas (cloud database):

1. **Update `.env` file:**
   ```env
   PORT=5000
   NODE_ENV=development
   
   # Add these lines for MongoDB Atlas:
   MONGODB_USERNAME=your_username
   MONGODB_PASSWORD=your_password
   MONGODB_CLUSTER=your_cluster.mongodb.net
   DB_NAME=billiards_hub
   ```

2. **Whitelist Your IP:**
   - Go to MongoDB Atlas dashboard
   - Navigate to Network Access
   - Add your current IP address or use `0.0.0.0/0` for testing (not recommended for production)

---

## 🖥️ Starting the Server

### Method 1: Using PowerShell

```powershell
# Navigate to server directory
cd "C:\Users\61426\Videos\webtemp\pool -v1\billiards_hub\server"

# Install dependencies (first time only)
npm install

# Start the server
node server.js
```

### Method 2: Using the Batch File

```powershell
cd "C:\Users\61426\Videos\webtemp\pool -v1\billiards_hub\server"
.\start_server.bat
```

### Expected Output (Success):
```
MongoDB API Server running on port 5000
API available at http://localhost:5000/api
Connecting to MongoDB...
URI: mongodb://localhost:27017/billiards_hub
✓ Connected to MongoDB successfully
```

---

## 📱 Starting the Flutter App

### Method 1: Using VS Code

1. Open the project in VS Code
2. Press `F5` or click Run → Start Debugging
3. Select your target device (Chrome, Windows, or connected device)

### Method 2: Using Terminal

```powershell
# Navigate to project root
cd "C:\Users\61426\Videos\webtemp\pool -v1\billiards_hub"

# Get dependencies (first time only)
flutter pub get

# Run on Chrome (recommended for testing)
flutter run -d chrome

# Or run on Windows
flutter run -d windows

# Or run on connected Android/iOS device
flutter run
```

---

## ✅ Verification Checklist

### Server Health Check:

1. **Test server is running:**
   ```powershell
   curl http://localhost:5000/api
   ```
   Or open in browser: http://localhost:5000/api

2. **Test specific endpoints:**
   ```powershell
   # Test venues endpoint
   curl http://localhost:5000/api/venues
   
   # Test users endpoint
   curl http://localhost:5000/api/users
   ```

### Flutter App Check:

1. **Check if app loads without errors**
2. **Verify data is loading from the server**
3. **Check console for any API connection errors**

---

## 🐛 Troubleshooting

### Server Issues

#### Problem: "ENOTFOUND" or "querySrv ENOTFOUND"
**Solution:** This means MongoDB Atlas connection failed. Either:
- Install MongoDB locally (Option 1)
- Fix your MongoDB Atlas credentials and whitelist your IP (Option 2)

#### Problem: "MongooseError: Operation buffering timed out"
**Solution:** MongoDB is not running or not accessible
- If using local MongoDB: Start MongoDB service
- If using Atlas: Check your internet connection and credentials

#### Problem: Port 5000 already in use
**Solution:** Another application is using port 5000
```powershell
# Find what's using port 5000
netstat -ano | findstr :5000

# Kill the process (replace PID with the number from above)
taskkill /PID <PID> /F
```

### Flutter App Issues

#### Problem: Cannot connect to server
**Solution:** 
- Ensure server is running on http://localhost:5000
- Check if Flutter app is configured to use correct API URL
- For web: localhost works fine
- For Android emulator: Use `10.0.2.2:5000` instead of `localhost:5000`

#### Problem: Build errors
**Solution:**
```powershell
# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Try running again
flutter run -d chrome
```

---

## 🔧 Quick Start Commands

### Complete Startup (Two Terminals):

**Terminal 1 - Server:**
```powershell
cd "C:\Users\61426\Videos\webtemp\pool -v1\billiards_hub\server"
node server.js
```

**Terminal 2 - Flutter App:**
```powershell
cd "C:\Users\61426\Videos\webtemp\pool -v1\billiards_hub"
flutter run -d chrome
```

---

## 📝 Notes

- **Server must be running** before starting the Flutter app for data to load
- **MongoDB must be running** before starting the server
- For development, keep both terminals open
- Use `Ctrl+C` to stop the server or Flutter app
- The server will auto-reload on code changes if using `nodemon server.js`

---

## 🎯 Recommended Development Workflow

1. Start MongoDB (if using local)
2. Start the server in Terminal 1
3. Verify server is connected to MongoDB
4. Start Flutter app in Terminal 2
5. Test features in the app
6. Check both terminals for errors

---

## 💡 Pro Tips

- Use **MongoDB Compass** to view/edit database data visually
- Use **Chrome DevTools** when running on web for debugging
- Keep server terminal visible to monitor API calls
- Check `http://localhost:5000/api` in browser to see available endpoints

---

## 📞 Common API Endpoints

- `GET /api/venues` - Get all venues
- `GET /api/venues/:id` - Get specific venue
- `GET /api/users` - Get all users
- `POST /api/users` - Create new user
- `GET /api/chats/:userId` - Get user's chats
- `POST /api/matches` - Create match request

---

Need more help? Check the error messages carefully - they usually indicate exactly what's wrong!
