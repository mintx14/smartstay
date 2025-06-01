// lib/utils/constants.dart

class ApiConstants {
  // Base URL for your API
  static const String baseUrl = 'https://your-api-domain.com';

  // API endpoints
  static const String loginEndpoint = '/api/login';
  static const String registerEndpoint = '/api/register';
  static const String usersEndpoint = '/api/users';

  // HTTP response codes
  static const int successCode = 200;
  static const int badRequestCode = 400;
  static const int unauthorizedCode = 401;
  static const int notFoundCode = 404;
  static const int serverErrorCode = 500;

  // Timeouts
  static const int connectionTimeout = 30000; // milliseconds
  static const int receiveTimeout = 30000; // milliseconds
}
