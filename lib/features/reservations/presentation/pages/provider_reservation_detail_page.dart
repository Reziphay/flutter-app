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
import 'package:reziphay_mobile/features/qr_completion/presentation/pages/provider_qr_page.dart';
import 'package:reziphay_mobile/features/reviews/data/reviews_repository.dart';
import 'package:reziphay_mobile/features/reviews/models/review_models.dart';
import 'package:reziphay_mobile/features/reviews/presentation/widgets/review_widgets.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import 'package:reziphay_mobile/features/reservations/presentation/widgets/reservation_widgets.dart';

class ProviderReservationDetailPage extends ConsumerStatefulWidget {
  const ProviderReservationDetailPage({required this.reservationId, super.key});

  static const path = '/provider/reservations/:reservationId';

  static String location(String reservationId) =>
      '/provider/reservations/$reservationId';

  final String reservationId;

  @override
  ConsumerState<ProviderReservationDetailPage> createState() =>
      _ProviderReservationDetailPageState();
}

class _ProviderReservationDetailPageState
    extends ConsumerState<ProviderReservationDetailPage> {
  String? _busyAction;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      providerReservationDetailProvider(widget.reservationId),
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
    final awaitingProvider =
        status == ReservationStatus.changeRequested &&
        latestChange?.requestedByLabel == 'Customer';
    final awaitingCustomer =
        status == ReservationStatus.changeRequested &&
        latestChange?.requestedByLabel == 'Provider';

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
              Text('Customer', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                icon: Icons.person_outline,
                label: 'Name',
                value: summary.customerName,
              ),
              if (summary.note != null && summary.note!.trim().isNotEmpty)
                _DetailRow(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Customer note',
                  value: summary.note!,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                icon: Icons.design_services_outlined,
                label: 'Service',
                value: summary.serviceName,
              ),
              if (summary.brandName != null)
                _DetailRow(
                  icon: Icons.storefront_outlined,
                  label: 'Brand',
                  value: summary.brandName!,
                ),
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
                icon: Icons.sell_outlined,
                label: 'Price',
                value: summary.priceLabel,
              ),
            ],
          ),
        ),
        if (status == ReservationStatus.changeRequested &&
            latestChange != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _PendingChangeCard(
            title: latestChange.requestedByLabel == 'Customer'
                ? 'Customer requested a new time'
                : 'Waiting for customer response',
            description: latestChange.requestedByLabel == 'Customer'
                ? 'Compare the current slot with the proposed time before accepting or countering it.'
                : 'Your proposed time is now waiting on the customer.',
            currentTimeLabel: summary.scheduledAtLabel,
            proposedTimeLabel: latestChange.proposedTimeLabel,
            statusLabel: latestChange.statusLabel,
          ),
        ],
        if (detail.changeHistory.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Change requests'),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: detail.changeHistory
                  .map(
                    (change) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ChangeTile(change: change),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Timeline'),
        const SizedBox(height: AppSpacing.md),
        AppCard(child: ReservationTimeline(events: detail.timeline)),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'QR and completion'),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status == ReservationStatus.completed
                    ? detail.completionMethod?.label ?? 'Completed'
                    : 'Display the signed provider QR for on-site completion, or fall back to manual completion if scanning fails.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Open provider QR',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go(ProviderQrPage.path),
              ),
            ],
          ),
        ),
        if (status == ReservationStatus.completed) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Customer review'),
          const SizedBox(height: AppSpacing.md),
          reviewAsync.when(
            data: (review) {
              if (review == null) {
                return AppCard(
                  child: Text(
                    'The customer has not left a review yet. Replies unlock automatically after a review is posted.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }

              return AppReviewCard(
                review: review,
                onReply: review.reply == null
                    ? () => _replyToReview(review)
                    : null,
                onReport: () => _reportReview(review),
              );
            },
            loading: () => const AppCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stackTrace) => AppCard(
              child: Text(
                error.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
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
          _ReasonCard(title: 'No-show note', message: detail.noShowReason!),
        ],
        if (_showActions(status, awaitingProvider, awaitingCustomer)) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Actions'),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (status == ReservationStatus.pendingApproval) ...[
                  AppButton(
                    label: 'Accept request',
                    isLoading: _busyAction == 'accept',
                    onPressed: () => _runAction(
                      'accept',
                      () => ref
                          .read(reservationsActionsProvider)
                          .acceptProviderReservation(widget.reservationId),
                      successMessage: 'Reservation confirmed.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Propose another time',
                    variant: AppButtonVariant.secondary,
                    isLoading: _busyAction == 'request-change',
                    onPressed: () => _requestChange(detail),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Reject request',
                    variant: AppButtonVariant.destructive,
                    isLoading: _busyAction == 'reject',
                    onPressed: _rejectReservation,
                  ),
                ],
                if (awaitingProvider) ...[
                  AppButton(
                    label: 'Accept proposed time',
                    isLoading: _busyAction == 'accept',
                    onPressed: () => _runAction(
                      'accept',
                      () => ref
                          .read(reservationsActionsProvider)
                          .acceptProviderReservation(widget.reservationId),
                      successMessage: 'Customer change accepted.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Propose another time',
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
                if (status == ReservationStatus.confirmed) ...[
                  AppButton(
                    label: 'Complete manually',
                    isLoading: _busyAction == 'complete',
                    onPressed: () => _runAction(
                      'complete',
                      () => ref
                          .read(reservationsActionsProvider)
                          .completeProviderReservation(widget.reservationId),
                      successMessage: 'Reservation completed.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                if (awaitingCustomer)
                  Text(
                    'The provider already proposed a new time. Waiting for the customer to respond, but cancellation is still available if needed.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                if (awaitingCustomer) ...[
                  const SizedBox(height: AppSpacing.md),
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
      ],
    );
  }

  bool _showActions(
    ReservationStatus status,
    bool awaitingProvider,
    bool awaitingCustomer,
  ) {
    return status == ReservationStatus.pendingApproval ||
        status == ReservationStatus.confirmed ||
        awaitingProvider ||
        awaitingCustomer;
  }

  Future<void> _requestChange(ReservationDetail detail) async {
    final draft = await showReservationChangeSheet(
      context,
      title: 'Propose a new time',
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
          .requestProviderChange(
            reservationId: widget.reservationId,
            proposedTime: draft.proposedTime,
            reason: draft.reason,
          ),
      successMessage: 'Change request sent to customer.',
    );
  }

  Future<void> _rejectReservation() async {
    final reason = await showReservationReasonSheet(
      context,
      title: 'Reject reservation',
      buttonLabel: 'Reject request',
      destructive: true,
    );

    if (reason == null) {
      return;
    }

    await _runAction(
      'reject',
      () => ref
          .read(reservationsActionsProvider)
          .rejectProviderReservation(
            reservationId: widget.reservationId,
            reason: reason,
          ),
      successMessage: 'Reservation rejected.',
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
          .cancelProviderReservation(
            reservationId: widget.reservationId,
            reason: reason,
          ),
      successMessage: 'Reservation cancelled.',
    );
  }

  Future<void> _replyToReview(AppReview review) async {
    final reply = await showReviewTextSheet(
      context,
      title: 'Reply to review',
      labelText: 'Reply',
      hintText: 'Write a short public reply for this completed reservation.',
      buttonLabel: 'Publish reply',
    );

    if (reply == null) {
      return;
    }

    await _runAction(
      'reply-review',
      () => ref
          .read(reviewsActionsProvider)
          .replyToReview(review: review, message: reply),
      successMessage: 'Reply published.',
    );
  }

  Future<void> _reportReview(AppReview review) async {
    final reason = await showReviewTextSheet(
      context,
      title: 'Report review',
      labelText: 'Reason',
      hintText: 'Explain why this review needs moderation.',
      buttonLabel: 'Submit report',
    );

    if (reason == null) {
      return;
    }

    await _runAction(
      'report-review',
      () => ref
          .read(reviewsActionsProvider)
          .reportReview(review: review, reason: reason),
      successMessage: 'Review reported.',
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

class _ChangeTile extends StatelessWidget {
  const _ChangeTile({required this.change});

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
