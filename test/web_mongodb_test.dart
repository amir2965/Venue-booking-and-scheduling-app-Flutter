import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:billiards_hub/src/services/web_mongodb_service.dart';
import 'package:billiards_hub/src/models/player_profile.dart';
import 'package:billiards_hub/src/models/user.dart';

void main() {
  // Initialize Flutter binding for SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebMongoDBService Tests', () {
    late WebMongoDBService mongoDBService;

    setUp(() {
      mongoDBService = WebMongoDBService();
    });

    test('should initialize and check connectivity', () async {
      // Initialize web storage
      await mongoDBService.initialize();

      // Check if connected
      final isConnected = await mongoDBService.checkConnectivity();

      // Assert
      expect(isConnected, isTrue);
    });

    test('should create and retrieve a player profile', () async {
      // Initialize web storage
      await mongoDBService.initialize();

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

      // Create the profile
      final created = await mongoDBService.createProfile(testProfile);
      expect(created, isTrue, reason: 'Profile should be created successfully');

      // Retrieve the profile
      final savedProfile = await mongoDBService.getProfile(testUserId);

      // Assert profile data
      expect(savedProfile, isNotNull);
      expect(savedProfile!.user.id, equals(testUserId));
      expect(savedProfile.firstName, equals('Test'));
      expect(savedProfile.skillLevel, equals(2.5));
      expect(savedProfile.preferredGameTypes, contains('8-Ball'));
    });

    test('should handle liked profiles', () async {
      // Initialize web storage
      await mongoDBService.initialize();

      final testUserId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';
      final likedUserId = 'liked-user-${DateTime.now().millisecondsSinceEpoch}';

      // Create profiles
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
        preferredGameTypes: ['9-Ball'],
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

      // Like profile
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
      // Initialize web storage
      await mongoDBService.initialize();

      final testUserId = 'test-user-${DateTime.now().millisecondsSinceEpoch}';

      // Create test profile
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

      // Get recommendations
      final recommendations =
          await mongoDBService.getRecommendedProfiles(testUserId);

      // We can't assert much since recommendations depend on server data
      // but we can at least ensure the user doesn't get recommended to themselves
      for (var profile in recommendations) {
        expect(profile.user.id, isNot(equals(testUserId)));
      }
    });

    tearDown(() async {
      await mongoDBService.close();
    });
  });
}
