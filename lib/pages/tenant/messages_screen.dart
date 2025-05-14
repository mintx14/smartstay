import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample message data
    final List<MessagePreview> messages = [
      MessagePreview(
        name: 'Sunshine Apartments',
        lastMessage: 'Your application has been received!',
        time: '10:30 AM',
        unread: 2,
        avatarUrl:
            'https://www.livehome3d.com/assets/img/articles/design-house/how-to-design-a-house.jpg',
      ),
      MessagePreview(
        name: 'Student Village',
        lastMessage: 'Would you like to schedule a tour?',
        time: 'Yesterday',
        unread: 0,
        avatarUrl:
            'https://www.livehome3d.com/assets/img/articles/design-house/how-to-design-a-house.jpg',
      ),
      MessagePreview(
        name: 'Campus View',
        lastMessage: 'We have special rates for students this month!',
        time: 'Mon',
        unread: 1,
        avatarUrl:
            'https://www.livehome3d.com/assets/img/articles/design-house/how-to-design-a-house.jpg',
      ),
      MessagePreview(
        name: 'College Commons',
        lastMessage: 'Thanks for your interest in our property.',
        time: 'Apr 20',
        unread: 0,
        avatarUrl:
            'https://www.livehome3d.com/assets/img/articles/design-house/how-to-design-a-house.jpg',
      ),
    ];

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
                _buildFilterTab('All', isSelected: true),
                _buildFilterTab('Properties'),
                _buildFilterTab('Agents'),
                _buildFilterTab('Roommates'),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageTile(messages[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF190152),
        child: const Icon(Icons.add_comment),
        onPressed: () {
          // Open new message screen
        },
      ),
    );
  }

  Widget _buildFilterTab(String label, {bool isSelected = false}) {
    return Container(
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
    );
  }

  Widget _buildMessageTile(MessagePreview message) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(message.avatarUrl),
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
      onTap: () {
        // Open message conversation
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
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact properties to start a conversation',
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

class MessagePreview {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final String avatarUrl;

  MessagePreview({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.avatarUrl,
  });
}
