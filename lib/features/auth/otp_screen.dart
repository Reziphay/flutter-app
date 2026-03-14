// otp_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/endpoints.dart';
import '../../core/network/network_exception.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    required this.purpose,
  });

  final String phone;
  final OtpPurpose purpose;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _otpLength = 6;

  final _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  bool _isLoading   = false;
  bool _canResend   = false;
  int  _resendTimer = 30;
  Timer? _timer;
  String? _error;

  String get _otpCode => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otpCode.length == _otpLength;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes)  { f.dispose(); }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() { _canResend = false; _resendTimer = 30; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendTimer <= 1) {
        t.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _resendTimer--);
      }
    });
  }

  void _onDigitChanged(int index, String value) {
    // Handle paste
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < digits.length && (index + i) < _otpLength; i++) {
        _controllers[index + i].text = digits[i];
      }
      final next = (index + digits.length).clamp(0, _otpLength - 1);
      _focusNodes[next].requestFocus();
      setState(() {});
      if (_isComplete) _verifyOtp();
      return;
    }

    if (value.isNotEmpty) {
      _controllers[index].text = value;
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    setState(() {});
    if (_isComplete) _verifyOtp();
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    } else {
      _controllers[index].clear();
    }
    setState(() {});
  }

  Future<void> _verifyOtp() async {
    if (!_isComplete || _isLoading) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final response = await AuthService.instance.verifyOtp(
        phone:   widget.phone,
        code:    _otpCode,
        purpose: widget.purpose,
      );

      if (!mounted) return;

      ref.read(appStateProvider.notifier).onSessionCreated(user: response.user);

      // New user with incomplete profile → go to register
      if (response.user.isNewUser && !response.user.isProfileComplete) {
        context.pushReplacement('/auth/register');
      } else {
        context.go('/home');
      }
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
      _clearOtp();
    } catch (_) {
      setState(() => _error = 'Invalid code. Please try again.');
      _clearOtp();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await AuthService.instance.requestOtp(
        phone:   widget.phone,
        purpose: widget.purpose,
      );
      _startTimer();
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to resend code. Please try again.');
    }
  }

  void _clearOtp() {
    for (final c in _controllers) { c.clear(); }
    _focusNodes.first.requestFocus();
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
              const Spacer(),
              _buildOtpInput(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildError(),
              ],
              const Spacer(),
              _buildVerifyButton(),
              const SizedBox(height: 16),
              _buildResendButton(),
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
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.message_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Verify your number',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to ${widget.phone}',
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // MARK: - OTP Input

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_otpLength, (i) => _OtpDigitCell(
        controller: _controllers[i],
        focusNode:  _focusNodes[i],
        isFocused:  _focusNodes[i].hasFocus,
        onChanged:  (v) => _onDigitChanged(i, v),
        onBackspace: () => _onBackspace(i),
      )),
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

  // MARK: - Verify Button

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isComplete && !_isLoading ? _verifyOtp : null,
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
                'Verify',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildResendButton() {
    return Center(
      child: _canResend
          ? TextButton(
              onPressed: _resendOtp,
              child: const Text(
                'Resend Code',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            )
          : Text(
              'Resend in ${_resendTimer}s',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
    );
  }
}

// MARK: - OTP Digit Cell

class _OtpDigitCell extends StatefulWidget {
  const _OtpDigitCell({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final void Function(String) onChanged;
  final VoidCallback onBackspace;

  @override
  State<_OtpDigitCell> createState() => _OtpDigitCellState();
}

class _OtpDigitCellState extends State<_OtpDigitCell> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    final hasValue = widget.controller.text.isNotEmpty;

    return Container(
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!hasValue)
            Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: focused
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            )
          else
            Text(
              widget.controller.text,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

          // Hidden TextField for input
          Opacity(
            opacity: 0.001,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              onChanged: widget.onChanged,
              onSubmitted: (_) {},
            ),
          ),

          // Backspace interceptor
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.focusNode.requestFocus,
          ),
        ],
      ),
    );
  }
}
