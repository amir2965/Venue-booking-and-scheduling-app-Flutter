import 'package:flutter_test/flutter_test.dart';
import 'package:billiards_hub/src/services/mongodb_local_service.dart';
import 'package:billiards_hub/src/models/player_profile.dart';
import 'package:billiards_hub/src/models/user.dart';

void main() {
  group('MongoDB Atlas Tests', () {
    late MongoDBLocalService mongoDBService;

    setUp(() async {
      mongoDBService = MongoDBLocalService();
      try {
        await mongoDBService.initialize();
      } catch (e) {
        fail('Failed to initialize MongoDB connection: $e');
      }
    });

    tearDown(() async {
      await mongoDBService.close();
    });

    test('should connect to MongoDB Atlas', () async {
      // Check if connected
      final isConnected = await mongoDBService.checkConnectivity();
      expect(isConnected, isTrue,
          reason: 'MongoDB Atlas connection should be successful');
    });

    test('should save and retrieve a player profile in Atlas', () async {
      // Create a test profile
      final testUserId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';
      final testProfile = PlayerProfile(
        user: User(
          id: testUserId,
          email: 'test@example.com',
          displayName: 'Test User',
        ),
        firstName: 'Test',
        bio: 'Test profile',
        skillLevel: 2.5,
        skillTier: 'Amateur',
        preferredGameTypes: ['8-Ball'],
        preferredLocation: 'Test Location',
        availability: {
          'Monday': ['Evening'],
          'Saturday': ['Afternoon'],
        },
        experiencePoints: 100,
        matchesPlayed: 0,
        winRate: 0.0,
        achievements: [],
      );

      // Save the profile
      final created = await mongoDBService.createProfile(testProfile);
      expect(created, isTrue, reason: 'Profile should be created successfully');

      // Retrieve the profile
      final savedProfile = await mongoDBService.getProfile(testUserId);

      // Assert profile exists and has correct data
      expect(savedProfile, isNotNull,
          reason: 'Saved profile should be retrievable');
      expect(savedProfile!.user.id, equals(testUserId),
          reason: 'Profile ID should match');
      expect(savedProfile.firstName, equals('Test'),
          reason: 'First name should match');
      expect(savedProfile.skillLevel, equals(2.5),
          reason: 'Skill level should match');
      expect(savedProfile.preferredGameTypes, contains('8-Ball'),
          reason: 'Preferred game types should match');
    });

    test('should handle liked profiles in Atlas', () async {
      final testUserId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';
      final likedUserId = 'liked-user-${DateTime.now().millisecondsSinceEpoch}';

      // Create main user profile
      final testProfile = PlayerProfile(
        user: User(
          id: testUserId,
          email: 'test@example.com',
          displayName: 'Test User',
        ),
        firstName: 'Test',
        bio: 'Test profile',
        skillLevel: 2.5,
        skillTier: 'Amateur',
        preferredGameTypes: ['8-Ball'],
        preferredLocation: 'Test Location',
        availability: {},
        experiencePoints: 100,
        matchesPlayed: 0,
        winRate: 0.0,
        achievements: [],
      );

      // Create a profile to be liked
      final likedProfile = PlayerProfile(
        user: User(
          id: likedUserId,
          email: 'liked@example.com',
          displayName: 'Liked User',
        ),
        firstName: 'Liked',
        bio: 'Profile to be liked',
        skillLevel: 3.0,
        skillTier: 'Intermediate',
        preferredGameTypes: ['8-Ball'],
        preferredLocation: 'Another Location',
        availability: {},
        experiencePoints: 200,
        matchesPlayed: 5,
        winRate: 0.6,
        achievements: [],
      );

      // Save both profiles
      await mongoDBService.createProfile(testProfile);
      await mongoDBService.createProfile(likedProfile);

      // Add liked profile
      final liked =
          await mongoDBService.addLikedProfile(testUserId, likedUserId);
      expect(liked, isTrue, reason: 'Should successfully like a profile');

      // Get liked profiles
      final likedProfiles = await mongoDBService.getLikedProfiles(testUserId);
      expect(likedProfiles, isNotEmpty, reason: 'Should have liked profiles');
      expect(likedProfiles.first.user.id, equals(likedUserId),
          reason: 'Should find the liked profile');
    });

    test('should get recommended profiles', () async {
      // Create test profiles
      final testUserId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';
      final otherUserIds = List.generate(
          3, (i) => 'test-user-$i-${DateTime.now().millisecondsSinceEpoch}');

      // Create and save main user profile
      final testProfile = PlayerProfile(
        user: User(
          id: testUserId,
          email: 'test@example.com',
          displayName: 'Test User',
        ),
        firstName: 'Test',
        bio: 'Test profile',
        skillLevel: 2.5,
        skillTier: 'Amateur',
        preferredGameTypes: ['8-Ball'],
        preferredLocation: 'Test Location',
        availability: {},
        experiencePoints: 100,
        matchesPlayed: 0,
        winRate: 0.0,
        achievements: [],
      );
      await mongoDBService.createProfile(testProfile);

      // Create and save other profiles
      for (var id in otherUserIds) {
        final profile = PlayerProfile(
          user: User(
            id: id,
            email: '$id@example.com',
            displayName: 'Profile $id',
          ),
          firstName: 'Test $id',
          bio: 'Test profile $id',
          skillLevel: 2.5,
          skillTier: 'Amateur',
          preferredGameTypes: ['8-Ball'],
          preferredLocation: 'Location $id',
          availability: {},
          experiencePoints: 100,
          matchesPlayed: 0,
          winRate: 0.0,
          achievements: [],
        );
        await mongoDBService.createProfile(profile);
      }

      // Get recommended profiles for the main user
      final recommended =
          await mongoDBService.getRecommendedProfiles(testUserId);

      // Assert recommendations are retrieved
      expect(recommended, isNotEmpty,
          reason: 'Should retrieve recommended profiles');
      expect(recommended.any((p) => otherUserIds.contains(p.user.id)), isTrue,
          reason: 'Should find recommended profiles from test set');
      expect(recommended.any((p) => p.user.id == testUserId), isFalse,
          reason: 'Should not recommend the user to themselves');
    });

    test('should verify username availability', () async {
      final testUsername = 'testuser_${DateTime.now().millisecondsSinceEpoch}';

      // Test username availability
      final isAvailable =
          await mongoDBService.isUsernameAvailable(testUsername);
      expect(isAvailable, isTrue, reason: 'New username should be available');

      // Create a profile using the username
      final testUserId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';
      final testProfile = PlayerProfile(
        user: User(
          id: testUserId,
          email: 'test@example.com',
          displayName: testUsername,
        ),
        firstName: 'Test',
        bio: 'Test profile',
        skillLevel: 2.5,
        skillTier: 'Amateur',
        preferredGameTypes: ['8-Ball'],
        preferredLocation: 'Test Location',
        availability: {},
        experiencePoints: 100,
        matchesPlayed: 0,
        winRate: 0.0,
        achievements: [],
      );

      await mongoDBService.createProfile(testProfile);

      // Check that the username is no longer available
      final isStillAvailable =
          await mongoDBService.isUsernameAvailable(testUsername);
      expect(isStillAvailable, isFalse,
          reason: 'Used username should not be available');
    });
  });
}
