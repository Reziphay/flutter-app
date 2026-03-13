import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';

ThemeData buildAppTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
      ).copyWith(
        error: AppColors.error,
        tertiary: AppColors.success,
        outline: AppColors.outline,
        surfaceTint: AppColors.primary,
        shadow: AppColors.shadow,
      );

  final baseTextTheme = ThemeData(brightness: Brightness.light).textTheme;
  final textTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 28,
      height: 34 / 28,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      color: AppColors.ink,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      height: 22 / 14,
      fontWeight: FontWeight.w400,
      color: AppColors.ink,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 13,
      height: 20 / 13,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      titleTextStyle: textTheme.titleMedium,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.surfaceMuted,
      labelTextStyle: WidgetStateProperty.all(textTheme.labelMedium),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: isSelected ? AppColors.primary : AppColors.textMuted,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        side: const BorderSide(color: AppColors.outline),
        foregroundColor: AppColors.ink,
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: textTheme.labelLarge,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      selectedColor: AppColors.surfaceMuted,
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.outlineSoft),
      labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.ink),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outlineSoft,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
  );
}
