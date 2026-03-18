// owner_change_request_sheet.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';
import '../../state/reservation_providers.dart';

// ── Public helper ────────────────────────────────────────────────────────────

Future<void> showOwnerChangeRequestSheet(
  BuildContext context,
  WidgetRef ref,
  ReservationItem reservation,
) async {
  final theme = Theme.of(context);
  final locale = Localizations.localeOf(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: theme,
      child: Localizations.override(
        context: context,
        locale: locale,
        child: _OwnerChangeRequestSheet(reservation: reservation, ref: ref),
      ),
    ),
  );
}

// ── Sheet ────────────────────────────────────────────────────────────────────

class _OwnerChangeRequestSheet extends StatefulWidget {
  const _OwnerChangeRequestSheet({
    required this.reservation,
    required this.ref,
  });

  final ReservationItem reservation;
  final WidgetRef ref;

  @override
  State<_OwnerChangeRequestSheet> createState() =>
      _OwnerChangeRequestSheetState();
}

class _OwnerChangeRequestSheetState extends State<_OwnerChangeRequestSheet> {
  bool _loading = false;
  String? _error;

  ReservationChangeRequest? get _changeRequest =>
      widget.reservation.pendingOwnerChangeRequest;

  Future<void> _respond({required bool accept}) async {
    final cr = _changeRequest;
    if (cr == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (accept) {
        await ReservationService.instance.acceptChangeRequest(cr.id);
      } else {
        await ReservationService.instance.rejectChangeRequest(cr.id);
      }
      widget.ref.invalidate(myReservationsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final dc = context.dc;
    final l10n = context.l10n;
    final cr = _changeRequest;

    return Container(
      decoration: BoxDecoration(
        color: dc.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dc.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: AppPalette.warning, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ownerChangeRequest,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: dc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.changeRequestDetails,
                      style:
                          TextStyle(fontSize: 13, color: dc.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (cr != null) ...[
            // Proposed new time
            _InfoTile(
              icon: Iconsax.calendar,
              label: 'Yeni vaxt',
              value: _formatDateTime(cr.requestedStartAt),
              dc: dc,
            ),
            if (cr.requestedEndAt != null) ...[
              const SizedBox(height: 10),
              _InfoTile(
                icon: Iconsax.clock,
                label: 'Bitmə vaxtı',
                value: _formatDateTime(cr.requestedEndAt!),
                dc: dc,
              ),
            ],
            const SizedBox(height: 10),

            // Reason
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dc.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Səbəb',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: dc.textTertiary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cr.reason,
                    style: TextStyle(
                      fontSize: 14,
                      color: dc.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Center(
              child: Text(
                'Aktiv dəyişiklik tələbi tapılmadı',
                style: TextStyle(color: dc.textSecondary),
              ),
            ),
          ],

          // Error banner
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppPalette.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppPalette.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                _error!,
                style:
                    const TextStyle(fontSize: 13, color: AppPalette.error),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          if (cr != null) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppPalette.error.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed:
                        _loading ? null : () => _respond(accept: false),
                    child: Text(
                      l10n.rejectChange,
                      style: const TextStyle(
                        color: AppPalette.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed:
                        _loading ? null : () => _respond(accept: true),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.acceptChange,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Bağla'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Yan', 'Fev', 'Mar', 'Apr', 'May', 'İyn',
      'İyl', 'Avq', 'Sep', 'Okt', 'Noy', 'Dek',
    ];
    final date = '${local.day} ${months[local.month - 1]} ${local.year}';
    final hour = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$date · $hour:$min';
  }
}

// ── Info tile ────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.dc,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppDynamicColors dc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: dc.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.palette.primary),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(fontSize: 14, color: dc.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: dc.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
