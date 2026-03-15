// register_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/network_exception.dart';
import '../../core/theme/app_palette.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';

/// Shown after OTP verify when the user is new and needs to complete registration.
/// Receives [registrationToken] (short-lived JWT proving phone was verified).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({
    super.key,
    required this.registrationToken,
    required this.phone,
  });

  final String registrationToken;
  final String phone;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _fullNameFocus = FocusNode();
  final _emailFocus    = FocusNode();

  bool    _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fullNameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _fullNameCtrl.text.trim().length >= 2 &&
      _emailCtrl.text.trim().contains('@');

  Future<void> _handleComplete() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final selectedRole = ref.read(appStateProvider).selectedRole;
      final session = await AuthService.instance.completeRegistration(
        registrationToken: widget.registrationToken,
        fullName:          _fullNameCtrl.text.trim(),
        email:             _emailCtrl.text.trim().toLowerCase(),
        role:              selectedRole?.value,
      );

      if (!mounted) return;

      ref.read(appStateProvider.notifier).onSessionCreated(user: session.user);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildField(
                label:        'Full Name',
                placeholder:  'Your full name',
                controller:   _fullNameCtrl,
                focusNode:    _fullNameFocus,
                keyboard:     TextInputType.name,
                capitalization: TextCapitalization.words,
                onNext: () => _emailFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              _buildField(
                label:        'Email Address',
                placeholder:  'your@email.com',
                controller:   _emailCtrl,
                focusNode:    _emailFocus,
                keyboard:     TextInputType.emailAddress,
                capitalization: TextCapitalization.none,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildError(),
              ],
              const Spacer(),
              _buildCompleteButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Header

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
        Text(
          'Phone verified: ${widget.phone}',
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // MARK: - Field

  Widget _buildField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextInputType keyboard,
    required TextCapitalization capitalization,
    VoidCallback? onNext,
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
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboard,
          textCapitalization: capitalization,
          textInputAction: onNext != null ? TextInputAction.next : TextInputAction.done,
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.palette.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => onNext?.call(),
        ),
      ],
    );
  }

  // MARK: - Error

  Widget _buildError() {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _error!,
            style: const TextStyle(fontSize: 13, color: AppColors.error),
          ),
        ),
      ],
    );
  }

  // MARK: - Complete Button

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _canProceed && !_isLoading ? _handleComplete : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.palette.primary,
          disabledBackgroundColor: context.palette.primary.withValues(alpha: 0.5),
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
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
