import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/service/api_client.dart';

class OrderService {
  /// Global revision notifier to signal when orders change
  static final ValueNotifier<int> ordersRevision = ValueNotifier<int>(0);

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final token = await ApiClient.getAccessToken();
    if (token == null && !ApiClient.isAuthenticated) return [];

    try {
      final res = await ApiClient.get('/orders?limit=50');
      if (res is Map && res['items'] is List) {
        final list = res['items'] as List;
        return list.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          // Normalize fields for UI display
          final itemsList = (m['items'] as List?) ?? [];
          final firstItem = itemsList.isNotEmpty ? itemsList.first as Map<String, dynamic> : null;

          final title = firstItem != null
              ? firstItem['product_name_snapshot']?.toString() ?? 'Custom Outfit'
              : (m['note'] != null && m['note'].toString().isNotEmpty)
                  ? m['note'].toString()
                  : (m['order_number']?.toString() ?? 'Outfit');

          m['design_title'] = title;
          m['garment_type'] = m['order_number'] ?? 'Standard Order';
          m['design_category'] = 'Ethnic Wear';
          m['design_price'] = '₹${m['total'] ?? m['subtotal'] ?? '0.00'}';

          return m;
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('OrderService fetchOrders error: $e');
      return [];
    }
  }

  Future<void> cancelOrder(String orderId) async {
    await ApiClient.post('/orders/$orderId/cancel');
    ordersRevision.value++;
  }

  /// Create custom stitching order from BookingScreen
  Future<String> createOrder({
    required String designTitle,
    required String designCategory,
    required String designPrice,
    required String garmentType,
    required Map<String, dynamic> measurements,
    String? fabricPreference,
    String? specialInstructions,
    String? referenceImagePath,
  }) async {
    // 1. Get or create a customer address
    final addressesRes = await ApiClient.get('/addresses');
    String addressId;

    if (addressesRes is List && addressesRes.isNotEmpty) {
      final defaultAddr = addressesRes.firstWhere(
        (a) => a['is_default'] == true,
        orElse: () => addressesRes.first,
      );
      addressId = defaultAddr['id'].toString();
    } else {
      // Create a default primary address
      final user = ApiClient.currentUser;
      final newAddr = await ApiClient.post(
        '/addresses',
        body: {
          'recipient_name': user?['full_name'] ?? 'Customer',
          'phone': user?['phone'] ?? '+91 9876543210',
          'street': 'Store Consultation Delivery',
          'city': 'Bengaluru',
          'state': 'Karnataka',
          'postal_code': '560001',
          'is_default': true,
        },
      );
      addressId = newAddr['id'].toString();
    }

    // 2. Find an active product to attach item snapshot or use first available product
    final prodsRes = await ApiClient.get('/products?limit=1');
    String productId;

    if (prodsRes is Map && prodsRes['items'] is List && (prodsRes['items'] as List).isNotEmpty) {
      productId = prodsRes['items'][0]['id'].toString();
    } else {
      // Create a baseline custom tailoring category & product if none exist yet
      final catsRes = await ApiClient.get('/categories');
      String catId;
      if (catsRes is List && catsRes.isNotEmpty) {
        catId = catsRes.first['id'].toString();
      } else {
        final cat = await ApiClient.post('/admin/categories', body: {'name': 'Custom Tailoring'});
        catId = cat['id'].toString();
      }
      final prod = await ApiClient.post(
        '/admin/products',
        body: {
          'name': designTitle,
          'description': 'Custom Tailored Outfit',
          'price': 999.00,
          'category_id': catId,
        },
      );
      productId = prod['id'].toString();
    }

    // Compose rich note with measurements and tailoring preferences
    final noteBuffer = StringBuffer();
    noteBuffer.writeln('$designTitle ($garmentType)');
    if (fabricPreference != null) noteBuffer.writeln('Fabric: $fabricPreference');
    if (specialInstructions != null && specialInstructions.isNotEmpty) {
      noteBuffer.writeln('Instructions: $specialInstructions');
    }
    if (referenceImagePath != null) {
      noteBuffer.writeln('Reference: $referenceImagePath');
    }
    noteBuffer.write('Measurements: ${jsonEncode(measurements)}');

    final res = await ApiClient.post(
      '/orders',
      body: {
        'address_id': addressId,
        'items': [
          {'product_id': productId, 'quantity': 1}
        ],
        'note': noteBuffer.toString(),
      },
    );

    ordersRevision.value++;
    return res['id'].toString();
  }

  /// Create standard catalog order
  Future<String> createStandardOrder({
    required String addressId,
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    final res = await ApiClient.post(
      '/orders',
      body: {
        'address_id': addressId,
        'items': items,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    ordersRevision.value++;
    return res['id'].toString();
  }
}
