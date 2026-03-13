import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/brand_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/provider_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_cards.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_media.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_notice_sheet.dart';
import 'package:reziphay_mobile/features/reviews/data/reviews_repository.dart';
import 'package:reziphay_mobile/features/reviews/models/review_models.dart';
import 'package:reziphay_mobile/features/reviews/presentation/widgets/review_widgets.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/reservation_request_page.dart';

class ServiceDetailPage extends ConsumerWidget {
  const ServiceDetailPage({required this.serviceId, super.key});

  static const path = '/customer/service/:serviceId';

  static String location(String serviceId) => '/customer/service/$serviceId';

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(serviceDetailProvider(serviceId));

    return Scaffold(
      appBar: AppBar(),
      body: detailAsync.when(
        data: (detail) {
          final dynamicReviewsAsync = ref.watch(
            entityReviewsProvider(
              ReviewEntityKey(
                type: ReviewTargetType.service,
                entityId: detail.summary.id,
              ),
            ),
          );

          return _ServiceDetailContent(
            detail: detail,
            dynamicReviewsAsync: dynamicReviewsAsync,
            onReport: (review) => _reportReview(context, ref, review),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not load service',
            description: error.toString(),
          ),
        ),
      ),
    );
  }
}

class _ServiceDetailContent extends StatelessWidget {
  const _ServiceDetailContent({
    required this.detail,
    required this.dynamicReviewsAsync,
    required this.onReport,
  });

  final ServiceDetail detail;
  final AsyncValue<List<AppReview>> dynamicReviewsAsync;
  final ValueChanged<AppReview> onReport;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: AppButton(
            label: detail.summary.approvalMode.ctaLabel,
            onPressed: () =>
                context.go(ReservationRequestPage.location(detail.summary.id)),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          SizedBox(
            height: 240,
            child: PageView.builder(
              itemCount: detail.galleryLabels.length,
              itemBuilder: (context, index) {
                final label = detail.galleryLabels[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == detail.galleryLabels.length - 1
                        ? 0
                        : AppSpacing.sm,
                  ),
                  child: DiscoveryMedia(
                    seed: '${detail.summary.id}-$index',
                    label: label,
                    kind: DiscoveryMediaKind.service,
                  ),
                );
              },
            ),
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
                label: detail.summary.approvalMode.label,
                tone: detail.summary.approvalMode == ApprovalMode.manual
                    ? StatusPillTone.warning
                    : StatusPillTone.success,
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
                DetailFactRow(
                  icon: Icons.storefront_outlined,
                  label: 'Brand',
                  value: detail.summary.brandName ?? 'Self branded',
                ),
                DetailFactRow(
                  icon: Icons.person_outline,
                  label: 'Provider',
                  value: detail.summary.providerName,
                ),
                DetailFactRow(
                  icon: Icons.grid_view_outlined,
                  label: 'Category',
                  value: detail.summary.categoryName,
                ),
                DetailFactRow(
                  icon: Icons.place_outlined,
                  label: 'Address',
                  value: detail.summary.addressLine,
                ),
                DetailFactRow(
                  icon: Icons.sell_outlined,
                  label: 'Price',
                  value: detail.summary.priceLabel,
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
                  'Availability',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  detail.availabilitySummary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: detail.requestableSlots
                      .map(
                        (slot) => StatusPill(
                          label: slot.note == null
                              ? slot.label
                              : '${slot.label} · ${slot.note}',
                          tone: slot.available
                              ? StatusPillTone.info
                              : StatusPillTone.neutral,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  detail.about,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                DetailFactRow(
                  icon: Icons.timer_outlined,
                  label: 'Waiting time',
                  value: detail.waitingTimeLabel,
                ),
                DetailFactRow(
                  icon: Icons.event_busy_outlined,
                  label: 'Cancellation',
                  value: detail.freeCancellationLabel,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            onTap: () =>
                context.go(ProviderDetailPage.location(detail.provider.id)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  detail.provider.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  detail.provider.headline,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  detail.provider.responseReliability,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (detail.brand != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              onTap: () =>
                  context.go(BrandDetailPage.location(detail.brand!.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Brand', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    detail.brand!.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    detail.brand!.headline,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          EntityReviewsSection(
            staticReviews: detail.reviews,
            dynamicReviewsAsync: dynamicReviewsAsync,
            onReport: onReport,
          ),
          TextButton.icon(
            onPressed: () => showDiscoveryNoticeSheet(
              context,
              title: 'Report flow',
              message:
                  'Reporting for services, brands, providers, and reviews lands in a later trust-and-safety pass.',
            ),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Report this service'),
          ),
        ],
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
    hintText: 'Explain why this comment should be reviewed.',
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
