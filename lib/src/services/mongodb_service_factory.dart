import 'package:flutter/foundation.dart';
import 'mongodb_local_service.dart';
import 'web_mongodb_service.dart';

/// A factory class that provides the appropriate MongoDB service based on platform
class MongoDBServiceFactory {
  // Singleton instance
  static final MongoDBServiceFactory _instance =
      MongoDBServiceFactory._internal();

  // Private constructor
  MongoDBServiceFactory._internal();

  // Factory constructor
  factory MongoDBServiceFactory() {
    return _instance;
  }

  /// Get the appropriate MongoDB service for the current platform
  dynamic getService() {
    if (kIsWeb) {
      debugPrint('Using WebMongoDBService for web platform');
      return WebMongoDBService();
    } else {
      debugPrint('Using MongoDBLocalService for native platform');
      return MongoDBLocalService();
    }
  }
}
