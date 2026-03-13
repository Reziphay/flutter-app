import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/features/auth/models/email_link_result_status.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/welcome_page.dart';

extension EmailLinkResultStatusPageX on EmailLinkResultStatus {
  String get title => switch (this) {
    EmailLinkResultStatus.success => 'Email verified',
    EmailLinkResultStatus.expired => 'This link expired',
    EmailLinkResultStatus.invalid => 'This link is invalid',
    EmailLinkResultStatus.alreadyUsed => 'This link was already used',
  };

  String get description => switch (this) {
    EmailLinkResultStatus.success =>
      'Your email verification finished successfully. Continue into the app with your phone session.',
    EmailLinkResultStatus.expired =>
      'Request a fresh email link from your profile or sign-in flow to complete verification.',
    EmailLinkResultStatus.invalid =>
      'The verification link could not be trusted. Start from the app and request a new one.',
    EmailLinkResultStatus.alreadyUsed =>
      'This email link has already been consumed. If your account is verified, continue to sign in.',
  };

  IconData get icon => switch (this) {
    EmailLinkResultStatus.success => Icons.mark_email_read_outlined,
    EmailLinkResultStatus.expired => Icons.schedule_outlined,
    EmailLinkResultStatus.invalid => Icons.report_gmailerrorred_outlined,
    EmailLinkResultStatus.alreadyUsed => Icons.info_outline,
  };

  Color get color => switch (this) {
    EmailLinkResultStatus.success => AppColors.success,
    EmailLinkResultStatus.expired => AppColors.warning,
    EmailLinkResultStatus.invalid => AppColors.error,
    EmailLinkResultStatus.alreadyUsed => AppColors.info,
  };
}

class EmailLinkResultPage extends StatelessWidget {
  const EmailLinkResultPage({required this.status, super.key});

  static const path = '/auth/email-link-result';
  static String location(EmailLinkResultStatus status) =>
      '$path?status=${status.name}';

  final EmailLinkResultStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(status.icon, size: 54, color: status.color),
              const SizedBox(height: AppSpacing.lg),
              Text(
                status.title,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                status.description,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              AppButton(
                label: status == EmailLinkResultStatus.success
                    ? 'Continue to sign in'
                    : 'Back to welcome',
                onPressed: () => context.go(
                  status == EmailLinkResultStatus.success
                      ? LoginPage.path
                      : WelcomePage.path,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
