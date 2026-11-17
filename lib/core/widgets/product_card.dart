import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'reusable_image.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final String category;
  final String price;
  final String? originalPrice;
  final String? discount;
  final String? rating;
  final String? reviews;
  final String? imageUrl;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onWishlistTap;

  const ProductCard({
    super.key,
    required this.title,
    required this.category,
    required this.price,
    this.originalPrice,
    this.discount,
    this.rating = '4.2',
    this.reviews = '128',
    this.imageUrl,
    this.isFavorite = false,
    required this.onTap,
    required this.onWishlistTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight, width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Wishlist Heart
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.0, // Clean 1:1 square ratio
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(9),
                    ),
                    child: ReusableImage(
                      imageUrl: imageUrl ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Wishlist Icon Button (Round white translucent pill)
                Positioned(
                  top: 7,
                  right: 7,
                  child: GestureDetector(
                    onTap: onWishlistTap,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.9),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? AppColors.discountBadge : AppColors.grey,
                        size: 16,
                      ),
                    ),
                  ),
                ),

                // Category Tag
                Positioned(
                  left: 7,
                  bottom: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(9.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Price Row (Price, Original, Discount)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      if (originalPrice != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          originalPrice!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      if (discount != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          discount!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.discountBadge,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Rating Badge & Free Delivery
                  Row(
                    children: [
                      if (rating != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.greenRating,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rating!,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.star_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        if (reviews != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '($reviews)',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                      const Spacer(),
                      const Text(
                        'Free Delivery',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
