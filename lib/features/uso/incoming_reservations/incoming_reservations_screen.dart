// incoming_reservations_screen.dart
// Reziphay — USO: incoming bookings list
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../models/reservation.dart';
import '../../../services/reservation_service.dart';
import '../../../state/app_state.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final _incomingProvider = AsyncNotifierProvider<_IncomingNotifier, List<ReservationItem>>(
  _IncomingNotifier.new,
);

class _IncomingNotifier extends AsyncNotifier<List<ReservationItem>> {
  @override
  Future<List<ReservationItem>> build() async {
    final authStatus = ref.watch(appStateProvider.select((s) => s.authStatus));
    if (authStatus != AuthStatus.authenticated) return [];
    return ReservationService.instance.fetchIncomingReservations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ReservationService.instance.fetchIncomingReservations(),
    );
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────

class IncomingReservationsScreen extends ConsumerStatefulWidget {
  const IncomingReservationsScreen({super.key});

  @override
  ConsumerState<IncomingReservationsScreen> createState() =>
      _IncomingReservationsScreenState();
}

class _IncomingReservationsScreenState
    extends ConsumerState<IncomingReservationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.primary;

    return Scaffold(
      backgroundColor: context.dc.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(primary: primary, tabs: _tabs),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _IncomingList(pending: true),
                  _IncomingList(pending: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({required this.primary, required this.tabs});

  final Color primary;
  final TabController tabs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      _incomingProvider.select((s) => s.isLoading),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incoming',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    Text(
                      'Manage your bookings',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.dc.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      )
                    : Icon(Iconsax.refresh, color: primary),
                onPressed: isLoading
                    ? null
                    : () => ref.read(_incomingProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: tabs,
          labelColor: primary,
          unselectedLabelColor: context.dc.textSecondary,
          indicatorColor: primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: context.dc.divider,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
          ],
        ),
      ],
    );
  }
}

// ── Tab list ───────────────────────────────────────────────────────────────

class _IncomingList extends ConsumerWidget {
  const _IncomingList({required this.pending});

  final bool pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_incomingProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        final dc = context.dc;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.warning_2, size: 48, color: dc.textTertiary),
              const SizedBox(height: 12),
              Text('Something went wrong', style: TextStyle(color: dc.textPrimary)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(_incomingProvider.notifier).refresh(),
                child: const Text('Try again'),
              ),
            ],
          ),
        );
      },
      data: (items) {
        final dc = context.dc;
        final filtered = pending
            ? items.where((r) => r.status == ReservationStatus.pending).toList()
            : items.where((r) => r.status == ReservationStatus.confirmed).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  pending ? Iconsax.clock : Iconsax.calendar_tick,
                  size: 56,
                  color: dc.textTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  pending ? 'No pending requests' : 'No confirmed bookings',
                  style: TextStyle(color: dc.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: context.palette.primary,
          onRefresh: () => ref.read(_incomingProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _IncomingCard(
              reservation: filtered[i],
              onUpdated: () => ref.read(_incomingProvider.notifier).refresh(),
            ),
          ),
        );
      },
    );
  }
}

// ── Card ───────────────────────────────────────────────────────────────────

class _IncomingCard extends ConsumerWidget {
  const _IncomingCard({required this.reservation, required this.onUpdated});

  final ReservationItem reservation;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = context.palette.primary;
    final dc      = context.dc;
    final r = reservation;
    final isPending = r.status == ReservationStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: dc.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dc.divider, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/reservation/${r.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: service name + status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.service.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: dc.textPrimary,
                      ),
                    ),
                  ),
                  _StatusBadge(status: r.status),
                ],
              ),
              const SizedBox(height: 8),
              // Customer
              Row(
                children: [
                  Icon(Iconsax.user, size: 14, color: dc.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    r.customer.fullName,
                    style: TextStyle(
                      fontSize: 13,
                      color: dc.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Date/time
              Row(
                children: [
                  Icon(Iconsax.calendar, size: 14, color: dc.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                  _formatDateTime(r.requestedStartAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: dc.textSecondary,
                    ),
                  ),
                ],
              ),
              // Price
              if (r.service.priceAmount != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.money, size: 14, color: dc.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      r.service.priceDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        color: dc.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              // Action buttons for PENDING
              if (isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => _showRejectDialog(context, ref),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          elevation: 0,
                        ),
                        onPressed: () => _accept(context, ref),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      await ReservationService.instance.acceptReservation(reservation.id);
      onUpdated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation accepted ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Reservation'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Reason (optional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ReservationService.instance
            .rejectReservation(reservation.id, reasonController.text.trim());
        onUpdated();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservation rejected')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
    reasonController.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour   = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $hour:$minute';
  }
}

// ── Status Badge ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ReservationStatus.pending   => ('Pending',   const Color(0xFFFF9500)),
      ReservationStatus.confirmed => ('Confirmed', AppColors.success),
      ReservationStatus.rejected  => ('Rejected',  AppColors.error),
      ReservationStatus.completed => ('Done',      AppColors.textSecondary),
      _                           => ('•',         AppColors.textTertiary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
