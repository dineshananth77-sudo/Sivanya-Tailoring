import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/service/api_service.dart';
import '../../core/widgets/sivanya_loader.dart';
import '../auth/login_screen.dart';
import '../data/order_service.dart';
import 'depth/custom_stitching_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    OrderService.ordersRevision.addListener(_onOrdersRevisionChanged);
    ApiService.currentUserNotifier.addListener(_onOrdersRevisionChanged);
    _loadOrders();
  }

  void _onOrdersRevisionChanged() {
    if (mounted) {
      _refreshOrders();
    }
  }

  @override
  void dispose() {
    OrderService.ordersRevision.removeListener(_onOrdersRevisionChanged);
    ApiService.currentUserNotifier.removeListener(_onOrdersRevisionChanged);
    super.dispose();
  }

  void _loadOrders() {
    _ordersFuture = _fetchOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final token = await ApiService.getToken();
    if (token == null && !ApiService.isAuthenticated) return [];
    if (!ApiService.isAuthenticated) {
      await ApiService.checkSession();
    }
    return await _orderService.fetchOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() => _loadOrders());
    await _ordersFuture;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue.shade700;
      case 'in progress':
        return Colors.orange.shade800;
      case 'completed':
        return AppColors.greenRating;
      case 'cancelled':
        return AppColors.discountBadge;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Recent';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'Recent';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text(
          'MY ORDERS',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SivanyaLoader(size: 64, message: 'Loading orders...'));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.secondary),
                    const SizedBox(height: 12),
                    Text('Failed to load orders: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _refreshOrders, child: const Text('RETRY')),
                  ],
                ),
              ),
            );
          }

          if (!ApiService.isAuthenticated) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AppColors.softLavender,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline_rounded, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Please Login to Track Orders',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to your account to view your past and active custom tailoring orders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ).then((_) => _refreshOrders());
                      },
                      child: const Text('LOGIN / SIGN UP', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: AppColors.softLavender,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Orders Placed Yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 6),
                  const Text('Explore our collection or request custom stitching to place an order.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CustomStitchingScreen()),
                      );
                    },
                    icon: const Icon(Icons.cut_outlined, size: 18),
                    label: const Text('START CUSTOM STITCHING', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final status = (order['status'] ?? 'pending').toString();
                final statusColor = _statusColor(status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight, width: 0.8),
                    boxShadow: const [
                      BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 1.5)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.softLavender,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.checkroom_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (order['design_title'] ?? 'Custom Outfit').toString(),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                                  ),
                                  Text(
                                    (order['garment_type'] ?? 'Garment').toString().toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor, width: 0.8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 0.8, color: AppColors.borderLight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Category: ${order['design_category'] ?? 'Custom'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('Price: ${order['design_price'] ?? '₹999'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Placed On: ${_formatDate(order['created_at'])}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          if (status.toLowerCase() == 'pending')
                            TextButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Cancel Order'),
                                    content: const Text('Are you sure you want to cancel this pending order?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('CANCEL ORDER', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await _orderService.cancelOrder(order['id'].toString());
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Order cancelled successfully.')),
                                      );
                                      _refreshOrders();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                }
                              },
                              icon: const Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                              label: const Text('Cancel Order', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
