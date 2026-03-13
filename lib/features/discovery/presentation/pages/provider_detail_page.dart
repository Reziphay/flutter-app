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
import 'package:reziphay_mobile/features/discovery/presentation/pages/brand_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_cards.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_media.dart';
import 'package:reziphay_mobile/features/reports/models/report_models.dart';
import 'package:reziphay_mobile/features/reports/presentation/widgets/report_submission_sheet.dart';
import 'package:reziphay_mobile/features/reviews/data/reviews_repository.dart';
import 'package:reziphay_mobile/features/reviews/models/review_models.dart';
import 'package:reziphay_mobile/features/reviews/presentation/widgets/review_widgets.dart';

class ProviderDetailPage extends ConsumerWidget {
  const ProviderDetailPage({required this.providerId, super.key});

  static const path = '/customer/provider/:providerId';

  static String location(String providerId) => '/customer/provider/$providerId';

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(providerDetailProvider(providerId));

    return Scaffold(
      appBar: AppBar(),
      body: detailAsync.when(
        data: (detail) {
          final dynamicReviewsAsync = ref.watch(
            entityReviewsProvider(
              ReviewEntityKey(
                type: ReviewTargetType.provider,
                entityId: detail.summary.id,
              ),
            ),
          );

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const DiscoveryMedia(
                seed: 'provider-detail',
                label: 'Provider',
                kind: DiscoveryMediaKind.provider,
                height: 180,
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
                  StatusPill(
                    label: detail.summary.availableNow
                        ? 'Available now'
                        : 'Next availability later',
                    tone: detail.summary.availableNow
                        ? StatusPillTone.success
                        : StatusPillTone.neutral,
                  ),
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
                      'Trust and stats',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      detail.summary.bio,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DetailFactRow(
                      icon: Icons.check_circle_outline,
                      label: 'Completed reservations',
                      value: detail.summary.completedReservations.toString(),
                    ),
                    DetailFactRow(
                      icon: Icons.timer_outlined,
                      label: 'Response reliability',
                      value: detail.summary.responseReliability,
                    ),
                    DetailFactRow(
                      icon: Icons.near_me_outlined,
                      label: 'Distance',
                      value:
                          '${detail.summary.distanceKm.toStringAsFixed(1)} km away',
                    ),
                  ],
                ),
              ),
              if (detail.associatedBrands.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Associated brands',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                ...detail.associatedBrands.map(
                  (brand) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: BrandCard(
                      brand: brand,
                      width: double.infinity,
                      onTap: () =>
                          context.go(BrandDetailPage.location(brand.id)),
                    ),
                  ),
                ),
              ],
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
              EntityReviewsSection(
                staticReviews: detail.reviews,
                dynamicReviewsAsync: dynamicReviewsAsync,
                onReport: (review) => _reportReview(context, ref, review),
              ),
              TextButton.icon(
                onPressed: () => submitReportFlow(
                  context,
                  ref,
                  title: 'Report provider',
                  target: ReportTargetSummary(
                    type: ReportTargetType.provider,
                    id: detail.summary.id,
                    title: detail.summary.name,
                    subtitle: detail.summary.headline,
                  ),
                ),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report this provider'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not load provider',
            description: error.toString(),
          ),
        ),
      ),
    );
  }
}

Future<void> _reportReview(
  BuildContext context,
  WidgetRef ref,
  AppReview review,
) async {
  final reason = await showReviewTextSheet(
    context,
    title: 'Report review',
    labelText: 'Reason',
    hintText: 'Explain why this review should be reviewed.',
    buttonLabel: 'Submit report',
  );

  if (reason == null) {
    return;
  }

  try {
    await ref
        .read(reviewsActionsProvider)
        .reportReview(review: review, reason: reason);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Review reported.')));
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}
