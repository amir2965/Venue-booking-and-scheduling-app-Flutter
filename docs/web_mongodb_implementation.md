# Billiards Hub Web-Friendly MongoDB Implementation

## Overview

This document explains how the Billiards Hub app handles data storage across different platforms, particularly focusing on the web platform solution.

## The Problem

The original MongoDB implementation was causing 404 errors when saving profiles in web environments. This is because web browsers cannot directly connect to a local MongoDB server due to security restrictions. This resulted in users seeing "complete your profile" prompts even after they had already set up their profiles.

## The Solution

We implemented a platform-specific approach to data storage:

1. **Native Platforms** (Windows, Android, iOS, macOS, Linux):
   - Uses a local MongoDB instance running on the development machine
   - Connects to MongoDB on localhost:27017
   - Full MongoDB functionality is available

2. **Web Platform**:
   - Uses a web-friendly implementation that stores data in localStorage/SharedPreferences
   - Provides the same API as the native MongoDB service
   - No MongoDB server required for web deployment
   - Data persists between browser sessions

## Key Components

### 1. MongoDB Service Factory

The `MongoDBServiceFactory` class determines which implementation to use based on the current platform:

```dart
class MongoDBServiceFactory {
  dynamic getService() {
    if (kIsWeb) {
      return WebMongoDBService();
    } else {
      return MongoDBLocalService();
    }
  }
}
```

### 2. MongoDB Local Service

For native platforms, the `MongoDBLocalService` class connects to a local MongoDB instance and provides methods for:
- Saving and retrieving player profiles
- Managing usernames
- Checking connectivity

### 3. Web MongoDB Service

For web platforms, the `WebMongoDBService` class stores data in localStorage/SharedPreferences and provides the same interface as the MongoDB service:
- Data is saved in the browser's local storage
- Methods have the same signatures as the native implementation
- No need for an actual MongoDB server

### 4. MongoDB Provider

The `mongoDBLocalServiceProvider` uses the factory to get the appropriate implementation:

```dart
final mongoDBLocalServiceProvider = Provider((ref) {
  final service = MongoDBServiceFactory().getService();
  service.initialize();
  ref.onDispose(() {
    service.close();
  });
  return service;
});
```

## How to Use

The beauty of this implementation is that your code doesn't need to know which platform it's running on. The factory handles that automatically:

```dart
// Get the MongoDB service (works on all platforms)
final mongoDBService = ref.watch(mongoDBLocalServiceProvider);

// Use it the same way on all platforms
await mongoDBService.savePlayerProfile(userId, profileData);
final profile = await mongoDBService.getPlayerProfile(userId);
```

## Testing

1. **Native Platforms**: Ensure MongoDB server is running locally
2. **Web Platform**: No additional setup required, works out of the box

You can also use the built-in test screen to verify the web MongoDB implementation:

1. Go to the Home screen
2. Scroll down to the Development Tools section
3. Tap on "Web MongoDB Test"
4. Use the test screen to:
   - Test the connection
   - Save a test profile
   - Load the saved profile
   - Verify data persistence

## MongoDB Status Indicator

A `MongoDBStatusIndicator` widget has been added to the development tools section of the home screen. This shows the current connection status and allows you to test the connection.

## Troubleshooting

- **Web Platform**: If data isn't persisting, check browser storage settings
- **Native Platforms**: Ensure MongoDB server is running on localhost:27017
