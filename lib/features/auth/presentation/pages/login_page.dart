import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/app_text_field.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const path = '/auth/login';

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text('Sign in with your phone', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Use OTP-based sign in. Sessions stay active until the user logs out.',
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
            Form(
              key: _formKey,
              child: AppTextField(
                controller: _phoneController,
                label: 'Phone number',
                hint: '+994 50 000 00 00',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: _validatePhone,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Request OTP',
              isLoading: sessionState.isBusy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                onPressed: () =>
                    context.go('${RegisterPage.path}?role=customer'),
                child: const Text('Create a new account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePhone(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.length < 10) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .requestOtpForLogin(_phoneController.text.trim());

    if (ok && mounted) {
      context.go(OtpVerificationPage.path);
    }
  }
}
