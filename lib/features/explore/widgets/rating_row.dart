// rating_row.dart
// Reziphay

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/discovery.dart';

class RatingRow extends StatelessWidget {
  const RatingRow({super.key, required this.stats, this.small = false});

  final RatingStats stats;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 12.0 : 14.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size, color: const Color(0xFFFFB800)),
        const SizedBox(width: 2),
        Text(
          stats.avgRating > 0
              ? stats.avgRating.toStringAsFixed(1)
              : '–',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (stats.reviewCount > 0) ...[
          const SizedBox(width: 3),
          Text(
            '(${stats.reviewCount})',
            style: TextStyle(fontSize: size - 1, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
