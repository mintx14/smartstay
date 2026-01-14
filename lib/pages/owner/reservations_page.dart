import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:my_app/config/api_config.dart';
import 'package:my_app/models/user_model.dart';

class ReservationsPage extends StatefulWidget {
  final User currentUser;

  const ReservationsPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  // State variables
  List<Map<String, dynamic>> _pendingReservations = [];
  List<Map<String, dynamic>> _confirmedReservations = [];
  List<Map<String, dynamic>> _historyReservations = [];
  bool _isLoading = true;
  String _selectedTab = 'Pending'; // 'Pending', 'Confirmed', 'History'

  // App color theme
  static const Color primaryColor = Color(0xFF1E3A5F);
  final Color _successColor = const Color(0xFF2EC4B6);
  final Color _warningColor = const Color(0xFFF77F00);
  final Color _backgroundColor = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      int userId;
      if (widget.currentUser.id is int) {
        userId = widget.currentUser.id as int;
      } else {
        userId = int.parse(widget.currentUser.id);
      }

      final url = ApiConfig.getOwnerBookings(userId);
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['bookings'] != null) {
          final bookings = List<Map<String, dynamic>>.from(data['bookings']);

          final pending = bookings.where((b) {
            final status = b['status']?.toString().trim().toLowerCase() ?? '';
            return status == 'pending';
          }).toList();

          final confirmed = bookings.where((b) {
            final status = b['status']?.toString().trim().toLowerCase() ?? '';
            return status == 'confirmed';
          }).toList();

          final history = bookings.where((b) {
            final status = b['status']?.toString().trim().toLowerCase() ?? '';
            return ['rejected', 'completed', 'cancelled'].contains(status);
          }).toList();

          if (mounted) {
            setState(() {
              _pendingReservations = pending;
              _confirmedReservations = confirmed;
              _historyReservations = history;
              _isLoading = false;
            });
          }
        } else {
          _setEmptyState();
        }
      } else {
        _setEmptyState();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: _warningColor,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading reservations: $e');
      _setEmptyState();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setEmptyState() {
    if (mounted) {
      setState(() {
        _pendingReservations = [];
        _confirmedReservations = [];
        _historyReservations = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.updateBookingStatus(bookingId, status)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'accept'
                    ? 'Booking accepted successfully'
                    : 'Booking declined',
              ),
              backgroundColor:
                  status == 'accept' ? _successColor : _warningColor,
            ),
          );
          _loadReservations();
        }
      } else {
        throw Exception('Failed to update booking status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Bookings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildCustomTabBar(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem('Pending', _pendingReservations.length),
          const SizedBox(width: 10),
          _buildTabItem('Confirmed', _confirmedReservations.length),
          const SizedBox(width: 10),
          _buildTabItem('History', _historyReservations.length),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int count) {
    final isSelected = _selectedTab == label;

    Color getBgColor() {
      if (!isSelected) return Colors.grey[100]!;
      switch (label) {
        case 'Pending':
          return _warningColor;
        case 'Confirmed':
          return _successColor;
        default:
          return primaryColor;
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = label;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? getBgColor() : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? getBgColor() : Colors.grey[200]!,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: getBgColor().withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withOpacity(0.95)
                      : Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    List<Map<String, dynamic>> currentList;
    switch (_selectedTab) {
      case 'Pending':
        currentList = _pendingReservations;
        break;
      case 'Confirmed':
        currentList = _confirmedReservations;
        break;
      case 'History':
        currentList = _historyReservations;
        break;
      default:
        currentList = [];
    }

    if (currentList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: currentList.length,
        itemBuilder: (context, index) {
          return _buildReservationCard(currentList[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    IconData icon;
    String message;
    String subMessage;

    switch (_selectedTab) {
      case 'Pending':
        icon = Icons.hourglass_empty_rounded;
        message = 'No Pending Requests';
        subMessage = 'New booking requests will appear here.';
        break;
      case 'Confirmed':
        icon = Icons.check_circle_outline_rounded;
        message = 'No Confirmed Bookings';
        subMessage = 'Approved bookings will show up here.';
        break;
      default:
        icon = Icons.history_rounded;
        message = 'No Booking History';
        subMessage = 'Past and cancelled bookings will be listed here.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final tenant = reservation['tenant'] ?? {};
    final property = reservation['property'] ?? {};
    final checkInDate = DateTime.parse(reservation['check_in_date']);
    final status = reservation['status']?.toString().toLowerCase() ?? '';

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = _warningColor;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'confirmed':
        statusColor = _successColor;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.task_alt_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Property Info & Status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Icon/Image Placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.home_work_rounded, color: primaryColor),
                ),
                const SizedBox(width: 12),
                // Title and ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property['title'] ?? 'Property Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking #${reservation['id']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Body: Tenant & Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Tenant Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Text(
                        tenant['full_name']?.substring(0, 1).toUpperCase() ??
                            'T',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
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
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            tenant['email'] ?? '',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Booking Details Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn(
                        'Check In',
                        DateFormat('MMM d, yyyy').format(checkInDate),
                        Icons.calendar_today_rounded,
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      _buildInfoColumn(
                        'Duration',
                        '${reservation['duration_months']} Months',
                        Icons.timer_outlined,
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      _buildInfoColumn(
                        'Total',
                        'RM ${reservation['total_amount']}',
                        Icons.payments_outlined,
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer: Actions (Only for Pending)
          if (status == 'pending') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _showDeclineDialog(reservation['id'].toString()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _showAcceptDialog(reservation['id'].toString()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _successColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon,
      {bool isHighlight = false}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? primaryColor : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  void _showAcceptDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: _successColor, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Accept Booking'),
          ],
        ),
        content: const Text(
          'Are you sure you want to accept this booking? The tenant will be notified immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateBookingStatus(bookingId, 'accept');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _successColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeclineDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Decline Booking'),
          ],
        ),
        content: const Text(
          'Are you sure you want to decline this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateBookingStatus(bookingId, 'reject');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Decline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
