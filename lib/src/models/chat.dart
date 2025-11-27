class Chat {
  final String id;
  final List<String> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final ChatUser? otherUser;
  final List<ChatUser>? participantDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCount,
    this.otherUser,
    this.participantDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id'] ?? json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? json['unreadCounts']?[0] ?? 0,
      otherUser: json['otherUser'] != null
          ? ChatUser.fromJson(json['otherUser'])
          : null,
      participantDetails: json['participantDetails'] != null
          ? List<ChatUser>.from(
              json['participantDetails'].map((x) => ChatUser.fromJson(x)))
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'participants': participants,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'otherUser': otherUser?.toJson(),
      'participantDetails': participantDetails?.map((x) => x.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Get other participant info for current user
  ChatUser? getOtherParticipant(String currentUserId) {
    if (participantDetails != null && participantDetails!.isNotEmpty) {
      try {
        return participantDetails!.firstWhere(
          (user) => user.id != currentUserId,
        );
      } catch (e) {
        // If no other participant found, return a default
        return ChatUser(id: 'unknown', name: 'Chat Partner');
      }
    }
    return otherUser ?? ChatUser(id: 'unknown', name: 'Chat Partner');
  }
}

class ChatMessage {
  final String? id;
  final String? chatId;
  final String senderId;
  final String message;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final List<MessageReaction> reactions;

  ChatMessage({
    this.id,
    this.chatId,
    required this.senderId,
    required this.message,
    this.type = 'text',
    required this.timestamp,
    this.isRead = false,
    this.reactions = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      message: json['message'],
      type: json['type'] ?? 'text',
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      reactions: json['reactions'] != null
          ? List<MessageReaction>.from(
              json['reactions'].map((x) => MessageReaction.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      if (chatId != null) 'chatId': chatId,
      'senderId': senderId,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'reactions': reactions.map((x) => x.toJson()).toList(),
    };
  }
}

class ChatUser {
  final String id;
  final String name;
  final String? photo;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatUser({
    required this.id,
    required this.name,
    this.photo,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? json['_id'] ?? json['userId'] ?? '',
      name: json['name'] ??
          json['firstName'] ??
          json['displayName'] ??
          json['fullName'] ??
          'Unknown User',
      photo: json['photo'] ?? json['profileImage'] ?? json['avatar'],
      isOnline:
          json['isOnline'] == true, // Safely handle null/non-boolean values
      lastSeen:
          json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photo': photo,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  String getOnlineStatus() {
    if (isOnline) {
      return 'Online';
    } else if (lastSeen != null) {
      final difference = DateTime.now().difference(lastSeen!);
      if (difference.inMinutes < 5) {
        return 'Last seen recently';
      } else if (difference.inHours < 1) {
        return 'Last seen ${difference.inMinutes} minutes ago';
      } else if (difference.inDays < 1) {
        return 'Last seen ${difference.inHours} hours ago';
      } else {
        return 'Last seen ${difference.inDays} days ago';
      }
    }
    return 'Offline';
  }
}

class MessageReaction {
  final String userId;
  final String emoji;
  final DateTime timestamp;

  MessageReaction({
    required this.userId,
    required this.emoji,
    required this.timestamp,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      userId: json['userId'],
      emoji: json['emoji'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'emoji': emoji,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
