// reservation_detail_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: _BackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: _BackButton(),
        ),
        body: Center(
          child: Text(e.toString(),
              style: const TextStyle(color: AppColors.textSecondary)),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this reservation?',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle:
                    const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.secondaryBackground,
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
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel booking'),
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
          const SnackBar(content: Text('Reservation cancelled')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _cancelling = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    final (statusLabel, statusColor) = _statusDisplay(r.status);

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: _BackButton(),
        title: const Text(
          'Reservation',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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
                  label: 'Date & Time',
                  value: _formatDateTime(r.requestedStartAt),
                ),
                if (r.requestedEndAt != null)
                  _DetailRow(
                    icon: Iconsax.clock,
                    label: 'End Time',
                    value: _formatDateTime(r.requestedEndAt!),
                  ),
                _DetailRow(
                  icon: Iconsax.money,
                  label: 'Price',
                  value: r.service.priceDisplay,
                ),
                _DetailRow(
                  icon: Iconsax.user,
                  label: 'Provider',
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
              title: 'Your Note',
              body: r.customerNote!,
            ),

          if (r.rejectionReason != null &&
              r.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Iconsax.close_circle,
              title: 'Rejection Reason',
              body: r.rejectionReason!,
              iconColor: AppColors.error,
            ),
          ],

          if (r.cancellationReason != null &&
              r.cancellationReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Iconsax.close_circle,
              title: 'Cancellation Reason',
              body: r.cancellationReason!,
              iconColor: AppColors.error,
            ),
          ],

          // Free cancellation note
          if (r.status.isCancellable &&
              r.freeCancellationEligible == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.tick_circle,
                      size: 18, color: AppColors.success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Free cancellation available',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.success,
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
                        'Check-in QR',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      r.completionQrPayload!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.textSecondary,
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
                  label: 'Booking ID',
                  value: r.id.substring(0, 8).toUpperCase(),
                ),
                _DetailRow(
                  icon: Iconsax.calendar_1,
                  label: 'Booked on',
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
              color: AppColors.background,
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _cancelling ? null : _showCancelDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
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
                            color: AppColors.error,
                          ),
                        )
                      : const Text(
                          'Cancel Reservation',
                          style: TextStyle(
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

  (String, Color) _statusDisplay(ReservationStatus s) => switch (s) {
        ReservationStatus.pending              => ('Pending', AppColors.warning),
        ReservationStatus.confirmed            => ('Confirmed', AppColors.success),
        ReservationStatus.rejected             => ('Rejected', AppColors.error),
        ReservationStatus.cancelledByCustomer  => ('Cancelled', AppColors.textSecondary),
        ReservationStatus.cancelledByOwner     => ('Cancelled by Owner', AppColors.textSecondary),
        ReservationStatus.changeRequestedByCustomer ||
        ReservationStatus.changeRequestedByOwner =>
          ('Change Requested', AppColors.warning),
        ReservationStatus.completed            => ('Completed', AppColors.success),
        ReservationStatus.noShow               => ('No Show', AppColors.error),
        ReservationStatus.expired              => ('Expired', AppColors.textTertiary),
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
          child: const Icon(Iconsax.arrow_left_2,
              size: 20, color: AppColors.textPrimary),
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
        color: AppColors.background,
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
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
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
