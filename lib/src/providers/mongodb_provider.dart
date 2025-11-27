import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mongodb_local_service.dart';
import '../services/mongodb_service_base.dart';
import '../services/mongodb_web_service.dart';

// Provider for MongoDB service - selects implementation based on platform
final mongoDBServiceProvider = Provider<MongoDBServiceBase>((ref) {
  if (kIsWeb) {
    // Use the web service in web environment with environment-based configuration
    final apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:5000',
    );
    return MongoDBWebService(customBaseUrl: apiBaseUrl);
  } else {
    // Use local service in native environment
    return MongoDBLocalService();
  }
});
