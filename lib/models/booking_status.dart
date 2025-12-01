// models/booking_status.dart - Updated Fix
import 'package:intl/intl.dart';

class BookingStatus {
  final int id;
  final int listingId;
  final int tenantId;
  final String tenantName;
  final String propertyTitle;
  final String propertyAddress;
  final String? propertyImageUrl;
  final String status;
  final String checkInDate;
  final int durationMonths;
  final double monthlyRent;
  final double depositAmount;
  final double totalAmount;
  final String createdAt;
  final String? message;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;

  // Payment related fields
  final String? paymentStatus;
  final String? paidAt;
  final String? paymentTransactionRef;
  final double? paymentAmount;
  final bool hasPaymentTransaction;

  // Additional fields
  final String? tenantEmail;
  final String? tenantPhone;
  final String? receiptUrl;

  BookingStatus({
    required this.id,
    required this.listingId,
    required this.tenantId,
    required this.tenantName,
    required this.propertyTitle,
    required this.propertyAddress,
    this.propertyImageUrl,
    required this.status,
    required this.checkInDate,
    required this.durationMonths,
    required this.monthlyRent,
    required this.depositAmount,
    required this.totalAmount,
    required this.createdAt,
    this.message,
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    this.paymentStatus,
    this.paidAt,
    this.paymentTransactionRef,
    this.paymentAmount,
    this.hasPaymentTransaction = false,
    this.tenantEmail,
    this.tenantPhone,
    this.receiptUrl,
  });

  factory BookingStatus.fromJson(Map<String, dynamic> json) {
    print('=== Parsing BookingStatus ===');
    // print('Raw JSON: $json'); // Uncomment to debug

    // Handle both nested and flat structures for backward compatibility
    final property = json['property'] ?? {};
    final owner = json['owner'] ?? {};
    final tenant = json['tenant'] ?? {};

    // Helper function to safely parse integers
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper function to safely parse doubles
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper function to safely parse nullable doubles
    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Parse property title
    String propertyTitle = 'Unknown Property';
    if (property['title'] != null) {
      propertyTitle = property['title'];
    } else if (json['property_title'] != null) {
      propertyTitle = json['property_title'];
    }

    // Parse property address
    String propertyAddress = '';
    if (property['address'] != null) {
      propertyAddress = property['address'];
    } else if (json['property_address'] != null) {
      propertyAddress = json['property_address'];
    }

    // Parse property image
    String? propertyImageUrl;
    if (property['image_url'] != null) {
      propertyImageUrl = property['image_url'];
    } else if (json['property_image_url'] != null) {
      propertyImageUrl = json['property_image_url'];
    }

    // Parse owner info
    String? ownerName;
    if (owner['name'] != null) {
      ownerName = owner['name'];
    } else if (owner['full_name'] != null) {
      ownerName = owner['full_name'];
    } else if (json['owner_name'] != null) {
      ownerName = json['owner_name'];
    }

    final result = BookingStatus(
      id: parseId(json['id']),
      listingId: parseId(json['listing_id'] ?? property['id']),
      tenantId: parseId(json['tenant_id'] ?? tenant['id']),
      tenantName: tenant['full_name'] ??
          json['tenant_full_name'] ??
          json['tenant_name'] ??
          'Unknown',
      propertyTitle: propertyTitle,
      propertyAddress: propertyAddress,
      propertyImageUrl: propertyImageUrl,
      status: json['status'] ?? 'pending',
      checkInDate: json['check_in_date'] ?? '',
      durationMonths: parseId(json['duration_months']),
      monthlyRent: parseDouble(json['monthly_rent']),
      depositAmount: parseDouble(json['deposit_amount']),
      totalAmount: parseDouble(json['total_amount']),
      createdAt: json['created_at'] ?? '',
      message: json['message'],
      ownerName: ownerName,
      ownerEmail: owner['email'] ?? json['owner_email'],
      ownerPhone: owner['phone'] ?? json['owner_phone'],

      // --- UPDATED PAYMENT PARSING ---
      paymentStatus: json['payment_status'],
      paidAt: json['paid_at'] ?? json['payment_paid_at'],
      paymentTransactionRef:
          json['payment_transaction_ref'] ?? json['transaction_ref'],
      paymentAmount: parseNullableDouble(json['payment_amount']),

      // FIX: Only set true if payment is CONFIRMED 'paid' or explicit flag is true.
      // Previous code set it to true if payment_status was just NOT null (which included 'pending')
      hasPaymentTransaction: json['has_payment_transaction'] == true ||
          json['payment_status'] == 'paid',
      // --------------------------------

      tenantEmail: json['tenant_email'],
      tenantPhone: json['tenant_phone'],
      receiptUrl: json['receipt_url'],
    );

    print(
        'Parsed booking: ID=${result.id}, Status=${result.status}, PaymentStatus=${result.paymentStatus}');
    return result;
  }

  // --- UPDATED HELPERS ---
  bool get isPaymentCompleted {
    // Check multiple conditions to be safe
    return paymentStatus?.toLowerCase() == 'paid' ||
        status.toLowerCase() == 'paid' || // In case main status is updated
        hasPaymentTransaction;
  }

  bool get isConfirmedAndNotPaid =>
      status.toLowerCase() == 'confirmed' && !isPaymentCompleted;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get displayStatus {
    if (isPaymentCompleted) return 'PAID';
    return status.toUpperCase();
  }

  String get checkOut {
    try {
      final checkIn = DateTime.parse(checkInDate);
      final checkOutDate = checkIn.add(Duration(days: durationMonths * 30));
      return DateFormat('MMM d, yyyy').format(checkOutDate);
    } catch (e) {
      return 'N/A';
    }
  }

  String? get formattedPaidDate {
    if (paidAt == null) return null;
    try {
      final date = DateTime.parse(paidAt!);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return null;
    }
  }
}
