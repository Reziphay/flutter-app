import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/section_header.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/provider_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:reziphay_mobile/features/maps/models/map_destination.dart';
import 'package:reziphay_mobile/features/maps/presentation/widgets/map_preview_card.dart';
import 'package:reziphay_mobile/features/qr_completion/presentation/pages/qr_scan_page.dart';
import 'package:reziphay_mobile/features/reports/models/report_models.dart';
import 'package:reziphay_mobile/features/reports/presentation/widgets/report_submission_sheet.dart';
import 'package:reziphay_mobile/features/reviews/data/reviews_repository.dart';
import 'package:reziphay_mobile/features/reviews/models/review_models.dart';
import 'package:reziphay_mobile/features/reviews/presentation/pages/review_create_page.dart';
import 'package:reziphay_mobile/features/reviews/presentation/widgets/review_widgets.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import 'package:reziphay_mobile/features/reservations/presentation/widgets/reservation_widgets.dart';

class CustomerReservationDetailPage extends ConsumerStatefulWidget {
  const CustomerReservationDetailPage({required this.reservationId, super.key});

  static const path = '/customer/reservations/:reservationId';

  static String location(String reservationId) =>
      '/customer/reservations/$reservationId';

  final String reservationId;

  @override
  ConsumerState<CustomerReservationDetailPage> createState() =>
      _CustomerReservationDetailPageState();
}

