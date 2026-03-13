import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
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

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(providerReservationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(providerReservationsProvider);
        ref.invalidate(providerDashboardProvider);
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
            'Keep incoming requests, customer change proposals, and today\'s confirmed work visible without turning the screen into a noisy ops console.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
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
          reservationsAsync.when(
            data: (reservations) {
              final filtered = reservations.where(_filter.matches).toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  title: _filter.emptyTitle,
                  description: _filter.emptyDescription,
                );
              }

              return Column(
                children: filtered
                    .map(
                      (reservation) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ReservationCard(
                          summary: reservation,
                          trailingLabel: reservation.customerName,
                          onTap: () => context.go(
                            ProviderReservationDetailPage.location(
                              reservation.id,
                            ),
                          ),
                          onExpire: _refresh,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
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

  void _refresh() {
    ref.invalidate(customerReservationsProvider);
    ref.invalidate(providerReservationsProvider);
    ref.invalidate(providerDashboardProvider);
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
    final today =
        summary.scheduledAt.year == now.year &&
        summary.scheduledAt.month == now.month &&
        summary.scheduledAt.day == now.day;
    final status = summary.effectiveStatus;

    return switch (this) {
      _ProviderReservationFilter.incoming =>
        status == ReservationStatus.pendingApproval ||
            status == ReservationStatus.changeRequested,
      _ProviderReservationFilter.today => today,
      _ProviderReservationFilter.upcoming =>
        status == ReservationStatus.confirmed && !today,
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
