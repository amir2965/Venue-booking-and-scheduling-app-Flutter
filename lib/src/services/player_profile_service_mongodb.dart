import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/player_profile.dart';
import 'mongodb_service_base.dart';
import 'auth_service.dart';
import 'simple_username_service.dart';

class PlayerProfileService {
  final AuthService _authService;
  final MongoDBServiceBase _mongoDBService;
  final UsernameService _usernameService;
  final Map<String, PlayerProfile> _userProfiles = {};

  PlayerProfileService(
      this._authService, this._mongoDBService, this._usernameService);

  // Add mock profiles if needed (for testing only)
  Future<void> _addMockProfiles() async {
    final firstNames = [
      'Alex',
      'Jordan',
      'Taylor',
      'Casey',
      'Morgan',
      'Riley',
      'Jamie',
      'Quinn',
      'Avery',
      'Blake'
    ];

    final lastNames = [
      'Smith',
      'Johnson',
      'Williams',
      'Brown',
      'Jones',
      'Garcia',
      'Miller',
      'Davis',
      'Rodriguez',
      'Martinez'
    ];

    for (int i = 0; i < 10; i++) {
      final firstName = firstNames[i % firstNames.length];
      final lastName = lastNames[(i + 3) % lastNames.length];
      final skillLevel = 1.0 + (i * 0.3);
      final mockUserId = 'mock-user-$i';

      final profile = PlayerProfile(
        user: User(
          id: mockUserId,
          email:
              '${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com',
          displayName: '$firstName $lastName',
          photoUrl: null,
        ),
        firstName: firstName,
        lastName: lastName,
        username: '${firstName.toLowerCase()}_${lastName.toLowerCase()}',
        bio: "I enjoy playing pool and meeting new people!",
        skillLevel: skillLevel,
        skillTier: _getSkillTier(skillLevel),
        preferredGameTypes: ['Bowling'],
        preferredLocation: 'Local Pool Hall',
        availability: {
          'Friday': ['Evening'],
          'Saturday': ['Afternoon']
        },
        experiencePoints: 10 + (i * 100),
        matchesPlayed: 10 + (i * 3),
        winRate: 0.3 + (i * 0.05),
        achievements: [],
      );

      // Save mock profile using new interface
      await _mongoDBService.createProfile(profile);

      // Reserve username
      await _usernameService.reserveUsername(
        profile.user.displayName ?? profile.firstName,
        mockUserId,
      );

      _userProfiles[mockUserId] = profile;
    }
  }

  // Get all profiles (cached or fetched)
  Future<List<PlayerProfile>> getAllProfiles() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    try {
      return await _mongoDBService.getRecommendedProfiles(user.id);
    } catch (e) {
      debugPrint('Error loading profiles from MongoDB: $e');
      return [];
    }
  }

  // Get user profile by ID
  Future<PlayerProfile?> getProfile(String userId) async {
    try {
      // Check in-memory cache first
      if (_userProfiles.containsKey(userId)) {
        return _userProfiles[userId];
      }

      // Fetch from MongoDB using new interface
      final profile = await _mongoDBService.getProfile(userId);
      if (profile != null) {
        _userProfiles[userId] = profile;
        return profile;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  /// Get the current user's profile
  Future<PlayerProfile?> getCurrentUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) return null;
    return getProfile(user.id);
  }

  /// Get a profile by ID (alias for getProfile)
  Future<PlayerProfile?> getProfileById(String id) async {
    return getProfile(id);
  }

  /// Ensure the user has a profile
  Future<PlayerProfile> ensureUserHasProfile() async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    final profile = await getCurrentUserProfile();
    if (profile != null) return profile;

    // Create a new profile with default values
    final newProfile = PlayerProfile(
      user: user,
      firstName: user.displayName?.split(' ')[0] ?? 'New',
      lastName: (user.displayName?.split(' ').length ?? 0) > 1
          ? user.displayName!.split(' ').sublist(1).join(' ')
          : 'User',
      username:
          user.displayName?.toLowerCase().replaceAll(' ', '_') ?? 'new_user',
      bio: 'Hey there! I\'m new to Billiards Hub.',
      skillLevel: 0.0,
      skillTier: 'Beginner',
      preferredGameTypes: ['8-Ball'],
      preferredLocation: '',
      availability: {},
      experiencePoints: 0,
      matchesPlayed: 0,
      winRate: 0.0,
      achievements: [],
    );

    await _mongoDBService.createProfile(newProfile);
    return newProfile;
  }

  /// Get the current user's liked profiles
  Future<List<PlayerProfile>> getLikedProfiles() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    return await _mongoDBService.getLikedProfiles(user.id);
  }

  /// Get the user's matches
  Future<List<String>> getMatches() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    return await _mongoDBService.getMatches(user.id);
  }

  /// Get potential matches for the user
  Future<List<PlayerProfile>> getPotentialMatches(
      {List<String>? excludeIds}) async {
    final user = _authService.currentUser;
    if (user == null) return [];

    final profiles = await _mongoDBService.getRecommendedProfiles(user.id);

    return profiles
        .where((p) =>
            p.user.id != user.id && !(excludeIds?.contains(p.user.id) ?? false))
        .toList();
  }

  /// Like a profile
  Future<bool> likeProfile(String profileId) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      await _mongoDBService.addLikedProfile(user.id, profileId);
      return true;
    } catch (e) {
      debugPrint('Error liking profile: $e');
      return false;
    }
  }

  /// Update a player profile
  Future<void> updatePlayerProfile(PlayerProfile profile) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    await _mongoDBService.updateProfile(profile);
    _userProfiles[user.id] = profile;
  }

  /// Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    return _mongoDBService.isUsernameAvailable(username);
  }

  String _getSkillTier(double skillLevel) {
    if (skillLevel < 2.0) return 'Beginner';
    if (skillLevel < 3.0) return 'Amateur';
    if (skillLevel < 4.0) return 'Intermediate';
    if (skillLevel < 5.0) return 'Advanced';
    return 'Expert';
  }
}
