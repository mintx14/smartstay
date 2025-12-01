import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
// ADD THIS IMPORT
import 'package:my_app/config/api_config.dart'; // Adjust path as needed

class PropertyService {
  // REMOVE THESE LINES - No longer needed
  // static const String _baseUrl = 'http://192.168.0.11/smartstay';

  // UPDATED: Use API config instead
  String get baseUrl => ApiConfig.baseUrl;

  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
    };
  }

  // Get all public listings with search and pagination
  Future<Map<String, dynamic>> getAllListings({
    int page = 1,
    int limit = 10,
    String? searchQuery,
    String? location,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Add optional search and filter parameters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice.toString();
      }
      if (bedrooms != null) {
        queryParams['bedrooms'] = bedrooms.toString();
      }
      if (bathrooms != null) {
        queryParams['bathrooms'] = bathrooms.toString();
      }

      // UPDATED: Use API config instead of hardcoded URL
      final uri = Uri.parse(ApiConfig.getAllListingsUrl)
          .replace(queryParameters: queryParams);
      final request = http.Request('GET', uri);
      request.headers.addAll(_getHeaders());

      final response = await _sendRequest(request);
      final responseData = json.decode(response);

      if (!responseData['success']) {
        throw Exception(
            'Server error: ${responseData['error'] ?? 'Unknown error'}');
      }

      if (!responseData.containsKey('listings') ||
          responseData['listings'] is! List) {
        throw Exception('Invalid response format: missing or invalid listings');
      }

      return _processListingsResponse(responseData);
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'Network error: Please check your internet connection.');
      } else if (e is FormatException) {
        throw Exception('Data format error: Invalid server response.');
      } else if (e.toString().contains('timeout')) {
        throw Exception(
            'Request timeout: Server is taking too long to respond.');
      } else {
        throw Exception('Error fetching listings: $e');
      }
    }
  }

  // Get featured/recent listings for homepage highlights
  Future<List<dynamic>> getFeaturedListings({int limit = 5}) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
      };

      // UPDATED: Use API config instead of hardcoded URL
      final uri = Uri.parse(ApiConfig.getFeaturedListingsUrl)
          .replace(queryParameters: queryParams);
      final request = http.Request('GET', uri);
      request.headers.addAll(_getHeaders());

      final response = await _sendRequest(request);
      final responseData = json.decode(response);

      if (!responseData['success']) {
        throw Exception(
            'Server error: ${responseData['error'] ?? 'Unknown error'}');
      }

      if (!responseData.containsKey('listings') ||
          responseData['listings'] is! List) {
        throw Exception('Invalid response format: missing or invalid listings');
      }

      return _processFeaturedListings(responseData['listings']);
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'Network error: Please check your internet connection.');
      } else if (e is FormatException) {
        throw Exception('Data format error: Invalid server response.');
      } else if (e.toString().contains('timeout')) {
        throw Exception(
            'Request timeout: Server is taking too long to respond.');
      } else {
        throw Exception('Error fetching featured listings: $e');
      }
    }
  }

  // Get property details by ID
  Future<Map<String, dynamic>> getPropertyDetails(int propertyId) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final uri = Uri.parse(ApiConfig.getPropertyDetailsUrl)
          .replace(queryParameters: {'id': propertyId.toString()});
      final request = http.Request('GET', uri);
      request.headers.addAll(_getHeaders());

      final response = await _sendRequest(request);
      final responseData = json.decode(response);

      if (!responseData['success']) {
        throw Exception(
            'Server error: ${responseData['error'] ?? 'Property not found'}');
      }

      return _processPropertyDetails(responseData['property']);
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'Network error: Please check your internet connection.');
      } else if (e is FormatException) {
        throw Exception('Data format error: Invalid server response.');
      } else if (e.toString().contains('timeout')) {
        throw Exception(
            'Request timeout: Server is taking too long to respond.');
      } else {
        throw Exception('Error fetching property details: $e');
      }
    }
  }

  // Search properties with autocomplete suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.isEmpty || query.length < 2) return [];

      // UPDATED: Use API config instead of hardcoded URL
      final uri = Uri.parse(ApiConfig.getSearchSuggestionsUrl)
          .replace(queryParameters: {'query': query});
      final request = http.Request('GET', uri);
      request.headers.addAll(_getHeaders());

      final response = await _sendRequest(request);
      final responseData = json.decode(response);

      if (responseData['success'] && responseData['suggestions'] is List) {
        return List<String>.from(responseData['suggestions']);
      }
      return [];
    } catch (e) {
      print('Error fetching search suggestions: $e');
      return [];
    }
  }

  // Helper method to send HTTP requests with retry logic
  Future<String> _sendRequest(http.Request request) async {
    final client = http.Client();
    try {
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          final streamedResponse = await client.send(request).timeout(_timeout);
          final responseBody = await streamedResponse.stream.bytesToString();

          if (streamedResponse.statusCode == 200) {
            return responseBody;
          } else {
            print('Server returned status ${streamedResponse.statusCode}');
          }
        } catch (e) {
          print('Attempt $attempt failed: $e');
          if (attempt == _maxRetries - 1) rethrow;
        }
      }
      throw Exception('Failed after $_maxRetries attempts');
    } finally {
      client.close();
    }
  }

  // Process listings response for pagination
  Map<String, dynamic> _processListingsResponse(
      Map<String, dynamic> responseData) {
    final listings = responseData['listings'] as List<dynamic>;

    for (var listing in listings) {
      if (listing is Map<String, dynamic>) {
        _processListingData(listing);
      }
    }

    return {
      'listings': listings,
      'page': responseData['current_page'] ?? 1,
      'pages': responseData['pages'] ?? 1,
      'total': responseData['total'] ?? 0,
      'has_more': responseData['has_more'] ?? false,
    };
  }

  // Process featured listings
  List<dynamic> _processFeaturedListings(List<dynamic> listings) {
    for (var listing in listings) {
      if (listing is Map<String, dynamic>) {
        _processListingData(listing);
      }
    }
    return listings;
  }

  // Process property details
  Map<String, dynamic> _processPropertyDetails(Map<String, dynamic> property) {
    _processListingData(property);
    return property;
  }

  // Common listing data processing
  void _processListingData(Map<String, dynamic> listing) {
    // Process image URLs - handle both existing data and empty arrays from backend
    if (listing.containsKey('image_urls')) {
      if (listing['image_urls'] is String && listing['image_urls'].isNotEmpty) {
        try {
          List<dynamic> imageUrls = json.decode(listing['image_urls']);
          final validUrls = <String>[];
          for (var url in imageUrls) {
            if (url is String && url.isNotEmpty) {
              try {
                final uri = Uri.parse(url);
                if (uri.hasScheme &&
                    (uri.scheme == 'http' || uri.scheme == 'https')) {
                  validUrls.add(url);
                }
              } catch (_) {}
            }
          }
          listing['image_urls'] = validUrls;
        } catch (e) {
          listing['image_urls'] = [];
        }
      } else if (listing['image_urls'] is List) {
        // Already processed by backend or empty array
        listing['image_urls'] = listing['image_urls'] ?? [];
      } else {
        listing['image_urls'] = [];
      }
    } else {
      listing['image_urls'] = [];
    }

    // Process amenities - handle both existing data and empty arrays from backend
    if (listing.containsKey('amenities')) {
      if (listing['amenities'] is String && listing['amenities'].isNotEmpty) {
        try {
          listing['amenities'] = json.decode(listing['amenities']);
        } catch (e) {
          listing['amenities'] = [];
        }
      } else if (listing['amenities'] is List) {
        // Already processed by backend or empty array
        listing['amenities'] = listing['amenities'] ?? [];
      } else {
        listing['amenities'] = [];
      }
    } else {
      listing['amenities'] = [];
    }

    // Ensure numeric fields are properly typed
    listing['id'] = _parseInt(listing['id']);
    listing['price'] = _parseDouble(listing['price']);
    listing['bedrooms'] = _parseInt(listing['bedrooms']);
    listing['bathrooms'] = _parseInt(listing['bathrooms']);
    listing['area_sqft'] = _parseInt(listing['area_sqft']);

    // Handle minimum_tenure as string (VARCHAR in your database)
    listing['minimum_tenure'] =
        listing['minimum_tenure']?.toString() ?? '6 months';

    // Handle user_id as string (VARCHAR in your database)
    listing['user_id'] = listing['user_id']?.toString() ?? '';

    // Set default values for optional fields
    listing['property_type'] = listing['property_type'] ?? 'apartment';
    listing['furnishing_status'] =
        listing['furnishing_status'] ?? 'unfurnished';
    listing['parking_spaces'] = _parseInt(listing['parking_spaces'] ?? 0);

    // Handle owner information (may be null from your backend)
    listing['owner_name'] = listing['owner_name'];
    listing['owner_phone'] = listing['owner_phone'];
    listing['owner_email'] = listing['owner_email'];
  }

  // Helper methods for parsing
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Get property statistics (optional - for dashboard)
  Future<Map<String, dynamic>> getPropertyStats() async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final uri = Uri.parse(ApiConfig.getPropertyStatsUrl);
      final request = http.Request('GET', uri);
      request.headers.addAll(_getHeaders());

      final response = await _sendRequest(request);
      final responseData = json.decode(response);

      if (responseData['success']) {
        return responseData['stats'] ?? {};
      }
      return {};
    } catch (e) {
      print('Error fetching property stats: $e');
      return {};
    }
  }
}
