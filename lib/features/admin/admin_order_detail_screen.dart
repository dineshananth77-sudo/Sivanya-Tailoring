import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/service/api_client.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/admin/orders/${widget.orderId}');
      if (mounted) {
        setState(() {
          _order = Map<String, dynamic>.from(res as Map);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading order detail: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus, {String? comment}) async {
    setState(() => _isUpdating = true);
    try {
      final res = await ApiClient.patch(
        '/admin/orders/${widget.orderId}/status',
        body: {'status': newStatus, 'comment': comment},
      );
      if (mounted) {
        setState(() {
          _order = Map<String, dynamic>.from(res as Map);
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status transitioned to ${newStatus.toUpperCase()}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade800;
      case 'confirmed':
        return Colors.blue.shade700;
      case 'preparing':
        return Colors.purple.shade700;
      case 'out_for_delivery':
        return Colors.teal.shade700;
      case 'delivered':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found.')),
      );
    }

    final status = _order!['status']?.toString() ?? 'pending';
    final addr = _order!['delivery_address_snapshot'] as Map<String, dynamic>? ?? {};
    final items = (_order!['items'] as List?) ?? [];
    final history = (_order!['status_history'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_order!['order_number'] ?? 'Order Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _getStatusColor(status)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping_rounded, color: _getStatusColor(status), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUS: ${status.replaceAll('_', ' ').toUpperCase()}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _getStatusColor(status),
                          ),
                        ),
                        Text(
                          'Order Placed: ${_order!['created_at']?.toString().substring(0, 10) ?? ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // State Machine Fulfillment Actions
            if (status != 'delivered' && status != 'cancelled') ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fulfillment Actions',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (status == 'pending')
                            ElevatedButton.icon(
                              onPressed: _isUpdating ? null : () => _updateStatus('confirmed'),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('CONFIRM ORDER'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                            ),
                          if (status == 'confirmed')
                            ElevatedButton.icon(
                              onPressed: _isUpdating ? null : () => _updateStatus('preparing'),
                              icon: const Icon(Icons.handyman_rounded, size: 16),
                              label: const Text('MARK PREPARING'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
                            ),
                          if (status == 'preparing')
                            ElevatedButton.icon(
                              onPressed: _isUpdating ? null : () => _updateStatus('out_for_delivery'),
                              icon: const Icon(Icons.delivery_dining_rounded, size: 16),
                              label: const Text('OUT FOR DELIVERY'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                            ),
                          if (status == 'out_for_delivery')
                            ElevatedButton.icon(
                              onPressed: _isUpdating ? null : () => _updateStatus('delivered'),
                              icon: const Icon(Icons.task_alt_rounded, size: 16),
                              label: const Text('MARK DELIVERED'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                            ),
                          OutlinedButton.icon(
                            onPressed: _isUpdating ? null : () => _updateStatus('cancelled', comment: 'Cancelled by admin'),
                            icon: const Icon(Icons.cancel_rounded, size: 16, color: Colors.red),
                            label: const Text('CANCEL ORDER', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Delivery Address Snapshot Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Delivery Address Snapshot',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      addr['recipient_name'] ?? 'Recipient',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${addr['street']}, ${addr['city']}, ${addr['state']} - ${addr['postal_code']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Phone: ${addr['phone'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Order Items Snapshot Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Items',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
                    ),
                    const SizedBox(height: 10),
                    ...items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item['product_name_snapshot']} (x${item['quantity']})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '₹${item['line_total']}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(color: AppColors.textSecondary)),
                        Text('₹${_order!['subtotal']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Charge:', style: TextStyle(color: AppColors.textSecondary)),
                        Text('₹${_order!['delivery_charge']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(
                          '₹${_order!['total']}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status History Timeline Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audit & Status Timeline',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
                    ),
                    const SizedBox(height: 10),
                    ...history.map((h) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle, size: 8, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h['new_status'].toString().toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  if (h['comment'] != null)
                                    Text(
                                      h['comment'],
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  Text(
                                    h['created_at']?.toString().substring(0, 19).replaceAll('T', ' ') ?? '',
                                    style: const TextStyle(fontSize: 10, color: AppColors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
