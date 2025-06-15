// lib/models/message_models.dart
class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final int receiverId;
  final String message;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;
  final String senderName;
  final String? senderAvatar;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
    required this.senderName,
    this.senderAvatar,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: int.parse(json['id'].toString()),
      conversationId: int.parse(json['conversation_id'].toString()),
      senderId: int.parse(json['sender_id'].toString()),
      receiverId: int.parse(json['receiver_id'].toString()),
      message: json['message'],
      messageType: json['message_type'],
      isRead: json['is_read'] == '1' || json['is_read'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
    );
  }
}

class ConversationModel {
  final int conversationId;
  final int userId;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ConversationModel({
    required this.conversationId,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.isOnline,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversationId: int.parse(json['conversation_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      name: json['name'],
      avatarUrl: json['avatar_url'],
      isOnline: json['is_online'] == '1' || json['is_online'] == 1,
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
      unreadCount: int.parse(json['unread_count'].toString()),
    );
  }
}
