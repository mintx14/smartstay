// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class MessageService {
  static const String baseUrl =
      'http://10.0.2.2/smartstay'; // Change this to your server URL

  // Get conversations for a user
  static Future<List<dynamic>> getConversations(
      int userId, String userType) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/messages.php?action=conversations&user_id=$userId&user_type=$userType'),
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
      final response = await http.get(
        Uri.parse(
            '$baseUrl/messages.php?action=messages&conversation_id=$conversationId'),
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
      final response = await http.post(
        Uri.parse('$baseUrl/messages.php'),
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
      final response = await http.post(
        Uri.parse('$baseUrl/messages.php'),
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
      final response = await http.post(
        Uri.parse('$baseUrl/messages.php'),
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
      final response = await http.get(
        Uri.parse('$baseUrl/messages.php?action=unread_count&user_id=$userId'),
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
