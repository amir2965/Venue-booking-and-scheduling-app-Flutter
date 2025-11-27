// This service class is responsible for notifying when profiles are updated
// It can be used by the profile setup screen to ensure navigation works correctly

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';

/// A notification service for profile updates
/// This ensures that UI components are properly notified when a profile changes
final profileUpdateNotifierProvider =
    Provider((ref) => ProfileUpdateNotifier(ref));

class ProfileUpdateNotifier {
  final Ref _ref;

  ProfileUpdateNotifier(this._ref);

  /// Notify that a profile has been updated for the given user ID
  void notifyProfileUpdated(String userId) {
    debugPrint('ProfileUpdateNotifier: Profile updated for user $userId');

    // Force invalidation of all profile-related providers
    _ref.invalidate(hasCompletedProfileSetupProvider);
    _ref.invalidate(currentUserProfileProvider);

    // Force refresh of the profile status
    _ref.refresh(hasCompletedProfileSetupProvider);

    debugPrint('ProfileUpdateNotifier: Providers refreshed for user $userId');
  }
}
