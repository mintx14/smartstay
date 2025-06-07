// services/favorites_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class FavoritesService {
  final String baseUrl = 'http://10.0.2.2/smartstay';

  // Get user's favorites
  Future<List<String>> getUserFavorites(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorites/$userId'),
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
      final response = await http.post(
        Uri.parse('$baseUrl/favorites'),
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
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/$userId/$listingId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }
}
