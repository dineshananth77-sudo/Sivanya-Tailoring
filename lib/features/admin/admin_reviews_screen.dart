import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/service/api_client.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'visible', 'hidden'

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, String>{
        'limit': '50',
        if (_filter == 'visible') 'visible': 'true',
        if (_filter == 'hidden') 'visible': 'false',
      };

      final res = await ApiClient.get('/admin/reviews', queryParams: params);
      if (mounted) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(res['items'] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVisibility(String reviewId, bool currentVisibility) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.patch(
        '/admin/reviews/$reviewId/visibility',
        body: {'is_visible': !currentVisibility},
      );
      _fetchReviews();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to permanently delete this customer review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.delete('/admin/reviews/$reviewId');
      _fetchReviews();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Reviews Moderation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Visible Only', 'visible'),
                const SizedBox(width: 8),
                _buildFilterChip('Hidden / Flagged', 'hidden'),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _reviews.isEmpty
                    ? const Center(child: Text('No reviews found for this filter.'))
                    : RefreshIndicator(
                        onRefresh: _fetchReviews,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _reviews.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final r = _reviews[idx];
                            final isVisible = r['is_visible'] == true;
                            final rating = r['rating'] as int? ?? 5;
                            final date = r['created_at']?.toString().substring(0, 10) ?? '';

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isVisible ? AppColors.border : Colors.orange.shade300,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          r['customer_name'] ?? 'Verified Customer',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Row(
                                          children: List.generate(5, (starIdx) {
                                            return Icon(
                                              starIdx < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                              size: 16,
                                              color: Colors.amber.shade700,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (r['comment'] != null && r['comment'].toString().isNotEmpty)
                                      Text(
                                        r['comment'],
                                        style: const TextStyle(fontSize: 12, color: AppColors.text),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          date,
                                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                        ),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _toggleVisibility(r['id'], isVisible),
                                              icon: Icon(
                                                isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                                size: 16,
                                                color: isVisible ? Colors.orange.shade800 : Colors.green.shade800,
                                              ),
                                              label: Text(
                                                isVisible ? 'HIDE' : 'SHOW',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isVisible ? Colors.orange.shade800 : Colors.green.shade800,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                              onPressed: () => _deleteReview(r['id']),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppColors.text,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceMuted,
      onSelected: (_) {
        setState(() => _filter = value);
        _fetchReviews();
      },
    );
  }
}
