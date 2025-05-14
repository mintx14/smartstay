// // lib/models/user_model.dart

// class User {
//   // final int id;
//   // final String fullName;
//   // final String email;
//   // final String userType;
//   // final String phoneNumber; // Added for personal information page
//   // final String
//   //     password;
//   int id;
//   String fullName;
//   String email;
//   String userType;
//   String phoneNumber; // Added for personal information page
//   String
//       password; // Added for personal information page (not recommended to store in clear text in production)

//   User({
//     required this.id,
//     required this.fullName,
//     required this.email,
//     required this.userType,
//     this.phoneNumber = '',
//     this.password = '',
//   });

//   // // Create a User from JSON data
//   // factory User.fromJson(Map<String, dynamic> json) {
//   //   return User(
//   //     id: json['id'],
//   //     fullName: json['full_name'],
//   //     email: json['email'],
//   //     userType: json['user_type'],
//   //     phoneNumber: json['phone_number'] ?? '',
//   //     password: json['password'] ??
//   //         '', // Note: storing passwords in clear text is not secure
//   //   );
//   // }

//   // Create a User from JSON
//   factory User.fromJson(Map<String, dynamic> json) {
//     // Debug print to see what we're receiving
//     print('Creating User from JSON: $json');

//     // Handle potential null values or inconsistent keys
//     return User(
//       id: json['id'] ?? 0,
//       fullName: json['full_name'] ?? '',
//       email: json['email'] ?? '',
//       phoneNumber: json['phone_number'] ?? '',
//       userType: json['user_type'] ?? '',
//       // Password should never be returned from the API for security reasons
//     );
//   }

//   // Convert User to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'full_name': fullName,
//       'email': email,
//       'phone_number': phoneNumber,
//       'user_type': userType,
//       // Only include password if it's provided (for updates)
//       if (password.isNotEmpty) 'password': password,
//     };
//   }

//   // Create a copy of this User with updated fields
//   User copyWith({
//     int? id,
//     String? fullName,
//     String? email,
//     String? phoneNumber,
//     String? userType,
//     String? password,
//   }) {
//     return User(
//       id: id ?? this.id,
//       fullName: fullName ?? this.fullName,
//       email: email ?? this.email,
//       phoneNumber: phoneNumber ?? this.phoneNumber,
//       userType: userType ?? this.userType,
//       password: password ?? this.password,
//     );
//   }

//   @override
//   String toString() {
//     return 'User{id: $id, fullName: $fullName, email: $email, phoneNumber: $phoneNumber, userType: $userType}';
//   }
// }
// lib/models/user_model.dart

class User {
  final String id;
  String fullName;
  String email;
  String phoneNumber;
  String userType;
  bool hasPassword; // Flag to indicate if user has a password set

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    this.hasPassword = true,
  });

  // Factory constructor to create a User object from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      userType: json['user_type'] ?? 'tenant',
      hasPassword: json['has_password'] ?? true,
    );
  }

  // Convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'user_type': userType,
    };
  }

  // Method to create a map for update requests
  Map<String, dynamic> toUpdateJson({String? newPassword}) {
    final Map<String, dynamic> data = {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'user_type': userType,
    };

    // Only include password if a new one is provided
    if (newPassword != null && newPassword.isNotEmpty) {
      data['new_password'] = newPassword;
    }

    return data;
  }
}
