import 'package:flutter/material.dart';

import 'package:my_app/models/user_model.dart';
import 'package:my_app/widgets/profile_menu_item.dart';
import 'package:my_app/pages/owner/personal_info_page.dart';
import 'package:my_app/pages/tenant/payment_methods_page.dart';
import 'package:my_app/pages/owner/rental_history_page.dart';
import 'package:my_app/pages/owner/help_support_page.dart';

class ProfileScreen extends StatelessWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF190152),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User profile header
            Container(
              color: const Color(0xFF190152),
              padding: const EdgeInsets.only(bottom: 24),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Profile picture
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: const Color(0xFF190152).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // User name
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // User email
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Edit profile button
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to edit profile page
                        _navigateToEditProfile(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF190152),
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),
            ),

            // Account section
            _buildSection(
              title: 'Account',
              items: [
                ProfileMenuItem(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  onTap: () {
                    _navigateToPersonalInfo(context);
                  },
                ),
                ProfileMenuItem(
                  icon: Icons.payment_outlined,
                  title: 'Payment Methods',
                  onTap: () {
                    _navigateToPaymentMethods(context);
                  },
                ),
              ],
            ),

            // Housing section
            _buildSection(
              title: 'Housing',
              items: [
                ProfileMenuItem(
                  icon: Icons.history_outlined,
                  title: 'Rental History',
                  onTap: () {
                    _navigateToRentalHistory(context);
                  },
                ),
              ],
            ),

            // Support section
            _buildSection(
              title: 'Support',
              items: [
                ProfileMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    _navigateToHelpSupport(context);
                  },
                ),
              ],
            ),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: TextButton(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // App version
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<ProfileMenuItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF190152),
            ),
          ),
        ),
        Column(
          children: items.map((item) {
            return ListTile(
              leading: Icon(item.icon, color: const Color(0xFF190152)),
              title: Text(item.title),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: item.onTap,
            );
          }).toList(),
        ),
      ],
    );
  }

  // Navigate to Edit Profile page
  void _navigateToEditProfile(BuildContext context) {
    // Navigate to personal info which doubles as edit profile
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PersonalInfoPage(user: user),
      ),
    );
  }

  // Navigate to Personal Information page
  void _navigateToPersonalInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PersonalInfoPage(user: user),
      ),
    );
  }

  // Navigate to Payment Methods page
  void _navigateToPaymentMethods(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentMethodsPage(user: user),
      ),
    );
  }

  // Navigate to Rental History page
  void _navigateToRentalHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RentalHistoryPage(),
      ),
    );
  }

  // Navigate to Help & Support page
  void _navigateToHelpSupport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HelpSupportPage(),
      ),
    );
  }

  // Show logout dialog and handle logout action
  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // Handle logout process
                _handleLogout(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Handle the logout process
  void _handleLogout(BuildContext context) {
    // Close the dialog
    Navigator.of(context).pop();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF190152)),
          ),
        );
      },
    );

    // Simulate logout process with a delay
    Future.delayed(const Duration(seconds: 2), () {
      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to login screen (replace with your actual navigation)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('Login Screen'),
            ),
          ),
        ),
        (route) => false, // This clears the navigation stack
      );

      // Optional: Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully logged out'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
}
