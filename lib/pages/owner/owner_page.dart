import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart';
import 'package:my_app/models/dashboard_models.dart';
import 'package:my_app/services/dashboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

import 'listings_page.dart';
import 'reservations_page.dart';
import 'messages_page.dart';
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
  late List<Widget> _screens;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Dashboard data
  DashboardStats? _dashboardStats;
  List<RecentActivity> _recentActivities = [];
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Also update your initState to rebuild screens after data loads:
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize screens first
    _initializeScreens();

    _loadDashboardData().then((_) {
      // Rebuild screens after data loads
      if (mounted) {
        setState(() {
          _screens = [
            _buildDashboard(),
            const ListingsPage(),
            const ReservationsPage(),
            const MessagesPage(),
            ProfilePage(user: widget.user),
          ];
        });
      }
    });

    _animationController.forward();
  }

// Add this helper method:
  void _initializeScreens() {
    _screens = [
      _buildDashboard(),
      const ListingsPage(),
      const ReservationsPage(),
      const MessagesPage(),
      ProfilePage(user: widget.user),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load all dashboard data from API
  // Replace your _loadDashboardData method with this version that forces rebuild:
  Future<void> _loadDashboardData() async {
    print('🔄 Starting _loadDashboardData...');

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Safely convert user.id to int
      int userId;
      if (widget.user.id is int) {
        userId = widget.user.id as int;
      } else if (widget.user.id is String) {
        userId = int.parse(widget.user.id as String);
      } else {
        userId = int.parse(widget.user.id.toString());
      }

      print('🔄 Loading dashboard data for user ID: $userId');

      // Fetch all data concurrently
      final results = await Future.wait([
        DashboardService.getDashboardStats(userId),
        DashboardService.getRecentActivities(userId),
        DashboardService.getNotifications(userId),
      ]);

      print('📦 Future.wait results: ${results.length} items received');

      // Handle the results
      final dashboardStats = results[0] as DashboardStats?;
      final activities = results[1] as List<RecentActivity>? ?? [];
      final notifications = results[2] as List<NotificationItem>? ?? [];

      print('📊 Dashboard stats received: $dashboardStats');
      print('📝 Activities count: ${activities.length}');
      print('🔔 Notifications count: ${notifications.length}');

      // Force rebuild with multiple setState calls
      if (!mounted) return;

      // First, stop loading
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });

      // Small delay to ensure first setState completes
      await Future.delayed(const Duration(milliseconds: 50));

      // Then update data
      if (!mounted) return;
      setState(() {
        _dashboardStats = dashboardStats;
        _recentActivities = activities;
        _notifications = notifications;
      });

      print(
          '✅ State updated - Loading: $_isLoading, Stats null: ${_dashboardStats == null}');

      // Force one more rebuild to be absolutely sure
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() {
        // Trigger rebuild without changing anything
      });
    } catch (e, stackTrace) {
      print('❌ Error loading dashboard data: $e');
      print('📍 Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading data: $e';
      });
    }
  }

  // Refresh dashboard data
  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  @override
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
          _buildDashboard(), // Always rebuild dashboard
          const ListingsPage(),
          const ReservationsPage(),
          const MessagesPage(),
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
          ],
        ),
      ),
    );
  }

  // Replace your _buildDashboardContent method with this improved version:

  // Replace your _buildDashboardContent method with this complete version:
  // Simplified _buildDashboardContent that will definitely work:
  Widget _buildDashboardContent() {
    print('🏗️ Building dashboard content - Stats: $_dashboardStats');

    // Even if stats is null, show something
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

              // Show stats if available, otherwise show placeholder
              if (_dashboardStats != null) ...[
                Row(
                  children: [
                    _buildStatCard(
                      'Properties',
                      _dashboardStats!.totalProperties.toString(),
                      Icons.home_work,
                      Colors.blue,
                      () => setState(() => _currentIndex = 1),
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Occupied',
                      _dashboardStats!.occupancyRate,
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
                      _dashboardStats!.formattedIncome,
                      Icons.attach_money,
                      Colors.purple,
                      null,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Messages',
                      _dashboardStats!.unreadMessages.toString(),
                      Icons.message,
                      Colors.orange,
                      () => setState(() => _currentIndex = 3),
                    ),
                  ],
                ),
              ] else ...[
                // Fallback content when stats is null
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Dashboard stats not available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
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

  // Add this method to your _OwnerPageState class to validate dashboard state:

  void _validateDashboardState() {
    print('🔍 Dashboard State Validation:');
    print('  - Loading: $_isLoading');
    print('  - Error: $_errorMessage');
    print('  - Stats null: ${_dashboardStats == null}');
    if (_dashboardStats != null) {
      print('  - Properties: ${_dashboardStats!.totalProperties}');
      print('  - Income: ${_dashboardStats!.monthlyIncome}');
      print('  - Occupancy Rate: ${_dashboardStats!.occupancyRate}');
    }
    print('  - Activities count: ${_recentActivities.length}');
    print('  - Notifications count: ${_notifications.length}');
  }

// Also add this method to force a complete refresh:
  Future<void> _forceRefreshDashboard() async {
    print('🔄 Force refreshing dashboard...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _dashboardStats = null;
      _recentActivities.clear();
      _notifications.clear();
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Small delay
    await _loadDashboardData();
    _validateDashboardState();
  }

  void _debugDashboardState() {
    print('🔍 DASHBOARD DEBUG STATE:');
    print('  - _isLoading: $_isLoading');
    print('  - _errorMessage: $_errorMessage');
    print('  - _dashboardStats null: ${_dashboardStats == null}');
    print('  - _recentActivities length: ${_recentActivities.length}');
    print('  - _notifications length: ${_notifications.length}');
    print('  - Widget mounted: $mounted');
  }
}
