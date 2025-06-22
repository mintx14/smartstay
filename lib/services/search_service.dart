// search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchLocation {
  final int id;
  final String name;
  final String? displayName;

  SearchLocation({
    required this.id,
    required this.name,
    this.displayName,
  });

  factory SearchLocation.fromJson(Map<String, dynamic> json) {
    return SearchLocation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name'],
    );
  }

  String get title => displayName ?? name;
}

class SearchResponse {
  final bool success;
  final String query;
  final List<SearchLocation> results;
  final int total;

  SearchResponse({
    required this.success,
    required this.query,
    required this.results,
    required this.total,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      success: json['success'] ?? false,
      query: json['query'] ?? '',
      results: (json['results'] as List?)
              ?.map((item) => SearchLocation.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}

class LocationSearchService {
  // Change this to your XAMPP server URL
  static const String baseUrl = 'http://192.168.0.27/smartstay';

  // For Android emulator, use: http://10.0.2.2/property_search
  // For iOS simulator, use: http://127.0.0.1/property_search
  // For real device, use your computer's IP address

  // Search locations
  Future<SearchResponse> searchLocations({
    String query = '',
    int limit = 10,
    bool suggestionsOnly = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/search_locations.php').replace(
        queryParameters: {
          'q': query,
          'limit': limit.toString(),
          if (suggestionsOnly) 'suggestions': '1',
        },
      );

      print('🔍 Searching locations: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 Search response status: ${response.statusCode}');
      print('📄 Search response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SearchResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to search locations: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Search error: $e');
      return SearchResponse(
        success: false,
        query: query,
        results: [],
        total: 0,
      );
    }
  }

  // Get popular location suggestions
  Future<List<SearchLocation>> getPopularSuggestions() async {
    try {
      final uri = Uri.parse('$baseUrl/get_popular_locations.php');

      print('🌟 Getting popular suggestions: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 Suggestions response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return (jsonData['suggestions'] as List)
              .map((item) => SearchLocation.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ Suggestions error: $e');
      return [];
    }
  }

  // Debounced search for real-time suggestions
  static Future<void> delayedSearch(Duration delay) async {
    await Future.delayed(delay);
  }
}
