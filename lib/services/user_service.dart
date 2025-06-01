// // lib/services/user_service.dart

// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:my_app/models/user_model.dart';

// class UserService {
//   // Change this to match your backend base path
//   static const String _baseUrl = 'http://10.0.2.2/smartstay';

//   // Register new user
//   Future<User> registerUser(User user) async {
//     final response = await http.post(
//       Uri.parse('$_baseUrl/register.php'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'full_name': user.fullName,
//         'email': user.email,
//         'phone_number': user.phoneNumber,
//         'password': user.password,
//         'user_type': user.userType,
//       }),
//     );

//     final data = jsonDecode(response.body);

//     if (response.statusCode == 200 && data['success'] == true) {
//       return User.fromJson(data['user']);
//     } else {
//       throw Exception(data['message'] ?? 'Registration failed');
//     }
//   }

//   // Login user
//   Future<User> loginUser(String email, String password) async {
//     final response = await http.post(
//       Uri.parse('$_baseUrl/login.php'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'password': password}),
//     );

//     final data = jsonDecode(response.body);

//     if (response.statusCode == 200 && data['success'] == true) {
//       return User.fromJson(data['user']);
//     } else {
//       throw Exception(data['message'] ?? 'Login failed');
//     }
//   }

//   // Get user by ID
//   Future<User> getUserById(int userId) async {
//     final response = await http.post(
//       Uri.parse('$_baseUrl/get_user.php'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'user_id': userId}),
//     );

//     final data = jsonDecode(response.body);

//     if (response.statusCode == 200 && data['success'] == true) {
//       return User.fromJson(data['user']);
//     } else {
//       throw Exception(data['message'] ?? 'Failed to load user');
//     }
//   }

//   // Update user
//   Future<User> updateUser(User user) async {
//     final response = await http.post(
//       Uri.parse('$_baseUrl/update_user.php'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'id': user.id,
//         'full_name': user.fullName,
//         'email': user.email,
//         'phone_number': user.phoneNumber,
//         'user_type': user.userType,
//         if (user.password.isNotEmpty && !user.password.startsWith('••'))
//           'password': user.password,
//       }),
//     );

//     final data = jsonDecode(response.body);

//     if (response.statusCode == 200 && data['success'] == true) {
//       return User.fromJson(data['user']);
//     } else {
//       throw Exception(data['message'] ?? 'Update failed');
//     }
//   }

//   // Delete user
//   Future<bool> deleteUser(int userId) async {
//     final response = await http.post(
//       Uri.parse('$_baseUrl/delete_user.php'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'user_id': userId}),
//     );

//     final data = jsonDecode(response.body);

//     if (response.statusCode == 200 && data['success'] == true) {
//       return true;
//     } else {
//       throw Exception(data['message'] ?? 'Delete failed');
//     }
//   }
// }

// lib/services/user_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/models/user_model.dart';

class UserService {
  // Update with your actual API base URL
  final String baseUrl = 'http://10.0.2.2/smartstay'; // For Android Emulator
  // Use 'http://localhost/smartstay' for web or iOS simulator

  // Method to update user information
  Future<User> updateUser(User user,
      {String? newPassword, String? updateField}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_user.php'),
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

  // Other user-related methods like login, register, etc.
}
