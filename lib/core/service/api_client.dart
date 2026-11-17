import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static String get defaultBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      // 10.0.2.2 connects the Android Emulator directly to the host computer's localhost
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  static String baseUrl = defaultBaseUrl;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Reactive state for user session
  static final ValueNotifier<Map<String, dynamic>?> currentUserNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  static bool get isAuthenticated => currentUserNotifier.value != null;
  static Map<String, dynamic>? get currentUser => currentUserNotifier.value;
  static bool get isAdmin => currentUser?['role'] == 'admin';
  static bool get isCustomer => currentUser?['role'] == 'customer';

  static Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  static Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    Map<String, dynamic>? user,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    if (user != null) {
      await _storage.write(key: 'user_profile', value: jsonEncode(user));
      currentUserNotifier.value = user;
    }
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_profile');
    currentUserNotifier.value = null;
  }

  static Future<Map<String, dynamic>?> restoreSession() async {
    try {
      final savedUser = await _storage.read(key: 'user_profile');
      if (savedUser != null) {
        currentUserNotifier.value = jsonDecode(savedUser) as Map<String, dynamic>;
      }
      final token = await getAccessToken();
      if (token == null) {
        currentUserNotifier.value = null;
        return null;
      }
      // Validate by fetching profile
      final profile = await get('/auth/me');
      currentUserNotifier.value = profile;
      await _storage.write(key: 'user_profile', value: jsonEncode(profile));
      return profile;
    } catch (_) {
      // If profile fails, try token refresh
      final refreshed = await refreshToken();
      if (refreshed) {
        try {
          final profile = await get('/auth/me');
          currentUserNotifier.value = profile;
          await _storage.write(key: 'user_profile', value: jsonEncode(profile));
          return profile;
        } catch (_) {}
      }
      await clearSession();
      return null;
    }
  }

  // ---------------- AUTH REQUESTS ----------------

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
        'phone': phone,
      }),
    );
    return _handleAuthResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _handleAuthResponse(response);
  }

  static Future<bool> refreshToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        if (data['user'] != null) {
          currentUserNotifier.value = data['user'] as Map<String, dynamic>;
          await _storage.write(key: 'user_profile', value: jsonEncode(data['user']));
        }
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }

    await clearSession();
    return false;
  }

  static Future<void> logout() async {
    final refresh = await getRefreshToken();
    final access = await getAccessToken();

    if (refresh != null && access != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $access',
          },
          body: jsonEncode({'refresh_token': refresh}),
        );
      } catch (_) {}
    }
    await clearSession();
  }

  static Future<Map<String, dynamic>> _handleAuthResponse(http.Response response) async {
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = Map<String, dynamic>.from(body);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      await saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
      );
      return data;
    }

    final message = _extractErrorMessage(body);
    throw Exception(message);
  }

  // ---------------- GENERAL REST HELPERS WITH AUTO-REFRESH ----------------

  static Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    return _sendWithRetry((token) async {
      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
      return await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
    });
  }

  static Future<dynamic> post(String endpoint, {dynamic body}) async {
    return _sendWithRetry((token) async {
      return await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  static Future<dynamic> put(String endpoint, {dynamic body}) async {
    return _sendWithRetry((token) async {
      return await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  static Future<dynamic> patch(String endpoint, {dynamic body}) async {
    return _sendWithRetry((token) async {
      return await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  static Future<dynamic> delete(String endpoint) async {
    return _sendWithRetry((token) async {
      return await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
    });
  }

  // ---------------- MULTIPART UPLOAD WITH RETRY ----------------

  static Future<dynamic> uploadFile(
    String endpoint, {
    required File file,
    required String fileField,
    Map<String, String>? fields,
  }) async {
    String? token = await getAccessToken();

    Future<http.StreamedResponse> sendMultipart(String? authToken) async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      if (fields != null) {
        request.fields.addAll(fields);
      }
      request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      return await request.send();
    }

    var streamed = await sendMultipart(token);
    var response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        token = await getAccessToken();
        streamed = await sendMultipart(token);
        response = await http.Response.fromStream(streamed);
      }
    }

    return _processResponse(response);
  }

  static Future<dynamic> _sendWithRetry(
    Future<http.Response> Function(String? token) requestFn,
  ) async {
    String? token = await getAccessToken();
    var response = await requestFn(token);

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        token = await getAccessToken();
        response = await requestFn(token);
      }
    }

    return _processResponse(response);
  }

  static dynamic _processResponse(http.Response response) {
    if (response.statusCode == 204) {
      return null;
    }

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = _extractErrorMessage(body);
    throw Exception(message);
  }

  static String _extractErrorMessage(dynamic body) {
    if (body is Map) {
      if (body.containsKey('error') && body['error'] is Map) {
        return body['error']['message']?.toString() ?? 'An error occurred';
      }
      if (body.containsKey('detail')) {
        return body['detail'].toString();
      }
      if (body.containsKey('message')) {
        return body['message'].toString();
      }
    }
    return body?.toString() ?? 'Network request failed';
  }
}
