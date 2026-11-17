import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Adapter class maintaining full backward compatibility with screens using ApiService,
/// while internally utilizing the resilient ApiClient.
class ApiService {
  static String get baseUrl => ApiClient.baseUrl;

  static ValueNotifier<Map<String, dynamic>?> get currentUserNotifier =>
      ApiClient.currentUserNotifier;

  static bool get isAuthenticated => ApiClient.isAuthenticated;
  static bool get isAdmin => ApiClient.isAdmin;

  static Map<String, dynamic>? get currentUser => ApiClient.currentUser;

  static Future<String?> getToken() => ApiClient.getAccessToken();

  static Future<Map<String, dynamic>?> checkSession() => ApiClient.restoreSession();

  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) =>
      ApiClient.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) =>
      ApiClient.login(
        email: email,
        password: password,
      );

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await ApiClient.get('/auth/me');
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<void> logout() => ApiClient.logout();
}
