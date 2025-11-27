import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';

// Chat Service Provider
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// Current Chat ID Provider
final currentChatIdProvider = StateProvider<String?>((ref) => null);

// Chat List Provider
final chatListProvider =
    StateNotifierProvider<ChatListNotifier, AsyncValue<List<Chat>>>((ref) {
  return ChatListNotifier(ref.read(chatServiceProvider));
});

// Chat Info Provider
final chatInfoProvider =
    StateNotifierProvider.family<ChatInfoNotifier, AsyncValue<Chat?>, String>(
        (ref, chatId) {
  return ChatInfoNotifier(ref.read(chatServiceProvider), chatId);
});

// Messages Provider
final messagesProvider = StateNotifierProvider.family<MessagesNotifier,
    AsyncValue<List<ChatMessage>>, String>((ref, chatId) {
  return MessagesNotifier(ref.read(chatServiceProvider), chatId);
});

// Chat List Notifier
class ChatListNotifier extends StateNotifier<AsyncValue<List<Chat>>> {
  final ChatService _chatService;
  Timer? _refreshTimer;

  ChatListNotifier(this._chatService) : super(const AsyncValue.loading());

  Future<void> loadChats(String userId) async {
    try {
      state = const AsyncValue.loading();
      final chats = await _chatService.getUserChats(userId);
      state = AsyncValue.data(chats);

      // Set up periodic refresh
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _refreshChats(userId);
      });
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> _refreshChats(String userId) async {
    try {
      final chats = await _chatService.getUserChats(userId);
      state = AsyncValue.data(chats);
    } catch (e) {
      // Silently handle refresh errors
    }
  }

  Future<String> createChat(String userId1, String userId2) async {
    try {
      final chatId = await _chatService.createOrGetChat(userId1, userId2);
      // Refresh chat list after creating new chat
      await _refreshChats(userId1);
      return chatId;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// Chat Info Notifier
class ChatInfoNotifier extends StateNotifier<AsyncValue<Chat?>> {
  final ChatService _chatService;
  final String _chatId;

  ChatInfoNotifier(this._chatService, this._chatId)
      : super(const AsyncValue.loading()) {
    loadChatInfo();
  }

  Future<void> loadChatInfo() async {
    try {
      state = const AsyncValue.loading();
      final chat = await _chatService.getChatInfo(_chatId);
      state = AsyncValue.data(chat);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Messages Notifier
class MessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatService _chatService;
  final String _chatId;
  Timer? _refreshTimer;

  MessagesNotifier(this._chatService, this._chatId)
      : super(const AsyncValue.loading()) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    try {
      state = const AsyncValue.loading();
      final messages = await _chatService.getChatMessages(_chatId);
      state = AsyncValue.data(messages);

      // Set up periodic refresh
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _refreshMessages();
      });
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> _refreshMessages() async {
    try {
      final messages = await _chatService.getChatMessages(_chatId);
      state = AsyncValue.data(messages);
    } catch (e) {
      // Silently handle refresh errors
    }
  }

  Future<void> sendMessage(String senderId, String message,
      {String type = 'text'}) async {
    try {
      // Optimistically add message to UI
      final optimisticMessage = ChatMessage(
        senderId: senderId,
        message: message,
        type: type,
        timestamp: DateTime.now(),
      );

      state.whenData((messages) {
        state = AsyncValue.data([...messages, optimisticMessage]);
      });

      // Send to server
      final sentMessage = await _chatService
          .sendMessage(_chatId, senderId, message, type: type);

      // Replace optimistic message with server response
      state.whenData((messages) {
        final updatedMessages = messages.map((msg) {
          if (msg.id == null &&
              msg.senderId == senderId &&
              msg.message == message &&
              msg.timestamp.isAtSameMomentAs(optimisticMessage.timestamp)) {
            return sentMessage;
          }
          return msg;
        }).toList();
        state = AsyncValue.data(updatedMessages);
      });
    } catch (e) {
      // Remove optimistic message on error
      await _refreshMessages();
      rethrow;
    }
  }

  Future<void> markAsRead(String userId) async {
    try {
      await _chatService.markMessagesAsRead(_chatId, userId);
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> addReaction(
      String messageId, String userId, String emoji) async {
    try {
      final reactions =
          await _chatService.addReaction(messageId, userId, emoji);

      state.whenData((messages) {
        final updatedMessages = messages.map((msg) {
          if (msg.id == messageId) {
            return ChatMessage(
              id: msg.id,
              chatId: msg.chatId,
              senderId: msg.senderId,
              message: msg.message,
              type: msg.type,
              timestamp: msg.timestamp,
              isRead: msg.isRead,
              reactions: reactions,
            );
          }
          return msg;
        }).toList();
        state = AsyncValue.data(updatedMessages);
      });
    } catch (e) {
      // Silently handle errors
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