class _CustomerReservationDetailPageState
    extends ConsumerState<CustomerReservationDetailPage> {
  String? _busyAction;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      customerReservationDetailProvider(widget.reservationId),
    );

    return Scaffold(
      appBar: AppBar(),
      body: detailAsync.when(
        data: (detail) => _buildContent(context, detail),
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

  Widget _buildContent(BuildContext context, ReservationDetail detail) {
    final reviewAsync = ref.watch(
      reservationReviewProvider(widget.reservationId),
    );
    final summary = detail.summary;
    final status = summary.effectiveStatus;
    final latestChange = detail.changeHistory.isEmpty
        ? null
        : detail.changeHistory.first;
    final isProviderChangeAwaitingCustomer =
        status == ReservationStatus.changeRequested &&
        latestChange?.requestedByLabel == 'Provider';
    final canChangeOrCancel = switch (status) {
      ReservationStatus.pendingApproval => true,
      ReservationStatus.confirmed => true,
      ReservationStatus.changeRequested => true,
      ReservationStatus.cancelled => false,
      ReservationStatus.completed => false,
      ReservationStatus.noShow => false,
      ReservationStatus.rejected => false,
      ReservationStatus.expired => false,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        ReservationStatusBanner(summary: summary, onExpire: _refresh),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.serviceName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusPill(
                    label: summary.priceLabel,
                    tone: StatusPillTone.neutral,
                  ),
                ],
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
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Open service',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => context.go(
                        ServiceDetailPage.location(summary.serviceId),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'View provider',
                      variant: AppButtonVariant.ghost,
                      onPressed: () => context.go(
                        ProviderDetailPage.location(summary.providerId),
                      ),
                    ),
                  ),
                ],
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
                'Time and place',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Scheduled time',
                value: summary.scheduledAtLabel,
              ),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: summary.addressLine,
              ),
              _DetailRow(
                icon: Icons.swap_horiz_outlined,
                label: 'Approval mode',
                value: summary.approvalMode.label,
              ),
              if (summary.note != null && summary.note!.trim().isNotEmpty)
                _DetailRow(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Your note',
                  value: summary.note!,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        MapPreviewCard(
          destination: MapDestination(
            title: summary.serviceName,
            subtitle: [
              if (summary.brandName != null) summary.brandName!,
              summary.providerName,
            ].join(' · '),
            addressLine: summary.addressLine,
            note:
                'Open the destination in your maps app if you need walking, driving, or ride-share handoff.',
          ),
        ),
        if (status == ReservationStatus.changeRequested &&
            latestChange != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _PendingChangeCard(
            title: latestChange.requestedByLabel == 'Provider'
                ? 'Provider proposed a new time'
                : 'Waiting on provider response',
            description: latestChange.requestedByLabel == 'Provider'
                ? 'Review the proposed time before accepting it or sending another change request.'
                : 'Your proposed time is waiting for the provider to confirm.',
            currentTimeLabel: summary.scheduledAtLabel,
            proposedTimeLabel: latestChange.proposedTimeLabel,
            statusLabel: latestChange.statusLabel,
          ),
        ],
        if (detail.changeHistory.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Change history'),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: detail.changeHistory
                  .map(
                    (change) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ChangeHistoryTile(change: change),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (detail.cancellationReason != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _ReasonCard(
            title: 'Cancellation reason',
            message: detail.cancellationReason!,
          ),
        ],
        if (detail.rejectionReason != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _ReasonCard(
            title: 'Rejection reason',
            message: detail.rejectionReason!,
          ),
        ],
        if (detail.noShowReason != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _ReasonCard(title: 'No-show record', message: detail.noShowReason!),
        ],
        if (detail.noShowObjection != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _NoShowObjectionCard(objection: detail.noShowObjection!),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Timeline'),
        const SizedBox(height: AppSpacing.md),
        AppCard(child: ReservationTimeline(events: detail.timeline)),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Completion'),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                switch (status) {
                  ReservationStatus.confirmed =>
                    'Completion happens by provider QR or manual confirmation.',
                  ReservationStatus.completed =>
                    detail.completionMethod?.label ?? 'Completed successfully.',
                  ReservationStatus.noShow =>
                    'If this no-show is incorrect, submit an objection with context.',
                  _ =>
                    'Completion actions unlock when the reservation reaches the right state.',
                },
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              if (status == ReservationStatus.confirmed)
                AppButton(
                  label: 'Open QR completion flow',
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      context.go(QrScanPage.location(widget.reservationId)),
                ),
              if (status == ReservationStatus.completed)
                reviewAsync.when(
                  data: (review) {
                    if (review == null) {
                      return AppButton(
                        label: 'Leave review',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => context.go(
                          ReviewCreatePage.location(widget.reservationId),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        AppReviewCard(
                          review: review,
                          onDelete: () => _deleteReview(review),
                        ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => Text(
                    error.toString(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ),
              if (status == ReservationStatus.noShow)
                AppButton(
                  label: detail.noShowObjection == null
                      ? 'Submit objection'
                      : 'Objection submitted',
                  variant: AppButtonVariant.secondary,
                  isLoading: _busyAction == 'objection',
                  onPressed: detail.noShowObjection == null
                      ? () => _submitNoShowObjection(detail)
                      : null,
                ),
            ],
          ),
        ),
        if (canChangeOrCancel || isProviderChangeAwaitingCustomer) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Actions'),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isProviderChangeAwaitingCustomer) ...[
                  AppButton(
                    label: 'Accept proposed time',
                    isLoading: _busyAction == 'accept-change',
                    onPressed: () => _runAction(
                      'accept-change',
                      () => ref
                          .read(reservationsActionsProvider)
                          .acceptCustomerChange(widget.reservationId),
                      successMessage: 'New time accepted.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (canChangeOrCancel) ...[
                  AppButton(
                    label: 'Request change',
                    variant: AppButtonVariant.secondary,
                    isLoading: _busyAction == 'request-change',
                    onPressed: () => _requestChange(detail),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Cancel reservation',
                    variant: AppButtonVariant.destructive,
                    isLoading: _busyAction == 'cancel',
                    onPressed: () => _cancelReservation(detail),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        TextButton.icon(
          onPressed: () => submitReportFlow(
            context,
            ref,
            title: 'Report reservation issue',
            target: ReportTargetSummary(
              type: ReportTargetType.reservation,
              id: detail.summary.id,
              title: detail.summary.serviceName,
              subtitle:
                  '${detail.summary.providerName} · ${detail.summary.scheduledAtLabel}',
            ),
          ),
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Report an issue'),
        ),
      ],
    );
  }

  Future<void> _cancelReservation(ReservationDetail detail) async {
    final reason = await showReservationReasonSheet(
      context,
      title: 'Cancel reservation',
      buttonLabel: 'Confirm cancellation',
      destructive: true,
      reservationLabel: detail.summary.serviceName,
      currentTimeLabel: detail.summary.scheduledAtLabel,
    );

    if (reason == null) {
      return;
    }

    await _runAction(
      'cancel',
      () => ref
          .read(reservationsActionsProvider)
          .cancelCustomerReservation(
            reservationId: widget.reservationId,
            reason: reason,
          ),
      successMessage: 'Reservation cancelled.',
    );
  }

  Future<void> _requestChange(ReservationDetail detail) async {
    final draft = await showReservationChangeSheet(
      context,
      title: 'Request a new time',
      initialTime: detail.summary.scheduledAt,
      reservationLabel: detail.summary.serviceName,
    );

    if (draft == null) {
      return;
    }

    await _runAction(
      'request-change',
      () => ref
          .read(reservationsActionsProvider)
          .requestCustomerChange(
            reservationId: widget.reservationId,
            proposedTime: draft.proposedTime,
            reason: draft.reason,
          ),
      successMessage: 'Change request sent.',
    );
  }

  Future<void> _deleteReview(AppReview review) async {
    final confirmed = await showReviewDeleteConfirmationSheet(
      context,
      review: review,
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(
      'delete-review',
      () => ref.read(reviewsActionsProvider).deleteReview(review),
      successMessage: 'Review deleted.',
    );
  }

  Future<void> _submitNoShowObjection(ReservationDetail detail) async {
    final draft = await showNoShowObjectionSheet(
      context,
      reservationLabel: detail.summary.serviceName,
      scheduledTimeLabel: detail.summary.scheduledAtLabel,
    );

    if (draft == null) {
      return;
    }

    await _runAction(
      'objection',
      () => ref
          .read(reservationsActionsProvider)
          .submitNoShowObjection(
            reservationId: widget.reservationId,
            reason: draft.reason,
            details: draft.details,
          ),
      successMessage: 'No-show objection submitted for review.',
    );
  }

  Future<void> _runAction(
    String action,
    Future<void> Function() task, {
    required String successMessage,
  }) async {
    setState(() => _busyAction = action);

    try {
      await task();
      _refresh();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
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

  void _refresh() {
    ref.invalidate(customerReservationsProvider);
    ref.invalidate(providerReservationsProvider);
    ref.invalidate(providerDashboardProvider);
    ref.invalidate(customerReservationDetailProvider(widget.reservationId));
    ref.invalidate(providerReservationDetailProvider(widget.reservationId));
    ref.invalidate(reservationReviewProvider(widget.reservationId));
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeHistoryTile extends StatelessWidget {
  const _ChangeHistoryTile({required this.change});

  final ReservationChangeEntry change;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                change.proposedTimeLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            StatusPill(
              label: change.statusLabel,
              tone: change.statusLabel.contains('Accepted')
                  ? StatusPillTone.success
                  : StatusPillTone.info,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '${change.requestedByLabel} · ${change.createdAtLabel}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(change.reason, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _PendingChangeCard extends StatelessWidget {
  const _PendingChangeCard({
    required this.title,
    required this.description,
    required this.currentTimeLabel,
    required this.proposedTimeLabel,
    required this.statusLabel,
  });

  final String title;
  final String description;
  final String currentTimeLabel;
  final String proposedTimeLabel;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFEFF3FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusPill(label: statusLabel, tone: StatusPillTone.info),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          _PendingChangeRow(label: 'Current', value: currentTimeLabel),
          const SizedBox(height: AppSpacing.xs),
          _PendingChangeRow(label: 'Proposed', value: proposedTimeLabel),
        ],
      ),
    );
  }
}

class _PendingChangeRow extends StatelessWidget {
  const _PendingChangeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFDECEC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NoShowObjectionCard extends StatelessWidget {
  const _NoShowObjectionCard({required this.objection});

  final NoShowObjection objection;

  @override
  Widget build(BuildContext context) {
    final tone = switch (objection.status) {
      NoShowObjectionStatus.underReview => StatusPillTone.info,
      NoShowObjectionStatus.accepted => StatusPillTone.success,
      NoShowObjectionStatus.rejected => StatusPillTone.error,
    };

    final background = switch (objection.status) {
      NoShowObjectionStatus.underReview => const Color(0xFFEFF3FF),
      NoShowObjectionStatus.accepted => const Color(0xFFEAF8F1),
      NoShowObjectionStatus.rejected => const Color(0xFFFDECEC),
    };

    return AppCard(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Objection status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusPill(label: objection.status.label, tone: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            objection.status.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          _PendingChangeRow(label: 'Reason', value: objection.reason.label),
          const SizedBox(height: AppSpacing.xs),
          _PendingChangeRow(
            label: 'Submitted',
            value: objection.submittedAtLabel,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            objection.details,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (objection.resolutionNote != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              objection.resolutionNote!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
