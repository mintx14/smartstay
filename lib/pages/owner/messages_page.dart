import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class MessagesPage extends StatefulWidget {
  final int currentUserId; // Tenant's user ID

  const MessagesPage({super.key, required this.currentUserId});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _selectedIndex = -1;
  final TextEditingController _searchController = TextEditingController();
  List<MessagePreview> conversations = [];
  bool isLoading = true;
  Timer? _refreshTimer;

  // Theme colors
  final Color primaryColor = Colors.indigo;
  final Color accentColor = Colors.indigoAccent;
  final Color backgroundColor = Colors.grey[50]!;
  final Color cardColor = Colors.white;
  final Color selectedChatColor = Colors.indigo.withOpacity(0.1);

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
    _searchController.dispose();
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
            conversations = (data['conversations'] as List)
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _showNewMessageDialog() async {
    // Get list of owners to start conversation with
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/get_users.php?current_user_id=${widget.currentUserId}&user_type=Owner'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['users'] != null) {
          List<User> users = (data['users'] as List)
              .map((user) => User.fromJson(user))
              .toList();

          if (users.isEmpty) {
            _showError('No property owners available to message');
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
        builder: (context) => ChatScreen(
          currentUserId: widget.currentUserId,
          otherUser: user,
        ),
      ),
    ).then((_) => _loadConversations()); // Refresh when returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: _showNewMessageDialog,
            tooltip: 'New Message',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : conversations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: _buildChatsList(context),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search messages',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            // You can implement search functionality here
          });
        },
      ),
    );
  }

  Widget _buildChatsList(BuildContext context) {
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        bool isSelected = index == _selectedIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: isSelected ? selectedChatColor : null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });

                // Navigate to full screen chat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      currentUserId: widget.currentUserId,
                      otherUser: User(
                        id: conversation.otherUserId,
                        fullName: conversation.name,
                        email: '',
                        userType: conversation.otherUserType,
                      ),
                    ),
                  ),
                ).then((_) {
                  setState(() {
                    _selectedIndex = -1;
                  });
                  _loadConversations();
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: _getAvatarColor(index),
                          child: Text(
                            conversation.name.isNotEmpty
                                ? conversation.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Online indicator for active conversations
                        if (conversation.unread > 0)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  conversation.name,
                                  style: TextStyle(
                                    fontWeight:
                                        isSelected || conversation.unread > 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 15.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                conversation.time,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conversation.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected || conversation.unread > 0
                                        ? Colors.black87
                                        : Colors.grey[600],
                                    fontSize: 13.0,
                                  ),
                                ),
                              ),
                              if (conversation.unread > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8.0),
                                  padding: const EdgeInsets.all(6.0),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    conversation.unread.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with property owners',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showNewMessageDialog,
            icon: const Icon(Icons.add_comment),
            label: const Text('Start New Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(int index) {
    List<Color> colors = [
      Colors.indigo,
      Colors.purple,
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
    ];
    return colors[index % colors.length];
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
                backgroundColor: Colors.indigo,
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.fullName),
              subtitle: Text('${user.userType} • ${user.email}'),
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

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final User otherUser;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUser,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  bool isLoading = true;
  Timer? _refreshTimer;

  // Theme colors
  final Color primaryColor = Colors.indigo;
  final Color accentColor = Colors.indigoAccent;
  final Color backgroundColor = Colors.grey[50]!;
  final Color cardColor = Colors.white;

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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if the response has an error
        if (data['error'] != null) {
          throw Exception(data['error']);
        }

        if (data['messages'] != null) {
          List<ChatMessage> newMessages = [];
          for (var msgData in data['messages']) {
            try {
              newMessages.add(ChatMessage.fromJson(msgData));
            } catch (e) {
              print('Error parsing message: $e');
              print('Message data: $msgData');
              // Skip this message and continue with others
            }
          }

          setState(() {
            messages = newMessages;
            isLoading = false;
          });
          _scrollToBottom();
        } else {
          setState(() {
            messages = [];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (showLoading) {
        _showError('Error loading messages: $e');
      }
      print('Error in _loadMessages: $e');
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leadingWidth: 40,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor,
                  child: Text(
                    widget.otherUser.fullName.isNotEmpty
                        ? widget.otherUser.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.otherUser.userType,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {},
            tooltip: 'Call',
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
            tooltip: 'Video Call',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
            tooltip: 'More Options',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Column(
          children: [
            // Chat messages
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
                      : _buildMessagesList(),
            ),
            // Message input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      controller: _scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return message.isOwnMessage
            ? _buildOutgoingMessage(message)
            : _buildIncomingMessage(message);
      },
    );
  }

  Widget _buildIncomingMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, right: 80.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16.0,
            backgroundColor: primaryColor,
            child: Text(
              widget.otherUser.fullName.isNotEmpty
                  ? widget.otherUser.fullName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(fontSize: 12.0, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0),
                      bottomRight: Radius.circular(18.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: const TextStyle(fontSize: 14.0),
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Icon(Icons.check, size: 14.0, color: Colors.grey[400]),
                    const SizedBox(width: 4.0),
                    Text(
                      _formatMessageTime(message.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutgoingMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, left: 80.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0),
                      bottomLeft: Radius.circular(18.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: const TextStyle(fontSize: 14.0),
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(message.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11.0,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14.0,
                      color: message.isRead ? accentColor : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: cardColor,
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
          IconButton(
            icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600]),
            onPressed: () {},
            tooltip: 'Emojis',
          ),
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.grey[600]),
            onPressed: () {},
            tooltip: 'Attachments',
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
              tooltip: 'Send Message',
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
