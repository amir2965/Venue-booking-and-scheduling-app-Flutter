import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:billiards_hub/src/models/user.dart';
import 'package:billiards_hub/src/services/auth_service.dart';
import 'package:billiards_hub/src/services/firestore_service.dart';
import 'package:billiards_hub/src/services/simple_username_service.dart';
import 'package:billiards_hub/src/services/player_profile_service_firebase.dart';
import 'package:billiards_hub/src/services/mongodb_local_service.dart';
import 'package:billiards_hub/src/services/username_service.dart';
import 'package:billiards_hub/src/services/player_profile_service_mongodb.dart';

// Generate mocks for all required services
@GenerateMocks(
    [AuthService, FirestoreService, UsernameService, MongoDBLocalService])
void main() {
  group('Firebase Profile Service Tests', () {
    late MockAuthService mockAuthService;
    late MockFirestoreService mockFirestoreService;
    late MockUsernameService mockUsernameService;
    late PlayerProfileService profileService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockFirestoreService = MockFirestoreService();
      mockUsernameService = MockUsernameService();
      profileService = PlayerProfileService(
        mockAuthService,
        mockFirestoreService,
        mockUsernameService,
      );
    });

    test(
        'getCurrentUserProfile should create a new profile if none exists in Firestore',
        () async {
      // Arrange
      final testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      // Setup mocks
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
      when(mockFirestoreService.getPlayerProfile('test-user-id'))
          .thenAnswer((_) async => null);
      when(mockFirestoreService.savePlayerProfile(any, any))
          .thenAnswer((_) async => true);

      // Act
      final profile = await profileService.getCurrentUserProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile!.user.id, equals('test-user-id'));
      expect(profile.firstName, equals('Test'));
      expect(profile.skillLevel, equals(1.0));
      expect(profile.skillTier, equals('Novice'));

      // Verify that profile was saved to Firestore
      verify(mockFirestoreService.savePlayerProfile('test-user-id', any))
          .called(1);
    });

    test('getCurrentUserProfile should handle null displayName', () async {
      // Arrange
      final testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: null, // Testing with null displayName
      );

      // Setup mocks
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
      when(mockFirestoreService.getPlayerProfile('test-user-id'))
          .thenAnswer((_) async => null);
      when(mockFirestoreService.savePlayerProfile(any, any))
          .thenAnswer((_) async => true);

      // Act
      final profile = await profileService.getCurrentUserProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile!.user.id, equals('test-user-id'));
      expect(profile.firstName, equals('')); // Should default to empty string
      expect(profile.skillLevel, equals(1.0));

      // Verify save was called
      verify(mockFirestoreService.savePlayerProfile('test-user-id', any))
          .called(1);
    });
  });

  group('MongoDB Profile Service Tests', () {
    late MockAuthService mockAuthService;
    late MockMongoDBService mockMongoDBService;
    late MockUsernameService mockUsernameService;
    late PlayerProfileService mongoProfileService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockMongoDBService = MockMongoDBService();
      mockUsernameService = MockUsernameService();
      mongoProfileService = PlayerProfileService(
        mockAuthService,
        mockMongoDBService,
        mockUsernameService,
      );
    });

    test(
        'getCurrentUserProfile should create a new profile if none exists in MongoDB',
        () async {
      // Arrange
      final testUser = User(
        id: 'test-mongo-id',
        email: 'mongo@example.com',
        displayName: 'Mongo User',
      );

      // Setup mocks
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
      when(mockMongoDBService.checkConnectivity())
          .thenAnswer((_) async => true);
      when(mockMongoDBService.getPlayerProfile('test-mongo-id'))
          .thenAnswer((_) async => null);
      when(mockMongoDBService.savePlayerProfile(any, any))
          .thenAnswer((_) async => true);

      // Act
      final profile = await mongoProfileService.getCurrentUserProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile!.user.id, equals('test-mongo-id'));
      expect(profile.firstName, equals('Mongo'));
      expect(profile.skillLevel, equals(1.0));

      // Verify that the profile was saved to MongoDB
      verify(mockMongoDBService.savePlayerProfile('test-mongo-id', any))
          .called(1);
    });
  });
}
