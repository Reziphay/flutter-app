// phone_entry_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/endpoints.dart';
import '../../core/network/network_exception.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phoneCtrl    = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();

  final _phoneFocus    = FocusNode();
  final _fullNameFocus = FocusNode();
  final _emailFocus    = FocusNode();

  bool _isLoading  = false;
  bool _isNewUser  = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneFocus.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String get _formattedPhone => '+994${_phoneCtrl.text.trim()}';

  bool get _canProceed {
    if (_phoneCtrl.text.length != 9) return false;
    if (_isNewUser) {
      return _fullNameCtrl.text.trim().length >= 2 &&
          _emailCtrl.text.trim().contains('@');
    }
    return true;
  }

  Future<void> _handleSendCode() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      if (_isNewUser) {
        await AuthService.instance.requestOtp(
          phone:    _formattedPhone,
          purpose:  OtpPurpose.register,
          fullName: _fullNameCtrl.text.trim(),
          email:    _emailCtrl.text.trim().toLowerCase(),
        );
        if (!mounted) return;
        context.push('/auth/otp', extra: {
          'phone':   _formattedPhone,
          'purpose': OtpPurpose.register,
        });
      } else {
        await AuthService.instance.requestOtp(
          phone:   _formattedPhone,
          purpose: OtpPurpose.login,
        );
        if (!mounted) return;
        context.push('/auth/otp', extra: {
          'phone':   _formattedPhone,
          'purpose': OtpPurpose.login,
        });
      }
    } on NetworkException catch (e) {
      if (e.isUnauthorized) {
        // User not found → switch to register mode
        setState(() {
          _isNewUser = true;
          _error     = null;
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          _fullNameFocus.requestFocus();
        });
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(appStateProvider).selectedRole;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(role),
              const SizedBox(height: 40),
              _buildPhoneField(),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isNewUser ? _buildRegisterFields() : const SizedBox.shrink(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildError(),
              ],
              const SizedBox(height: 40),
              _buildSendButton(),
              const SizedBox(height: 16),
              if (_isNewUser)
                _buildSwitchNumberButton()
              else
                _buildTermsText(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Header

  Widget _buildHeader(dynamic role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            role?.value == 'USO'
                ? Icons.work_rounded
                : Icons.person_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _isNewUser ? 'Create your account' : 'Enter your phone number',
            key: ValueKey(_isNewUser),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _isNewUser
                ? 'Fill in your details to get started'
                : "We'll send you a one-time code to verify your identity",
            key: ValueKey(_isNewUser),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // MARK: - Phone Field

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country code badge
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                '+994',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Phone input
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                enabled: !_isNewUser,
                style: const TextStyle(fontSize: 17),
                decoration: InputDecoration(
                  hintText: 'XX 123 45 67',
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // MARK: - Register Fields

  Widget _buildRegisterFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          _buildTextField(
            label: 'Full Name',
            placeholder: 'Your full name',
            controller: _fullNameCtrl,
            focusNode: _fullNameFocus,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email',
            placeholder: 'your@email.com',
            controller: _emailCtrl,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
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
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
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
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (_) => setState(() {}),
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

  // MARK: - Send Button

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _canProceed && !_isLoading ? _handleSendCode : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
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
                'Send Code',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSwitchNumberButton() {
    return Center(
      child: TextButton(
        onPressed: () => setState(() {
          _isNewUser = false;
          _error     = null;
        }),
        child: const Text(
          'Use a different number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return const Center(
      child: Text(
        'By continuing, you agree to our Terms of Service\nand Privacy Policy',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
      ),
    );
  }
}
