import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String relatedUserId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.relatedUserId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      relatedUserId: json['relatedUserId'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'type': type,
      'relatedUserId': relatedUserId,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class NotificationService {
  static const String baseUrl = 'http://localhost:5000/api';

  /// Get user notifications
  Future<List<NotificationModel>> getNotifications(
    String userId, {
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/notifications/$userId?unreadOnly=$unreadOnly&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> notificationsJson = data['notifications'];
          return notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        }
      }

      throw Exception('Failed to get notifications: ${response.statusCode}');
    } catch (e) {
      print('Error getting notifications: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/$userId?unreadOnly=true'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unreadCount'] ?? 0;
      }

      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$userId/read-all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Create a new notification
  Future<bool> createNotification({
    required String userId,
    required String type,
    required String relatedUserId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'type': type,
          'relatedUserId': relatedUserId,
          'message': message,
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }

      print('Failed to create notification: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  /// Create match notifications for both users when a match occurs
  Future<bool> createMatchNotifications({
    required String firstUserId,
    required String secondUserId,
    required String firstUserName,
    required String secondUserName,
  }) async {
    try {
      // Create notification for the first user (who liked initially)
      final firstUserResult = await createNotification(
        userId: firstUserId,
        type: 'match',
        relatedUserId: secondUserId,
        message: 'It\'s a match! $secondUserName liked you back!',
      );

      // Create notification for the second user (who just liked)
      final secondUserResult = await createNotification(
        userId: secondUserId,
        type: 'match',
        relatedUserId: firstUserId,
        message: 'It\'s a match! You and $firstUserName liked each other!',
      );

      return firstUserResult && secondUserResult;
    } catch (e) {
      print('Error creating match notifications: $e');
      return false;
    }
  }

  /// Delete a notification (used when user sees the notification)
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }
}
