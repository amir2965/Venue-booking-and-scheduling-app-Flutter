// This file contains a utility function to test the profile navigation fix
// It can be used in the app to manually trigger the navigation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../providers/player_provider.dart';

/// Test class to verify navigation works correctly
class NavigationTest {
  /// Test function that performs the same navigation logic as the profile setup screen
  static void testHomeNavigation(BuildContext context, WidgetRef ref) {
    debugPrint('NavigationTest: Testing navigation to home screen');

    // Invalidate providers to force refresh
    ref.invalidate(hasCompletedProfileSetupProvider);
    ref.invalidate(currentUserProfileProvider);

    // Force an immediate refresh (async)
    ref.refresh(hasCompletedProfileSetupProvider);

    // Show debug info
    debugPrint(
        'NavigationTest: Current route: ${GoRouterState.of(context).matchedLocation}');

    // Add a small delay for state propagation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        try {
          // Use primary navigation method
          debugPrint('NavigationTest: Navigating with go_router');
          context.go('/home');

          // Add a fallback with slight delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              final route = ModalRoute.of(context);
              debugPrint(
                  'NavigationTest: Current route after delay: ${route?.settings.name}');

              if (route?.settings.name != '/home') {
                debugPrint(
                    'NavigationTest: Using fallback Navigator.pushAndRemoveUntil');
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            }
          });
        } catch (e) {
          debugPrint('NavigationTest: Error during navigation: $e');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      }
    });
  }
}
