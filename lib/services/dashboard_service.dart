// // services/dashboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_models.dart';
// ADD THIS IMPORT
import 'package:my_app/config/api_config.dart'; // Adjust path as needed

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

  // Updated method signature to accept dynamic userId
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

  // Additional helper method to test if user ID is valid
  static bool isValidUserId(dynamic userId) {
    return _safeParseUserId(userId) != null;
  }

  // Method to get all dashboard data at once
  static Future<Map<String, dynamic>> getAllDashboardData(
      dynamic userId) async {
    try {
      // Validate user ID first
      if (!isValidUserId(userId)) {
        throw Exception('Invalid user ID provided');
      }

      print('🔄 Loading all dashboard data for user: $userId');

      // Run all requests concurrently for better performance
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
}
