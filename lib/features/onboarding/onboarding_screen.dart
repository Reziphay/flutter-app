// onboarding_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../state/settings_provider.dart';
import '../../core/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dc = context.dc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dc.background,
      body: Stack(
        children: [
          // ── Decorative background blobs ─────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: _Blob(
              size: 300,
              color: const Color(0xFFC71F37).withValues(alpha: isDark ? 0.08 : 0.10),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -100,
            child: _Blob(
              size: 340,
              color: const Color(0xFF0466C8).withValues(alpha: isDark ? 0.07 : 0.09),
            ),
          ),
          Positioned(
            top: 200,
            left: -60,
            child: _Blob(
              size: 180,
              color: const Color(0xFFC71F37).withValues(alpha: isDark ? 0.04 : 0.05),
            ),
          ),
          // ── Content ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const _TopBar(),
                  const Spacer(),
                  const _HeroSection(),
                  const Spacer(),
                  _RoleCardsSection(onRoleSelected: (role) {
                    ref.read(appStateProvider.notifier).selectRole(role);
                    context.push('/auth/phone');
                  }),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Background Blob

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// MARK: - Top Bar (theme + language)

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final dc = context.dc;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Language picker
        _LangButton(
          current: settings.language,
          onChanged: notifier.setLanguage,
          dc: dc,
        ),
        const SizedBox(width: 8),
        // Theme toggle
        _ThemeButton(
          current: settings.themeMode,
          onChanged: notifier.setThemeMode,
          dc: dc,
        ),
      ],
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.current,
    required this.onChanged,
    required this.dc,
  });

  final AppLanguage current;
  final void Function(AppLanguage) onChanged;
  final AppDynamicColors dc;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: dc.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dc.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current.code.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dc.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 14, color: dc.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LangSheet(current: current, onChanged: onChanged),
    );
  }
}

class _LangSheet extends StatelessWidget {
  const _LangSheet({required this.current, required this.onChanged});

  final AppLanguage current;
  final void Function(AppLanguage) onChanged;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = context.l10n;
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: dc.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.languageModalTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: dc.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...AppLanguage.values.map((lang) {
              final selected = lang == current;
              return ListTile(
                onTap: () {
                  onChanged(lang);
                  Navigator.of(context).pop();
                },
                title: Text(
                  lang.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? AppColors.primary : dc.textPrimary,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
                    : null,
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.current,
    required this.onChanged,
    required this.dc,
  });

  final AppThemeMode current;
  final void Function(AppThemeMode) onChanged;
  final AppDynamicColors dc;

  IconData get _icon => switch (current) {
        AppThemeMode.light  => Icons.light_mode_rounded,
        AppThemeMode.dark   => Icons.dark_mode_rounded,
        AppThemeMode.system => Icons.brightness_auto_rounded,
      };

  AppThemeMode get _next => switch (current) {
        AppThemeMode.system => AppThemeMode.light,
        AppThemeMode.light  => AppThemeMode.dark,
        AppThemeMode.dark   => AppThemeMode.system,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(_next),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: dc.secondaryBackground,
          shape: BoxShape.circle,
          border: Border.all(color: dc.divider),
        ),
        child: Icon(_icon, size: 18, color: dc.textPrimary),
      ),
    );
  }
}

// MARK: - Hero

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = context.l10n;
    return Column(
      children: [
        Text(
          'Reziphay.',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: dc.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.appTagline,
          style: TextStyle(
            fontSize: 16,
            color: dc.textSecondary,
          ),
        ),
      ],
    );
  }
}

// MARK: - Role Cards

class _RoleCardsSection extends StatelessWidget {
  const _RoleCardsSection({required this.onRoleSelected});
  final void Function(UserRole) onRoleSelected;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.onboardingPrompt,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: dc.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          icon: Icons.person_rounded,
          title: l10n.roleCustomer,
          subtitle: l10n.roleCustomerDesc,
          color: const Color(0xFFC71F37),
          onTap: () => onRoleSelected(UserRole.ucr),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          icon: Icons.work_rounded,
          title: l10n.roleProvider,
          subtitle: l10n.roleProviderDesc,
          color: const Color(0xFF0466C8),
          onTap: () => onRoleSelected(UserRole.uso),
        ),
      ],
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: dc.cardBackground.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: dc.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: dc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: dc.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: dc.textTertiary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
