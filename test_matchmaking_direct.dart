import 'package:billiards_hub/src/services/matchmaking_service.dart';

void main() async {
  print('🧪 Testing MatchmakingService directly...');

  final service = MatchmakingService();
  final userId =
      'HvflhVZfY9b4XJNdwznaA2nzFY02'; // The problematic user from logs

  try {
    print('🔍 Calling getPotentialMatches for user: $userId');
    final matches = await service.getPotentialMatches(userId);
    print('✅ Successfully got ${matches.length} matches');

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      print(
          'Match $i: ${match.firstName} ${match.lastName} (${match.user.id})');
    }
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('📍 StackTrace: $stackTrace');
  }
}
