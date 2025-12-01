import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/models/user_model.dart';
// ADD THIS IMPORT
import 'package:my_app/config/api_config.dart'; // Adjust path as needed

class UserService {
  // REMOVE THESE LINES - No longer needed
  // final String baseUrl = 'http://192.168.0.11/smartstay';

  // Method to update user information
  Future<User> updateUser(User user,
      {String? newPassword, String? updateField}) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.post(
        Uri.parse(ApiConfig.updateUserUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toUpdateJson(newPassword: newPassword)),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        // Return the updated user object
        return User.fromJson(data['user']);
      } else {
        throw Exception(data['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
