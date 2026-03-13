import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';

class AccountClosedPage extends ConsumerWidget {
  const AccountClosedPage({super.key});

  static const path = '/account-closed';

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
                Icons.block_outlined,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Account closed',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Accounts at the indefinite closure threshold cannot create or manage reservations. The app keeps this state clear instead of hiding it behind generic auth errors.',
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
