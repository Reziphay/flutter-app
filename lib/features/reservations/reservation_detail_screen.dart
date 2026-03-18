// reservation_detail_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';
import '../../state/reservation_providers.dart';

class ReservationDetailScreen extends ConsumerWidget {
  const ReservationDetailScreen({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVal = ref.watch(reservationDetailProvider(reservationId));

    return asyncVal.when(
      loading: () => Scaffold(
        backgroundColor: context.dc.background,
        appBar: AppBar(
          backgroundColor: context.dc.background,
          elevation: 0,
          leading: _BackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.dc.background,
        appBar: AppBar(
          backgroundColor: context.dc.background,
          elevation: 0,
          leading: _BackButton(),
        ),
        body: Center(
          child: Text(e.toString(),
              style: TextStyle(color: context.dc.textSecondary)),
        ),
      ),
      data: (reservation) =>
          _ReservationDetailView(reservation: reservation),
    );
  }
}

// ── Detail view ─────────────────────────────────────────────────────────────

class _ReservationDetailView extends ConsumerStatefulWidget {
  const _ReservationDetailView({required this.reservation});

  final ReservationItem reservation;

  @override
  ConsumerState<_ReservationDetailView> createState() =>
      _ReservationDetailViewState();
}

class _ReservationDetailViewState
    extends ConsumerState<_ReservationDetailView> {
  bool _cancelling = false;

  Future<void> _showCancelDialog() async {
    final reasonController = TextEditingController();
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelReservationTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cancelReservationContent,
              style: TextStyle(
                  color: context.dc.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.cancelReasonHint,
                hintStyle:
                    TextStyle(color: context.dc.textTertiary),
                filled: true,
                fillColor: context.dc.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.keepIt),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppPalette.error),
            child: Text(l10n.cancelBooking),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ReservationService.instance.cancelReservation(
        widget.reservation.id,
        reasonController.text.trim(),
      );
      ref.invalidate(myReservationsProvider);
      ref.invalidate(
          reservationDetailProvider(widget.reservation.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.reservationCancelled)),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _cancelling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppPalette.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = widget.reservation;
    final dc = context.dc;
    final (statusLabel, statusColor) = _statusDisplay(l10n, r.status, dc);

    return Scaffold(
      backgroundColor: dc.secondaryBackground,
      appBar: AppBar(
        backgroundColor: dc.background,
        elevation: 0,
        leading: _BackButton(),
        title: Text(
          l10n.reservationTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: dc.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.service.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: dc.textPrimary,
                        ),
                      ),
                    ),
                    _StatusBadge(
                        label: statusLabel, color: statusColor),
                  ],
                ),
                if (r.brand != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    r.brand!.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.palette.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Iconsax.calendar,
                  label: l10n.dateTime,
                  value: _formatDateTime(r.requestedStartAt),
                ),
                if (r.requestedEndAt != null)
                  _DetailRow(
                    icon: Iconsax.clock,
                    label: l10n.endTime,
                    value: _formatDateTime(r.requestedEndAt!),
                  ),
                _DetailRow(
                  icon: Iconsax.money,
                  label: l10n.price,
                  value: r.service.priceDisplay,
                ),
                _DetailRow(
                  icon: Iconsax.user,
                  label: l10n.providerLabel,
                  value: r.owner.fullName,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Notes / reason card
          if (r.customerNote != null && r.customerNote!.isNotEmpty)
            _InfoCard(
              icon: Iconsax.note,
              title: l10n.yourNote,
              body: r.customerNote!,
            ),

          if (r.rejectionReason != null &&
              r.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Iconsax.close_circle,
              title: l10n.rejectionReason,
              body: r.rejectionReason!,
              iconColor: AppPalette.error,
            ),
          ],

          if (r.cancellationReason != null &&
              r.cancellationReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Iconsax.close_circle,
              title: l10n.cancellationReason,
              body: r.cancellationReason!,
              iconColor: AppPalette.error,
            ),
          ],

          // Free cancellation note
          if (r.status.isCancellable &&
              r.freeCancellationEligible == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.tick_circle,
                      size: 18, color: AppPalette.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.freeCancellation,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppPalette.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // QR payload card
          if (r.completionQrPayload != null &&
              r.completionQrPayload!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.scan, size: 18, color: context.palette.primary),
                      SizedBox(width: 8),
                      Text(
                        l10n.checkinQr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: dc.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dc.secondaryBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      r.completionQrPayload!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: dc.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Booking ID + created at
          _Card(
            child: Column(
              children: [
                _DetailRow(
                  icon: Iconsax.receipt,
                  label: l10n.bookingId,
                  value: r.id.substring(0, 8).toUpperCase(),
                ),
                _DetailRow(
                  icon: Iconsax.calendar_1,
                  label: l10n.bookedOn,
                  value: _formatDateTime(r.createdAt),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
      // Cancel button
      bottomNavigationBar: r.status.isCancellable
          ? Container(
              color: dc.background,
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _cancelling ? null : _showCancelDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.error,
                    side: const BorderSide(color: AppPalette.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _cancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppPalette.error,
                          ),
                        )
                      : Text(
                          l10n.cancelReservationTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            )
          : null,
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

  (String, Color) _statusDisplay(AppLocalizations l10n, ReservationStatus s, AppDynamicColors dc) => switch (s) {
        ReservationStatus.pending              => (l10n.statusPending, AppPalette.warning),
        ReservationStatus.confirmed            => (l10n.statusConfirmed, AppPalette.success),
        ReservationStatus.rejected             => (l10n.statusRejected, AppPalette.error),
        ReservationStatus.cancelledByCustomer  => (l10n.statusCancelled, dc.textSecondary),
        ReservationStatus.cancelledByOwner     => (l10n.statusCancelled, dc.textSecondary),
        ReservationStatus.changeRequestedByCustomer ||
        ReservationStatus.changeRequestedByOwner =>
          (l10n.statusChangeReq, AppPalette.warning),
        ReservationStatus.completed            => (l10n.statusCompleted, AppPalette.success),
        ReservationStatus.noShow               => (l10n.statusNoShow, AppPalette.error),
        ReservationStatus.expired              => (l10n.statusExpired, dc.textTertiary),
      };
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(Iconsax.arrow_left_2,
              size: 20, color: context.dc.textPrimary),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.dc.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.palette.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.dc.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.dc.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? context.palette.primary;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: effectiveIconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.dc.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              color: context.dc.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

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
