import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class MessagesScreen extends StatefulWidget {
  final int currentUserId; // Owner's user ID

  const MessagesScreen({super.key, required this.currentUserId});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<MessagePreview> messages = [];
  bool isLoading = true;
  String selectedFilter = 'All';
  Timer? _refreshTimer;

  // API Configuration
  static const String baseUrl =
      'http://10.0.2.2/smartstay'; // Change to your server URL

  @override
  void initState() {
    super.initState();
    _loadConversations();
    // Auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadConversations();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/get_conversations.php?user_id=${widget.currentUserId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['conversations'] != null) {
          setState(() {
            messages = (data['conversations'] as List)
                .map((conv) => MessagePreview.fromJson(conv))
                .toList();
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Error loading conversations: $e');
    }
  }

  List<MessagePreview> get filteredMessages {
    if (selectedFilter == 'All') return messages;
    return messages.where((msg) {
      switch (selectedFilter) {
        case 'Properties':
          return msg.otherUserType == 'Tenant';
        case 'Agents':
          return msg.otherUserType == 'Owner';
        case 'Roommates':
          return msg.otherUserType == 'Tenant';
        default:
          return true;
      }
    }).toList();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _showNewMessageDialog() async {
    // Get list of users to start conversation with
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/get_users.php?current_user_id=${widget.currentUserId}&user_type=Tenant'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['users'] != null) {
          List<User> users = (data['users'] as List)
              .map((user) => User.fromJson(user))
              .toList();

          if (users.isEmpty) {
            _showError('No tenants available to message');
            return;
          }

          showDialog(
            context: context,
            builder: (context) => _NewMessageDialog(
              users: users,
              onUserSelected: (user) {
                Navigator.of(context).pop();
                _openChatWithUser(user);
              },
            ),
          );
        }
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      _showError('Error loading users: $e');
    }
  }

  void _openChatWithUser(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OwnerChatScreen(
          currentUserId: widget.currentUserId,
          otherUser: user,
        ),
      ),
    ).then((_) => _loadConversations()); // Refresh when returning
  }

  void _openChat(MessagePreview message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OwnerChatScreen(
          currentUserId: widget.currentUserId,
          otherUser: User(
            id: message.otherUserId,
            fullName: message.name,
            email: '',
            userType: message.otherUserType,
          ),
        ),
      ),
    ).then((_) => _loadConversations()); // Refresh when returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF190152),
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Message filter tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterTab('All'),
                _buildFilterTab('Properties'),
                _buildFilterTab('Agents'),
                _buildFilterTab('Roommates'),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMessages.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.builder(
                          itemCount: filteredMessages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageTile(filteredMessages[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF190152),
        onPressed: _showNewMessageDialog,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE9F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF190152) : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageTile(MessagePreview message) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFF190152),
        child: Text(
          message.name.isNotEmpty ? message.name[0].toUpperCase() : 'U',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              message.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            message.time,
            style: TextStyle(
              fontSize: 12,
              color: message.unread > 0 ? const Color(0xFF190152) : Colors.grey,
              fontWeight:
                  message.unread > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              message.lastMessage,
              style: TextStyle(
                fontSize: 14,
                color: message.unread > 0 ? Colors.black87 : Colors.grey,
                fontWeight:
                    message.unread > 0 ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (message.unread > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF190152),
                shape: BoxShape.circle,
              ),
              child: Text(
                message.unread.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () => _openChat(message),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with tenants',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NewMessageDialog extends StatelessWidget {
  final List<User> users;
  final Function(User) onUserSelected;

  const _NewMessageDialog({
    required this.users,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start New Conversation'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF190152),
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.fullName),
              subtitle: Text(user.userType),
              onTap: () => onUserSelected(user),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// Data models
class MessagePreview {
  final int conversationId;
  final int otherUserId;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final String otherUserType;

  MessagePreview({
    required this.conversationId,
    required this.otherUserId,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.otherUserType,
  });

  factory MessagePreview.fromJson(Map<String, dynamic> json) {
    return MessagePreview(
      conversationId: json['conversation_id'],
      otherUserId: json['other_user_id'],
      name: json['other_user_name'] ?? 'Unknown',
      lastMessage: json['last_message'] ?? 'No messages yet',
      time: _formatTime(json['last_message_time']),
      unread: json['unread_count'] ?? 0,
      otherUserType: json['other_user_type'] ?? 'Unknown',
    );
  }

  static String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final DateTime time = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(time);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Now';
      }
    } catch (e) {
      return '';
    }
  }
}

class User {
  final int id;
  final String fullName;
  final String email;
  final String userType;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      userType: json['user_type'],
    );
  }
}

class OwnerChatScreen extends StatefulWidget {
  final int currentUserId;
  final User otherUser;

  const OwnerChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUser,
  });

  @override
  State<OwnerChatScreen> createState() => _OwnerChatScreenState();
}

class _OwnerChatScreenState extends State<OwnerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  bool isLoading = true;
  Timer? _refreshTimer;

  static const String baseUrl = 'http://10.0.2.2/smartstay';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/get_messages.php?user_id=${widget.currentUserId}&other_user_id=${widget.otherUser.id}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['messages'] != null) {
          setState(() {
            messages = (data['messages'] as List)
                .map((msg) => ChatMessage.fromJson(msg))
                .toList();
            isLoading = false;
          });
          _scrollToBottom();
        }
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (showLoading) {
        _showError('Error loading messages: $e');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send_message.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_id': widget.currentUserId,
          'receiver_id': widget.otherUser.id,
          'message': messageText,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _loadMessages(showLoading: false);
        } else {
          throw Exception(data['error'] ?? 'Failed to send message');
        }
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      _showError('Error sending message: $e');
      _messageController.text = messageText; // Restore message on error
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF190152),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text(
                widget.otherUser.fullName.isNotEmpty
                    ? widget.otherUser.fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Color(0xFF190152),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.otherUser.userType,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isOwnMessage = message.isOwnMessage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF190152),
              child: Text(
                widget.otherUser.fullName.isNotEmpty
                    ? widget.otherUser.fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isOwnMessage ? const Color(0xFF190152) : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOwnMessage ? 18 : 4),
                  bottomRight: Radius.circular(isOwnMessage ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isOwnMessage ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: TextStyle(
                      color: isOwnMessage ? Colors.white70 : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOwnMessage) const SizedBox(width: 50),
          if (!isOwnMessage) const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF190152),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(String timestamp) {
    try {
      final DateTime time = DateTime.parse(timestamp);
      final now = DateTime.now();

      if (time.day == now.day &&
          time.month == now.month &&
          time.year == now.year) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else {
        return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }
}

class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
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
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'],
      isRead: json['is_read'],
      createdAt: json['created_at'],
      senderName: json['sender_name'],
      isOwnMessage: json['is_own_message'],
    );
  }
}
