import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/service/api_service.dart';

class WishlistManager extends ChangeNotifier {
  WishlistManager._();

  static final WishlistManager instance = WishlistManager._();

  static String get _baseUrl => ApiService.baseUrl;

  final List<Map<String, String>> _items = [];

  String? _loadedUserId;
  bool _isLoading = false;
  int _requestId = 0;

  List<Map<String, String>> get items =>
      List<Map<String, String>>.unmodifiable(_items);

  bool get isLoading => _isLoading;

  bool isFavorite(String title, String category) {
    return _items.any(
      (item) => item['title'] == title && item['category'] == category,
    );
  }

  // Listen to auth changes from ApiService
  void startListeningToAuthChanges() {
    ApiService.currentUserNotifier.addListener(_onAuthChanged);
    if (ApiService.isAuthenticated) {
      loadForCurrentUser();
    }
  }

  void _onAuthChanged() {
    final user = ApiService.currentUser;
    if (user == null) {
      _clearWishlist();
    } else {
      loadForCurrentUser();
    }
  }

  void _clearWishlist() {
    _requestId++;
    _loadedUserId = null;
    _isLoading = false;
    _items.clear();
    notifyListeners();
    debugPrint('WISHLIST: Cleared on logout');
  }

  Future<void> loadForCurrentUser() async {
    final token = await ApiService.getToken();
    final user = ApiService.currentUser;

    if (token == null || user == null) {
      _clearWishlist();
      return;
    }

    final userId = user['id']?.toString();
    if (_isLoading && _loadedUserId == userId) return;

    if (_loadedUserId != userId) {
      _items.clear();
    }

    _loadedUserId = userId;
    _isLoading = true;
    final currentRequest = ++_requestId;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wishlist/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (currentRequest != _requestId) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['items'] as List<dynamic>? ?? [];

        _items.clear();
        for (final row in list) {
          final item = <String, String>{};
          for (final key in ['title', 'category', 'price', 'image']) {
            final val = row[key];
            if (val != null) {
              item[key] = val.toString();
            }
          }
          _items.add(item);
        }
        debugPrint('WISHLIST: Loaded ${_items.length} items');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await ApiService.logout();
        _clearWishlist();
      }
    } catch (e) {
      debugPrint('WISHLIST LOAD ERROR: $e');
    } finally {
      if (currentRequest == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggle(Map<String, String> product) async {
    final token = await ApiService.getToken();
    if (token == null) {
      debugPrint('Please log in to use the wishlist.');
      return;
    }

    final title = product['title'];
    final category = product['category'];
    if (title == null || category == null) return;

    // Optimistically update local list
    final alreadySaved = isFavorite(title, category);
    if (alreadySaved) {
      _items.removeWhere(
        (item) => item['title'] == title && item['category'] == category,
      );
    } else {
      _items.add(Map<String, String>.from(product));
    }
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wishlist/toggle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'category': category,
          'price': product['price'],
          'image': product['image'],
        }),
      );

      if (response.statusCode != 200) {
        // Revert on failure
        if (alreadySaved) {
          _items.add(Map<String, String>.from(product));
        } else {
          _items.removeWhere(
            (item) => item['title'] == title && item['category'] == category,
          );
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('WISHLIST TOGGLE ERROR: $e');
      if (alreadySaved) {
        _items.add(Map<String, String>.from(product));
      } else {
        _items.removeWhere(
          (item) => item['title'] == title && item['category'] == category,
        );
      }
      notifyListeners();
    }
  }

  Future<void> remove(Map<String, String> product) async {
    final token = await ApiService.getToken();
    if (token == null) return;

    final title = product['title'];
    final category = product['category'];
    if (title == null || category == null) return;

    _items.removeWhere(
      (item) => item['title'] == title && item['category'] == category,
    );
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/wishlist/').replace(
        queryParameters: {
          'title': title,
          'category': category,
        },
      );
      await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint('WISHLIST REMOVE ERROR: $e');
    }
  }
}
