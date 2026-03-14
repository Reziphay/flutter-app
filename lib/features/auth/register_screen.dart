// register_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/network_exception.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';

/// Shown after OTP verify when user.isNewUser == true and profile incomplete.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  bool _isLoading = false;
  String? _error;

  bool get _canProceed =>
      _fullNameCtrl.text.trim().length >= 2 &&
      _emailCtrl.text.trim().contains('@');

  Future<void> _completeRegistration() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final user = await AuthService.instance.updateProfile(
        fullName: _fullNameCtrl.text.trim(),
        email:    _emailCtrl.text.trim().toLowerCase(),
      );
      if (!mounted) return;
      ref.read(appStateProvider.notifier).updateUser(user);
      context.go('/home');
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildField(
                label: 'Full Name',
                placeholder: 'Your full name',
                controller: _fullNameCtrl,
                keyboard: TextInputType.name,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Email Address',
                placeholder: 'your@email.com',
                controller: _emailCtrl,
                keyboard: TextInputType.emailAddress,
                capitalization: TextCapitalization.none,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canProceed && !_isLoading
                      ? _completeRegistration
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Complete Registration',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Almost there!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tell us a bit about yourself to complete your account setup',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required TextInputType keyboard,
    required TextCapitalization capitalization,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, __, ___) => TextField(
            controller: controller,
            keyboardType: keyboard,
            textCapitalization: capitalization,
            autocorrect: false,
            style: const TextStyle(fontSize: 17),
            decoration: InputDecoration(
              hintText: placeholder,
              filled: true,
              fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }
}
