import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:billiards_hub/src/providers/player_provider.dart';
import 'package:billiards_hub/src/models/user.dart';
import 'package:billiards_hub/src/services/player_profile_service.dart';
import 'package:mockito/mockito.dart';

class MockPlayerProfileService extends Mock implements PlayerProfileService {}

void main() {
  test('hasCompletedProfileSetupProvider returns false for new users',
      () async {
    final container = ProviderContainer();

    // Verify hasCompletedProfileSetupProvider returns false for a new profile
    final hasCompletedProfile =
        await container.read(hasCompletedProfileSetupProvider.future);

    // Since we modified PlayerProfileService to create profiles with empty location
    // and availability for new users, this should return false
    expect(hasCompletedProfile, false);
  });
}
