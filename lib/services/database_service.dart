import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/models/listing.dart';

class DatabaseService {
  // Replace with your actual backend URL
  static const String _baseUrl =
      'http://10.0.2.2/smartstay'; // Android emulator
  // Use 'http://localhost/smartstay' for iOS simulator
  // Use your actual IP for physical device: 'http://192.168.1.xxx/smartstay'

  String get baseUrl => _baseUrl;

  // HTTP client with timeout configuration
  static final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 30);

  // Current user ID (you would get this from your auth system)
  Future<String?> get currentUserId async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  // Test server connection
  Future<bool> testConnection() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/test_connection.php'),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Get common headers
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
    };
  }

  // Enhanced image upload with better error handling
  Future<List<String>> uploadImages(
      List<String> filePaths, String userId) async {
    List<String> imageUrls = [];

    for (String filePath in filePaths) {
      try {
        final file = File(filePath);

        // Validate file exists and is readable
        if (!await file.exists()) {
          throw Exception('File does not exist: $filePath');
        }

        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('File is empty: $filePath');
        }

        // Check file size (limit to 5MB)
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('File too large (max 5MB): $filePath');
        }

        final fileName = basename(file.path);
        print('Uploading image: $fileName (${fileSize} bytes)');

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/upload_image.php'),
        );

        // Add headers
        request.headers.addAll({
          'Accept': 'application/json',
        });

        request.fields['user_id'] = userId;

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            filename: fileName,
          ),
        );

        var response = await request.send().timeout(_timeout);
        var responseData = await response.stream.bytesToString();

        print('Upload response for $fileName: $responseData');

        try {
          var parsedResponse = json.decode(responseData);

          if (response.statusCode == 200 && parsedResponse['success'] == true) {
            final imageUrl = parsedResponse['image_url'];
            if (imageUrl != null && imageUrl.isNotEmpty) {
              imageUrls.add(imageUrl);
              print('Successfully uploaded: $imageUrl');
            } else {
              throw Exception('Empty image URL returned');
            }
          } else {
            throw Exception(
                'Upload failed: ${parsedResponse['error'] ?? 'Unknown error'}');
          }
        } catch (jsonError) {
          print('JSON parse error: $jsonError');
          print('Raw response: $responseData');
          throw Exception('Invalid response format from server');
        }
      } catch (e) {
        print('Error uploading image $filePath: $e');
        throw Exception('Failed to upload image ${basename(filePath)}: $e');
      }
    }

    return imageUrls;
  }

  // Enhanced listing addition with better error handling
  Future<void> addListing(Listing listing) async {
    final userId = await currentUserId;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final requestBody = {
        'user_id': userId,
        'title': listing.title,
        'address': listing.address,
        'postcode': listing.postcode,
        'description': listing.description,
        'price': listing.price,
        'bedrooms': listing.bedrooms,
        'bathrooms': listing.bathrooms,
        'area_sqft': listing.areaSqft,
        'available_from': listing.availableFrom
            .toIso8601String()
            .split('T')[0], // Format as YYYY-MM-DD
        'minimum_tenure': listing.minimumTenure,
        'image_urls': listing.imageUrls,
      };

      print('Sending listing data: ${json.encode(requestBody)}');

      final response = await _client
          .post(
            Uri.parse('$baseUrl/add_listing.php'),
            headers: _getHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      print('Add listing response: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 200 || responseData['success'] != true) {
        throw Exception(
            'Failed to add listing: ${responseData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error adding listing: $e');
      rethrow;
    }
  }

  // Enhanced get listings with better error handling and validation
  Future<Map<String, dynamic>> getListings(
      {int page = 1, String? userId}) async {
    try {
      // Build query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': '10',
      };

      // Add user_id filter if requested
      if (userId != null && userId.isNotEmpty) {
        queryParams['user_id'] = userId;
      }

      final uri = Uri.parse('$baseUrl/get_listings.php')
          .replace(queryParameters: queryParams);

      print('Fetching listings from: $uri');

      final response = await _client
          .get(
            uri,
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      print('Get listings response status: ${response.statusCode}');
      print('Get listings response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode}: Failed to fetch listings');
      }

      final responseData = json.decode(response.body);

      if (responseData['success'] != true) {
        throw Exception(
            'Server error: ${responseData['error'] ?? 'Unknown error'}');
      }

      // Validate response structure
      if (!responseData.containsKey('listings') ||
          responseData['listings'] is! List) {
        throw Exception('Invalid response format: missing or invalid listings');
      }

      // Validate and process image URLs
      final listings = responseData['listings'] as List;
      for (var listing in listings) {
        if (listing is Map<String, dynamic> &&
            listing.containsKey('image_urls') &&
            listing['image_urls'] is List) {
          final imageUrls = listing['image_urls'] as List;
          final validUrls = <String>[];

          for (var url in imageUrls) {
            if (url is String && url.isNotEmpty) {
              // Validate URL format
              try {
                final uri = Uri.parse(url);
                if (uri.hasScheme &&
                    (uri.scheme == 'http' || uri.scheme == 'https')) {
                  validUrls.add(url);
                  print('Valid image URL: $url');
                } else {
                  print('Invalid URL scheme: $url');
                }
              } catch (e) {
                print('Invalid URL format: $url - Error: $e');
              }
            }
          }

          listing['image_urls'] = validUrls;
        }
      }

      return {
        'listings': listings,
        'page': responseData['page'] ?? page,
        'pages': responseData['pages'] ?? 1,
        'total': responseData['total'] ?? 0,
      };
    } catch (e) {
      print('Error fetching listings: $e');

      // Provide more specific error messages
      if (e is SocketException) {
        throw Exception(
            'Network error: Unable to connect to server. Please check your internet connection.');
      } else if (e is FormatException) {
        throw Exception('Data format error: Invalid response from server.');
      } else if (e.toString().contains('timeout')) {
        throw Exception(
            'Request timeout: Server is taking too long to respond.');
      } else {
        rethrow;
      }
    }
  }

  // Clean up resources
  void dispose() {
    _client.close();
  }
}
