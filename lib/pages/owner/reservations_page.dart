import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:my_app/config/api_config.dart';
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

  // Add this debug version to your reservations_page.dart
// Replace the _loadReservations method with this debug version

  // Replace your _loadReservations method with this improved version:

  Future<void> _loadReservations() async {
    print('\n🔍 === LOAD RESERVATIONS START ===');

    setState(() {
      _isLoading = true;
    });
    print('✅ Loading state set to true');

    try {
      // FIX: Safe ID conversion
      print('👤 User Debug Info:');
      print('   - User ID raw: ${widget.currentUser.id}');
      print('   - User ID type: ${widget.currentUser.id.runtimeType}');

      // Convert ID safely
      int userId;
      if (widget.currentUser.id is int) {
        userId = widget.currentUser.id as int;
      } else {
        userId = int.parse(widget.currentUser.id);
      }

      print('   - User ID converted: $userId (${userId.runtimeType})');
      print('   - User type: ${widget.currentUser.userType}');
      print('   - User full name: ${widget.currentUser.fullName}');

      // Build URL with converted ID
      final url = ApiConfig.getOwnerBookings(userId);
      print('🌐 API URL: $url');

      // Make HTTP request
      print('📡 Making HTTP request...');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📨 Response received:');
      print('   - Status code: ${response.statusCode}');
      print('   - Response body length: ${response.body.length}');
      print('   - Raw response: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ HTTP 200 - Parsing JSON...');

        final data = json.decode(response.body);
        print('📋 Parsed JSON structure:');
        print('   - Keys: ${data.keys}');
        print('   - Success field: ${data['success']}');
        print('   - Bookings field exists: ${data['bookings'] != null}');
        if (data['bookings'] != null) {
          print('   - Bookings type: ${data['bookings'].runtimeType}');
          print('   - Bookings length: ${data['bookings'].length}');
        }

        if (data['success'] == true && data['bookings'] != null) {
          print('✅ Valid response structure detected');

          final bookings = List<Map<String, dynamic>>.from(data['bookings']);
          print('📚 Bookings array processed:');
          print('   - Total bookings: ${bookings.length}');

          // Debug each booking
          for (int i = 0; i < bookings.length; i++) {
            final booking = bookings[i];
            print('   📖 Booking $i:');
            print('      - ID: ${booking['id']}');
            print(
                '      - Status: "${booking['status']}" (${booking['status'].runtimeType})');
            print('      - Owner ID: ${booking['owner_id']}');
            print('      - Expected Owner ID: $userId');
            print(
                '      - Match: ${booking['owner_id'].toString() == userId.toString()}');
          }

          print('\n🔄 Starting filtering process...');

          // Filter pending bookings
          print('🟡 Filtering PENDING bookings...');
          final pending = bookings.where((b) {
            final status = b['status'];
            final statusStr = status?.toString().trim().toLowerCase() ?? '';
            final isPending = statusStr == 'pending';
            print(
                '   - Booking ${b['id']}: status="$status" -> "$statusStr" -> isPending: $isPending');
            return isPending;
          }).toList();

          // Filter confirmed bookings
          print('🟢 Filtering CONFIRMED bookings...');
          final confirmed = bookings.where((b) {
            final status = b['status'];
            final statusStr = status?.toString().trim().toLowerCase() ?? '';
            final isConfirmed = statusStr == 'confirmed';
            print(
                '   - Booking ${b['id']}: status="$status" -> "$statusStr" -> isConfirmed: $isConfirmed');
            return isConfirmed;
          }).toList();

          // Filter history bookings
          print('🔴 Filtering HISTORY bookings...');
          final history = bookings.where((b) {
            final status = b['status'];
            final statusStr = status?.toString().trim().toLowerCase() ?? '';
            final isHistory = statusStr == 'rejected' ||
                statusStr == 'completed' ||
                statusStr == 'cancelled';
            print(
                '   - Booking ${b['id']}: status="$status" -> "$statusStr" -> isHistory: $isHistory');
            return isHistory;
          }).toList();

          print('\n📊 FILTERING RESULTS:');
          print('   🟡 Pending: ${pending.length} bookings');
          print('   🟢 Confirmed: ${confirmed.length} bookings');
          print('   🔴 History: ${history.length} bookings');

          // Print booking IDs in each category
          print('\n📋 Booking assignments:');
          print('   🟡 Pending IDs: ${pending.map((b) => b['id']).toList()}');
          print(
              '   🟢 Confirmed IDs: ${confirmed.map((b) => b['id']).toList()}');
          print('   🔴 History IDs: ${history.map((b) => b['id']).toList()}');

          print('\n🔄 Updating state...');
          setState(() {
            _pendingReservations = pending;
            _confirmedReservations = confirmed;
            _historyReservations = history;
            _isLoading = false;
          });

          print('✅ State updated successfully!');
          print('   📊 Final state:');
          print(
              '      🟡 _pendingReservations.length: ${_pendingReservations.length}');
          print(
              '      🟢 _confirmedReservations.length: ${_confirmedReservations.length}');
          print(
              '      🔴 _historyReservations.length: ${_historyReservations.length}');
          print('      ⏳ _isLoading: $_isLoading');
        } else {
          print('❌ Invalid response structure');
          print('   - success field: ${data['success']}');
          print('   - bookings field: ${data['bookings']}');
          print('   - Setting empty state...');

          setState(() {
            _pendingReservations = [];
            _confirmedReservations = [];
            _historyReservations = [];
            _isLoading = false;
          });
          print('✅ Empty state set');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('   Response body: ${response.body}');

        setState(() {
          _pendingReservations = [];
          _confirmedReservations = [];
          _historyReservations = [];
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ EXCEPTION in _loadReservations:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');

      setState(() {
        _pendingReservations = [];
        _confirmedReservations = [];
        _historyReservations = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    print('🔍 === LOAD RESERVATIONS END ===\n');
  }

// Also add this test method to call _loadReservations manually:

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

  // Update your build method to include TWO debug buttons:
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                    ),
                    SizedBox(height: 16),
                    Text('Loading reservations...'),
                  ],
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

  // Also, update your _buildReservationsList method to add debug info:
  Widget _buildReservationsList(
      List<Map<String, dynamic>> reservations, String status) {
    print(
        '=== Building reservations list for $status: ${reservations.length} items ===');

    // Debug: Print the actual reservations being displayed
    for (int i = 0; i < reservations.length; i++) {
      final reservation = reservations[i];
      print(
          '  $status[$i]: Booking ID ${reservation['id']} - Status: "${reservation['status']}"');
    }

    if (reservations.isEmpty) {
      print('Showing empty state for $status');
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
            const SizedBox(height: 8),
            Text(
              'Expected: ${status == 'Pending' ? '1' : status == 'History' ? '4' : '0'} bookings based on API data',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    print('Showing ${reservations.length} cards for $status');

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
          print(
              'Building card $index for booking ${reservation['id']} in $status tab');

          // Keep your existing card building code here...
          // (I'm only showing the debug additions, rest stays the same)

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
                          '${reservation['status']}'
                              .toUpperCase(), // Show actual status from data
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

                  // Keep your existing emergency contact and message sections...

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
