// services/dashboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_models.dart';
// ADD THIS IMPORT
import 'package:smartstay/config/api_config.dart'; // Adjust path as needed

class DashboardService {
  // Helper method to safely convert user ID to int
  static int? _safeParseUserId(dynamic userId) {
    if (userId == null) {
      print('❌ User ID is null');
      return null;
    }

    try {
      if (userId is int) {
        print('✅ User ID is already int: $userId');
        return userId;
      }

      String userIdStr = userId.toString().trim();
      if (userIdStr.isEmpty) {
        print('❌ User ID string is empty');
        return null;
      }

      int parsedId = int.parse(userIdStr);
      print('✅ Successfully parsed user ID: $parsedId');
      return parsedId;
    } catch (e) {
      print('❌ Failed to parse user ID "$userId": $e');
      return null;
    }
  }

  // ============================================
  // ENHANCED DASHBOARD STATS (with occupancy)
  // ============================================

  static Future<DashboardStats?> getDashboardStats(dynamic userId) async {
    try {
      // Safely parse the user ID
      int? ownerId = _safeParseUserId(userId);
      if (ownerId == null) {
        print('❌ Invalid user ID provided to getDashboardStats: $userId');
        throw Exception('Invalid user ID. Please log in again.');
      }

      final url = ApiConfig.getDashboardUrlWithParams('stats', ownerId);
      print('🌐 API Call URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('📋 Decoded JSON: $jsonData');

        if (jsonData['success'] == true) {
          print('✅ API Success, creating DashboardStats...');
          final stats = DashboardStats.fromJson(jsonData['data']);
          print('📊 Created stats: $stats');
          return stats;
        } else {
          print('❌ API returned success=false: ${jsonData['message']}');
          throw Exception(
              'API Error: ${jsonData['message'] ?? 'Unknown error'}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in getDashboardStats: $e');
      rethrow; // Re-throw to let the caller handle it
    }
  }

  // ============================================
  // NEW: OCCUPANCY SPECIFIC METHODS
  // ============================================

  /// Get occupancy statistics (occupied/total properties)
  static Future<Map<String, dynamic>> getOccupancyStats(dynamic userId) async {
    try {
      int? ownerId = _safeParseUserId(userId);
      if (ownerId == null) {
        throw Exception('Invalid user ID provided');
      }

      final url = '${ApiConfig.baseUrl}/dashboard.php/occupancy-stats/$ownerId';
      print('🏠 Occupancy Stats API Call: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Occupancy Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return jsonData['data'];
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to fetch occupancy stats');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Error in getOccupancyStats: $e');
      rethrow;
    }
  }

  /// Get list of occupied properties with details
  static Future<List<Map<String, dynamic>>> getOccupiedProperties(
      dynamic userId) async {
    try {
      int? ownerId = _safeParseUserId(userId);
      if (ownerId == null) {
        throw Exception('Invalid user ID provided');
      }

      final url = '${ApiConfig.baseUrl}/dashboard.php/occupied/$ownerId';
      print('🏠 Occupied Properties API Call: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Occupied Properties Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to fetch occupied properties');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Error in getOccupiedProperties: $e');
      rethrow;
    }
  }

  // ============================================
  // NEW: BOOKING MANAGEMENT METHODS
  // ============================================

  /// Get all bookings for an owner with optional filters
  static Future<List<Map<String, dynamic>>> getOwnerBookings(
    dynamic userId, {
    String? status,
    String? paymentStatus,
    int? listingId,
  }) async {
    try {
      int? ownerId = _safeParseUserId(userId);
      if (ownerId == null) {
        throw Exception('Invalid user ID provided');
      }

      String url = '${ApiConfig.baseUrl}/dashboard.php/bookings/$ownerId';
      List<String> queryParams = [];

      if (status != null) queryParams.add('status=$status');
      if (paymentStatus != null) {
        queryParams.add('payment_status=$paymentStatus');
      }
      if (listingId != null) queryParams.add('listing_id=$listingId');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('📋 Bookings API Call: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch bookings');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Error in getOwnerBookings: $e');
      rethrow;
    }
  }

  /// Get specific booking by ID
  static Future<Map<String, dynamic>> getBookingById(int bookingId) async {
    try {
      final url = '${ApiConfig.baseUrl}/dashboard.php/booking/$bookingId';
      print('📄 Booking Details API Call: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return jsonData['data'];
        } else {
          throw Exception(jsonData['message'] ?? 'Booking not found');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Error in getBookingById: $e');
      rethrow;
    }
  }

  /// Update payment status for a booking
  static Future<Map<String, dynamic>> updatePaymentStatus(
    int bookingId,
    String paymentStatus, {
    String? transactionId,
    String? receiptUrl,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/dashboard.php/payment/$bookingId';
      print('💰 Payment Update API Call: $url');

      final body = {
        'payment_status': paymentStatus,
        if (transactionId != null) 'transaction_id': transactionId,
        if (receiptUrl != null) 'receipt_url': receiptUrl,
      };

      print('💰 Payment Update Body: $body');

      final response = await http
          .put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      print(
          '📡 Payment Update Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return jsonData;
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to update payment status');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Error in updatePaymentStatus: $e');
      rethrow;
    }
  }

  // ============================================
  // EXISTING METHODS (Enhanced)
  // ============================================

  static Future<List<RecentActivity>> getRecentActivities(
      dynamic userId) async {
    try {
      // Safely parse the user ID
      int? ownerId = _safeParseUserId(userId);
      if (ownerId == null) {
        print('❌ Invalid user ID provided to getRecentActivities: $userId');
        return []; // Return empty list instead of throwing for activities
      }

      final url = ApiConfig.getDashboardUrlWithParams('activities', ownerId);
      print('🌐 Activities API Call: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print(
          '📡 Activities Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          List<dynamic> activitiesJson = jsonData['data'] ?? [];
          final activities = activitiesJson
              .map((json) => RecentActivity.fromJson(json))
              .toList();
          print('📝 Activities created: ${activities.length} items');
          return activities;
        } else {
          print(
              '❌ Activities API returned success=false: ${jsonData['message']}');
          return [];
        }
      } else {
        print('❌ Activities HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception in getRecentActivities: $e');
      return []; // Return empty list on error
    }
  }

  static Future<List<NotificationItem>> getNotifications(dynamic userId) async {
    try {
      // Safely parse the user ID
      int? ownerId = _safeParseUserId(userId);
      if (ownerId == null) {
        print('❌ Invalid user ID provided to getNotifications: $userId');
        return []; // Return empty list instead of throwing for notifications
      }

      final url = ApiConfig.getDashboardUrlWithParams('notifications', ownerId);
      print('🌐 Notifications API Call: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print(
          '📡 Notifications Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          List<dynamic> notificationsJson = jsonData['data'] ?? [];
          final notifications = notificationsJson
              .map((json) => NotificationItem.fromJson(json))
              .toList();
          print('🔔 Notifications created: ${notifications.length} items');
          return notifications;
        } else {
          print(
              '❌ Notifications API returned success=false: ${jsonData['message']}');
          return [];
        }
      } else {
        print('❌ Notifications HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception in getNotifications: $e');
      return []; // Return empty list on error
    }
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  // Additional helper method to test if user ID is valid
  static bool isValidUserId(dynamic userId) {
    return _safeParseUserId(userId) != null;
  }

  /// Get all dashboard data at once (ENHANCED - now includes occupancy)
  static Future<Map<String, dynamic>> getAllDashboardData(
      dynamic userId) async {
    try {
      // Validate user ID first
      if (!isValidUserId(userId)) {
        throw Exception('Invalid user ID provided');
      }

      int? ownerId = _safeParseUserId(userId);
      print('🔄 Loading all dashboard data for user: $ownerId');

      // Option 1: Use the new single API call (RECOMMENDED)
      final url = ApiConfig.getDashboardUrlWithParams('all', ownerId!);
      print('🌐 All Dashboard Data API Call: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return {
            'stats': jsonData['stats'] != null
                ? DashboardStats.fromJson(jsonData['stats'])
                : null,
            'activities': (jsonData['activities'] as List? ?? [])
                .map((json) => RecentActivity.fromJson(json))
                .toList(),
            'notifications': (jsonData['notifications'] as List? ?? [])
                .map((json) => NotificationItem.fromJson(json))
                .toList(),
          };
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to fetch dashboard data');
        }
      }

      // Option 2: Fallback to individual calls if the 'all' endpoint fails
      print('⚠️ Single call failed, falling back to individual calls');

      final results = await Future.wait([
        getDashboardStats(userId),
        getRecentActivities(userId),
        getNotifications(userId),
      ]);

      return {
        'stats': results[0] as DashboardStats?,
        'activities': results[1] as List<RecentActivity>,
        'notifications': results[2] as List<NotificationItem>,
      };
    } catch (e) {
      print('❌ Error in getAllDashboardData: $e');
      rethrow;
    }
  }

  // ============================================
  // NEW: PAYMENT TRANSACTION METHODS
  // ============================================

  /// Get payment transactions for an owner with optional filters
  static Future<Map<String, dynamic>> getPaymentTransactions(
    dynamic userId, {
    String? status,
    int? month,
    int? year,
    int? bookingId,
  }) async {
    try {
      int? ownerId = _safeParseUserId(userId);
      if (ownerId == null) {
        throw Exception('Invalid user ID provided');
      }

      String url = '${ApiConfig.baseUrl}/dashboard.php/payments/$ownerId';
      List<String> queryParams = [];

      if (status != null) queryParams.add('status=$status');
      if (month != null) queryParams.add('month=$month');
      if (year != null) queryParams.add('year=$year');
      if (bookingId != null) queryParams.add('booking_id=$bookingId');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('💰 Payment Transactions API Call: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return jsonData;
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to fetch payment transactions');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Error in getPaymentTransactions: $e');
      rethrow;
    }
  }

  /// Get monthly income summary for the year
  static Future<Map<String, dynamic>> getMonthlyIncomeSummary(
    dynamic userId, {
    int? year,
  }) async {
    try {
      int? ownerId = _safeParseUserId(userId);
      if (ownerId == null) {
        throw Exception('Invalid user ID provided');
      }

      String url = '${ApiConfig.baseUrl}/dashboard.php/income-summary/$ownerId';
      if (year != null) {
        url += '?year=$year';
      }

      print('📊 Monthly Income Summary API Call: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return jsonData;
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to fetch income summary');
        }
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Error in getMonthlyIncomeSummary: $e');
      rethrow;
    }
  }

  // ============================================
  // CONVENIENCE METHODS FOR PAYMENTS
  // ============================================

  /// Get current month's payments
  static Future<Map<String, dynamic>> getCurrentMonthPayments(
      dynamic userId) async {
    final now = DateTime.now();
    return getPaymentTransactions(
      userId,
      status: 'paid',
      month: now.month,
      year: now.year,
    );
  }

  /// Get total income for current month (quick method)
  static Future<double> getCurrentMonthIncome(dynamic userId) async {
    try {
      final payments = await getCurrentMonthPayments(userId);
      return (payments['total_amount'] ?? 0.0).toDouble();
    } catch (e) {
      print('❌ Error getting current month income: $e');
      return 0.0;
    }
  }

  /// Get paid transactions only
  static Future<List<Map<String, dynamic>>> getPaidTransactions(
      dynamic userId) async {
    try {
      final result = await getPaymentTransactions(userId, status: 'paid');
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    } catch (e) {
      print('❌ Error getting paid transactions: $e');
      return [];
    }
  }

  /// Get pending transactions that need attention
  static Future<List<Map<String, dynamic>>> getPendingTransactions(
      dynamic userId) async {
    try {
      final result = await getPaymentTransactions(userId, status: 'pending');
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    } catch (e) {
      print('❌ Error getting pending transactions: $e');
      return [];
    }
  }

  /// Get pending bookings that need attention
  static Future<List<Map<String, dynamic>>> getPendingBookings(
      dynamic userId) async {
    return getOwnerBookings(userId, status: 'pending');
  }

  /// Get confirmed and paid bookings (active tenants)
  static Future<List<Map<String, dynamic>>> getActiveBookings(
      dynamic userId) async {
    return getOwnerBookings(userId, status: 'confirmed', paymentStatus: 'paid');
  }

  /// Mark a booking as paid (common use case)
  static Future<Map<String, dynamic>> markBookingAsPaid(
    int bookingId, {
    String? transactionId,
    String? receiptUrl,
  }) async {
    return updatePaymentStatus(
      bookingId,
      'paid',
      transactionId: transactionId,
      receiptUrl: receiptUrl,
    );
  }

  /// Get occupancy summary for dashboard display
  static Future<String> getOccupancyDisplayString(dynamic userId) async {
    try {
      final stats = await getOccupancyStats(userId);
      return stats['occupancy_display'] ?? '0/0';
    } catch (e) {
      print('❌ Error getting occupancy display: $e');
      return '0/0';
    }
  }

  /// Get vacancy rate as percentage
  static Future<double> getVacancyRate(dynamic userId) async {
    try {
      final stats = await getOccupancyStats(userId);
      return (stats['vacancy_rate'] ?? 0.0).toDouble();
    } catch (e) {
      print('❌ Error getting vacancy rate: $e');
      return 0.0;
    }
  }
}
