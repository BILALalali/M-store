/// ثوابت التطبيق الأساسية
class AppConstants {
  // App Info
  static const String appName = 'Almustafa Admin';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'https://api.almustafa.com';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
