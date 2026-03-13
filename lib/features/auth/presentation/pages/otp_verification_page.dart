import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/app_text_field.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/welcome_page.dart';
import 'package:reziphay_mobile/features/customer/presentation/pages/customer_home_page.dart';
import 'package:reziphay_mobile/features/provider/presentation/pages/provider_dashboard_page.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/pending_auth_context.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key});

  static const path = '/auth/otp';

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final pendingAuth = sessionState.pendingAuth;
    final textTheme = Theme.of(context).textTheme;

    if (pendingAuth == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: _MissingOtpContext(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text('Verify your phone', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Enter the 6-digit code sent to ${_maskPhone(pendingAuth.phoneNumber)}.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (sessionState.errorMessage != null) ...[
              AppCard(
                color: const Color(0xFFFDECEC),
                child: Text(
                  sessionState.errorMessage!,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (pendingAuth.debugOtpCode != null) ...[
              AppCard(
                color: AppColors.surfaceSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Development OTP', style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      pendingAuth.debugOtpCode!,
                      style: textTheme.headlineSmall,
                    ),
                    if (pendingAuth.otpExpiresAt != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Expires at ${TimeOfDay.fromDateTime(pendingAuth.otpExpiresAt!.toLocal()).format(context)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Form(
              key: _formKey,
              child: AppTextField(
                controller: _otpController,
                label: 'OTP code',
                hint: '123456',
                icon: Icons.password_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                  if (digits.length != 6) {
                    return 'Enter the 6-digit OTP.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Verify and continue',
              isLoading: sessionState.isBusy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Resend OTP',
              variant: AppButtonVariant.ghost,
              onPressed: sessionState.isBusy
                  ? null
                  : () => _resend(pendingAuth),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Invalid, expired, and rate-limited OTP states now come directly from backend auth responses.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _maskPhone(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) {
      return phoneNumber;
    }

    final suffix = digits.substring(digits.length - 4);
    return '•••• ••$suffix';
  }

  Future<void> _resend(PendingAuthContext pendingAuth) async {
    final controller = ref.read(sessionControllerProvider.notifier);

    if (pendingAuth.mode == AuthFlowMode.login) {
      await controller.requestOtpForLogin(pendingAuth.phoneNumber);
      return;
    }

    await controller.requestOtpForRegistration(
      fullName: pendingAuth.fullName ?? '',
      email: pendingAuth.email ?? '',
      phoneNumber: pendingAuth.phoneNumber,
      intendedRole: pendingAuth.intendedRole,
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .verifyOtp(_otpController.text.trim());

    if (!ok || !mounted) {
      return;
    }

    final session = ref.read(sessionControllerProvider).session;
    final destination = session?.activeRole == AppRole.provider
        ? ProviderDashboardPage.path
        : CustomerHomePage.path;

    context.go(destination);
  }
}

class _MissingOtpContext extends StatelessWidget {
  const _MissingOtpContext();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 40,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'The OTP flow is no longer active.',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Request a fresh OTP to continue with registration or sign in.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Back to welcome',
            onPressed: () => context.go(WelcomePage.path),
            expand: false,
          ),
        ],
      ),
    );
  }
}
