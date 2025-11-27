class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final bool isDelivered;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data = const {},
    required this.createdAt,
    this.isRead = false,
    this.isDelivered = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      isDelivered: json['isDelivered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isDelivered': isDelivered,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    bool? isDelivered,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, title: $title, message: $message, type: $type, isRead: $isRead)';
  }
}

enum NotificationType {
  match,
  message,
  like,
  general,
}

class MatchNotificationData {
  final String matchId;
  final String matchedUserId;
  final String matchedUserName;
  final String? matchedUserPhoto;

  const MatchNotificationData({
    required this.matchId,
    required this.matchedUserId,
    required this.matchedUserName,
    this.matchedUserPhoto,
  });

  factory MatchNotificationData.fromJson(Map<String, dynamic> json) {
    return MatchNotificationData(
      matchId: json['matchId'] ?? '',
      matchedUserId: json['matchedUserId'] ?? '',
      matchedUserName: json['matchedUserName'] ?? '',
      matchedUserPhoto: json['matchedUserPhoto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'matchedUserId': matchedUserId,
      'matchedUserName': matchedUserName,
      'matchedUserPhoto': matchedUserPhoto,
    };
  }
}
