import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

// Student Rental Listing Model
class RentalListing {
  final String imageUrl;
  final String location;
  final String propertyName;
  final String distance;
  final double price;
  final List<String> amenities;
  final double rating;
  final bool isFavorite;

  RentalListing({
    required this.imageUrl,
    required this.location,
    required this.propertyName,
    required this.distance,
    required this.price,
    required this.amenities,
    required this.rating,
    this.isFavorite = false,
  });
}

// Rental Card Widget
class RentalCard extends StatelessWidget {
  final RentalListing listing;

  const RentalCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  listing.imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 220,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      color: Colors.grey[300],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red[300], size: 40),
                            const SizedBox(height: 8),
                            Text("Couldn't load image",
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.thumb_up, color: Color(0xFF190152), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Student Favorite',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  listing.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: listing.isFavorite ? Colors.red : Colors.white,
                ),
              ),
            ],
          ),

          // Property Details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      listing.location,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          listing.rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  listing.propertyName,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  listing.distance,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                // Amenities
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: listing.amenities.map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        amenity,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF190152)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: '\$${listing.price} ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const TextSpan(
                        text: '/ month',
                        style: TextStyle(color: Colors.grey),
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
}
