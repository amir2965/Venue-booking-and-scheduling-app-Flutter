import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'simple_username_service.dart';

/// Implementation of PlayerProfileService using Firestore
class PlayerProfileService {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final UsernameService _usernameService;
  final List<PlayerProfile> _profiles = [];
  final Map<String, PlayerProfile> _userProfiles = {};
  final Map<String, List<String>> _likedProfiles = {};
  final Map<String, List<String>> _matches = {};

  // Shared preferences keys for caching
  final String _profilesCacheKey = 'cached_profiles';
  final String _likedProfilesCacheKey = 'cached_liked_profiles';
  final String _matchesCacheKey = 'cached_matches';

  PlayerProfileService(
      this._authService, this._firestoreService, this._usernameService) {
    debugPrint('PlayerProfileService initialized with Firestore');
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSavedData();
  }

  // Load saved data from shared preferences
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cached profiles
      final profilesJson = prefs.getString(_profilesCacheKey);
      if (profilesJson != null) {
        final Map<String, dynamic> profilesMap = json.decode(profilesJson);
        profilesMap.forEach((key, value) {
          try {
            final profile =
                PlayerProfile.fromJson(Map<String, dynamic>.from(value));
            _profiles.add(profile);
            _userProfiles[profile.user.id] = profile;
          } catch (e) {
            debugPrint('Error parsing cached profile: $e');
          }
        });
      }

      // Load liked profiles
      final likedJson = prefs.getString(_likedProfilesCacheKey);
      if (likedJson != null) {
        final Map<String, dynamic> likedMap = json.decode(likedJson);
        likedMap.forEach((key, value) {
          _likedProfiles[key] = List<String>.from(value);
        });
      }

      // Load matches
      final matchesJson = prefs.getString(_matchesCacheKey);
      if (matchesJson != null) {
        final Map<String, dynamic> matchesMap = json.decode(matchesJson);
        matchesMap.forEach((key, value) {
          _matches[key] = List<String>.from(value);
        });
      }

      debugPrint('Loaded ${_profiles.length} profiles from cache');

