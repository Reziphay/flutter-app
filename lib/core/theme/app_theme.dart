// app_theme.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_palette.dart';

abstract final class AppTheme {
  /// Builds a [ThemeData] from the given [AppPalette].
  /// Call this with the result of [appPaletteProvider].
  static ThemeData build(AppPalette palette) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor:  palette.primary,
        primary:    palette.primary,
        onPrimary:  Colors.white,
        surface:    AppColors.background,
        onSurface:  AppColors.textPrimary,
        error:      AppColors.error,
      ),
      extensions: [palette],
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'SF Pro Display',

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ElevatedButton — uses colorScheme.primary → dynamic
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: palette.primary),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryBackground,
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
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
      ),

      // TextTheme
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold,    color: AppColors.textPrimary),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,   color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,  color: AppColors.textPrimary),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,      color: AppColors.textPrimary),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,     color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.normal,     color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.normal,    color: AppColors.textPrimary),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.normal,     color: AppColors.textSecondary),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,     color: AppColors.textSecondary),
      ),
    );
  }

  /// Neutral fallback (unauthenticated state).
  static ThemeData get neutral => build(AppPalette.neutral);
}
