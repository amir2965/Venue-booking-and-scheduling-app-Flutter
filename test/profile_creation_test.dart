import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:billiards_hub/src/models/user.dart';
import 'package:billiards_hub/src/services/auth_service.dart';
import 'package:billiards_hub/src/services/firestore_service.dart';
import 'package:billiards_hub/src/services/simple_username_service.dart';
import 'package:billiards_hub/src/services/player_profile_service_firebase.dart';

@GenerateMocks([AuthService, FirestoreService, UsernameService])
void main() {
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

  test('getCurrentUserProfile should create a new profile if none exists',
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

    // Verify that a new profile was saved to Firestore
    verify(mockFirestoreService.savePlayerProfile('test-user-id', any))
        .called(1);
  });

  test('getCurrentUserProfile should return existing profile if one exists',
      () async {
    // Arrange
    final testUser = User(
      id: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
    );

    final existingProfileData = {
      'user': testUser.toJson(),
      'firstName': 'Existing',
      'bio': 'Existing bio',
      'skillLevel': 2.5,
      'skillTier': 'Intermediate',
      'preferredGameTypes': ['8-Ball', '9-Ball'],
      'availability': {
        'Monday': ['Evening']
      },
      'experiencePoints': 100,
      'matchesPlayed': 5,
      'winRate': 0.8,
      'achievements': ['First Game'],
      'preferredLocation': 'Local Pool Hall',
    };

    // Setup mocks
    when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
    when(mockFirestoreService.getPlayerProfile('test-user-id'))
        .thenAnswer((_) async => existingProfileData);

    // Act
    final profile = await profileService.getCurrentUserProfile();

    // Assert
    expect(profile, isNotNull);
    expect(profile!.user.id, equals('test-user-id'));
    expect(profile.firstName, equals('Existing'));
    expect(profile.skillLevel, equals(2.5));
    expect(profile.skillTier, equals('Intermediate'));

    // Verify that we didn't try to save a new profile
    verifyNever(mockFirestoreService.savePlayerProfile(any, any));
  });
}
