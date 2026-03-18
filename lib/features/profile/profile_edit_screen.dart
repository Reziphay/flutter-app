// profile_edit_screen.dart
// Reziphay — Profile editing (UCR & USO)
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/network/network_exception.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _nameCtrl;
  File? _pendingAvatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(appStateProvider).currentUser;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // MARK: - Avatar picker

  Future<void> _pickAvatar() async {
    final source = await _showSourceSheet();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
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
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (cropped != null) {
      setState(() => _pendingAvatar = File(cropped.path));
    }
  }

  Future<ImageSource?> _showSourceSheet() {
    final l10n = context.l10n;
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dc = context.dc;
        return Container(
          decoration: BoxDecoration(
            color: dc.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dc.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Iconsax.camera, color: dc.textPrimary),
                  title: Text(
                    l10n.takePhoto,
                    style: TextStyle(color: dc.textPrimary),
                  ),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Iconsax.gallery, color: dc.textPrimary),
                  title: Text(
                    l10n.chooseFromLibrary,
                    style: TextStyle(color: dc.textPrimary),
                  ),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // MARK: - Save

  Future<void> _save() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      _showError('Full name cannot be empty.');
      return;
    }

    setState(() => _saving = true);
    try {
      final user = ref.read(appStateProvider).currentUser;

      // Upload avatar if changed
      if (_pendingAvatar != null) {
        final updated = await AuthService.instance.uploadAvatar(_pendingAvatar!);
        ref.read(appStateProvider.notifier).updateUser(updated);
      }

      // Update name if changed
      if (newName != user?.fullName) {
        final updated = await AuthService.instance.updateProfile(fullName: newName);
        ref.read(appStateProvider.notifier).updateUser(updated);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppPalette.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n    = context.l10n;
    final user    = ref.watch(appStateProvider).currentUser;
    final dc      = context.dc;
    final primary = context.palette.primary;
    final topPad  = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: dc.secondaryBackground,
      body: Column(
        children: [
          // ── Top bar ─────────────────────────────────────────────────────
          Container(
            color: dc.background,
            padding: EdgeInsets.fromLTRB(8, topPad + 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: dc.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    l10n.editProfileTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: dc.textPrimary,
                    ),
                  ),
                ),
                _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _save,
                        child: Text(
                          l10n.save,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 24),
              children: [
                // ── Avatar ────────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _picking ? null : _pickAvatar,
                    child: Stack(
                      children: [
                        _AvatarCircle(
                          localFile:  _pendingAvatar,
                          networkUrl: user?.avatarUrl,
                          fallbackInitials: _initials(user?.fullName),
                          primary: primary,
                          size: 100,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: dc.background, width: 2),
                            ),
                            child: const Icon(Iconsax.camera5,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Fields ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: dc.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: dc.divider),
                    ),
                    child: Column(
                      children: [
                        _EditField(
                          icon:        Iconsax.user,
                          label:       l10n.fullName,
                          controller:  _nameCtrl,
                          enabled:     true,
                          dc:          dc,
                        ),
                        Divider(height: 1, indent: 52, color: dc.divider),
                        _EditField(
                          icon:    Iconsax.sms,
                          label:   l10n.email,
                          value:   user?.email ?? '—',
                          enabled: false,
                          dc:      dc,
                        ),
                        Divider(height: 1, indent: 52, color: dc.divider),
                        _EditField(
                          icon:    Iconsax.call,
                          label:   l10n.phone,
                          value:   user?.phone ?? '—',
                          enabled: false,
                          dc:      dc,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    l10n.emailDisabledNote,
                    style: TextStyle(fontSize: 12, color: dc.textTertiary),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _picking => false;

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

// MARK: - Avatar Circle

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.fallbackInitials,
    required this.primary,
    required this.size,
    this.localFile,
    this.networkUrl,
  });

  final File?   localFile;
  final String? networkUrl;
  final String  fallbackInitials;
  final Color   primary;
  final double  size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary.withValues(alpha: 0.12),
      ),
      clipBehavior: Clip.antiAlias,
      child: _child,
    );
  }

  Widget get _child {
    if (localFile != null) {
      return Image.file(localFile!, fit: BoxFit.cover);
    }
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: networkUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => _initials,
      );
    }
    return _initials;
  }

  Widget get _initials => Center(
        child: Text(
          fallbackInitials,
          style: TextStyle(
            fontSize:   size * 0.32,
            fontWeight: FontWeight.w700,
            color:      primary,
          ),
        ),
      );
}

// MARK: - Edit Field

class _EditField extends StatelessWidget {
  const _EditField({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.dc,
    this.controller,
    this.value,
  });

  final IconData             icon;
  final String               label;
  final bool                 enabled;
  final AppDynamicColors     dc;
  final TextEditingController? controller;
  final String?              value;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: dc.textTertiary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize:   11,
                      color:      dc.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? '—',
                    style: TextStyle(
                      fontSize:   15,
                      color:      dc.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.lock_outline_rounded, size: 16, color: dc.textTertiary),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: dc.textTertiary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize:   11,
                    color:      dc.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      filled:              false,
                      border:              InputBorder.none,
                      enabledBorder:       InputBorder.none,
                      focusedBorder:       InputBorder.none,
                      errorBorder:         InputBorder.none,
                      focusedErrorBorder:  InputBorder.none,
                      isDense:             true,
                      contentPadding:      EdgeInsets.zero,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    style: TextStyle(
                      fontSize:   15,
                      color:      dc.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      border:        InputBorder.none,
                      isDense:       true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
