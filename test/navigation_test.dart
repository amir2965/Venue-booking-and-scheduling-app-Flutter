import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:billiards_hub/src/app.dart';
import 'package:billiards_hub/src/screens/auth/profile_setup_screen.dart';
import 'package:billiards_hub/src/screens/home_screen.dart';
import 'package:billiards_hub/src/services/profile_navigation_fixer.dart';
import 'package:billiards_hub/src/providers/player_provider.dart';

void main() {
  testWidgets('Test navigation after profile setup',
      (WidgetTester tester) async {
    // Build our widget with required providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Mock required providers here if needed
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Test the navigation fixer
                    final ref = ProviderScope.containerOf(context);
                    ProfileNavigationFixer.navigateToHomeScreen(context, ref);
                  },
                  child: const Text('Test Navigation'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Verify the button is there
    expect(find.text('Test Navigation'), findsOneWidget);

    // Tap the button
    await tester.tap(find.text('Test Navigation'));
    await tester.pumpAndSettle();

    // Expect to see the home screen content
    // This test will fail if navigation doesn't work properly
    // You'll need to adapt this based on what's visible in your HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
