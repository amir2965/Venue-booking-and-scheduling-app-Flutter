# MongoDB Implementation for Billiards Hub

This document explains how to set up and use the MongoDB implementation for the Billiards Hub app.

## Overview

The Billiards Hub app now uses a platform-specific approach for storing data:

1. **Native Platforms** (Windows, Android, iOS, macOS, Linux):
   - Uses a local MongoDB instance running on your machine
   - Connects to MongoDB on localhost:27017

2. **Web Platform**:
   - Uses a web-friendly implementation with SharedPreferences/localStorage
   - No MongoDB server needed for web deployment

This replaces the previous MongoDB implementation that was causing 404 errors when saving profiles.

## Setup Instructions for Native Platforms

1. **Install MongoDB Community Edition**
   - MongoDB must be installed on your development machine
   - Data directory should be set up at `C:\data\db`
   - MongoDB server should be running on the default port (27017)

2. **Verify MongoDB is Running**
   - You can check if MongoDB is running with: `tasklist | findstr mongo`
   - You should see `mongod.exe` in the list of processes

## Implementation Details

### Key Components

1. **MongoDBServiceFactory**
   - Located at `lib/src/services/mongodb_service_factory.dart`
   - Provides the appropriate MongoDB implementation based on the platform

2. **MongoDBLocalService**
   - Located at `lib/src/services/mongodb_local_service.dart`
   - Handles all MongoDB operations for native platforms:
     - Connecting to the local database
     - Saving and retrieving player profiles
     - Managing usernames
     - Checking connectivity

3. **WebMongoDBService**
   - Located at `lib/src/services/web_mongodb_service.dart`
   - Provides a web-friendly implementation that uses localStorage
   - Maintains API compatibility with the native MongoDB service

4. **MongoDB Provider**
   - Located at `lib/src/providers/mongodb_provider.dart`
   - Uses the factory to get the appropriate service implementation
   - Ensures proper initialization and disposal

## Usage

1. **Accessing the MongoDB Service**
   ```dart
   final mongoDBService = ref.watch(mongoDBLocalServiceProvider);
   ```

2. **Saving a Player Profile**
   ```dart
   await mongoDBService.savePlayerProfile(userId, profileData);
   ```

3. **Retrieving a Player Profile**
   ```dart
   final profile = await mongoDBService.getPlayerProfile(userId);
   ```

## Troubleshooting

- **Native Platforms**:
  - If profiles are not being saved, check if MongoDB is running
  - If the app can't connect to MongoDB, make sure the server is started with `mongod --dbpath C:\data\db`
  - For connection issues, try restarting the MongoDB service

- **Web Platform**:
  - Web uses localStorage instead of MongoDB
  - Check browser console logs for any errors
  - Make sure you have not exceeded localStorage limits

## Testing

- A test file is available at `test/mongodb_local_test.dart` to verify that the MongoDB service is working correctly.
- You can also run the test app at `lib/mongodb_test.dart` to interactively test the MongoDB functionality.
