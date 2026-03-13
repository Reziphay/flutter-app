import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/customer_reservation_detail_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/widgets/reservation_widgets.dart';

class CustomerReservationsPage extends ConsumerStatefulWidget {
  const CustomerReservationsPage({super.key});

  static const path = '/customer/reservations';

  @override
  ConsumerState<CustomerReservationsPage> createState() =>
      _CustomerReservationsPageState();
}

class _CustomerReservationsPageState
    extends ConsumerState<CustomerReservationsPage> {
  var _filter = _CustomerReservationFilter.pending;

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(customerReservationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(customerReservationsProvider);
        await ref.read(customerReservationsProvider.future);
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
            'Reservations',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Track provider responses, upcoming visits, completion, and the full change history in one place.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _CustomerReservationFilter.values
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
              final filtered = reservations.where((reservation) {
                return _filter.matches(reservation);
              }).toList();

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
                          onTap: () => context.go(
                            CustomerReservationDetailPage.location(
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
              title: 'Could not load reservations',
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

enum _CustomerReservationFilter {
  pending,
  upcoming,
  completed,
  cancelled,
  noShow,
}

extension on _CustomerReservationFilter {
  String get label => switch (this) {
    _CustomerReservationFilter.pending => 'Pending',
    _CustomerReservationFilter.upcoming => 'Upcoming',
    _CustomerReservationFilter.completed => 'Completed',
    _CustomerReservationFilter.cancelled => 'Cancelled',
    _CustomerReservationFilter.noShow => 'No-show',
  };

  String get emptyTitle => switch (this) {
    _CustomerReservationFilter.pending => 'No pending reservations',
    _CustomerReservationFilter.upcoming => 'No upcoming reservations',
    _CustomerReservationFilter.completed => 'No completed reservations',
    _CustomerReservationFilter.cancelled => 'No cancelled reservations',
    _CustomerReservationFilter.noShow => 'No no-show records',
  };

  String get emptyDescription => switch (this) {
    _CustomerReservationFilter.pending =>
      'New requests and change negotiations will appear here.',
    _CustomerReservationFilter.upcoming =>
      'Confirmed upcoming reservations will appear here.',
    _CustomerReservationFilter.completed =>
      'Completed visits unlock review actions here.',
    _CustomerReservationFilter.cancelled =>
      'Cancelled, rejected, and expired reservations will appear here.',
    _CustomerReservationFilter.noShow =>
      'No-show outcomes and objection entry points will appear here.',
  };

  bool matches(ReservationSummary summary) {
    final status = summary.effectiveStatus;

    return switch (this) {
      _CustomerReservationFilter.pending =>
        status == ReservationStatus.pendingApproval ||
            status == ReservationStatus.changeRequested,
      _CustomerReservationFilter.upcoming =>
        status == ReservationStatus.confirmed,
      _CustomerReservationFilter.completed =>
        status == ReservationStatus.completed,
      _CustomerReservationFilter.cancelled =>
        status == ReservationStatus.cancelled ||
            status == ReservationStatus.rejected ||
            status == ReservationStatus.expired,
      _CustomerReservationFilter.noShow => status == ReservationStatus.noShow,
    };
  }
}
