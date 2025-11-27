import 'dart:convert';
import 'dart:io';

import 'lib/src/models/player_profile.dart';

void main() async {
  try {
    print('🧪 Testing fixed PlayerProfile parsing...');

    // Test data similar to what we found in the API
    final testProfiles = [
      // Profile with missing lastName
      {
        'user': {
          'id': '33qfB6RLqPeG0SiO0z7Wmcsgx542',
          'email': 'amir2965yyyy@yahoo.com',
          'displayName': 'Daryosh farzaii',
          'photoUrl': null,
          'emailVerified': false,
          'createdAt': '2025-07-05T05:35:24.000Z'
        },
        'firstName': 'Daryosh',
        // lastName is missing
        'username': 'kingmode1',
        'bio':
            'Looking forward to connecting with fellow billiards enthusiasts!',
        'skillLevel': 5,
        'skillTier': 'Pro',
        'preferredGameTypes': ['8-ball', '9-ball'],
        'preferredLocation': 'Brisbane',
        'experiencePoints': 10,
        'matchesPlayed': 0,
        'winRate': 0,
        'achievements': []
      },
      // Profile with missing email
      {
        'user': {
          'id': 'chat_test_user_1752152794043_1'
          // email is missing
        },
        'firstName': 'ChatUser1',
        'lastName': 'Test',
        'age': 25,
        'bio': 'Test profile for chat system'
      }
    ];

    for (int i = 0; i < testProfiles.length; i++) {
      try {
        print('\n🔍 Testing profile $i...');
        final profile = PlayerProfile.fromJson(testProfiles[i]);
        print(
            '✅ Successfully parsed: ${profile.firstName} ${profile.lastName} (${profile.user.id})');
        print('   Email: "${profile.user.email}"');
      } catch (e) {
        print('❌ Failed to parse profile $i: $e');
      }
    }

    print('\n🎯 Testing with actual API...');
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(
        'http://localhost:5000/api/matchmaking/HvflhVZfY9b4XJNdwznaA2nzFY02/potential-matches'));
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);

      if (data['success'] == true) {
        final List<dynamic> matchesJson = data['matches'];
        print('📦 Found ${matchesJson.length} matches from API');

        int successCount = 0;
        for (int i = 0; i < matchesJson.length; i++) {
          try {
            final profile = PlayerProfile.fromJson(matchesJson[i]);
            successCount++;
            print(
                '✅ Match $i: ${profile.firstName} ${profile.lastName.isEmpty ? '(no lastName)' : profile.lastName}');
          } catch (e) {
            print('❌ Match $i failed: $e');
          }
        }

        print(
            '\n🎉 Successfully parsed $successCount out of ${matchesJson.length} profiles!');
      }
    }

    client.close();
  } catch (e) {
    print('❌ Test error: $e');
  }
}
