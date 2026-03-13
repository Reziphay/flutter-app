import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/features/reports/data/reports_repository.dart';
import 'package:reziphay_mobile/features/reports/models/report_models.dart';

Future<ReportSubmissionDraft?> showReportSubmissionSheet(
  BuildContext context, {
  required ReportTargetSummary target,
  String title = 'Submit report',
}) {
  final detailsController = TextEditingController();
  var selectedReason = ReportReason.misleadingInfo;

  return showModalBottomSheet<ReportSubmissionDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final canSubmit =
              selectedReason != ReportReason.other ||
              detailsController.text.trim().isNotEmpty;

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      color: AppColors.surfaceSoft,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            target.type.label,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            target.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (target.subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              target.subtitle!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Why are you reporting this?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...ReportReason.values.map(
                      (reason) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => selectedReason = reason),
                          child: AppCard(
                            color: selectedReason == reason
                                ? AppColors.surfaceSoft
                                : null,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  selectedReason == reason
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: selectedReason == reason
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reason.label,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        reason.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: detailsController,
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Additional detail',
                        hintText: selectedReason == ReportReason.other
                            ? 'Add the missing context for this report.'
                            : 'Optional context for the moderation review.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Submit report',
                      onPressed: canSubmit
                          ? () => Navigator.of(context).pop(
                              ReportSubmissionDraft(
                                reason: selectedReason,
                                details: detailsController.text.trim(),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> submitReportFlow(
  BuildContext context,
  WidgetRef ref, {
  required ReportTargetSummary target,
  String title = 'Submit report',
  String successMessage = 'Report submitted.',
}) async {
  final draft = await showReportSubmissionSheet(
    context,
    target: target,
    title: title,
  );

  if (draft == null) {
    return;
  }

  try {
    await ref
        .read(reportsActionsProvider)
        .submitReport(
          target: target,
          reason: draft.reason,
          details: draft.details,
        );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
  }
}
