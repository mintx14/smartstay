import 'package:flutter/material.dart';
import 'add_listing_page.dart';

class ListingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Listings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to add new listing page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddListingPage()),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 16.0),
                    elevation: 2.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4.0),
                              topRight: Radius.circular(4.0),
                            ),
                            image: DecorationImage(
                              image: NetworkImage(
                                  'https://via.placeholder.com/400x200'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Hostel ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Active',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                '123 University Avenue, City',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Icon(Icons.hotel,
                                      size: 16, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text('${(index + 1) * 2} Rooms'),
                                  SizedBox(width: 16),
                                  Icon(Icons.person,
                                      size: 16, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text('${(index + 1)} Available'),
                                  SizedBox(width: 16),
                                  Icon(Icons.attach_money,
                                      size: 16, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text('\$${300 + (index * 50)}/month'),
                                ],
                              ),
                              SizedBox(height: 12.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      // Navigate to edit listing page
                                    },
                                    icon: Icon(Icons.edit, size: 16),
                                    label: Text('Edit'),
                                  ),
                                  SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      // Show delete confirmation
                                    },
                                    icon: Icon(Icons.delete, size: 16),
                                    label: Text('Delete'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
