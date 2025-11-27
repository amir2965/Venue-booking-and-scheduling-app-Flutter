import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    print('🧪 Testing API response structure...');

    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(
        'http://localhost:5000/api/matchmaking/HvflhVZfY9b4XJNdwznaA2nzFY02/potential-matches'));
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);

      print('✅ Success: ${data['success']}');
      print('📦 Total matches: ${data['matches']?.length ?? 0}');

      if (data['matches'] != null && data['matches'].isNotEmpty) {
        print('\n🔍 Analyzing first few matches:');

        for (int i = 0; i < 3 && i < data['matches'].length; i++) {
          final match = data['matches'][i];
          print('\n--- Match $i ---');
          print('📋 Keys: ${match.keys.toList()}');
          print('👤 User field: ${match['user']}');
          print('🏷️ firstName: ${match['firstName']}');
          print('🏷️ lastName: ${match['lastName']}');
          print('📧 email (direct): ${match['email']}');
          print('🆔 userId (direct): ${match['userId']}');

          // Check if user field contains data
          if (match['user'] != null) {
            final user = match['user'];
            if (user is Map) {
              print('👤 User keys: ${user.keys.toList()}');
              print('📧 user.email: ${user['email']}');
              print('🆔 user.id: ${user['id']}');
            } else {
              print('👤 User is not a Map: $user (${user.runtimeType})');
            }
          }
        }
      }
    } else {
      print('❌ HTTP Error: ${response.statusCode}');
    }

    client.close();
  } catch (e) {
    print('❌ Error: $e');
  }
}
