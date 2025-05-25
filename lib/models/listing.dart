class Listing {
  final String id;
  final String title;
  final String address;
  final String postcode;
  final String description;
  final double price;
  final int bedrooms;
  final int bathrooms;
  final int areaSqft;
  final DateTime availableFrom;
  final String minimumTenure;
  final List<String> imageUrls;

  Listing({
    required this.id,
    required this.title,
    required this.address,
    required this.postcode,
    required this.description,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqft,
    required this.availableFrom,
    required this.minimumTenure,
    this.imageUrls = const [],
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'].toString(),
      title: json['title'],
      address: json['address'],
      postcode: json['postcode'],
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      bedrooms: int.parse(json['bedrooms'].toString()),
      bathrooms: int.parse(json['bathrooms'].toString()),
      areaSqft: int.parse(json['area_sqft'].toString()),
      availableFrom: json['available_from'] is String
          ? DateTime.parse(json['available_from'])
          : DateTime.fromMillisecondsSinceEpoch(json['available_from'] * 1000),
      minimumTenure: json['minimum_tenure'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'postcode': postcode,
      'description': description,
      'price': price,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area_sqft': areaSqft,
      'available_from': availableFrom.toIso8601String(),
      'minimum_tenure': minimumTenure,
      'image_urls': imageUrls,
    };
  }
}
