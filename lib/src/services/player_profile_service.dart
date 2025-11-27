import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/player_profile.dart';
import '../constants/venue_sports.dart';
import 'mongodb_service.dart';
import 'auth_service.dart';
import 'simple_username_service.dart';

class PlayerProfileService {
  final AuthService _authService;
  final MongoDBService _mongoDBService;
  final UsernameService _usernameService;
  final List<PlayerProfile> _profiles = [];
  final Map<String, PlayerProfile> _userProfiles = {};
  final Map<String, List<String>> _likedProfiles = {};
  final Map<String, List<String>> _matches = {};

  PlayerProfileService(
      this._authService, this._mongoDBService, this._usernameService) {
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

  // Load profiles from SharedPreferences
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

      // Try to sync with Firestore if we're online
      final isConnected = await _firestoreService.checkConnectivity();
      if (isConnected) {
        try {
          final profiles = await _firestoreService.getAllPlayerProfiles();

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
          debugPrint('Error syncing with Firestore: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading saved profiles: $e');
    }
  }

  // Save profiles to SharedPreferences
  Future<void> _saveUserProfiles() async {
    try {
      final isConnected = await _firestoreService.checkConnectivity();

      if (isConnected) {
        // Sync with Firestore if we're online
        for (var profile in _userProfiles.values) {
          try {
            await _firestoreService.savePlayerProfile(
                profile.user.id, profile.toJson());
            debugPrint(
                'Saved profile to Firestore for user ${profile.user.id}');
          } catch (e) {
            debugPrint(
                'Error saving profile to Firestore for user ${profile.user.id}: $e');
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

    // First check Firestore for the user's profile
    try {
      final isConnected = await _firestoreService.checkConnectivity();
      if (isConnected) {
        debugPrint(
            'Connected to network, attempting to fetch profile from Firestore');
        final profileData =
            await _firestoreService.getPlayerProfile(currentUser.id);

        if (profileData != null) {
          debugPrint('Found profile in Firestore for user ${currentUser.id}');
          // Convert the Firestore data to a PlayerProfile object
          final profile = PlayerProfile.fromJson(profileData);

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
      debugPrint('Error fetching profile from Firestore: $e');
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

    debugPrint(
        'Creating new profile for user ${currentUser.id}'); // Create a new profile for the authenticated user
    final newProfile = PlayerProfile(
      user: currentUser,
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

  // Update a player's profile (for profile setup and edits)
  Future<bool> updatePlayerProfile(PlayerProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final userId = profile.user.id;
      final newUsername = profile.user.displayName?.trim();

      PlayerProfile? oldProfile;
      final index = _profiles.indexWhere((p) => p.user.id == userId);
      if (index >= 0) {
        oldProfile = _profiles[index];
      }
      final oldUsername = oldProfile?.user.displayName?.trim();

      if (newUsername != null && newUsername.isNotEmpty) {
        if (oldUsername == null || oldUsername != newUsername) {
          try {
            final isAvailable =
                await _usernameService.isUsernameAvailable(newUsername);
            if (!isAvailable) {
              debugPrint('Username $newUsername is already taken');
              return false;
            }
            if (oldUsername != null && oldUsername.isNotEmpty) {
              try {
                final success =
                    await _usernameService.updateUsername(userId, newUsername);
                if (!success) {
                  debugPrint(
                      'Failed to update username from $oldUsername to $newUsername');
                  return _handleServerFallback(profile, userId, newUsername);
                }
                debugPrint(
                    'Updated username from $oldUsername to $newUsername');
              } catch (e) {
                debugPrint('Error updating username, trying fallback: $e');
                return _handleServerFallback(profile, userId, newUsername);
              }
            } else {
              try {
                final success =
                    await _usernameService.reserveUsername(newUsername, userId);
                if (!success) {
                  debugPrint('Failed to reserve username $newUsername');
                  return _handleServerFallback(profile, userId, newUsername);
                }
                debugPrint('Reserved new username $newUsername');
              } catch (e) {
                debugPrint('Error reserving username, trying fallback: $e');
                return _handleServerFallback(profile, userId, newUsername);
              }
            }
          } catch (e) {
            debugPrint(
                'Error checking username availability, trying fallback: $e');
            if (_checkUsernameLocallyAsBackup(newUsername)) {
              return _handleServerFallback(profile, userId, newUsername);
            }
            return false;
          }
        }
      }

      // Update in-memory profile
      _userProfiles[userId] = profile;

      final profileIndex = _profiles.indexWhere((p) => p.user.id == userId);
      if (profileIndex >= 0) {
        _profiles[profileIndex] = profile;
      } else {
        _profiles.add(profile);
      }

      // Save to Firestore first if connected
      final isConnected = await _firestoreService.checkConnectivity();
      if (isConnected) {
        try {
          debugPrint('Saving profile to Firestore for user $userId');
          await _firestoreService.savePlayerProfile(userId, profile.toJson());
        } catch (e) {
          debugPrint(
              'Error saving to Firestore, falling back to local storage: $e');
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

  // Handle server fallback mode for profile updates
  bool _handleServerFallback(
      PlayerProfile profile, String userId, String newUsername) {
    debugPrint('Handling profile update in fallback mode');

    // Check username availability locally
    if (!_checkUsernameLocallyAsBackup(newUsername)) {
      debugPrint('Username $newUsername is taken (local check)');
      return false;
    }

    // Update in-memory profile
    _userProfiles[userId] = profile;

    final profileIndex = _profiles.indexWhere((p) => p.user.id == userId);
    if (profileIndex >= 0) {
      _profiles[profileIndex] = profile;
    } else {
      _profiles.add(profile);
    }

    // Save to local storage asynchronously
    _saveUserProfiles();

    debugPrint('Profile updated successfully in fallback mode');
    return true;
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
      if (!_matches.containsKey(profileId)) {
        _matches[profileId] = [];
      }

      if (!_matches[currentUserId]!.contains(profileId)) {
        _matches[currentUserId]!.add(profileId);
      }
      if (!_matches[profileId]!.contains(currentUserId)) {
        _matches[profileId]!.add(currentUserId);
      }

      // Save the updated matches
      await _saveUserProfiles();
      return true; // Return true to indicate a match was created
    }

    return false; // No match was created
  }

  // Get the current user's liked profiles
  Future<List<String>> getLikedProfiles() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      return [];
    }

    return _likedProfiles[currentUser.id] ?? [];
  }

  // Get the current user's matches
  Future<List<String>> getMatches() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      return [];
    }

    return _matches[currentUser.id] ?? [];
  }

  // Get a profile by user ID
  Future<PlayerProfile?> getProfileById(String userId) async {
    // First check in-memory cache
    if (_userProfiles.containsKey(userId)) {
      return _userProfiles[userId];
    }

    // If not in memory, try to fetch from Firestore
    try {
      final isConnected = await _firestoreService.checkConnectivity();
      if (isConnected) {
        final profileData = await _firestoreService.getPlayerProfile(userId);
        if (profileData != null) {
          final profile = PlayerProfile.fromJson(profileData);
          // Cache the profile
          _userProfiles[userId] = profile;
          return profile;
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile for ID $userId: $e');
    }

    // Try to find in the _profiles list if not found elsewhere
    final profileIndex = _profiles.indexWhere((p) => p.user.id == userId);
    if (profileIndex >= 0) {
      final profile = _profiles[profileIndex];
      _userProfiles[userId] = profile; // Cache it for future use
      return profile;
    }

    return null;
  }

  // Check if a username already exists
  Future<bool> isUsernameAvailable(String username) async {
    debugPrint('Checking if username "$username" is available');
    if (username.trim().isEmpty) {
      return false; // Empty usernames are not available
    }

    try {
      final isAvailable = await _usernameService.isUsernameAvailable(username);
      debugPrint(
          'Username "$username" is ${isAvailable ? "available" : "not available"}');
      return isAvailable;
    } catch (e) {
      debugPrint('Error checking username availability: $e');
      return _checkUsernameLocallyAsBackup(username);
    }
  }

  // Fallback method to check username locally when Firebase is unavailable
  bool _checkUsernameLocallyAsBackup(String username) {
    final normalizedUsername = username.trim().toLowerCase();
    return !_profiles.any((profile) =>
        profile.user.displayName?.trim().toLowerCase() == normalizedUsername);
  }

  // Generate mock profiles for demo/testing
  List<PlayerProfile> _generateMockProfiles() {
    final List<String> firstNames = [
      'Alex',
      'Jordan',
      'Taylor',
      'Casey',
      'Morgan',
      'Riley',
      'Jamie',
      'Quinn',
      'Avery',
      'Blake',
      'Charlie',
      'Dakota',
      'Drew',
      'Elliot',
      'Frankie',
      'Hayden',
      'Jesse',
      'Kelly',
      'Leslie',
      'Max',
      'Nico',
      'Parker',
      'Reese',
      'Sam',
      'Tristan'
    ];

    final List<String> lastNames = [
      'Smith',
      'Johnson',
      'Williams',
      'Brown',
      'Jones',
      'Garcia',
      'Miller',
      'Davis',
      'Rodriguez',
      'Martinez',
      'Hernandez',
      'Lopez',
      'Gonzalez',
      'Wilson',
      'Anderson',
      'Thomas',
      'Taylor',
      'Moore',
      'Jackson',
      'Martin',
      'Lee',
      'Perez',
      'Thompson',
      'White',
      'Harris'
    ];

    final List<PlayerProfile> mockProfiles = [];

    for (int i = 0; i < 10; i++) {
      final firstName = firstNames[i % firstNames.length];
      final lastName = lastNames[(i + 3) %
          lastNames
              .length]; // Create a random skill level but let's make them level 1 for demo
      final skillLevel = 1.0;
      final experiencePoints =
          10 + (i * 100); // Vary the experience points for demo users

      mockProfiles.add(
        PlayerProfile(
          user: User(
            id: 'player$i',
            email:
                '${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com',
            displayName: '$firstName $lastName',
            photoUrl: null, // Replace with actual photo URLs in a real app
          ),
          bio: _generateRandomBio(firstName, i),
          skillLevel: skillLevel,
          skillTier: _getSkillTier(skillLevel),
          preferredGameTypes: _generateRandomGameTypes(i),
          preferredLocation: _generateRandomLocation(i),
          availability: _generateRandomAvailability(i),
          experiencePoints: experiencePoints,
          matchesPlayed: 10 + (i * 3),
          winRate: 0.3 + (i * 0.05),
          achievements: _generateRandomAchievements(i),
        ),
      );
    }

    return mockProfiles;
  }

  // Generate additional profiles (for when we run out)
  List<PlayerProfile> _generateAdditionalProfiles() {
    return _generateMockProfiles();
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

  // Helper function to generate a random bio
  String _generateRandomBio(String name, int seed) {
    final List<String> bios = [
      "$name here! I've been playing pool for about ${seed % 10 + 1} years. Looking for casual games and to improve my skills.",
      "I enjoy a good challenge on the pool table. ${seed % 2 == 0 ? "I prefer defensive play." : "I like to take risks and go for difficult shots."}",
      "Just looking for friendly matches. Nothing too competitive. I usually play ${seed % 2 == 0 ? "weekends" : "evenings after work"}.",
      "Semi-serious pool player. ${seed % 2 == 0 ? "I compete in local tournaments occasionally." : "I play in a league on Thursdays."}",
      "I like to play for fun but don't mind a competitive game now and then. Always looking to learn new techniques!",
      "Started playing in college and got hooked. Looking for partners to practice with regularly.",
      "${seed % 2 == 0 ? "Casual player" : "Competitive spirit"} who enjoys a good game and good conversation.",
      "Pool is my therapy. ${seed % 2 == 0 ? "I play to relax and unwind." : "It helps me focus and clear my mind."}",
      "I'm working on improving my ${seed % 2 == 0 ? 'bank shots' : 'position play'}. Would love to find partners of similar skill level.",
      "Friendly player looking for regular matches. I can teach beginners or challenge experienced players.",
    ];

    return bios[seed % bios.length];
  }

  // Helper function to generate random sports
  List<String> _generateRandomGameTypes(int seed) {
    final List<String> allSports = VenueSports.allSports;
    final List<String> selectedSports = [];

    // First sport selection (everyone has at least one)
    selectedSports.add(allSports[seed % allSports.length]);

    // Potentially add a second sport
    if (seed % 3 != 0) {
      final secondSport = allSports[(seed + 2) % allSports.length];
      if (!selectedSports.contains(secondSport)) {
        selectedSports.add(secondSport);
      }
    }

    // Potentially add a third sport for variety
    if (seed % 7 == 0) {
      final thirdSport = allSports[(seed + 4) % allSports.length];
      if (!selectedSports.contains(thirdSport)) {
        selectedSports.add(thirdSport);
      }
    }

    return selectedSports;
  }

  // Helper function to generate random locations
  String _generateRandomLocation(int seed) {
    final List<String> locations = [
      'Downtown Sports Complex',
      'Recreation Center East',
      'Community Sports Hub',
      'Elite Sports & Entertainment',
      'Central Venue Plaza',
      'Riverside Sports Center',
      'Metro Sports Zone',
    ];

    return locations[seed % locations.length];
  }

  // Helper function to generate random availability
  Map<String, List<String>> _generateRandomAvailability(int seed) {
    final Map<String, List<String>> availability = {};
    final List<String> days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final List<String> timeSlots = ['Morning', 'Afternoon', 'Evening', 'Night'];

    // Generate 2-4 days of availability
    final numDays = 2 + (seed % 3);
    final selectedDayIndices = List.generate(days.length, (index) => index)
      ..shuffle();

    for (int i = 0; i < numDays; i++) {
      final dayIndex = selectedDayIndices[i];
      final day = days[dayIndex];

      // For each day, pick 1-2 time slots
      final numTimeSlots = 1 + (seed + i) % 2;
      final selectedTimeIndices =
          List.generate(timeSlots.length, (index) => index)..shuffle();
      final dayTimeSlots = <String>[];

      for (int j = 0; j < numTimeSlots; j++) {
        dayTimeSlots.add(timeSlots[selectedTimeIndices[j]]);
      }

      availability[day] = dayTimeSlots;
    }

    return availability;
  }

  // Helper function to generate random achievements
  List<String>? _generateRandomAchievements(int seed) {
    if (seed % 4 == 0) {
      // Some players have no achievements yet
      return [];
    }

    final List<String> allAchievements = [
      'League Champion 2024',
      'Perfect Break',
      '5 Game Winning Streak',
      'Local Tournament Finalist',
      'Most Improved Player',
      'Century Break',
      'Maximum Break',
      'Bank Shot Master',
      'Comeback King',
      'Table Runner',
    ];

    final List<String> selectedAchievements = [];
    final achievementCount = seed % 4; // 0-3 achievements

    for (int i = 0; i < achievementCount; i++) {
      final achievement = allAchievements[(seed + i) % allAchievements.length];
      if (!selectedAchievements.contains(achievement)) {
        selectedAchievements.add(achievement);
      }
    }

    return selectedAchievements;
  }
}
