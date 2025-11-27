import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/player_profile.dart';
import '../services/player_profile_service_mongodb.dart';
import '../services/mongodb_service_base.dart';
import '../services/simple_username_service.dart';
import 'auth_provider.dart';
import 'username_provider.dart';
import 'mongodb_provider.dart';

// Define the MatchPreferences class to store filter preferences
class MatchPreferences {
  final List<String>? preferredGameTypes;
  final List<String>? preferredDays;
  final String? preferredLocation;
  final double? minSkillLevel;
  final double? maxSkillLevel;

  MatchPreferences({
    this.preferredGameTypes,
    this.preferredDays,
    this.preferredLocation,
    this.minSkillLevel,
    this.maxSkillLevel,
  });
}

// Provider for the player profile service
final playerProfileServiceProvider = Provider<PlayerProfileService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final mongoDBService = ref.watch(mongoDBServiceProvider);
  final usernameService = ref.watch(usernameServiceProvider);
  return PlayerProfileService(authService, mongoDBService, usernameService);
});

// Provider to get the currently logged-in user's profile
final currentUserProfileProvider = FutureProvider<PlayerProfile?>((ref) async {
  final profileService = ref.watch(playerProfileServiceProvider);
  // Use ensureUserHasProfile instead of getCurrentUserProfile to ensure a profile always exists
  try {
    return await profileService.ensureUserHasProfile();
  } catch (e) {
    debugPrint('Error ensuring user has profile: $e');
    return await profileService.getCurrentUserProfile();
  }
});

// Provider to check if the current user has completed profile setup
final hasCompletedProfileSetupProvider = FutureProvider<bool>((ref) async {
  final profileService = ref.watch(playerProfileServiceProvider);

  try {
    // Try to ensure a profile exists (creates one if it doesn't)
    final profile = await profileService.ensureUserHasProfile();

    // Debug profile completion status
    debugPrint('Profile completion check: profile=${profile != null}');

    if (profile == null) {
      debugPrint('No profile found');
      return false;
    }

    // Log profile details for debugging
    debugPrint(
        'Profile details: name=${profile.user.displayName}, location=${profile.preferredLocation}, availability=${profile.availability.isNotEmpty}');

    // More lenient completion criteria:
    // 1. Profile exists AND
    // 2. Has a display name (first name)
    // Location and availability are optional for basic profile completion
    final hasName = profile.firstName.isNotEmpty;
    final isComplete = hasName;

    debugPrint('Profile completion result: $isComplete (name: $hasName)');

    return isComplete;
  } catch (e) {
    debugPrint('Error in profile completion check: $e');

    // Fallback to original method
    final profile = await profileService.getCurrentUserProfile();
    if (profile == null) {
      debugPrint('Fallback check - no profile found');
      return false;
    }

    final hasName = profile.user.displayName?.isNotEmpty == true;
    final hasLocation = profile.preferredLocation?.isNotEmpty == true;
    final isComplete = hasName && hasLocation;
    debugPrint(
        'Fallback profile completion result: $isComplete (name: $hasName, location: $hasLocation)');
    return isComplete;
  }
});

// Provider to get potential matches for the current user
final potentialMatchesProvider =
    FutureProvider<List<PlayerProfile>>((ref) async {
  final profileService = ref.watch(playerProfileServiceProvider);

  // Get already processed profiles to exclude them
  final likedProfileObjects = await profileService.getLikedProfiles();
  final matches = await profileService.getMatches();

  // Extract user IDs from the liked profile objects and convert to List<String>
  final likedIds = likedProfileObjects.map((p) => p.user.id).toList();
  // Convert matches to List<String> explicitly
  final List<String> matchIds = matches.map((m) => m.toString()).toList();

  // Combine both lists to exclude
  final List<String> excludeIds = [...likedIds, ...matchIds];

  return await profileService.getPotentialMatches(excludeIds: excludeIds);
});

// Provider to get the current user's matches
final userMatchesProvider = FutureProvider<List<PlayerProfile>>((ref) async {
  final profileService = ref.watch(playerProfileServiceProvider);
  final matchIds = await profileService.getMatches();

  List<PlayerProfile> matchedProfiles = [];
  for (final id in matchIds) {
    final profile = await profileService.getProfileById(id);
    if (profile != null) {
      matchedProfiles.add(profile);
    }
  }

  return matchedProfiles;
});

// Provider for liked profiles
final likedProfilesProvider = StateProvider<List<PlayerProfile>>((ref) => []);

// Provider for disliked profiles
final dislikedProfilesProvider =
    StateProvider<List<PlayerProfile>>((ref) => []);

// Provider for match preferences
final matchPreferencesProvider =
    StateProvider<MatchPreferences>((ref) => MatchPreferences(
          minSkillLevel: 1.0,
          maxSkillLevel: 5.0,
        ));

// Provider for filtering potential matches based on criteria
final filteredMatchesProvider = Provider<List<PlayerProfile>>((ref) {
  final potentialMatchesAsync = ref.watch(potentialMatchesProvider);

  return potentialMatchesAsync.when(
    data: (matches) {
      // Apply any additional filtering logic here
      return matches;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for filtering potential matches based on user preferences
final filteredPotentialMatchesProvider = Provider<List<PlayerProfile>>((ref) {
  final potentialMatchesAsync = ref.watch(potentialMatchesProvider);
  final preferences = ref.watch(matchPreferencesProvider);
  final likedProfiles = ref.watch(likedProfilesProvider);
  final dislikedProfiles = ref.watch(dislikedProfilesProvider);

  return potentialMatchesAsync.when(
    data: (matches) {
      // Filter out profiles that have already been processed
      matches = matches
          .where((profile) =>
              !likedProfiles.contains(profile.user.id) &&
              !dislikedProfiles.contains(profile.user.id))
          .toList();

      // Apply filter based on preferences
      if (preferences.preferredGameTypes != null &&
          preferences.preferredGameTypes!.isNotEmpty) {
        matches = matches
            .where((profile) => profile.preferredGameTypes
                .any((game) => preferences.preferredGameTypes!.contains(game)))
            .toList();
      }

      if (preferences.preferredDays != null &&
          preferences.preferredDays!.isNotEmpty) {
        matches = matches
            .where((profile) => profile.availability.keys
                .any((day) => preferences.preferredDays!.contains(day)))
            .toList();
      }

      if (preferences.preferredLocation != null) {
        matches = matches
            .where((profile) =>
                profile.preferredLocation == preferences.preferredLocation)
            .toList();
      }

      if (preferences.minSkillLevel != null) {
        matches = matches
            .where(
                (profile) => profile.skillLevel >= preferences.minSkillLevel!)
            .toList();
      }

      if (preferences.maxSkillLevel != null) {
        matches = matches
            .where(
                (profile) => profile.skillLevel <= preferences.maxSkillLevel!)
            .toList();
      }

      return matches;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
