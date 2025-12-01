import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/config/api_config.dart'; // Add this import

class RentalHistoryPage extends StatefulWidget {
  const RentalHistoryPage({super.key});

  @override
  State<RentalHistoryPage> createState() => _RentalHistoryPageState();
}

class _RentalHistoryPageState extends State<RentalHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RentalHistory> activeRentals = [];
  List<RentalHistory> pastRentals = [];
  bool isLoading = true;
  int userId = 1; // Get this from your user session/provider

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRentalHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRentalHistory() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getRentalHistoryUrlWithUserId(userId)),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final rentals = data.map((e) => RentalHistory.fromJson(e)).toList();

        setState(() {
          activeRentals = rentals.where((r) => r.status == 'active').toList();
          pastRentals = rentals.where((r) => r.status != 'active').toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading rental history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF190152),
        title: const Text(
          'Rental History',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRentalList(activeRentals, true),
                _buildRentalList(pastRentals, false),
              ],
            ),
    );
  }

  Widget _buildRentalList(List<RentalHistory> rentals, bool isActive) {
    if (rentals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active rentals' : 'No past rentals',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rental = rentals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showRentalDetails(rental),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Image
                if (rental.propertyImageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.home,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Property Name
                      Text(
                        rental.propertyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Address
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              rental.propertyAddress,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Rental Period
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatDate(rental.startDate)} - ${rental.endDate != null ? _formatDate(rental.endDate!) : 'Present'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Monthly Rent and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${rental.monthlyRent.toStringAsFixed(2)}/month',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF190152),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(rental.status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              rental.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Rating (for past rentals)
                      if (!isActive && rental.rating != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < rental.rating!
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 20,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${rental.rating}/5',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'terminated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showRentalDetails(RentalHistory rental) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Property Name
                Text(
                  rental.propertyName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Details
                _buildDetailRow(
                    Icons.location_on, 'Address', rental.propertyAddress),
                _buildDetailRow(Icons.person, 'Landlord',
                    rental.landlordName ?? 'Not specified'),
                _buildDetailRow(Icons.calendar_today, 'Rental Period',
                    '${_formatDate(rental.startDate)} - ${rental.endDate != null ? _formatDate(rental.endDate!) : 'Present'}'),
                _buildDetailRow(Icons.attach_money, 'Monthly Rent',
                    '\$${rental.monthlyRent.toStringAsFixed(2)}'),
                _buildDetailRow(Icons.payments, 'Total Paid',
                    '\$${rental.totalPaid.toStringAsFixed(2)}'),
                _buildDetailRow(
                    Icons.info, 'Status', rental.status.toUpperCase()),

                // Review section (for past rentals)
                if (rental.status != 'active') ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Your Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (rental.rating != null) ...[
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < rental.rating! ? Icons.star : Icons.star_border,
                            size: 24,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${rental.rating}/5',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (rental.review != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        rental.review!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () => _showAddReviewDialog(rental),
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Add Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF190152),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog(RentalHistory rental) {
    int rating = 0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate your experience:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    onPressed: () {
                      setState(() {
                        rating = i + 1;
                      });
                    },
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      size: 32,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  labelText: 'Your Review',
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: rating > 0
                  ? () {
                      _submitReview(rental, rating, reviewController.text);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF190152),
              ),
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(
      RentalHistory rental, int rating, String review) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.rentalHistoryUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'rental_id': rental.id,
          'rating': rating,
          'review': review,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadRentalHistory();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class RentalHistory {
  final int id;
  final String propertyName;
  final String propertyAddress;
  final String? propertyImageUrl;
  final String? landlordName;
  final DateTime startDate;
  final DateTime? endDate;
  final double monthlyRent;
  final double totalPaid;
  final String status;
  final int? rating;
  final String? review;

  RentalHistory({
    required this.id,
    required this.propertyName,
    required this.propertyAddress,
    this.propertyImageUrl,
    this.landlordName,
    required this.startDate,
    this.endDate,
    required this.monthlyRent,
    required this.totalPaid,
    required this.status,
    this.rating,
    this.review,
  });

  factory RentalHistory.fromJson(Map<String, dynamic> json) {
    return RentalHistory(
      id: json['id'],
      propertyName: json['property_name'],
      propertyAddress: json['property_address'],
      propertyImageUrl: json['property_image_url'],
      landlordName: json['landlord_name'],
      startDate: DateTime.parse(json['rental_start_date']),
      endDate: json['rental_end_date'] != null
          ? DateTime.parse(json['rental_end_date'])
          : null,
      monthlyRent: double.parse(json['monthly_rent'].toString()),
      totalPaid: double.parse(json['total_paid'].toString()),
      status: json['status'],
      rating: json['rating'],
      review: json['review'],
    );
  }
}
