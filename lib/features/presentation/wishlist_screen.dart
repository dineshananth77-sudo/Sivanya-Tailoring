import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/service/api_service.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/sivanya_loader.dart';
import '../auth/login_screen.dart';
import 'depth/design_details_screen.dart';
import 'depth/wishlist_manager.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistManager.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text(
          'MY WISHLIST',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: wishlist,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.softLavender,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${wishlist.items.length} SAVED',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: wishlist,
        builder: (context, child) {
          final isLoggedIn = ApiService.isAuthenticated;

          if (wishlist.isLoading && wishlist.items.isEmpty) {
            return const Center(
              child: SivanyaLoader(size: 64, message: 'Loading your wishlist...'),
            );
          }

          if (!isLoggedIn) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: AppColors.softLavender,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border_rounded, size: 44, color: AppColors.primary),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Sign In to View Your Wishlist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Save your favourite bespoke designs and custom tailoring inspirations in one place.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 180,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text('SIGN IN'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (wishlist.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.softLavender,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border_rounded, size: 38, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Wishlist is Empty',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Explore our fashion collection and tap the heart to save outfits.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: wishlist.items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              mainAxisExtent: 260,
            ),
            itemBuilder: (context, index) {
              final product = wishlist.items[index];
              final title = product['title'] ?? 'Design';
              final category = product['category'] ?? 'Outfit';
              final price = product['price'] ?? '₹999';
              final image = product['image'];

              return ProductCard(
                title: title,
                category: category,
                price: price,
                imageUrl: image,
                isFavorite: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DesignDetailsScreen(
                        title: title,
                        category: category,
                        price: price,
                        imageUrl: image,
                      ),
                    ),
                  );
                },
                onWishlistTap: () {
                  wishlist.remove(product);
                },
              );
            },
          );
        },
      ),
    );
  }
}
