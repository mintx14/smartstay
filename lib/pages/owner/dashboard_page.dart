import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20.0),
          _buildStatsCards(),
          SizedBox(height: 20.0),
          Text(
            'Recent Reservations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10.0),
          _buildRecentReservations(),
          SizedBox(height: 20.0),
          Text(
            'Recent Messages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10.0),
          _buildRecentMessages(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 10.0,
      mainAxisSpacing: 10.0,
      children: [
        _buildStatCard('Total Listings', '5', Colors.blue),
        _buildStatCard('Active Listings', '4', Colors.green),
        _buildStatCard('Pending Reservations', '3', Colors.orange),
        _buildStatCard('Messages', '7', Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: color.withOpacity(0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReservations() {
    return Container(
      height: 180,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 8.0),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('S${index + 1}'),
              ),
              title: Text('Reservation #${10023 + index}'),
              subtitle: Text('Student ${index + 1} • Room ${101 + index}'),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Pending',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentMessages() {
    return Container(
      height: 180,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple[(index + 1) * 100],
                child: Text('S${index + 1}'),
              ),
              title: Text('Student ${index + 1}'),
              subtitle: Text('Is the room still available?'),
              trailing: Text('${index + 1}h ago'),
            ),
          );
        },
      ),
    );
  }
}
