import 'dart:async';
import '../models/player_profile.dart';

/// Base class for MongoDB services that defines the common interface
abstract class MongoDBServiceBase {
  /// Initialize the service
  Future<void> initialize();

  /// Check connectivity status
  Future<bool> checkConnectivity();

  /// Create a player profile
  Future<bool> createProfile(PlayerProfile profile);

  /// Get a player profile
  Future<PlayerProfile?> getProfile(String uid);

  /// Update a player profile
  Future<bool> updateProfile(PlayerProfile profile);

  /// Get liked profiles for a user
  Future<List<PlayerProfile>> getLikedProfiles(String uid);

  /// Add a liked profile
  Future<bool> addLikedProfile(String uid, String likedProfileId);

  /// Get recommended profiles for a user
  Future<List<PlayerProfile>> getRecommendedProfiles(String uid);

  /// Check if a username is available
  Future<bool> isUsernameAvailable(String username);

  /// Reserve a username for a user
  Future<bool> reserveUsername(String username, String userId);

  /// Update a user's username
  Future<bool> updateUsername(String userId, String newUsername);

  /// Get all matches for a user
  Future<List<String>> getMatches(String userId);

  /// Get a profile by ID (alias for getProfile)
  Future<PlayerProfile?> getProfileById(String id) => getProfile(id);

  /// Close the connection
  Future<void> close();
}
