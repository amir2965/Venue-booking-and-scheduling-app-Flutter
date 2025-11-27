import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/venue.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  // For tracking connectivity changes
  StreamSubscription? _connectivitySubscription;
  bool _isConnected = true;

  // Collections
  final String _usersCollection = 'users';
  final String _venuesCollection = 'venues';
  final String _usernamesCollection = 'usernames';

  // Shared Preferences keys
  final String _cachedUsernamesKey = 'cached_usernames';

  // Constructor that sets up connectivity monitoring
  FirestoreService() {
    _initConnectivityMonitoring();
  }

  // Initialize connectivity monitoring to sync data when back online
  void _initConnectivityMonitoring() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) async {
      final wasConnected = _isConnected;
      _isConnected = result != ConnectivityResult.none;

      // If we just got back online after being offline, sync local data
      if (_isConnected && !wasConnected) {
        debugPrint('Connection restored. Synchronizing cached usernames...');
        await synchronizeCachedUsernames();
      }
    });

    // Initialize current connection state
    _connectivity.checkConnectivity().then((result) {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  // Dispose connectivity subscription
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // Helper method to check if device is currently connected
  Future<bool> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _isConnected = connectivityResult != ConnectivityResult.none;
    return _isConnected;
  }

  // Cache usernames locally for offline access
  Future<void> _cacheUsername(String username, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUsernames = prefs.getString(_cachedUsernamesKey);
      Map<String, dynamic> usernamesMap = {};

      if (cachedUsernames != null) {
        usernamesMap = json.decode(cachedUsernames);
      }

      usernamesMap[username.toLowerCase()] = userId;
      await prefs.setString(_cachedUsernamesKey, json.encode(usernamesMap));
    } catch (e) {
      debugPrint('Error caching username: $e');
    }
  }

  // Remove a username from local cache
  Future<void> _removeCachedUsername(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUsernamesJson = prefs.getString(_cachedUsernamesKey);

      if (cachedUsernamesJson != null) {
        Map<String, dynamic> cachedUsernames = Map<String, dynamic>.from(
            Map<String, dynamic>.from(Map.castFrom(
                jsonDecode(cachedUsernamesJson) as Map<dynamic, dynamic>)));

        // Remove the username
        cachedUsernames.remove(username.trim().toLowerCase());

        // Save updated cache
        await prefs.setString(_cachedUsernamesKey, jsonEncode(cachedUsernames));
      }
    } catch (e) {
      debugPrint('Error removing cached username: $e');
    }
  }

  // Check if a username exists in local cache
  Future<bool> _isUsernameCached(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUsernamesJson = prefs.getString(_cachedUsernamesKey);

      if (cachedUsernamesJson != null) {
        Map<String, dynamic> cachedUsernames = Map<String, dynamic>.from(
            Map<String, dynamic>.from(Map.castFrom(
                jsonDecode(cachedUsernamesJson) as Map<dynamic, dynamic>)));

        return cachedUsernames.containsKey(username.trim().toLowerCase());
      }
    } catch (e) {
      debugPrint('Error checking cached username: $e');
    }

    return false;
  }

  // Synchronize local username cache with Firestore
  Future<void> synchronizeCachedUsernames() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return; // Can't synchronize while offline
      }

      final prefs = await SharedPreferences.getInstance();
      final cachedUsernamesJson = prefs.getString(_cachedUsernamesKey);

      if (cachedUsernamesJson != null) {
        Map<String, dynamic> cachedUsernames = Map<String, dynamic>.from(
            Map<String, dynamic>.from(Map.castFrom(
                jsonDecode(cachedUsernamesJson) as Map<dynamic, dynamic>)));

        // Batch operation for performance
        WriteBatch batch = _firestore.batch();

        // Add all cached usernames to Firestore
        for (var entry in cachedUsernames.entries) {
          final username = entry.key;
          final userData = entry.value;

          DocumentReference docRef =
              _firestore.collection(_usernamesCollection).doc(username);
          batch.set(docRef, userData, SetOptions(merge: true));
        }

        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error synchronizing cached usernames: $e');
    }
  }

  // User methods
  Future<void> createOrUpdateUser(User user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).set(
            user.toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to create or update user: $e');
    }
  }

  Future<User?> getUserById(String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return User.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Stream<User?> streamUserById(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return User.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Venue methods
  Future<void> createOrUpdateVenue(Venue venue) async {
    try {
      await _firestore.collection(_venuesCollection).doc(venue.id).set(
            venue.toJson(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to create or update venue: $e');
    }
  }

  Future<Venue?> getVenueById(String venueId) async {
    try {
      final doc =
          await _firestore.collection(_venuesCollection).doc(venueId).get();
      if (doc.exists && doc.data() != null) {
        return Venue.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get venue: $e');
    }
  }

  Future<List<Venue>> getAllVenues() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection(_venuesCollection).get();
      List<Venue> venues = [];
      for (var doc in snapshot.docs) {
        if (doc.data() != null) {
          venues.add(Venue.fromJson(doc.data() as Map<String, dynamic>));
        }
      }
      return venues;
    } catch (e) {
      throw Exception('Failed to get venues: $e');
    }
  }

  Stream<List<Venue>> streamVenues() {
    return _firestore.collection(_venuesCollection).snapshots().map(
      (snapshot) {
        List<Venue> venues = [];
        for (var doc in snapshot.docs) {
          venues.add(Venue.fromJson(doc.data() as Map<String, dynamic>));
        }
        return venues;
      },
    );
  }

  Future<void> deleteVenue(String venueId) async {
    try {
      await _firestore.collection(_venuesCollection).doc(venueId).delete();
    } catch (e) {
      throw Exception('Failed to delete venue: $e');
    }
  }

  // Username methods
  Future<bool> isUsernameAvailable(String username) async {
    if (username.trim().isEmpty) {
      return false; // Empty usernames are not available
    }

    // Normalize the username (convert to lowercase)
    final normalizedUsername = username.trim().toLowerCase();

    try {
      // First check the connection status
      final connectivityResult = await _connectivity.checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;

      // If we're online, query Firestore and update local cache
      if (isConnected) {
        try {
          // Check if username exists in the usernames collection
          final docSnapshot = await _firestore
              .collection(_usernamesCollection)
              .doc(normalizedUsername)
              .get();

          final isAvailable = !docSnapshot.exists;

          // If available, we don't need to update local cache
          // If not available, update local cache for offline access
          if (!isAvailable) {
            final userData = docSnapshot.data();
            if (userData != null) {
              await _cacheUsername(username, userData['userId'] as String);
            }
          }

          return isAvailable;
        } catch (e) {
          debugPrint('Error checking username in Firestore: $e');
          // Fall back to local cache if Firestore query fails
          return !(await _isUsernameCached(username));
        }
      } else {
        // We're offline, check the local cache
        debugPrint('Device is offline, checking local username cache');
        return !(await _isUsernameCached(username));
      }
    } catch (e) {
      debugPrint('Error in isUsernameAvailable: $e');
      // Last resort fallback
      return !(await _isUsernameCached(username));
    }
  }

  Future<void> reserveUsername(String username, String userId) async {
    if (username.trim().isEmpty) {
      throw Exception('Cannot reserve empty username');
    }

    // Normalize the username
    final normalizedUsername = username.trim().toLowerCase();

    try {
      // First check the connection status
      final connectivityResult = await _connectivity.checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;

      // Always cache username locally for offline access
      await _cacheUsername(username, userId);

      // If we're online, update Firestore
      if (isConnected) {
        try {
          // Create a document in the usernames collection
          await _firestore
              .collection(_usernamesCollection)
              .doc(normalizedUsername)
              .set({
            'userId': userId,
            'username': username.trim(), // Store original case
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Error reserving username in Firestore: $e');
          // We still have it in local cache, so we'll sync later
          // Not throwing an exception as local operation succeeded
        }
      } else {
        debugPrint('Device is offline, username reserved locally only');
        // Username is cached locally and will be synced when back online
      }
    } catch (e) {
      debugPrint('Error in reserveUsername: $e');
      throw Exception('Failed to reserve username: $e');
    }
  }

  Future<void> updateUsername(
      String oldUsername, String newUsername, String userId) async {
    if (newUsername.trim().isEmpty) {
      throw Exception('Cannot update to empty username');
    }

    // Normalize usernames
    final normalizedOldUsername = oldUsername.trim().toLowerCase();
    final normalizedNewUsername = newUsername.trim().toLowerCase();

    if (normalizedOldUsername == normalizedNewUsername) {
      return; // No change needed
    }

    try {
      // First check the connection status
      final connectivityResult = await _connectivity.checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;

      // Always update local cache first
      await _removeCachedUsername(oldUsername);
      await _cacheUsername(newUsername, userId);

      // If we're online, update Firestore
      if (isConnected) {
        try {
          // Execute in a transaction to ensure consistency
          await _firestore.runTransaction((transaction) async {
            // Check if new username is available
            final newUsernameDoc = await transaction.get(_firestore
                .collection(_usernamesCollection)
                .doc(normalizedNewUsername));

            if (newUsernameDoc.exists) {
              final existingUserId = newUsernameDoc.data()?['userId'];
              if (existingUserId != userId) {
                throw Exception('Username is already taken');
              }
              // If it exists but belongs to this user, that's fine
            }

            // Delete old username document
            transaction.delete(_firestore
                .collection(_usernamesCollection)
                .doc(normalizedOldUsername));

            // Create new username document
            transaction.set(
                _firestore
                    .collection(_usernamesCollection)
                    .doc(normalizedNewUsername),
                {
                  'userId': userId,
                  'username': newUsername.trim(), // Store original case
                  'createdAt': FieldValue.serverTimestamp(),
                });
          });
        } catch (e) {
          debugPrint('Error updating username in Firestore: $e');
          // Local cache is already updated, so we'll sync when possible
          // Not throwing the exception as local operation succeeded
        }
      } else {
        debugPrint('Device is offline, username updated locally only');
        // Username is updated in local cache and will be synced when online
      }
    } catch (e) {
      debugPrint('Error in updateUsername: $e');
      throw Exception('Failed to update username: $e');
    }
  }

  // Save a player profile to Firestore
  Future<void> savePlayerProfile(
      String userId, Map<String, dynamic> profileData) async {
    if (!_isConnected) return;

    try {
      await _firestore
          .collection('player_profiles')
          .doc(userId)
          .set(profileData);
    } catch (e) {
      debugPrint('Error saving player profile to Firestore: $e');
      throw e;
    }
  }

  // Get all player profiles from Firestore
  Future<List<Map<String, dynamic>>> getAllPlayerProfiles() async {
    if (!_isConnected) return [];

    try {
      final snapshot = await _firestore.collection('player_profiles').get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error getting player profiles from Firestore: $e');
      return [];
    }
  }

  // Get a specific player profile from Firestore by user ID
  Future<Map<String, dynamic>?> getPlayerProfile(String userId) async {
    if (!_isConnected) return null;

    try {
      final docSnapshot =
          await _firestore.collection('player_profiles').doc(userId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        debugPrint(
            'Retrieved player profile from Firestore: ${data['firstName']}, skillTier: ${data['skillTier']}, skillLevel: ${data['skillLevel']}');
        return {'id': docSnapshot.id, ...data};
      }
      return null;
    } catch (e) {
      debugPrint('Error getting player profile from Firestore: $e');
      return null;
    }
  }
}
