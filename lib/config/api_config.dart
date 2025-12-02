// Fixed ApiConfig with debugging capabilities
// import 'dart:convert';

// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Change this IP address when needed
  static const String _baseUrl = 'http://192.168.0.4'; //URL RUMAHSEWA
  //static String _baseUrl = 'http://192.168.0.117'; //URL RUMAH
  //static String _baseUrl = 'http://172.20.10.5'; //URL PHONE
  //static String _baseUrl = 'https://databasetest.infinityfree.me'; //URL ONLINE

  // API endpoints
  static const String _apiPath = '/smartstay';

  // 2. NEW GETTER FOR RAW DOMAIN (For images)
  // This returns just 'http://192.168.0.4' without '/smartstay'
  static String get rawBaseUrl => _baseUrl;

  // Complete base URL with debug logging
  static String get baseUrl {
    const url = '$_baseUrl$_apiPath';
    // Uncomment next line for debugging
    // print("🔍 Current Base URL: $url");
    return url;
  }

  // Add debug method
  static void debugCurrentConfig() {
    print("🔍 ===================");
    print("🔍 Current _baseUrl: $_baseUrl");
    print("🔍 Current _apiPath: $_apiPath");
    print("🔍 Final baseUrl: $baseUrl");
    print("🔍 Sample endpoint: $loginUrl");
    print("🔍 Timestamp: ${DateTime.now()}");
    print("🔍 ===================");
  }

  // Method to update base URL
  // static void updateBaseUrl(String newBaseUrl) {
  //   _baseUrl = newBaseUrl;
  //   print("🔄 Base URL updated to: $_baseUrl");
  //   // Reset any HTTP clients here
  //   PropertyService.resetHttpClient();
  //   debugCurrentConfig();
  // }

  // // Force refresh method
  // static Future<void> forceRefresh() async {
  //   print("🔄 Forcing complete refresh...");
  //   debugCurrentConfig();

  //   // Reset HTTP clients
  //   PropertyService.resetHttpClient();

  //   // Clear any cached data if needed
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.remove('cached_base_url');
  //     await prefs.remove('api_config');
  //   } catch (e) {
  //     print("No SharedPreferences to clear: $e");
  //   }

  //   print("✅ Refresh complete");
  // }

  // Authentication endpoints
  static String get loginUrl => '$baseUrl/login.php';
  static String get registerUrl => '$baseUrl/register.php';

  // Listing endpoints
  static String get getListingsUrl => '$baseUrl/get_listings.php';
  static String get getListingOwnerUrl => '$baseUrl/get_listing_owner.php';

  // Messaging endpoints
  static String get getConversationsUrl => '$baseUrl/get_conversations.php';
  static String get getUsersUrl => '$baseUrl/get_users.php';
  static String get getMessagesUrl => '$baseUrl/get_messages.php';
  static String get sendMessageUrl => '$baseUrl/send_message.php';

  // Dashboard endpoints
  static String get dashboardUrl => '$baseUrl/dashboard.php';

  // User management endpoints
  static String get updateUserUrl => '$baseUrl/update_user.php';

  // Listing management endpoints
  static String get uploadImageUrl => '$baseUrl/upload_image.php';
  static String get uploadVideoUrl => '$baseUrl/upload_video.php';
  static String get addListingUrl => '$baseUrl/add_listing.php';
  static String get updateListingUrl => '$baseUrl/update_listing.php';
  static String get getSingleListingUrl => '$baseUrl/get_single_listing.php';
  static String get updateListingStatusUrl =>
      '$baseUrl/update_listing_status.php';
  static String get deleteListingUrl => '$baseUrl/delete_listing.php';
  static String get getListingsCountUrl => '$baseUrl/get_listings_count.php';
  static String get testConnectionUrl => '$baseUrl/test_connection.php';

  // Property browsing endpoints
  static String get getAllListingsUrl => '$baseUrl/get_all_listings.php';
  static String get getFeaturedListingsUrl =>
      '$baseUrl/get_featured_listings.php';
  static String get getPropertyDetailsUrl =>
      '$baseUrl/get_property_details.php';
  static String get getSearchSuggestionsUrl =>
      '$baseUrl/get_search_suggestions.php';
  static String get getPropertyStatsUrl => '$baseUrl/get_property_stats.php';

  // Favorites endpoints
  static String get favoritesBaseUrl => '$baseUrl/favorites';

  // Message service endpoints
  static String get messagesUrl => '$baseUrl/messages.php';

  // Booking endpoints
  static String get createBooking => '$baseUrl/bookings_api.php/create';
  static String getTenantBookings(int tenantId) =>
      '$baseUrl/bookings_api.php/tenant/$tenantId';
  static String getOwnerBookings(int ownerId) =>
      '$baseUrl/bookings_api.php/owner/$ownerId';
  static String updateBookingStatus(String bookingId, String action) =>
      '$baseUrl/bookings_api.php/$bookingId/$action';
  static String checkExistingBooking(String tenantId, String listingId) =>
      '$baseUrl/bookings_api.php/check-existing/$tenantId/$listingId';

  // Helper endpoints
  static String checkAvailability(String listingId) =>
      '$baseUrl/booking_helpers.php/availability/$listingId';
  static String cancelBooking(String bookingId) =>
      '$baseUrl/booking_helpers.php/cancel/$bookingId';

  // Profile endpoints
  static String get paymentMethodsUrl => '$baseUrl/payment_methods.php';
  static String get rentalHistoryUrl => '$baseUrl/rental_history.php';
  static String get faqUrl => '$baseUrl/faq.php';
  static String get supportTicketsUrl => '$baseUrl/support_tickets.php';
  static String get ticketMessagesUrl => '$baseUrl/ticket_messages.php';

  // 3. NEW HELPER FUNCTION TO GENERATE FULL MEDIA URL
  static String generateFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    // If it's already a full URL (e.g. from external source), return it
    if (path.startsWith('http')) return path;

    // Remove leading slash to prevent double slashes if needed,
    // but usually _baseUrl does NOT end with / and path starts with /
    // stored path: /smartstay/uploads/3/image.jpg
    // _baseUrl:    http://192.168.0.4

    // Result: http://192.168.0.4/smartstay/uploads/3/image.jpg
    return '$rawBaseUrl$path';
  }

  // Methods with parameters
  static String getListingOwnerUrlWithId(int listingId) {
    return '$getListingOwnerUrl?listing_id=$listingId';
  }

  static String getConversationsUrlWithUserId(int userId) {
    return '$getConversationsUrl?user_id=$userId';
  }

  static String getUsersUrlWithParams(int currentUserId, String userType) {
    return '$getUsersUrl?current_user_id=$currentUserId&user_type=$userType';
  }

  static String getMessagesUrlWithParams(int userId, int otherUserId) {
    return '$getMessagesUrl?user_id=$userId&other_user_id=$otherUserId';
  }

  static String getDashboardUrlWithParams(String action, int ownerId) {
    return '$dashboardUrl?action=$action&owner_id=$ownerId';
  }

  static String getListingsCountUrlWithUserId(int userId) {
    return '$getListingsCountUrl?user_id=$userId';
  }

  static String getSingleListingUrlWithParams(String listingId, String userId) {
    return '$getSingleListingUrl?listing_id=$listingId&user_id=$userId';
  }

  static String getFavoritesUrlWithUserId(String userId) {
    return '$favoritesBaseUrl/$userId';
  }

  static String getFavoritesUrlWithUserAndListing(
      String userId, String listingId) {
    return '$favoritesBaseUrl/$userId/$listingId';
  }

  static String getMessagesUrlWithParams2(String action,
      {Map<String, String>? params}) {
    String url = '$messagesUrl?action=$action';
    if (params != null) {
      params.forEach((key, value) {
        url += '&$key=$value';
      });
    }
    return url;
  }

  // Profile endpoint methods with parameters
  static String getPaymentMethodsUrlWithUserId(int userId) {
    return '$paymentMethodsUrl?user_id=$userId';
  }

  static String deletePaymentMethodUrl(int userId, int paymentId) {
    return '$paymentMethodsUrl?user_id=$userId&payment_id=$paymentId';
  }

  static String getRentalHistoryUrlWithUserId(int userId) {
    return '$rentalHistoryUrl?user_id=$userId';
  }

  // NEW: Payment Banking endpoints for property owners
  static String get ownerBankAccountsUrl => '$baseUrl/owner_bank_accounts.php';
  static String get paymentTransactionsUrl =>
      '$baseUrl/payment_transactions.php';
  static String get paymentSummaryUrl => '$baseUrl/payment_summary.php';
  static String get simulatePaymentUrl =>
      '$baseUrl/simulate_payment_webhook.php';

  // Method to easily switch between different environments
  // static void setEnvironment(Environment env) {
  //   switch (env) {
  //     case Environment.development:
  //       _baseUrl = 'http://192.168.0.34';
  //       break;
  //     case Environment.local:
  //       _baseUrl = 'http://10.0.2.2'; // For Android emulator
  //       break;
  //     case Environment.production:
  //       _baseUrl = 'https://your-production-url.com';
  //       break;
  //   }
  //   PropertyService.resetHttpClient();
  //   debugCurrentConfig();
  // }
}

