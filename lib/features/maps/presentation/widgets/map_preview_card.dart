import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/features/maps/data/maps_repository.dart';
import 'package:reziphay_mobile/features/maps/models/map_destination.dart';

class MapPreviewCard extends ConsumerStatefulWidget {
  const MapPreviewCard({
    required this.destination,
    super.key,
    this.title = 'Location',
  });

  final MapDestination destination;
  final String title;

  @override
  ConsumerState<MapPreviewCard> createState() => _MapPreviewCardState();
}

class _MapPreviewCardState extends ConsumerState<MapPreviewCard> {
  String? _busyAction;

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF173B3A),
                  Color(0xFF2A6664),
                  Color(0xFF8CC9B2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -12,
                  top: -4,
                  child: Icon(
                    Icons.near_me_outlined,
                    size: 82,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            destination.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (destination.subtitle != null &&
                        destination.subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        destination.subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      destination.addressLine,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (destination.note != null &&
              destination.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              destination.note!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Open in maps',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.map_outlined,
                  isLoading: _busyAction == 'preview',
                  onPressed: () => _runAction(
                    'preview',
                    () => ref
                        .read(mapsRepositoryProvider)
                        .openPreview(destination),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Directions',
                  icon: Icons.route_outlined,
                  isLoading: _busyAction == 'directions',
                  onPressed: () => _runAction(
                    'directions',
                    () => ref
                        .read(mapsRepositoryProvider)
                        .openDirections(destination),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runAction(String action, Future<void> Function() task) async {
    setState(() => _busyAction = action);

    try {
      await task();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _busyAction = null);
      }
    }
  }
}
