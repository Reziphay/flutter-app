import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/app_text_field.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({required this.initialRole, super.key});

  static const path = '/auth/register';

  final AppRole initialRole;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  late AppRole _role;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
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
            Text('Create your account', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Register once, verify by phone and email, then switch roles without logging out.',
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start as', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<AppRole>(
                    segments: const [
                      ButtonSegment(
                        value: AppRole.customer,
                        label: Text('Customer'),
                        icon: Icon(Icons.person_search_outlined),
                      ),
                      ButtonSegment(
                        value: AppRole.provider,
                        label: Text('Provider'),
                        icon: Icon(Icons.storefront_outlined),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: (selection) {
                      setState(() => _role = selection.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _fullNameController,
                    label: 'Full name',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().length < 3) {
                        return 'Enter your full name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.alternate_email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final email = (value ?? '').trim();
                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone number',
                    hint: '+994 50 000 00 00',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                      if (digits.length < 10) {
                        return 'Enter a valid phone number.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Continue to OTP',
              isLoading: sessionState.isBusy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Phone verification is required. Email verification completes via magic link after registration.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                onPressed: () => context.go(LoginPage.path),
                child: const Text('Already have an account? Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .requestOtpForRegistration(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          intendedRole: _role,
        );

    if (ok && mounted) {
      context.go(OtpVerificationPage.path);
    }
  }
}
