
import 'package:flutter/material.dart';

import 'package:stitch_style/app/theme/app_colors.dart';
import 'package:stitch_style/core/service/api_service.dart';
import 'package:stitch_style/features/auth/login_screen.dart';
import 'package:stitch_style/features/presentation/depth/wishlist_manager.dart';
import 'package:stitch_style/features/presentation/depth/design_details_screen.dart';
import 'package:stitch_style/features/presentation/depth/custom_stitching_screen.dart';

class DesignCard extends StatelessWidget {
  final String title;
  final String category;
  final String price;
  final String? imageUrl;

  const DesignCard({
    super.key,
    required this.title,
    required this.category,
    required this.price,
    this.imageUrl,
  });

  // Use 'image' because WishlistManager and WishlistScreen
  // both expect this exact key.
  Map<String, String> get product => {
        'title': title,
        'category': category,
        'price': price,
        'image': imageUrl ?? '',
      };

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DesignDetailsScreen(
          title: title,
          category: category,
          price: price,
          imageUrl: imageUrl,
        ),
      ),
    );
  }

  void _openCustomization(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomStitchingScreen(
          initialTitle: title,
          initialCategory: category,
          initialPrice: price,
          initialImageUrl: imageUrl,
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 165,
      width: double.infinity,
      color: AppColors.secondary.withValues(alpha: 0.3),
      child: const Icon(
        Icons.checkroom_outlined,
        size: 45,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildProductImage() {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _imagePlaceholder();
    }

    return Image.network(
      imageUrl!,
      height: 165,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Container(
          height: 165,
          width: double.infinity,
          color: AppColors.secondary.withValues(alpha: 0.2),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _imagePlaceholder();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistManager.instance;

    const plum = Color(0xFF492B46);
    const ivory = Color(0xFFF5F1E9);
    const charcoal = Color(0xFF22201F);
    const mutedRose = Color(0xFFB98591);

    return Container(
      width: 165,
      height: 320,
      decoration: BoxDecoration(
        color: ivory,
        border: Border.all(
          color: charcoal,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: plum,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image and wishlist button
          Stack(
            children: [
              GestureDetector(
                onTap: () => _openDetails(context),
                child: SizedBox(
                  height: 165,
                  width: double.infinity,
                  child: _buildProductImage(),
                ),
              ),

              // Wishlist button
              Positioned(
                top: 9,
                right: 9,
                child: AnimatedBuilder(
                  animation: wishlist,
                  builder: (context, child) {
                    final isFavorite =
                        wishlist.isFavorite(title, category);

                    return Material(
                      color: ivory,
                      child: InkWell(
                        onTap: () {
                          if (!ApiService.isAuthenticated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                            return;
                          }
                          wishlist.toggle(product);
                        },
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: charcoal,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 19,
                            color: isFavorite ? mutedRose : plum,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Category label
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  color: plum,
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: ivory,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Product information
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _openDetails(context),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: charcoal,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Container(
                    width: 27,
                    height: 2,
                    color: mutedRose,
                  ),

                  const SizedBox(height: 6),

                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: plum,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const Spacer(),

                  // Customize button
                  SizedBox(
                    width: double.infinity,
                    height: 35,
                    child: ElevatedButton(
                      onPressed: () => _openCustomization(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: plum,
                        foregroundColor: ivory,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'CUSTOMIZE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 7),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
