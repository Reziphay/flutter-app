import 'package:flutter/material.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/features/media/models/app_media_asset.dart';

enum DiscoveryMediaKind { service, brand, provider, category }

class DiscoveryMedia extends StatelessWidget {
  const DiscoveryMedia({
    required this.seed,
    required this.label,
    required this.kind,
    super.key,
    this.height = 112,
    this.width = double.infinity,
    this.borderRadius,
    this.media,
  });

  final String seed;
  final String label;
  final DiscoveryMediaKind kind;
  final double height;
  final double width;
  final BorderRadiusGeometry? borderRadius;
  final AppMediaAsset? media;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = media?.label ?? label;
    final effectiveSeed = media?.id ?? seed;
    final palette = _palettes[effectiveSeed.hashCode.abs() % _palettes.length];
    final radius = borderRadius ?? BorderRadius.circular(AppRadii.lg);

    if (media?.hasBytes == true) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          width: width,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(media!.bytes!, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.56),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(_iconForKind(kind), color: Colors.white, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        effectiveLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -18,
            child: Icon(
              _iconForKind(kind),
              size: 74,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconForKind(kind), color: Colors.white, size: 20),
                const Spacer(),
                Text(
                  effectiveLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForKind(DiscoveryMediaKind kind) {
    return switch (kind) {
      DiscoveryMediaKind.service => Icons.event_available_outlined,
      DiscoveryMediaKind.brand => Icons.storefront_outlined,
      DiscoveryMediaKind.provider => Icons.person_outline,
      DiscoveryMediaKind.category => Icons.grid_view_outlined,
    };
  }
}

const _palettes = [
  [Color(0xFF9989FF), Color(0xFF6657D9)],
  [Color(0xFF5E8BFF), Color(0xFF324D99)],
  [Color(0xFF3FA8A4), Color(0xFF256B68)],
  [Color(0xFFF6A96C), Color(0xFFB26D37)],
  [Color(0xFF8BC686), Color(0xFF4D8E49)],
];
