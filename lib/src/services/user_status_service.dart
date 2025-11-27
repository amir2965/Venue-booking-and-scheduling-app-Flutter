import 'dart:convert';
import 'package:http/http.dart' as http;

class UserStatusService {
  static const String baseUrl = 'http://localhost:5000/api';

  // Update user online status
  Future<void> updateUserStatus({
    required String userId,
    bool isOnline = true,
    String? platform,
    String? version,
    String? userAgent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'isOnline': isOnline,
          'platform': platform ?? 'mobile',
          'version': version ?? '1.0.0',
          'userAgent': userAgent ?? 'Flutter App',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user status: ${response.body}');
      }
    } catch (e) {
      print('Error updating user status: $e');
      // Don't throw error for status updates to avoid disrupting app flow
    }
  }

  // Get user status
  Future<UserStatus> getUserStatus(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserStatus.fromJson(data);
      } else {
        throw Exception('Failed to get user status: ${response.body}');
      }
    } catch (e) {
      print('Error getting user status: $e');
      return UserStatus(
        userId: userId,
        isOnline: false,
        lastSeen: null,
      );
    }
  }

  // Get multiple users' status
  Future<Map<String, UserStatus>> getBatchUserStatus(
      List<String> userIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/status/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userIds': userIds}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statuses = data['statuses'] as Map<String, dynamic>;

        return statuses.map((userId, statusData) =>
            MapEntry(userId, UserStatus.fromJson(statusData)));
      } else {
        throw Exception('Failed to get batch user status: ${response.body}');
      }
    } catch (e) {
      print('Error getting batch user status: $e');
      // Return empty status for all users on error
      return Map.fromEntries(
        userIds.map((id) => MapEntry(
            id,
            UserStatus(
              userId: id,
              isOnline: false,
              lastSeen: null,
            ))),
      );
    }
  }

  // Set user offline (for logout)
  Future<void> setUserOffline(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/offline'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to set user offline: ${response.body}');
      }
    } catch (e) {
      print('Error setting user offline: $e');
      // Don't throw error for status updates
    }
  }

  // Keep user online with periodic updates
  void startKeepAlive(String userId) {
    // Update status every 2 minutes to keep user online
    Stream.periodic(const Duration(minutes: 2)).listen((_) {
      updateUserStatus(userId: userId, isOnline: true);
    });
  }
}

class UserStatus {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
  final DeviceInfo? deviceInfo;

  UserStatus({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
    this.deviceInfo,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      userId: json['userId'],
      isOnline: json['isOnline'] ?? false,
      lastSeen:
          json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      deviceInfo: json['deviceInfo'] != null
          ? DeviceInfo.fromJson(json['deviceInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'deviceInfo': deviceInfo?.toJson(),
    };
  }
}

class DeviceInfo {
  final String platform;
  final String version;
  final String userAgent;

  DeviceInfo({
    required this.platform,
    required this.version,
    required this.userAgent,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      platform: json['platform'] ?? 'unknown',
      version: json['version'] ?? 'unknown',
      userAgent: json['userAgent'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'version': version,
      'userAgent': userAgent,
    };
  }
}
