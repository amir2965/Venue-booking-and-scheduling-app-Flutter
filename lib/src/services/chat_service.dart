import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat.dart';

class ChatService {
  static const String baseUrl = 'http://localhost:5000/api';

  // Get user's chat list
  Future<List<Chat>> getUserChats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Chat>.from(data['chats'].map((x) => Chat.fromJson(x)));
        }
      }

      throw Exception('Failed to load chats: ${response.body}');
    } catch (e) {
      throw Exception('Error fetching chats: $e');
    }
  }

  // Create or get existing chat between two users
  Future<String> createOrGetChat(String userId1, String userId2) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId1': userId1,
          'userId2': userId2,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['chatId'];
        }
      }

      throw Exception('Failed to create chat: ${response.body}');
    } catch (e) {
      throw Exception('Error creating chat: $e');
    }
  }

  // Get messages for a chat
  Future<List<ChatMessage>> getChatMessages(String chatId,
      {int page = 1, int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$chatId/messages?page=$page&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<ChatMessage>.from(
              data['messages'].map((x) => ChatMessage.fromJson(x)));
        }
      }

      throw Exception('Failed to load messages: ${response.body}');
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  // Send a message
  Future<ChatMessage> sendMessage(
      String chatId, String senderId, String message,
      {String type = 'text'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': senderId,
          'message': message,
          'type': type,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return ChatMessage.fromJson(data['message']);
        }
      }

      throw Exception('Failed to send message: ${response.body}');
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/chats/$chatId/read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark messages as read: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error marking messages as read: $e');
    }
  }

  // Add reaction to message
  Future<List<MessageReaction>> addReaction(
      String messageId, String userId, String emoji) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages/$messageId/reactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'emoji': emoji,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<MessageReaction>.from(
              data['reactions'].map((x) => MessageReaction.fromJson(x)));
        }
      }

      throw Exception('Failed to add reaction: ${response.body}');
    } catch (e) {
      throw Exception('Error adding reaction: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/messages/$messageId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete message: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }

  // Get chat info with participant details
  Future<Chat> getChatInfo(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats/info/$chatId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend returns the chat object directly, not wrapped in success/chat
        return Chat.fromJson(data);
      }

      throw Exception('Failed to get chat info: ${response.body}');
    } catch (e) {
      throw Exception('Error getting chat info: $e');
    }
  }
}