enum Environment { development, local, production }

// Fixed PropertyService with proper HTTP client management
// class PropertyService {
//   static http.Client? _httpClient;

//   // Get HTTP client with fresh configuration
//   static http.Client get httpClient {
//     _httpClient ??= http.Client();
//     return _httpClient!;
//   }

//   // Reset HTTP client to pick up new base URL
//   static void resetHttpClient() {
//     _httpClient?.close();
//     _httpClient = null;
//     print("🔄 HTTP Client reset");
//   }

//   Future<Map<String, dynamic>> getAllListings({
//     int page = 1,
//     String? searchQuery,
//   }) async {
//     try {
//       // Always use fresh base URL
//       String url = ApiConfig.getAllListingsUrl;

//       final uri = Uri.parse(url).replace(queryParameters: {
//         'page': page.toString(),
//         if (searchQuery != null && searchQuery.isNotEmpty)
//           'search': searchQuery,
//       });

//       print("🌐 Making request to: $uri");

//       final response = await httpClient.get(
//         uri,
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(const Duration(seconds: 30));

//       print("📡 Response status: ${response.statusCode}");

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data;
//       } else {
//         throw Exception('Failed to load listings: ${response.statusCode}');
//       }
//     } catch (e) {
//       print("❌ Error in getAllListings: $e");
//       throw Exception('Network error: $e');
//     }
//   }

//   // Test connection method
//   Future<bool> testConnection() async {
//     try {
//       final response = await httpClient.get(
//         Uri.parse(ApiConfig.testConnectionUrl),
//         headers: {'Content-Type': 'application/json'},
//       ).timeout(const Duration(seconds: 10));

//       print("🔗 Connection test - Status: ${response.statusCode}");
//       print("🔗 Response: ${response.body}");

//       return response.statusCode == 200;
//     } catch (e) {
//       print("❌ Connection test failed: $e");
//       return false;
//     }
//   }
// }
