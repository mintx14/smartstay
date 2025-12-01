class Listing {
  final int id;
  final String userId;
  final String title;
  final String address;
  final String postcode;
  final String? description;
  final double price;
  final double deposit;
  final int bedrooms;
  final int bathrooms;
  final int areaSqft;
  final DateTime availableFrom;
  final String minimumTenure;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional fields with defaults
  final List<String> amenities;
  final String propertyType;
  final String furnishingStatus;
  final int parkingSpaces;
  final String? ownerName;
  final String? ownerPhone;
  final String? ownerEmail;

  Listing({
    required this.id,
    required this.userId,
    required this.title,
    required this.address,
    required this.postcode,
    this.description,
    required this.price,
    required this.deposit,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqft,
    required this.availableFrom,
    required this.minimumTenure,
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.amenities = const [],
    this.propertyType = 'apartment',
    this.furnishingStatus = 'unfurnished',
    this.parkingSpaces = 0,
    this.ownerName,
    this.ownerPhone,
    this.ownerEmail,
  });

  factory Listing.fromJson(Map<String, dynamic> data) {
    print('🔍 Parsing listing: ${data['title']}');

    try {
      return Listing(
        id: _safeInt(data['id']),
        userId: _safeString(data['user_id']),
        title: _safeString(data['title'], 'Untitled Property'),
        address: _safeString(data['address']),
        postcode: _safeString(data['postcode']),
        description: data['description']?.toString(),
        price: _safeDouble(data['price']),
        deposit: _safeDouble(data['deposit']),
        bedrooms: _safeInt(data['bedrooms'], 1),
        bathrooms: _safeInt(data['bathrooms'], 1),
        areaSqft: _safeInt(data['area_sqft']),
        availableFrom: _safeDate(data['available_from']),
        minimumTenure: _safeString(data['minimum_tenure'], '6 months'),
        imageUrls: _safeList(data['image_urls']),
        createdAt: _safeDate(data['created_at']),
        updatedAt: _safeDate(data['updated_at']),
        amenities: _safeList(data['amenities']),
        propertyType: _safeString(data['property_type'], 'apartment'),
        furnishingStatus: _safeString(data['furnishing_status'], 'unfurnished'),
        parkingSpaces: _safeInt(data['parking_spaces']),
        ownerName: data['owner_name']?.toString(),
        ownerPhone: data['owner_phone']?.toString(),
        ownerEmail: data['owner_email']?.toString(),
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing listing: $e');
      print('📄 Data: $data');
      print('📋 Stack: $stackTrace');
      rethrow;
    }
  }

  // Helper methods
  static int _safeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static double _safeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static String _safeString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  static DateTime _safeDate(dynamic value) {
    final defaultDate = DateTime.now();
    if (value == null) return defaultDate;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Handle different date formats from MySQL
        if (value.contains('T')) {
          // ISO format: 2024-01-15T10:30:00
          return DateTime.parse(value);
        } else if (value.contains(' ')) {
          // MySQL datetime: 2024-01-15 10:30:00
          return DateTime.parse(value.replaceAll(' ', 'T'));
        } else {
          // Date only: 2024-01-15
          return DateTime.parse('${value}T00:00:00');
        }
      } catch (e) {
        print('⚠️ Date parse error for "$value": $e');
        return defaultDate;
      }
    }
    return defaultDate;
  }

  static List<String> _safeList(dynamic value) {
    // Since your database doesn't have JSON arrays, just return empty list
    // The PHP backend already sets this to empty array []
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'address': address,
      'postcode': postcode,
      'description': description,
      'price': price,
      'deposit': deposit,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area_sqft': areaSqft,
      'available_from': availableFrom.toIso8601String().split('T')[0],
      'minimum_tenure': minimumTenure,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'amenities': amenities,
      'property_type': propertyType,
      'furnishing_status': furnishingStatus,
      'parking_spaces': parkingSpaces,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'owner_email': ownerEmail,
    };
  }
}
