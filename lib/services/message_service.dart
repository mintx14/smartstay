import 'dart:convert';
import 'package:http/http.dart' as http;
// ADD THIS IMPORT
import 'package:my_app/config/api_config.dart'; // Adjust path as needed

class MessageService {
  // REMOVE THIS LINE - No longer needed
  // static const String baseUrl = 'http://192.168.0.11/smartstay';

  // Get conversations for a user
  static Future<List<dynamic>> getConversations(
      int userId, String userType) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.get(
        Uri.parse(ApiConfig.getMessagesUrlWithParams2('conversations',
            params: {'user_id': userId.toString(), 'user_type': userType})),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }

  // Get messages for a conversation
  static Future<List<dynamic>> getMessages(int conversationId) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.get(
        Uri.parse(ApiConfig.getMessagesUrlWithParams2('messages',
            params: {'conversation_id': conversationId.toString()})),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Send a message
  static Future<Map<String, dynamic>?> sendMessage({
    required int senderId,
    required int receiverId,
    required int ownerId,
    required int studentId,
    required String message,
    String messageType = 'text',
  }) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.post(
        Uri.parse(ApiConfig.messagesUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'send_message',
          'sender_id': senderId,
          'receiver_id': receiverId,
          'owner_id': ownerId,
          'student_id': studentId,
          'message': message,
          'message_type': messageType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  // Mark messages as read
  static Future<bool> markAsRead(int conversationId, int userId) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.post(
        Uri.parse(ApiConfig.messagesUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'mark_read',
          'conversation_id': conversationId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'];
      }
      return false;
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  // Create conversation
  static Future<int?> createConversation(int ownerId, int studentId) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.post(
        Uri.parse(ApiConfig.messagesUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'create_conversation',
          'owner_id': ownerId,
          'student_id': studentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data']['conversation_id'];
        }
      }
      return null;
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }

  // Get unread message count
  static Future<int> getUnreadCount(int userId) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.get(
        Uri.parse(ApiConfig.getMessagesUrlWithParams2('unread_count',
            params: {'user_id': userId.toString()})),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data']['unread_count'];
        }
      }
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
}
