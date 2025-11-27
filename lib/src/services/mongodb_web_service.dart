import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'mongodb_service_base.dart';
import '../models/player_profile.dart';

/// A service class for MongoDB operations through REST API for web environment
class MongoDBWebService implements MongoDBServiceBase {
  final String baseUrl;
  bool _isConnected = false;

  MongoDBWebService({String? customBaseUrl})
      : baseUrl = customBaseUrl ??
            (kDebugMode
                ? 'http://localhost:5000'
                : 'https://your-production-api.com');

  @override
  Future<void> initialize() async {
    try {
      debugPrint('🔄 Initializing MongoDB service at $baseUrl/api/health');

      final uri = Uri.parse('$baseUrl/api/health');
      debugPrint('Making request to: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout after 10 seconds');
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body: ${response.body}');

      _isConnected = response.statusCode == 200;

      if (_isConnected) {
        debugPrint('🌐 Successfully connected to MongoDB API Server');
        final responseData = json.decode(response.body);
        if (responseData['dbConnected'] == true) {
          debugPrint('✅ Database connection confirmed');
        } else {
          debugPrint('⚠️ Server connected but database not connected');
        }
      } else {
        debugPrint('❌ Server responded with status ${response.statusCode}');
        _isConnected = false;
      }
    } catch (e) {
      debugPrint('❌ Failed to connect to MongoDB API Server: $e');
      _isConnected = false;
      rethrow;
    }
  }

  @override
  Future<bool> checkConnectivity() async {
    if (!_isConnected) {
      try {
        debugPrint('🔍 Checking MongoDB connectivity...');
        await initialize();
        debugPrint('✅ MongoDB connectivity check passed: $_isConnected');
      } catch (e) {
        debugPrint('❌ Failed to initialize MongoDB service: $e');
        _isConnected = false;
        return false;
      }
    }
    return _isConnected;
  }

  @override
  Future<void> close() async {
    _isConnected = false;
  }

  @override
  Future<PlayerProfile?> getProfile(String uid) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/profile/$uid'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Server returns { success: true, data: userProfile }
        if (data != null && data['data'] != null) {
          return PlayerProfile.fromJson(data['data']);
        } else {
          debugPrint('Profile data is null in response');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting profile: $e');
      return null;
    }
  }

  @override
  Future<bool> createProfile(PlayerProfile profile) async {
    try {
      debugPrint('🚀 Starting profile creation for user: ${profile.user.id}');
      debugPrint('User email: ${profile.user.email}');
      debugPrint('User display name: ${profile.user.displayName}');
      debugPrint('Username: ${profile.username}');

      final profileData = profile.toJson();
      debugPrint('Initial profile data: $profileData');

      // The username is already included in the profile data from toJson()
      // but ensure required server fields are present
      profileData['email'] = profile.user.email;
      profileData['userId'] = profile.user.id;

      debugPrint('📤 Final profile data being sent: $profileData');

      final String jsonBody = json.encode(profileData);
      final uri = Uri.parse('$baseUrl/api/profile/${profile.user.id}');

      debugPrint('🌐 Making PUT request to: $uri');
      debugPrint('📝 Request body: $jsonBody');

      final response = await http
          .put(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonBody,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Profile creation request timeout after 15 seconds');
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response headers: ${response.headers}');
      debugPrint('📥 Response body: ${response.body}');

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) {
        debugPrint('✅ Profile created successfully!');
      } else {
        debugPrint(
            '❌ Profile creation failed with status: ${response.statusCode}');
      }

      return success;
    } catch (e, stackTrace) {
      debugPrint('💥 Error creating profile: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Future<bool> updateProfile(PlayerProfile profile) async {
    try {
      final profileData = profile.toJson();

      // Add username field required by server
      String username =
          profile.user.displayName?.toLowerCase().replaceAll(' ', '_') ??
              profile.user.email.split('@')[0].toLowerCase();
      username = '${username}_${profile.user.id.substring(0, 8)}';
      profileData['username'] = username;

      final response = await http.put(
        Uri.parse('$baseUrl/api/profile/${profile.user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profileData),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      return false;
    }
  }

  @override
  Future<List<PlayerProfile>> getLikedProfiles(String uid) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/profile/$uid/liked'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((p) => PlayerProfile.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting liked profiles: $e');
      return [];
    }
  }

  @override
  Future<bool> addLikedProfile(String uid, String likedProfileId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/profile/like'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': uid,
          'likedProfileId': likedProfileId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error adding liked profile: $e');
      return false;
    }
  }

  @override
  Future<List<PlayerProfile>> getRecommendedProfiles(String uid) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/profile/$uid/recommended'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((p) => PlayerProfile.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting recommended profiles: $e');
      return [];
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/username/check?username=$username'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isAvailable'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking username availability: $e');
      return false;
    }
  }

  @override
  Future<bool> reserveUsername(String username, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/username/reserve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'userId': userId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error reserving username: $e');
      return false;
    }
  }

  @override
  Future<bool> updateUsername(String userId, String newUsername) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/username/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'username': newUsername,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error updating username: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getMatches(String userId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/profile/$userId/matches'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((m) => m.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting matches: $e');
      return [];
    }
  }

  @override
  Future<PlayerProfile?> getProfileById(String id) => getProfile(id);
}
