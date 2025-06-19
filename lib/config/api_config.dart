class ApiConfig {
  // Change this IP address when needed
  static const String _baseUrl = 'http://192.168.0.11';

  // API endpoints
  static const String _apiPath = '/smartstay';

  // Complete base URL
  static String get baseUrl => '$_baseUrl$_apiPath';

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
  static final String createBooking = '$baseUrl/bookings_api.php/create';
  static String getTenantBookings(String tenantId) =>
      '$baseUrl/bookings_api.php/tenant/$tenantId';
  static String getOwnerBookings(String ownerId) =>
      '$baseUrl/bookings_api.php/owner/$ownerId';
  static String updateBookingStatus(String bookingId, String action) =>
      '$baseUrl/bookings_api.php/$bookingId/$action';

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
  static final String ownerBankAccountsUrl = '$baseUrl/owner_bank_accounts.php';
  static final String paymentTransactionsUrl =
      '$baseUrl/payment_transactions.php';
  static final String paymentSummaryUrl = '$baseUrl/payment_summary.php';
  static final String simulatePaymentUrl =
      '$baseUrl/simulate_payment_webhook.php';

  // Method to easily switch between different environments
  static void setEnvironment(Environment env) {
    switch (env) {
      case Environment.development:
        // Keep current IP
        break;
      case Environment.local:
        // For Android emulator
        break;
      case Environment.production:
        // Production URL
        break;
    }
  }
}

enum Environment {
  development,
  local,
  production,
}
