// app_colors.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary palette
  static const Color primary        = Color(0xFF6B4FFF);
  static const Color primaryLight   = Color(0xFF9C7FFF);
  static const Color primaryDark    = Color(0xFF4B2FDF);

  // Background
  static const Color background          = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF2F2F7);
  static const Color tertiaryBackground  = Color(0xFFE5E5EA);

  // Text
  static const Color textPrimary   = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary  = Color(0xFFC7C7CC);

  // Semantic
  static const Color error   = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);

  // Onboarding dark background
  static const Color darkBg    = Color(0xFF0F0A26);
  static const Color darkBgEnd = Color(0xFF1A0F38);
}
