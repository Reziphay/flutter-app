import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const path = '/welcome';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Reziphay',
              style: textTheme.displayLarge?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Find the right service or manage reservations without forcing your workflow into a rigid booking engine.',
              style: textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            _IntentCard(
              title: 'Continue as a customer',
              description:
                  'Search nearby services, compare providers, and manage reservations from one place.',
              buttonLabel: 'Create customer account',
              onPressed: () => context.go('${RegisterPage.path}?role=customer'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _IntentCard(
              title: 'Continue as a service provider',
              description:
                  'Create brands, publish services, and respond to reservation requests from the same account system.',
              buttonLabel: 'Create provider account',
              onPressed: () => context.go('${RegisterPage.path}?role=provider'),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'I already have an account',
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(LoginPage.path),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'By continuing you agree to the future Terms and Privacy Policy. This foundation is mobile-first and role-aware by design.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentCard extends StatelessWidget {
  const _IntentCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: buttonLabel, onPressed: onPressed),
        ],
      ),
    );
  }
}
