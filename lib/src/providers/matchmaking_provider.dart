import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_profile.dart';
import '../models/match_result.dart';
import '../models/matchmaking_stats.dart';
import '../services/matchmaking_service.dart';
import '../services/notification_service.dart';
import '../services/notification_monitor_service.dart';
import 'matchmaking_filters_provider.dart';
import 'notification_provider.dart';

// Matchmaking service provider
final matchmakingServiceProvider = Provider<MatchmakingService>((ref) {
  return MatchmakingService();
});

// Current potential matches provider
final potentialMatchesProvider = StateNotifierProvider<PotentialMatchesNotifier,
    AsyncValue<List<PlayerProfile>>>((ref) {
  final service = ref.watch(matchmakingServiceProvider);
  return PotentialMatchesNotifier(service, ref);
});

// User's matches provider
final userMatchesProvider =
    StateNotifierProvider<UserMatchesNotifier, AsyncValue<List<PlayerProfile>>>(
        (ref) {
  final service = ref.watch(matchmakingServiceProvider);
  return UserMatchesNotifier(service);
});

// Matchmaking stats provider
final matchmakingStatsProvider = StateNotifierProvider<MatchmakingStatsNotifier,
    AsyncValue<MatchmakingStats>>((ref) {
  final service = ref.watch(matchmakingServiceProvider);
  return MatchmakingStatsNotifier(service);
});

// Current swipe index provider
final currentSwipeIndexProvider = StateProvider<int>((ref) => 0);

// Match result provider for showing match animations
final matchResultProvider = StateProvider<MatchResult?>((ref) => null);

