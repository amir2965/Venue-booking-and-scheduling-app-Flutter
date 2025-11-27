import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/player_profile.dart';
import 'mongodb_service_base.dart';

/// A service class for MongoDB Atlas operations
class MongoDBLocalService implements MongoDBServiceBase {
  Db? _db;
  bool _isConnected = false;
  final String _dbName = 'billiards_hub';
  late final String _connectionString;

  /// Collection names
  final String _profilesCollectionName = 'player_profiles';
  final String _usernamesCollectionName = 'usernames';
  final String _likesCollectionName = 'likes';
  final String _matchesCollectionName = 'matches';

  MongoDBLocalService() {
    // In production, these should be fetched from environment variables or secure storage
    const username = String.fromEnvironment('MONGODB_USERNAME',
        defaultValue: 'your_mongodb_username');
    const password = String.fromEnvironment('MONGODB_PASSWORD',
        defaultValue: 'nmBGXaUUTiSOYwL6');
    const cluster = String.fromEnvironment('MONGODB_CLUSTER',
        defaultValue: 'cluster0.lpgew0e.mongodb.net');

    // Use SSL-enabled connection string for web environment
    if (kIsWeb) {
      _connectionString =
          'mongodb+srv://$username:$password@$cluster/$_dbName?ssl=true&retryWrites=true&w=majority';
    } else {
      _connectionString = 'mongodb+srv://$username:$password@$cluster/$_dbName';
    }
  }

  @override
  Future<void> initialize() async {
    if (_db != null) return;
    try {
      debugPrint('ðŸ”„ Connecting to MongoDB Atlas cluster');

      if (kIsWeb) {
        // Configure MongoDB for web environment
        _db = Db(_connectionString);
        await _db!.open(
          secure: true,
          tlsAllowInvalidCertificates: false,
        );
      } else {
        _db = await Db.create(_connectionString);
        await _db!.open();
      }

      _isConnected = true;
      debugPrint('âœ… Connected to MongoDB Atlas cluster');

      // Create collections and indexes if they don't exist
      final collections = await _db!.getCollectionNames();
      if (!collections.contains(_profilesCollectionName)) {
        await _db!.createCollection(_profilesCollectionName);
      }
      if (!collections.contains(_usernamesCollectionName)) {
        await _db!.createCollection(_usernamesCollectionName);
      }
      if (!collections.contains(_likesCollectionName)) {
        await _db!.createCollection(_likesCollectionName);
      }
      if (!collections.contains(_matchesCollectionName)) {
        await _db!.createCollection(_matchesCollectionName);
      }
    } catch (e) {
      _isConnected = false;
      debugPrint('âŒ Error connecting to MongoDB: $e');
      rethrow;
    }
  }

  @override
  Future<bool> checkConnectivity() async {
    if (!_isConnected || _db == null) return false;
    try {
      await _profilesCollection.findOne();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _isConnected = false;
  }

  @override
  Future<bool> createProfile(PlayerProfile profile) async {
    try {
      await _profilesCollection.insertOne({
        'userId': profile.user.id,
        'profile': profile.toJson(),
      });
      return true;
    } catch (e) {
      debugPrint('âŒ Error creating profile: $e');
      return false;
    }
  }

  @override
  Future<PlayerProfile?> getProfile(String uid) async {
    try {
      final result = await _profilesCollection.findOne(where.eq('userId', uid));
      if (result != null) {
        return PlayerProfile.fromJson(result['profile']);
      }
      return null;
    } catch (e) {
      debugPrint('âŒ Error getting profile: $e');
      return null;
    }
  }

  @override
  Future<bool> updateProfile(PlayerProfile profile) async {
    try {
      final result = await _profilesCollection.updateOne(
        where.eq('userId', profile.user.id),
        modify.set('profile', profile.toJson()),
      );
      return result.isSuccess;
    } catch (e) {
      debugPrint('âŒ Error updating profile: $e');
      return false;
    }
  }

  @override
  Future<List<PlayerProfile>> getLikedProfiles(String uid) async {
    try {
      final likedIds =
          await _likesCollection.find(where.eq('userId', uid)).toList();
      final profiles = <PlayerProfile>[];

      for (final likedId in likedIds) {
        final profile = await getProfile(likedId['likedProfileId']);
        if (profile != null) {
          profiles.add(profile);
        }
      }

      return profiles;
    } catch (e) {
      debugPrint('âŒ Error getting liked profiles: $e');
      return [];
    }
  }

  @override
  Future<bool> addLikedProfile(String uid, String likedProfileId) async {
    try {
      await _likesCollection.insertOne({
        'userId': uid,
        'likedProfileId': likedProfileId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('âŒ Error adding liked profile: $e');
      return false;
    }
  }

  @override
  Future<List<PlayerProfile>> getRecommendedProfiles(String uid) async {
    try {
      // Get all profiles except the user's own profile and already liked profiles
      final likedIds = await _likesCollection
          .find(where.eq('userId', uid))
          .map((doc) => doc['likedProfileId'] as String)
          .toList();

      final query = where.ne('userId', uid).nin('userId', likedIds);
      final results = await _profilesCollection.find(query).toList();

      return results
          .map((doc) => PlayerProfile.fromJson(doc['profile']))
          .toList();
    } catch (e) {
      debugPrint('âŒ Error getting recommended profiles: $e');
      return [];
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await _usernamesCollection.findOne(
        where.eq('username', username.toLowerCase()),
      );
      return result == null;
    } catch (e) {
      debugPrint('âŒ Error checking username availability: $e');
      return false;
    }
  }

  @override
  Future<bool> reserveUsername(String username, String userId) async {
    try {
      // First check if username is available
      if (!await isUsernameAvailable(username)) {
        return false;
      }

      // Reserve the username
      await _usernamesCollection.insertOne({
        'username': username.toLowerCase(),
        'userId': userId,
        'reservedAt': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('âŒ Error reserving username: $e');
      return false;
    }
  }

  @override
  Future<bool> updateUsername(String userId, String newUsername) async {
    try {
      // First check if new username is available
      if (!await isUsernameAvailable(newUsername)) {
        return false;
      }

      // Remove old username reservation
      await _usernamesCollection.deleteOne(where.eq('userId', userId));

      // Add new username reservation
      return reserveUsername(newUsername, userId);
    } catch (e) {
      debugPrint('âŒ Error updating username: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getMatches(String userId) async {
    try {
      final matches = await _matchesCollection.find({
        r'$or': [
          {'user1Id': userId},
          {'user2Id': userId},
        ],
      }).toList();

      // Extract the other user's ID for each match
      return matches.map((match) {
        final String otherId =
            match['user1Id'] == userId ? match['user2Id'] : match['user1Id'];
        return otherId;
      }).toList();
    } catch (e) {
      debugPrint('âŒ Error getting matches: $e');
      return [];
    }
  }

  @override
  Future<PlayerProfile?> getProfileById(String id) => getProfile(id);

  // Helper methods to get collections
  DbCollection get _profilesCollection =>
      _db!.collection(_profilesCollectionName);
  DbCollection get _usernamesCollection =>
      _db!.collection(_usernamesCollectionName);
  DbCollection get _likesCollection => _db!.collection(_likesCollectionName);
  DbCollection get _matchesCollection =>
      _db!.collection(_matchesCollectionName);
}
