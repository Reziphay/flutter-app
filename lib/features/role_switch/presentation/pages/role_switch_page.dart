import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/customer/presentation/pages/customer_home_page.dart';
import 'package:reziphay_mobile/features/provider/presentation/pages/provider_dashboard_page.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';

class RoleSwitchPage extends ConsumerWidget {
  const RoleSwitchPage({super.key});

  static const path = '/role-switch';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider);
    final session = sessionState.session;

    if (session == null) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final hasProviderRole = session.availableRoles.contains(AppRole.provider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text('Role switch', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'One account, two product surfaces. Customer and provider mode should be a fast switch, not a re-auth flow.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final role in AppRole.values) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(role.label, style: textTheme.titleLarge),
                    ),
                    if (session.activeRole == role)
                      const StatusPill(
                        label: 'Current',
                        tone: StatusPillTone.info,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  role.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: session.activeRole == role
                      ? 'Active now'
                      : 'Switch to ${role.label}',
                  variant: session.activeRole == role
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  onPressed:
                      !session.availableRoles.contains(role) ||
                          session.activeRole == role
                      ? null
                      : () async {
                          await ref
                              .read(sessionControllerProvider.notifier)
                              .switchRole(role);
                          if (context.mounted) {
                            context.go(
                              role == AppRole.provider
                                  ? ProviderDashboardPage.path
                                  : CustomerHomePage.path,
                            );
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (!hasProviderRole)
          AppCard(
            color: AppColors.surfaceMuted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activate provider mode', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This mirrors the backend `activate-uso` flow and adds the provider role to the same account.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Activate provider role',
                  isLoading: sessionState.isBusy,
                  onPressed: () async {
                    await ref
                        .read(sessionControllerProvider.notifier)
                        .activateProviderRole();
                    final updatedSession = ref
                        .read(sessionControllerProvider)
                        .session;
                    if (context.mounted &&
                        updatedSession?.activeRole == AppRole.provider) {
                      context.go(ProviderDashboardPage.path);
                    }
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
