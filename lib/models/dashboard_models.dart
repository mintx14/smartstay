// models/dashboard_models.dart
import 'package:flutter/material.dart';

class DashboardStats {
  final int totalProperties;
  final int totalRooms;
  final int occupiedRooms;
  final double monthlyIncome;
  final int unreadMessages;

  DashboardStats({
    required this.totalProperties,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.monthlyIncome,
    required this.unreadMessages,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    print('🏗️ Creating DashboardStats from JSON: $json');
    return DashboardStats(
      totalProperties: json['total_properties'] ?? 0,
      totalRooms: json['total_rooms'] ?? 0,
      occupiedRooms: json['occupied_rooms'] ?? 0,
      monthlyIncome: (json['monthly_income'] ?? 0).toDouble(),
      unreadMessages: json['unread_messages'] ?? 0,
    );
  }

  String get occupancyRate =>
      totalRooms > 0 ? '$occupiedRooms/$totalRooms' : '0/0';
  String get formattedIncome => 'RM ${monthlyIncome.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'DashboardStats(properties: $totalProperties, rooms: $totalRooms, occupied: $occupiedRooms, income: $monthlyIncome, messages: $unreadMessages)';
  }
}

class RecentActivity {
  final String type;
  final String title;
  final String timeAgo;
  final int relatedId;

  RecentActivity({
    required this.type,
    required this.title,
    required this.timeAgo,
    required this.relatedId,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      timeAgo: json['time_ago'] ?? '',
      relatedId: json['related_id'] ?? 0,
    );
  }

  IconData get icon {
    switch (type) {
      case 'booking_request':
        return Icons.calendar_today;
      case 'payment_received':
        return Icons.payment;
      case 'new_message':
        return Icons.message;
      case 'property_added':
        return Icons.home_work;
      default:
        return Icons.info;
    }
  }

  Color get color {
    switch (type) {
      case 'booking_request':
        return Colors.blue;
      case 'payment_received':
        return Colors.green;
      case 'new_message':
        return Colors.orange;
      case 'property_added':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String message;
  final String timeAgo;
  final bool isRead;
  final int? relatedId;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.isRead,
    this.relatedId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timeAgo: json['time_ago'] ?? '',
      isRead: json['is_read'] == 1,
      relatedId: json['related_id'],
    );
  }

  IconData get icon {
    switch (type) {
      case 'booking_request':
        return Icons.calendar_today;
      case 'payment_received':
        return Icons.payment;
      case 'new_message':
        return Icons.message;
      case 'booking_approved':
        return Icons.check_circle;
      case 'booking_cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'booking_request':
        return Colors.blue;
      case 'payment_received':
        return Colors.green;
      case 'new_message':
        return Colors.orange;
      case 'booking_approved':
        return Colors.green;
      case 'booking_cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
