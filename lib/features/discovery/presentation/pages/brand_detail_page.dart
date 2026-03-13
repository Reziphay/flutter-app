import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/provider_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_cards.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_media.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_notice_sheet.dart';

class BrandDetailPage extends ConsumerWidget {
  const BrandDetailPage({required this.brandId, super.key});

  static const path = '/customer/brand/:brandId';

  static String location(String brandId) => '/customer/brand/$brandId';

  final String brandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(brandDetailProvider(brandId));

    return Scaffold(
      appBar: AppBar(),
      body: detailAsync.when(
        data: (detail) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DiscoveryMedia(
              seed: detail.summary.id,
              label: detail.summary.name,
              kind: DiscoveryMediaKind.brand,
              height: 200,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              detail.summary.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final label in detail.summary.visibilityLabels)
                  StatusPill(
                    label: label.label,
                    tone: switch (label) {
                      VisibilityLabel.common => StatusPillTone.neutral,
                      VisibilityLabel.vip => StatusPillTone.info,
                      VisibilityLabel.bestOfMonth => StatusPillTone.success,
                      VisibilityLabel.sponsored => StatusPillTone.warning,
                    },
                  ),
                StatusPill(
                  label: detail.summary.openNow
                      ? 'Open now'
                      : 'Currently closed',
                  tone: detail.summary.openNow
                      ? StatusPillTone.success
                      : StatusPillTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            RatingRow(
              rating: detail.summary.rating,
              reviewCount: detail.summary.reviewCount,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trust and info',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    detail.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DetailFactRow(
                    icon: Icons.place_outlined,
                    label: 'Address',
                    value: detail.summary.addressLine,
                  ),
                  DetailFactRow(
                    icon: Icons.groups_outlined,
                    label: 'Providers',
                    value: '${detail.summary.memberCount} active members',
                  ),
                  DetailFactRow(
                    icon: Icons.design_services_outlined,
                    label: 'Services',
                    value: '${detail.summary.serviceCount} published services',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Map preview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    detail.mapHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Providers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...detail.members.map(
              (provider) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ProviderCard(
                  provider: provider,
                  width: double.infinity,
                  onTap: () =>
                      context.go(ProviderDetailPage.location(provider.id)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Services', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...detail.services.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ServiceCard(
                  service: service,
                  width: double.infinity,
                  onTap: () =>
                      context.go(ServiceDetailPage.location(service.id)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (detail.reviews.isNotEmpty) ...[
              Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              ...detail.reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ReviewCard(review: review),
                ),
              ),
            ],
            TextButton.icon(
              onPressed: () => showDiscoveryNoticeSheet(
                context,
                title: 'Report brand',
                message:
                    'The lightweight report sheet arrives in a later trust-and-safety pass.',
              ),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Report this brand'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not load brand',
            description: error.toString(),
          ),
        ),
      ),
    );
  }
}
