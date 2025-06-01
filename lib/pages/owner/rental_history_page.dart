// lib/pages/rental_history_page.dart
import 'package:flutter/material.dart';

class RentalHistoryPage extends StatelessWidget {
  const RentalHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Rental History'),
        backgroundColor: const Color(0xFF190152),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Rentals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF190152),
              ),
            ),
            const SizedBox(height: 16),
            _buildRentalCard(
              imageUrl: 'https://via.placeholder.com/150',
              title: 'Modern Apartment in Downtown',
              address: '123 Main Street, Apt 4B',
              dates: 'Jan 2023 - Present',
              status: 'Active',
              statusColor: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'Past Rentals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF190152),
              ),
            ),
            const SizedBox(height: 16),
            _buildRentalCard(
              imageUrl: 'https://via.placeholder.com/150',
              title: 'Cozy Studio Near Park',
              address: '456 Park Avenue',
              dates: 'Mar 2021 - Dec 2022',
              status: 'Completed',
              statusColor: Colors.grey,
            ),
            _buildRentalCard(
              imageUrl: 'https://via.placeholder.com/150',
              title: 'Charming Victorian Home',
              address: '789 Oak Street',
              dates: 'Jun 2019 - Feb 2021',
              status: 'Completed',
              statusColor: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalCard({
    required String imageUrl,
    required String title,
    required String address,
    required String dates,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Just a placeholder since we can't include actual images
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.home,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dates,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // View details
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF190152),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
