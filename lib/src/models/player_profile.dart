import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:billiards_hub/src/models/user.dart';

class PlayerProfile {
  static const int _baseXP = 1000;
  static const double _xpMultiplier = 1.5;

  static const List<String> availableCities = [
    'Sydney',
    'Melbourne',
    'Brisbane',
    'Perth',
    'Adelaide',
    'Gold Coast',
    'Newcastle',
    'Canberra'
  ];

  static const Map<String, List<String>> availabilityOptions = {
    'Monday': ['Morning', 'Afternoon', 'Evening', 'Available'],
    'Tuesday': ['Morning', 'Afternoon', 'Evening', 'Available'],
    'Wednesday': ['Morning', 'Afternoon', 'Evening', 'Available'],
    'Thursday': ['Morning', 'Afternoon', 'Evening', 'Available'],
    'Friday': ['Morning', 'Afternoon', 'Evening', 'Available'],
    'Saturday': ['Morning', 'Afternoon', 'Evening', 'Available'],
    'Sunday': ['Morning', 'Afternoon', 'Evening', 'Available'],
  };

  final User user;
  final String firstName;
  final String lastName;
  final String username;
  final String bio;
  final double skillLevel;
  final String skillTier;
  final List<String>
      preferredGameTypes; // Play modes: Just for Fun, Competitive, etc.
  final List<String>
      preferredSports; // Sports: Bowling, Billiards, Snooker, etc.
  final String? preferredLocation;
  final String? profileImageUrl;
  final Map<String, String>? profileImageUrls; // Multiple image sizes
  final Map<String, List<String>> availability;
  final int experiencePoints;
  final int matchesPlayed;
  final double winRate;
  final List<String> achievements;
  final DateTime? dateOfBirth;

  const PlayerProfile({
    required this.user,
    required this.firstName,
    required this.lastName,
    this.username = '',
    required this.bio,
    required this.skillLevel,
    required this.skillTier,
    required this.preferredGameTypes,
    this.preferredSports = const [],
    this.preferredLocation,
    this.profileImageUrl,
    this.profileImageUrls,
    required this.availability,
    this.experiencePoints = 0,
    this.matchesPlayed = 0,
    this.winRate = 0.0,
    this.achievements = const [],
    this.dateOfBirth,
  });

  int get level {
    int currentLevel = 1;
    int remainingXP = experiencePoints;

    while (remainingXP >= _getXPForLevel(currentLevel)) {
      remainingXP -= _getXPForLevel(currentLevel);
      currentLevel++;
    }

    return currentLevel;
  }

  double get levelProgressPercentage {
    int currentLevel = level;
    int xpForCurrentLevel = _getXPForLevel(currentLevel - 1);
    int xpForNextLevel = _getXPForLevel(currentLevel);
    int xpNeededForNextLevel = xpForNextLevel - xpForCurrentLevel;
    int xpInCurrentLevel = experiencePoints - xpForCurrentLevel;

    return (xpInCurrentLevel / xpNeededForNextLevel * 100).clamp(0.0, 100.0);
  }

