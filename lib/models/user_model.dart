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
