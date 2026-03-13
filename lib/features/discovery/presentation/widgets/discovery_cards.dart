import 'package:flutter/material.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_media.dart';

class RatingRow extends StatelessWidget {
  const RatingRow({required this.rating, this.reviewCount, super.key});

  final double rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFE8A317), size: 18),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: AppSpacing.xxs),
          Text('($reviewCount)', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.service,
    required this.onTap,
    super.key,
    this.width = 280,
  });

  final ServiceSummary service;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DiscoveryMedia(
              seed: service.id,
              label: service.name,
              kind: DiscoveryMediaKind.service,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.lg),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VisibilityWrap(labels: service.visibilityLabels),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    service.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    [
                      service.brandName ?? service.providerName,
                      service.categoryName,
                    ].join(' · '),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RatingRow(
                    rating: service.rating,
                    reviewCount: service.reviewCount,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    service.priceLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${service.distanceKm.toStringAsFixed(1)} km · ${service.nextAvailabilityLabel}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StatusPill(
                    label: service.approvalMode.label,
                    tone: service.approvalMode == ApprovalMode.manual
                        ? StatusPillTone.warning
                        : StatusPillTone.success,
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

class BrandCard extends StatelessWidget {
  const BrandCard({
    required this.brand,
    required this.onTap,
    super.key,
    this.width = 280,
  });

  final BrandSummary brand;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DiscoveryMedia(
              seed: brand.id,
              label: brand.name,
              kind: DiscoveryMediaKind.brand,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.lg),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VisibilityWrap(labels: brand.visibilityLabels),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    brand.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    brand.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RatingRow(
                    rating: brand.rating,
                    reviewCount: brand.reviewCount,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${brand.memberCount} providers · ${brand.serviceCount} services',
                    style: Theme.of(context).textTheme.bodySmall,
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

class ProviderCard extends StatelessWidget {
  const ProviderCard({
    required this.provider,
    required this.onTap,
    super.key,
    this.width = 280,
  });

  final ProviderSummary provider;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DiscoveryMedia(
                  seed: provider.id,
                  label: provider.name,
                  kind: DiscoveryMediaKind.provider,
                  width: 72,
                  height: 72,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _VisibilityWrap(labels: provider.visibilityLabels),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        provider.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        provider.headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            RatingRow(
              rating: provider.rating,
              reviewCount: provider.reviewCount,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${provider.completedReservations} completed · ${provider.responseReliability}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, super.key});

  final ReviewPreview review;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.authorName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              RatingRow(rating: review.rating),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            review.comment,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(review.dateLabel, style: Theme.of(context).textTheme.bodySmall),
          if (review.reply != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                review.reply!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DetailFactRow extends StatelessWidget {
  const DetailFactRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityWrap extends StatelessWidget {
  const _VisibilityWrap({required this.labels});

  final List<VisibilityLabel> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: labels
          .map(
            (label) => StatusPill(
              label: label.label,
              tone: switch (label) {
                VisibilityLabel.common => StatusPillTone.neutral,
                VisibilityLabel.vip => StatusPillTone.info,
                VisibilityLabel.bestOfMonth => StatusPillTone.success,
                VisibilityLabel.sponsored => StatusPillTone.warning,
              },
            ),
          )
          .toList(),
    );
  }
}