class PotentialMatchesNotifier
    extends StateNotifier<AsyncValue<List<PlayerProfile>>> {
  final MatchmakingService _service;
  final Ref _ref;

  PotentialMatchesNotifier(this._service, this._ref)
      : super(const AsyncValue.data([]));

  Future<void> loadPotentialMatches(String userId,
      {bool forceRefresh = false}) async {
    // If force refresh is requested, clear any cached state first
    if (forceRefresh) {
      state = const AsyncValue.loading();
    } else {
      // Only show loading if we don't have data or if we're in error state
      state.when(
        data: (data) {
          // Keep existing data while loading new data
          if (data.isEmpty) {
            state = const AsyncValue.loading();
          }
        },
        loading: () {
          // Already loading, no need to change
        },
        error: (error, stackTrace) {
          // Clear error state and show loading
          state = const AsyncValue.loading();
        },
      );
    }

    try {
      print('🔍 Loading potential matches for user: $userId');
      final matches = await _service.getPotentialMatches(userId);
      print('📦 Received ${matches.length} potential matches from server');

      // Get current filters
      final filters = _ref.read(matchmakingFiltersProvider);

      // Apply filters
      final filteredMatches = matches.where((profile) {
        // This is a simplified filter implementation - in a real app,
        // you would need more robust logic and access to more properties

        // Filter by play modes - check if profiles have matching play modes
        if (filters.playModes.isNotEmpty &&
            !profile.preferredGameTypes
                .any((mode) => filters.playModes.contains(mode))) {
          return false;
        }

        // Filter by age if dateOfBirth is available
        if (profile.dateOfBirth != null) {
          final age = profile.age;
          if (age < filters.ageRange.start || age > filters.ageRange.end) {
            return false;
          }
        }

        // Filter by game types
        if (filters.gameTypes.isNotEmpty &&
            !profile.preferredGameTypes
                .any((type) => filters.gameTypes.contains(type))) {
          return false;
        }

        // For other filters like age, distance and online status,
        // you'd need additional data in the profile model

        return true;
      }).toList();

      print('✅ Applied filters, showing ${filteredMatches.length} matches');
      state = AsyncValue.data(filteredMatches);
    } catch (error, stackTrace) {
      print('❌ Error loading potential matches: $error');
      print('📍 StackTrace: $stackTrace');

      // Provide more detailed error information
      String errorMessage = 'Failed to load matches';
      if (error.toString().contains('Failed to host lookup')) {
        errorMessage =
            'Network connection error. Please check your internet connection.';
      } else if (error.toString().contains('500')) {
        errorMessage = 'Server error. Please try again in a moment.';
      } else if (error.toString().contains('404')) {
        errorMessage =
            'Matchmaking service unavailable. Please try again later.';
      }

      state = AsyncValue.error(errorMessage, stackTrace);
    }
  }

  Future<MatchResult> recordAction(
      String userId, String targetUserId, MatchAction action) async {
    try {
      print('🎯 Recording action: $action for user $userId -> $targetUserId');
      final result = await _service.recordAction(userId, targetUserId, action);

      // If it's a match, create notifications for both users
      if (result.isMatch && action == MatchAction.like) {
        print('🎉 Match detected! Creating notifications...');
        // Get user profiles to get names for notifications
        final currentUserProfile = await _getUserProfile(userId);
        final targetUserProfile = await _getUserProfile(targetUserId);

        if (currentUserProfile != null && targetUserProfile != null) {
          try {
            // Create notifications using the notification provider
            final notificationNotifier =
                _ref.read(notificationsProvider.notifier);
            await notificationNotifier.createMatchNotifications(
              firstUserId: targetUserId, // The user who liked first
              secondUserId: userId, // The user who just liked back
              firstUserName: targetUserProfile.firstName,
              secondUserName: currentUserProfile.firstName,
            );

            // Show in-app notification to current user immediately
            _ref.read(inAppNotificationProvider.notifier).state =
                NotificationModel(
              id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
              userId: userId,
              type: 'match',
              relatedUserId: targetUserId,
              message:
                  'It\'s a match! You and ${targetUserProfile.firstName} liked each other!',
              isRead: false,
              createdAt: DateTime.now(),
            );

            // Force notification check for all users to ensure real-time delivery
            // This will help User A (who liked first) get the notification immediately
            // Add a small delay to ensure backend has processed the notifications
            Future.delayed(const Duration(milliseconds: 500), () {
              final notificationMonitor =
                  _ref.read(notificationMonitorProvider);
              notificationMonitor.checkNow();
            });
          } catch (notificationError) {
            print('⚠️ Failed to create notifications: $notificationError');
            // Don't fail the entire action if notifications fail
          }
        }
      }

      // Only update state if we're currently showing data (not in error state)
      state.whenData((profiles) {
        final updatedProfiles =
            profiles.where((p) => p.user.id != targetUserId).toList();
        print('👥 Updated local matches: ${updatedProfiles.length} remaining');
        state = AsyncValue.data(updatedProfiles);
      });

      return result;
    } catch (error) {
      print('❌ Error recording action: $error');
      // Don't update the state on action error - keep existing matches visible
      rethrow;
    }
  }

  // Helper method to get user profile
  Future<PlayerProfile?> _getUserProfile(String userId) async {
    try {
      // This would typically come from a user profile service
      // For now, we'll look in the current potential matches or return null
      final currentMatches = state.value ?? [];
      return currentMatches.firstWhere(
        (profile) => profile.user.id == userId,
        orElse: () => throw StateError('Profile not found'),
      );
    } catch (e) {
      // Profile not in current matches, would need to fetch from service
      print('Could not find user profile for $userId');
      return null;
    }
  }

  void removeCurrentProfile(String profileId) {
    state.whenData((profiles) {
      final updatedProfiles =
          profiles.where((p) => p.user.id != profileId).toList();
      state = AsyncValue.data(updatedProfiles);
    });
  }

  Future<void> refresh(String userId) async {
    print('🔄 Force refreshing potential matches for user: $userId');
    await loadPotentialMatches(userId, forceRefresh: true);
  }

  // Add method to clear error state and retry
  void clearErrorAndRetry(String userId) {
    print('🧹 Clearing error state and retrying for user: $userId');
    state = const AsyncValue.loading();
    loadPotentialMatches(userId, forceRefresh: true);
  }
}

class UserMatchesNotifier
    extends StateNotifier<AsyncValue<List<PlayerProfile>>> {
  final MatchmakingService _service;

  UserMatchesNotifier(this._service) : super(const AsyncValue.data([]));

  Future<void> loadUserMatches(String userId) async {
    state = const AsyncValue.loading();
    try {
      final matches = await _service.getUserMatches(userId);
      state = AsyncValue.data(matches);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh(String userId) async {
    await loadUserMatches(userId);
  }
}

class MatchmakingStatsNotifier
    extends StateNotifier<AsyncValue<MatchmakingStats>> {
  final MatchmakingService _service;

  MatchmakingStatsNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> loadStats(String userId) async {
    state = const AsyncValue.loading();
    try {
      final stats = await _service.getMatchmakingStats(userId);
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh(String userId) async {
    await loadStats(userId);
  }
}
