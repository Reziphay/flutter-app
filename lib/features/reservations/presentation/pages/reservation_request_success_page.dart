import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/customer/presentation/pages/customer_home_page.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/customer_reservation_detail_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/customer_reservations_page.dart';

class ReservationRequestSuccessPage extends ConsumerWidget {
  const ReservationRequestSuccessPage({required this.reservationId, super.key});

  static const path = '/customer/reservations/success/:reservationId';

  static String location(String reservationId) =>
      '/customer/reservations/success/$reservationId';

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      customerReservationDetailProvider(reservationId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reservation sent')),
      body: detailAsync.when(
        data: (detail) => _SuccessContent(detail: detail),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not load reservation',
            description: error.toString(),
          ),
        ),
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.detail});

  final ReservationDetail detail;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;
    final isPending =
        summary.effectiveStatus == ReservationStatus.pendingApproval;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Container(
            height: 84,
            width: 84,
            decoration: BoxDecoration(
              color: isPending
                  ? const Color(0xFFFFF5DF)
                  : const Color(0xFFEAF8F1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isPending ? Icons.schedule_outlined : Icons.check_circle_outline,
              size: 40,
              color: isPending ? AppColors.warning : AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isPending
              ? 'Request is waiting for provider response'
              : 'Reservation confirmed',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isPending
              ? 'The provider has 5 minutes to accept, reject, or propose a change.'
              : 'This service is using automatic confirmation, so the reservation is already secured.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.serviceName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                [
                  if (summary.brandName != null) summary.brandName!,
                  summary.providerName,
                ].join(' · '),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusPill(
                    label: summary.effectiveStatus.label,
                    tone: isPending
                        ? StatusPillTone.warning
                        : StatusPillTone.success,
                  ),
                  StatusPill(
                    label: summary.scheduledAtLabel,
                    tone: StatusPillTone.info,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                summary.addressLine,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                summary.priceLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          color: AppColors.surfaceSoft,
          child: Text(
            isPending
                ? 'You can follow the countdown and the provider response inside reservation detail. If nothing happens before the deadline, the request expires automatically.'
                : 'You can manage changes, cancellations, and completion from the reservation detail screen.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Open reservation detail',
          onPressed: () =>
              context.go(CustomerReservationDetailPage.location(summary.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'View all reservations',
          variant: AppButtonVariant.secondary,
          onPressed: () => context.go(CustomerReservationsPage.path),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Back to home',
          variant: AppButtonVariant.ghost,
          onPressed: () => context.go(CustomerHomePage.path),
        ),
      ],
    );
  }
}
