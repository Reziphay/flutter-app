// reservations_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/network_exception.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../models/reservation.dart';
import '../../state/app_state.dart';
import '../../state/reservation_providers.dart';

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    final dc = context.dc;

    return Scaffold(
      backgroundColor: dc.secondaryBackground,
      body: Column(
        children: [
          // Header
          Container(
            color: dc.background,
            padding: EdgeInsets.only(top: topPadding),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        'Reservations',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: dc.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      _RefreshButton(),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: context.palette.primary,
                  unselectedLabelColor: dc.textSecondary,
                  indicatorColor: context.palette.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                  ],
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ReservationList(filter: (r) => r.status.isActive),
                _ReservationList(filter: (r) => r.status.isFinished),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Refresh button ──────────────────────────────────────────────────────────

class _RefreshButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      myReservationsProvider.select((s) => s.isLoading),
    );
    return isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : GestureDetector(
            onTap: () =>
                ref.read(myReservationsProvider.notifier).refresh(),
            child: Icon(
              Iconsax.refresh,
              size: 22,
              color: context.dc.textSecondary,
            ),
          );
  }
}

// ── Filtered list ───────────────────────────────────────────────────────────

class _ReservationList extends ConsumerWidget {
  const _ReservationList({required this.filter});

  final bool Function(ReservationItem) filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVal = ref.watch(myReservationsProvider);

    return asyncVal.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        final isSessionExpired =
            e is NetworkException && e.statusCode == 401;
        final dc = context.dc;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSessionExpired ? Iconsax.lock : Iconsax.warning_2,
                  size: 48,
                  color: dc.textTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: dc.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (isSessionExpired)
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(appStateProvider.notifier).logout(),
                    icon: const Icon(Iconsax.logout, size: 16),
                    label: const Text('Log in again'),
                  )
                else
                  TextButton(
                    onPressed: () =>
                        ref.read(myReservationsProvider.notifier).refresh(),
                    child: const Text('Try again'),
                  ),
              ],
            ),
          ),
        );
      },
      data: (all) {
        final items = all.where(filter).toList();
        if (items.isEmpty) return _EmptyState(filter: filter);
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(myReservationsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) => _ReservationCard(
              reservation: items[i],
              onTap: () =>
                  context.push('/reservation/${items[i].id}'),
            ),
          ),
        );
      },
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final bool Function(ReservationItem) filter;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.calendar_remove,
                size: 56, color: dc.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No reservations here',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: dc.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse services and book your first appointment',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: dc.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reservation card ────────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.onTap,
  });

  final ReservationItem reservation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = reservation.status;
    final (statusLabel, statusColor) = _statusDisplay(status);
    final dc = context.dc;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: dc.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dc.divider, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service name + status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reservation.service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: dc.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(label: statusLabel, color: statusColor),
                ],
              ),

              if (reservation.brand != null) ...[
                const SizedBox(height: 4),
                Text(
                  reservation.brand!.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.palette.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Date/time row
              Row(
                children: [
                  const Icon(Iconsax.calendar,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(reservation.requestedStartAt),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    reservation.service.priceDisplay,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.palette.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  (String, Color) _statusDisplay(ReservationStatus s) => switch (s) {
        ReservationStatus.pending              => ('Pending', AppColors.warning),
        ReservationStatus.confirmed            => ('Confirmed', AppColors.success),
        ReservationStatus.rejected             => ('Rejected', AppColors.error),
        ReservationStatus.cancelledByCustomer  => ('Cancelled', AppColors.textSecondary),
        ReservationStatus.cancelledByOwner     => ('Cancelled', AppColors.textSecondary),
        ReservationStatus.changeRequestedByCustomer ||
        ReservationStatus.changeRequestedByOwner =>
          ('Change Req.', AppColors.warning),
        ReservationStatus.completed            => ('Completed', AppColors.success),
        ReservationStatus.noShow               => ('No Show', AppColors.error),
        ReservationStatus.expired              => ('Expired', AppColors.textTertiary),
      };
}

// ── Status badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
