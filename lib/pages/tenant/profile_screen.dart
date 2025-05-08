import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Open settings
            },
          ),
        ],
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
                        // Navigate to edit profile
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

            // Profile sections
            _buildSection(
              title: 'Account',
              items: [
                ProfileMenuItem(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  onTap: () {},
                ),
                ProfileMenuItem(
                  icon: Icons.school_outlined,
                  title: 'Student Verification',
                  onTap: () {},
                ),
                ProfileMenuItem(
                  icon: Icons.payment_outlined,
                  title: 'Payment Methods',
                  onTap: () {},
                ),
              ],
            ),

            _buildSection(
              title: 'Housing',
              items: [
                ProfileMenuItem(
                  icon: Icons.history_outlined,
                  title: 'Rental History',
                  onTap: () {},
                ),
                ProfileMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Applications',
                  onTap: () {},
                ),
                ProfileMenuItem(
                  icon: Icons.bookmark_border,
                  title: 'Saved Searches',
                  onTap: () {},
                ),
              ],
            ),

            _buildSection(
              title: 'Support',
              items: [
                ProfileMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {},
                ),
                ProfileMenuItem(
                  icon: Icons.support_agent_outlined,
                  title: 'Contact Support',
                  onTap: () {},
                ),
                ProfileMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                ProfileMenuItem(
                  icon: Icons.info_outline,
                  title: 'About SmartStay',
                  onTap: () {},
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
                Navigator.of(context).pop();
                // In production code, you would implement actual logout functionality here
                // For this demo without login functionality, we'll just navigate back to home
              },
            ),
          ],
        );
      },
    );
  }
}

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap; // Change this line

  ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
