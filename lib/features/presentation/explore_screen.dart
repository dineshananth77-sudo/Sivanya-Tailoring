import 'package:flutter/material.dart';

import 'package:stitch_style/app/theme/app_colors.dart';
import 'package:stitch_style/core/constants/mock_fashion_data.dart';
import 'package:stitch_style/core/service/api_service.dart';
import 'package:stitch_style/core/widgets/app_search_bar.dart';
import 'package:stitch_style/core/widgets/product_card.dart';
import 'package:stitch_style/features/auth/login_screen.dart';
import 'package:stitch_style/features/presentation/depth/custom_stitching_screen.dart';
import 'package:stitch_style/features/presentation/depth/design_details_screen.dart';
import 'package:stitch_style/features/presentation/depth/wishlist_manager.dart';

class ExploreScreen extends StatefulWidget {
  final String initialCategory;
  final String initialSearch;

  const ExploreScreen({
    super.key,
    this.initialCategory = 'All',
    this.initialSearch = '',
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController searchController = TextEditingController();
  late String selectedCategory;
  String sortBy = 'Popular';

  final List<String> categories = [
    'All',
    'Sarees',
    'Kurtis',
    'Blouses',
    'Lehengas',
    'Dresses',
    'Salwar Suits',
    'Anarkali Suits',
    'Gowns',
    'Palazzo Sets',
    'Sharara Sets',
    'Chudidars',
    'Half Sarees',
    'Ethnic Wear',
    'Party Wear',
    'Bridal Wear',
    'Co-ord Sets',
    'Skirts & Tops',
    'Tunics',
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'All';
    searchController.text = widget.initialSearch;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool get _showBrowseGrid {
    return searchController.text.trim().isEmpty && selectedCategory == 'All';
  }

  List<Map<String, dynamic>> get filteredProducts {
    final searchText = searchController.text.trim().toLowerCase();
    final all = MockFashionData.products;

    return all.where((product) {
      final matchesCategory = selectedCategory == 'All' ||
          product['category'] == selectedCategory;

      final title = product['title'].toString().toLowerCase();
      final cat = product['category'].toString().toLowerCase();
      final matchesSearch = searchText.isEmpty ||
          title.contains(searchText) ||
          cat.contains(searchText);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DesignDetailsScreen(
          title: product['title'].toString(),
          category: product['category'].toString(),
          price: product['price'].toString(),
          imageUrl: product['image']?.toString(),
        ),
      ),
    );
  }

  void _openSortSheet() {
    final sortOptions = ['Popular', 'Price: Low to High', 'Price: High to Low', 'Newest First', 'Top Rated'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppColors.surface,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...sortOptions.map((option) {
                final isSelected = sortBy == option;
                return ListTile(
                  dense: true,
                  title: Text(
                    option,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.text,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 18)
                      : null,
                  onTap: () {
                    setState(() => sortBy = option);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrowseGrid() {
    // Filter out 'Custom Stitching' — it has its own FAB
    final browseCats = MockFashionData.categories
        .where((c) => c['name'] != 'Custom Stitching')
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
      itemCount: browseCats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final cat = browseCats[index];
        final name = cat['name'] ?? '';
        final imageUrl = cat['image'] ?? '';

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedCategory = categories.contains(name) ? name : 'All';
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.surfaceMuted,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context2, err, stack) => Container(
                      color: AppColors.surfaceMuted,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                  height: 1.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistManager.instance;
    final showBrowse = _showBrowseGrid;
    final displayedProducts = showBrowse ? [] : filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text(
          'EXPLORE FASHION',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: AppColors.primary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: AppSearchBar(
              controller: searchController,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Horizontal Category Filter Chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = selectedCategory == cat;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = cat;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.text,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Filter Bar (Item count & Sort)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.borderLight, width: 0.8),
                bottom: BorderSide(color: AppColors.borderLight, width: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  showBrowse
                      ? 'Browse Categories'
                      : '${displayedProducts.length} Designs Found',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: _openSortSheet,
                  child: Row(
                    children: [
                      const Icon(Icons.sort_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Sort: $sortBy',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Browse Categories Grid OR Products Grid OR Empty State
          Expanded(
            child: showBrowse
                ? _buildBrowseGrid()
                : (displayedProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No Outfits Found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try searching with a different keyword or category.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : AnimatedBuilder(
                        animation: wishlist,
                        builder: (context, _) {
                          return GridView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: displayedProducts.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 272,
                            ),
                            itemBuilder: (context, index) {
                              final item = displayedProducts[index];
                              final title = item['title'].toString();
                              final category = item['category'].toString();
                              final isFav = wishlist.isFavorite(title, category);

                              return ProductCard(
                                title: title,
                                category: category,
                                price: item['price'].toString(),
                                originalPrice: item['originalPrice']?.toString(),
                                discount: item['discount']?.toString(),
                                rating: item['rating']?.toString(),
                                reviews: item['reviews']?.toString(),
                                imageUrl: item['image']?.toString(),
                                isFavorite: isFav,
                                onTap: () => _openProductDetails(item),
                                onWishlistTap: () {
                                  if (!ApiService.isAuthenticated) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                    return;
                                  }
                                  wishlist.toggle({
                                    'title': title,
                                    'category': category,
                                    'price': item['price'].toString(),
                                    'image': item['image'].toString(),
                                  });
                                },
                              );
                            },
                          );
                        },
                      )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomStitchingScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.cut_outlined, size: 18, color: Colors.white),
        label: const Text(
          'Custom Stitching',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