      // Refresh from Firestore if needed
      if (_profiles.isEmpty) {
        await _refreshProfilesFromFirestore();
      }
    } catch (e) {
      debugPrint('Error loading saved data: $e');
    }
  }

  // Refresh profiles from Firestore
  Future<void> _refreshProfilesFromFirestore() async {
    try {
      final allProfiles = await _firestoreService.getAllPlayerProfiles();

      for (final profileData in allProfiles) {
        try {
          final profile = PlayerProfile.fromJson(profileData);
          _profiles.add(profile);
          _userProfiles[profile.user.id] = profile;
        } catch (e) {
          debugPrint('Error parsing profile from Firestore: $e');
        }
      }

      debugPrint('Refreshed ${_profiles.length} profiles from Firestore');

      // Save to cache
      await _saveProfilesToCache();
    } catch (e) {
      debugPrint('Error refreshing profiles from Firestore: $e');
    }
  }

  // Save profiles to cache
  Future<void> _saveProfilesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert profiles to a map for storage
      final Map<String, dynamic> profilesMap = {};
      for (final profile in _profiles) {
        profilesMap[profile.user.id] = profile.toJson();
      }

      // Save profiles
      await prefs.setString(_profilesCacheKey, json.encode(profilesMap));

      // Save liked profiles
      await prefs.setString(
          _likedProfilesCacheKey, json.encode(_likedProfiles));

      // Save matches
      await prefs.setString(_matchesCacheKey, json.encode(_matches));

      debugPrint('Saved ${_profiles.length} profiles to cache');
    } catch (e) {
      debugPrint('Error saving profiles to cache: $e');
    }
  }

  // Get the current user's profile
  Future<PlayerProfile?> getCurrentUserProfile() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        debugPrint('No current user found');
        return null;
      }

      debugPrint('Getting profile for user: ${currentUser.id}');

      // Check if we have it in memory
      if (_userProfiles.containsKey(currentUser.id)) {
        debugPrint('Found profile in memory for ${currentUser.id}');
        return _userProfiles[currentUser.id];
      }

      // Try to get from Firestore
      final profileData =
          await _firestoreService.getPlayerProfile(currentUser.id);

      if (profileData != null) {
        try {
          final profile = PlayerProfile.fromJson(profileData);

          // Store in memory
          _userProfiles[currentUser.id] = profile;

          // Add to general profiles list if not already there
          if (!_profiles.any((p) => p.user.id == profile.user.id)) {
            _profiles.add(profile);
          }

          // Update cache
          await _saveProfilesToCache();

          debugPrint('Retrieved profile from Firestore: ${profile.firstName}');
          return profile;
        } catch (e) {
          debugPrint('Error parsing profile from Firestore: $e');
        }
      }

      debugPrint(
          'No profile found for user ${currentUser.id} - creating new one');

      // No profile found - create a new one
      final newProfile = PlayerProfile(
        user: currentUser,
        firstName: currentUser.displayName?.split(' ').first ?? '',
        bio: "I'm new to the Billiards Hub!",
        skillLevel: 1.0,
        skillTier: _getSkillTier(1.0),
        preferredGameTypes: ['8-Ball'],
        preferredLocation: '',
        availability: {},
        experiencePoints: 10,
        matchesPlayed: 0,
        winRate: 0.0,
        achievements: [],
      );

      // Store in memory
      _userProfiles[currentUser.id] = newProfile;
      _profiles.add(newProfile);

      // Save to Firestore
      try {
        await _firestoreService.savePlayerProfile(
            currentUser.id, newProfile.toJson());
        debugPrint('Created and saved new profile to Firestore');
      } catch (e) {
        debugPrint('Error saving new profile to Firestore: $e');
        // Continue with local profile regardless
      }

      // Update cache
      await _saveProfilesToCache();

      return newProfile;
    } catch (e) {
      debugPrint('Error getting current user profile: $e');
      return null;
    }
  }

  // Get a list of all profiles
  Future<List<PlayerProfile>> getProfiles() async {
    if (_profiles.isEmpty) {
      await _refreshProfilesFromFirestore();
    }
    return _profiles;
  }

  // Update a profile
  Future<bool> updateProfile(PlayerProfile profile) async {
    return await updatePlayerProfile(profile);
  }

  // Get list of profiles the current user has liked
  Future<List<String>> getLikedProfiles() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return [];

      return _likedProfiles[currentUser.id] ?? [];
    } catch (e) {
      debugPrint('Error getting liked profiles: $e');
      return [];
    }
  }

  // Get list of mutual matches
  Future<List<String>> getMatches() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return [];

      return _matches[currentUser.id] ?? [];
    } catch (e) {
      debugPrint('Error getting matches: $e');
      return [];
    }
  }

  // Get potential matches for the current user
  Future<List<PlayerProfile>> getPotentialMatches(
      {List<String>? excludeIds}) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return [];

      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile == null) return [];

      // Refresh profiles if needed
      if (_profiles.isEmpty) {
        await _refreshProfilesFromFirestore();
      }

      // IDs to exclude from potential matches
      final excludeSet = <String>{};
      if (excludeIds != null) excludeSet.addAll(excludeIds);
      excludeSet.add(currentUser.id); // Exclude self

      // Exclude already liked profiles
      final likedProfiles = await getLikedProfiles();
      excludeSet.addAll(likedProfiles);

      // Filter profiles based on criteria
      final potentialMatches = _profiles.where((profile) {
        return !excludeSet.contains(profile.user.id);
      }).toList();

      return potentialMatches;
    } catch (e) {
      debugPrint('Error getting potential matches: $e');
      return [];
    }
  }

  // Get a profile by ID
  Future<PlayerProfile?> getProfileById(String id) async {
    try {
      // Check if we have it in memory
      if (_userProfiles.containsKey(id)) {
        return _userProfiles[id];
      }

      // Try to get from Firestore
      final profileData = await _firestoreService.getPlayerProfile(id);

      if (profileData != null) {
        try {
          final profile = PlayerProfile.fromJson(profileData);

          // Store in memory
          _userProfiles[id] = profile;

          return profile;
        } catch (e) {
          debugPrint('Error parsing profile from Firestore: $e');
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting profile by ID: $e');
      return null;
    }
  }

  // Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    return await _usernameService.isUsernameAvailable(username);
  }

  // Update a player profile
  Future<bool> updatePlayerProfile(PlayerProfile profile) async {
    try {
      final userId = profile.user.id;

      // Save to Firestore
      await _firestoreService.savePlayerProfile(userId, profile.toJson());

      // Update in memory
      _userProfiles[userId] = profile;

      // Update in profiles list
      final index = _profiles.indexWhere((p) => p.user.id == userId);
      if (index >= 0) {
        _profiles[index] = profile;
      } else {
        _profiles.add(profile);
      }

      // Update cache
      await _saveProfilesToCache();

      debugPrint('Updated profile for user $userId');
      return true;
    } catch (e) {
      debugPrint('Error updating player profile: $e');
      return false;
    }
  }

  // Like a profile
  Future<bool> likeProfile(String profileId) async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return false;

      final userId = currentUser.id;

      // Add to liked profiles
      if (!_likedProfiles.containsKey(userId)) {
        _likedProfiles[userId] = [];
      }

      _likedProfiles[userId]!.add(profileId);

      // Check if this is a mutual match
      final isMatch = _likedProfiles.containsKey(profileId) &&
          _likedProfiles[profileId]!.contains(userId);

      // If it's a match, add to matches list
      if (isMatch) {
        if (!_matches.containsKey(userId)) {
          _matches[userId] = [];
        }
        _matches[userId]!.add(profileId);

        if (!_matches.containsKey(profileId)) {
          _matches[profileId] = [];
        }
        _matches[profileId]!.add(userId);
      }

      // Update cache
      await _saveProfilesToCache();

      return isMatch;
    } catch (e) {
      debugPrint('Error liking profile: $e');
      return false;
    }
  }

  // Helper function to determine skill tier from skill level
  String _getSkillTier(double skillLevel) {
    if (skillLevel < 1.0) return 'Beginner';
    if (skillLevel < 2.0) return 'Novice';
    if (skillLevel < 3.0) return 'Intermediate';
    if (skillLevel < 4.0) return 'Advanced';
    if (skillLevel < 4.5) return 'Expert';
    return 'Pro';
  }
}
