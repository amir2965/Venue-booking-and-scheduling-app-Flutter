import 'package:flutter/foundation.dart';
import 'mongodb_service_base.dart';

/// A simplified version of the UsernameService to resolve import issues
class UsernameService {
  final MongoDBServiceBase _mongoDBService;

  UsernameService(this._mongoDBService);

  void initialize() {
    debugPrint('Simple UsernameService initialized');
  }

  /// Check if a username is valid
  bool isValidUsername(String username) {
    if (username.isEmpty) return false;
    if (username.length < 3 || username.length > 20) return false;

    // Only allow alphanumeric characters and underscores
    final RegExp validUsernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    return validUsernameRegex.hasMatch(username);
  }

  /// Check if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    if (!isValidUsername(username)) return false;
    return await _mongoDBService.isUsernameAvailable(username);
  }

  /// Reserve a username for a user
  Future<bool> reserveUsername(String username, String userId) async {
    if (!isValidUsername(username)) return false;

    try {
      return await _mongoDBService.reserveUsername(username, userId);
    } catch (e) {
      debugPrint('Error reserving username: $e');
      return false;
    }
  }

  /// Update a user's username
  Future<bool> updateUsername(String userId, String newUsername) async {
    if (!isValidUsername(newUsername)) return false;

    try {
      return await _mongoDBService.updateUsername(userId, newUsername);
    } catch (e) {
      debugPrint('Error updating username: $e');
      return false;
    }
  }

  /// Get server health
  Future<bool> isServerUp() async {
    return await _mongoDBService.checkConnectivity();
  }
}
