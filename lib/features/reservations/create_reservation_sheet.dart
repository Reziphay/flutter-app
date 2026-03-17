// create_reservation_sheet.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../models/discovery.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';
import '../../state/reservation_providers.dart';

// ── Public helper ───────────────────────────────────────────────────────────

Future<bool> showCreateReservationSheet(
  BuildContext context,
  ServiceItem service,
) async {
  final theme = Theme.of(context);
  final locale = Localizations.localeOf(context);
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Theme(
      data: theme,
      child: Localizations.override(
        context: context,
        locale: locale,
        child: _CreateReservationSheet(service: service),
      ),
    ),
  );
  return result ?? false;
}

// ── Sheet widget ────────────────────────────────────────────────────────────

class _CreateReservationSheet extends ConsumerStatefulWidget {
  const _CreateReservationSheet({required this.service});

  final ServiceItem service;

  @override
  ConsumerState<_CreateReservationSheet> createState() =>
      _CreateReservationSheetState();
}

class _CreateReservationSheetState
    extends ConsumerState<_CreateReservationSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay(
    hour: (DateTime.now().hour + 1) % 24,
    minute: 0,
  );
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  DateTime get _requestedStartAt => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  // ── Pickers ───────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ReservationService.instance.createReservation(
        CreateReservationDto(
          serviceId: widget.service.id,
          requestedStartAt: _requestedStartAt,
          customerNote: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
      );
      // Refresh reservations list
      ref.invalidate(myReservationsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _loading = false);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final dc = context.dc;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: dc.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: dc.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            widget.service.approvalMode == 'AUTO'
                ? l10n.sheetBookNow
                : l10n.sheetRequestBooking,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: dc.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.service.name,
            style: TextStyle(
              fontSize: 14,
              color: dc.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Date row
          _PickerTile(
            icon: Iconsax.calendar,
            label: l10n.sheetDate,
            value: _formatDate(_selectedDate),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),

          // Time row
          _PickerTile(
            icon: Iconsax.clock,
            label: l10n.sheetTime,
            value: _selectedTime.format(context),
            onTap: _pickTime,
          ),
          const SizedBox(height: 20),

          // Note field
          TextField(
            controller: _noteController,
            maxLines: 3,
            style: TextStyle(color: dc.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.sheetNoteHint,
              hintStyle: TextStyle(color: dc.textTertiary),
              filled: true,
              fillColor: dc.secondaryBackground,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.5), width: 1),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Book button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
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
                      widget.service.approvalMode == 'AUTO'
                          ? l10n.sheetConfirmBooking
                          : l10n.sheetSendRequest,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Picker tile ─────────────────────────────────────────────────────────────

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: dc.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: dc.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: dc.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Iconsax.arrow_right_3, size: 16, color: dc.textTertiary),
          ],
        ),
      ),
    );
  }
}
