import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/section_header.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/common/presentation/pages/settings_page.dart';
import 'package:reziphay_mobile/features/role_switch/presentation/pages/role_switch_page.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/user_status.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const path = '/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).session;

    if (session == null) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final user = session.user;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xs),
        const SectionHeader(title: 'Profile'),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.fullName.characters.first.toUpperCase(),
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          user.email,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(user.phoneNumber, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusPill(
                    label: session.activeRole.label,
                    tone: StatusPillTone.info,
                    icon: Icons.swap_horiz,
                  ),
                  StatusPill(
                    label: user.status.label,
                    tone: _toneForStatus(user.status),
                  ),
                  for (final role in user.roles)
                    StatusPill(
                      label: role.shortLabel,
                      tone: StatusPillTone.neutral,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Role management', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Reziphay keeps customer and provider workflows under the same account. Switching role should never require logout.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Switch or activate role',
                onPressed: () => context.go(RoleSwitchPage.path),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account state', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                user.status.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const StatusPill(
                label: 'Penalty flow and objections arrive in Phase 3+',
                tone: StatusPillTone.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shortcuts', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                subtitle: const Text('Reminder and notification preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(SettingsPage.path),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                subtitle: const Text('Clear the local session'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    ref.read(sessionControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  StatusPillTone _toneForStatus(UserStatus status) {
    return switch (status) {
      UserStatus.active => StatusPillTone.success,
      UserStatus.suspended => StatusPillTone.warning,
      UserStatus.closed => StatusPillTone.error,
    };
  }
}
