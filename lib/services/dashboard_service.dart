// services/dashboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_models.dart';

class DashboardService {
  // Change this to your XAMPP server URL
  static const String baseUrl = 'http://10.0.2.2/smartstay/dashboard.php';

  // Get dashboard statistics
  static Future<DashboardStats?> getDashboardStats(int ownerId) async {
    try {
      final url = '$baseUrl?action=stats&owner_id=$ownerId';
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
          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception in getDashboardStats: $e');
      return null;
    }
  }

  static Future<List<RecentActivity>> getRecentActivities(int ownerId) async {
    try {
      final url = '$baseUrl?action=activities&owner_id=$ownerId';
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
          List<dynamic> activitiesJson = jsonData['data'];
          final activities = activitiesJson
              .map((json) => RecentActivity.fromJson(json))
              .toList();
          print('📝 Activities created: ${activities.length} items');
          return activities;
        }
      }
      return [];
    } catch (e) {
      print('❌ Exception in getRecentActivities: $e');
      return [];
    }
  }

  static Future<List<NotificationItem>> getNotifications(int ownerId) async {
    try {
      final url = '$baseUrl?action=notifications&owner_id=$ownerId';
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
          List<dynamic> notificationsJson = jsonData['data'];
          final notifications = notificationsJson
              .map((json) => NotificationItem.fromJson(json))
              .toList();
          print('🔔 Notifications created: ${notifications.length} items');
          return notifications;
        }
      }
      return [];
    } catch (e) {
      print('❌ Exception in getNotifications: $e');
      return [];
    }
  }
}
