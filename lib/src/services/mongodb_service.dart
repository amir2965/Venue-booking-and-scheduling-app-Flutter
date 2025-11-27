import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user.dart';

class MongoDBService {
  // Replace with your actual server URL
  final String _baseUrl = 'http://localhost:3000/api';
  final Connectivity _connectivity = Connectivity();
  bool _isConnected = true;

  // Add this map to store cached profiles
  final Map<String, Map<String, dynamic>> _cachedProfiles = {};

  // Add these constants for retry logic
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Initialize connectivity monitoring
  MongoDBService() {
    _initConnectivityMonitoring();
  }

  // Initialize connectivity monitoring to sync data when back online
  void _initConnectivityMonitoring() {
    _connectivity.onConnectivityChanged.listen((result) async {
      final wasConnected = _isConnected;
      _isConnected = result != ConnectivityResult.none;

      // If we just got back online after being offline, sync local data
      if (_isConnected && !wasConnected) {
        debugPrint('Connection restored. Ready to synchronize data.');
      }
    });

    // Initialize current connection state
    _connectivity.checkConnectivity().then((result) {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  // Helper method to check if device is currently connected
  Future<bool> checkConnectivity() async {
    try {
      // First check general device connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      _isConnected = connectivityResult != ConnectivityResult.none;

      if (!_isConnected) {
        debugPrint('Device has no network connectivity');
        return false;
      }
      // Then verify we can actually reach the MongoDB server
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            _isConnected = data['status'] == 'ok';
            debugPrint(
                'MongoDB server health check: ${_isConnected ? 'OK' : 'Failed'}');
          } catch (e) {
            debugPrint('Error parsing MongoDB health response: $e');
            _isConnected = false;
          }
        } else {
          debugPrint(
              'MongoDB server returned status code: ${response.statusCode}');
          _isConnected = false;
        }
      } catch (e) {
        debugPrint('Failed to connect to MongoDB server: $e');
        _isConnected = false;
      }

      return _isConnected;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isConnected = false;
      return false;
    }
  }

