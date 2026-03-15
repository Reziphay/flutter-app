// settings_screen.dart
// Reziphay — App Settings (Theme, Language, UCR Reminders)
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../state/app_state.dart';
import '../../state/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final primary  = context.palette.primary;
    final dc       = context.dc;
    final isUcr    = !ref.watch(appStateProvider).isUso;

    return Scaffold(
      backgroundColor: dc.secondaryBackground,
      appBar: AppBar(
        backgroundColor: dc.background,
        foregroundColor: dc.textPrimary,
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [

          // ── Appearance ────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance', icon: Iconsax.brush, dc: dc),
          _SettingsCard(dc: dc, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.sun, size: 20, color: dc.textTertiary),
                      const SizedBox(width: 14),
                      Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: dc.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ThemeSegmentedControl(
                    current: settings.themeMode,
                    primary: primary,
                    dc:      dc,
                    onChanged: notifier.setThemeMode,
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Language ──────────────────────────────────────────────────
          _SectionHeader(title: 'Language', icon: Iconsax.language_square, dc: dc),
          _SettingsCard(
            dc: dc,
            children: AppLanguage.values.map((lang) {
              final isLast     = lang == AppLanguage.values.last;
              final isSelected = settings.language == lang;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LangRow(
                    lang:       lang,
                    selected:   isSelected,
                    primary:    primary,
                    dc:         dc,
                    onTap:      () => notifier.setLanguage(lang),
                  ),
                  if (!isLast) _HairlineDivider(dc: dc),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // ── Reminders (UCR only) ──────────────────────────────────────
          if (isUcr) ...[
            _SectionHeader(
              title: 'Reservation Reminders',
              icon: Iconsax.notification,
              dc: dc,
            ),
            _SettingsCard(dc: dc, children: [
              // Toggle row
              _SwitchRow(
                icon:    Iconsax.notification_bing,
                label:   'Enable Reminders',
                value:   settings.reminderEnabled,
                primary: primary,
                dc:      dc,
                onChanged: notifier.setReminderEnabled,
              ),

              // Minutes picker — only visible when enabled
              if (settings.reminderEnabled) ...[
                _HairlineDivider(dc: dc),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Iconsax.timer, size: 20,
                              color: dc.textTertiary),
                          const SizedBox(width: 14),
                          Text(
                            'Remind me',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: dc.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ReminderMinutesPicker(
                        current: settings.reminderMinutes,
                        primary: primary,
                        dc:      dc,
                        onChanged: notifier.setReminderMinutes,
                      ),
                    ],
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Theme segmented control ───────────────────────────────────────────────────

class _ThemeSegmentedControl extends StatelessWidget {
  const _ThemeSegmentedControl({
    required this.current,
    required this.primary,
    required this.dc,
    required this.onChanged,
  });

  final AppThemeMode                 current;
  final Color                        primary;
  final AppDynamicColors             dc;
  final ValueChanged<AppThemeMode>   onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color:        dc.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: AppThemeMode.values.map((mode) {
          final isSelected = current == mode;
          final icon = switch (mode) {
            AppThemeMode.system => Icons.brightness_auto_rounded,
            AppThemeMode.light  => Icons.wb_sunny_rounded,
            AppThemeMode.dark   => Icons.nightlight_round,
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:  primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: isSelected ? Colors.white : dc.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      mode.label,
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : dc.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Language row ──────────────────────────────────────────────────────────────

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.lang,
    required this.selected,
    required this.primary,
    required this.dc,
    required this.onTap,
  });

  final AppLanguage      lang;
  final bool             selected;
  final Color            primary;
  final AppDynamicColors dc;
  final VoidCallback     onTap;

  static const _flags = {
    'az': '🇦🇿',
    'en': '🇬🇧',
    'ru': '🇷🇺',
    'tr': '🇹🇷',
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(_flags[lang.code] ?? '🌐',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                lang.displayName,
                style: TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w500,
                  color:      dc.textPrimary,
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity:  selected ? 1.0 : 0.0,
              child: Icon(Icons.check_rounded, size: 20, color: primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reminder minutes picker ───────────────────────────────────────────────────

class _ReminderMinutesPicker extends StatelessWidget {
  const _ReminderMinutesPicker({
    required this.current,
    required this.primary,
    required this.dc,
    required this.onChanged,
  });

  final int                 current;
  final Color               primary;
  final AppDynamicColors    dc;
  final ValueChanged<int>   onChanged;

  static const _options = [10, 15, 30, 60, 120];

  static String _label(int min) {
    if (min < 60) return '${min}m';
    return '${min ~/ 60}h';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((min) {
        final isSelected = current == min;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(min),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary
                    : dc.secondaryBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _label(min),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : dc.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Switch row ────────────────────────────────────────────────────────────────

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.primary,
    required this.dc,
    required this.onChanged,
  });

  final IconData             icon;
  final String               label;
  final bool                 value;
  final Color                primary;
  final AppDynamicColors     dc;
  final ValueChanged<bool>   onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: dc.textTertiary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w500,
                color:      dc.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value:           value,
            onChanged:       onChanged,
            activeColor:     primary,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.dc,
  });
  final String           title;
  final IconData         icon;
  final AppDynamicColors dc;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 14, color: dc.textTertiary),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize:      11,
                fontWeight:    FontWeight.w700,
                color:         dc.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children, required this.dc});
  final List<Widget>     children;
  final AppDynamicColors dc;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color:        dc.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:     Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset:    const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
}

class _HairlineDivider extends StatelessWidget {
  const _HairlineDivider({required this.dc});
  final AppDynamicColors dc;

  @override
  Widget build(BuildContext context) => Divider(
        height:    1,
        indent:    52,
        endIndent: 0,
        color:     dc.divider,
      );
}
