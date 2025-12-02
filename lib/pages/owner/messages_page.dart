import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:my_app/config/api_config.dart'; // Adjust path as needed

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

  // Background color
  final Color backgroundColor = Colors.grey[50]!;

  // REMOVE THIS LINE - No longer needed
  // static const String baseUrl = 'http://192.168.0.11/smartstay';

  @override
  void initState() {
    super.initState();
    _loadConversations();
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
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.get(
        Uri.parse(
            ApiConfig.getConversationsUrlWithUserId(widget.currentUserId)),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF190152),
                  const Color(0xFF2D1B69),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chat with your tenants',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
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
      ),
    );
  }

  // Widget _buildSearchBar() {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: TextField(
  //       controller: _searchController,
  //       decoration: InputDecoration(
  //         hintText: 'Search messages',
  //         hintStyle: TextStyle(color: Colors.grey[400]),
  //         prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(30.0),
  //           borderSide: BorderSide.none,
  //         ),
  //         filled: true,
  //         fillColor: Colors.grey[100],
  //         contentPadding: const EdgeInsets.symmetric(vertical: 0),
  //       ),
  //       onChanged: (value) {
  //         setState(() {
  //           // You can implement search functionality here
  //         });
  //       },
  //     ),
  //   );
  // }

  Widget _buildChatsList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        bool isSelected = index == _selectedIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.06),
                blurRadius: isSelected ? 15 : 10,
                spreadRadius: isSelected ? 2 : 0,
                offset: const Offset(0, 3),
              ),
            ],
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    width: 2)
                : null,
          ),
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
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                _getAvatarColor(index),
                                _getAvatarColor(index).withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getAvatarColor(index).withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.transparent,
                            child: Text(
                              conversation.name.isNotEmpty
                                  ? conversation.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        // Online/unread indicator with pulsing effect
                        if (conversation.unread > 0)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF66BB6A)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50)
                                        .withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
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
                                    fontWeight: conversation.unread > 0
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 17,
                                    color: Colors.black87,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: conversation.unread > 0
                                      ? Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  conversation.time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: conversation.unread > 0
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[600],
                                    fontWeight: conversation.unread > 0
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conversation.lastMessage,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: conversation.unread > 0
                                        ? Colors.black87
                                        : Colors.grey[600],
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: conversation.unread > 0
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (conversation.unread > 0) ...[
                                const SizedBox(width: 12),
                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).primaryColor,
                                        Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      conversation.unread > 99
                                          ? '99+'
                                          : conversation.unread.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.15),
                  Theme.of(context).primaryColor.withOpacity(0.08),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 90,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Your messages with tenants will appear here',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
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

  // Background color
  final Color backgroundColor = Colors.grey[50]!;

  // REMOVE THIS LINE - No longer needed
  // static const String baseUrl = 'http://192.168.0.11/smartstay';

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
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.get(
        Uri.parse(ApiConfig.getMessagesUrlWithParams(
            widget.currentUserId, widget.otherUser.id)),
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
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.post(
        Uri.parse(ApiConfig.sendMessageUrl),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.arrow_back, size: 20, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.transparent,
                      child: Text(
                        widget.otherUser.fullName.isNotEmpty
                            ? widget.otherUser.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
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
                        fontSize: 17,
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
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF190152),
                  const Color(0xFF2D1B69),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
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
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start the conversation!',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildMessagesList(),
              ),
              // Message input
              _buildMessageInput(),
            ],
          ),
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
      padding: const EdgeInsets.only(bottom: 18, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              child: Text(
                widget.otherUser.fullName.isNotEmpty
                    ? widget.otherUser.fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                      bottomLeft: Radius.circular(6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    _formatMessageTime(message.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
      padding: const EdgeInsets.only(bottom: 18, left: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.35),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        message.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 17,
                        color: message.isRead
                            ? Theme.of(context).primaryColor
                            : Colors.grey[500],
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14),
                    prefixIcon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _sendMessage,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
