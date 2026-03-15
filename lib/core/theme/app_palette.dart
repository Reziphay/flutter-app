// app_palette.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';

/// Role-aware color palette injected via [ThemeExtension].
/// Access via [BuildContext.palette].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.darkBg,
    required this.darkBgEnd,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color darkBg;
  final Color darkBgEnd;

  // ── UCR — Customer (Red Family) ──────────────────────────────────────────
  static const ucr = AppPalette(
    primary:      Color(0xFFC71F37),
    primaryLight: Color(0xFFDA1E37),
    primaryDark:  Color(0xFF85182A),
    darkBg:       Color(0xFF641220),
    darkBgEnd:    Color(0xFF85182A),
  );

  // ── USO — Service Provider (Blue Family) ────────────────────────────────
  static const uso = AppPalette(
    primary:      Color(0xFF0466C8),
    primaryLight: Color(0xFF5C677D),
    primaryDark:  Color(0xFF0353A4),
    darkBg:       Color(0xFF001233),
    darkBgEnd:    Color(0xFF002855),
  );

  // ── Neutral — Login / Register / Onboarding ─────────────────────────────
  static const neutral = AppPalette(
    primary:      Color(0xFF000000),
    primaryLight: Color(0xFF5C5C5C),
    primaryDark:  Color(0xFF1C1C1E),
    darkBg:       Color(0xFF000000),
    darkBgEnd:    Color(0xFF1C1C1E),
  );

  // ── ThemeExtension boilerplate ──────────────────────────────────────────

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? darkBg,
    Color? darkBgEnd,
  }) =>
      AppPalette(
        primary:      primary      ?? this.primary,
        primaryLight: primaryLight ?? this.primaryLight,
        primaryDark:  primaryDark  ?? this.primaryDark,
        darkBg:       darkBg       ?? this.darkBg,
        darkBgEnd:    darkBgEnd    ?? this.darkBgEnd,
      );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      primary:      Color.lerp(primary,      other.primary,      t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark:  Color.lerp(primaryDark,  other.primaryDark,  t)!,
      darkBg:       Color.lerp(darkBg,       other.darkBg,       t)!,
      darkBgEnd:    Color.lerp(darkBgEnd,    other.darkBgEnd,    t)!,
    );
  }
}

// ── BuildContext extension ──────────────────────────────────────────────────

extension AppPaletteX on BuildContext {
  /// Returns the role-specific [AppPalette] injected into the current [Theme].
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.neutral;
}
