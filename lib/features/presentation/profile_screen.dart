import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/service/api_service.dart';
import '../../../features/admin/admin_dashboard_screen.dart';
import '../../../features/auth/login_screen.dart';
import '../../../features/data/measurement_service.dart';
import 'orders_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final MeasurementService _measurementService = MeasurementService();

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _measurements;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    if (ApiService.isAuthenticated) {
      try {
        _profile = await ApiService.getProfile();
        _measurements = await _measurementService.loadMeasurements();
      } catch (e) {
        debugPrint('Profile error: $e');
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    ).then((_) => _loadProfileData());
  }

  Future<void> _launchWhatsAppSupport() async {
    final whatsappUrl = Uri.https(
      'wa.me',
      '/${AppConstants.whatsappBusinessNumber}',
      {'text': AppConstants.customerSupportMessage},
    );

    try {
      final launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WhatsApp is not installed or could not be opened on your device.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ApiService.isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text(
          'ACCOUNT & PROFILE',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : SingleChildScrollView(
        child: Column(
          children: [
            // 1. User Info Header Card
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.softLavender,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? (_profile?['full_name'] ?? 'Sivanya Customer') : 'Guest User',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLoggedIn ? (_profile?['email'] ?? '') : 'Login to view orders and saved measurements',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (!isLoggedIn)
                    ElevatedButton(
                      onPressed: _openLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('LOGIN'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. Saved Measurements Section
            if (isLoggedIn) ...[
              _buildSectionCard(
                title: 'My Saved Measurements',
                icon: Icons.straighten_rounded,
                child: _measurements != null && _measurements!.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _measurements!.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border, width: 0.8),
                            ),
                            child: Text(
                              '${entry.key.toUpperCase()}: ${entry.value}"',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text),
                            ),
                          );
                        }).toList(),
                      )
                    : const Text(
                        'No saved measurements yet. Enter them during your next order to save for quick re-orders!',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
              ),
              const SizedBox(height: 12),
            ],

            // 3. Navigation List Tiles
            Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  if (isLoggedIn && _profile?['role'] == 'admin') ...[
                    _tile(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Admin Management Panel',
                      subtitle: 'Manage products, images, delivery & orders',
                      titleColor: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        ).then((_) => _loadProfileData());
                      },
                    ),
                    const Divider(height: 1, indent: 56, color: AppColors.borderLight),
                  ],
                  _tile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Orders',
                    subtitle: 'Track past & ongoing tailoring consultations',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: AppColors.borderLight),
                  _tile(
                    icon: Icons.favorite_border_rounded,
                    title: 'My Wishlist',
                    subtitle: 'View saved designs and lehengas',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: AppColors.borderLight),
                  _tile(
                    icon: Icons.support_agent_rounded,
                    title: 'Customer Support',
                    subtitle: 'Chat with our master tailor on WhatsApp',
                    onTap: _launchWhatsAppSupport,
                  ),
                  if (isLoggedIn) ...[
                    const Divider(height: 1, indent: 56, color: AppColors.borderLight),
                    _tile(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out from this device',
                      titleColor: AppColors.discountBadge,
                      onTap: () async {
                        await ApiService.logout();
                        _loadProfileData();
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.softLavender,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: titleColor ?? AppColors.primary),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: titleColor ?? AppColors.text)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.grey),
      onTap: onTap,
    );
  }
}
