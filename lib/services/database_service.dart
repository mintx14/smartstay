import 'dart:async';
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
  static const int _maxRetries = 3;

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
      final response = await http
          .get(Uri.parse('$baseUrl/test_connection.php'))
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
          Uri.parse('$baseUrl/upload_image.php'),
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
          Uri.parse('$baseUrl/upload_video.php'),
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

        // Set timeout for video uploads (longer than images)
        var streamedResponse = await request.send().timeout(
          const Duration(minutes: 5),
          onTimeout: () {
            throw TimeoutException('Video upload timeout');
          },
        );

        var responseBody = await streamedResponse.stream.bytesToString();
        final parsedResponse = json.decode(responseBody);

        if (parsedResponse['success'] == true) {
          // Changed to use 'image_url' since we're using the same table structure
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
        'image_urls':
            listing.imageUrls, // This now contains both images and videos
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
      String url = '$baseUrl/get_listings.php';
      List<String> queryParams = [];

      queryParams.add('page=$page');

      if (status != null && status != 'All') {
        queryParams.add('status=${status.toLowerCase()}');
      }

      if (userId != null) {
        queryParams.add('user_id=$userId');
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
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

  Map<String, dynamic> _processListings(List<dynamic> listings) {
    for (var listing in listings) {
      if (listing is Map<String, dynamic>) {
        // Process image URLs
        if (listing.containsKey('image_urls') &&
            listing['image_urls'] is List) {
          final imageUrls = listing['image_urls'] as List;
          final validImageUrls = <String>[];

          for (var url in imageUrls) {
            if (url is String && url.isNotEmpty) {
              try {
                final uri = Uri.parse(url);
                if (uri.hasScheme &&
                    (uri.scheme == 'http' || uri.scheme == 'https')) {
                  validImageUrls.add(url);
                }
              } catch (_) {}
            }
          }
          listing['image_urls'] = validImageUrls;
        }

        // Process video URLs
        if (listing.containsKey('video_urls') &&
            listing['video_urls'] is List) {
          final videoUrls = listing['video_urls'] as List;
          final validVideoUrls = <String>[];

          for (var url in videoUrls) {
            if (url is String && url.isNotEmpty) {
              try {
                final uri = Uri.parse(url);
                if (uri.hasScheme &&
                    (uri.scheme == 'http' || uri.scheme == 'https')) {
                  validVideoUrls.add(url);
                }
              } catch (_) {}
            }
          }
          listing['video_urls'] = validVideoUrls;
        }
      }
    }

    return {
      'listings': listings,
      'page': listings.isNotEmpty ? listings[0]['page'] ?? 1 : 1,
      'pages': listings.isNotEmpty ? listings[0]['pages'] ?? 1 : 1,
      'total': listings.isNotEmpty ? listings[0]['total'] ?? 0 : 0,
    };
  }

  // Update listing status
  // Future<bool> updateListingStatus(int listingId, String status) async {
  //   try {
  //     final response = await http.put(
  //       Uri.parse('$baseUrl/update_listing_status.php?id=$listingId'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({'status': status}),
  //     );

  //     return response.statusCode == 200;
  //   } catch (e) {
  //     print('Error updating listing status: $e');
  //     return false;
  //   }
  // }

  // // Archive a listing (soft delete)
  // Future<bool> archiveListing(int listingId) async {
  //   return await updateListingStatus(listingId, 'archived');
  // }

  // // Activate a listing
  // Future<bool> activateListing(int listingId) async {
  //   return await updateListingStatus(listingId, 'active');
  // }

  // // Deactivate a listing
  // Future<bool> deactivateListing(int listingId) async {
  //   return await updateListingStatus(listingId, 'inactive');
  // }

  // Delete listing permanently
  // Future<bool> deleteListing(int listingId) async {
  //   try {
  //     final response = await http.delete(
  //       Uri.parse('$baseUrl/delete_listing.php?id=$listingId'),
  //     );

  //     return response.statusCode == 200;
  //   } catch (e) {
  //     print('Error deleting listing: $e');
  //     return false;
  //   }
  // }

  // Get listings count by status
  Future<Map<String, int>> getListingsCount(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_listings_count.php?user_id=$userId'),
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

// Add this method to your DatabaseService class in database_service.dart

  Future<bool> updateListing(
      Listing listing, List<String> deletedMediaUrls) async {
    try {
      final userId = await currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Prepare the data for the API
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
        'new_media':
            [], // This will be populated if you upload new media separately
      };

      // Make API call to update listing
      final response = await http.post(
        Uri.parse(
            'http://10.0.2.2/smartstay/update_listing.php'), // Update with your actual URL
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

// You might also need this method to get a single listing for editing
  Future<Listing?> getSingleListing(String listingId) async {
    try {
      final userId = await currentUserId;

      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2/smartstay/get_single_listing.php?listing_id=$listingId&user_id=$userId'),
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

// Update the updateListingStatus method if it's not already there
  Future<bool> updateListingStatus(int listingId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/smartstay/update_listing_status.php'),
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

// Delete listing method
  Future<bool> deleteListing(int listingId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/smartstay/delete_listing.php'),
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
