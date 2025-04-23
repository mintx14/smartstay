// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your actual API URL (where your PHP script is located)
  // If testing on emulator with localhost XAMPP, use 10.0.2.2 instead of localhost
  static const String baseUrl = 'http://10.0.2.2/smartstay';
  // If using a physical device, use your computer's IP address
  // static const String baseUrl = 'http://192.168.1.X/smartstay';

  // User registration method
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register.php'),
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
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
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
