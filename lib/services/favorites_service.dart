import 'package:http/http.dart' as http;
import 'dart:convert';
// ADD THIS IMPORT
import 'package:my_app/config/api_config.dart'; // Adjust path as needed

class FavoritesService {
  // REMOVE THIS LINE - No longer needed
  // final String baseUrl = 'http://192.168.0.11/smartstay';

  // Get user's favorites
  Future<List<String>> getUserFavorites(String userId) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.get(
        Uri.parse(ApiConfig.getFavoritesUrlWithUserId(userId)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['favoriteIds']);
      }
      return [];
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  // Add favorite
  Future<bool> addFavorite(String userId, String listingId) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.post(
        Uri.parse(ApiConfig.favoritesBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'listingId': listingId,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error adding favorite: $e');
      return false;
    }
  }

  // Remove favorite
  Future<bool> removeFavorite(String userId, String listingId) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.delete(
        Uri.parse(
            ApiConfig.getFavoritesUrlWithUserAndListing(userId, listingId)),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }
}
