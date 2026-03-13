import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';

class AccountSuspendedPage extends ConsumerWidget {
  const AccountSuspendedPage({super.key});

  static const path = '/account-suspended';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.timer_off_outlined,
                size: 56,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Account suspended',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Penalty rules temporarily restrict this account for one month once the threshold is reached. Provider and customer navigation stay blocked until the suspension ends.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Log out',
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    ref.read(sessionControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
