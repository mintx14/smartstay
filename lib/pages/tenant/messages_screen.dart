import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';

import 'package:my_app/config/api_config.dart'; // Adjust path as needed
import 'package:my_app/pages/tenant/toyyibpay_payment_screen.dart';
import 'package:my_app/models/booking_status.dart';

// --- NEW IMPORTS ---
// We import your REAL models and give them aliases to avoid naming conflicts
import 'package:my_app/models/user_model.dart' as MainUser;
import 'package:my_app/models/chat_message.dart' as MainChatMessage;
// --- END NEW IMPORTS ---

class MessagesScreen extends StatefulWidget {
  final String currentUserId;

  const MessagesScreen({super.key, required this.currentUserId});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with TickerProviderStateMixin {
  List<MessagePreview> messages = [];
  List<BookingStatus> bookings = [];
  bool isLoading = true;
  String selectedFilter = 'All';
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        if (_currentTabIndex == 1) {
          _loadBookings();
        }
      }
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadData();
    _animationController.forward();

    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      if (_currentTabIndex == 1) {
        _loadBookings();
      } else {
        _loadConversations();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadConversations(),
      _loadBookings(),
    ]);
  }

  Future<void> _loadConversations() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getConversationsUrlWithUserId(
            int.parse(widget.currentUserId))),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['conversations'] != null) {
          setState(() {
            messages = (data['conversations'] as List)
                .map((conv) => MessagePreview.fromJson(conv))
                .toList();
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Error loading conversations: $e');
    }
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    try {
      print('=== Loading Tenant Bookings ===');
      print('User ID: ${widget.currentUserId}');

      final response = await http.get(
        Uri.parse(ApiConfig.getTenantBookings(int.parse(widget.currentUserId))),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['bookings'] != null) {
          final bookingsList =
              List<Map<String, dynamic>>.from(data['bookings'] ?? []);

          setState(() {
            bookings = bookingsList.map((booking) {
              return BookingStatus.fromJson(booking);
            }).toList();
          });

          print('Successfully loaded ${bookings.length} bookings');
        } else {
          print('No bookings found or success is false');
          setState(() {
            bookings = [];
          });
        }
      } else {
        throw Exception('Failed to load bookings: ${response.body}');
      }
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        bookings = [];
      });
    }
  }

  List<MessagePreview> get filteredMessages {
    if (selectedFilter == 'All') return messages;
    return messages.where((msg) {
      switch (selectedFilter) {
        case 'Properties':
          return msg.otherUserType == 'Tenant';
        case 'Agents':
          return msg.otherUserType == 'Owner';
        case 'Roommates':
          return msg.otherUserType == 'Tenant';
        default:
          return true;
      }
    }).toList();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _openChat(MessagePreview message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OwnerChatScreen(
          currentUserId: widget.currentUserId,
          // --- UPDATED ---
          // Use your main user model and its constructor
          otherUser: MainUser.User(
            id: message.otherUserId,
            fullName: message.name,
            email: '', // Not available in MessagePreview
            userType: message.otherUserType,
            phoneNumber: '', // Not available in MessagePreview
          ),
          // --- END UPDATE ---
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.chat_bubble,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Messages & Bookings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentTabIndex == 0
                              ? '${filteredMessages.length} conversations'
                              : '${bookings.length} bookings',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.6),
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Messages'),
                      Tab(text: 'Bookings'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMessagesTab(),
                _buildBookingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (filteredMessages.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF667EEA),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 16),
          itemCount: filteredMessages.length,
          itemBuilder: (context, index) {
            return _buildMessageTile(filteredMessages[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    if (isLoading && bookings.isEmpty) {
      return _buildLoadingState();
    }

    if (bookings.isEmpty) {
      return _buildEmptyBookingsState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadBookings,
        color: const Color(0xFF667EEA),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _buildBookingCard(bookings[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingStatus booking, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _showBookingDetailsDialog(booking);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (booking.propertyImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            booking.propertyImageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child:
                                    const Icon(Icons.home, color: Colors.grey),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.home, color: Colors.grey),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.propertyTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.propertyAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(booking),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today,
                      'Check-in: ${DateFormat('MMM d, yyyy').format(DateTime.parse(booking.checkInDate))}'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.access_time,
                      'Duration: ${booking.durationMonths} months'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.attach_money,
                      'RM ${booking.monthlyRent.toStringAsFixed(0)}/month'),
                  if (booking.ownerName != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Color(0xFF667EEA),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Owner: ${booking.ownerName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          if (booking.isPending)
                            Text(
                              'Awaiting response',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (booking.isConfirmedAndNotPaid) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ToyyibPayPaymentScreen(
                                booking: booking,
                                currentUserId: int.parse(widget.currentUserId),
                              ),
                            ),
                          ).then((_) => _loadBookings());
                        },
                        icon: const Icon(Icons.payment),
                        label: Text(
                          'Pay Deposit (RM ${booking.depositAmount.toStringAsFixed(0)})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (booking.isPaymentCompleted) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Deposit Paid',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (booking.formattedPaidDate != null)
                                    Text(
                                      'Paid on ${booking.formattedPaidDate}',
                                      style: TextStyle(
                                        color: Colors.green.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (booking.paymentTransactionRef != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Transaction Ref:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        booking.paymentTransactionRef!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (booking.paymentAmount != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Amount Paid:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          'RM ${booking.paymentAmount!.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus booking) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String statusText;

    if (booking.isPaymentCompleted) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
      icon = Icons.check_circle;
      statusText = 'PAID';
    } else {
      switch (booking.status.toLowerCase()) {
        case 'confirmed':
          backgroundColor = Colors.blue.shade100;
          textColor = Colors.blue.shade800;
          icon = Icons.check_circle_outline;
          statusText = 'CONFIRMED';
          break;
        case 'pending':
          backgroundColor = Colors.orange.shade100;
          textColor = Colors.orange.shade800;
          icon = Icons.access_time;
          statusText = 'PENDING';
          break;
        case 'cancelled':
          backgroundColor = Colors.red.shade100;
          textColor = Colors.red.shade800;
          icon = Icons.cancel;
          statusText = 'CANCELLED';
          break;
        case 'completed':
          backgroundColor = Colors.purple.shade100;
          textColor = Colors.purple.shade800;
          icon = Icons.done_all;
          statusText = 'COMPLETED';
          break;
        default:
          backgroundColor = Colors.grey.shade100;
          textColor = Colors.grey.shade800;
          icon = Icons.info;
          statusText = booking.status.toUpperCase();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetailsDialog(BookingStatus booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              booking.isPaymentCompleted ? Icons.payment : Icons.receipt_long,
              color: booking.isPaymentCompleted
                  ? Colors.green
                  : const Color(0xFF667EEA),
            ),
            const SizedBox(width: 8),
            Text('Booking #${booking.id}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Property', booking.propertyTitle),
              _buildDetailRow('Address', booking.propertyAddress),
              _buildDetailRow(
                  'Check-in',
                  DateFormat('MMMM d, yyyy')
                      .format(DateTime.parse(booking.checkInDate))),
              _buildDetailRow('Duration', '${booking.durationMonths} months'),
              _buildDetailRow('Monthly Rent',
                  'RM ${booking.monthlyRent.toStringAsFixed(2)}'),
              _buildDetailRow(
                  'Deposit', 'RM ${booking.depositAmount.toStringAsFixed(2)}'),
              _buildDetailRow(
                  'Total', 'RM ${booking.totalAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _buildDetailRow('Status', booking.displayStatus),
              if (booking.hasPaymentTransaction) ...[
                const Divider(),
                Text(
                  'Payment Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Payment Status',
                    booking.paymentStatus?.toUpperCase() ?? 'NO PAYMENT'),
                if (booking.paymentTransactionRef != null)
                  _buildDetailRow(
                      'Transaction Ref', booking.paymentTransactionRef!),
                if (booking.paymentAmount != null)
                  _buildDetailRow('Amount Paid',
                      'RM ${booking.paymentAmount!.toStringAsFixed(2)}'),
                if (booking.paidAt != null)
                  _buildDetailRow(
                      'Paid On',
                      DateFormat('MMMM d, yyyy h:mm a')
                          .format(DateTime.parse(booking.paidAt!))),
              ],
              if (booking.ownerName != null) ...[
                const Divider(),
                _buildDetailRow('Owner', booking.ownerName!),
                if (booking.ownerPhone != null)
                  _buildDetailRow('Contact', booking.ownerPhone!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (booking.isConfirmedAndNotPaid)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ToyyibPayPaymentScreen(
                      booking: booking,
                      currentUserId: int.parse(widget.currentUserId),
                    ),
                  ),
                ).then((_) => _loadBookings());
              },
              icon: const Icon(Icons.payment),
              label: const Text('Pay Deposit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageTile(MessagePreview message, int index) {
    final hasActiveBooking = bookings.any((booking) =>
        booking.tenantId == message.otherUserId &&
        (booking.status.toLowerCase() == 'confirmed' ||
            booking.status.toLowerCase() == 'pending'));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openChat(message),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Hero(
                    tag: 'avatar_${message.otherUserId}',
                    child: Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF667EEA),
                                Color(0xFF764BA2),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              message.name.isNotEmpty
                                  ? message.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        if (hasActiveBooking)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.home,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                message.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.grey.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              message.time,
                              style: TextStyle(
                                fontSize: 12,
                                color: message.unread > 0
                                    ? const Color(0xFF667EEA)
                                    : Colors.grey.shade500,
                                fontWeight: message.unread > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                message.lastMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: message.unread > 0
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade600,
                                  fontWeight: message.unread > 0
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (message.unread > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  message.unread.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF667EEA),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBookingsState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking history will appear here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerChatScreen extends StatefulWidget {
  final String currentUserId;
  // --- UPDATED ---
  // Use your main user model
  final MainUser.User otherUser;
  // --- END UPDATE ---

  const OwnerChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUser,
  });

  @override
  State<OwnerChatScreen> createState() => _OwnerChatScreenState();
}

class _OwnerChatScreenState extends State<OwnerChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // --- UPDATED ---
  // Use your main chat message model
  List<MainChatMessage.ChatMessage> messages = [];
  // --- END UPDATE ---
  bool isLoading = true;
  Timer? _refreshTimer;
  bool _isTyping = false;
  late AnimationController _sendButtonAnimController;
  late Animation<double> _sendButtonAnimation;

  @override
  void initState() {
    super.initState();
    _sendButtonAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sendButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sendButtonAnimController,
      curve: Curves.easeInOut,
    ));
    _messageController.addListener(_onMessageChanged);
    _loadMessages();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages(showLoading: false);
    });
  }

  void _onMessageChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
      if (_isTyping) {
        _sendButtonAnimController.forward();
      } else {
        _sendButtonAnimController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _sendButtonAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getMessagesUrlWithParams(
            int.parse(widget.currentUserId), int.parse(widget.otherUser.id))),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['messages'] != null) {
          setState(() {
            // --- UPDATED ---
            // Use your main chat message model
            messages = (data['messages'] as List)
                .map((msg) => MainChatMessage.ChatMessage.fromJson(msg))
                .toList();
            // --- END UPDATE ---
            isLoading = false;
          });
          _scrollToBottom();
        }
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (showLoading) {
        _showError('Error loading messages: $e');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendMessageUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_id': widget.currentUserId,
          'receiver_id': widget.otherUser.id,
          'message': messageText,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _loadMessages(showLoading: false);
        } else {
          throw Exception(data['error'] ?? 'Failed to send message');
        }
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      _showError('Error sending message: $e');
      _messageController.text = messageText;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Hero(
              tag: 'avatar_${widget.otherUser.id}',
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.otherUser.fullName.isNotEmpty
                        ? widget.otherUser.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Color(0xFF667EEA),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.otherUser.userType,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF667EEA),
                    ),
                  )
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final showDate = index == 0 ||
                              _isDifferentDay(
                                messages[index - 1].createdAt,
                                message.createdAt,
                              );
                          return Column(
                            children: [
                              if (showDate)
                                _buildDateDivider(message.createdAt),
                              _buildMessageBubble(message, index),
                            ],
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  bool _isDifferentDay(String date1, String date2) {
    final d1 = DateTime.parse(date1);
    final d2 = DateTime.parse(date2);
    return d1.day != d2.day || d1.month != d2.month || d1.year != d2.year;
  }

  Widget _buildDateDivider(String date) {
    final parsedDate = DateTime.parse(date);
    final now = DateTime.now();
    String dateText;

    if (parsedDate.day == now.day &&
        parsedDate.month == now.month &&
        parsedDate.year == now.year) {
      dateText = 'Today';
    } else if (parsedDate.day == now.day - 1 &&
        parsedDate.month == now.month &&
        parsedDate.year == now.year) {
      dateText = 'Yesterday';
    } else {
      dateText = '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.grey.shade300),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }

  // --- UPDATED ---
  // Use your main chat message model
  Widget _buildMessageBubble(MainChatMessage.ChatMessage message, int index) {
    // --- END UPDATE ---
    final isOwnMessage = message.isOwnMessage;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isOwnMessage) ...[
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF667EEA),
                child: Text(
                  widget.otherUser.fullName.isNotEmpty
                      ? widget.otherUser.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isOwnMessage
                      ? const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        )
                      : null,
                  color: isOwnMessage ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isOwnMessage ? 20 : 4),
                    bottomRight: Radius.circular(isOwnMessage ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.message,
                      style: TextStyle(
                        color:
                            isOwnMessage ? Colors.white : Colors.grey.shade800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMessageTime(message.createdAt),
                      style: TextStyle(
                        color: isOwnMessage
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isOwnMessage) const SizedBox(width: 50),
            if (!isOwnMessage) const SizedBox(width: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: _sendButtonAnimation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(String timestamp) {
    try {
      final DateTime time = DateTime.parse(timestamp);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

class MessagePreview {
  final int conversationId;
  final String otherUserId;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final String otherUserType;

  MessagePreview({
    required this.conversationId,
    required this.otherUserId,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.otherUserType,
  });

  factory MessagePreview.fromJson(Map<String, dynamic> json) {
    return MessagePreview(
      conversationId: json['conversation_id'],
      otherUserId: json['other_user_id'].toString(),
      name: json['other_user_name'] ?? 'Unknown',
      lastMessage: json['last_message'] ?? 'No messages yet',
      time: _formatTime(json['last_message_time']),
      unread: json['unread_count'] ?? 0,
      otherUserType: json['other_user_type'] ?? 'Unknown',
    );
  }

  static String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final DateTime time = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(time);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Now';
      }
    } catch (e) {
      return '';
    }
  }
}

// --- DELETED ---
// The old, local 'User' class that was here has been removed.
// ---

// --- DELETED ---
// The old, local 'ChatMessage' class that was here has been removed.
// ---
