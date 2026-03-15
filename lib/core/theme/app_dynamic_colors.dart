// app_dynamic_colors.dart
// Reziphay — ThemeExtension that adapts to light / dark mode
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';

/// Dynamic color palette that changes between light and dark themes.
/// Access via [BuildContext.dc] (short for DynamicColors).
@immutable
class AppDynamicColors extends ThemeExtension<AppDynamicColors> {
  const AppDynamicColors({
    required this.background,
    required this.secondaryBackground,
    required this.tertiaryBackground,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
  });

  final Color background;
  final Color secondaryBackground;
  final Color tertiaryBackground;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;

  // ── Light (current app appearance) ──────────────────────────────────────
  static const light = AppDynamicColors(
    background:          Color(0xFFFFFFFF),
    secondaryBackground: Color(0xFFF2F2F7),
    tertiaryBackground:  Color(0xFFE5E5EA),
    cardBackground:      Color(0xFFFFFFFF),
    textPrimary:         Color(0xFF000000),
    textSecondary:       Color(0xFF8E8E93),
    textTertiary:        Color(0xFFC7C7CC),
    divider:             Color(0xFFE5E5EA),
  );

  // ── Dark ────────────────────────────────────────────────────────────────
  // Layered charcoal-slate: not pure black, clear depth between surfaces,
  // visible dividers, readable tertiary text.
  static const dark = AppDynamicColors(
    background:          Color(0xFF0D0D12),   // very dark slate, not pure black
    secondaryBackground: Color(0xFF17171C),   // scaffold / page background
    tertiaryBackground:  Color(0xFF252530),   // input fills, inactive chips
    cardBackground:      Color(0xFF1C1C24),   // cards clearly elevated above bg
    textPrimary:         Color(0xFFF2F2F7),   // Apple-style soft white
    textSecondary:       Color(0xFF8E8E9A),   // medium grey
    textTertiary:        Color(0xFF636374),   // clearly readable (was 0xFF48484A)
    divider:             Color(0xFF2C2C3E),   // visible on cards
  );

  // ── ThemeExtension boilerplate ──────────────────────────────────────────

  @override
  AppDynamicColors copyWith({
    Color? background,
    Color? secondaryBackground,
    Color? tertiaryBackground,
    Color? cardBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
  }) =>
      AppDynamicColors(
        background:          background          ?? this.background,
        secondaryBackground: secondaryBackground ?? this.secondaryBackground,
        tertiaryBackground:  tertiaryBackground  ?? this.tertiaryBackground,
        cardBackground:      cardBackground      ?? this.cardBackground,
        textPrimary:         textPrimary         ?? this.textPrimary,
        textSecondary:       textSecondary       ?? this.textSecondary,
        textTertiary:        textTertiary        ?? this.textTertiary,
        divider:             divider             ?? this.divider,
      );

  @override
  AppDynamicColors lerp(AppDynamicColors? other, double t) {
    if (other == null) return this;
    return AppDynamicColors(
      background:          Color.lerp(background,          other.background,          t)!,
      secondaryBackground: Color.lerp(secondaryBackground, other.secondaryBackground, t)!,
      tertiaryBackground:  Color.lerp(tertiaryBackground,  other.tertiaryBackground,  t)!,
      cardBackground:      Color.lerp(cardBackground,      other.cardBackground,      t)!,
      textPrimary:         Color.lerp(textPrimary,         other.textPrimary,         t)!,
      textSecondary:       Color.lerp(textSecondary,       other.textSecondary,       t)!,
      textTertiary:        Color.lerp(textTertiary,        other.textTertiary,        t)!,
      divider:             Color.lerp(divider,             other.divider,             t)!,
    );
  }
}

// ── BuildContext shorthand ───────────────────────────────────────────────────

extension AppDynamicColorsX on BuildContext {
  /// Returns the dynamic colors for the current brightness.
  AppDynamicColors get dc =>
      Theme.of(this).extension<AppDynamicColors>() ?? AppDynamicColors.light;
}
