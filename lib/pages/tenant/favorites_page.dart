import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/models/rental_listing_model.dart';
import 'package:my_app/widgets/rental_card.dart';

class FavoritesPage extends StatefulWidget {
  final User user;

  const FavoritesPage({super.key, required this.user});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // This would typically come from a service or state management solution
  List<RentalListing> allListings = [
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

  List<RentalListing> get favoriteListings {
    return allListings.where((listing) => listing.isFavorite).toList();
  }

  void _toggleFavorite(int index) {
    final listingToUpdate = favoriteListings[index];

    setState(() {
      // Find the listing in the original list
      int originalIndex = allListings.indexWhere(
          (listing) => listing.propertyName == listingToUpdate.propertyName);

      if (originalIndex != -1) {
        allListings[originalIndex].isFavorite =
            !allListings[originalIndex].isFavorite;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return favoriteListings.isEmpty ? _buildEmptyState() : _buildListView();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Save your favorite properties to view them here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate to explore page through parent widget
              // This would be handled better with state management
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Go to Explore tab to view properties')),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Browse Properties'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.favorite, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Your Favorite Properties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteListings.length,
            itemBuilder: (context, index) {
              return RentalCard(
                listing: favoriteListings[index],
                onFavoriteToggle: () => _toggleFavorite(index),
              );
            },
          ),
        ),
      ],
    );
  }
}
