import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';
import '../utils/navigation_fixer.dart';

/// A widget extension to add to the profile setup screen
/// This adds a debug button to test and verify navigation
class ProfileNavigationDebugHelper extends ConsumerWidget {
  const ProfileNavigationDebugHelper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Colors.amber.shade100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Navigation Troubleshooter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(hasCompletedProfileSetupProvider);
                      ref.invalidate(currentUserProfileProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Providers refreshed')),
                      );
                    },
                    child: const Text('Refresh Providers'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      NavigationFixer.navigateToHomeAfterProfileUpdate(
                          context, ref);
                    },
                    child: const Text('Test Navigation'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
