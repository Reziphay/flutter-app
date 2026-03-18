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
    required this.shades,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.darkBg,
    required this.darkBgEnd,
  });

  /// Full gradient of role colors (darkest → lightest or themed order).
  final List<Color> shades;

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color darkBg;
  final Color darkBgEnd;

  // ── Semantic colors (role-independent) ──────────────────────────────────

  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color blue = Color(0xFF0066CC);
  static const Color blueLight = Color(0xFF4DA3FF);

  // ── UCR — Customer (Red/Pink Family) ────────────────────────────────────

  static const ucr = AppPalette(
    shades: [
      Color(0xFFCC444B), // 0
      Color(0xFFDA5552), // 1
      Color(0xFFDF7373), // 2
      Color(0xFFE39695), // 3
      Color(0xFFE4B1AB), // 4
    ],
    primary: Color(0xFFCC444B), // shade 0
    primaryLight: Color(0xFFDF7373), // shade 2
    primaryDark: Color(0xFFCC444B), // shade 0
    darkBg: Color(0xFFCC444B), // shade 0
    darkBgEnd: Color(0xFFDA5552), // shade 1
  );

  // ── USO — Service Provider (Green Family) ─────────────────────────────

  static const uso = AppPalette(
    shades: [
      Color(0xFFEDEEC9), // 0
      Color(0xFFDDE7C7), // 1
      Color(0xFFBFD8BD), // 2
      Color(0xFF98C9A3), // 3
      Color(0xFF77BFA3), // 4
    ],
    primary: Color(0xFF77BFA3), // shade 4
    primaryLight: Color(0xFFBFD8BD), // shade 2
    primaryDark: Color(0xFF77BFA3), // shade 4
    darkBg: Color(0xFF77BFA3), // shade 4
    darkBgEnd: Color(0xFF98C9A3), // shade 3
  );

  // ── Neutral — Login / Register / Onboarding ─────────────────────────────

  static const neutral = AppPalette(
    shades: [
      Color(0xFF595959), // 0
      Color(0xFF7F7F7F), // 1
      Color(0xFFA5A5A5), // 2
      Color(0xFFCCCCCC), // 3
      Color(0xFFF2F2F2), // 4
    ],
    primary: Color(0xFF595959), // shade 0
    primaryLight: Color(0xFFA5A5A5), // shade 2
    primaryDark: Color(0xFF595959), // shade 0
    darkBg: Color(0xFF595959), // shade 0
    darkBgEnd: Color(0xFF7F7F7F), // shade 1
  );

  // ── ThemeExtension boilerplate ──────────────────────────────────────────

  @override
  AppPalette copyWith({
    List<Color>? shades,
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? darkBg,
    Color? darkBgEnd,
  }) =>
      AppPalette(
        shades: shades ?? this.shades,
        primary: primary ?? this.primary,
        primaryLight: primaryLight ?? this.primaryLight,
        primaryDark: primaryDark ?? this.primaryDark,
        darkBg: darkBg ?? this.darkBg,
        darkBgEnd: darkBgEnd ?? this.darkBgEnd,
      );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    final lerpedShades = <Color>[];
    final len = shades.length < other.shades.length
        ? shades.length
        : other.shades.length;
    for (var i = 0; i < len; i++) {
      lerpedShades.add(Color.lerp(shades[i], other.shades[i], t)!);
    }
    return AppPalette(
      shades: lerpedShades,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      darkBg: Color.lerp(darkBg, other.darkBg, t)!,
      darkBgEnd: Color.lerp(darkBgEnd, other.darkBgEnd, t)!,
    );
  }
}

// ── BuildContext extension ──────────────────────────────────────────────────

extension AppPaletteX on BuildContext {
  /// Returns the role-specific [AppPalette] injected into the current [Theme].
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.neutral;
}
