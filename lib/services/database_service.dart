import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/models/listing.dart';
// ADD THIS IMPORT
import 'package:my_app/config/api_config.dart'; // Adjust path as needed

class DatabaseService {
  // REMOVE THESE LINES - No longer needed
  // static const String _baseUrl = 'http://192.168.0.11/smartstay';

  // UPDATED: Use API config instead
  String get baseUrl => ApiConfig.baseUrl;

  static const Duration _timeout = Duration(seconds: 30);

  Future<String?> get currentUserId async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  Future<bool> testConnection() async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http
          .get(Uri.parse(ApiConfig.testConnectionUrl))
          .timeout(_timeout);
      print('Connection test response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
    };
  }

  Future<List<String>> uploadImages(
    List<String> filePaths,
    String userId,
  ) async {
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
          'POST',
          // UPDATED: Use API config instead of hardcoded URL
          Uri.parse(ApiConfig.uploadImageUrl),
        );
        request.headers.addAll({'Accept': 'application/json'});
        request.fields['user_id'] = userId;
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            filename: fileName,
          ),
        );

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
            'Upload failed: ${parsedResponse['error'] ?? 'Unknown error'}',
          );
        }
      } catch (e) {
        throw Exception('Failed to upload image ${basename(filePath)}: $e');
      }
    }

    return imageUrls;
  }

  Future<List<String>> uploadVideos(
    List<String> filePaths,
    String userId,
  ) async {
    List<String> videoUrls = [];

    for (String filePath in filePaths) {
      try {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('File does not exist: $filePath');
        }
        if (await file.length() == 0) {
          throw Exception('File is empty: $filePath');
        }

        // Check file size (limit to 100MB for videos)
        final fileSize = await file.length();
        if (fileSize > 100 * 1024 * 1024) {
          throw Exception('Video file size exceeds 100MB limit');
        }

        final fileName = basename(file.path);
        var request = http.MultipartRequest(
          'POST',
          // UPDATED: Use API config instead of hardcoded URL
          Uri.parse(ApiConfig.uploadVideoUrl),
        );
        request.headers.addAll({'Accept': 'application/json'});
        request.fields['user_id'] = userId;
        request.files.add(
          await http.MultipartFile.fromPath(
            'video',
            file.path,
            filename: fileName,
          ),
        );

        var streamedResponse = await request.send().timeout(
          const Duration(minutes: 5),
          onTimeout: () {
            throw TimeoutException('Video upload timeout');
          },
        );

        var responseBody = await streamedResponse.stream.bytesToString();
        final parsedResponse = json.decode(responseBody);

        if (parsedResponse['success'] == true) {
          final videoUrl = parsedResponse['image_url'];
          if (videoUrl != null && videoUrl.isNotEmpty) {
            videoUrls.add(videoUrl);
          } else {
            throw Exception('Empty video URL returned');
          }
        } else {
          throw Exception(
            'Upload failed: ${parsedResponse['error'] ?? 'Unknown error'}',
          );
        }
      } catch (e) {
        throw Exception('Failed to upload video ${basename(filePath)}: $e');
      }
    }

    return videoUrls;
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
            // UPDATED: Use API config instead of hardcoded URL
            Uri.parse(ApiConfig.addListingUrl),
            headers: _getHeaders(),
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      final responseData = json.decode(response.body);
      if (response.statusCode != 200 || responseData['success'] != true) {
        throw Exception(
          'Failed to add listing: ${responseData['error'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Error adding listing: $e');
    }
  }

  Future<Map<String, dynamic>> getListings({
    int page = 1,
    String? status,
    int? userId,
  }) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      String url = ApiConfig.getListingsUrl;
      List<String> queryParams = [];

      queryParams.add('page=$page');

      if (status != null && status != 'All') {
        queryParams.add('status=${status.toLowerCase()}');
      }

      if (userId != null) {
        queryParams.add('user_id=$userId');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('🌐 Making request to: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: _getHeaders(),
          )
          .timeout(_timeout);

      print('📡 Response status: ${response.statusCode}');
      print('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          if (data is Map<String, dynamic>) {
            return data;
          } else {
            throw Exception(
                'Invalid response format: expected Map but got ${data.runtimeType}');
          }
        } catch (e) {
          print('❌ JSON parsing error: $e');
          throw Exception('Failed to parse server response: $e');
        }
      } else {
        String errorMessage = 'Server returned status ${response.statusCode}';

        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('error')) {
            errorMessage += ': ${errorData['error']}';
          }
        } catch (_) {
          errorMessage += ': ${response.body}';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Exception in getListings: $e');

      if (e is SocketException) {
        throw Exception(
            'Network error: Please check your internet connection and server availability.');
      } else if (e is TimeoutException) {
        throw Exception(
            'Request timeout: Server is taking too long to respond.');
      } else if (e is FormatException) {
        throw Exception('Data format error: Invalid server response.');
      } else if (e.toString().contains('Connection refused')) {
        throw Exception(
            'Connection refused: Please check if the server is running on $baseUrl');
      } else {
        throw Exception('Error loading listings: $e');
      }
    }
  }

  Future<Map<String, int>> getListingsCount(int userId) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.get(
        Uri.parse(ApiConfig.getListingsCountUrlWithUserId(userId)),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'active': data['active'] ?? 0,
          'inactive': data['inactive'] ?? 0,
          'total': data['total'] ?? 0,
        };
      } else {
        throw Exception('Failed to load listings count');
      }
    } catch (e) {
      print('Error loading listings count: $e');
      return {'active': 0, 'inactive': 0, 'total': 0};
    }
  }

  Future<bool> updateListing(
      Listing listing, List<String> deletedMediaUrls) async {
    try {
      final userId = await currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final Map<String, dynamic> data = {
        'listing_id': listing.id,
        'user_id': userId,
        'title': listing.title,
        'address': listing.address,
        'postcode': listing.postcode,
        'price': listing.price,
        'bedrooms': listing.bedrooms,
        'bathrooms': listing.bathrooms,
        'area_sqft': listing.areaSqft,
        'description': listing.description,
        'available_from': listing.availableFrom.toIso8601String().split('T')[0],
        'minimum_tenure': listing.minimumTenure,
        'deleted_media': deletedMediaUrls,
        'new_media': [],
      };

      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.post(
        Uri.parse(ApiConfig.updateListingUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      } else {
        throw Exception('Failed to update listing: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating listing: $e');
      return false;
    }
  }

  Future<Listing?> getSingleListing(String listingId) async {
    try {
      final userId = await currentUserId;

      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.get(
        Uri.parse(ApiConfig.getSingleListingUrlWithParams(listingId, userId!)),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true && result['listing'] != null) {
          return Listing.fromJson(result['listing']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting single listing: $e');
      return null;
    }
  }

  Future<bool> updateListingStatus(int listingId, String status) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.post(
        Uri.parse(ApiConfig.updateListingStatusUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'listing_id': listingId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating listing status: $e');
      return false;
    }
  }

  Future<bool> deleteListing(int listingId) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.post(
        Uri.parse(ApiConfig.deleteListingUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'listing_id': listingId,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleting listing: $e');
      return false;
    }
  }
}
