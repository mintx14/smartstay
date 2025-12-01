class Listing {
  final String id;
  final String title;
  final String address;
  final String postcode;
  final String description;
  final List<String> imageUrls; // This will contain both images and videos
  final double price;
  final double deposit;
  final int depositMonths; // <--- ADDED THIS
  final int bedrooms;
  final int bathrooms;
  final int areaSqft;
  final DateTime availableFrom;
  final String minimumTenure;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? contractUrl;

  Listing({
    required this.id,
    required this.title,
    required this.address,
    required this.postcode,
    required this.description,
    required this.imageUrls,
    required this.price,
    required this.deposit,
    required this.depositMonths, // <--- ADDED THIS
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqft,
    required this.availableFrom,
    required this.minimumTenure,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.contractUrl,
  });

  // Helper methods to separate images and videos
  List<String> get images => imageUrls
      .where((url) =>
          url.toLowerCase().endsWith('.jpg') ||
          url.toLowerCase().endsWith('.jpeg') ||
          url.toLowerCase().endsWith('.png') ||
          url.toLowerCase().endsWith('.gif') ||
          url.toLowerCase().endsWith('.webp'))
      .toList();

  List<String> get videos => imageUrls
      .where((url) =>
              url.toLowerCase().endsWith('.mp4') ||
              url.toLowerCase().endsWith('.mpeg') ||
              url.toLowerCase().endsWith('.mov') ||
              url.toLowerCase().endsWith('.avi') ||
              url.toLowerCase().endsWith('.wmv') ||
              url.toLowerCase().endsWith('.webm') ||
              url.contains('/videos/') // Check if it's in the videos directory
          )
      .toList();

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      address: json['address'] ?? '',
      postcode: json['postcode'] ?? '',
      description: json['description'] ?? '',
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      deposit: double.tryParse(json['deposit']?.toString() ?? '0') ?? 0.0,

      // <--- ADDED THIS: Parse deposit_months safely
      depositMonths:
          int.tryParse(json['deposit_months']?.toString() ?? '0') ?? 0,

      bedrooms: int.tryParse(json['bedrooms']?.toString() ?? '0') ?? 0,
      bathrooms: int.tryParse(json['bathrooms']?.toString() ?? '0') ?? 0,
      areaSqft: int.tryParse(json['area_sqft']?.toString() ?? '0') ?? 0,
      availableFrom:
          DateTime.tryParse(json['available_from'] ?? '') ?? DateTime.now(),
      minimumTenure: json['minimum_tenure'] ?? '12 months',
      status: json['status'] ?? 'Active',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      contractUrl: json['contract_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'postcode': postcode,
      'description': description,
      'image_urls': imageUrls,
      'price': price,
      'deposit': deposit,
      'deposit_months': depositMonths, // <--- ADDED THIS
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area_sqft': areaSqft,
      'available_from': availableFrom.toIso8601String(),
      'minimum_tenure': minimumTenure,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'contract_url': contractUrl,
    };
  }

  // Getters
  bool get isActive => status.toLowerCase() == 'active';
  bool get isInactive => status.toLowerCase() == 'inactive';

  Listing copyWith({
    String? id,
    String? title,
    String? address,
    String? postcode,
    String? description,
    List<String>? imageUrls,
    double? price,
    double? deposit,
    int? depositMonths, // <--- ADDED THIS
    int? bedrooms,
    int? bathrooms,
    int? areaSqft,
    DateTime? availableFrom,
    String? minimumTenure,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Listing(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      postcode: postcode ?? this.postcode,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      price: price ?? this.price,
      deposit: deposit ?? this.deposit,
      depositMonths: depositMonths ?? this.depositMonths, // <--- ADDED THIS
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      areaSqft: areaSqft ?? this.areaSqft,
      availableFrom: availableFrom ?? this.availableFrom,
      minimumTenure: minimumTenure ?? this.minimumTenure,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
