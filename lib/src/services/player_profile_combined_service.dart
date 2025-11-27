import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/player_profile.dart';
import 'mongodb_service.dart';
import 'auth_service.dart';

// Simplified service that doesn't depend on UsernameService
class PlayerProfileService {
  final AuthService _authService;
  final MongoDBService _mongoDBService;
  final List<PlayerProfile> _profiles = [];
  final Map<String, PlayerProfile> _userProfiles = {};
  final Map<String, List<String>> _likedProfiles = {};
  final Map<String, List<String>> _matches = {};

  PlayerProfileService(this._authService, this._mongoDBService) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSavedProfiles();
    if (_profiles.length < 10) {
      final mockProfiles = _generateMockProfiles();
      final existingUserIds = _userProfiles.keys.toSet();
      final newMockProfiles = mockProfiles
          .where((profile) => !existingUserIds.contains(profile.user.id))
          .toList();
      _profiles.addAll(newMockProfiles);
    }
  }

  // Load profiles from SharedPreferences and MongoDB
  Future<void> _loadSavedProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load from local storage first
      final profilesJson = prefs.getString('user_profiles');
      if (profilesJson != null) {
        final Map<String, dynamic> profilesData = json.decode(profilesJson);
        _userProfiles.clear();
        for (var entry in profilesData.entries) {
          final profile =
              PlayerProfile.fromJson(Map<String, dynamic>.from(entry.value));
          _userProfiles[entry.key] = profile;
          if (!_profiles.any((p) => p.user.id == profile.user.id)) {
            _profiles.add(profile);
          }
        }
      }

      // Load liked profiles and matches
      final likedProfilesJson = prefs.getString('liked_profiles');
      if (likedProfilesJson != null) {
        final Map<String, dynamic> likedData = json.decode(likedProfilesJson);
        _likedProfiles.clear();
        for (var entry in likedData.entries) {
          _likedProfiles[entry.key] = List<String>.from(entry.value);
        }
      }

      final matchesJson = prefs.getString('matches');
      if (matchesJson != null) {
        final Map<String, dynamic> matchesData = json.decode(matchesJson);
        _matches.clear();
        for (var entry in matchesData.entries) {
          _matches[entry.key] = List<String>.from(entry.value);
        }
      }

      // Try to sync with MongoDB if we're online
      final isConnected = await _mongoDBService.checkConnectivity();
      if (isConnected) {
        try {
          final profiles = await _mongoDBService.getAllPlayerProfiles();

          for (var profileData in profiles) {
            final profile = PlayerProfile.fromJson(profileData);
            _userProfiles[profileData['id']] = profile;
            if (!_profiles.any((p) => p.user.id == profile.user.id)) {
              _profiles.add(profile);
            }
          }

          // Save the merged data back to local storage
          await _saveUserProfiles();
        } catch (e) {
          debugPrint('Error syncing with MongoDB: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading saved profiles: $e');
    }
  }

  // Save profiles to SharedPreferences and MongoDB
  Future<void> _saveUserProfiles() async {
    try {
      final isConnected = await _mongoDBService.checkConnectivity();

      if (isConnected) {
        // Sync with MongoDB if we're online
        for (var profile in _userProfiles.values) {
          try {
            await _mongoDBService.savePlayerProfile(
                profile.user.id, profile.toJson());
            debugPrint('Saved profile to MongoDB for user ${profile.user.id}');
          } catch (e) {
            debugPrint(
                'Error saving profile to MongoDB for user ${profile.user.id}: $e');
            // Continue with other profiles even if one fails
          }
        }
      } else {
        debugPrint('Device is offline. Saving profiles to local storage only.');
      }

      // Always save to local storage as backup
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = json.encode(_userProfiles.map(
        (key, value) => MapEntry(key, value.toJson()),
      ));
      await prefs.setString('user_profiles', profilesJson);
      debugPrint('Saved ${_userProfiles.length} profiles to local storage');

      // Save liked profiles and matches
      await prefs.setString('liked_profiles', json.encode(_likedProfiles));
      await prefs.setString('matches', json.encode(_matches));
    } catch (e) {
      debugPrint('Error saving user profiles: $e');
    }
  }

  // Get the current user's profile
  Future<PlayerProfile?> getCurrentUserProfile() async {
    final currentUser = await _authService.getCurrentUser();
    debugPrint(
        'getCurrentUserProfile: currentUser=${currentUser != null ? currentUser.id : 'null'}');

    if (currentUser == null) {
      debugPrint('No current user found');
      return null;
    }

    // First check MongoDB for the user's profile
    try {
      final isConnected = await _mongoDBService.checkConnectivity();
      if (isConnected) {
        debugPrint(
            'Connected to network, attempting to fetch profile from MongoDB');
        final profileData =
            await _mongoDBService.getPlayerProfile(currentUser.id);

        if (profileData != null) {
          debugPrint('Found profile in MongoDB for user ${currentUser.id}');

          // Ensure the profile has complete data with detailed logging
          debugPrint('Profile data before ensuring fields:');
          debugPrint('  firstName: ${profileData['firstName']}');
          debugPrint('  skillTier: ${profileData['skillTier']}');
          debugPrint('  skillLevel: ${profileData['skillLevel']}');

          // Ensure firstName is not null and not empty
          profileData['firstName'] = profileData['firstName'] ?? '';
          if (profileData['firstName'] == '') {
            debugPrint('firstName is empty, setting to default value');
          }

          // Ensure skillTier is preserved as selected by user, not defaulted
          profileData['skillTier'] = profileData['skillTier'] ?? 'Novice';

          // Ensure skillLevel is a valid double
          if (profileData['skillLevel'] == null) {
            profileData['skillLevel'] = 1.0;
            debugPrint('skillLevel was null, setting to default: 1.0');
          } else if (profileData['skillLevel'] is! double) {
            try {
              profileData['skillLevel'] =
                  (profileData['skillLevel'] as num).toDouble();
              debugPrint(
                  'Converted skillLevel to double: ${profileData['skillLevel']}');
            } catch (e) {
              profileData['skillLevel'] = 1.0;
              debugPrint(
                  'Could not convert skillLevel to double, setting to default: 1.0');
            }
          }

          // Make sure user object is consistent
          if (profileData['user'] != null) {
            final userMap = profileData['user'] as Map<String, dynamic>;
            userMap['displayName'] =
                userMap['displayName'] ?? currentUser.displayName;
          }

          // Convert the MongoDB data to a PlayerProfile object
          final profile = PlayerProfile.fromJson(profileData);

          // Add detailed logging for debugging
          debugPrint('MongoDB profile converted to PlayerProfile:');
          debugPrint('  firstName: ${profile.firstName}');
          debugPrint('  displayName: ${profile.user.displayName}');
          debugPrint('  skillLevel: ${profile.skillLevel}');
          debugPrint('  skillTier: ${profile.skillTier}');

          // Update the cached profile
          _userProfiles[currentUser.id] = profile;

          // Also update the profile in the profiles list if it exists
          final existingProfileIndex =
              _profiles.indexWhere((p) => p.user.id == currentUser.id);
          if (existingProfileIndex >= 0) {
            _profiles[existingProfileIndex] = profile;
          } else {
            _profiles.add(profile);
          }

          // Save to local storage for offline access
          await _saveUserProfiles();

          return profile;
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile from MongoDB: $e');
      // Continue to local fallbacks
    }

    // Return cached profile if available
    if (_userProfiles.containsKey(currentUser.id)) {
      debugPrint('Found cached profile for user ${currentUser.id}');
      return _userProfiles[currentUser.id];
    }

    // Check if user already has a profile in our system
    final existingProfileIndex =
        _profiles.indexWhere((profile) => profile.user.id == currentUser.id);

    if (existingProfileIndex >= 0) {
      debugPrint(
          'Found existing profile in _profiles for user ${currentUser.id}');
      final profile = _profiles[existingProfileIndex];
      _userProfiles[currentUser.id] = profile;
      return profile;
    }
    debugPrint('Creating new profile for user ${currentUser.id}');
    // Create a new profile for the authenticated user
    final newProfile = PlayerProfile(
      user: currentUser,
      firstName: currentUser.displayName ?? 'New Player',
      bio: "I'm new to the Billiards Hub!",
      skillLevel: 1.0, // Always start at level 1
      skillTier: _getSkillTier(1.0),
      preferredGameTypes: ['Bowling'],
      // Set empty values for fields that require user input
      preferredLocation: '', // Empty to trigger profile setup
      availability: {}, // Empty to trigger profile setup
      experiencePoints: 10, // Start with 10 XP
      matchesPlayed: 0,
      winRate: 0.0,
      achievements: [],
    );

    // Add the new profile to our storage
    _profiles.add(newProfile);
    _userProfiles[currentUser.id] = newProfile;

    // Save to persistent storage
    await _saveUserProfiles();

    return newProfile;
  }

  // Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    // Check in MongoDB first
    try {
      final isConnected = await _mongoDBService.checkConnectivity();
      if (isConnected) {
        final isAvailable = await _mongoDBService.isUsernameAvailable(username);
        return isAvailable;
      }
    } catch (e) {
      debugPrint('Error checking username availability: $e');
    }

    // Fallback to local check if MongoDB is unavailable
    return _checkUsernameLocallyAsBackup(username);
  }

  // Fallback method to check username locally
  bool _checkUsernameLocallyAsBackup(String username) {
    final normalizedUsername = username.trim().toLowerCase();

    // Check if any existing profile uses this username
    for (final profile in _profiles) {
      if (profile.user.displayName?.trim().toLowerCase() ==
          normalizedUsername) {
        return false;
      }
    }

    return true;
  }

  // Update a player's profile (for profile setup and edits)
  Future<bool> updatePlayerProfile(PlayerProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final userId = profile.user.id;

      // Add detailed logging for debugging
      debugPrint('Updating player profile for user $userId:');
      debugPrint('  firstName: ${profile.firstName}');
      debugPrint('  displayName: ${profile.user.displayName}');
      debugPrint('  skillLevel: ${profile.skillLevel}');
      debugPrint('  skillTier: ${profile.skillTier}');

      // Update in-memory profile
      _userProfiles[userId] = profile;

      final profileIndex = _profiles.indexWhere((p) => p.user.id == userId);
      if (profileIndex >= 0) {
        _profiles[profileIndex] = profile;
      } else {
        _profiles.add(profile);
      }

      // Save to MongoDB first if connected
      final isConnected = await _mongoDBService.checkConnectivity();
      if (isConnected) {
        try {
          debugPrint(
              'Saving profile to MongoDB for user $userId: firstName=${profile.firstName}, skillTier=${profile.skillTier}');

          // Create a complete profile object to save
          final profileToSave = {
            'id': userId,
            'user': profile.user.toJson(),
            'firstName': profile.firstName,
            'bio': profile.bio,
            'skillLevel': profile.skillLevel,
            'skillTier': profile.skillTier,
            'preferredGameTypes': profile.preferredGameTypes,
            'availability': profile.availability,
            'preferredLocation': profile.preferredLocation,
            'experiencePoints': profile.experiencePoints,
            'matchesPlayed': profile.matchesPlayed,
            'winRate': profile.winRate,
            'achievements': profile.achievements,
            'gender': 'Not specified', // Default value
            'playStyle': '', // Default value
            'showInPartnerMatching': true, // Default value
          };

          await _mongoDBService.savePlayerProfile(userId, profileToSave);

          // Verify what was saved by retrieving it back
          final savedProfile = await _mongoDBService.getPlayerProfile(userId);
          if (savedProfile != null) {
            debugPrint('Verification after save - MongoDB profile:');
            debugPrint('  firstName: ${savedProfile['firstName']}');
            debugPrint('  skillTier: ${savedProfile['skillTier']}');
          }
        } catch (e) {
          debugPrint(
              'Error saving to MongoDB, falling back to local storage: $e');
        }
      }

      // Always save to local storage as a backup
      await _saveUserProfiles();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Get potential matches (for the partner swipe screen)
  Future<List<PlayerProfile>> getPotentialMatches({
    List<String> excludeIds = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_profiles.length < 15) {
      _profiles.addAll(_generateAdditionalProfiles());
    }

    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      return [];
    }

    final currentUserId = currentUser.id;

    return _profiles.where((profile) {
      if (profile.user.id == currentUserId) return false;
      if (excludeIds.contains(profile.user.id)) return false;
      if (_matches.containsKey(currentUserId) &&
          _matches[currentUserId]!.contains(profile.user.id)) return false;
      return true;
    }).toList();
  }

  // Add a profile to the liked list and check if it's a match
  Future<bool> likeProfile(String profileId) async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      return false;
    }

    final currentUserId = currentUser.id;

    if (!_likedProfiles.containsKey(currentUserId)) {
      _likedProfiles[currentUserId] = [];
    }

    if (!_likedProfiles[currentUserId]!.contains(profileId)) {
      _likedProfiles[currentUserId]!.add(profileId);
    }

    await _saveUserProfiles();

    // Check if this creates a match
    if (_likedProfiles.containsKey(profileId) &&
        _likedProfiles[profileId]!.contains(currentUserId)) {
      // It's a match! Add to matches list
      if (!_matches.containsKey(currentUserId)) {
        _matches[currentUserId] = [];
      }
      if (!_matches[currentUserId]!.contains(profileId)) {
        _matches[currentUserId]!.add(profileId);
      }

      if (!_matches.containsKey(profileId)) {
        _matches[profileId] = [];
      }
      if (!_matches[profileId]!.contains(currentUserId)) {
        _matches[profileId]!.add(currentUserId);
      }

      await _saveUserProfiles();
      return true; // Return true to indicate it's a match
    }

    return false; // No match yet
  }

  // Get the user's matches
  Future<List<String>> getMatches() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      return [];
    }

    final currentUserId = currentUser.id;
    return _matches[currentUserId] ?? [];
  }

  // Get the user's liked profiles
  Future<List<PlayerProfile>> getLikedProfiles() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      return [];
    }

    final currentUserId = currentUser.id;
    final likedIds = _likedProfiles[currentUserId] ?? [];
    final profiles = <PlayerProfile>[];

    for (final id in likedIds) {
      final profile = await getProfileById(id);
      if (profile != null) {
        profiles.add(profile);
      }
    }

    return profiles;
  }

  // Get a specific profile by ID
  Future<PlayerProfile?> getProfileById(String userId) async {
    // Try MongoDB first if connected
    try {
      final isConnected = await _mongoDBService.checkConnectivity();
      if (isConnected) {
        final profileData = await _mongoDBService.getPlayerProfile(userId);
        if (profileData != null) {
          final profile = PlayerProfile.fromJson(profileData);

          // Cache the profile
          _userProfiles[userId] = profile;
          final existingProfileIndex =
              _profiles.indexWhere((p) => p.user.id == userId);
          if (existingProfileIndex >= 0) {
            _profiles[existingProfileIndex] = profile;
          } else {
            _profiles.add(profile);
          }

          return profile;
        }
      }
    } catch (e) {
      debugPrint('Error getting profile from MongoDB: $e');
    }

    // Check local cache
    if (_userProfiles.containsKey(userId)) {
      return _userProfiles[userId];
    }

    // Check profiles list
    final profileIndex = _profiles.indexWhere((p) => p.user.id == userId);
    if (profileIndex >= 0) {
      return _profiles[profileIndex];
    }

    return null;
  }

  // Helper method to generate mock profiles for development/testing
  List<PlayerProfile> _generateMockProfiles() {
    // Implementation details omitted for brevity
    return [];
  }

  // Helper method to generate additional profiles if needed
  List<PlayerProfile> _generateAdditionalProfiles() {
    // Implementation details omitted for brevity
    return [];
  }

  // Helper to determine skill tier from numeric skill level
  String _getSkillTier(double skillLevel) {
    if (skillLevel < 1.0) return 'Novice';
    if (skillLevel < 2.0) return 'Beginner';
    if (skillLevel < 3.0) return 'Intermediate';
    if (skillLevel < 4.0) return 'Advanced';
    if (skillLevel < 4.5) return 'Expert';
    return 'Pro';
  }
}
