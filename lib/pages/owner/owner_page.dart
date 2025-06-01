import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'listings_page.dart';
import 'reservations_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';
import 'add_listing_page.dart';

class OwnerPage extends StatefulWidget {
  final User user;

  const OwnerPage({super.key, required this.user});

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  int _currentIndex = 0;

  // List of screens to be displayed based on the selected index
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize the screens list
    _screens = [
      _buildDashboardScreen(), // Your main dashboard screen
      const ListingsPage(),
      const ReservationsPage(),
      const MessagesPage(),
      ProfilePage(user: widget.user), // Pass user data to profile page
    ];
  }

  // Logout function
  Future<void> _logout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate back to login page
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // Create the dashboard screen (main content)
  Widget _buildDashboardScreen() {
    return Column(
      children: [
        // Quick Stats Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildStatCard('Properties', '8', Icons.home),
              const SizedBox(width: 10),
              _buildStatCard('Bookings', '24', Icons.calendar_today),
              const SizedBox(width: 10),
              _buildStatCard('Revenue', '\$5.2K', Icons.attach_money),
            ],
          ),
        ),

        // Quick Access Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickAccessButton(
                    'Add Listing',
                    Icons.add_home,
                    Colors.indigo,
                    () {
                      // Navigate to add listing page
                      setState(() {
                        _currentIndex = 1; // Switch to Listings tab
                      });
                      // You could also navigate to a specific add listing page
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const AddListingPage(),
                      ));
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAccessButton(
                    'Manage Bookings',
                    Icons.book_online,
                    Colors.teal,
                    () {
                      // Navigate to reservations page
                      setState(() {
                        _currentIndex = 2; // Switch to Reservations tab
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAccessButton(
                    'Maintenance',
                    Icons.build,
                    Colors.amber.shade700,
                    () {
                      // Navigate to maintenance page
                      // This could be a separate page or part of listings management
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recent Activity Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to notifications or activity page
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),

        // Activity List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildActivityItem(
                'New booking request',
                'Sunshine Apartments - Unit 302',
                '10 minutes ago',
                Icons.notifications,
                Colors.orange,
              ),
              _buildActivityItem(
                'Payment received',
                'Student Village - Unit 5B',
                '2 hours ago',
                Icons.payment,
                Colors.green,
              ),
              _buildActivityItem(
                'Maintenance request',
                'Campus View - Unit 201',
                '5 hours ago',
                Icons.build,
                Colors.red,
              ),
              _buildActivityItem(
                'Tenant message',
                'John from Student Village',
                'Yesterday',
                Icons.mail,
                Colors.blue,
              ),
              _buildActivityItem(
                'Lease ending soon',
                'Sunshine Apartments - Unit 103',
                '2 days ago',
                Icons.event,
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build a stat card widget
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 5.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF190152), size: 24),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF190152),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a quick access button widget
  Widget _buildQuickAccessButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build an activity item widget
  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          // Handle tap on activity item
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // App Bar with App Name and Logout Button
      appBar: AppBar(
        backgroundColor: const Color(0xFF190152),
        elevation: 0,
        title: const Text(
          'SmartStay Owner',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Welcome message with user's first name
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Hello, ${widget.user.fullName.split(' ')[0]}!',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        // Display the selected screen based on current index
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF190152),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Reservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
