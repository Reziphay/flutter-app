import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/reservations/models/reservation_models.dart';

class ReservationCard extends StatelessWidget {
  const ReservationCard({
    required this.summary,
    required this.onTap,
    super.key,
    this.onExpire,
    this.trailingLabel,
  });

  final ReservationSummary summary;
  final VoidCallback onTap;
  final VoidCallback? onExpire;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final status = summary.effectiveStatus;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.serviceName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      [
                        if (summary.brandName != null) summary.brandName!,
                        summary.providerName,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(label: status.label, tone: _toneForStatus(status)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            summary.scheduledAtLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${summary.addressLine} · ${summary.priceLabel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (status == ReservationStatus.pendingApproval &&
              summary.pendingTimeRemaining != null) ...[
            const SizedBox(height: AppSpacing.sm),
            CountdownPill(
              deadline: summary.responseDeadline!,
              onExpire: onExpire,
            ),
          ] else if (trailingLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              trailingLabel!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class ReservationStatusBanner extends StatelessWidget {
  const ReservationStatusBanner({
    required this.summary,
    super.key,
    this.onExpire,
  });

  final ReservationSummary summary;
  final VoidCallback? onExpire;

  @override
  Widget build(BuildContext context) {
    final status = summary.effectiveStatus;

    return AppCard(
      color: _bannerColor(status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  status.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (status == ReservationStatus.pendingApproval &&
                  summary.responseDeadline != null)
                CountdownPill(
                  deadline: summary.responseDeadline!,
                  onExpire: onExpire,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            status.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class CountdownPill extends StatefulWidget {
  const CountdownPill({required this.deadline, super.key, this.onExpire});

  final DateTime deadline;
  final VoidCallback? onExpire;

  @override
  State<CountdownPill> createState() => _CountdownPillState();
}

class _CountdownPillState extends State<CountdownPill> {
  Timer? _timer;
  var _didNotifyExpiry = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_didNotifyExpiry && !DateTime.now().isBefore(widget.deadline)) {
        _didNotifyExpiry = true;
        widget.onExpire?.call();
        _timer?.cancel();
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deadline.difference(DateTime.now());
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    final minutes = clamped.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');

    return StatusPill(
      label: '$minutes:$seconds left',
      tone: StatusPillTone.warning,
      icon: Icons.timer_outlined,
    );
  }
}

class ReservationTimeline extends StatelessWidget {
  const ReservationTimeline({required this.events, super.key});

  final List<ReservationTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events
          .map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.xxs),
                    height: 10,
                    width: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          event.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${event.actorLabel} · ${event.timestampLabel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

Future<void> showReservationMessageSheet(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'Close',
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: buttonLabel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> showReservationReasonSheet(
  BuildContext context, {
  required String title,
  required String buttonLabel,
  required bool destructive,
}) {
  final controller = TextEditingController();

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Explain the cancellation, rejection, or change.',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: buttonLabel,
                variant: destructive
                    ? AppButtonVariant.destructive
                    : AppButtonVariant.primary,
                onPressed: () =>
                    Navigator.of(context).pop(controller.text.trim()),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<ReservationChangeDraft?> showReservationChangeSheet(
  BuildContext context, {
  required String title,
  required DateTime initialTime,
}) {
  final reasonController = TextEditingController();
  var selectedTime = initialTime.add(const Duration(hours: 2));

  return showModalBottomSheet<ReservationChangeDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final option in [
                        initialTime.add(const Duration(hours: 2)),
                        initialTime.add(const Duration(hours: 4)),
                        initialTime.add(const Duration(days: 1)),
                      ])
                        ChoiceChip(
                          label: Text(
                            '${option.month}/${option.day} · ${option.hour.toString().padLeft(2, '0')}:${option.minute.toString().padLeft(2, '0')}',
                          ),
                          selected: selectedTime == option,
                          onSelected: (_) =>
                              setState(() => selectedTime = option),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Explain why you need a new time.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Submit change request',
                    onPressed: () => Navigator.of(context).pop(
                      ReservationChangeDraft(
                        proposedTime: selectedTime,
                        reason: reasonController.text.trim(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Color _bannerColor(ReservationStatus status) {
  return switch (status) {
    ReservationStatus.pendingApproval => const Color(0xFFFFF5DF),
    ReservationStatus.confirmed => const Color(0xFFEAF8F1),
    ReservationStatus.changeRequested => const Color(0xFFEFF3FF),
    ReservationStatus.cancelled => const Color(0xFFFDECEC),
    ReservationStatus.completed => const Color(0xFFEAF8F1),
    ReservationStatus.noShow => const Color(0xFFFDECEC),
    ReservationStatus.rejected => const Color(0xFFFDECEC),
    ReservationStatus.expired => const Color(0xFFFDECEC),
  };
}

StatusPillTone _toneForStatus(ReservationStatus status) {
  return switch (status) {
    ReservationStatus.pendingApproval => StatusPillTone.warning,
    ReservationStatus.confirmed => StatusPillTone.success,
    ReservationStatus.changeRequested => StatusPillTone.info,
    ReservationStatus.cancelled => StatusPillTone.error,
    ReservationStatus.completed => StatusPillTone.success,
    ReservationStatus.noShow => StatusPillTone.error,
    ReservationStatus.rejected => StatusPillTone.error,
    ReservationStatus.expired => StatusPillTone.error,
  };
}
