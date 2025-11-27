import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/simple_username_service.dart';
import 'mongodb_provider.dart';

// Provider for UsernameService
final usernameServiceProvider = Provider<UsernameService>((ref) {
  // Inject MongoDB service into UsernameService
  final mongoDBService = ref.watch(mongoDBServiceProvider);
  final service = UsernameService(mongoDBService);
  return service;
});