  int _getXPForLevel(int targetLevel) {
    return (_baseXP * math.pow(_xpMultiplier, targetLevel)).round();
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'bio': bio,
      'skillLevel': skillLevel,
      'skillTier': skillTier,
      'preferredGameTypes': preferredGameTypes,
      'preferredSports': preferredSports,
      'preferredLocation': preferredLocation,
      'profileImageUrl': profileImageUrl,
      'profileImageUrls': profileImageUrls,
      'availability': availability,
      'experiencePoints': experiencePoints,
      'matchesPlayed': matchesPlayed,
      'winRate': winRate,
      'achievements': achievements,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
    };
  }

  factory PlayerProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('Cannot create PlayerProfile from null JSON');
    }

    try {
      if (kDebugMode) {
        print('🔍 Parsing PlayerProfile from JSON...');
        print('📋 Available JSON keys: ${json.keys.toList()}');
      }

      Map<String, List<String>> parseAvailability(dynamic availabilityData) {
        if (availabilityData == null) {
          return {};
        }

        if (availabilityData is Map<String, dynamic>) {
          return availabilityData.map((key, value) {
            if (value is List) {
              return MapEntry(key, value.map((e) => e.toString()).toList());
            }
            return MapEntry(key, []);
          });
        }

        return {};
      }

      List<String> parseStringList(dynamic list) {
        if (list == null) return [];
        if (list is List) {
          return list.map((e) => e.toString()).toList();
        }
        return [];
      }

      final Map<String, dynamic> userData =
          json['user'] as Map<String, dynamic>? ?? {};

      if (kDebugMode) {
        print('👤 User data keys: ${userData.keys.toList()}');
        print(
            '🎯 Key fields - firstName: ${json['firstName']}, skillLevel: ${json['skillLevel']}, gameTypes: ${json['preferredGameTypes']}');
      }

      final profile = PlayerProfile(
        user: User.fromJson(userData),
        firstName: json['firstName']?.toString() ?? 'Unknown',
        lastName: json['lastName']?.toString() ?? '', // Handle missing lastName
        username: json['username']?.toString() ?? '',
        bio: json['bio']?.toString() ?? '',
        skillLevel: (json['skillLevel'] as num?)?.toDouble() ?? 0.0,
        skillTier: json['skillTier']?.toString() ?? 'Beginner',
        preferredGameTypes: parseStringList(json['preferredGameTypes']),
        preferredSports: parseStringList(json['preferredSports']),
        preferredLocation: json['preferredLocation']?.toString(),
        profileImageUrl: json['profileImageUrl']?.toString(),
        profileImageUrls: json['profileImageUrls'] != null
            ? Map<String, String>.from(json['profileImageUrls'])
            : null,
        availability: parseAvailability(json['availability']),
        experiencePoints: (json['experiencePoints'] as num?)?.toInt() ?? 0,
        matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
        winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
        achievements: parseStringList(json['achievements']),
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.parse(json['dateOfBirth'])
            : null,
      );

      if (kDebugMode) {
        print('✅ Successfully parsed PlayerProfile for: ${profile.firstName}');
      }

      return profile;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error parsing PlayerProfile JSON: $e');
        print('📍 StackTrace: $stackTrace');
        print('📄 Full JSON: $json');
      }
      rethrow;
    }
  }

  PlayerProfile copyWith({
    User? user,
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    double? skillLevel,
    String? skillTier,
    List<String>? preferredGameTypes,
    List<String>? preferredSports,
    String? preferredLocation,
    String? profileImageUrl,
    Map<String, String>? profileImageUrls,
    Map<String, List<String>>? availability,
    int? experiencePoints,
    int? matchesPlayed,
    double? winRate,
    List<String>? achievements,
    DateTime? dateOfBirth,
  }) {
    return PlayerProfile(
      user: user ?? this.user,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      skillLevel: skillLevel ?? this.skillLevel,
      skillTier: skillTier ?? this.skillTier,
      preferredGameTypes: preferredGameTypes ?? this.preferredGameTypes,
      preferredSports: preferredSports ?? this.preferredSports,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImageUrls: profileImageUrls ?? this.profileImageUrls,
      availability: availability ?? this.availability,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      winRate: winRate ?? this.winRate,
      achievements: achievements ?? this.achievements,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  bool get isProfileComplete {
    // Basic profile completion - just needs first name
    // Location and availability are nice-to-have but not required
    return firstName.isNotEmpty;
  }

  // More strict completion check for advanced features
  bool get isFullyComplete {
    return firstName.isNotEmpty &&
        preferredLocation != null &&
        preferredLocation!.isNotEmpty &&
        availableCities.contains(preferredLocation) &&
        availability.isNotEmpty &&
        availability.keys.any((key) =>
            availability[key] != null &&
            availability[key]!.contains('Available'));
  }

  // Calculate age based on dateOfBirth
  int get age {
    if (dateOfBirth == null) return 0;

    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;

    // Adjust age if birthday hasn't occurred yet this year
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }

    return age;
  }

  // Check if user is 18 years or older
  bool get isAdult {
    return age >= 18;
  }

  @override
  String toString() {
    return 'PlayerProfile(firstName: $firstName, location: $preferredLocation, availability: $availability)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerProfile &&
        other.user == user &&
        other.firstName == firstName &&
        other.preferredLocation == preferredLocation &&
        other.availability == availability;
  }

  @override
  int get hashCode =>
      Object.hash(user, firstName, preferredLocation, availability);
}
