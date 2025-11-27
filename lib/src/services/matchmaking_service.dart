import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/player_profile.dart';
import '../models/match_result.dart';
import '../models/matchmaking_stats.dart';

class MatchmakingService {
  static const String baseUrl = 'http://localhost:5000/api';

  /// Get potential matches for a user
  Future<List<PlayerProfile>> getPotentialMatches(
    String userId, {
    int limit = 10,
    bool excludeViewed = true,
  }) async {
    try {
      print('🌐 Requesting potential matches for $userId from $baseUrl');

      final response = await http.get(
        Uri.parse(
            '$baseUrl/matchmaking/$userId/potential-matches?limit=$limit&excludeViewed=$excludeViewed'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Request timeout - please check your internet connection');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('📄 Raw response body length: ${response.body.length}');
        print(
            '📄 Response body preview: ${response.body.substring(0, math.min(300, response.body.length))}...');

        final data = json.decode(response.body);
        print('📊 Decoded JSON successfully');
        print('📊 Response keys: ${data.keys.toList()}');

        if (data['success'] == true) {
          final List<dynamic> matchesJson = data['matches'];
          print('🔍 Processing ${matchesJson.length} matches...');

          final matches = <PlayerProfile>[];
          for (int i = 0; i < matchesJson.length; i++) {
            try {
              print('🔍 Parsing match $i...');
              print('📋 Match $i keys: ${matchesJson[i].keys.toList()}');
              print('👤 Match $i user field: ${matchesJson[i]['user']}');
              print('🏷️ Match $i firstName: ${matchesJson[i]['firstName']}');
              print('🏷️ Match $i lastName: ${matchesJson[i]['lastName']}');

              final profile = PlayerProfile.fromJson(matchesJson[i]);
              matches.add(profile);
              print(
                  '✅ Successfully parsed match $i: ${profile.firstName} ${profile.lastName}');
            } catch (e, stackTrace) {
              print('❌ Failed to parse match $i: $e');
              print('📄 Match $i JSON: ${matchesJson[i]}');
              print('📍 StackTrace: $stackTrace');

              // Log specific field analysis for this failed match
              final matchData = matchesJson[i];
              print('🔍 Failed match analysis:');
              print(
                  '  - firstName: ${matchData['firstName']} (${matchData['firstName'].runtimeType})');
              print(
                  '  - lastName: ${matchData['lastName']} (${matchData['lastName'].runtimeType})');
              print(
                  '  - user: ${matchData['user']} (${matchData['user'].runtimeType})');
              if (matchData['user'] != null) {
                final userData = matchData['user'];
                print(
                    '  - user.id: ${userData['id']} (${userData['id'].runtimeType})');
                print(
                    '  - user.email: ${userData['email']} (${userData['email'].runtimeType})');
              }

              rethrow; // Re-throw to see the full error
            }
          }

          print('✅ Successfully parsed all ${matches.length} matches');
          return matches;
        } else {
          throw Exception(
              'Server returned success=false: ${data['error'] ?? 'Unknown error'}');
        }
      }

      throw Exception(
          'Failed to get potential matches: HTTP ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('❌ Error getting potential matches: $e');

      // Provide more specific error messages
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
            'Network connection error. Please check your internet connection and try again.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.toString().contains('Connection refused')) {
        throw Exception(
            'Cannot connect to server. Please ensure the server is running.');
      }

      rethrow;
    }
  }

  /// Record a like or pass action
  Future<MatchResult> recordAction(
    String userId,
    String targetUserId,
    MatchAction action,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/matchmaking/action'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'targetUserId': targetUserId,
          'action': action.name,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MatchResult.fromJson(data);
      }

      throw Exception('Failed to record action: ${response.statusCode}');
    } catch (e) {
      print('Error recording action: $e');
      rethrow;
    }
  }

  /// Get user's matches
  Future<List<PlayerProfile>> getUserMatches(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/matchmaking/$userId/matches'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> matchesJson = data['matches'];
          return matchesJson
              .map((json) => PlayerProfile.fromJson(json))
              .toList();
        }
      }

      throw Exception('Failed to get matches: ${response.statusCode}');
    } catch (e) {
      print('Error getting matches: $e');
      rethrow;
    }
  }

  /// Get matchmaking statistics
  Future<MatchmakingStats> getMatchmakingStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/matchmaking/$userId/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return MatchmakingStats.fromJson(data['stats']);
        }
      }

      throw Exception('Failed to get stats: ${response.statusCode}');
    } catch (e) {
      print('Error getting stats: $e');
      rethrow;
    }
  }

  /// Check server health for matchmaking
  Future<bool> isMatchmakingServiceHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['dbConnected'] == true;
      }

      return false;
    } catch (e) {
      print('Error checking matchmaking service health: $e');
      return false;
    }
  }

  /// Debug method to test parsing a single profile
  Future<void> testProfileParsing() async {
    try {
      print('🧪 Testing profile parsing...');

      // Test with the exact response structure we know works
      final testJson = {
        "user": {
          "id": "mock-user-8",
          "email": "avery.johnson@example.com",
          "displayName": "Avery Johnson",
          "photoUrl": null,
          "emailVerified": false,
          "createdAt": null
        },
        "firstName": "Avery",
        "bio": "I enjoy playing pool and meeting new people!",
        "skillLevel": 3.4,
        "skillTier": "Intermediate",
        "preferredGameTypes": ["Bowling"],
        "preferredLocation": "Local Pool Hall",
        "availability": {
          "Friday": ["Evening"],
          "Saturday": ["Afternoon"]
        },
        "experiencePoints": 810,
        "matchesPlayed": 34,
        "winRate": 0.7,
        "achievements": []
      };

      print('🔍 Attempting to parse test profile...');
      final profile = PlayerProfile.fromJson(testJson);
      print('✅ Successfully parsed: ${profile.firstName} (${profile.user.id})');
    } catch (e, stackTrace) {
      print('❌ Profile parsing test failed: $e');
      print('📍 StackTrace: $stackTrace');
    }
  }
}

enum MatchAction { like, pass }
