import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../models/player_profile.dart';
import 'mongodb_service_base.dart';

/// A service class for MongoDB operations in web environment
/// This communicates with the REST API server
class WebMongoDBService implements MongoDBServiceBase {
  static const String baseUrl = 'http://localhost:5000/api';

  WebMongoDBService();

  /// Initialize the connection through the REST API
  @override
  Future<void> initialize() async {
    try {
      debugPrint('🔄 Initializing web MongoDB service');
      await html.HttpRequest.request(
        '$baseUrl/health',
        method: 'GET',
        requestHeaders: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      debugPrint('✅ Successfully initialized web MongoDB service');
    } catch (e) {
      debugPrint('❌ Error initializing web MongoDB service: $e');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    // No need to do anything for web service
  }

  @override
  Future<bool> checkConnectivity() async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/health',
        method: 'GET',
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  @override
  Future<bool> createProfile(PlayerProfile profile) async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/profiles',
        method: 'POST',
        requestHeaders: {'Content-Type': 'application/json'},
        sendData: jsonEncode(profile.toJson()),
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('Error creating profile: $e');
      return false;
    }
  }

  @override
  Future<PlayerProfile?> getProfile(String uid) async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/profiles/$uid',
        method: 'GET',
      );

      if (response.status != 200) return null;

      final data = jsonDecode(response.responseText ?? '{}');
      return PlayerProfile.fromJson(data);
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  @override
  Future<bool> updateProfile(PlayerProfile profile) async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/profiles/${profile.user.id}',
        method: 'PUT',
        requestHeaders: {'Content-Type': 'application/json'},
        sendData: jsonEncode(profile.toJson()),
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  @override
  Future<List<PlayerProfile>> getLikedProfiles(String uid) async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/profiles/$uid/liked',
        method: 'GET',
      );

      if (response.status != 200) return [];

      final List<dynamic> data = jsonDecode(response.responseText ?? '[]');
      return data.map((json) => PlayerProfile.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting liked profiles: $e');
      return [];
    }
  }

  @override
  Future<bool> addLikedProfile(String uid, String likedProfileId) async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/profiles/$uid/liked/$likedProfileId',
        method: 'POST',
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('Error adding liked profile: $e');
      return false;
    }
  }

  @override
  Future<List<PlayerProfile>> getRecommendedProfiles(String uid) async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/profiles/$uid/recommended',
        method: 'GET',
      );

      if (response.status != 200) return [];

      final List<dynamic> data = jsonDecode(response.responseText ?? '[]');
      return data.map((json) => PlayerProfile.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting recommended profiles: $e');
      return [];
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/usernames/$username/available',
        method: 'GET',
      );

      if (response.status != 200) return false;

      final data = jsonDecode(response.responseText ?? '{}');
      return data['available'] == true;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      return false;
    }
  }

  @override
  Future<bool> reserveUsername(String username, String userId) async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/usernames/$username',
        method: 'POST',
        requestHeaders: {'Content-Type': 'application/json'},
        sendData: jsonEncode({'userId': userId}),
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('Error reserving username: $e');
      return false;
    }
  }

  @override
  Future<bool> updateUsername(String userId, String newUsername) async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/profiles/$userId/username',
        method: 'PUT',
        requestHeaders: {'Content-Type': 'application/json'},
        sendData: jsonEncode({'username': newUsername}),
      );
      return response.status == 200;
    } catch (e) {
      debugPrint('Error updating username: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getMatches(String userId) async {
    try {
      final response = await html.HttpRequest.request(
        '$baseUrl/profiles/$userId/matches',
        method: 'GET',
      );

      if (response.status != 200) return [];

      final List<dynamic> data = jsonDecode(response.responseText ?? '[]');
      return data.map((id) => id.toString()).toList();
    } catch (e) {
      debugPrint('Error getting matches: $e');
      return [];
    }
  }

  @override
  Future<PlayerProfile?> getProfileById(String id) => getProfile(id);
}
