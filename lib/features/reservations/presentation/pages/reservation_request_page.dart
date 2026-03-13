import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/reservation_request_success_page.dart';

class ReservationRequestPage extends ConsumerStatefulWidget {
  const ReservationRequestPage({required this.serviceId, super.key});

  static const path = '/customer/service/:serviceId/request';

  static String location(String serviceId) =>
      '/customer/service/$serviceId/request';

  final String serviceId;

  @override
  ConsumerState<ReservationRequestPage> createState() =>
      _ReservationRequestPageState();
}

class _ReservationRequestPageState
    extends ConsumerState<ReservationRequestPage> {
  final _noteController = TextEditingController();
  DateTime? _selectedTime;
  var _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(serviceDetailProvider(widget.serviceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Request reservation')),
      body: detailAsync.when(
        data: (detail) => _buildContent(context, detail),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not load request flow',
            description: error.toString(),
          ),
        ),
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (detail) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: AppButton(
              label: detail.summary.approvalMode == ApprovalMode.manual
                  ? 'Send request'
                  : 'Confirm reservation',
              isLoading: _isSubmitting,
              onPressed: detail.requestableSlots.any((slot) => slot.available)
                  ? () => _submit(detail)
                  : null,
            ),
          ),
        ),
        orElse: SizedBox.shrink,
      ),
    );
  }

  Widget _buildContent(BuildContext context, ServiceDetail detail) {
    final textTheme = Theme.of(context).textTheme;
    final availableSlots = detail.requestableSlots
        .where((slot) => slot.available)
        .toList();
    final selectedTime = _selectedTime ?? availableSlots.firstOrNull?.startsAt;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.summary.name, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                [
                  if (detail.summary.brandName != null)
                    detail.summary.brandName!,
                  detail.summary.providerName,
                ].join(' · '),
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusPill(
                    label: detail.summary.approvalMode.label,
                    tone: detail.summary.approvalMode == ApprovalMode.manual
                        ? StatusPillTone.warning
                        : StatusPillTone.success,
                  ),
                  StatusPill(
                    label: detail.summary.priceLabel,
                    tone: StatusPillTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                detail.summary.descriptionSnippet ?? detail.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Choose a time', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'These are requestable times, not a rigid calendar lock. The provider still sees the request in context.',
          style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: detail.requestableSlots
              .map(
                (slot) => ChoiceChip(
                  label: Text(
                    slot.note == null
                        ? slot.label
                        : '${slot.label} · ${slot.note}',
                  ),
                  selected: selectedTime == slot.startsAt,
                  onSelected: slot.available
                      ? (_) => setState(() => _selectedTime = slot.startsAt)
                      : null,
                ),
              )
              .toList(),
        ),
        if (selectedTime != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            color: AppColors.surfaceSoft,
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Selected time: ${_formatSelectedTime(selectedTime)}',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (selectedTime == null) ...[
          const SizedBox(height: AppSpacing.md),
          const EmptyState(
            title: 'No requestable slots',
            description:
                'This service does not have any open request windows right now.',
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('Optional note', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _noteController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Note for provider',
            hintText:
                'Preferences, arrival note, or anything the provider should know.',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          color: detail.summary.approvalMode == ApprovalMode.manual
              ? const Color(0xFFFFF5DF)
              : const Color(0xFFEAF8F1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    detail.summary.approvalMode == ApprovalMode.manual
                        ? Icons.timer_outlined
                        : Icons.check_circle_outline,
                    color: detail.summary.approvalMode == ApprovalMode.manual
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      detail.summary.approvalMode == ApprovalMode.manual
                          ? 'Manual approval stays explicit'
                          : 'This time confirms instantly',
                      style: textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                detail.summary.approvalMode.detailDescription,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              if (detail.summary.approvalMode == ApprovalMode.manual) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'If the provider does not respond within 5 minutes, the request expires automatically instead of hanging in limbo.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatSelectedTime(DateTime selectedTime) {
    final hour = selectedTime.hour.toString().padLeft(2, '0');
    final minute = selectedTime.minute.toString().padLeft(2, '0');
    return '${selectedTime.day}/${selectedTime.month} · $hour:$minute';
  }

  Future<void> _submit(ServiceDetail detail) async {
    final availableSlots = detail.requestableSlots
        .where((slot) => slot.available)
        .toList();
    final selectedTime = _selectedTime ?? availableSlots.firstOrNull?.startsAt;

    if (selectedTime == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reservationId = await ref
          .read(reservationsActionsProvider)
          .createReservation(
            serviceId: detail.summary.id,
            scheduledAt: selectedTime,
            note: _noteController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      context.go(ReservationRequestSuccessPage.location(reservationId));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
