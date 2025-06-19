import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/models/dashboard_models.dart';
import 'package:my_app/services/dashboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
// import 'dart:convert';
// import 'package:http/http.dart' as http;
import 'listings_page.dart';
import 'reservations_page.dart';
import 'messages_page.dart' as owner_messaging; // Add prefix to avoid conflicts
import 'profile_page.dart';
import 'add_listing_page.dart';

class OwnerPage extends StatefulWidget {
  final User user;

  const OwnerPage({super.key, required this.user});

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  // Dashboard data
  DashboardStats? _dashboardStats;
  List<RecentActivity> _recentActivities = [];
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Debug user data first
    _debugUserData();

    // Initialize screens first
    _initializeScreens();

    _loadDashboardData().then((_) {
      // Rebuild screens after data loads
      if (mounted) {
        setState(() {});
      }
    });

    _animationController.forward();
  }

  // Add debug method to check user data
  void _debugUserData() {
    print('🔍 DEBUG: User data check');
    print('   User ID: "${widget.user.id}"');
    print('   User ID type: ${widget.user.id.runtimeType}');
    print('   User ID length: ${widget.user.id.toString().length}');
    print('   User name: "${widget.user.fullName}"');
    print('   User email: "${widget.user.email}"');
    print('   User type: "${widget.user.userType}"');
  }

  // Helper method to safely parse user ID
  int? _getSafeUserId() {
    try {
      // Check if user.id is null or empty
      if (widget.user.id.toString().trim().isEmpty) {
        print('❌ User ID is null or empty');
        return null;
      }

      String userIdStr = widget.user.id.toString().trim();
      print('🔄 Attempting to parse user ID: "$userIdStr"');

      // If it's already an int, return it
      if (widget.user.id is int) {
        print('✅ User ID is already an int: ${widget.user.id}');
        return widget.user.id as int;
      }

      // Try to parse as int
      int userId = int.parse(userIdStr);
      print('✅ Successfully parsed user ID: $userId');
      return userId;
    } catch (e) {
      print('❌ Error parsing user ID "${widget.user.id}": $e');
      return null;
    }
  }

  // Add this helper method:
  void _initializeScreens() {}

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load all dashboard data from API
// Replace your _loadDashboardData method in OwnerPage with this:
  Future<void> _loadDashboardData() async {
    print('🔄 Starting _loadDashboardData...');

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user ID is valid using the new service method
      if (!DashboardService.isValidUserId(widget.user.id)) {
        throw Exception('Invalid user session. Please log in again.');
      }

      print('🔄 Loading dashboard data for user ID: ${widget.user.id}');

      // Option 1: Use the new getAllDashboardData method (recommended)
      final allData =
          await DashboardService.getAllDashboardData(widget.user.id);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _dashboardStats = allData['stats'] as DashboardStats?;
        _recentActivities = allData['activities'] as List<RecentActivity>;
        _notifications = allData['notifications'] as List<NotificationItem>;
        _errorMessage = null;
      });

      print('✅ All dashboard data loaded successfully');
      print('📊 Stats: ${_dashboardStats != null}');
      print('📝 Activities: ${_recentActivities.length}');
      print('🔔 Notifications: ${_notifications.length}');

      /* 
    // Option 2: Keep individual calls if you prefer (alternative approach)
    DashboardStats? dashboardStats;
    List<RecentActivity> activities = [];
    List<NotificationItem> notifications = [];

    try {
      print('📊 Fetching dashboard stats...');
      dashboardStats = await DashboardService.getDashboardStats(widget.user.id);
      print('📊 Dashboard stats result: $dashboardStats');
    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      // Continue with other calls even if stats fail
    }

    try {
      print('📝 Fetching recent activities...');
      activities = await DashboardService.getRecentActivities(widget.user.id);
      print('📝 Activities count: ${activities.length}');
    } catch (e) {
      print('❌ Error fetching activities: $e');
      // Continue with empty list
    }

    try {
      print('🔔 Fetching notifications...');
      notifications = await DashboardService.getNotifications(widget.user.id);
      print('🔔 Notifications count: ${notifications.length}');
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      // Continue with empty list
    }

    // Update state with whatever data we managed to fetch
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _dashboardStats = dashboardStats;
      _recentActivities = activities;
      _notifications = notifications;
      _errorMessage = null;
    });
    */
    } catch (e, stackTrace) {
      print('❌ Error in _loadDashboardData: $e');
      print('📍 Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Refresh dashboard data
  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    print(
        '🏗️ Building OwnerPage - Current index: $_currentIndex, Loading: $_isLoading');

    return Scaffold(
      key: ValueKey(
          'owner_page_${_isLoading}_${_dashboardStats != null}'), // Force rebuild
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          const ListingsPage(),
          ReservationsPage(currentUser: widget.user),
          _buildMessagesPage(), // ✅ Now uses the helper method
          ProfilePage(user: widget.user),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF190152),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_work),
              label: 'Properties',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF190152),
        elevation: 0,
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Debug user info button (remove in production)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.info, color: Colors.yellow),
              onPressed: () {
                _showUserDebugInfo();
              },
            ),
          // Notification icon with real count
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
                if (_notifications.where((n) => !n.isRead).isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showNotifications,
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshDashboard,
          ),
          // Debug button (remove in production)
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.yellow),
              onPressed: () {
                setState(() {
                  _isLoading = false;
                });
                print('🐛 Debug: Forced loading to false');
              },
            ),
          // Logout icon
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  // Add debug dialog method
  void _showUserDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug: User Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: "${widget.user.id}"'),
            Text('Type: ${widget.user.id.runtimeType}'),
            Text('Length: ${widget.user.id.toString().length}'),
            Text('Name: "${widget.user.fullName}"'),
            Text('Email: "${widget.user.email}"'),
            Text('Phone: "${widget.user.phoneNumber}"'),
            Text('User Type: "${widget.user.userType}"'),
            const SizedBox(height: 10),
            Text('Parsed ID: ${_getSafeUserId()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(); // Force logout to re-login
            },
            child: const Text('Re-login'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesPage() {
    try {
      // Use the safe method to get user ID
      int? userId = _getSafeUserId();

      if (userId == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Invalid user session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please log in again',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF190152),
                ),
                child: const Text(
                  'Login Again',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }

      return owner_messaging.MessagesPage(currentUserId: userId);
    } catch (e) {
      print('Error in _buildMessagesPage: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${e.toString()}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF190152),
              ),
              child: const Text(
                'Login Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Properties';
      case 2:
        return 'Bookings';
      case 3:
        return 'Messages';
      case 4:
        return 'Profile';
      default:
        return 'Owner Dashboard';
    }
  }

  // Replace your _buildDashboard method to add debug info:
  Widget _buildDashboard() {
    print(
        '🏗️ Building dashboard - Loading: $_isLoading, Error: $_errorMessage, Stats: ${_dashboardStats != null}');

    return Container(
      key: ValueKey(
          'dashboard_${_isLoading}_${_dashboardStats != null}'), // Force rebuild
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[50]!, Colors.white],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF190152),
                      const Color(0xFF190152).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF190152).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${widget.user.fullName.split(' ')[0]}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage your properties easily',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          // Debug info in development
                          if (kDebugMode) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Debug: ID="${widget.user.id}" (${widget.user.id.runtimeType})',
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Show loading OR content - never both
              _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildDashboardContent(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF190152)),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _refreshDashboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF190152),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Re-login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Replace your _buildDashboardContent method with this improved version:

  // Replace your _buildDashboardContent method with this complete version:
  Widget _buildDashboardContent() {
    print('🏗️ Building dashboard content - Stats: $_dashboardStats');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Overview Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF190152),
                ),
              ),
              const SizedBox(height: 16),

              // Updated stats cards with new format
              Row(
                children: [
                  _buildStatCard(
                    'Total Properties',
                    _dashboardStats?.totalProperties.toString() ?? '0',
                    Icons.home_work,
                    Colors.blue,
                    () => setState(() => _currentIndex = 1),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Occupied/Total', // ✅ New label
                    _dashboardStats?.propertyOccupancyDisplay ??
                        '0/0', // ✅ New format "0/2"
                    Icons.people,
                    Colors.green,
                    () => setState(() => _currentIndex = 2),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                    'This Month',
                    _dashboardStats?.formattedIncome ?? 'RM 0',
                    Icons.attach_money,
                    Colors.purple,
                    null,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Messages',
                    _dashboardStats?.unreadMessages.toString() ?? '0',
                    Icons.message,
                    Colors.orange,
                    () => setState(() => _currentIndex = 3),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        // Quick Actions Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF190152),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildQuickAction(
                    'Add Property',
                    Icons.add_home,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddListingPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    'View Bookings',
                    Icons.calendar_today,
                    Colors.green,
                    () => setState(() => _currentIndex = 2),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    'Messages',
                    Icons.message,
                    Colors.orange,
                    () => setState(() => _currentIndex = 3),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Recent Activities Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF190152),
                ),
              ),
              const SizedBox(height: 16),
              if (_recentActivities.isEmpty)
                _buildNoActivitiesMessage()
              else
                Column(
                  children: _recentActivities
                      .take(5)
                      .map((activity) => _buildActivityItem(activity))
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoActivitiesMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'No recent activities',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10.0,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(RecentActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: activity.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(activity.icon, color: activity.color, size: 20),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          activity.timeAgo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          // Handle activity tap based on type
          switch (activity.type) {
            case 'booking_request':
              setState(() => _currentIndex = 2);
              break;
            case 'new_message':
              setState(() => _currentIndex = 3);
              break;
            case 'property_added':
              setState(() => _currentIndex = 1);
              break;
          }
        },
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF190152),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) =>
                          _buildNotificationItem(_notifications[index]),
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.grey[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.grey.withOpacity(0.2)
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notification.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(notification.icon, color: notification.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight:
                        notification.isRead ? FontWeight.w500 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
