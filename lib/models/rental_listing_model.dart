class RentalListing {
  final String imageUrl;
  final String location;
  final String propertyName;
  final String distance;
  final double price;
  final List<String> amenities;
  final double rating;
  bool isFavorite;

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

// List of dummy rental listings for testing
List<RentalListing> getDummyListings() {
  return [
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
    RentalListing(
      imageUrl:
          'https://www.livehome3d.com/assets/img/articles/design-house/how-to-design-a-house.jpg',
      location: 'Westside',
      propertyName: 'College Commons',
      distance: '0.8 miles from campus',
      price: 410,
      amenities: ['Parking', 'Pet-friendly', 'Pool'],
      rating: 4.3,
      isFavorite: false,
    ),
    RentalListing(
      imageUrl:
          'https://www.livehome3d.com/assets/img/articles/design-house/how-to-design-a-house.jpg',
      location: 'Eastside',
      propertyName: 'The Graduate',
      distance: '1.5 miles from campus',
      price: 350,
      amenities: ['Balcony', 'Full kitchen', 'Security'],
      rating: 4.1,
      isFavorite: false,
    ),
  ];
}
