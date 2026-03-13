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
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/provider_reservation_detail_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/widgets/reservation_widgets.dart';

class ProviderReservationsPage extends ConsumerStatefulWidget {
  const ProviderReservationsPage({super.key});

  static const path = '/provider/reservations';

  @override
  ConsumerState<ProviderReservationsPage> createState() =>
      _ProviderReservationsPageState();
}

class _ProviderReservationsPageState
    extends ConsumerState<ProviderReservationsPage> {
  var _filter = _ProviderReservationFilter.incoming;
  String? _busyAction;

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(providerReservationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await ref.read(providerReservationsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          Text(
            'Provider reservations',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Treat this as the provider\'s active queue: incoming approvals, customer change proposals, today\'s work, and closed outcomes should stay obvious at a glance.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          reservationsAsync.when(
            data: (reservations) => _buildBody(context, reservations),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => EmptyState(
              title: 'Could not load provider reservations',
              description: error.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<ReservationSummary> reservations,
  ) {
    final incoming = [
      ...reservations.where(
        (reservation) => reservation.isAwaitingProviderAction,
      ),
    ]..sort(_compareIncomingReservations);
    final expiringSoonCount = reservations
        .where((reservation) => reservation.isPendingManualApproval)
        .where((reservation) => reservation.isUrgentPendingWindow)
        .length;
    final todayCount = reservations
        .where((reservation) => reservation.isActiveToday)
        .length;
    final closedCount = reservations.where(_isClosedReservation).length;
    final filtered = [...reservations.where(_filter.matches)];

    if (_filter == _ProviderReservationFilter.completed ||
        _filter == _ProviderReservationFilter.closed) {
      filtered.sort(
        (left, right) => right.scheduledAt.compareTo(left.scheduledAt),
      );
    } else {
      filtered.sort(
        (left, right) => left.scheduledAt.compareTo(right.scheduledAt),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _ReservationOpsStatCard(
              label: 'Incoming',
              value: incoming.length,
              helper: 'Need provider action',
              tone: StatusPillTone.info,
              icon: Icons.inbox_outlined,
              backgroundColor: const Color(0xFFEFF3FF),
            ),
            _ReservationOpsStatCard(
              label: 'Expiring soon',
              value: expiringSoonCount,
              helper: 'Under 2 minutes left',
              tone: StatusPillTone.warning,
              icon: Icons.timer_outlined,
              backgroundColor: const Color(0xFFFFF5DF),
            ),
            _ReservationOpsStatCard(
              label: 'Today',
              value: todayCount,
              helper: 'Non-terminal reservations',
              tone: StatusPillTone.success,
              icon: Icons.today_outlined,
              backgroundColor: const Color(0xFFEAF8F1),
            ),
            _ReservationOpsStatCard(
              label: 'Closed',
              value: closedCount,
              helper: 'Cancelled, rejected, expired',
              tone: StatusPillTone.neutral,
              icon: Icons.archive_outlined,
              backgroundColor: AppColors.surfaceSoft,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _ProviderReservationFilter.values
                .map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_filter == _ProviderReservationFilter.incoming)
          _buildIncomingQueue(context, incoming)
        else if (filtered.isEmpty)
          EmptyState(
            title: _filter.emptyTitle,
            description: _filter.emptyDescription,
          )
        else
          Column(
            children: filtered
                .map(
                  (reservation) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ReservationCard(
                      summary: reservation,
                      trailingLabel: reservation.customerName,
                      onTap: () => context.go(
                        ProviderReservationDetailPage.location(reservation.id),
                      ),
                      onExpire: _refresh,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildIncomingQueue(
    BuildContext context,
    List<ReservationSummary> incoming,
  ) {
    if (incoming.isEmpty) {
      return const EmptyState(
        title: 'No incoming actions',
        description:
            'New approval requests and customer change proposals will appear here.',
      );
    }

    final manualApprovals = incoming
        .where((reservation) => reservation.isPendingManualApproval)
        .toList();
    final customerChanges = incoming
        .where((reservation) => reservation.isCustomerChangeRequest)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (manualApprovals.isNotEmpty) ...[
          SectionHeader(title: 'Manual approvals (${manualApprovals.length})'),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'These requests can expire. Keep the countdown visible and resolve the urgent ones first.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          ...manualApprovals.map(
            (reservation) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _IncomingReservationCard(
                summary: reservation,
                onExpire: _refresh,
                isPrimaryLoading: _isBusy('accept', reservation.id),
                primaryLabel: 'Accept request',
                onPrimaryPressed: () => _acceptReservation(reservation),
                isSecondaryLoading: _isBusy('reject', reservation.id),
                secondaryLabel: 'Reject request',
                onSecondaryPressed: () => _rejectReservation(reservation),
                tertiaryLabel: 'View details',
                onTertiaryPressed: () => context.go(
                  ProviderReservationDetailPage.location(reservation.id),
                ),
              ),
            ),
          ),
        ],
        if (manualApprovals.isNotEmpty && customerChanges.isNotEmpty)
          const SizedBox(height: AppSpacing.lg),
        if (customerChanges.isNotEmpty) ...[
          SectionHeader(
            title: 'Customer change requests (${customerChanges.length})',
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Each card compares the current reservation time against the proposed slot so the provider can accept it or keep the original booking.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          ...customerChanges.map(
            (reservation) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _IncomingReservationCard(
                summary: reservation,
                onExpire: _refresh,
                isPrimaryLoading: _isBusy('accept', reservation.id),
                primaryLabel: 'Accept proposed time',
                onPrimaryPressed: () => _acceptReservation(reservation),
                isSecondaryLoading: _isBusy('keep-original', reservation.id),
                secondaryLabel: 'Keep original time',
                onSecondaryPressed: () => _keepOriginalTime(reservation),
                tertiaryLabel: 'View details',
                onTertiaryPressed: () => context.go(
                  ProviderReservationDetailPage.location(reservation.id),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _acceptReservation(ReservationSummary reservation) async {
    await _runAction(
      'accept',
      reservation.id,
      () => ref
          .read(reservationsActionsProvider)
          .acceptProviderReservation(reservation.id),
      successMessage: reservation.isCustomerChangeRequest
          ? 'Customer change accepted.'
          : 'Reservation confirmed.',
    );
  }

  Future<void> _rejectReservation(ReservationSummary reservation) async {
    final reason = await showReservationReasonSheet(
      context,
      title: 'Reject reservation',
      buttonLabel: 'Reject request',
      destructive: true,
      reservationLabel: reservation.serviceName,
      currentTimeLabel: reservation.scheduledAtLabel,
    );

    if (reason == null) {
      return;
    }

    await _runAction(
      'reject',
      reservation.id,
      () => ref
          .read(reservationsActionsProvider)
          .rejectProviderReservation(
            reservationId: reservation.id,
            reason: reason,
          ),
      successMessage: 'Reservation rejected.',
    );
  }

  Future<void> _keepOriginalTime(ReservationSummary reservation) async {
    final reason = await showReservationReasonSheet(
      context,
      title: 'Keep original time',
      buttonLabel: 'Keep original time',
      destructive: false,
      reservationLabel: reservation.serviceName,
      currentTimeLabel: reservation.scheduledAtLabel,
    );

    if (reason == null) {
      return;
    }

    await _runAction(
      'keep-original',
      reservation.id,
      () => ref
          .read(reservationsActionsProvider)
          .declineCustomerChange(reservationId: reservation.id, reason: reason),
      successMessage: 'Original time kept.',
    );
  }

  Future<void> _runAction(
    String action,
    String reservationId,
    Future<void> Function() task, {
    required String successMessage,
  }) async {
    setState(() => _busyAction = '$action:$reservationId');

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

  bool _isBusy(String action, String reservationId) {
    return _busyAction == '$action:$reservationId';
  }

  void _refresh() {
    ref.invalidate(customerReservationsProvider);
    ref.invalidate(providerReservationsProvider);
    ref.invalidate(providerDashboardProvider);
  }

  int _compareIncomingReservations(
    ReservationSummary left,
    ReservationSummary right,
  ) {
    final leftPriority = left.isPendingManualApproval ? 0 : 1;
    final rightPriority = right.isPendingManualApproval ? 0 : 1;

    if (leftPriority != rightPriority) {
      return leftPriority.compareTo(rightPriority);
    }

    if (left.isPendingManualApproval &&
        right.isPendingManualApproval &&
        left.responseDeadline != null &&
        right.responseDeadline != null) {
      return left.responseDeadline!.compareTo(right.responseDeadline!);
    }

    return left.scheduledAt.compareTo(right.scheduledAt);
  }

  bool _isClosedReservation(ReservationSummary reservation) {
    final status = reservation.effectiveStatus;
    return status == ReservationStatus.cancelled ||
        status == ReservationStatus.noShow ||
        status == ReservationStatus.rejected ||
        status == ReservationStatus.expired;
  }
}

enum _ProviderReservationFilter { incoming, today, upcoming, completed, closed }

extension on _ProviderReservationFilter {
  String get label => switch (this) {
    _ProviderReservationFilter.incoming => 'Incoming',
    _ProviderReservationFilter.today => 'Today',
    _ProviderReservationFilter.upcoming => 'Upcoming',
    _ProviderReservationFilter.completed => 'Completed',
    _ProviderReservationFilter.closed => 'Cancelled / No-show',
  };

  String get emptyTitle => switch (this) {
    _ProviderReservationFilter.incoming => 'No incoming actions',
    _ProviderReservationFilter.today => 'No reservations today',
    _ProviderReservationFilter.upcoming => 'No upcoming reservations',
    _ProviderReservationFilter.completed => 'No completed reservations',
    _ProviderReservationFilter.closed => 'No closed reservations',
  };

  String get emptyDescription => switch (this) {
    _ProviderReservationFilter.incoming =>
      'New approval requests and customer change proposals will appear here.',
    _ProviderReservationFilter.today =>
      'Today\'s working list will appear here once reservations are scheduled.',
    _ProviderReservationFilter.upcoming =>
      'Confirmed future reservations appear here after they are accepted.',
    _ProviderReservationFilter.completed =>
      'Manual and QR-completed reservations appear here.',
    _ProviderReservationFilter.closed =>
      'Cancelled, rejected, expired, and no-show outcomes appear here.',
  };

  bool matches(ReservationSummary summary) {
    final now = DateTime.now();
    final status = summary.effectiveStatus;

    return switch (this) {
      _ProviderReservationFilter.incoming => summary.isAwaitingProviderAction,
      _ProviderReservationFilter.today => summary.isActiveToday,
      _ProviderReservationFilter.upcoming =>
        status == ReservationStatus.confirmed &&
            summary.scheduledAt.isAfter(now) &&
            !summary.isActiveToday,
      _ProviderReservationFilter.completed =>
        status == ReservationStatus.completed,
      _ProviderReservationFilter.closed =>
        status == ReservationStatus.cancelled ||
            status == ReservationStatus.noShow ||
            status == ReservationStatus.rejected ||
            status == ReservationStatus.expired,
    };
  }
}

class _ReservationOpsStatCard extends StatelessWidget {
  const _ReservationOpsStatCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.tone,
    required this.icon,
    required this.backgroundColor,
  });

  final String label;
  final int value;
  final String helper;
  final StatusPillTone tone;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: AppCard(
        color: backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusPill(label: label, tone: tone, icon: icon),
            const SizedBox(height: AppSpacing.md),
            Text(
              value.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              helper,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingReservationCard extends StatelessWidget {
  const _IncomingReservationCard({
    required this.summary,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.isPrimaryLoading,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    required this.isSecondaryLoading,
    required this.tertiaryLabel,
    required this.onTertiaryPressed,
    this.onExpire,
  });

  final ReservationSummary summary;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final bool isPrimaryLoading;
  final String secondaryLabel;
  final VoidCallback onSecondaryPressed;
  final bool isSecondaryLoading;
  final String tertiaryLabel;
  final VoidCallback onTertiaryPressed;
  final VoidCallback? onExpire;

  @override
  Widget build(BuildContext context) {
    final queueLabel = summary.isPendingManualApproval
        ? 'Manual approval'
        : 'Customer requested change';
    final queueTone = summary.isPendingManualApproval
        ? StatusPillTone.warning
        : StatusPillTone.info;
    final backgroundColor = summary.isPendingManualApproval
        ? summary.isUrgentPendingWindow
              ? const Color(0xFFFFF1D7)
              : const Color(0xFFFFF8EA)
        : const Color(0xFFEFF3FF);

    return AppCard(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.serviceName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      summary.customerName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(label: queueLabel, tone: queueTone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (summary.isPendingManualApproval &&
              summary.responseDeadline != null) ...[
            CountdownPill(
              deadline: summary.responseDeadline!,
              onExpire: onExpire,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Respond before the manual approval window closes.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            summary.scheduledAtLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${summary.addressLine} · ${summary.priceLabel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (summary.isCustomerChangeRequest &&
              summary.latestChangeProposedTimeLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            _QueueInfoRow(label: 'Current', value: summary.scheduledAtLabel),
            const SizedBox(height: AppSpacing.xs),
            _QueueInfoRow(
              label: 'Proposed',
              value: summary.latestChangeProposedTimeLabel!,
            ),
          ],
          if (summary.note != null && summary.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Customer note',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              summary.note!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: primaryLabel,
                expand: false,
                isLoading: isPrimaryLoading,
                onPressed: onPrimaryPressed,
              ),
              AppButton(
                label: secondaryLabel,
                variant: summary.isPendingManualApproval
                    ? AppButtonVariant.destructive
                    : AppButtonVariant.secondary,
                expand: false,
                isLoading: isSecondaryLoading,
                onPressed: onSecondaryPressed,
              ),
              AppButton(
                label: tertiaryLabel,
                variant: AppButtonVariant.ghost,
                expand: false,
                onPressed: onTertiaryPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueInfoRow extends StatelessWidget {
  const _QueueInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
