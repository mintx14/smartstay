// shared/chat_screen.dart
// This file can be used by both tenant and owner

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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
}

class ChatMessage {
  final int id;
  final String message;
  final String senderName;
  final DateTime createdAt;
  final bool isOwnMessage;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderName,
    required this.createdAt,
    required this.isOwnMessage,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      message: json['message'],
      senderName: json['sender_name'],
      createdAt: DateTime.parse(json['created_at']),
      isOwnMessage: json['is_own_message'] == 1,
      isRead: json['is_read'] == 1,
    );
  }
}

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final User otherUser;
  final int? listingId;
  final String? listingTitle;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUser,
    this.listingId,
    this.listingTitle,
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

  static const String baseUrl =
      'http://192.168.0.11/smartstay'; // Update for your environment
  //'http://10.0.2.2/smartstay'; // Update for your environment

  @override
  void initState() {
    super.initState();

    // Debug: Print the listing ID and other parameters
    print('=== CHAT SCREEN DEBUG INFO ===');
    print('Current User ID: ${widget.currentUserId}');
    print('Other User ID: ${widget.otherUser.id}');
    print('Other User Name: ${widget.otherUser.fullName}');
    print('Listing ID: ${widget.listingId}');
    print('Listing Title: ${widget.listingTitle}');
    print('=============================');

    // Also use debugPrint for better visibility
    debugPrint('🔍 CHAT DEBUG: Current User ID: ${widget.currentUserId}');
    debugPrint('🔍 CHAT DEBUG: Other User ID: ${widget.otherUser.id}');
    debugPrint('🔍 CHAT DEBUG: Listing ID: ${widget.listingId}');
    debugPrint('🔍 CHAT DEBUG: Listing Title: ${widget.listingTitle}');

    // Show immediate debug info in UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug: Listing ID = ${widget.listingId}'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });

    _loadMessages();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages(showLoading: false);
    });

    if (widget.listingId != null && widget.listingTitle != null) {
      _checkIfFirstMessage();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFirstMessage() async {
    try {
      final url =
          '$baseUrl/get_messages.php?user_id=${widget.currentUserId}&other_user_id=${widget.otherUser.id}';
      print('Checking first message with URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('First message check response: $data');

        if (data['messages'] != null && (data['messages'] as List).isEmpty) {
          setState(() {
            _messageController.text =
                'Hi, I\'m interested in your property "${widget.listingTitle}". Is it still available?';
          });
        }
      }
    } catch (e) {
      print('Error in _checkIfFirstMessage: $e');
    }
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final url =
          '$baseUrl/get_messages.php?user_id=${widget.currentUserId}&other_user_id=${widget.otherUser.id}';
      debugPrint('📡 Loading messages with URL: $url');

      final response = await http.get(Uri.parse(url));
      debugPrint('📡 Load messages response status: ${response.statusCode}');
      debugPrint('📡 Load messages response body: ${response.body}');

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
      }
    } catch (e) {
      debugPrint('❌ Error in _loadMessages: $e');
      setState(() {
        isLoading = false;
      });
      if (showLoading) {
        _showError('Error loading messages: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    try {
      final requestBody = {
        'sender_id': widget.currentUserId,
        'receiver_id': widget.otherUser.id,
        'message': messageText,
        'listing_id': widget.listingId,
      };

      print('Sending message with data: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/send_message.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Send message response status: ${response.statusCode}');
      print('Send message response body: ${response.body}');

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
      print('Error in _sendMessage: $e');
      _showError('Error sending message: $e');
      _messageController.text = messageText;
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
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
          if (widget.listingId != null)
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                // Show debug info in snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Listing ID: ${widget.listingId}'),
                        Text('Property: ${widget.listingTitle}'),
                      ],
                    ),
                    backgroundColor: primaryColor,
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
              tooltip: 'Property Info',
            ),
          // Add debug button to show all parameters
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Debug Info'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current User ID: ${widget.currentUserId}'),
                      Text('Other User ID: ${widget.otherUser.id}'),
                      Text('Other User Name: ${widget.otherUser.fullName}'),
                      Text('Listing ID: ${widget.listingId ?? "NULL"}'),
                      Text('Listing Title: ${widget.listingTitle ?? "NULL"}'),
                      const SizedBox(height: 10),
                      const Text('API URLs:'),
                      const Text('Get Messages: $baseUrl/get_messages.php'),
                      const Text('Send Message: $baseUrl/send_message.php'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Debug Info',
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
            if (widget.listingId != null && widget.listingTitle != null)
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.home, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Discussing: ${widget.listingTitle} (ID: ${widget.listingId})',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.listingId != null
                                    ? 'Start your conversation about this property'
                                    : 'No messages yet. Start the conversation!',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              if (widget.listingId != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Ask about availability, schedule a viewing, or inquire about details',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Listing ID: ${widget.listingId}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : _buildMessagesList(),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0, right: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(4.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: const TextStyle(
                  fontSize: 15.0,
                  color: Colors.black87,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingMessage(ChatMessage message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0, left: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(4.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: const TextStyle(
                  fontSize: 15.0,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14.0,
                    color: message.isRead ? Colors.blue : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
              padding: const EdgeInsets.all(12.0),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
