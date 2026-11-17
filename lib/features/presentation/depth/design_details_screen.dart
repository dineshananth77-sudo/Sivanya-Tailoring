import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/service/api_service.dart';
import '../../../../core/widgets/reusable_image.dart';
import '../../../../features/auth/login_screen.dart';
import '../booking_screen.dart';
import 'custom_stitching_screen.dart';
import 'wishlist_manager.dart';

class DesignDetailsScreen extends StatefulWidget {
  final String title;
  final String category;
  final String price;
  final String? imageUrl;

  const DesignDetailsScreen({
    super.key,
    required this.title,
    required this.category,
    required this.price,
    this.imageUrl,
  });

  @override
  State<DesignDetailsScreen> createState() => _DesignDetailsScreenState();
}

class _DesignDetailsScreenState extends State<DesignDetailsScreen> {
  final WishlistManager wishlist = WishlistManager.instance;
  String selectedSize = 'Custom Fit';

  final List<String> sizes = ['XS', 'S', 'M', 'L', 'XL', 'Custom Fit'];

  Map<String, String> get product => {
        'title': widget.title,
        'category': widget.category,
        'price': widget.price,
        'image': widget.imageUrl ?? '',
      };

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _toggleWishlist() {
    if (!ApiService.isAuthenticated) {
      _openLogin();
      return;
    }

    wishlist.toggle(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wishlist.isFavorite(widget.title, widget.category)
              ? 'Added to Wishlist'
              : 'Removed from Wishlist',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _openCustomization() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomStitchingScreen(
          initialTitle: widget.title,
          initialCategory: widget.category,
          initialPrice: widget.price,
          initialImageUrl: widget.imageUrl,
        ),
      ),
    );
  }

  void _continueToBooking() {
    if (!ApiService.isAuthenticated) {
      _openLogin();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          designTitle: widget.title,
          designCategory: widget.category,
          designPrice: widget.price,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: wishlist,
            builder: (context, _) {
              final isFav = wishlist.isFavorite(widget.title, widget.category);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.discountBadge : AppColors.text,
                ),
                onPressed: _toggleWishlist,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.text),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Image
            Container(
              color: AppColors.surface,
              width: double.infinity,
              height: 380,
              child: ReusableImage(
                imageUrl: widget.imageUrl ?? '',
                fit: BoxFit.cover,
              ),
            ),

            // 2. Main Details Card
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.softLavender,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.greenRating,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              '4.3',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.star_rounded, size: 12, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '₹1,999',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '50% OFF',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.discountBadge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.offerText),
                      SizedBox(width: 6),
                      Text(
                        'Free Measurement Consultation & Home Delivery',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.offerText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 3. Size Selection Card
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Size or Custom Fit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: sizes.map((size) {
                      final isSelected = selectedSize == size;
                      return ChoiceChip(
                        label: Text(size),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceMuted,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.text,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => selectedSize = size);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 4. Product Details & Tailoring Guarantee
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Specifications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _specRow('Fabric', 'Pure Silk & Cotton Blend'),
                  _specRow('Lining', '100% Breathable Cotton Included'),
                  _specRow('Stitching', 'Handcrafted Custom Tailoring'),
                  _specRow('Consultation', 'WhatsApp Tailor Audio/Video Call'),
                  _specRow('Delivery Time', '4 to 6 Business Days'),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      // Bottom Dual Sticky Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // 1. Customize Button (Outlined)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _openCustomization,
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('CUSTOMIZE'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 2. Book Consultation Button (Solid)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _continueToBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'BOOK NOW',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
