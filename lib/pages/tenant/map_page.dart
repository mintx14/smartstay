import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart';

class MapPage extends StatefulWidget {
  final User user;

  const MapPage({super.key, required this.user});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool _isMapView = true;
  List<Map<String, dynamic>> propertyLocations = [
    {
      'name': 'Sunshine Apartments',
      'lat': 37.422,
      'lng': -122.084,
      'price': '\$450/mo',
      'distance': '0.5 miles from campus'
    },
    {
      'name': 'Student Village',
      'lat': 37.425,
      'lng': -122.082,
      'price': '\$380/mo',
      'distance': '1.2 miles from campus'
    },
    {
      'name': 'Campus View',
      'lat': 37.421,
      'lng': -122.086,
      'price': '\$520/mo',
      'distance': '0.3 miles from campus'
    },
    {
      'name': 'College Heights',
      'lat': 37.427,
      'lng': -122.088,
      'price': '\$490/mo',
      'distance': '0.8 miles from campus'
    },
    {
      'name': 'University Commons',
      'lat': 37.423,
      'lng': -122.090,
      'price': '\$420/mo',
      'distance': '0.6 miles from campus'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search this area',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Toggle between map and list view
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(30),
                  renderBorder: false,
                  fillColor: Colors.blue,
                  selectedColor: Colors.white,
                  color: Colors.grey[600],
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  isSelected: [_isMapView, !_isMapView],
                  onPressed: (index) {
                    setState(() {
                      _isMapView = index == 0;
                    });
                  },
                  children: const [
                    Icon(Icons.map),
                    Icon(Icons.list),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Map view or List view based on toggle
        Expanded(
          child: _isMapView ? _buildMapView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    // In a real app, you would use a map package like google_maps_flutter
    // Here we're just showing a placeholder
    return Stack(
      children: [
        // Placeholder for map
        Container(
          color: Colors.grey[300],
          child: Center(
            child: Icon(Icons.map, size: 100, color: Colors.grey[400]),
          ),
        ),

        // Property markers
        ...propertyLocations.map((property) {
          // Calculate position (this would be done properly with a real map)
          final x = (property['lng'] + 122.09) * 1000;
          final y = (property['lat'] - 37.42) * 1000;

          return Positioned(
            left: x,
            top: y,
            child: GestureDetector(
              onTap: () {
                _showPropertyDetails(property);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  property['price'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),

        // Filter button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              // Show filter options
              _showFilterOptions();
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.filter_list, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: propertyLocations.length,
      itemBuilder: (context, index) {
        final property = propertyLocations[index];

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: const Icon(Icons.home, color: Colors.blue),
          ),
          title: Text(property['name']),
          subtitle: Text(property['distance']),
          trailing: Text(
            property['price'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          onTap: () {
            _showPropertyDetails(property);
          },
        );
      },
    );
  }

  void _showPropertyDetails(Map<String, dynamic> property) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                property['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(property['distance']),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(property['price']),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Save'),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // In a real app, navigate to property details page
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Properties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Price Range'),
              RangeSlider(
                values: const RangeValues(350, 550),
                min: 300,
                max: 700,
                divisions: 8,
                labels: const RangeLabels('\$350', '\$550'),
                onChanged: (RangeValues values) {},
              ),
              const Text('Distance from Campus'),
              Slider(
                value: 1.5,
                min: 0.1,
                max: 3.0,
                divisions: 29,
                label: '1.5 miles',
                onChanged: (double value) {},
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
