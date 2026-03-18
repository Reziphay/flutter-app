// incoming_reservations_screen.dart
// Reziphay — USO: incoming bookings list
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/l10n/app_localizations.dart';
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

// ── Tab kind ───────────────────────────────────────────────────────────────

enum _TabKind { pending, confirmed, history }

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
    _tabs = TabController(length: 3, vsync: this);
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
                  _IncomingList(kind: _TabKind.pending),
                  _IncomingList(kind: _TabKind.confirmed),
                  _IncomingList(kind: _TabKind.history),
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
    final l10n = context.l10n;
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
                      l10n.incomingTitle,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    Text(
                      l10n.incomingSubtitle,
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
          tabs: [
            Tab(text: l10n.tabPending),
            Tab(text: l10n.tabConfirmed),
            Tab(text: l10n.tabHistory),
          ],
        ),
      ],
    );
  }
}

// ── Tab list ───────────────────────────────────────────────────────────────

class _IncomingList extends ConsumerWidget {
  const _IncomingList({required this.kind});

  final _TabKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_incomingProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        final dc = context.dc;
        final l10n = context.l10n;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.warning_2, size: 48, color: dc.textTertiary),
              const SizedBox(height: 12),
              Text(l10n.somethingWentWrong, style: TextStyle(color: dc.textPrimary)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(_incomingProvider.notifier).refresh(),
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        );
      },
      data: (items) {
        final dc = context.dc;
        final l10n = context.l10n;

        final filtered = switch (kind) {
          _TabKind.pending   => items.where((r) => r.status == ReservationStatus.pending).toList(),
          _TabKind.confirmed => items.where((r) => r.status == ReservationStatus.confirmed).toList(),
          _TabKind.history   => items.where((r) => r.status.isFinished).toList(),
        };

        if (filtered.isEmpty) {
          final (icon, label) = switch (kind) {
            _TabKind.pending   => (Iconsax.clock,           l10n.noPendingRequests),
            _TabKind.confirmed => (Iconsax.calendar_tick,   l10n.noConfirmedBookings),
            _TabKind.history   => (Iconsax.document_text,   l10n.noHistoryItems),
          };
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: dc.textTertiary),
                const SizedBox(height: 12),
                Text(label, style: TextStyle(color: dc.textSecondary)),
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
                    style: TextStyle(fontSize: 13, color: dc.textSecondary),
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
                    style: TextStyle(fontSize: 13, color: dc.textSecondary),
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
                      style: TextStyle(fontSize: 13, color: dc.textSecondary),
                    ),
                  ],
                ),
              ],
              // Action buttons — only for PENDING
              if (isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppPalette.error,
                          side: const BorderSide(color: AppPalette.error),
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => _showRejectDialog(context, ref),
                        child: Text(context.l10n.rejectChange),
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
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          elevation: 0,
                        ),
                        onPressed: () => _accept(context, ref),
                        child: Text(context.l10n.acceptChange),
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
          SnackBar(
            content: Text(context.l10n.reservationAccepted),
            backgroundColor: AppPalette.success,
          ),
        );
      }
    } catch (e) {
      onUpdated(); // refresh list — reservation may have expired/changed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    // Dialog owns the controller — disposed in its State.dispose(),
    // safely after the closing animation completes.
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _RejectDialog(l10n: context.l10n),
    );

    if (reason != null && context.mounted) {
      try {
        await ReservationService.instance
            .rejectReservation(reservation.id, reason);
        onUpdated();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.reservationRejected)),
          );
        }
      } catch (e) {
        onUpdated(); // refresh list — reservation may have expired/changed
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
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
    final l10n = context.l10n;
    final (label, color) = switch (status) {
      ReservationStatus.pending   => (l10n.statusPending,   const Color(0xFFFF9500)),
      ReservationStatus.confirmed => (l10n.statusConfirmed, AppPalette.success),
      ReservationStatus.rejected  => (l10n.statusRejected,  AppPalette.error),
      ReservationStatus.completed => (l10n.statusCompleted, context.dc.textSecondary),
      _                           => ('•',                  context.dc.textTertiary),
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

// ── Reject dialog (owns its TextEditingController) ─────────────────────────

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.rejectReservationTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.cancelReasonHint),
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(
            l10n.rejectChange,
            style: const TextStyle(color: AppPalette.error),
          ),
        ),
      ],
    );
  }
}
