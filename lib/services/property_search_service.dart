// property_search_service.dart - Updated with image URLs

import 'dart:convert';
import 'package:http/http.dart' as http;

// Enhanced Location model with property count
class SearchLocation {
  final int id;
  final String name;
  final String? displayName;
  final int propertyCount;
  final int searchCount;
  final String? subtitle;

  SearchLocation({
    required this.id,
    required this.name,
    this.displayName,
    this.propertyCount = 0,
    this.searchCount = 0,
    this.subtitle,
  });

  factory SearchLocation.fromJson(Map<String, dynamic> json) {
    return SearchLocation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name'],
      propertyCount: json['property_count'] ?? 0,
      searchCount: json['search_count'] ?? 0,
      subtitle: json['subtitle'],
    );
  }

  String get title => displayName ?? name;
}

// Updated Property model with image URLs
class PropertyListing {
  final int id;
  final int userId;
  final String title;
  final String address;
  final String postcode;
  final String? description;
  final double price;
  final int bedrooms;
  final int bathrooms;
  final int areaSqft;
  final String availableFrom;
  final String minimumTenure;
  final String status;
  final String? formattedPrice;
  final String? formattedDate;
  final String? locationMatch;
  final List<String> imageUrls; // Added image URLs

  PropertyListing({
    required this.id,
    required this.userId,
    required this.title,
    required this.address,
    required this.postcode,
    this.description,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqft,
    required this.availableFrom,
    required this.minimumTenure,
    required this.status,
    this.formattedPrice,
    this.formattedDate,
    this.locationMatch,
    required this.imageUrls,
  });

  factory PropertyListing.fromJson(Map<String, dynamic> json) {
    return PropertyListing(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      address: json['address'] ?? '',
      postcode: json['postcode'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      areaSqft: json['area_sqft'] ?? 0,
      availableFrom: json['available_from'] ?? '',
      minimumTenure: json['minimum_tenure'] ?? '',
      status: json['status'] ?? 'active',
      formattedPrice: json['formatted_price'],
      formattedDate: json['formatted_date'],
      locationMatch: json['location_match'],
      imageUrls: (json['image_urls'] as List<dynamic>?)
              ?.map((url) => url.toString())
              .toList() ??
          [],
    );
  }
}

// Property search response
class PropertySearchResponse {
  final bool success;
  final Map<String, dynamic>? location;
  final List<PropertyListing> properties;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PropertySearchResponse({
    required this.success,
    this.location,
    required this.properties,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PropertySearchResponse.fromJson(Map<String, dynamic> json) {
    return PropertySearchResponse(
      success: json['success'] ?? false,
      location: json['location'],
      properties: (json['properties'] as List?)
              ?.map((item) => PropertyListing.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}

class PropertySearchService {
  // Change this to your XAMPP server URL
  static const String baseUrl = 'http://192.168.0.27/smartstay';

  // For Android emulator, use: http://10.0.2.2/property_search
  // For iOS simulator, use: http://127.0.0.1/property_search
  // For real device, use your computer's IP address

  // Search locations with property count
  Future<List<SearchLocation>> searchLocationsWithCount({
    String query = '',
    int limit = 5,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/search_locations_with_count.php').replace(
        queryParameters: {
          'q': query,
          'limit': limit.toString(),
        },
      );

      print('🔍 Searching locations with count: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return (jsonData['results'] as List)
              .map((item) => SearchLocation.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ Search error: $e');
      return [];
    }
  }

  // Search properties by location - using enhanced API
  Future<PropertySearchResponse> searchPropertiesByLocation({
    int? locationId,
    String? locationName,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (locationId != null) {
        queryParams['location_id'] = locationId.toString();
      }
      if (locationName != null && locationName.isNotEmpty) {
        queryParams['location_name'] = locationName;
      }

      // Use the enhanced API endpoint
      final uri =
          Uri.parse('$baseUrl/enhanced_search_properties_by_location.php')
              .replace(queryParameters: queryParams);

      print('🏠 Searching properties: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Properties response status: ${response.statusCode}');
      print('📄 Properties response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PropertySearchResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to search properties: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Property search error: $e');
      return PropertySearchResponse(
        success: false,
        properties: [],
        total: 0,
        page: page,
        limit: limit,
        totalPages: 0,
      );
    }
  }

  // Get property details
  Future<PropertyListing?> getPropertyDetails(int propertyId) async {
    try {
      final uri = Uri.parse('$baseUrl/get_property_details.php').replace(
        queryParameters: {
          'id': propertyId.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['property'] != null) {
          return PropertyListing.fromJson(jsonData['property']);
        }
      }

      return null;
    } catch (e) {
      print('❌ Get property details error: $e');
      return null;
    }
  }
}
