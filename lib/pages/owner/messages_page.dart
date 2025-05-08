import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messaging App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MessagesPage(),
    );
  }
}

class MessagesPage extends StatefulWidget {
  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Theme colors
  final Color primaryColor = Colors.indigo;
  final Color accentColor = Colors.indigoAccent;
  final Color backgroundColor = Colors.grey[50]!;
  final Color cardColor = Colors.white;
  final Color selectedChatColor = Colors.indigo.withOpacity(0.1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Messages'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_square),
            onPressed: () {},
            tooltip: 'New Message',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildChatsList(context),
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
          contentPadding: EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildChatsList(BuildContext context) {
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        bool isSelected = index == _selectedIndex;
        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
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
                      studentIndex: index,
                      avatarColor: _getAvatarColor(index),
                    ),
                  ),
                );
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
                            'S${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (index < 3)
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
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Student ${index + 1}',
                                style: TextStyle(
                                  fontWeight: isSelected || index < 3
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 15.0,
                                ),
                              ),
                              Text(
                                '${index == 0 ? 'Now' : '${index}h ago'}',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.0),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Hello, is the room still available?',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected || index < 3
                                        ? Colors.black87
                                        : Colors.grey[600],
                                    fontSize: 13.0,
                                  ),
                                ),
                              ),
                              if (index < 3)
                                Container(
                                  margin: EdgeInsets.only(left: 8.0),
                                  padding: EdgeInsets.all(6.0),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
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
  final int studentIndex;
  final Color avatarColor;

  ChatScreen({required this.studentIndex, required this.avatarColor});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Theme colors
  final Color primaryColor = Colors.indigo;
  final Color accentColor = Colors.indigoAccent;
  final Color backgroundColor = Colors.grey[50]!;
  final Color cardColor = Colors.white;

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
                  backgroundColor: widget.avatarColor,
                  child: Text(
                    'S${widget.studentIndex + 1}',
                    style: TextStyle(
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
            SizedBox(width: 12.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student ${widget.studentIndex + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone),
            onPressed: () {},
            tooltip: 'Call',
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () {},
            tooltip: 'Video Call',
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
            tooltip: 'More Options',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          image: DecorationImage(
            image: AssetImage('assets/chat_bg.png'),
            opacity: 0.05,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child: _buildMessagesList(),
            ),
            // Message input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView(
      padding: EdgeInsets.all(16.0),
      reverse: true,
      controller: _scrollController,
      children: [
        _buildOutgoingMessage(
            'Yes, it\'s available for June. When would you like to visit?',
            '10:10 AM'),
        _buildIncomingMessage(
            'That\'s great! Is it still available for move-in next month?',
            '10:08 AM'),
        _buildOutgoingMessage(
            'The room has a private bathroom, shared kitchen, and includes WiFi.',
            '10:05 AM'),
        _buildIncomingMessage(
            'Can you tell me more about the amenities?', '10:02 AM'),
        _buildOutgoingMessage(
            'Hello! Yes, we have one room available at Hostel 1.', '10:00 AM'),
        _buildIncomingMessage(
            'Hello, I\'m interested in renting a room in your hostel. Do you have any availability?',
            '9:58 AM'),
      ],
    );
  }

  Widget _buildIncomingMessage(String message, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, right: 80.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16.0,
            backgroundColor: widget.avatarColor,
            child: Text('S${widget.studentIndex + 1}',
                style: TextStyle(fontSize: 12.0, color: Colors.white)),
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0),
                      bottomRight: Radius.circular(18.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: TextStyle(fontSize: 14.0),
                  ),
                ),
                SizedBox(height: 4.0),
                Row(
                  children: [
                    Icon(Icons.check, size: 14.0, color: Colors.grey[400]),
                    SizedBox(width: 4.0),
                    Text(
                      time,
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

  Widget _buildOutgoingMessage(String message, String time) {
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0),
                      bottomLeft: Radius.circular(18.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: TextStyle(fontSize: 14.0),
                  ),
                ),
                SizedBox(height: 4.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11.0,
                      ),
                    ),
                    SizedBox(width: 4.0),
                    Icon(Icons.done_all, size: 14.0, color: accentColor),
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
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, -2),
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
          SizedBox(width: 8.0),
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8.0),
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
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
              tooltip: 'Send Message',
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      // Here you would actually send the message
      // For now we're just clearing the input
      _messageController.clear();

      // Scroll to bottom of message list
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
