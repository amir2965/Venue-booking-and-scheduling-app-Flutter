// This file provides a comprehensive solution for the navigation issue in the app
// It can be used throughout the app to ensure reliable navigation after profile changes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';

/// A utility class that provides a comprehensive solution to navigation issues
/// This fixes problems with navigation when profiles are created or updated
class NavigationFixer {
  /// Navigate to the home screen with fallback mechanisms to ensure reliability
  static void navigateToHomeAfterProfileUpdate(
      BuildContext context, WidgetRef ref) {
    debugPrint('NavigationFixer: Attempting to navigate to home screen');

    // Step 1: Force provider refresh
    ref.invalidate(hasCompletedProfileSetupProvider);
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(authUserProvider);

    // Step 2: Trigger immediate refresh of profile status
    ref.refresh(hasCompletedProfileSetupProvider);

    // Step 3: Ensure the route has time to update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      debugPrint('NavigationFixer: Post-frame callback - ready to navigate');
      _executeNavigationWithRetry(context);
    });
  }

  /// Internal method for executing navigation with retry
  static void _executeNavigationWithRetry(BuildContext context) {
    try {
      // First attempt: use go_router
      debugPrint('NavigationFixer: Attempting go_router navigation');
      context.go('/home');

      // Set up fallback options
      _setupFallbackNavigation(context);
    } catch (e) {
      debugPrint('NavigationFixer: Primary navigation failed - $e');
      _useFallbackNavigation(context);
    }
  }

  /// Set up fallback navigation to run after a delay
  static void _setupFallbackNavigation(BuildContext context) {
    // Fallback with delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!context.mounted) return;

      final currentRoute = GoRouterState.of(context).matchedLocation;
      debugPrint('NavigationFixer: Current route after delay: $currentRoute');

      if (currentRoute != '/home') {
        debugPrint('NavigationFixer: Route not updated, using fallback');
        _useFallbackNavigation(context);
      } else {
        debugPrint('NavigationFixer: Successfully navigated to home screen');
      }
    });
  }

  /// Direct navigation fallback using Navigator API
  static void _useFallbackNavigation(BuildContext context) {
    if (!context.mounted) return;

    debugPrint('NavigationFixer: Using direct Navigator API fallback');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false, // Remove all previous routes
    );

    debugPrint('NavigationFixer: Fallback navigation complete');
  }
}
