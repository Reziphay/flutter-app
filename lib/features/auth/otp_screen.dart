// otp_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/endpoints.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/network/network_exception.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../../core/l10n/app_localizations.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    this.debugCode,
  });

  final String phone;
  final String? debugCode;

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
  String? _debugCode;

  String get _otpCode => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otpCode.length == _otpLength;

  @override
  void initState() {
    super.initState();
    _debugCode = widget.debugCode;
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fillDebugCode(_debugCode);
    });
  }

  void _fillDebugCode(String? code) {
    if (code != null && code.length == _otpLength) {
      final digits = code.split('');
      for (var i = 0; i < _otpLength; i++) {
        _controllers[i].text = digits[i];
      }
      if (mounted) setState(() {});
    } else {
      _focusNodes.first.requestFocus();
    }
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
      final result = await AuthService.instance.verifyOtp(
        phone: widget.phone,
        code:  _otpCode,
      );

      if (!mounted) return;

      if (result.requiresRegistration) {
        // New user — collect fullName + email
        context.pushReplacement('/auth/register', extra: {
          'registrationToken': result.registrationPending!.registrationToken,
          'phone':             widget.phone,
        });
      } else {
        final session = result.session!;
        ref.read(appStateProvider.notifier).onSessionCreated(user: session.user);
        context.go('/home');
      }
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
      _clearOtp();
    } catch (_) {
      setState(() => _error = context.l10n.otpInvalidCode);
      _clearOtp();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      final res = await AuthService.instance.requestOtp(
        phone:   widget.phone,
        purpose: OtpPurpose.authenticate,
      );
      _startTimer();
      _clearOtp();
      _debugCode = res.debugCode;
      _fillDebugCode(_debugCode);
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = context.l10n.otpResendFailed);
    }
  }

  void _clearOtp() {
    for (final c in _controllers) { c.clear(); }
    _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: dc.background,
      appBar: AppBar(
        backgroundColor: dc.background,
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: context.palette.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.message_rounded,
            color: context.palette.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.otpTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: context.dc.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.otpSubtitle(widget.phone),
          style: TextStyle(fontSize: 15, color: context.dc.textSecondary),
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
        const Icon(Icons.error_outline_rounded, color: AppPalette.error, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _error!,
            style: const TextStyle(fontSize: 13, color: AppPalette.error),
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
            : Text(
                context.l10n.otpVerify,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildResendButton() {
    final l10n = context.l10n;
    return Center(
      child: _canResend
          ? TextButton(
              onPressed: _resendOtp,
              child: Text(
                l10n.otpResend,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.palette.primary,
                ),
              ),
            )
          : Text(
              l10n.otpResendIn(_resendTimer),
              style: TextStyle(
                fontSize: 15,
                color: context.dc.textSecondary,
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

    final primary = context.palette.primary;
    final dc = context.dc;
    return Container(
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        color: dc.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? primary : Colors.transparent,
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
                    ? primary
                    : dc.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            )
          else
            Text(
              widget.controller.text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: dc.textPrimary,
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
              autofillHints: const [AutofillHints.oneTimeCode],
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
