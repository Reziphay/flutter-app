// app_theme.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'app_dynamic_colors.dart';
import 'app_palette.dart';

abstract final class AppTheme {
  /// Light [ThemeData] from the given [AppPalette].
  static ThemeData build(AppPalette palette) =>
      _build(palette, Brightness.light);

  /// Dark [ThemeData] from the given [AppPalette].
  static ThemeData buildDark(AppPalette palette) =>
      _build(palette, Brightness.dark);

  /// Neutral fallback (unauthenticated state).
  static ThemeData get neutral => build(AppPalette.neutral);

  // ── Internal builder ────────────────────────────────────────────────────

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final dc     = isDark ? AppDynamicColors.dark : AppDynamicColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness:   brightness,
      colorScheme:  ColorScheme.fromSeed(
        brightness: brightness,
        seedColor:  palette.primary,
        primary:    palette.primary,
        onPrimary:  Colors.white,
        surface:    dc.background,
        onSurface:  dc.textPrimary,
        error:      AppPalette.error,
      ),
      extensions: [palette, dc],
      scaffoldBackgroundColor: dc.background,
      fontFamily: 'SF Pro Display',

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:        dc.background,
        foregroundColor:        dc.textPrimary,
        elevation:              0,
        scrolledUnderElevation: 0,
        centerTitle:            true,
        titleTextStyle: TextStyle(
          color:      dc.textPrimary,
          fontSize:   17,
          fontWeight: FontWeight.w600,
          fontFamily: 'SF Pro Display',
        ),
      ),

      // ── NavigationBar (bottom tab bar) ──────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dc.background,
        indicatorColor:  Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),

      // ── ElevatedButton ──────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: palette.primary),
          textStyle: const TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── InputDecoration ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: dc.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(color: dc.textSecondary),
        hintStyle:  TextStyle(color: dc.textTertiary),
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: dc.divider,
        thickness: 1,
        space: 1,
      ),

      // ── TextTheme ───────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge:   TextStyle(fontSize: 34, fontWeight: FontWeight.bold,   color: dc.textPrimary),
        headlineLarge:  TextStyle(fontSize: 28, fontWeight: FontWeight.bold,   color: dc.textPrimary),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,   color: dc.textPrimary),
        titleLarge:     TextStyle(fontSize: 17, fontWeight: FontWeight.w600,   color: dc.textPrimary),
        titleMedium:    TextStyle(fontSize: 15, fontWeight: FontWeight.w500,   color: dc.textPrimary),
        bodyLarge:      TextStyle(fontSize: 17, fontWeight: FontWeight.normal, color: dc.textPrimary),
        bodyMedium:     TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: dc.textPrimary),
        bodySmall:      TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: dc.textSecondary),
        labelMedium:    TextStyle(fontSize: 13, fontWeight: FontWeight.w500,   color: dc.textSecondary),
      ),
    );
  }
}
