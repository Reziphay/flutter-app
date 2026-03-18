// edit_brand_screen.dart
// Reziphay — USO: Edit Brand (name, email, logo)
// Phone is read-only — was OTP-verified at creation.
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
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

class EditBrandScreen extends ConsumerStatefulWidget {
  const EditBrandScreen({super.key, required this.brandId});

  final String brandId;

  @override
  ConsumerState<EditBrandScreen> createState() => _EditBrandScreenState();
}

class _EditBrandScreenState extends ConsumerState<EditBrandScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _websiteCtrl  = TextEditingController();

  // Read-only — shown but not editable
  String? _phone;

  // Logo state
  String? _existingLogoUrl;
  File?   _pickedImage;

  bool _loadingInit = false;
  bool _isSaving    = false;

  @override
  void initState() {
    super.initState();
    _loadBrand();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  // ── Load existing brand ────────────────────────────────────────────────────

  Future<void> _loadBrand() async {
    setState(() => _loadingInit = true);
    try {
      final json = await ApiClient.instance.get<Map<String, dynamic>>(
        Endpoints.brandById(widget.brandId),
        fromJson: (j) => j,
      );
      final brand =
          (json['brand'] as Map<String, dynamic>?) ?? json;
      _nameCtrl.text     = brand['name']        as String? ?? '';
      _emailCtrl.text    = brand['email']       as String? ?? '';
      _descCtrl.text     = brand['description'] as String? ?? '';
      _locationCtrl.text = brand['location']    as String? ?? '';
      _websiteCtrl.text  = brand['website']     as String? ?? '';
      _phone = brand['phone'] as String?;
      final logoFile = brand['logoFile'] as Map<String, dynamic>?;
      _existingLogoUrl = logoFile?['url'] as String?;
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.somethingWentWrong)),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  // ── Photo picking ──────────────────────────────────────────────────────────

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
          IOSUiSettings(
              title: context.l10n.cropPhoto,
              aspectRatioLockEnabled: true),
        ],
      );
      if (cropped == null) return;
      if (mounted) {
        setState(() {
          _pickedImage = File(cropped.path);
          _existingLogoUrl = null; // preview with new image
        });
      }
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
          ],
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 1. Update brand fields
      await ApiClient.instance.patch<Map<String, dynamic>>(
        Endpoints.updateBrand(widget.brandId),
        data: {
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          'description': _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          'location': _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          'website': _websiteCtrl.text.trim().isEmpty
              ? null
              : _websiteCtrl.text.trim(),
        },
        fromJson: (j) => j,
      );

      // 2. Upload new logo if picked
      if (_pickedImage != null) {
        try {
          await ApiClient.instance.postMultipart(
            Endpoints.uploadBrandLogo(widget.brandId),
            file: _pickedImage!,
            fieldName: 'file',
          );
        } catch (_) {
          // logo upload failure is non-critical
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.brandUpdated)),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n    = context.l10n;
    final primary = context.palette.primary;
    final dc      = context.dc;

    if (_loadingInit) {
      return Scaffold(
        backgroundColor: dc.background,
        appBar: AppBar(
          backgroundColor: dc.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.editBrand,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

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
          l10n.editBrand,
          style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                l10n.save,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // ── Logo ────────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    children: [
                      _LogoWidget(
                        existingUrl: _existingLogoUrl,
                        pickedFile: _pickedImage,
                        name: _nameCtrl.text,
                        primary: primary,
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

              // ── Name ────────────────────────────────────────────────
              _SectionLabel(label: l10n.brandName.toUpperCase()),
              const SizedBox(height: 6),
              _FormTextField(
                controller: _nameCtrl,
                hint: l10n.brandNameHint,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? l10n.nameRequired
                        : null,
              ),
              const SizedBox(height: 20),

              // ── Email ────────────────────────────────────────────────
              _SectionLabel(label: l10n.brandEmail.toUpperCase()),
              const SizedBox(height: 6),
              _FormTextField(
                controller: _emailCtrl,
                hint: l10n.brandEmailHint,
                keyboardType: TextInputType.emailAddress,
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
              const SizedBox(height: 20),

              // ── Phone (read-only) ────────────────────────────────────
              if (_phone != null) ...[
                _SectionLabel(label: l10n.brandPhone.toUpperCase()),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: dc.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _phone!,
                          style: TextStyle(
                            fontSize: 15,
                            color: dc.textSecondary,
                          ),
                        ),
                      ),
                      Icon(Iconsax.lock, size: 16, color: dc.textTertiary),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Iconsax.info_circle,
                        size: 13, color: dc.textTertiary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        l10n.phoneNotEditable,
                        style: TextStyle(
                            fontSize: 11, color: dc.textTertiary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo Widget
// ─────────────────────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  const _LogoWidget({
    required this.existingUrl,
    required this.pickedFile,
    required this.name,
    required this.primary,
  });

  final String? existingUrl;
  final File?   pickedFile;
  final String  name;
  final Color   primary;

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (pickedFile != null) {
      imageProvider = FileImage(pickedFile!);
    } else if (existingUrl != null) {
      imageProvider = CachedNetworkImageProvider(existingUrl!);
    }

    if (imageProvider != null) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
      );
    }

    // Initials fallback
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: context.dc.textSecondary,
        ),
      );
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
