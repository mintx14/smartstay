import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24.0),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue,
                  child: Text(
                    'JD',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  'John Doe',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Property Owner',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8.0),
                OutlinedButton.icon(
                  onPressed: () {
                    // Edit profile
                  },
                  icon: Icon(Icons.edit),
                  label: Text('Edit Profile'),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.0),
          Text(
            'Personal Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.0),
          _buildInfoCard('Email Address', 'john.doe@example.com', Icons.email),
          _buildInfoCard('Phone Number', '+1 (555) 123-4567', Icons.phone),
          _buildInfoCard(
              'Address', '456 Property Street, City, State', Icons.location_on),
          SizedBox(height: 24.0),
          Text(
            'Account Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.0),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('Notifications'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Change Password'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.payment),
                  title: Text('Payment Methods'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Help & Support'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: 24.0),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                // Log out logic
              },
            ),
          ),
          SizedBox(height: 32.0),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.0,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
