class ChatMessage {
  final int id;
  final String senderId;
  final String receiverId;
  final String message;
  final bool isRead;
  final String createdAt;
  final String senderName;
  final bool isOwnMessage;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.senderName,
    required this.isOwnMessage,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _parseToInt(json['id']),
      senderId: json['sender_id'].toString(),
      receiverId: json['receiver_id'].toString(),
      message: json['message']?.toString() ?? '',
      isRead: _parseToBool(json['is_read']),
      createdAt: json['created_at']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? '',
      isOwnMessage: _parseToBool(json['is_own_message']),
    );
  }

  // Helper method to safely parse integers
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper method to safely parse booleans
  static bool _parseToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}
