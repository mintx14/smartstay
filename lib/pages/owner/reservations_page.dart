import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:my_app/config/api_config.dart';
import 'package:my_app/widgets/chat_screen.dart' as chat;
import 'package:my_app/models/user_model.dart';

// Updated Reservations Page for Property Owners
class ReservationsPage extends StatefulWidget {
  final User currentUser; // Add current user (owner)

  const ReservationsPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingReservations = [];
  List<Map<String, dynamic>> _confirmedReservations = [];
  List<Map<String, dynamic>> _historyReservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the correct API endpoint
      final response = await http.get(
        Uri.parse(ApiConfig.getOwnerBookings(widget.currentUser.id)),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings =
            List<Map<String, dynamic>>.from(data['bookings'] ?? []);

        setState(() {
          _pendingReservations =
              bookings.where((b) => b['status'] == 'pending').toList();
          _confirmedReservations =
              bookings.where((b) => b['status'] == 'confirmed').toList();
          _historyReservations = bookings
              .where((b) =>
                  b['status'] == 'rejected' ||
                  b['status'] == 'completed' ||
                  b['status'] == 'cancelled')
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load reservations: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reservations: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.updateBookingStatus(bookingId, status)),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accept'
                  ? 'Booking accepted successfully'
                  : 'Booking declined',
            ),
            backgroundColor: status == 'accept' ? Colors.green : Colors.orange,
          ),
        );
        _loadReservations(); // Reload reservations
      } else {
        throw Exception('Failed to update booking status: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Pending (${_pendingReservations.length})'),
                Tab(text: 'Confirmed (${_confirmedReservations.length})'),
                Tab(text: 'History (${_historyReservations.length})'),
              ],
              labelColor: const Color(0xFF667EEA),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF667EEA),
              indicatorWeight: 3,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildReservationsList(_pendingReservations, 'Pending'),
                  _buildReservationsList(_confirmedReservations, 'Confirmed'),
                  _buildReservationsList(_historyReservations, 'History'),
                ],
              ),
      ),
    );
  }

  Widget _buildReservationsList(
      List<Map<String, dynamic>> reservations, String status) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'Pending'
                  ? Icons.hourglass_empty
                  : status == 'Confirmed'
                      ? Icons.check_circle_outline
                      : Icons.history,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status.toLowerCase()} reservations',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    Color statusColor = status == 'Pending'
        ? Colors.orange
        : (status == 'Confirmed' ? Colors.green : Colors.grey);

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          final tenant = reservation['tenant'] ?? {};
          final property = reservation['property'] ?? {};
          final checkInDate = DateTime.parse(reservation['check_in_date']);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Booking #${reservation['id']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tenant Information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF667EEA),
                          child: Text(
                            tenant['full_name']
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                'T',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant['full_name'] ?? 'Tenant Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tenant['email'] ?? 'tenant@example.com',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              if (tenant['phone'] != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  tenant['phone'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Property Information
                  Row(
                    children: [
                      Icon(Icons.home, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          property['title'] ?? 'Property Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Booking Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Check-In',
                            DateFormat('MMM d, yyyy').format(checkInDate)),
                        const SizedBox(height: 8),
                        _buildDetailRow('Duration',
                            '${reservation['duration_months']} months'),
                        const SizedBox(height: 8),
                        _buildDetailRow('Monthly Rent',
                            'RM ${reservation['monthly_rent']}'),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                            'Total Amount', 'RM ${reservation['total_amount']}',
                            isTotal: true),
                      ],
                    ),
                  ),

                  // Emergency Contact (if available)
                  if (reservation['emergency_contact_name'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emergency,
                              size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Emergency Contact',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${reservation['emergency_contact_name']} - ${reservation['emergency_contact_phone']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Message from tenant (if any)
                  if (reservation['message'] != null &&
                      reservation['message'].isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message from tenant:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reservation['message'],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Action Buttons
                  if (status == 'Pending')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            _showDeclineDialog(reservation['id'].toString());
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAcceptDialog(reservation['id'].toString());
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (status == 'Confirmed')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // Navigate to chat with tenant
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => chat.ChatScreen(
                                  currentUserId:
                                      int.parse(widget.currentUser.id),
                                  otherUser: chat.User(
                                    id: int.parse(tenant['id'].toString()),
                                    fullName: tenant['full_name'] ?? 'Tenant',
                                    email: tenant['email'] ?? '',
                                    userType: 'Tenant',
                                  ),
                                  listingId:
                                      int.parse(property['id'].toString()),
                                  listingTitle: property['title'] ?? 'Property',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.message, size: 18),
                          label: const Text('Message Tenant'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF667EEA),
                            side: const BorderSide(color: Color(0xFF667EEA)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 15 : 13,
            color: isTotal ? const Color(0xFF667EEA) : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showAcceptDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Accept Booking'),
          ],
        ),
        content: const Text(
          'Are you sure you want to accept this booking request? The tenant will be notified and can proceed with payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateBookingStatus(bookingId, 'accept');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeclineDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cancel,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Decline Booking'),
          ],
        ),
        content: const Text(
          'Are you sure you want to decline this booking request? The tenant will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateBookingStatus(bookingId, 'reject');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Decline',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