  // Improved method to get a user profile with caching and retry
  Future<Map<String, dynamic>?> getPlayerProfile(String userId) async {
    // First check if we have a cached copy
    if (_cachedProfiles.containsKey(userId)) {
      debugPrint('Returning cached profile for user $userId');
      return _cachedProfiles[userId];
    }

    // If offline, return null
    if (!await checkConnectivity()) {
      debugPrint('Device is offline, cannot fetch profile from MongoDB');
      return null;
    }

    // Implement retry logic
    for (int attempt = 0; attempt < maxRetryAttempts; attempt++) {
      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/profiles/$userId'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Cache the profile data
          final profile = data;
          _cachedProfiles[userId] = profile;

          // Log successful retrieval
          debugPrint('Retrieved and cached profile for user $userId');
          return profile;
        } else if (response.statusCode == 404) {
          debugPrint('Profile not found in MongoDB for user $userId');
          return null;
        } else {
          debugPrint('MongoDB server returned error: ${response.statusCode}');
          if (attempt < maxRetryAttempts - 1) {
            debugPrint('Retrying... (${attempt + 1}/$maxRetryAttempts)');
            await Future.delayed(retryDelay);
            continue;
          }
        }
      } catch (e) {
        debugPrint('Error getting profile from MongoDB: $e');
        if (attempt < maxRetryAttempts - 1) {
          debugPrint('Retrying... (${attempt + 1}/$maxRetryAttempts)');
          await Future.delayed(retryDelay);
          continue;
        }
      }
    }

    // All retries failed
    debugPrint('All attempts to fetch profile failed');
    return null;
  }

  // Save a player profile
  Future<void> savePlayerProfile(
      String userId, Map<String, dynamic> profileData) async {
    if (!_isConnected) return;

    try {
      // Convert app profile to MongoDB format
      final mongoData = _convertAppProfileToMongoProfile(profileData, userId);

      // Log the data being sent to MongoDB
      debugPrint('Saving profile to MongoDB for user $userId:');
      debugPrint('  firstName: ${mongoData['firstName']}');
      debugPrint('  username: ${mongoData['username']}');
      debugPrint('  skillLevel: ${mongoData['skillLevel']}');
      debugPrint('  skillTier: ${mongoData['skillTier']}');
      final response = await http.put(
        Uri.parse('$_baseUrl/profiles/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(mongoData),
      );

      if (response.statusCode == 200) {
        debugPrint('Profile saved successfully to MongoDB');

        // Verify what was saved by retrieving it back (for debugging)
        final savedProfile = await getPlayerProfile(userId);
        if (savedProfile != null) {
          debugPrint('Verification - profile after save:');
          debugPrint('  firstName: ${savedProfile['firstName']}');
          debugPrint('  displayName: ${savedProfile['user']['displayName']}');
          debugPrint('  skillTier: ${savedProfile['skillTier']}');
        }
      } else {
        throw Exception('Failed to save profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saving player profile to MongoDB: $e');
      throw e;
    }
  }

  // Get all player profiles
  Future<List<Map<String, dynamic>>> getAllPlayerProfiles() async {
    if (!_isConnected) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profiles'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> profiles = json.decode(response.body);
        return profiles
            .map((profile) => profile as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting player profiles from MongoDB: $e');
      return [];
    }
  }

  // Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    if (!_isConnected) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/profiles/check-username/$username'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['available'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      throw e;
    }
  }

  // Helper method to convert MongoDB profile structure to our app's structure
  Map<String, dynamic> _convertMongoProfileToAppProfile(
      Map<String, dynamic> mongoProfile, String userId) {
    // Extract availability from MongoDB format
    Map<String, List<String>> availability = {};
    if (mongoProfile['availability'] != null) {
      final Map<String, dynamic> mongoAvailability =
          Map<String, dynamic>.from(mongoProfile['availability']);
      mongoAvailability.forEach((key, value) {
        if (value is List) {
          availability[key] = List<String>.from(value);
        }
      });
    }

    // Get the firstName for proper display - ensure it's preserved
    final String firstName = mongoProfile['firstName'] ?? '';

    // Ensure the skill tier is properly preserved
    final String skillTier = mongoProfile['skillTier'] ?? 'Novice';
    final double skillLevel = (mongoProfile['skillLevel'] is num)
        ? (mongoProfile['skillLevel'] as num).toDouble()
        : 1.0;

    // Create a user object from MongoDB data
    final Map<String, dynamic> user = {
      'id': userId,
      'displayName': mongoProfile['username'], // This is the username
      'email': mongoProfile['email'] ?? '',
    };

    // Log the conversion for debugging
    debugPrint('Converting MongoDB profile to app format:');
    debugPrint('  MongoDB firstName: ${mongoProfile['firstName']}');
    debugPrint('  MongoDB username: ${mongoProfile['username']}');
    debugPrint('  MongoDB skillTier: ${mongoProfile['skillTier']}');
    debugPrint('  MongoDB skillLevel: ${mongoProfile['skillLevel']}');
    debugPrint('  Converted firstName: $firstName');
    debugPrint('  Converted displayName: ${user['displayName']}');
    debugPrint('  Converted skillTier: $skillTier');
    debugPrint('  Converted skillLevel: $skillLevel');

    // Return the complete profile in our app's format
    return {
      'id': userId,
      'user': user,
      'firstName': firstName,
      'bio': mongoProfile['bio'] ?? '',
      'skillLevel': skillLevel,
      'skillTier': skillTier,
      'preferredGameTypes': mongoProfile['preferredGameTypes'] ?? ['Bowling'],
      'availability': availability,
      'preferredLocation': mongoProfile['preferredLocation'] ?? '',
      'experiencePoints': mongoProfile['experiencePoints'] ?? 10,
      'matchesPlayed': mongoProfile['matchesPlayed'] ?? 0,
      'winRate': mongoProfile['winRate'] ?? 0.0,
      'achievements': mongoProfile['achievements'] ?? [],
      'gender': mongoProfile['gender'] ?? '',
      'playStyle': mongoProfile['playStyle'] ?? '',
      'showInPartnerMatching': mongoProfile['showInPartnerMatching'] ?? true,
    };
  }

  // Helper method to convert our app's profile structure to MongoDB format
  Map<String, dynamic> _convertAppProfileToMongoProfile(
      Map<String, dynamic> appProfile, String userId) {
    // Add more detailed logging for debugging
    debugPrint('Converting app profile to MongoDB format:');
    debugPrint('  firstName=${appProfile['firstName']}');
    debugPrint('  displayName=${appProfile['user']['displayName']}');
    debugPrint('  skillLevel=${appProfile['skillLevel']}');
    debugPrint('  skillTier=${appProfile['skillTier']}');
    debugPrint('  availability=${appProfile['availability']}');
    debugPrint('  preferredLocation=${appProfile['preferredLocation']}');
    debugPrint('  bio=${appProfile['bio']}');
    debugPrint('  gender=${appProfile['gender']}');
    debugPrint('  playStyle=${appProfile['playStyle']}');
    debugPrint(
        '  showInPartnerMatching=${appProfile['showInPartnerMatching']}');
    debugPrint('  achievements=${appProfile['achievements']}');
    debugPrint('  experiencePoints=${appProfile['experiencePoints']}');
    debugPrint('  matchesPlayed=${appProfile['matchesPlayed']}');
    debugPrint('  winRate=${appProfile['winRate']}');
    debugPrint(
        '  username=${appProfile['user']['email']}'); // Log the email as username

    // Ensure skillTier is correctly captured from app profile and matches the skillLevel
    String skillTier = appProfile['skillTier'] ?? 'Novice';
    final double skillLevel = (appProfile['skillLevel'] is num)
        ? (appProfile['skillLevel'] as num).toDouble()
        : 1.0;

    // Update skillTier based on skillLevel if needed for consistency
    if (skillTier != _getSkillTierFromLevel(skillLevel)) {
      debugPrint(
          'Warning: skillTier ($skillTier) does not match skillLevel ($skillLevel)');
      debugPrint(
          'Maintaining the skillTier as selected by the user: $skillTier');
    }

    // MongoDB expects user data in a different format
    return {
      'userId': userId,
      'username': appProfile['user']['displayName'],
      'email': appProfile['user']['email'] ?? '',
      'firstName': appProfile['firstName'] ?? '',
      'bio': appProfile['bio'] ?? '',
      'skillLevel': skillLevel,
      'skillTier': skillTier,
      'preferredGameTypes': appProfile['preferredGameTypes'] ?? ['Bowling'],
      'availability': appProfile['availability'] ?? {},
      'preferredLocation': appProfile['preferredLocation'] ?? '',
      'experiencePoints': appProfile['experiencePoints'] ?? 10,
      'matchesPlayed': appProfile['matchesPlayed'] ?? 0,
      'winRate': appProfile['winRate'] ?? 0.0,
      'achievements': appProfile['achievements'] ?? [],
      'gender': appProfile['gender'] ?? '',
      'playStyle': appProfile['playStyle'] ?? '',
      'showInPartnerMatching': appProfile['showInPartnerMatching'] ?? true,
    };
  }

  // Helper method to calculate skill tier from a numeric level
  String _getSkillTierFromLevel(double skillLevel) {
    if (skillLevel < 1.0) return 'Novice';
    if (skillLevel < 2.0) return 'Beginner';
    if (skillLevel < 3.0) return 'Intermediate';
    if (skillLevel < 4.0) return 'Advanced';
    if (skillLevel < 4.5) return 'Expert';
    return 'Pro';
  }

  // Create a new profile with improved error handling and offline support
  Future<Map<String, dynamic>?> createPlayerProfile(
      User user, Map<String, dynamic> profileData) async {
    // Prepare the profile data with the user information
    final fullProfileData = {
      ...profileData,
      'user': user.toJson(),
    };

    // Save to local cache immediately
    _cachedProfiles[user.id] = fullProfileData;
    debugPrint('Saved profile to local cache for user ${user.id}');

    // Try to save to MongoDB if online
    if (await checkConnectivity()) {
      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/profiles'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(fullProfileData),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 201) {
          debugPrint('Profile created successfully in MongoDB');
          final data = json.decode(response.body);
          return data;
        } else {
          debugPrint(
              'Failed to create profile in MongoDB: ${response.statusCode}');
          // Return cached data even if remote save failed
          return fullProfileData;
        }
      } catch (e) {
        debugPrint('Error creating profile in MongoDB: $e');
        // Return cached data even if remote save failed
        return fullProfileData;
      }
    } else {
      debugPrint('Device is offline, profile will be synced later');
      // Return cached data since we're offline
      return fullProfileData;
    }
  }
}
