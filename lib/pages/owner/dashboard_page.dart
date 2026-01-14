import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // App color theme
  static const Color primaryColor = Color(0xFF1E3A5F);

  bool _isLoading = true;
  String? _error;

  // Dashboard data
  Map<String, dynamic>? _stats;
  List<dynamic> _recentBookings = [];
  List<dynamic> _recentMessages = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch all dashboard data
      await Future.wait([
        _fetchStats(userId),
        _fetchRecentBookings(userId),
        _fetchRecentMessages(userId),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStats(int userId) async {
    try {
      final url = ApiConfig.getDashboardUrlWithParams('stats', userId);
      print('📊 Fetching stats from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Stats response: $data');

        if (data['success'] == true) {
          setState(() {
            _stats = data['data'];
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load stats');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching stats: $e');
      // Set default values if stats fetch fails
      setState(() {
        _stats = {
          'total_properties': 0,
          'occupied_properties': 0,
          'property_occupancy_display': '0/0',
          'monthly_income': 0.0,
          'formatted_income': 'RM 0.00',
          'unread_messages': 0,
        };
      });
    }
  }

  Future<void> _fetchRecentBookings(int userId) async {
    try {
      final url = '${ApiConfig.baseUrl}/dashboard.php/bookings/$userId';
      print('📋 Fetching bookings from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📋 Bookings response: $data');

        if (data['success'] == true) {
          setState(() {
            // Get only the 3 most recent bookings
            _recentBookings = (data['data'] as List).take(3).toList();
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching bookings: $e');
      setState(() {
        _recentBookings = [];
      });
    }
  }

  Future<void> _fetchRecentMessages(int userId) async {
    try {
      // Use the same endpoint as the messages page
      final url = ApiConfig.getConversationsUrlWithUserId(userId);
      print('💬 Fetching conversations from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('💬 Conversations response: $data');

        if (data['conversations'] != null) {
          final conversations = data['conversations'] as List;
          setState(() {
            // Get only the 3 most recent conversations
            _recentMessages = conversations.take(3).toList();
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching conversations: $e');
      setState(() {
        _recentMessages = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade50, Colors.white],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildStatsCards(),
              const SizedBox(height: 28),
              _buildSectionTitle('Recent Reservations'),
              const SizedBox(height: 14),
              _buildRecentReservations(),
              const SizedBox(height: 28),
              _buildSectionTitle('Recent Messages'),
              const SizedBox(height: 14),
              _buildRecentMessages(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final stats = _stats ?? {};
    final totalProperties = stats['total_properties'] ?? 0;
    final occupiedProperties = stats['occupied_properties'] ?? 0;
    final notOccupiedProperties = stats['not_occupied_properties'] ?? 0;
    final formattedIncome = stats['formatted_income'] ?? 'RM 0.00';
    final unreadMessages = stats['unread_messages'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Listings',
                totalProperties.toString(),
                Icons.home_work_rounded,
                const Color(0xFF4361EE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Available',
                notOccupiedProperties.toString(),
                Icons.check_circle_outline_rounded,
                const Color(0xFF2EC4B6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Occupied',
                occupiedProperties.toString(),
                Icons.meeting_room_rounded,
                const Color(0xFFF77F00),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Messages',
                unreadMessages.toString(),
                Icons.message_rounded,
                const Color(0xFF9B5DE5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Monthly income card - full width
        _buildIncomeCard(formattedIncome),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(String income) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF3D5A80)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Income',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  income,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReservations() {
    if (_recentBookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No recent reservations',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentBookings.asMap().entries.map((entry) {
        final index = entry.key;
        final booking = entry.value;

        final bookingId = booking['id'] ?? '';
        final tenantName = booking['tenant_name'] ?? 'Unknown Tenant';
        final propertyTitle = booking['property_title'] ?? 'Property';
        final status = booking['status'] ?? 'pending';
        final paymentStatus = booking['payment_status'] ?? 'unpaid';

        // Determine display status and color
        String displayStatus;
        Color statusColor;

        if (paymentStatus == 'paid' && status == 'confirmed') {
          displayStatus = 'Confirmed';
          statusColor = const Color(0xFF2EC4B6);
        } else if (status == 'pending') {
          displayStatus = 'Pending';
          statusColor = const Color(0xFFF77F00);
        } else if (status == 'cancelled') {
          displayStatus = 'Cancelled';
          statusColor = const Color(0xFFEF476F);
        } else {
          displayStatus = status.toString().toUpperCase();
          statusColor = Colors.grey;
        }

        final colors = [
          const Color(0xFF4361EE),
          const Color(0xFF2EC4B6),
          const Color(0xFF9B5DE5),
        ];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Navigate to booking details
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors[index % colors.length].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${bookingId.toString().padLeft(4, '0')}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors[index % colors.length],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenantName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            propertyTitle,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentMessages() {
    if (_recentMessages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.message_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No recent messages',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentMessages.asMap().entries.map((entry) {
        final index = entry.key;
        final conversation = entry.value;

        // Extract conversation data
        final otherUserName = conversation['other_user_name'] ?? 'Unknown User';
        final lastMessage = conversation['last_message'] ?? 'No messages yet';
        final unreadCount = conversation['unread_count'] ?? 0;
        final lastMessageTime = conversation['last_message_time'];

        // Format time
        String timeAgo = 'Recently';
        if (lastMessageTime != null) {
          try {
            final messageTime = DateTime.parse(lastMessageTime);
            final now = DateTime.now();
            final difference = now.difference(messageTime);

            if (difference.inMinutes < 1) {
              timeAgo = 'Just now';
            } else if (difference.inHours < 1) {
              timeAgo = '${difference.inMinutes}m ago';
            } else if (difference.inDays < 1) {
              timeAgo = '${difference.inHours}h ago';
            } else if (difference.inDays < 7) {
              timeAgo = '${difference.inDays}d ago';
            } else {
              timeAgo = '${(difference.inDays / 7).floor()}w ago';
            }
          } catch (e) {
            print('Error parsing time: $e');
          }
        }

        final colors = [
          const Color(0xFF4361EE),
          const Color(0xFFF77F00),
          const Color(0xFF2EC4B6),
        ];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Navigate to messages
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors[index % colors.length],
                            colors[index % colors.length].withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          otherUserName.isNotEmpty
                              ? otherUserName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherUserName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF2D3142),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMessage,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
