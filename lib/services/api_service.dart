// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
// ADD THIS IMPORT
import 'package:my_app/config/api_config.dart'; // Adjust path as needed

class ApiService {
  // REMOVE THESE LINES - No longer needed
  // static const String baseUrl = 'http://192.168.0.11/smartstay';

  // User registration method
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String userType,
  }) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'user_type': userType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // User login method
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // UPDATED: Use API config instead of hardcoded URL
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
}
