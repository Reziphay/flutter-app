// create_brand_screen.dart
// Reziphay — USO: Create a Brand with phone OTP verification
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/network_exception.dart';
import '../../../core/theme/app_dynamic_colors.dart';
import '../../../core/theme/app_palette.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CreateBrandScreen extends ConsumerStatefulWidget {
  const CreateBrandScreen({super.key});

  @override
  ConsumerState<CreateBrandScreen> createState() => _CreateBrandScreenState();
}

class _CreateBrandScreenState extends ConsumerState<CreateBrandScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _websiteCtrl  = TextEditingController();

  File?   _pickedImage;
  bool    _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  // ── Photo picking ─────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: context.l10n.cropPhoto,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: context.l10n.cropPhoto, aspectRatioLockEnabled: true),
        ],
      );
      if (cropped == null) return;
      if (mounted) setState(() => _pickedImage = File(cropped.path));
    } on PlatformException catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      final msg = e.code == 'camera_access_denied'
          ? l10n.cameraAccessDenied
          : l10n.photoLibraryAccessDenied;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _showPhotoOptions() {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.camera),
              title: Text(l10n.takePhoto),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.gallery),
              title: Text(l10n.chooseFromLibrary),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_pickedImage != null)
              ListTile(
                leading: const Icon(
                    Iconsax.trash, color: AppPalette.error),
                title: Text(
                  context.l10n.removePhoto,
                  style: const TextStyle(color: AppPalette.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _pickedImage = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── OTP flow ──────────────────────────────────────────────────────────────

  Future<String?> _requestAndVerifyPhoneOtp(String phone) async {
    // 1. Request OTP — capture debugCode for dev auto-fill
    String? debugCode;
    try {
      final res = await ApiClient.instance.post<Map<String, dynamic>>(
        Endpoints.requestPhoneOtp,
        data: {'phone': phone, 'purpose': OtpPurpose.verifyPhone.value},
        fromJson: (j) => j,
      );
      debugCode = res['debugCode'] as String?;
    } on NetworkException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppPalette.error,
        ),
      );
      return null;
    }

    // 2. Show OTP bottom sheet and wait for the code
    if (!mounted) return null;
    final theme  = Theme.of(context);
    final locale = Localizations.localeOf(context);

    final code = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Theme(
        data: theme,
        child: Localizations.override(
          context: context,
          locale: locale,
          child: _OtpBottomSheet(phone: phone, debugCode: debugCode),
        ),
      ),
    );

    return code; // null if cancelled / failed
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    final phone = _phoneCtrl.text.trim();

    setState(() => _isSubmitting = true);

    try {
      // 1. Phone OTP verification (required if phone entered)
      String? phoneOtpCode;
      if (phone.isNotEmpty) {
        phoneOtpCode = await _requestAndVerifyPhoneOtp(phone);
        if (phoneOtpCode == null) {
          // User cancelled or OTP failed
          setState(() => _isSubmitting = false);
          return;
        }
      }

      // 2. Create brand
      final createBody = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        if (_emailCtrl.text.trim().isNotEmpty)
          'email': _emailCtrl.text.trim(),
        if (phone.isNotEmpty) 'phone': phone,
        if (phoneOtpCode != null) 'phoneOtpCode': phoneOtpCode,
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
        if (_locationCtrl.text.trim().isNotEmpty)
          'location': _locationCtrl.text.trim(),
        if (_websiteCtrl.text.trim().isNotEmpty)
          'website': _websiteCtrl.text.trim(),
      };

      final created = await ApiClient.instance.post<Map<String, dynamic>>(
        Endpoints.createBrand,
        data: createBody,
        fromJson: (j) => j,
      );

      // 3. Upload logo if picked
      if (_pickedImage != null) {
        final brandId =
            (created['brand'] as Map<String, dynamic>?)?['id'] as String?;
        if (brandId != null) {
          try {
            await ApiClient.instance.postMultipart(
              Endpoints.uploadBrandLogo(brandId),
              file: _pickedImage!,
              fieldName: 'file',
            );
          } catch (_) {
            // Logo upload failure is non-critical
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.brandCreated)),
      );
      context.pop(true);
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppPalette.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.genericError),
          backgroundColor: AppPalette.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n    = context.l10n;
    final primary = context.palette.primary;
    final dc      = context.dc;

    return Scaffold(
      backgroundColor: dc.background,
      appBar: AppBar(
        backgroundColor: dc.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.createBrand,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              // ── Logo picker ──────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          image: _pickedImage != null
                              ? DecorationImage(
                                  image: FileImage(_pickedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _pickedImage == null
                            ? Icon(Iconsax.shop,
                                size: 40,
                                color: primary.withValues(alpha: 0.4))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Name ─────────────────────────────────────────────────
              _SectionLabel(label: l10n.brandName.toUpperCase()),
              const SizedBox(height: 6),
              _FormTextField(
                controller: _nameCtrl,
                hint: l10n.brandNameHint,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
              ),
              const SizedBox(height: 20),

              // ── Email ─────────────────────────────────────────────────
              _SectionLabel(label: l10n.brandEmail.toUpperCase()),
              const SizedBox(height: 6),
              _FormTextField(
                controller: _emailCtrl,
                hint: l10n.brandEmailHint,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // ── Phone ─────────────────────────────────────────────────
              _SectionLabel(label: l10n.brandPhone.toUpperCase()),
              const SizedBox(height: 6),
              _FormTextField(
                controller: _phoneCtrl,
                hint: l10n.brandPhoneHint,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.fieldRequired;
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Iconsax.info_circle,
                      size: 14, color: dc.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.verifyPhoneSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: dc.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Description ───────────────────────────────────────────
              _SectionLabel(label: l10n.brandDescription.toUpperCase()),
              const SizedBox(height: 6),
              _FormTextField(
                controller: _descCtrl,
                hint: l10n.brandDescriptionHint,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // ── Location ──────────────────────────────────────────────
              _SectionLabel(label: l10n.brandLocation.toUpperCase()),
              const SizedBox(height: 6),
              _FormTextField(
                controller: _locationCtrl,
                hint: l10n.brandLocationHint,
              ),
              const SizedBox(height: 20),

              // ── Website ───────────────────────────────────────────────
              _SectionLabel(label: l10n.brandWebsite.toUpperCase()),
              const SizedBox(height: 6),
              _FormTextField(
                controller: _websiteCtrl,
                hint: l10n.brandWebsiteHint,
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final uri = Uri.tryParse(v.trim());
                  if (uri == null ||
                      !uri.hasScheme ||
                      (!uri.scheme.startsWith('http'))) {
                    return l10n.invalidUrl;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                disabledBackgroundColor: primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      l10n.verifyAndCreate,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _OtpBottomSheet extends StatefulWidget {
  const _OtpBottomSheet({required this.phone, this.debugCode});

  final String  phone;
  final String? debugCode;

  @override
  State<_OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<_OtpBottomSheet> {
  static const _otpLength = 6;

  final _controllers = List.generate(_otpLength, (_) => TextEditingController());
  final _focusNodes  = List.generate(_otpLength, (_) => FocusNode());

  bool   _isVerifying = false;
  bool   _canResend   = false;
  int    _resendTimer = 30;
  Timer? _timer;
  String? _error;

  String get _code => _controllers.map((c) => c.text).join();
  bool   get _complete => _code.length == _otpLength;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fillCode(widget.debugCode);
    });
  }

  void _fillCode(String? code) {
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

  void _clearOtp() {
    for (final c in _controllers) { c.clear(); }
    if (mounted) _focusNodes.first.requestFocus();
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
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < digits.length && (index + i) < _otpLength; i++) {
        _controllers[index + i].text = digits[i];
      }
      final next = (index + digits.length).clamp(0, _otpLength - 1);
      _focusNodes[next].requestFocus();
      setState(() {});
      if (_complete) _confirm();
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
    if (_complete) _confirm();
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

  void _confirm() {
    if (!_complete || _isVerifying) return;
    // Return the entered code to the caller
    Navigator.of(context).pop(_code);
  }

  Future<void> _resend() async {
    try {
      final res = await ApiClient.instance.post<Map<String, dynamic>>(
        Endpoints.requestPhoneOtp,
        data: {
          'phone': widget.phone,
          'purpose': OtpPurpose.verifyPhone.value,
        },
        fromJson: (j) => j,
      );
      _startTimer();
      _clearOtp();
      setState(() => _error = null);
      // Auto-fill debug code if returned
      final newDebugCode = res['debugCode'] as String?;
      if (newDebugCode != null) _fillCode(newDebugCode);
    } catch (e) {
      setState(() =>
          _error = e is NetworkException ? e.message : context.l10n.otpResendFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n    = context.l10n;
    final primary = context.palette.primary;
    final dc      = context.dc;

    return AutofillGroup(
      child: Container(
      decoration: BoxDecoration(
        color: dc.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: dc.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            l10n.verifyPhone,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: dc.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${l10n.otpSentTo} ${widget.phone}',
            style: TextStyle(fontSize: 14, color: dc.textSecondary),
          ),
          const SizedBox(height: 24),

          // OTP input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              _otpLength,
              (i) => _OtpCell(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                onChanged: (v) => _onDigitChanged(i, v),
                onBackspace: () => _onBackspace(i),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppPalette.error, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        fontSize: 13, color: AppPalette.error),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Resend
          Center(
            child: _canResend
                ? TextButton(
                    onPressed: _resend,
                    child: Text(
                      l10n.otpResend,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: primary,
                      ),
                    ),
                  )
                : Text(
                    l10n.otpResendIn(_resendTimer),
                    style: TextStyle(
                        fontSize: 14, color: dc.textSecondary),
                  ),
          ),
          const SizedBox(height: 8),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _complete && !_isVerifying ? _confirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                disabledBackgroundColor: primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.verifyAndCreate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),   // AutofillGroup
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP Digit Cell
// ─────────────────────────────────────────────────────────────────────────────

class _OtpCell extends StatefulWidget {
  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final VoidCallback onBackspace;

  @override
  State<_OtpCell> createState() => _OtpCellState();
}

class _OtpCellState extends State<_OtpCell> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final focused  = widget.focusNode.hasFocus;
    final hasValue = widget.controller.text.isNotEmpty;
    final primary  = context.palette.primary;
    final dc       = context.dc;

    return Container(
      width: 46,
      height: 56,
      decoration: BoxDecoration(
        color: dc.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
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
              width: 18,
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
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: dc.textPrimary,
              ),
            ),
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
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.focusNode.requestFocus,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: context.dc.textSecondary,
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  const _FormTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.inputFormatters,
  });

  final TextEditingController              controller;
  final String                             hint;
  final TextInputType?                     keyboardType;
  final String? Function(String?)?         validator;
  final int                                maxLines;
  final List<TextInputFormatter>?          inputFormatters;

  @override
  Widget build(BuildContext context) {
    final dc      = context.dc;
    final primary = context.palette.primary;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: 15, color: dc.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: dc.textTertiary, fontSize: 14),
        filled: true,
        fillColor: dc.secondaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppPalette.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppPalette.error, width: 1.5),
        ),
      ),
    );
  }
}
