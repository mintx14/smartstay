// lib/models/user_model.dart
class User {
  final int id;
  final String fullName;
  final String email;
  final String userType;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.userType,
  });

  // Create a User from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      userType: json['user_type'],
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'user_type': userType,
    };
  }
}
