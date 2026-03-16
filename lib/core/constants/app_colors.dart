// app_colors.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary palette — Crimson Red
  static const Color primary        = Color(0xFFC71F37);
  static const Color primaryLight   = Color(0xFFE01E37);
  static const Color primaryDark    = Color(0xFF85182A);

  // Background
  static const Color background          = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF2F2F2);
  static const Color tertiaryBackground  = Color(0xFFE5E5E5);

  // Text
  static const Color textPrimary   = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary  = Color(0xFFC7C7CC);

  // Semantic
  static const Color error   = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);

  // Blue family
  static const Color blue      = Color(0xFF0066CC);
  static const Color blueLight = Color(0xFF4DA3FF);

  // Onboarding dark background — deep crimson
  static const Color darkBg    = Color(0xFF641220);
  static const Color darkBgEnd = Color(0xFF85182A);
}
