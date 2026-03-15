// settings_provider.dart
// Reziphay — Persistent app settings (theme, language, reminders)
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Enums ────────────────────────────────────────────────────────────────────

enum AppThemeMode {
  system('System'),
  light('Light'),
  dark('Dark');

  const AppThemeMode(this.label);
  final String label;
}

enum AppLanguage {
  azerbaijani('az', 'Azərbaycan'),
  english('en', 'English'),
  russian('ru', 'Русский'),
  turkish('tr', 'Türkçe');

  const AppLanguage(this.code, this.displayName);
  final String code;
  final String displayName;
}

// ── State ────────────────────────────────────────────────────────────────────

class SettingsState {
  const SettingsState({
    this.themeMode       = AppThemeMode.system,
    this.language        = AppLanguage.azerbaijani,
    this.reminderEnabled = true,
    this.reminderMinutes = 30,
    this.loaded          = false,
  });

  final AppThemeMode themeMode;
  final AppLanguage  language;

  /// UCR-only: show a reminder notification before each reservation
  final bool reminderEnabled;
  final int  reminderMinutes;

  /// Whether prefs have been loaded from disk (used to delay MaterialApp build)
  final bool loaded;

  SettingsState copyWith({
    AppThemeMode? themeMode,
    AppLanguage?  language,
    bool?         reminderEnabled,
    int?          reminderMinutes,
    bool?         loaded,
  }) =>
      SettingsState(
        themeMode:       themeMode       ?? this.themeMode,
        language:        language        ?? this.language,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
        loaded:          loaded          ?? this.loaded,
      );

  /// Maps [AppThemeMode] → Flutter [ThemeMode]
  ThemeMode get flutterThemeMode => switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light  => ThemeMode.light,
        AppThemeMode.dark   => ThemeMode.dark,
      };

  /// Maps [AppLanguage] → Flutter [Locale]
  Locale get locale => Locale(language.code);
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  static const _keyTheme  = 'settings_theme_idx';
  static const _keyLang   = 'settings_lang_code';
  static const _keyRemEn  = 'settings_reminder_enabled';
  static const _keyRemMin = 'settings_reminder_minutes';

  Future<void> _load() async {
    final prefs     = await SharedPreferences.getInstance();
    final themeIdx  = prefs.getInt(_keyTheme)     ?? 0;
    final langCode  = prefs.getString(_keyLang)   ?? 'az';
    final remEn     = prefs.getBool(_keyRemEn)    ?? true;
    final remMin    = prefs.getInt(_keyRemMin)     ?? 30;

    final theme = AppThemeMode.values[
        themeIdx.clamp(0, AppThemeMode.values.length - 1)];
    final lang = AppLanguage.values.firstWhere(
      (l) => l.code == langCode,
      orElse: () => AppLanguage.azerbaijani,
    );

    state = SettingsState(
      themeMode:       theme,
      language:        lang,
      reminderEnabled: remEn,
      reminderMinutes: remMin,
      loaded:          true,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, mode.index);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = state.copyWith(language: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, lang.code);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    state = state.copyWith(reminderEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRemEn, enabled);
  }

  Future<void> setReminderMinutes(int minutes) async {
    state = state.copyWith(reminderMinutes: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRemMin, minutes);
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
