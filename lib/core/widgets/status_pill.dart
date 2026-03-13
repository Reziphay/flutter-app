import 'package:flutter/material.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';

enum StatusPillTone { neutral, info, success, warning, error }

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    super.key,
    this.tone = StatusPillTone.neutral,
    this.icon,
  });

  final String label;
  final StatusPillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = switch (tone) {
      StatusPillTone.neutral => (AppColors.ink, AppColors.surfaceSoft),
      StatusPillTone.info => (AppColors.info, const Color(0xFFEFF3FF)),
      StatusPillTone.success => (AppColors.success, const Color(0xFFEAF8F1)),
      StatusPillTone.warning => (AppColors.warning, const Color(0xFFFFF5DF)),
      StatusPillTone.error => (AppColors.error, const Color(0xFFFDECEC)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.$2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: palette.$1),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.$1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
