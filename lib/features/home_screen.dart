import 'package:flutter/material.dart';

import 'package:stitch_style/app/theme/app_colors.dart';
import 'package:stitch_style/core/constants/mock_fashion_data.dart';
import 'package:stitch_style/core/service/api_service.dart';
import 'package:stitch_style/core/widgets/app_search_bar.dart';
import 'package:stitch_style/core/widgets/category_circle.dart';
import 'package:stitch_style/core/widgets/custom_stitching_banner.dart';
import 'package:stitch_style/core/widgets/product_card.dart';
import 'package:stitch_style/core/widgets/promotional_banner.dart';
import 'package:stitch_style/core/widgets/sivanya_loader.dart';
import 'package:stitch_style/features/auth/login_screen.dart';
import 'package:stitch_style/features/data/order_service.dart';
import 'package:stitch_style/features/presentation/depth/custom_stitching_screen.dart' as custom;
import 'package:stitch_style/features/presentation/depth/design_details_screen.dart';
import 'package:stitch_style/features/presentation/depth/wishlist_manager.dart';
import 'package:stitch_style/features/presentation/explore_screen.dart';
import 'package:stitch_style/features/presentation/orders_screen.dart';
import 'package:stitch_style/features/presentation/profile_screen.dart';
import 'package:stitch_style/features/presentation/wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController();
  final OrderService _orderService = OrderService();
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  int _currentBannerIndex = 0;
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchRecentOrders();
    OrderService.ordersRevision.addListener(_onOrdersRevisionChanged);
    ApiService.currentUserNotifier.addListener(_onOrdersRevisionChanged);
  }

  void _onOrdersRevisionChanged() {
    if (mounted) {
      setState(() {
        _ordersFuture = _fetchRecentOrders();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentOrders() async {
    final token = await ApiService.getToken();
    if (token == null && !ApiService.isAuthenticated) return [];
    if (!ApiService.isAuthenticated) {
      await ApiService.checkSession();
    }
    return await _orderService.fetchOrders();
  }

  @override
  void dispose() {
    OrderService.ordersRevision.removeListener(_onOrdersRevisionChanged);
    ApiService.currentUserNotifier.removeListener(_onOrdersRevisionChanged);
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  void _openExploreWithCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExploreScreen(initialCategory: category),
      ),
    );
  }

  void _openCustomStitching() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const custom.CustomStitchingScreen(),
      ),
    );
  }

  void _openProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DesignDetailsScreen(
          title: product['title'].toString(),
          category: product['category'].toString(),
          price: product['price'].toString(),
          imageUrl: product['image']?.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistManager.instance;
    final allProducts = MockFashionData.products;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildTopAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Meesho-Style Discount Highlight Bar
            _buildDiscountHighlightBar(),

            // 2. Horizontal Circular Category Avatars
            _buildCategorySection(),

            const SizedBox(height: 10),

            // 3. Promotional Banners Carousel
            _buildBannersCarousel(),

            const SizedBox(height: 10),

            // 4. Custom Stitching High-Impact Feature Banner
            CustomStitchingBanner(
              onTap: _openCustomStitching,
            ),

            const SizedBox(height: 14),

            // 4b. Customer's Latest Orders (Home Screen)
            _buildRecentOrdersSection(),

            const SizedBox(height: 14),

            // 5. Shop by Category Image Cards (Meesho Style)
            _buildShopByCategorySection(),

            const SizedBox(height: 18),

            // 6. Section Header: Trending Outfits
            _buildSectionHeader(
              title: 'Trending Outfits',
              subtitle: 'Tailored to perfection • Popular this week',
              actionText: 'View All',
              onActionTap: () => _openExploreWithCategory('All'),
            ),

            // 7. Products 2-Column Responsive Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: AnimatedBuilder(
                animation: wishlist,
                builder: (context, _) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allProducts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 272,
                    ),
                    itemBuilder: (context, index) {
                      final item = allProducts[index];
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
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0.5,
      titleSpacing: 14,
      title: Row(
        children: [
          // Logo Badge
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/brand/sivanya_logo.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SIVANYA',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'TAILORING & BOUTIQUE',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Wishlist Shortcut
        IconButton(
          icon: const Icon(Icons.favorite_border_rounded, size: 23, color: AppColors.text),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WishlistScreen()),
            );
          },
        ),

        // Orders Shortcut
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, size: 22, color: AppColors.text),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            );
          },
        ),

        // User Account / Profile Button
        ValueListenableBuilder(
          valueListenable: ApiService.currentUserNotifier,
          builder: (context, user, _) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  if (user == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.softLavender,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Icon(
                    user != null ? Icons.person_rounded : Icons.person_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: AppSearchBar(
            controller: _searchController,
            readOnly: true,
            onSearchTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExploreScreen(initialCategory: 'All'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountHighlightBar() {
    return Container(
      width: double.infinity,
      color: AppColors.offerBanner,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppColors.offerText,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'SPECIAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Upto ₹150 OFF on 1st Custom Stitching Order',
            style: TextStyle(
              color: AppColors.offerText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = MockFashionData.categories;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 94,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return CategoryCircle(
                  name: cat['name']!,
                  imageUrl: cat['image']!,
                  onTap: () {
                    if (cat['name'] == 'Custom Stitching') {
                      _openCustomStitching();
                    } else {
                      _openExploreWithCategory(cat['name']!);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannersCarousel() {
    final banners = MockFashionData.banners;

    return Column(
      children: [
        SizedBox(
          height: 156,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (idx) {
              setState(() {
                _currentBannerIndex = idx;
              });
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final b = banners[index];
              return PromotionalBanner(
                title: b['title']!,
                subtitle: b['subtitle']!,
                tag: b['tag'],
                imageUrl: b['image']!,
                onTap: () => _openExploreWithCategory('All'),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: _currentBannerIndex == index ? 16 : 5,
              height: 4.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentBannerIndex == index
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShopByCategorySection() {
    final list = MockFashionData.shopByCategory;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Shop By Category',
            subtitle: 'Popular ethnic collections curated for you',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _categoryTile(list[0])),
              const SizedBox(width: 10),
              Expanded(child: _categoryTile(list[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _categoryTile(list[2])),
              const SizedBox(width: 10),
              Expanded(child: _categoryTile(list[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryTile(Map<String, String> item) {
    return GestureDetector(
      onTap: () => _openExploreWithCategory(item['category']!),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderLight, width: 0.8),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 1.5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(item['image']!, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['name']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      item['discount']!,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Recent';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'Recent';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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

  Widget _buildRecentOrdersSection() {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ApiService.currentUserNotifier,
      builder: (context, user, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                title: 'My Latest Orders',
                subtitle: 'Track your custom tailoring orders',
                actionText: 'View All',
                onActionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              if (user == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight, width: 0.8),
                    boxShadow: const [
                      BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 1.5)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.softLavender,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Track Your Tailoring Orders',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Log in to view live order progress and measurement details.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )
              else
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _ordersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 90,
                        alignment: Alignment.center,
                        child: const SivanyaLoader(size: 36, message: 'Loading orders...'),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderLight, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.secondary, size: 22),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Unable to load recent orders',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _ordersFuture = _fetchRecentOrders();
                                });
                              },
                              child: const Text('RETRY'),
                            ),
                          ],
                        ),
                      );
                    }

                    final orders = snapshot.data ?? [];
                    if (orders.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderLight, width: 0.8),
                          boxShadow: const [
                            BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 1.5)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.softLavender,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.checkroom_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'No Active Orders',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Create your first custom stitched outfit today!',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _openCustomStitching,
                              child: const Text('START', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    }

                    final recentOrders = orders.take(3).toList();
                    return Column(
                      children: recentOrders.map((order) {
                        final status = (order['status'] ?? 'pending').toString();
                        final statusColor = _statusColor(status);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OrdersScreen()),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderLight, width: 0.8),
                              boxShadow: const [
                                BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 1.5)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.softLavender,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.checkroom_rounded, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (order['design_title'] ?? order['garment_type'] ?? 'Custom Outfit').toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            (order['design_category'] ?? 'Custom').toString(),
                                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                          ),
                                          const Text(' • ', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                          Text(
                                            _formatDate(order['created_at']),
                                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      (order['design_price'] ?? '₹999').toString(),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.text),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: statusColor, width: 0.6),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: statusColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
