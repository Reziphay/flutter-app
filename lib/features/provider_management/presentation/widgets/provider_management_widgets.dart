import 'package:flutter/material.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';

class ManagementStatCard extends StatelessWidget {
  const ManagementStatCard({
    required this.label,
    required this.value,
    required this.tone,
    super.key,
  });

  final String label;
  final String value;
  final StatusPillTone tone;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(label: label, tone: tone),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

class ManagementSectionCard extends StatelessWidget {
  const ManagementSectionCard({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class VisibilityLabelSelector extends StatelessWidget {
  const VisibilityLabelSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Set<VisibilityLabel> selected;
  final ValueChanged<Set<VisibilityLabel>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: VisibilityLabel.values.map((label) {
        final isSelected = selected.contains(label);
        return FilterChip(
          selected: isSelected,
          label: Text(label.label),
          onSelected: (value) {
            final next = Set<VisibilityLabel>.of(selected);
            if (value) {
              next.add(label);
            } else {
              next.remove(label);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}

class EditableStringList extends StatelessWidget {
  const EditableStringList({
    required this.items,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.addLabel,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final List<String> items;
  final String emptyTitle;
  final String emptyDescription;
  final String addLabel;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isEmpty)
          EmptyState(title: emptyTitle, description: emptyDescription)
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: items
                .map(
                  (item) => InputChip(
                    label: Text(item),
                    onDeleted: () => onRemove(item),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: addLabel,
          variant: AppButtonVariant.secondary,
          icon: Icons.add,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

Future<String?> showManagementTextSheet(
  BuildContext context, {
  required String title,
  required String labelText,
  required String hintText,
  required String buttonLabel,
  String initialValue = '',
}) {
  final controller = TextEditingController(text: initialValue);

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
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: hintText,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: buttonLabel,
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
