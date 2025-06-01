import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/models/listing.dart';

class DatabaseService {
  static const String _baseUrl =
      'http://10.0.2.2/smartstay'; // Android emulator
  String get baseUrl => _baseUrl;

  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3; // Maximum number of retries

  Future<String?> get currentUserId async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  // Future<bool> testConnection() async {
  //   try {
  //     final response = await http
  //         .get(Uri.parse('$baseUrl/test_connection.php'))
  //         .timeout(_timeout);
  //     return response.statusCode == 200;
  //   } catch (e) {
  //     print('Connection test failed: $e');
  //     return false;
  //   }
  // }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
    };
  }

  Future<List<String>> uploadImages(
      List<String> filePaths, String userId) async {
    List<String> imageUrls = [];

    for (String filePath in filePaths) {
      try {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('File does not exist: $filePath');
        }
        if (await file.length() == 0) {
          throw Exception('File is empty: $filePath');
        }

        final fileName = basename(file.path);
        var request = http.MultipartRequest(
            'POST', Uri.parse('$baseUrl/upload_image.php'));
        request.headers.addAll({'Accept': 'application/json'});
        request.fields['user_id'] = userId;
        request.files.add(await http.MultipartFile.fromPath('image', file.path,
            filename: fileName));

        var streamedResponse = await request.send();
        var responseBody = await streamedResponse.stream.bytesToString();
        final parsedResponse = json.decode(responseBody);

        if (parsedResponse['success'] == true) {
          final imageUrl = parsedResponse['image_url'];
          if (imageUrl != null && imageUrl.isNotEmpty) {
            imageUrls.add(imageUrl);
          } else {
            throw Exception('Empty image URL returned');
          }
        } else {
          throw Exception(
              'Upload failed: ${parsedResponse['error'] ?? 'Unknown error'}');
        }
      } catch (e) {
        throw Exception('Failed to upload image ${basename(filePath)}: $e');
      }
    }

    return imageUrls;
  }

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
        'available_from': listing.availableFrom.toIso8601String().split('T')[0],
        'minimum_tenure': listing.minimumTenure,
        'image_urls': listing.imageUrls,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/add_listing.php'),
            headers: _getHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      final responseData = json.decode(response.body);
      if (response.statusCode != 200 || responseData['success'] != true) {
        throw Exception(
            'Failed to add listing: ${responseData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error adding listing: $e');
    }
  }

  Future<Map<String, dynamic>> getListings(
      {int page = 1, String? userId}) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': '10',
      };

      if (userId != null && userId.isNotEmpty) {
        queryParams['user_id'] = userId;
      }

      final uri = Uri.parse('$baseUrl/get_listings.php')
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

      return _processListings(responseData['listings']);
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

  Future<String> _sendRequest(http.Request request) async {
    final client = http.Client();
    try {
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        try {
          final streamedResponse = await client.send(request).timeout(_timeout);
          final responseBody = await streamedResponse.stream.bytesToString();

          if (streamedResponse.statusCode == 200) {
            return responseBody; // ✅ success
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
      client.close(); // ✅ Always close the client in finally
    }
  }

  Map<String, dynamic> _processListings(List<dynamic> listings) {
    for (var listing in listings) {
      if (listing is Map<String, dynamic> &&
          listing.containsKey('image_urls') &&
          listing['image_urls'] is List) {
        final imageUrls = listing['image_urls'] as List;
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
      }
    }

    return {
      'listings': listings,
      'page': listings.isNotEmpty ? listings[0]['page'] ?? 1 : 1,
      'pages': listings.isNotEmpty ? listings[0]['pages'] ?? 1 : 1,
      'total': listings.isNotEmpty ? listings[0]['total'] ?? 0 : 0,
    };
  }
}
