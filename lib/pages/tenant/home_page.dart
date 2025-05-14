import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/models/rental_listing_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/widgets/rental_card.dart';
// Import your screen classes
import 'favorites_page.dart';
import 'map_page.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  List<RentalListing> dummyListings = [
    RentalListing(
      imageUrl:
          'https://www.livehome3d.com/assets/img/articles/design-house/how-to-design-a-house.jpg',
      location: 'Near State University',
      propertyName: 'Sunshine Apartments',
      distance: '0.5 miles from campus',
      price: 450,
      amenities: ['Wifi', 'Furnished', 'Utilities included'],
      rating: 4.7,
      isFavorite: true,
    ),
    RentalListing(
      imageUrl:
          'https://www.livehome3d.com/assets/img/articles/design-house/how-to-design-a-house.jpg',
      location: 'Downtown',
      propertyName: 'Student Village',
      distance: '1.2 miles from campus',
      price: 380,
      amenities: ['Laundry', 'Study rooms', 'Gym'],
      rating: 4.5,
      isFavorite: false,
    ),
    RentalListing(
      imageUrl:
          'https://www.livehome3d.com/assets/img/articles/design-house/how-to-design-a-house.jpg',
      location: 'University District',
      propertyName: 'Campus View',
      distance: '0.3 miles from campus',
      price: 520,
      amenities: ['Private bathroom', 'Bike storage', 'Security'],
      rating: 4.8,
      isFavorite: true,
    ),
  ];

  // List of screens to be displayed based on the selected index
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize the screens list
    _screens = [
      _buildExploreScreen(), // Your existing home/explore screen content
      FavoritesPage(user: widget.user), // Pass user if needed
      MapPage(user: widget.user),
      MessagesScreen(), // Pass user if needed
      ProfileScreen(user: widget.user), // Pass user if needed
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

  // Create the explore screen (original home content)
  Widget _buildExploreScreen() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search for student housing',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Property Listings
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dummyListings.length,
            itemBuilder: (context, index) {
              final listing = dummyListings[index];
              return RentalCard(listing: listing);
            },
          ),
        ),
      ],
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
          'SmartStay',
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
            icon: Icon(Icons.search),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon,
      {bool isSelected = false}) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 24,
              height: 2,
              color: Colors.blue,
            ),
        ],
      ),
    );
  }
}
