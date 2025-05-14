// lib/pages/help_support_page.dart
import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: const Color(0xFF190152),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Support Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Support',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF190152),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildContactItem(
                      icon: Icons.email,
                      title: 'Email Us',
                      subtitle: 'support@example.com',
                      onTap: () {
                        // Open email client
                      },
                    ),
                    const Divider(),
                    _buildContactItem(
                      icon: Icons.phone,
                      title: 'Call Us',
                      subtitle: '+1 (555) 123-4567',
                      onTap: () {
                        // Make a call
                      },
                    ),
                    const Divider(),
                    _buildContactItem(
                      icon: Icons.chat_bubble,
                      title: 'Live Chat',
                      subtitle: 'Available 9AM - 5PM',
                      onTap: () {
                        // Open chat
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF190152),
              ),
            ),
            const SizedBox(height: 16),

            _buildFAQItem(
              question: 'How do I update my payment method?',
              answer:
                  'Go to Profile > Payment Methods and tap "Add Payment Method" to add a new payment method or edit an existing one.',
            ),

            _buildFAQItem(
              question: 'Can I cancel my reservation?',
              answer:
                  'Yes, you can cancel your reservation up to 48 hours before check-in with a full refund. After that, cancellation policies vary by property.',
            ),

            _buildFAQItem(
              question: 'How do I reset my password?',
              answer:
                  'Go to the login screen and tap "Forgot Password". Follow the instructions sent to your email to reset your password.',
            ),

            _buildFAQItem(
              question: 'How do I become a host?',
              answer:
                  'Go to Profile > Settings and select "Switch to Host". You need to complete your profile and add property details.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF190152).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                color: const Color(0xFF190152),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        iconColor: const Color(0xFF190152),
        textColor: const Color(0xFF190152),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
