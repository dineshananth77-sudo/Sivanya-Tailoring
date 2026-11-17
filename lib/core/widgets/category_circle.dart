import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'reusable_image.dart';

class CategoryCircle extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;
  final bool isSelected;

  const CategoryCircle({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                color: AppColors.surface,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: ReusableImage(
                  imageUrl: imageUrl,
                  width: 56,
                  height: 56,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 66,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
